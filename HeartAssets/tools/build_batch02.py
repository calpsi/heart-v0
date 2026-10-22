"""Build one segmented, hollow heart-tube teaching model at a time.
Blender --background --factory-startup --python this_file -- --stage 3 (or 4).
"""
import sys, math, json, argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
import bpy
from mathutils import Vector
from math import sin, cos, pi

SEGMENTS = [
    ('SinusVenosus','Sinus venosus',0,30),
    ('PrimitiveAtrium','Primitive atrium',30,60),
    ('AVCanal','Atrioventricular canal',60,76),
    ('PrimitiveVentricle','Primitive ventricle',76,124),
    ('BulbusCordis','Bulbus cordis',124,168),
    ('TruncusArteriosus','Truncus arteriosus',168,200),
]
# Parameter positions refer to shared rings, giving perfectly matching seams.
LOOP = [
    (0, (.38,.82,1.16)),(.15,(.73,.68,.74)),
    (.30,(.77,.34,.06)),(.38,(.67,.00,-.42)),
    (.50,(.26,-.25,-.91)),(.62,(-.48,-.39,-.70)),
    (.73,(-.76,-.32,-.13)),(.84,(-.60,-.12,.50)),
    (1,(-.24,.04,1.38)),
]
RADII=[(0,.22),(.075,.30),(.15,.27),(.225,.37),(.30,.24),(.34,.18),
       (.38,.25),(.50,.43),(.62,.32),(.73,.38),(.84,.25),(1,.21)]

def interpolate(knots,t):
    # Cubic Hermite interpolation using finite-difference derivatives.
    k=next((i for i in range(len(knots)-1) if t<=knots[i+1][0]),len(knots)-2)
    t0,p0=knots[k]; t1,p1=knots[k+1]
    a,pa=knots[max(0,k-1)]; b,pb=knots[min(len(knots)-1,k+2)]
    m0=(p1-pa)/(t1-a); m1=(pb-p0)/(b-t0)
    u=(t-t0)/(t1-t0)
    return (2*u**3-3*u**2+1)*p0+(u**3-2*u**2+u)*(t1-t0)*m0+(-2*u**3+3*u**2)*p1+(u**3-u**2)*(t1-t0)*m1

def centre(t,looped):
    if not looped: return Vector((.035*sin(pi*t),0,-1.60+3.20*t))
    return interpolate([(u,Vector(p)) for u,p in LOOP],t)

def frames(looped):
    points=[centre(i/200,looped) for i in range(201)]
    tangents=[(points[min(i+1,200)]-points[max(i-1,0)]).normalized() for i in range(201)]
    # Project the dorsal direction onto each cross-section so removing the
    # anterior panels actually reveals the lumen from the ventral teaching view.
    # These paths never run parallel to the dorsal axis.
    result=[]
    for i,tangent in enumerate(tangents):
        v=Vector((0,1,0))-tangent*tangent.y
        assert v.length>0.1, 'Cross-section direction is ambiguous'
        v.normalize()
        u=v.cross(tangent).normalized()
        result.append((u.copy(),v))
    return points,result

def tube_panel(name,lo,hi,f0,f1,a0,a1,points,axes,mat,parent,label):
    # Use every second shared ring. Boundary indices are all even.
    indices=list(range(lo,hi+1,2)); n=len(indices); m=16
    verts=[]; faces=[]
    for factor in (f0,f1):
        for index in indices:
            t=index/200; radius=interpolate(RADII,t)*factor
            p=points[index]; u,v=axes[index]
            for j in range(m+1):
                angle=a0+(a1-a0)*j/m
                # Fine relief is shared at seams and does not obstruct the lumen.
                relief=1+.008*sin(31*t+3*angle)*sin(pi*t)
                verts.append(p+radius*relief*(cos(angle)*u+sin(angle)*v))
    stride=m+1; layer=n*stride
    for k in range(2):
        for i in range(n-1):
            for j in range(m):
                a=k*layer+i*stride+j
                f=(a,a+1,a+1+stride,a+stride)
                faces.append(f if k else tuple(reversed(f)))
    for i in (0,n-1):
        for j in range(m):
            a=i*stride+j
            faces.append((a,a+1,a+1+layer,a+layer))
    for j in (0,m):
        for i in range(n-1):
            a=i*stride+j
            faces.append((a,a+stride,a+stride+layer,a+layer))
    return core.mesh(name,verts,faces,mat,parent,label)

def build(number):
    materials=core.setup()
    root=core.group('Heart_03_PrimitiveHeartTube' if number==3 else 'Heart_04_CardiacLooping')
    points,axes=frames(number==4)
    for segment,label,lo,hi in SEGMENTS:
        parent=core.group(segment,root)
        for layer,f0,f1,key,tissue in [
            ('Myocardium',.78,1,'muscle','myocardium'),
            ('CardiacJelly',.61,.78,'jelly','cardiac jelly'),
            ('Endocardium',.54,.61,'lining','endocardium')]:
            for panel,a0,a1 in [('Posterior',0,pi),('Anterior',pi,2*pi)]:
                tube_panel(f'{layer}_{segment}_{panel}',lo,hi,f0,f1,a0,a1,points,axes,
                           materials[key],parent,f'{label} — {tissue}, {panel.lower()} panel')
    core.export(root,number)
    manifest_path=core.BASE/'manifests'/(root.name+'.json')
    data=json.loads(manifest_path.read_text())
    data['batch']=2
    data['coordinate_note']='Blender +Z cranial, -Y ventral. USD +Y cranial, +Z ventral. Ventral view: anatomical right at viewer left (-X). Anterior/posterior teaching cuts follow the projected dorsal direction around the curved tube.'
    data['state']='Straight, segmented tube' if number==3 else 'Illustrative established D-loop; not an exact Day 24 reconstruction'
    data['limitations']=['Static morphology; no contraction or continuous looping animation',
        'No sinus venosus tributaries, dorsal mesocardium, trabeculation or endocardial cushions',
        'Segment cuts and wall thickness are exaggerated for teaching; source review required']
    data['segments']=[{'id':s,'label':l,'ring_range':[lo,hi]} for s,l,lo,hi in SEGMENTS]
    manifest_path.write_text(json.dumps(data,indent=2))

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    parser=argparse.ArgumentParser(); parser.add_argument('--stage',type=int,choices=[3,4],required=True)
    build(parser.parse_args(args).stage)

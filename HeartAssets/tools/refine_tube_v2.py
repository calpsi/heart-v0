"""Refine the primitive tube with continuous elliptical walls and tissue PBR."""
import sys, math, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
from math import sin, cos, pi
import build_batch01 as core
import build_batch02 as tube
from tissue_materials import tissue

ROOT='Heart_03_PrimitiveHeartTube'
# A gently bent pre-loop tube, with regional swellings and a narrower AV canal.
RADII=[(0,.28),(.10,.30),(.23,.34),(.34,.215),(.48,.40),(.59,.37),(.72,.30),(.84,.235),(1,.18)]
def surface(t,a,f):
    r=tube.interpolate(RADII,t)*f
    # Ellipticity and slight asymmetry avoid a lathed, bead-like silhouette.
    c=Vector((.10*sin(pi*t)-.04*sin(2*pi*t),.065*sin(pi*t),-1.6+3.2*t))
    r*=1+.012*sin(3*a+9*t)*sin(pi*t)
    return c+Vector((r*cos(a),r*(.84+.05*sin(pi*t))*sin(a),0))
def normal(t,a,f):
    dt=surface(t+.0001,a,f)-surface(t-.0001,a,f)
    da=surface(t,a+.0001,f)-surface(t,a-.0001,f)
    return da.cross(dt).normalized()
def panel(name,lo,hi,f0,f1,a0,mat,parent,label):
    m=32;indices=list(range(lo,hi+1));n=len(indices);stride=m+1;size=n*stride
    verts=[];norms=[];uvs=[];faces=[]
    for k,f in enumerate([f0,f1]):
        for index in indices:
            t=index/200
            for j in range(m+1):
                a=a0+pi*j/m
                verts.append(surface(t,a,f));norms.append(normal(t,a,f)*(1 if k else -1));uvs.append((a/(2*pi),t))
    for k in range(2):
        for i in range(n-1):
            for j in range(m):
                a=k*size+i*stride+j
                face=(a,a+1,a+1+stride,a+stride);faces.append(face if k else tuple(reversed(face)))
    surface_count=len(faces)
    for i in [0,n-1]:
        for j in range(m):
            a=i*stride+j;faces.append((a,a+1,a+1+size,a+size))
    for j in [0,m]:
        for i in range(n-1):
            a=i*stride+j;faces.append((a,a+stride,a+stride+size,a+size))
    obj=core.mesh(name,verts,faces,mat,parent,label)
    normals=[]
    for poly in obj.data.polygons:
        poly.use_smooth=poly.index<surface_count
        for li in poly.loop_indices:
            vi=obj.data.loops[li].vertex_index
            normals.append(norms[vi] if poly.index<surface_count else poly.normal.copy())
            obj.data.uv_layers.active.data[li].uv=uvs[vi]
    obj.data.normals_split_custom_set(normals)
    return obj

core.setup();root=core.group(ROOT)
mats={'muscle':tissue('Tube_Myocardium',(.28,.048,.061),'muscle'),
      'jelly':tissue('Tube_CardiacJelly',(.48,.27,.16),'jelly'),
      'lining':tissue('Tube_Endocardium',(.40,.17,.15),'lining')}
for segment,label,lo,hi in tube.SEGMENTS:
    parent=core.group(segment,root)
    for layer,f0,f1,key in [('Myocardium',.80,1,'muscle'),('CardiacJelly',.65,.80,'jelly'),('Endocardium',.59,.65,'lining')]:
        for side,a0 in [('Posterior',0),('Anterior',pi)]:
            panel(f'{layer}_{segment}_{side}',lo,hi,f0,f1,a0,mats[key],parent,f'{label} — {layer.lower()}, {side.lower()} panel')
# Use the established exporter with a matching refined-asset preview setup.
original_presentation=core.presentation
def presentation(root):
    original_presentation(root);scene=bpy.context.scene
    scene.cycles.samples=40;scene.view_settings.exposure=-1.4
    scene.camera.location=(.12,-.62,.15)
    scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler()
    scene.camera.data.ortho_scale=.25
core.presentation=presentation
core.export(root,3)
p=core.BASE/'manifests'/(ROOT+'.json');data=json.loads(p.read_text())
data.update(revision='tube-v2',status='original_educational_refinement',batch=2,
    reference='https://www.youtube.com/watch?v=a0qyagIgBPw',
    limitations=['Illustrative pre-loop tube, not a segmented specimen or validated anatomy',
    'Teaching regions and layer thickness are enlarged; embryo context and vascular tributaries absent',
    'Static model; no contraction or growth deformation'],
    changes=['Continuous normals across region cuts','Elliptical, gently asymmetric tube with regional swellings',
    'Open continuous lumen with three removable tissue layers','Nine embedded colour, roughness and normal maps'])
p.write_text(json.dumps(data,indent=2))

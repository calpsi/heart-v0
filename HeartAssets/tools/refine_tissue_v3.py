"""Sequential, restartable refinement of the app's 16 independently selectable assets.
Always starts from immutable pre-revision backups; never compounds deformation.
"""
import bpy,bmesh,sys,json,shutil,math,argparse
from pathlib import Path
from math import sin,cos,pi
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from tissue_v3_materials import PALETTE
P=argparse.ArgumentParser();P.add_argument('--stage',type=int,required=True);a=P.parse_args(sys.argv[sys.argv.index('--')+1:]);number=a.stage
assert 1<=number<=16
a.sculpt = number>=5
B=core.BASE;REV=B/'refinements/tissue-v3';REV.mkdir(exist_ok=True)
mp=next((B/'manifests').glob(f'Heart_{number:02}_*.json'));name=json.loads(mp.read_text())['asset']
backup=REV/'before'/name;backup.mkdir(parents=True,exist_ok=True)
for source in [mp,B/'blender'/(name+'.blend'),core.EXPORT/(name+'.usdz'),B/'previews'/(name+'_assembled.png'),B/'previews'/(name+'_layers.png')]:
    if source.exists() and not (backup/source.name).exists():shutil.copy2(source,backup/source.name)
manifest=json.loads((backup/mp.name).read_text())
bpy.ops.wm.open_mainfile(filepath=str(backup/(name+'.blend')))
bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[name]
mats={};kinds={}
def mat(kind):
    if kind not in mats:
        m=bpy.data.materials.new('Pending_'+kind);m.diffuse_color=(*PALETTE[kind][0],1);mats[kind]=m
    return mats[kind]
def replace(old,new):
    new.parent=old.parent
    new['part_id']=old.name;new['display_name']=old.get('display_name',old.name)
    oldname=old.name;bpy.data.objects.remove(old,do_unlink=True);new.name=oldname
    return new

def context_shape(o):
    # Folded, volumetric embryonic context rather than an almost planar oval.
    for v in o.data.vertices:
        x,y,z=v.co/core.S
        v.co.y=core.S*(y*2.6+.11*(x*x)+.035*cos(z*3.2)*cos(x*2.8))
    mod=o.modifiers.new('Smooth folded context','SUBSURF');mod.levels=1
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)

if number<=2:
    for o in list(root.children_recursive):
        if o.type=='MESH' and 'Context' in o.name:
            context_shape(o)
            if number==2:o.location.y+=.30*core.S
    if number==1:
        for ident,a0,a1,r,w,d,y in [
            ('CardiogenicCrescent',-.15*pi,1.15*pi,1.07,.25,.205,-.13),
            ('AngioblasticCord_L',.52*pi,1.13*pi,1.075,.047,.047,-.34),
            ('AngioblasticCord_R',-.13*pi,.48*pi,1.075,.047,.047,-.34)]:
            old=bpy.data.objects[ident];vs=[];fs=[];n=144;m=40
            for i in range(n+1):
                t=i/n;theta=a0+(a1-a0)*t;taper=.18+.82*sin(pi*t)**.5
                for j in range(m):
                    b=2*pi*j/m
                    irregular=1+.055*sin(5*theta+.7)+.025*cos(11*theta+2*b)
                    radius=r+w*cos(b)*taper*irregular
                    vs.append((radius*cos(theta),y+d*sin(b)*taper*irregular+.045*cos(theta*2),.22+radius*sin(theta)))
            for i in range(n):
                for j in range(m):
                    q=i*m+j;qq=i*m+(j+1)%m;fs.append((q,qq,qq+m,q+m))
            fs += [tuple(reversed(range(m))),tuple(n*m+j for j in range(m))]
            new=core.mesh(ident+'_new',vs,fs,mat('mesoderm' if ident=='CardiogenicCrescent' else 'cord'),old.parent,old.get('display_name',ident))
            replace(old,new)
    else:
        # Increase radial/longitudinal sampling without rounding the removable cut edges.
        for old in list(root.children_recursive):
            if old.type!='MESH' or 'Context' in old.name:continue
            ident=old.name;side=-1 if '_L_' in ident else 1;a0=0 if ident.endswith('Posterior') else pi
            r0,r1= (.218,.29) if ident.startswith('Myocardium') else ((.154,.214) if ident.startswith('CardiacJelly') else (.123,.150))
            vs=[];fs=[];n=120;m=40;stride=m+1;size=(n+1)*stride
            for radius in (r0,r1):
                for i in range(n+1):
                    t=i/n;z=-1.3+2.6*t;cx=side*(.52+.11*cos(2*pi*t))
                    for j in range(m+1):
                        theta=a0+pi*j/m
                        r=radius*(1+.14*sin(pi*t)**2)*(1+.028*sin(11*t+3*theta)*sin(pi*t))
                        vs.append((cx+r*cos(theta),r*sin(theta)*(.94+.08*sin(pi*t))+.055*sin(2*pi*t),z))
            for k in range(2):
                for i in range(n):
                    for j in range(m):
                        q=k*size+i*stride+j;f=(q,q+1,q+stride+1,q+stride);fs.append(f if k else tuple(reversed(f)))
            for i in (0,n):
                for j in range(m):
                    q=i*stride+j;fs.append((q,q+1,q+1+size,q+size))
            for j in (0,m):
                for i in range(n):
                    q=i*stride+j;fs.append((q,q+stride,q+stride+size,q+size))
            new=core.mesh(ident+'_new',vs,fs,mat('muscle'),old.parent,old.get('display_name',ident));replace(old,new)

for o in root.children_recursive:
    if o.type!='MESH':continue
    key=(o.name+' '+' '.join(s.material.name for s in o.material_slots if s.material)).lower()
    kind='muscle'
    if 'endoderm' in key:kind='endoderm'
    elif 'neural' in key:kind='neural'
    elif 'angioblastic' in key or 'pending_cord' in key:kind='cord'
    elif 'crescent' in key or 'mesoderm' in key:kind='mesoderm'
    elif any(t in key for t in ['jelly','cushion','spongiosa']):kind='jelly'
    elif any(t in key for t in ['fibrosa','chord_','ligament']):kind='fibrous'
    elif any(t in key for t in ['endocard','lining','leaflet','cusp','flap','fossa','primum']):kind='lining'
    kinds[o.name]=kind
    o.data.materials.clear();o.data.materials.append(mat(kind))
    if a.sculpt and number in (5,12):
        # A common smooth deformation retains the fit between removable walls and septa.
        # Depart from a perfectly circular shell with asymmetric chamber distension.
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            xx=x*(1+.10*cos(2.4*z)+.025*sin(3*y))+.035*sin(2*z)
            yy=y*(1+.10*cos(2.3*z)+.035*sin(2*x))
            zz=z+.040*sin(2.4*x)*cos(2*y)
            # Shallow tissue folds rather than a completely planar atrial membrane.
            if 'SeptumPrimum' in o.name:
                xx+=.008*sin(12*y+2*z)*sin(8*z)
            v.co=o.matrix_world.inverted()@(core.S*Vector((xx,yy,zz)))
    if a.sculpt and number==6:
        # Softly irregular cushion/canal contours, with a common field on both fusion halves.
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            xx=x*(1+.06*cos(3*y))+.02*sin(4*y)
            yy=y*(1+.05*cos(4*x))+.018*sin(3*x)
            zz=z*(1+.12*sin(2*x)*cos(3*y))+.018*cos(5*x)*sin(3*y)
            v.co=o.matrix_world.inverted()@(core.S*Vector((xx,yy,zz)))
    if a.sculpt and number in (7,9,10,11,13,14):
        # Refine only the lower ventricular contour; leave upper diagnostic connections in place.
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            t=max(0,min(1,(-.5-z)/.8 if number==13 else (.1-z)/1.3));t=t*t*(3-2*t)
            xx=x*(1-.12*t)+.045*t*(1-.5*min(abs(x),1))
            yy=y*(1+.08*sin(2*x)*t)
            zz=z-.10*t*t*math.exp(-x*x/.5)
            v.co=o.matrix_world.inverted()@(core.S*Vector((xx,yy,zz)))
    if a.sculpt and number in (8,15,16):
        # Gentle vessel irregularity, coherent across complementary cut panels and alternatives.
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            if number==8:
                t=max(0,min(1,(1.4-z)/.5))
                xx=x*(1+.02*cos(2*z)*t);yy=y*(1+.04*sin(3*z)*t)+.01*sin(3*z)*t
            else:
                xx=x+.012*sin(3*z);yy=y+.006*sin(2*x)*sin(2*z)
            v.co=o.matrix_world.inverted()@(core.S*Vector((xx,yy,z)))
    # World-coherent tiny relief moves mating panels together; no independent normal displacement.
    # Keep diagnostic apertures and attachment positions unchanged in the later teaching assets.
    if number<=4:
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            p.y+=core.S*.0022*sin(23*x+7*z)*sin(19*z-5*x)
            v.co=o.matrix_world.inverted()@p
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(o.name,'nonmanifold')
    if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
    assert bm.calc_volume(signed=True)>0,(o.name,'invalid volume')
    bm.to_mesh(o.data);bm.free()

from bake_tissue_v3 import bake
bake([o for o in root.children_recursive if o.type=='MESH'],kinds,name)

# Export every alternative state; rendering hides only the current teaching snapshot.
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
bpy.data.orphans_purge(do_recursive=True)
scene=bpy.context.scene;scene.cycles.samples=40;scene.render.resolution_x=1200;scene.render.resolution_y=1200
scene.view_settings.exposure=-1.15
if number<=2:
    scene.camera.location=(.29,-.64,.21);scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.ortho_scale=.285
# Slightly tighter key: broad wet highlights with enough shading to reveal depth.
for o in scene.objects:
    if o.type=='LIGHT' and 'Key' in o.name:o.data.size=.22

def display(state,cutaway):
    for part in manifest['parts']:
        o=bpy.data.objects[part['id']]
        hide=(part.get('state',state)!=state) or (cutaway and part['id'].endswith('_Anterior'))
        o.hide_render=hide;o.hide_set(hide)
state=manifest.get('defaultState');cut=manifest.get('defaultCutaway',False)
display(state,cut)
bpy.ops.wm.save_as_mainfile(filepath=str(B/'blender'/(name+'.blend')))
scene.render.filepath=str(B/'previews'/(name+'_assembled.png'));bpy.ops.render.render(write_still=True)
thumb=('Stage'+f'{number:02}') if number<=10 else ('Anomaly'+f'{number-10:02}')
shutil.copy2(scene.render.filepath,core.PROJECT/'heart v3/Assets.xcassets'/(thumb+'.imageset')/(thumb+'.png'))
if number==1:
    bpy.data.objects['Endoderm_Context'].location.y+=.075;bpy.data.objects['NeuralPlate_Context'].location.y+=.035;bpy.data.objects['VascularPrecursors'].location.y-=.045
elif manifest.get('states'):
    display(manifest['states'][-1]['id'],True)
else:display(state,True)
scene.render.filepath=str(B/'previews'/(name+'_layers.png'));bpy.ops.render.render(write_still=True)
manifest['revision']='tissue-v3';manifest['contourRefinement']=bool(a.sculpt);manifest['status']='original_educational_refinement'
manifest['appearanceChanges']=['Embedded 2048px colour, roughness and tangent-normal atlases baked from continuous 3D tissue fields','Irregular warm tissue mottling and fine surface relief','Nonmetallic moist highlights','UV coverage on every surface; original selectable part IDs retained']
if number<=2:manifest['appearanceChanges'].append('Rebuilt early tissue volumes and folded context')
if a.sculpt and number==6:manifest['appearanceChanges'].append('Softly irregular cushion and canal contours, preserving fused/unfused openings')
if a.sculpt and number==5:manifest['appearanceChanges'].append('Asymmetric atrial contour and shallow primum folds; all teaching apertures retained')
if a.sculpt and number>=7:manifest['appearanceChanges'].append('Coherent organic contour refinement; existing anatomical topology and diagnostic openings retained')
manifest['appearanceLimit']='Illustrative tissue finish, not specimen-derived or anatomically validated photorealism.'
mp.write_text(json.dumps(manifest,indent=2))
progressfile=REV/'progress.json';progress=json.loads(progressfile.read_text()) if progressfile.exists() else {'revision':'tissue-v3','stages':{}}
geometry_revision = ('early-stage rebuild' if number<=2 else 'existing refined form with subtle relief' if number<=4 else
    'asymmetric atrial contour and membrane folds' if number in (5,12) else 'organic cushion and canal contours' if number==6 else
    'lower ventricular contour refinement' if number in (7,9,10,11,13,14) else 'gentle vessel contour refinement')
progress['stages'][str(number)]={'asset':name,'status':'exported; pending full integration validation','geometry':geometry_revision,'materials':len(mats)}
progress['nextStage']=next((i for i in range(1,17) if str(i) not in progress['stages']),None)
progress['nextContourStage']=next((i for i in range(5,17) if not json.loads(next((B/'manifests').glob(f'Heart_{i:02}_*.json')).read_text()).get('contourRefinement')),None)
progress['integrationStatus']='final app rebuild and runtime validation pending'
progressfile.write_text(json.dumps(progress,indent=2))
print('TISSUE V3 COMPLETE',name,flush=True)

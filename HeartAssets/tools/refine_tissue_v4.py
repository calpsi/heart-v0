"""Refine existing teaching meshes without changing their selectable anatomy IDs.
Starts from a durable v3 snapshot. Geometry stays an educational illustration.
"""
import bpy, bmesh, json, sys, shutil, argparse, math
from pathlib import Path
from math import sin, cos, pi, sqrt
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_batch01 as core
from tissue_v3_materials import PALETTE
parser=argparse.ArgumentParser();parser.add_argument('--stage',type=int,required=True)
number=parser.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
assert 1<=number<=16
B=core.BASE;REV=B/'refinements/tissue-v4';REV.mkdir(parents=True,exist_ok=True)
mp=next((B/'manifests').glob(f'Heart_{number:02}_*.json'));name=json.loads(mp.read_text())['asset']
backup=REV/'before'/name;backup.mkdir(parents=True,exist_ok=True)
for source in [mp,B/'blender'/(name+'.blend'),core.EXPORT/(name+'.usdz'),B/'previews'/(name+'_assembled.png'),B/'previews'/(name+'_layers.png')]:
    if source.exists() and not (backup/source.name).exists():shutil.copy2(source,backup/source.name)
manifest=json.loads((backup/mp.name).read_text())
bpy.ops.wm.open_mainfile(filepath=str(backup/(name+'.blend')))
bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[name]
changes=[]
if number==1:
    # Shared low-frequency curvature gives the whole cardiogenic field a spatial saddle.
    # It is a tissue field at this age, not a miniature four-chamber heart.
    for o in root.children_recursive:
        if o.type!='MESH':continue
        for v in o.data.vertices:
            p=o.matrix_world@v.co;x,y,z=p/core.S
            p.y+=core.S*(.17*x*x-.11*(z-.25)**2+.035*x*z)
            v.co=o.matrix_world.inverted()@p
    changes.append('Curved cardiogenic tissue field with continuous saddle depth across neighbouring tissues')
if number in (2,3,4):
    # A fine bevel gives exposed cut faces a readable thickness instead of a razor edge.
    # Keep the lumen and independent layer topology; clamp prevents narrow layers collapsing.
    for o in root.children_recursive:
        if o.type!='MESH' or 'Context' in o.name:continue
        bpy.context.view_layer.objects.active=o
        mod=o.modifiers.new('Soft tissue cut margin','BEVEL');mod.width=.00022;mod.segments=3
        mod.limit_method='ANGLE';mod.angle_limit=.65;mod.use_clamp_overlap=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    changes.append('Rounded exposed cut margins with preserved hollow lumens and removable tissue layers')
if number in (7,11):
    # Replace six isolated ellipsoids with tapered curved muscular ridges following
    # the chamber's inner ellipsoid. Each ridge stays one independently selectable part.
    for old in list(root.children_recursive):
        if not old.name.startswith('Trabecula_'):continue
        ident=old.name;k=int(ident[-1])-1;side=-1 if '_R' in ident else 1
        vs=[];fs=[];segments=72;sides=16
        def centre(t):
            z=-.91+1.00*t+.055*k
            x=side*(.25+.185*k+.12*sin(pi*t)+.035*sin(2*pi*t+k))
            y=.69*sqrt(max(.02,1-(x/1.07)**2-((z+.15)/1.07)**2))-.025+.055*abs(2*t-1)**8
            # Same lower ventricular contour as the existing v3 wall.
            q=max(0,min(1,(.1-z)/1.3));q=q*q*(3-2*q)
            return Vector((x*(1-.12*q)+.045*q*(1-.5*min(abs(x),1)),
                           y*(1+.08*sin(2*x)*q),z-.10*q*q*math.exp(-x*x/.5)))
        for i in range(segments+1):
            t=i/segments;c=centre(t)
            tangent=(centre(min(1,t+.001))-centre(max(0,t-.001))).normalized()
            across=tangent.cross(Vector((0,1,0))).normalized();normal=across.cross(tangent).normalized()
            radius=(.006+.047*sin(pi*t)**.65)*(1+.10*sin(7*pi*t+k))
            for j in range(sides):
                angle=2*pi*j/sides
                vs.append(tuple(c+across*(cos(angle)*radius)+normal*(sin(angle)*radius*.82)))
        for i in range(segments):
            for j in range(sides):
                a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
        fs.extend([tuple(reversed(range(sides))),tuple(segments*sides+j for j in range(sides))])
        # A short muscular side bridge branches into the neighbouring wall;
        # its distal end is buried in myocardium, avoiding floating capped rods.
        base=len(vs);branch_segments=36
        def branch_centre(t):
            c=centre(.38+.32*t)
            c.x+=side*.14*t*t
            c.y+=.055*t*t
            c.z+=.06*t
            return c
        for i in range(branch_segments+1):
            t=i/branch_segments;c=branch_centre(t)
            tangent=(branch_centre(min(1,t+.001))-branch_centre(max(0,t-.001))).normalized()
            across=tangent.cross(Vector((0,1,0))).normalized();normal=across.cross(tangent).normalized()
            radius=.033*(1-.80*t)+.008*sin(pi*t)
            for j in range(sides):
                angle=2*pi*j/sides;vs.append(tuple(c+across*cos(angle)*radius+normal*sin(angle)*radius))
        for i in range(branch_segments):
            for j in range(sides):
                a=base+i*sides+j;b=base+i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
        fs.extend([tuple(reversed(range(base,base+sides))),tuple(base+branch_segments*sides+j for j in range(sides))])
        parent=old.parent;label=old.get('display_name',ident)
        m=bpy.data.materials.new('Pending_muscle')
        new=core.mesh(ident+'_refined',vs,fs,m,parent,label)
        bpy.data.objects.remove(old,do_unlink=True);new.name=ident
        new['part_id']=ident
        bpy.context.view_layer.objects.active=new
        remesh=new.modifiers.new('Continuous branching muscle','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.00045
        bpy.ops.object.modifier_apply(modifier=remesh.name)
        smooth=new.modifiers.new('Soften trabecular junction','SMOOTH');smooth.factor=.65;smooth.iterations=3
        bpy.ops.object.modifier_apply(modifier=smooth.name)
        for face in new.data.polygons:face.use_smooth=True
    changes.append('Six curved branching trabecular ridges with embedded wall attachments instead of detached oval nodules')

if number>=5:
    edge_parts=0
    for o in root.children_recursive:
        if o.type!='MESH' or not any(tag in o.name for tag in ('Wall','Septum','Leaflet','Cusp')):continue
        bpy.context.view_layer.objects.active=o
        edge_parts+=1
        mod=o.modifiers.new('Soft dissected tissue edge','BEVEL');mod.width=.00016;mod.segments=2
        mod.limit_method='ANGLE';mod.angle_limit=.8;mod.use_clamp_overlap=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    if edge_parts:changes.append('Subtle rounded dissection margins on chamber walls, septa and valve tissue')

kinds={}
for o in root.children_recursive:
    if o.type!='MESH':continue
    key=o.name.lower();kind='muscle'
    if 'endoderm' in key:kind='endoderm'
    elif 'neural' in key:kind='neural'
    elif 'angioblastic' in key or 'vascularprecursor' in key:kind='cord'
    elif 'crescent' in key or 'mesoderm' in key:kind='mesoderm'
    elif any(t in key for t in ['jelly','cushion','spongiosa','septalcontribution']):kind='jelly'
    elif any(t in key for t in ['fibrosa','chord_','ligament']):kind='fibrous'
    elif any(t in key for t in ['endocard','lining','leaflet','cusp','flap','fossa','primum','membranous','subaortic','subpulmonary']):kind='lining'
    kinds[o.name]=kind
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(o.name,'nonmanifold')
    if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
    assert bm.calc_volume(signed=True)>0
    bm.to_mesh(o.data);bm.free()
from bake_tissue_v4 import bake
bake([o for o in root.children_recursive if o.type=='MESH'],kinds,name)
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
bpy.data.orphans_purge(do_recursive=True)
scene=bpy.context.scene;scene.cycles.samples=40;scene.render.resolution_x=1200;scene.render.resolution_y=1200
scene.view_settings.exposure=-1.15
if number<=2:
    scene.camera.location=(.36,-.64,.26);scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.ortho_scale=.285

def display(state,cutaway):
    for part in manifest['parts']:
        o=bpy.data.objects[part['id']]
        hide=part.get('state',state)!=state or (cutaway and part['id'].endswith('_Anterior'))
        o.hide_render=hide;o.hide_set(hide)
state=manifest.get('defaultState');display(state,manifest.get('defaultCutaway',False))
bpy.ops.wm.save_as_mainfile(filepath=str(B/'blender'/(name+'.blend')))
scene.render.filepath=str(B/'previews'/(name+'_assembled.png'));bpy.ops.render.render(write_still=True)
thumb=('Stage'+f'{number:02}') if number<=10 else ('Anomaly'+f'{number-10:02}')
shutil.copy2(scene.render.filepath,core.PROJECT/'heart v3/Assets.xcassets'/(thumb+'.imageset')/(thumb+'.png'))
if number==1:
    bpy.data.objects['Endoderm_Context'].location.y+=.075;bpy.data.objects['NeuralPlate_Context'].location.y+=.035;bpy.data.objects['VascularPrecursors'].location.y-=.045
elif manifest.get('states'):display(manifest['states'][-1]['id'],True)
else:display(state,True)
scene.render.filepath=str(B/'previews'/(name+'_layers.png'));bpy.ops.render.render(write_still=True)
manifest['revision']='tissue-v4';manifest['detailChanges']=changes+['Directional fine tissue grain and broader, less plastic surface highlights; three embedded PBR maps']
mp.write_text(json.dumps(manifest,indent=2))
progressfile=REV/'progress.json';progress=json.loads(progressfile.read_text()) if progressfile.exists() else {'revision':'tissue-v4','stages':{}}
progress['stages'][str(number)]={'asset':name,'status':'exported; validation pending','changes':manifest['detailChanges']}
progressfile.write_text(json.dumps(progress,indent=2));print('TISSUE V4 COMPLETE',name,flush=True)

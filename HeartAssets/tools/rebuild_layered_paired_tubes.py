"""Original layered teaching reconstruction; not a segmentation of a specimen.
Build a reviewable candidate before replacing the application's current asset.
"""
import sys, json, math, shutil
from pathlib import Path
import bpy, bmesh
from mathutils import Vector
from math import sin, cos, pi, exp
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
import build_batch02 as tube
from bake_layered_tissue import bake

NAME='Heart_02_PairedHeartTubes'
OUT=core.BASE/'refinements/layered-tissue'
OUT.mkdir(parents=True,exist_ok=True)
BACK=OUT/'before'/NAME;BACK.mkdir(parents=True,exist_ok=True)
for source in [core.BASE/'blender'/(NAME+'.blend'),core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.BASE/'previews'/(NAME+'_layers.png')]:
    if not (BACK/source.name).exists():shutil.copy2(source,BACK/source.name)
manifest=json.loads((BACK/(NAME+'.json')).read_text())
bpy.ops.wm.open_mainfile(filepath=str(BACK/(NAME+'.blend')))
bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[NAME]
for obj in list(root.children_recursive):
    if obj.type=='MESH' and obj.name!='Endoderm_Context':bpy.data.objects.remove(obj,do_unlink=True)
context=bpy.data.objects['Endoderm_Context']
ys=[v.co.y for v in context.data.vertices];mid=(min(ys)+max(ys))/2
for v in context.data.vertices:
    v.co.y=mid+(v.co.y-mid)*.18
pending=bpy.data.materials.new('Pending')
RADII=[(0,.27),(.10,.30),(.22,.35),(.34,.23),(.48,.42),(.59,.39),(.72,.31),(.84,.24),(1,.19)]

def surface(t,a,boundary):
    r=.095+.125*sin(pi*max(0,min(1,t)))**1.3+.018*sin(3*pi*t)**2
    envelope=sin(pi*t)**2
    outer=r*(1+.045*sin(3*a+7*t)*envelope+.012*sin(7*a-13*t)*envelope)
    muscle_inner=outer-r*(.15+.025*cos(2*a+5*t))
    cavity=r*(.46+.065*cos(2*a-3*t)+.025*sin(3*a+8*t))
    lining_outer=cavity+r*.035
    radius=[cavity,lining_outer,muscle_inner,outer][boundary]
    eccentricity=int(boundary<2)
    cx=direction*(.49+.12*sin(2*pi*t)-.065*sin(pi*t))
    cy=.11*sin(pi*t)+direction*.065*sin(2*pi*t)
    return Vector((cx+radius*cos(a)+eccentricity*.012*envelope,
                   cy+radius*(.84+.06*sin(pi*t))*sin(a),-1.25+2.5*t))

def normal(t,a,b):
    dt=surface(t+.00001,a,b)-surface(t-.00001,a,b)
    da=surface(t,a+.00001,b)-surface(t,a-.00001,b)
    return da.cross(dt).normalized()

kinds={'Endoderm_Context':'endoderm'};cut_faces={'Endoderm_Context':10**9};quality=[]
for segment,label,lo,hi,direction in [('L','Left tube',0,160,-1),('R','Right tube',0,160,1)]:
    parent=bpy.data.objects['Tube_'+segment]
    for layer,b0,b1,kind in [('Myocardium',2,3,'muscle'),('CardiacJelly',1,2,'jelly'),('Endocardium',0,1,'lining')]:
        for side,a0,span in [('Posterior',-pi/6,4*pi/3),('Anterior',7*pi/6,2*pi/3)]:
            ident=f'{layer}_{segment}_{side}';verts=[];normals=[];faces=[]
            m=40;n=hi-lo+1;stride=m+1;size=n*stride
            for b in [b0,b1]:
                for index in range(lo,hi+1):
                    t=index/160
                    for j in range(m+1):
                        a=a0+span*j/m
                        verts.append(surface(t,a,b));normals.append(normal(t,a,b)*(-1 if b==b0 else 1))
            for k in range(2):
                for i in range(n-1):
                    for j in range(m):
                        a=k*size+i*stride+j;face=(a,a+1,a+stride+1,a+stride)
                        faces.append(face if k else tuple(reversed(face)))
            count=len(faces)
            for i in [0,n-1]:
                for j in range(m):
                    a=i*stride+j;faces.append((a,a+1,a+1+size,a+size))
            for j in [0,m]:
                for i in range(n-1):
                    a=i*stride+j;faces.append((a,a+stride,a+stride+size,a+size))
            obj=core.mesh(ident,verts,faces,pending,parent,f'{label} — {layer.lower()}, {side.lower()} panel')
            loopnormals=[]
            for face in obj.data.polygons:
                face.use_smooth=face.index<count
                loopnormals.extend(normals[v] if face.index<count else face.normal.copy() for v in face.vertices)
            obj.data.normals_split_custom_set(loopnormals)
            bm=bmesh.new();bm.from_mesh(obj.data)
            assert all(e.is_manifold for e in bm.edges),ident
            assert bm.calc_volume(signed=True)>0,ident
            bm.free();kinds[ident]=kind;cut_faces[ident]=count

# Numerically check every sampled ring: ordered nested layers and a patent lumen.
minimum_gap=100
for i in range(201):
    for j in range(96):
        t=i/200;a=j*2*pi/96
        for b in range(3):
            gap=(surface(t,a,b+1)-surface(t,a,b)).dot(Vector((cos(a),sin(a),0)))
            assert gap>0,(t,a,b,gap)
            minimum_gap=min(minimum_gap,gap*core.S)
expected={p['id'] for p in manifest['parts']}
assert expected=={o.name for o in root.children_recursive if o.type=='MESH'}
bake([o for o in root.children_recursive if o.type=='MESH'],kinds,NAME,cut_faces)
# Retain the original camera and lights, avoiding duplicate illumination.
scene=bpy.context.scene;scene.cycles.samples=40;scene.view_settings.exposure=-1.15
scene.camera.location=(.20,-.65,.23)
scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=.25
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(OUT/(NAME+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
scene.render.filepath=str(OUT/(NAME+'_assembled.png'));bpy.ops.render.render(write_still=True)
for o in root.children_recursive:
    if o.name.endswith('_Anterior'):o.hide_render=True
scene.render.filepath=str(OUT/(NAME+'_layers.png'));bpy.ops.render.render(write_still=True)
# Staggered peel reveals all three nested layers in one learning illustration.
for o in root.children_recursive:
    if o.type!='MESH':continue
    if o.name.endswith('_Anterior'):o.hide_render=False;o.location.x=.065;o.location.y=-.02
    if o.name.startswith('Endocardium'):o.location.x-=.045
    if o.name=='Endoderm_Context':o.hide_render=True
scene.camera.data.ortho_scale=.35
scene.render.filepath=str(OUT/(NAME+'_separated.png'));bpy.ops.render.render(write_still=True)
manifest.update(revision='layered-tissue-2',presentationNote='Simplified paired channels · connecting vessels and embryo omitted',detailChanges=[
    'Rebuilt tapered, undulating paired tubes with independently contoured lining, cardiac jelly and myocardial mantle',
    'Independent myocardial envelope and shared matching layer interfaces',
    'Distinct cut-surface and intact-tissue colour, roughness and normal maps',
    '13 existing selectable parts retained; tapered paired tubes follow the supplied video silhouette; 120-degree removable anterior windows'],
    appearanceLimit='Original teaching reconstruction; not scan-derived or validated photorealism. Layer thickness and region cuts enlarged for learning.',
    referenceSources=['https://www.nature.com/articles/s42003-022-03153-x','https://hdbratlas.org/organ-systems/cardiovascular-system/heart/heart-HE.html'],
    referenceVideo={'url':'https://www.facebook.com/share/r/1CzT4A9CPz/','viewed':True,'reason':'Sampled 12 frames across the supplied 51.78-second local video; paired tubes referenced at 0.15 seconds'},
    geometryChecks={'watertightParts':13,'positiveVolumeParts':13,'nestedBoundarySamples':201*96,'minimumLayerThicknessMetres':minimum_gap})
for o in root.children_recursive:
    if o.type=='MESH':o.data.calc_loop_triangles()
manifest['triangles']=sum(len(o.data.loop_triangles) for o in root.children_recursive if o.type=='MESH')
(OUT/(NAME+'.json')).write_text(json.dumps(manifest,indent=2))
print('LAYERED TUBE CANDIDATE COMPLETE',flush=True)

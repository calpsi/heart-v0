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

NAME='Heart_03_PrimitiveHeartTube'
OUT=core.BASE/'refinements/layered-tissue'
OUT.mkdir(parents=True,exist_ok=True)
BACK=OUT/'before'/NAME;BACK.mkdir(parents=True,exist_ok=True)
for source in [core.BASE/'blender'/(NAME+'.blend'),core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.BASE/'previews'/(NAME+'_layers.png')]:
    if not (BACK/source.name).exists():shutil.copy2(source,BACK/source.name)
manifest=json.loads((BACK/(NAME+'.json')).read_text())
core.setup();root=core.group(NAME)
pending=bpy.data.materials.new('Pending')
RADII=[(0,.27),(.10,.30),(.22,.39),(.34,.23),(.48,.47),(.59,.41),(.72,.31),(.84,.24),(1,.19)]

def surface(t,a,boundary):
    r=tube.interpolate(RADII,t)
    envelope=sin(pi*t)**2
    # Common broad contour; inner interfaces have their own shape rather than
    # being scaled copies. A thin lining surrounds a deliberately patent lumen.
    outer=r*(1+.035*sin(3*a+5*t)*envelope+.012*sin(7*a-17*t)*envelope)
    muscle_inner=outer-r*(.13+.025*cos(2*a+4*t)+.025*sin(pi*t)**2)
    cavity=r*(.49+.065*cos(2*a-3*t)+.035*sin(3*a+8*t))
    cavity+=r*.018*sin(9*a+11*t)*envelope
    lining_outer=cavity+r*.035
    radius=[cavity,lining_outer,muscle_inner,outer][boundary]
    # Offset endocardial conduit within the matrix, without artificial gaps.
    eccentricity=(1 if boundary<2 else 0)
    cx=.18*sin(pi*t)-.065*sin(2*pi*t)
    cy=.13*sin(pi*t)+.035*sin(2*pi*t)
    x=cx+radius*cos(a)+eccentricity*.035*envelope
    y=cy+radius*(.80+.065*sin(pi*t))*sin(a)-eccentricity*.02*envelope
    return Vector((x,y,-1.4+2.8*t))

def normal(t,a,b):
    dt=surface(t+.00001,a,b)-surface(t-.00001,a,b)
    da=surface(t,a+.00001,b)-surface(t,a-.00001,b)
    return da.cross(dt).normalized()

kinds={};cut_faces={};quality=[]
for segment,label,lo,hi in tube.SEGMENTS:
    parent=core.group(segment,root)
    for layer,b0,b1,kind in [('Myocardium',2,3,'muscle'),('CardiacJelly',1,2,'jelly'),('Endocardium',0,1,'lining')]:
        for side,a0,span in [('Posterior',-pi/6,4*pi/3),('Anterior',7*pi/6,2*pi/3)]:
            ident=f'{layer}_{segment}_{side}';verts=[];normals=[];faces=[]
            m=48;n=hi-lo+1;stride=m+1;size=n*stride
            for b in [b0,b1]:
                for index in range(lo,hi+1):
                    t=index/200
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
bake([o for o in root.children_recursive if o.type=='MESH'],kinds,NAME,cut_faces)
core.presentation(root)
scene=bpy.context.scene;scene.cycles.samples=40;scene.view_settings.exposure=-1.15
scene.camera.location=(.28,-.62,.30)
scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=.26
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
    if o.name.startswith('Endocardium'):o.location.x-=.065
scene.camera.data.ortho_scale=.35
scene.render.filepath=str(OUT/(NAME+'_separated.png'));bpy.ops.render.render(write_still=True)
manifest.update(revision='layered-tissue-2',presentationNote='Unfolded region map · tissue layers enlarged for learning',detailChanges=[
    'Reconstructed non-concentric lumen, thin endocardial lining and variable-thickness cardiac jelly',
    'Fuller regional swellings and shorter, gently curved single-tube silhouette; shared matching layer interfaces',
    'Distinct cut-surface and intact-tissue colour, roughness and normal maps',
    '36 existing selectable parts and all regional boundaries retained; anterior removal opens a 120-degree viewing window rather than flattening the tube into a half-shell'],
    appearanceLimit='Original teaching reconstruction; not scan-derived or validated photorealism. Layer thickness and region cuts enlarged for learning.',
    referenceSources=['https://www.nature.com/articles/s42003-022-03153-x','https://hdbratlas.org/organ-systems/cardiovascular-system/heart/heart-HE.html'],
    referenceVideo={'url':'https://www.facebook.com/share/r/1CzT4A9CPz/','viewed':True,'reason':'Reviewed 12 extracted frames of the attached 51.78-second video. Surface treatment informed by the reference; internal anatomy remains an illustrative reconstruction.'},
    geometryChecks={'watertightParts':36,'positiveVolumeParts':36,'nestedBoundarySamples':201*96,'minimumLayerThicknessMetres':minimum_gap})
for o in root.children_recursive:
    if o.type=='MESH':o.data.calc_loop_triangles()
manifest['triangles']=sum(len(o.data.loop_triangles) for o in root.children_recursive if o.type=='MESH')
(OUT/(NAME+'.json')).write_text(json.dumps(manifest,indent=2))
print('LAYERED TUBE CANDIDATE COMPLETE',flush=True)

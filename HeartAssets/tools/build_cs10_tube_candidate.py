"""CS10-inspired regional candidate, not a specimen segmentation.
Topology follows HDBR CS10 descriptions; all dimensions remain illustrative.
Do not automatically install this candidate over the app's existing regional map.
"""
import bpy,bmesh,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from bake_layered_tissue import bake
OUT=core.BASE/'refinements/cs10-tube';OUT.mkdir(parents=True,exist_ok=True)
NAME='CS10_PrimitiveTube_Candidate'
m=core.setup();root=core.group(NAME);kinds={};cuts={}

def shell(name,fn,lo,hi,a0,a1,kind,label):
 n=96;jmax=48;v=[];f=[];stride=jmax+1;size=(n+1)*stride
 for b in [lo,hi]:
  for i in range(n+1):
   for j in range(jmax+1):v.append(fn(i/n,a0+(a1-a0)*j/jmax,b))
 for k in range(2):
  for i in range(n):
   for j in range(jmax):
    a=k*size+i*stride+j;face=(a,a+1,a+stride+1,a+stride);f.append(face if k else tuple(reversed(face)))
 count=len(f)
 for i in [0,n]:
  for j in range(jmax):
   a=i*stride+j;f.append((a,a+1,a+1+size,a+size))
 for j in ([] if abs(a1-a0-2*pi)<1e-8 else [0,jmax]):
  for i in range(n):
   a=i*stride+j;f.append((a,a+stride,a+stride+size,a+size))
 o=core.mesh(name,v,f,m[kind],root,label)
 for p in o.data.polygons:p.use_smooth=p.index<count
 kinds[name]=kind;cuts[name]=count
 return o

def center(t):
 # Lower inlet limb and upper outlet limb bend toward anatomical right.
 return Vector((-.16+.33*t+.16*sin(pi*t),-.22*sin(pi*t),-1.05+2.1*t))
def radii(t):
 # Separate geometry for lining, extracellular cuff and myocardial cloak.
 waist=math.exp(-((t-.52)/.12)**2)
 lumen=.20+.055*cos(2*pi*t)-.080*waist
 jelly=.10+.055*sin(pi*t)**2
 return [lumen,lumen+.018,lumen+.018+jelly,lumen+.018+jelly+.055]
def surface(t,a,b):
 r=radii(t)[b];return center(t)+Vector((r*cos(a),r*.84*sin(a),0))
for layer,lo,hi,kind in [('Endocardium',0,1,'lining'),('CardiacJelly',1,2,'jelly')]:
 for side,a0,a1 in [('Anterior',pi,2*pi),('Posterior',0,pi)]:
  shell(layer+'_'+side,surface,lo,hi,a0,a1,kind,layer+' — '+side.lower()+' teaching panel')
# A dorsal gap through the myocardial cloak: no invented complete dorsal cylinder.
shell('Myocardium_Anterior',surface,2,3,pi,2*pi,'muscle','Myocardial cloak — anterior teaching panel')
for side,a0,a1 in [('L',0,pi*.32),('R',pi*.68,pi)]:
 shell('Myocardium_Dorsal_'+side,surface,2,3,a0,a1,'muscle','Myocardial cloak — dorsal rim '+side)
# Dorsal attachments are interrupted at the inter-ventricular waist.
# Ribbon strips continue from both cloak margins toward a pharyngeal support plane.
for pole,t0,t1 in [('Caudal',.03,.38),('Cranial',.66,.97)]:
 for side,a in [('L',pi*.32),('R',pi*.68)]:
  def curtain(u,v,b,a=a,t0=t0,t1=t1):
   t=t0+(t1-t0)*u;p=surface(t,a,2+b)
   return p+Vector((0,v*(.64-p.y),0))
  # Reuse closed two-boundary grid; v spans a linear ribbon rather than an angle.
  shell('DorsalMesocardium_'+pole+'_'+side,curtain,0,1,0,1,'muscle','Dorsal mesocardial attachment — '+pole.lower()+' '+side)
# Paired vessels at both poles, kept hollow. These are regional continuations;
# their distal cut ends do not claim a complete extra-cardiac vascular network.
for pole,t,signz in [('Inflow',0,-1),('Outflow',1,1)]:
 for side,sign in [('L',-1),('R',1)]:
  start=center(t)
  def vessel(u,a,b,start=start,sign=sign,signz=signz,t=t):
   p=start+Vector((sign*.62*u,.12*u,signz*.32*u))
   tangent=Vector((sign*.62,.12,signz*.32)).normalized()
   axis=Vector((0,1,0));axis=(axis-tangent*axis.dot(tangent)).normalized();other=axis.cross(tangent)
   r=(.12-.035*u)+b*.025
   return p+r*(cos(a)*axis+sin(a)*other)
  shell(pole+'_'+side,vessel,0,1,0,2*pi,'lining','Paired '+pole.lower()+' vessel — '+side+' (distal teaching cut)')

# Weld only coincident seams; do not smooth away the lumen or dorsal attachment gap.
checks=[]
for o in root.children_recursive:
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8)
 # Full-circumference vessel has duplicate radial side caps: remove those faces first.
 if o.name.startswith(('Inflow','Outflow')):
  deg=[f for f in bm.faces if f.calc_area()<1e-12];bmesh.ops.delete(bm,geom=deg,context='FACES')
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
 assert all(e.is_manifold for e in bm.edges),(o.name,'nonmanifold')
 assert bm.calc_volume(signed=True)>0,o.name
 bm.to_mesh(o.data);bm.free()
 checks.append(dict(id=o.name,closedPositiveVolume=True))
# Analytical nested-boundary check, not a physiological wall-thickness measurement.
assert min(radii(i/200)[0] for i in range(201))>.05
assert all(all(b>a for a,b in zip(radii(i/200),radii(i/200)[1:])) for i in range(201))
core.presentation(root)
scene=bpy.context.scene;scene.cycles.samples=16
scene.render.resolution_x=1000;scene.render.resolution_y=1000
scene.camera.location=(.18,-.55,.20);scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.ortho_scale=.24
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'_geometry.blend')))
# Cut indices may change at welded full vessel seams; only the open-ended cuff
# and myocardium carry explicit teaching-cut surface material.
for o in root.children_recursive:
 if o.name.startswith(('Inflow','Outflow')):cuts[o.name]=set()
bake(list(root.children_recursive),kinds,NAME,cuts)
for mat in bpy.data.materials:
 if mat.use_nodes:
  for node in mat.node_tree.nodes:
   if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.16
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root
usd=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(usd),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
scene.render.filepath=str(OUT/'ventral.png');bpy.ops.render.render(write_still=True)
for o in root.children_recursive:
 if o.name.endswith('_Anterior'):o.hide_render=True
scene.render.filepath=str(OUT/'cutaway.png');bpy.ops.render.render(write_still=True)
for o in root.children_recursive:o.hide_render=False
scene.camera.location=(.12,.55,.22);scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=str(OUT/'dorsal.png');bpy.ops.render.render(write_still=True)
(OUT/'validation.json').write_text(json.dumps(dict(geometryChecksPassed=True,installed=False,parts=checks,minimumLumenRadius=min(radii(i/200)[0] for i in range(201))*core.S,source='https://hdbratlas.org/hikspoors-pdf/JH_CS10_new_description.html',limitations=['Original parametric regional geometry, not source vertices','Dorsal attachment dimensions and overall proportions require registration','Vessel junctions overlap and require lumen-union review before installation','Foregut, transverse septum and distal vascular plexuses absent','No histological wall-thickness measurement'],sha256=hashlib.sha256(usd.read_bytes()).hexdigest()),indent=2))
print('CS10 CANDIDATE COMPLETE',flush=True)

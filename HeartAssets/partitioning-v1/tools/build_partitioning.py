"""Original, enlarged educational heart cutaways; run with Blender --background.
Coordinates: X anatomical left, -Y anterior, Z superior; length unit metre.
Four snapshots, not a simulation. Outputs kept separate from existing app assets.
"""
import bpy,bmesh,math,json,sys,argparse
import numpy as np
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi,sqrt
BASE=Path(__file__).resolve().parents[1]
S=.065
parser=argparse.ArgumentParser();parser.add_argument('--stage',type=int,default=1)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);stage=args.stage
NAMES=['01_Week04_EarlyPartitioning','02_Weeks05-06_CushionFusion','03_Week07_VentricularClosure','04_Week08_FourChambers']
NAME='HeartPartition_'+NAMES[stage-1]
for f in ['blender','glb','usdz','previews','manifests','textures']: (BASE/f).mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.unit_settings.system='METRIC'
root=bpy.data.objects.new(NAME,None);scene.collection.objects.link(root)
parts=[]
anterior_continuations={}

def apply(o,m):
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
def delete(o):bpy.data.objects.remove(o,do_unlink=True)
def sphere(name,c,r,seg=48,rings=32):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=tuple(S*v for v in c))
 o=bpy.context.object;o.name=name;o.scale=tuple(S*v for v in r)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return o

def texture(name,color,rough=.36,cut=False):
 n=1024;y,x=np.mgrid[:n,:n]/n;rng=np.random.default_rng(181)
 f=np.zeros_like(x);h=np.zeros_like(x)
 for freq,amp in [(3,.32),(7,.20),(19,.12),(47,.055),(113,.026),(241,.011)]:
  phase=rng.uniform(0,2*pi,2);q=np.sin(2*pi*(x*freq+y*freq*.3)+phase[0])*np.cos(2*pi*(y*freq-x*freq*.17)+phase[1]);f+=amp*q;h+=amp/freq*q
 fiber=np.sin(2*pi*(x*145+y*20+.5*np.sin(y*25)))
 pores=np.maximum(0,np.sin(x*310+np.sin(y*170))*np.sin(y*330+np.cos(x*150)))**9
 rgba=np.ones((n,n,4),dtype=np.float32)
 for k,c in enumerate(color):rgba[:,:,k]=np.clip(c*(1+.31*f-.13*pores+(.026 if cut else .012)*fiber),0,1)
 roughpixels=np.ones_like(rgba);roughpixels[:,:,:3]=np.clip(rough+.08*f[:,:,None]+.035*pores[:,:,None],.22,.65)
 h=.075*h+.000024*fiber+.00007*pores
 gy,gx=np.gradient(h);normal=np.stack([-gx*n,-gy*n,np.ones_like(x)],axis=2);normal/=np.linalg.norm(normal,axis=2)[:,:,None]
 normalpixels=np.ones_like(rgba);normalpixels[:,:,:3]=normal*.5+.5
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=0
 bs.inputs['Coat Weight'].default_value=.12;bs.inputs['Coat Roughness'].default_value=.25
 for suffix,pixels,target in [('BaseColor',rgba,'Base Color'),('Roughness',roughpixels,'Roughness'),('Normal',normalpixels,None)]:
  im=bpy.data.images.new(name+'_'+suffix,width=n,height=n)
  if suffix!='BaseColor':im.colorspace_settings.name='Non-Color'
  im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(BASE/'textures'/(im.name+'.png'));im.file_format='PNG';im.save();im.pack()
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
  if target:m.node_tree.links.new(tex.outputs['Color'],bs.inputs[target])
  else:
   nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.65;m.node_tree.links.new(tex.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
 return m
muscle=texture('Myocardium_Rose',(.48,.16,.17),.35)
lining=texture('Endocardium_Warm',(.64,.29,.28),.31)
cutmat=texture('Cut_Myocardium',(.76,.43,.37),.44,True)
venous=texture('Atrial_Exterior_Plum',(.31,.24,.39),.35)
cushionmat=texture('Cushion_PearlRose',(.79,.53,.43),.39)
valvemat=texture('Valve_IvoryRose',(.83,.65,.53),.32)
allm=[muscle,lining,cutmat,venous]

def slots(o,mats=allm,index=0):
 o.data.materials.clear()
 for m in mats:o.data.materials.append(m)
 for p in o.data.polygons:p.material_index=index

def uv(o):
 if not o.data.uv_layers:o.data.uv_layers.new(name='UVMap')
 layer=o.data.uv_layers.active
 for p in o.data.polygons:
  # Stable planar mapping; each surface receives a broad non-repeating tissue field.
  axis=max(range(3),key=lambda a:abs(p.normal[a]))
  for li in p.loop_indices:
   v=o.matrix_world@o.data.vertices[o.data.loops[li].vertex_index].co/S
   coords=(v.y,v.z) if ('Septum' in o.name or 'Septal' in o.name) and abs(p.normal.y)<.99 else (v.x,v.z)
   layer.data[li].uv=((coords[0]+2)/4,(coords[1]+2)/4)

def register(o,name,label,mat=None,role='anatomy'):
 o.name=name;o.parent=root
 if mat:slots(o,[mat])
 for p in o.data.polygons:p.use_smooth=True
 uv(o);o['part_id']=name;o['display_name']=label;o['role']=role
 parts.append({'id':name,'label':label,'role':role})
 continuation=anterior_continuations.pop(o.as_pointer(),None)
 if continuation is not None:
  register(continuation,name+'_AnteriorContinuation',label+' — anterior continuation',mat,role='removable_front')
  continuation.hide_render=True;continuation.hide_set(True)
 return o

def boolean(o,c,operation='DIFFERENCE',remove=True):
 m=o.modifiers.new(operation,'BOOLEAN');m.operation=operation;m.solver='EXACT';m.object=c;apply(o,m)
 if remove:delete(c)
 return o

def cube(c,r):
 bpy.ops.mesh.primitive_cube_add(size=1,location=tuple(S*v for v in c));o=bpy.context.object;o.scale=tuple(S*v for v in r);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);slots(o,index=2);return o

def union_blobs(name,blobs,voxel=.022):
 obs=[sphere('temporary',c,r,40,28) for c,r in blobs]
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();o=obs[0];o.name=name
 m=o.modifiers.new('Organic continuous surface','REMESH');m.mode='VOXEL';m.voxel_size=S*voxel;m.use_smooth_shade=True;apply(o,m)
 m=o.modifiers.new('Surface relaxation','SMOOTH');m.factor=.7;m.iterations=4;apply(o,m)
 return o

# Atria are superior/posterior; anatomical right appears on image left.
# Fetal LV/RV thicknesses are similar; avoid imposing adult LV hypertrophy.
centres=[(-.44,.04,.88),(.44,.09,.93),(-.43,0,-.59),(.43,.015,-.68)]
radii=[(.66,.59,.62),(.64,.57,.59),(.68,.64,.83),(.65,.63,.90)]
outer=union_blobs('OuterWall',list(zip(centres,radii))+[((-.45,0,.22),(.44,.50,.50)),((.45,0,.23),(.42,.49,.49)),((0,.03,.25),(.70,.60,.65))])
slots(outer)
envelope=bpy.data.objects.new('TissueEnvelope',outer.data.copy());scene.collection.objects.link(envelope);envelope.matrix_world=outer.matrix_world.copy()
# Keep inserted tissue just beneath the epicardial surface; avoid coincident outer faces.
for v in envelope.data.vertices:
 v.co=envelope.matrix_world.inverted()@((envelope.matrix_world@v.co)*.985)
for p in outer.data.polygons:
 if (outer.matrix_world@p.center).z>S*.37:p.material_index=3
innercentres=[(-.40,.035,.89),(.40,.085,.93),(-.36,0,-.57),(.36,.015,-.66)]
innerradii=[(.56,.46,.49),(.54,.44,.46),(.54,.49,.67),(.52,.48,.72)]
inner=union_blobs('Lumen',list(zip(innercentres,innerradii))+[((-.43,0,.20),(.27,.35,.47)),((.43,0,.20),(.27,.35,.47)),((0,0,.23),(.63,.36,.30)),((0,.03,.28),(.37,.40,.52))],.019)
slots(inner,index=1)
boolean(outer,inner,remove=False)
# Removable cut panels and permanent posterior walls. Teaching cut at y=-0.15.
for upper,label in [(True,'AtrialWall'),(False,'VentricularWall')]:
 for front,side in [(False,'Posterior'),(True,'Anterior')]:
  o=bpy.data.objects.new(label+'_'+side,outer.data.copy());scene.collection.objects.link(o);o.matrix_world=outer.matrix_world.copy()
  boolean(o,cube((0,(-2.075 if front else 1.925),0),(8,3.85 if front else 4.15,8)),'INTERSECT')
  boolean(o,cube((0,0,2.175 if upper else -1.825),(8,8,3.65 if upper else 4.35)),'INTERSECT')
  register(o,label+'_'+side,('Atrial' if upper else 'Ventricular')+' wall — '+side.lower(),role='removable_front' if front else 'wall')
  # Keep planar cut edges flat.
  for p in o.data.polygons:
   if p.material_index==2:p.use_smooth=False
  if front:o.hide_render=True;o.hide_set(True)
delete(outer)

cut_index=0
def clip_internal_tissue(o):
 global cut_index
 cut_y=-.135+.007*cut_index;cut_index+=1
 boolean(o,envelope,'INTERSECT',False)
 # Preserve the complementary tissue half for full-wall exports.
 front=bpy.data.objects.new(o.name+'_AnteriorContinuation',o.data.copy());scene.collection.objects.link(front);front.matrix_world=o.matrix_world.copy()
 bm=bmesh.new();bm.from_mesh(front.data)
 point=front.matrix_world.inverted()@Vector((0,cut_y*S,0))
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-8,plane_co=point,plane_no=Vector((0,1,0)),clear_inner=False,clear_outer=True)
 edges=[e for e in bm.edges if e.is_boundary]
 if edges:bmesh.ops.holes_fill(bm,edges=edges,sides=0)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(front.data);bm.free()
 if len(front.data.vertices):anterior_continuations[o.as_pointer()]=front
 else:delete(front)
 bm=bmesh.new();bm.from_mesh(o.data)
 point=o.matrix_world.inverted()@Vector((0,cut_y*S,0))
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-8,plane_co=point,plane_no=Vector((0,1,0)),clear_inner=True,clear_outer=False)
 edges=[e for e in bm.edges if e.is_boundary]
 if edges:bmesh.ops.holes_fill(bm,edges=edges,sides=0)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 return o

# Muscular septum grows from floor; a superior communication remains until closure.
height=[.43,.59,.65,.65][stage-1];z=[-.91,-.76,-.70,-.70][stage-1]
o=sphere('Muscular',(.015,.03,z),(.125,.62,height));clip_internal_tissue(o);register(o,'MuscularInterventricularSeptum','Muscular interventricular septum',muscle)
# Primum descends from the atrial roof. Primum opening is a real inferior gap.
bottom=[.57,.24,.24,.24][stage-1];top=1.46
primum=sphere('Primum',(.045,.08,(bottom+top)/2),(.052,.54,(top-bottom)/2+.07))
if stage>=2:
 # Ostium secundum, through the sagittal sheet (X axis).
 boolean(primum,sphere('OstiumSecundum',(.045,.18,1.09),(.30,.18,.16)))
clip_internal_tissue(primum);register(primum,'SeptumPrimum','Septum primum'+(' / fetal flap' if stage>=3 else ''),lining)
if stage>=3:
 secundum=sphere('Secundum',(-.10,.065,.98),(.055,.54,.52))
 boolean(secundum,sphere('ForamenOvale',(-.10,-.035,.70),(.32,.30,.27)))
 clip_internal_tissue(secundum);register(secundum,'SeptumSecundum','Septum secundum / foramen ovale rim',muscle)
 # Slightly bowed primum/flap is on the anatomical left. Offset openings form an oblique fetal route.
# Dorsal/ventral cushions approach across AP direction, not across left/right.
for dorsal in [True,False]:
 y=(.25 if dorsal else -.22) if stage==1 else .0125
 c=sphere('Cushion',(0,y,.245),(.245,.19 if stage==1 else .40,.15))
 # two halves meet at y=.0125 in fused stages.
 if stage>=2:
  boolean(c,cube((0,2.0125 if dorsal else -1.9875,0),(8,4,8)),'INTERSECT')
 clip_internal_tissue(c)
 register(c,('Dorsal' if dorsal else 'Ventral')+'EndocardialCushion',('Dorsal (superior)' if dorsal else 'Ventral (inferior)')+' endocardial cushion',cushionmat)
if stage>=3:
 o=sphere('Closure',(.035,.05,.016),(.091,.42,.23));clip_internal_tissue(o);register(o,'MembranousSeptalClosure','Superior septal closure — cushion and outlet contributions',cushionmat)

# Modest trabecular ridges are attached to the posterior luminal wall.
def tube(name,coords,r,mat,label):
 verts=[];faces=[];n=len(coords);ns=12
 for i,c in enumerate(coords):
  tangent=(Vector(coords[min(n-1,i+1)])-Vector(coords[max(0,i-1)])).normalized()
  u=tangent.cross(Vector((0,1,0))).normalized();v=tangent.cross(u).normalized()
  rad=r*(.16+.84*sin(pi*i/(n-1))**.45)
  for j in range(ns):verts.append(tuple(S*(Vector(c)+rad*(cos(2*pi*j/ns)*u+sin(2*pi*j/ns)*v))))
 for i in range(n-1):
  for j in range(ns):a=i*ns+j;b=i*ns+(j+1)%ns;faces.append((a,b,b+ns,a+ns))
 faces.extend([tuple(reversed(range(ns))),tuple((n-1)*ns+j for j in range(ns))])
 me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(name,me);scene.collection.objects.link(o)
 return register(o,name,label,mat)
rng=np.random.default_rng(573)
for side,(c,r) in enumerate(zip(innercentres[2:],innerradii[2:])):
 for k in range(11):
  coords=[];base=(k%6-2.5)*.12;phase=rng.uniform(0,6);slope=rng.uniform(-.18,.18)
  lo=rng.uniform(-.57,-.32);hi=rng.uniform(.18,.48)
  for j in range(32):
   t=j/31;xx=base+.055*sin(2*pi*t+phase)+slope*(t-.5);zz=lo+(hi-lo)*t
   xx=max(-.41,min(.41,xx));q=max(.04,1-(xx/r[0])**2-(zz/r[2])**2)
   coords.append((c[0]+xx,c[1]+r[1]*sqrt(q)+.025-.047*sin(pi*t)**.6,c[2]+zz))
  tube(('RV' if side==0 else 'LV')+f'_Trabecula_{k+1:02}',coords,(.022 if stage==1 else .029)*rng.uniform(.7,1.2),muscle,('Right' if side==0 else 'Left')+' ventricular trabecula')
# Developing AV leaflets, with primitive subvalvar attachments in final snapshot.
if stage>=2:
 for side,cx,count,title in [(-1,-.43,3,'Tricuspid'),(1,.43,2,'Mitral')]:
  for k in range(count):
   a=2*pi*k/count+.2
   verts=[];faces=[];nr=13;na=22
   for i in range(nr):
    t=i/(nr-1)
    for j in range(na):
     u=j/(na-1);ang=a+(u-.5)*(2*pi/count*.91);r=.25*(1-.61*t)
     verts.append((S*(cx+r*cos(ang)),S*(.02+r*.97*sin(ang)),S*(.22-(.14 if stage==2 else .27)*t+.025*sin(pi*u))))
   for i in range(nr-1):
    for j in range(na-1):v=i*na+j;faces.append((v,v+1,v+1+na,v+na))
   me=bpy.data.meshes.new('Leaflet');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new(title+f'Leaflet{k+1}',me);scene.collection.objects.link(o)
   m=o.modifiers.new('Soft developing leaflet','SUBSURF');m.levels=2;apply(o,m)
   m=o.modifiers.new('Leaflet thickness','SOLIDIFY');m.thickness=.012*S;apply(o,m)
   register(o,title+f'_Leaflet_{k+1}',title+' valve primordium',valvemat)
   if stage==4:
    tip=(cx+.098*cos(a),.02+.098*sin(a),-.045);pap=(cx+.19*cos(a),.21,-.37)
    tube(title+f'_ChordalAttachment_{k+1}',[tip,((tip[0]+pap[0])/2,(tip[1]+pap[1])/2,-.23),pap],.008,valvemat,'Developing chordal attachment')
    o=sphere('Papillary',(pap[0],.35,-.55),(.075,.22,.23),40,28);register(o,title+f'_PapillaryPrimordium_{k+1}','Papillary muscle primordium',muscle)
delete(inner);delete(envelope)
# Recalculate outward normals and validate each closed tissue surface.
checks=[]
for p in parts:
 o=bpy.data.objects[p['id']];bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data)
 checks.append({'part':o.name,'vertices':len(bm.verts),'faces':len(bm.faces),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),'volume_m3':bm.calc_volume(signed=True)});bm.free()
 uv(o)
 # Flat cut caps and sharp-normal boundaries prevent black interpolation artifacts.
 for face in o.data.polygons:
  if face.normal.y<-.999:face.use_smooth=False
 o.data.set_sharp_from_angle(angle=.9)
 assert len(o.data.vertices)>0, 'Empty mesh: '+o.name
 assert checks[-1]['nonmanifold_edges']==0, 'Open mesh: '+o.name
# Export only visible cutaway parts; full removable front is retained in .blend.
# Full exports include anterior wall panels and internal septal continuations.
meshes=[bpy.data.objects[p['id']] for p in parts]
def select(front=False):
 bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
 for o in meshes:
  o.hide_set(False);o.hide_render=False;o.select_set(front or o.get('role')!='removable_front')
 bpy.context.view_layer.objects.active=root
select(False)
bpy.ops.export_scene.gltf(filepath=str(BASE/'glb'/(NAME+'_Cutaway.glb')),export_format='GLB',use_selection=True,export_yup=True,export_extras=True)
bpy.ops.wm.usd_export(filepath=str(BASE/'usdz'/(NAME+'_Cutaway.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
select(True)
bpy.ops.export_scene.gltf(filepath=str(BASE/'glb'/(NAME+'_Full.glb')),export_format='GLB',use_selection=True,export_yup=True,export_extras=True)
bpy.ops.wm.usd_export(filepath=str(BASE/'usdz'/(NAME+'_Full.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
# Studio lighting approximates the reference viewport; no Tripo lighting is stored in FBX.
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=48;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=1600;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.22,.23,.25,1);scene.world.node_tree.nodes.get('Background').inputs[1].default_value=.40
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=-1.25
def aim(o,p=(0,0,0)):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(-.19,-.68,.14));cam=bpy.context.object;cam.name='PresentationCamera';aim(cam,(0,0,0));cam.data.type='ORTHO';cam.data.ortho_scale=.245;scene.camera=cam
for name,loc,power,size,color in [('Key',(-.28,-.38,.38),14,.30,(1,.83,.76)),('Fill',(.28,-.2,.08),8,.25,(.76,.83,1)),('Rim',(.1,.3,.3),18,.22,(1,.74,.62))]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color;aim(o)
for o in meshes:
 hidden=o.get('role')=='removable_front';o.hide_render=hidden;o.hide_set(hidden)
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True);bpy.context.view_layer.objects.active=root
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'blender'/(NAME+'.blend')))
manifest={'asset':NAME,'stage':stage,'age_basis':'approximate post-fertilization age; overlapping events, not a day-exact reconstruction','units':'metres','blender_axes':'+X anatomical left; -Y anterior; +Z superior','export_axes':'+X anatomical left; +Y superior; +Z anterior','scale':'enlarged teaching model, about 20 cm tall','parts':parts,'checks':checks,'limitations':['Original illustrative anatomy, not a specimen-derived reconstruction','Septation geometry simplified and thickness exaggerated for teaching','Outflow tract and vessels omitted to expose chamber partitioning','Fetal foramen ovale retained; no postnatal sealing implied','Static stages; no morph animation; stage 4 valve attachments are simplified primordia'],'export_note':'Cutaway exports omit removable anterior wall meshes. Full exports and blend retain walls plus anterior continuations of internal septa/cushions.'}
(BASE/'manifests'/(NAME+'.json')).write_text(json.dumps(manifest,indent=2))
scene.render.filepath=str(BASE/'previews'/(NAME+'.png'));bpy.ops.render.render(write_still=True)
print('COMPLETE',NAME,'parts',len(parts),'nonmanifold',sum(x['nonmanifold_edges'] for x in checks),flush=True)

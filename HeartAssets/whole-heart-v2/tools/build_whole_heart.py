"""Whole exterior embryonic heart series. Original illustrations, not specimen segmentation.
Blender +X anatomical left, -Y anterior, +Z cranial. All output in metres.
"""
import bpy,bmesh,math,json,sys,argparse
import numpy as np
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi
P=argparse.ArgumentParser();P.add_argument('--stage',type=int,required=True);a=P.parse_args(sys.argv[sys.argv.index('--')+1:]);stage=a.stage
B=Path(__file__).resolve().parents[1];S=.065
for p in ['blender','glb','usdz','fbx','textures','previews','manifests']:(B/p).mkdir(exist_ok=True)
N=['01_Week04_LoopedHeart','02_Weeks05-06_Remodeling','03_Week07_SeparatedOutflows','04_Week08_FourChamberExterior'][stage-1];NAME='WholeHeart_'+N
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.unit_settings.system='METRIC';parts=[]
root=bpy.data.objects.new(NAME,None);scene.collection.objects.link(root)
def apply(o,m):bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
def remove(o):bpy.data.objects.remove(o,do_unlink=True)
def texture(name,color,rough):
 n=1024;y,x=np.mgrid[:n,:n]/n;rng=np.random.default_rng(391);f=np.zeros_like(x);height=np.zeros_like(x)
 for freq,amp in [(2,.3),(5,.19),(13,.14),(31,.065),(73,.029),(179,.015)]:
  phase=rng.uniform(0,2*pi,2);wave=np.sin(2*pi*(x*freq+.22*y*freq)+phase[0])*np.cos(2*pi*(y*freq-.11*x*freq)+phase[1]);f+=amp*wave;height+=amp/freq*wave
 folds=np.sin(2*pi*(x*38+.7*np.sin(2*pi*y*3)+.23*np.sin(2*pi*y*9)))
 fine=np.sin(2*pi*(x*180+y*7+.5*np.sin(y*20)))
 veins=np.zeros_like(x)
 for i in range(7):
  track=(i+.4)/7+.031*np.sin(2*pi*y*(2+i%3)+i)+.008*np.sin(y*55+i)
  veins+=np.exp(-((x-track)/.0016)**2)*np.sin(pi*y)**4
 rgba=np.ones((n,n,4),np.float32)
 for k,c in enumerate(color):rgba[:,:,k]=np.clip(c*(1+.45*f-.10*veins+.02*folds),0,1)
 r=np.ones_like(rgba);r[:,:,:3]=np.clip(rough+.11*f[:,:,None]-.05*np.abs(folds[:,:,None]),.10,.45)
 height=.14*height+.00023*folds+.000028*fine-.00008*veins
 gy,gx=np.gradient(height);norm=np.stack([-gx*n,-gy*n,np.ones_like(x)],axis=2);norm/=np.linalg.norm(norm,axis=2)[:,:,None];nm=np.ones_like(rgba);nm[:,:,:3]=norm*.5+.5
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1);bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Metallic'].default_value=0;bs.inputs['Coat Weight'].default_value=.16;bs.inputs['Coat Roughness'].default_value=.2
 for suffix,pixels,target in [('BaseColor',rgba,'Base Color'),('Roughness',r,'Roughness'),('Normal',nm,None)]:
  im=bpy.data.images.new(name+'_'+suffix,width=n,height=n)
  if suffix!='BaseColor':im.colorspace_settings.name='Non-Color'
  im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(B/'textures'/(im.name+'.png'));im.file_format='PNG';im.save();im.pack()
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=im
  if target:m.node_tree.links.new(t.outputs['Color'],bs.inputs[target])
  else:
   nn=m.node_tree.nodes.new('ShaderNodeNormalMap');nn.inputs['Strength'].default_value=.62;m.node_tree.links.new(t.outputs['Color'],nn.inputs['Color']);m.node_tree.links.new(nn.outputs['Normal'],bs.inputs['Normal'])
 return m
mats={'muscle':texture('Whole_Myocardium',(.49,.17,.19),.29),'atrium':texture('Whole_AtrialTissue',(.33,.22,.36),.27),'artery':texture('Whole_ArterialTissue',(.63,.28,.24),.26),'vein':texture('Whole_VenousTissue',(.23,.24,.44),.25)}
def uv(o):
 if not o.data.uv_layers:o.data.uv_layers.new(name='UVMap')
 for p in o.data.polygons:
  for li in p.loop_indices:
   v=o.matrix_world@o.data.vertices[o.data.loops[li].vertex_index].co/S
   o.data.uv_layers.active.data[li].uv=((v.x+.29*v.y+2)/4,(v.z+.12*v.y+2)/5)
def register(o,name,label,material):
 o.name=name;o.parent=root;o.data.materials.clear();o.data.materials.append(material)
 for p in o.data.polygons:p.use_smooth=True
 uv(o);o['part_id']=name;o['display_name']=label;parts.append({'id':name,'label':label});return o
def sphere(c,r,rot=0):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=32,location=tuple(S*v for v in c));o=bpy.context.object;o.scale=tuple(S*v for v in r);o.rotation_euler.y=rot;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return o
def fuse(obs,voxel=.015,detail=True):
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();o=obs[0]
 m=o.modifiers.new('Continuous sculpted tissue','REMESH');m.mode='VOXEL';m.voxel_size=S*voxel;m.use_smooth_shade=True;apply(o,m)
 m=o.modifiers.new('Organic smoothing','SMOOTH');m.factor=.75;m.iterations=6;apply(o,m)
 if detail:
  tex=bpy.data.textures.new('Fine tissue folds','CLOUDS');tex.noise_scale=S*.095;tex.noise_depth=2
  m=o.modifiers.new('Fine surface relief','DISPLACE');m.texture=tex;m.strength=S*.009;m.mid_level=.5;apply(o,m)
 return o
# Ventricle ballooning and asymmetric apex, rather than a frontal four-lobed shell.
if stage==1:
 blobs=[((.34,-.03,-.35),(.70,.59,.70),-.25),((-.37,-.19,.0),(.44,.42,.58),.30),((-.31,-.06,.46),(.26,.31,.46),-.2),((.28,.27,.31),(.30,.32,.32),-.2)]
elif stage==2:
 blobs=[((.33,.025,-.45),(.63,.57,.85),-.22),((-.27,-.21,-.21),(.66,.49,.66),.23),((-.40,-.11,.29),(.31,.33,.48),-.17)]
else:
 blobs=[((.35,.04,-.48),(.61,.56,.91 if stage==3 else .98),-.24),((-.28,-.23,-.23),(.66,.48,.72),.28),((-.39,-.08,.31),(.30,.33,.48),-.12)]
if stage>=3:blobs.append(((.05,-.055,-.78),(.43,.40,.46),-.12))
vent=fuse([sphere(c,r,rot) for c,r,rot in blobs])
# Subtle anterior interventricular sulcus, growing more distinct across the stages.
for v in vent.data.vertices:
 w=vent.matrix_world@v.co; x,y,z=w/S
 if -.99<z<.35 and y<-.15:
  track=.08-.24*z+.03*sin(4*z);depth=(.014 if stage<3 else .023)*math.exp(-((x-track)/.045)**2)*sin(pi*(z+.99)/1.34)**.6
  w.y+=S*depth;v.co=vent.matrix_world.inverted()@w
register(vent,'VentricularMyocardium','Ventricular myocardium with leftward apex',mats['muscle'])
# Atria are behind and above the ventricles; auricles wrap around the arterial root.
if stage==1:
 atr=fuse([sphere((.20,.44,.67),(.57,.42,.47)),sphere((-.23,.43,.75),(.45,.37,.37))]);register(atr,'CommonAtrium','Common atrium / early right and left expansions',mats['atrium'])
else:
 for side in [-1,1]:
  cx=side*(.52 if stage>=3 else .47);cz=.54 if side==-1 else .65
  rr=(.50,.40,.49) if side==-1 else (.43,.38,.42)
  aur=[sphere((cx,.33,cz),rr,-side*.15),sphere((cx+side*.15,.045,cz+.06),((.30,.28,.24) if side<0 else (.23,.25,.17)),side*.4),sphere((cx+side*.12,-.15,cz+.15),((.24,.21,.16) if side<0 else (.18,.20,.12)),side*.7),sphere((cx+side*.01,-.27,cz+.19),((.17,.16,.11) if side<0 else (.13,.17,.09)),side*.5)]
  o=fuse(aur,.013);register(o,('Right' if side<0 else 'Left')+'AtriumAndAuricle',('Right' if side<0 else 'Left')+' atrial wall and appendage',mats['atrium'])
# Catmull-Rom vascular paths with a lumen, continuous fork junctions and rounded cut rims.
def samples(knots,n=14):
 out=[]
 for k in range(len(knots)-1):
  p0=Vector(knots[max(0,k-1)][:3]);p1=Vector(knots[k][:3]);p2=Vector(knots[k+1][:3]);p3=Vector(knots[min(len(knots)-1,k+2)][:3])
  for j in range(n):
   t=j/n;p=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t);r=knots[k][3]*(1-t)+knots[k+1][3]*t;out.append((p,r))
 out.append((Vector(knots[-1][:3]),knots[-1][3]));return out
def solid_tube(knots,factor=1,extend=(False,False)):
 path=samples(knots);verts=[];faces=[];ns=36
 if extend[0]:path[0]=(path[0][0]-(path[1][0]-path[0][0]).normalized()*.10,path[0][1])
 if extend[1]:path[-1]=(path[-1][0]+(path[-1][0]-path[-2][0]).normalized()*.10,path[-1][1])
 for i,(p,r) in enumerate(path):
  tangent=(path[min(len(path)-1,i+1)][0]-path[max(0,i-1)][0]).normalized();up=Vector((0,1,0))
  if abs(tangent.dot(up))>.95:up=Vector((1,0,0))
  u=tangent.cross(up).normalized();v=tangent.cross(u).normalized()
  for j in range(ns):verts.append(tuple(S*(p+r*factor*(u*cos(2*pi*j/ns)+v*sin(2*pi*j/ns)))))
 for i in range(len(path)-1):
  for j in range(ns):a=i*ns+j;b=i*ns+(j+1)%ns;faces.append((a,b,b+ns,a+ns))
 faces.extend([tuple(reversed(range(ns))),tuple((len(path)-1)*ns+j for j in range(ns))])
 me=bpy.data.meshes.new('VesselSurface');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('VesselWork',me);scene.collection.objects.link(o)
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();return o

def vessels(name,label,paths,mat):
 outer=fuse([solid_tube(k) for k in paths],.010,False)
 inside=[]
 for i,k in enumerate(paths):
  free=[]
  for endpoint in [k[0],k[-1]]:
   point=Vector(endpoint[:3]);joined=any((point-q).length<r*.95+endpoint[3]*.3 for j,other in enumerate(paths) if j!=i for q,r in samples(other))
   free.append(not joined)
  inside.append(solid_tube(k,.70,tuple(free)))
 inner=fuse(inside,.009,False)
 m=outer.modifiers.new('True vessel lumens','BOOLEAN');m.operation='DIFFERENCE';m.solver='EXACT';m.object=inner;apply(outer,m);remove(inner)
 return register(outer,name,label,mat)
if stage==1:
 vessels('CommonOutflow','Bulbus / common outflow and aortic sac branches',[
 [(-.38,-.08,.35,.26),(-.39,.0,.83,.235),(-.14,.03,1.15,.205),(.03,.08,1.37,.18)],
 [(.01,.08,1.29,.17),(-.18,.15,1.50,.14),(-.37,.17,1.68,.12)],
 [(.01,.08,1.30,.17),(.28,.16,1.47,.14),(.43,.2,1.65,.12)]],mats['artery'])
 vessels('SinusVenosusAndHorns','Sinus venosus and paired venous inflow stumps',[
 [(0,.58,.60,.20),(-.38,.66,.41,.16),(-.69,.62,.18,.13)],
 [(0,.58,.60,.20),(.39,.64,.40,.16),(.66,.61,.18,.13)]],mats['vein'])
elif stage==2:
 vessels('RemodelingOutflow','Remodeling common outlet / emerging arterial pathways',[
 [(-.30,-.11,.35,.26),(-.27,-.05,.85,.25),(-.07,.04,1.15,.235)],
 [(-.07,.04,1.06,.19),(.04,.13,1.42,.18),(.31,.30,1.60,.16),(.64,.43,1.40,.14),(.63,.49,1.06,.13)],
 [(-.12,-.06,1.00,.16),(-.35,-.02,1.30,.15),(-.64,.12,1.40,.115)]],mats['artery'])
 vessels('RightVenousInflow','Developing right caval inflow',[
 [(-.57,.38,.37,.15),(-.61,.39,.83,.16),(-.62,.43,1.30,.14)],
 [(-.57,.38,.42,.16),(-.54,.47,.01,.13),(-.62,.58,-.35,.12)]],mats['vein'])
 vessels('CommonPulmonaryVein','Common pulmonary venous entry',[[ (.48,.43,.65,.13),(.58,.68,.69,.11),(.80,.91,.72,.09)]],mats['artery'])
else:
 # Aorta is posterior/right of pulmonary root, arches toward anatomical left.
 vessels('AortaAndArch','Ascending aorta, arch, branches and descending stump',[
 [(.03,.035,.16,.21),(.025,.04,.76,.20),(.07,.14,1.29,.205),(.27,.28,1.53,.20),(.66,.39,1.45,.18),(.81,.43,1.08,.165),(.79,.47,.76,.155)],
 [(.15,.20,1.46,.12),(.04,.23,1.74,.115),(-.02,.24,1.92,.105)],
 [(.34,.30,1.53,.10),(.40,.32,1.84,.087)],
 [(.57,.37,1.50,.09),(.70,.40,1.77,.079)]],mats['artery'])
 vessels('PulmonaryTrunkAndArteries','Pulmonary trunk with left and right branches',[
 [(-.39,-.22,.28,.24),(-.31,-.27,.73,.215),(-.13,-.18,1.06,.19),(.04,-.025,1.18,.17)],
 [(.01,-.02,1.14,.145),(.34,.055,1.19,.13),(.63,.10,1.19,.11),(.93,.17,1.23,.10)],
 [(.005,-.01,1.14,.14),(-.28,.26,1.13,.115),(-.69,.39,1.06,.10),(-.95,.42,1.04,.09)]],mats['vein'])
 vessels('DuctusArteriosus','Fetal ductus arteriosus',[[ (.37,.06,1.18,.092),(.58,.22,1.25,.095),(.76,.40,1.27,.09)]],mats['vein'])
 vessels('SuperiorVenaCava','Superior caval inflow stump',[[(-.59,.40,.57,.17),(-.65,.43,1.00,.155),(-.72,.43,1.48,.135)]],mats['vein'])
 vessels('InferiorVenaCava','Inferior caval inflow stump',[[(-.54,.44,.26,.18),(-.58,.54,-.06,.15),(-.62,.62,-.39,.135)]],mats['vein'])
 for side in [-1,1]:
  for j in range(2):
   z=.61-j*.27
   vessels(('Right' if side<0 else 'Left')+'PulmonaryVein'+str(j+1),('Right' if side<0 else 'Left')+' pulmonary venous entry',[[ (.35+side*.18,.55,z,.095),(.35+side*.39,.72,z+.03,.085),(.35+side*.60,.84,z+.07,.07)]],mats['artery'])
# Mesh verification and portable exports, with independent anatomical entities.
checks=[]
for p in parts:
 o=bpy.data.objects[p['id']];bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data)
 c={'part':o.name,'vertices':len(bm.verts),'triangles':sum(len(f.verts)-2 for f in bm.faces),'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),'signed_volume':bm.calc_volume(signed=True)};bm.free();assert c['vertices'] and c['nonmanifold_edges']==0 and c['signed_volume']>0,c;checks.append(c)
 uv(o)
bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
for p in parts:bpy.data.objects[p['id']].select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.gltf(filepath=str(B/'glb'/(NAME+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_extras=True)
bpy.ops.wm.usd_export(filepath=str(B/'usdz'/(NAME+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
bpy.ops.export_scene.fbx(filepath=str(B/'fbx'/(NAME+'.fbx')),use_selection=True,object_types={'MESH','EMPTY'},path_mode='COPY',embed_textures=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y')
# Reference-style studio lighting and large, transparent catalogue renders.
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=True
scene.render.resolution_x=1400;scene.render.resolution_y=1700;scene.render.resolution_percentage=100;scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG'
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.18,.19,.22,1);scene.world.node_tree.nodes.get('Background').inputs[1].default_value=.45
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=-.8
bpy.ops.object.camera_add(location=(.25,-.59,.19));cam=bpy.context.object;cam.name='Camera_Anterior';cam.data.type='ORTHO';cam.data.ortho_scale=.28;scene.camera=cam
target=Vector((0,0,.017));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size,color in [('Key',(-.30,-.35,.4),11,.28,(1,.89,.82)),('Fill',(.31,-.18,.17),7,.25,(.80,.85,1)),('Rim',(.2,.32,.3),17,.23,(.93,.88,1))]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.data.color=color;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.select_all(action='DESELECT');root.select_set(True);bpy.context.view_layer.objects.active=root
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(B/'blender'/(NAME+'.blend')))
(B/'manifests'/(NAME+'.json')).write_text(json.dumps({'asset':NAME,'stage':stage,'age_basis':'approximate post-fertilization age','parts':parts,'checks':checks,'scope':'Whole exterior teaching model. Vessel lumens are hollow; chamber wall volumes are exterior sculptures, not a reconstructed internal septal anatomy. Use the complementary partitioning-v1 cutaways for interior teaching.','style':'Original PBR surface maps and studio lighting; Tripo references inspected, not re-used as anatomy','units':'metres','usd_axes':'Y-up, +X anatomical left, +Z anterior','limitations':['Illustrative reconstruction; not specimen segmented or clinically validated','Truncated vessels; body circulation is not modeled','Identification colors are not literal fetal oxygen saturation','Independent vessel assemblies overlap at anatomical attachments','No animation or growth rig']},indent=2))
for view,loc in [('Anterior',(.25,-.59,.19)),('Posterior',(-.24,.59,.19))]:
 cam.location=loc;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(B/'previews'/(NAME+'_'+view+'.png'));bpy.ops.render.render(write_still=True)
print('COMPLETE',NAME,len(parts),sum(c['triangles'] for c in checks),flush=True)

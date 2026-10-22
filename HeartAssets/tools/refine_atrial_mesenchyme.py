"""Add missing AV mesenchymal contributors to the regional atrial teaching model.
Original illustrative geometry: dimensions are NOT histological measurements.
Draft only; separate promotion after export and visual checks.
"""
import bpy,bmesh,sys,json,math,shutil,hashlib
from pathlib import Path
from mathutils import Vector
from pxr import Usd,UsdGeom,UsdShade
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,register
from bake_layered_tissue import bake
NAME='Heart_05_AtrialSeptation'; OUT=core.BASE/'refinements/atrial-mesenchyme';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=core.BASE/'blender'/(NAME+'.blend'); BACK=OUT/'before';BACK.mkdir(exist_ok=True)
for p in [SOURCE,core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.PROJECT/'heart v3/Resources/HeartModels.json']:
 if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/SOURCE.name));root=bpy.data.objects[NAME]
entry=next(a for a in json.loads((BACK/'HeartModels.json').read_text()) if a['id']==NAME)
core.parts=entry['parts'].copy()
for o in root.children_recursive:o.hide_set(False);o.hide_render=False
material=bpy.data.objects['CushionAnchor_Dorsal'].data.materials[0]
# Follow the existing primary opening's actual bore contour, stopping before
# the contour exits the primary septum. This is an enlarged teaching cap.
def inside(t):
 y=.52*math.sin(t);z=-.15+.58*math.cos(t)
 return (y/.66)**2+((z-.57)/.86)**2<.97
limit=max(t*math.pi/2000 for t in range(1001) if inside(t*math.pi/2000))
def cap_tube(name,points,radius,state,label,kind):
 vs=[];fs=[];sides=20
 for i,p in enumerate(points):
  p=Vector(p);t=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized()
  u=Vector((1,0,0));v=t.cross(u).normalized()
  for j in range(sides):vs.append(tuple((p+radius*(math.cos(j*2*math.pi/sides)*u+math.sin(j*2*math.pi/sides)*v))*core.S))
 for i in range(len(points)-1):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
 fs += [tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))]
 me=bpy.data.meshes.new(name+'Mesh');me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
 register(o,root,label,state,(.035,0,.025));kinds[name]=kind
 return o
kinds={o.name:('jelly' if 'Cushion' in o.name else 'lining' if 'Primum' in o.name else 'muscle') for o in root.children_recursive if o.type=='MESH'}
points=[(.03,.52*math.sin(-limit+2*limit*i/64),-.15+.58*math.cos(-limit+2*limit*i/64)) for i in range(65)]
cap_tube('MesenchymalCap_Early',points,.035,'early','Mesenchymal cap — primary septal free edge (enlarged)','jelly')
# Dorsal protrusion bridges posterior atrial context toward the AV cushion.
# It occupies the dorsal side, not the entire primary opening.
o=ball('DorsalMesenchymalProtrusion_Early',(.035,.46,-.12),(.115,.24,.24),material)
register(o,root,'Dorsal mesenchymal protrusion — early contribution (schematic)','early',(-.035,0,-.03));kinds[o.name]='jelly'
# Later myocardialized mesenchymal contribution at the inferior atrial rim.
# Kept distinct from the superior/posterior wall infolding.
o=ball('MesenchymalComplex_Later',(.015,.02,-.18),(.13,.44,.14),material)
register(o,root,'Joined mesenchymal complex — later inferior rim (schematic)','later',(.035,-.02,0));kinds[o.name]='muscle'
o=ball('DorsalContribution_Later',(.015,.46,-.10),(.13,.24,.24),material)
register(o,root,'Dorsal contribution — later muscularized rim (schematic)','later',(-.035,0,-.03));kinds[o.name]='muscle'
for p in core.parts:
 if p['id']=='SeptumSecundum_Later':p['label']='Right atrial infolding — simplified superior rim'
 bpy.data.objects[p['id']]['display_name']=p['label']
objects=[o for o in root.children_recursive if o.type=='MESH'];checks=[]
for o in objects:
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),o.name;assert bm.calc_volume(signed=True)>0,o.name;bm.to_mesh(o.data);bm.free()
 checks.append({'id':o.name,'closedPositiveVolume':True})
# Keep a pre-bake source checkpoint for reproducible iteration.
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'_geometry.blend')))
bake(objects,kinds,NAME,{o.name:set() for o in objects})
# Existing exported assets use modest surface relief; avoid amplifying it here.
for m in bpy.data.materials:
 if m.use_nodes:
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.25
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root
candidate=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(candidate),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
usd=Usd.Stage.Open(str(candidate));assert len([p for p in usd.Traverse() if p.IsA(UsdGeom.Mesh)])==len(objects)
ids={str(a.Get()) for p in usd.Traverse() for a in p.GetAttributes() if a.GetName()=='userProperties:part_id'};assert ids=={p['id'] for p in core.parts}
entry['parts']=core.parts;entry['presentationNote']='Regional septation diagram with mesenchymal cap and dorsal contribution; enlarged tissues and discrete early/later states, not a measured embryonic reconstruction.'
(OUT/'catalog-entry.json').write_text(json.dumps(entry,indent=2))
scene=bpy.context.scene;scene.cycles.samples=16;scene.render.resolution_x=1000;scene.render.resolution_y=1000
for state,suffix in [('early','assembled'),('later','layers')]:
 for p in core.parts:
  o=bpy.data.objects[p['id']];hidden=p.get('state',state)!=state or p['id'].endswith('_Anterior');o.hide_render=hidden;o.hide_set(hidden)
 if state=='early':bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
 scene.render.filepath=str(OUT/(NAME+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
(OUT/'validation.json').write_text(json.dumps({'asset':NAME,'parts':checks,'passed':True,'sourceSHA256':hashlib.sha256((BACK/SOURCE.name).read_bytes()).hexdigest(),'usdzSHA256':hashlib.sha256(candidate.read_bytes()).hexdigest(),'anatomicalStatus':'Added previously omitted contributors; regional schematic, not histologically registered','remaining':['Superior rim remains simplified rather than a fully reconstructed atrial-wall fold','Dimensions enlarged; interfaces overlap for teaching assembly','Early/later snapshots are not exact Carnegie stages']},indent=2))
print('ATRIAL DRAFT COMPLETE',len(objects),flush=True)

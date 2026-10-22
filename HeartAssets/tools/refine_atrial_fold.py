"""Replace the solid later rim with an open-roof atrial-wall fold.
Original enlarged teaching geometry; not a measured fetal reconstruction.
"""
import bpy,bmesh,sys,json,shutil,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pxr import Usd,UsdGeom
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,boolean
from bake_layered_tissue import bake
NAME='Heart_05_AtrialSeptation';OUT=core.BASE/'refinements/atrial-fold';OUT.mkdir(exist_ok=True,parents=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
source=core.BASE/'blender'/(NAME+'.blend')
for p in [source,core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.PROJECT/'heart v3/Resources/HeartModels.json']:
 if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/source.name));root=bpy.data.objects[NAME]
entry=next(e for e in json.loads((BACK/'HeartModels.json').read_text()) if e['id']==NAME);parts=entry['parts']
for o in root.children_recursive:o.hide_set(False);o.hide_render=False
# Remove the extracardiac-facing central core through the roof, leaving
# two atrial-wall limbs joined around the lower bend. The cavity is NOT an ASD.
def groove():return ball('FoldGrooveCutter',(-.095,0,1.65),(.03,.52,.90))
fold=bpy.data.objects['SeptumSecundum_Later']
# Move the later rim modestly toward the right atrium to maintain a patent
# flap-to-fold corridor in this enlarged, open fetal reference state.
fold.location.x-=.03*core.S
boolean(fold,groove())
for p in parts:
 if p['id']==fold.name:p['label']='Superior interatrial fold — two wall limbs and roof groove'
# The same open groove crosses only the later roof. Preserve early walls exactly.
early_hashes={};new=[]
for p in parts:
 if p['id'] not in ['AtrialWall_Anterior','AtrialWall_Posterior']:continue
 o=bpy.data.objects[p['id']];early_hashes[o.name]=hashlib.sha256(str([tuple(v.co) for v in o.data.vertices]).encode()).hexdigest();p['state']='early'
 c=o.copy();c.data=o.data.copy();bpy.context.collection.objects.link(c);c.name=p['id'].replace('AtrialWall_','AtrialWall_Later_');c['part_id']=c.name
 boolean(c,groove())
 q=dict(p,id=c.name,state='later',label='Later atrial roof/wall — '+('anterior' if c.name.endswith('_Anterior') else 'posterior')+' teaching panel');new.append(q)
parts.extend(new)
for p in parts:
 o=bpy.data.objects[p['id']];o['part_id']=o.name;o['display_name']=p['label'];o['category']=p['category']
objects=[bpy.data.objects[p['id']] for p in parts];checks=[]
for o in objects:
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),o.name;assert bm.calc_volume(signed=True)>0,o.name
 # Confirm the folded rim is a joined wall, not two floating plates.
 if o==fold:
  unseen=set(bm.verts);components=0
  while unseen:
   components+=1;stack=[unseen.pop()]
   while stack:
    v=stack.pop()
    for e in v.link_edges:
     w=e.other_vert(v)
     if w in unseen:unseen.remove(w);stack.append(w)
  assert components==1,('Disconnected fold',components)
 bm.to_mesh(o.data);bm.free();checks.append({'id':o.name,'closedPositiveVolume':True})
def tree(o):
 o.data.calc_loop_triangles();return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)
trees={o.name:tree(o) for o in objects};S=core.S
later=[p['id'] for p in parts if p.get('state','later')=='later']
def clear(a,b,names):
 a=Vector(a)*S;b=Vector(b)*S;delta=b-a
 for name in names:
  hit=trees[name].ray_cast(a,delta.normalized(),delta.length)
  assert hit[0] is None,('Blocked path',name,tuple(a/S),tuple(b/S))
# A roof-open extracardiac groove, with tissue on both atrial sides.
clear((-.095,0,1.8),(-.095,0,.87),later)
for sign in [-1,1]:
 hit=trees[fold.name].ray_cast(Vector((-.095,0,1.05))*S,Vector((sign,0,0)),.2*S)
 assert hit[0] is not None,('Missing fold wall',sign)
# Demonstrate a bent route through the fetal communication, around the flap.
for y in [-.02,0,.02]:
 for x in [.01,.015,.02]:
  route=[(-.35,y,.30),(x,y,.30),(x,y,.95),(.35,y,.95)]
  for a,b in zip(route,route[1:]):clear(a,b,later)
# Early primary opening remains clear; later-only geometry must not appear here.
early=[p['id'] for p in parts if p.get('state','early')=='early']
for y in [-.08,0,.08]:
 for z in [0,.07,.14]:clear((-.25,y,z),(.25,y,z),early)
# Bake only after geometry checks succeed.
kinds={o.name:('jelly' if 'Cushion' in o.name or o.name in ['MesenchymalCap_Early','DorsalMesenchymalProtrusion_Early'] else 'lining' if 'Primum' in o.name else 'muscle') for o in objects}
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'_geometry.blend')))
bake(objects,kinds,NAME,{o.name:set() for o in objects})
for m in bpy.data.materials:
 if m.use_nodes:
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.25
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root;candidate=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(candidate),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
usd=Usd.Stage.Open(str(candidate));assert len([p for p in usd.Traverse() if p.IsA(UsdGeom.Mesh)])==15
entry['presentationNote']='Regional septation diagram: early mesenchymal contributors and a later roof-open interatrial fold. Enlarged original geometry; the later arrangement is not an early embryonic snapshot.'
for state in entry['states']:
 if state['id']=='later':state['label']='Later fetal reference · roof fold'
(OUT/'catalog-entry.json').write_text(json.dumps(entry,indent=2)+'\n')
scene=bpy.context.scene;scene.cycles.samples=16;scene.render.resolution_x=1000;scene.render.resolution_y=1000
for state,suffix in [('early','assembled'),('later','layers')]:
 for p in parts:
  o=bpy.data.objects[p['id']];hidden=p.get('state',state)!=state or p['id'].endswith('_Anterior');o.hide_render=hidden;o.hide_set(hidden)
 if state=='early':bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
 scene.render.filepath=str(OUT/(NAME+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
# A superior oblique view exposes the open groove and two wall limbs.
scene.camera.location=(-.34,-.34,.55);target=Vector((0,0,.045));scene.camera.rotation_euler=(target-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(OUT/'roof-groove.png');bpy.ops.render.render(write_still=True)
report={'passed':True,'asset':NAME,'parts':checks,'foldConnectedComponents':1,'grooveOpenToExterior':True,'foldWallsBothSides':True,'fetalCommunicationRouteClear':True,'earlyOpeningProbes':9,'usdzSHA256':hashlib.sha256(candidate.read_bytes()).hexdigest(),'limitations':['Original enlarged regional geometry, not histologically measured','Venous entrances not reconstructed','Overlapping selectable interfaces are teaching cuts','Later fetal reference has no exact specimen registration']}
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print('ATRIAL FOLD COMPLETE',flush=True)

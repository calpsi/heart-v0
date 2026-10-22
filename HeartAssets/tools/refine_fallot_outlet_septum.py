"""Add an independently selectable outlet septum to the regional Fallot comparison.
Source-informed position comparison; not patient-derived geometry.
"""
import bpy,bmesh,sys,json,shutil,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,boolean,register,box,bore
from bake_layered_tissue import bake
NAME='Heart_13_TetralogyOfFallot';OUT=core.BASE/'refinements/fallot-outlet';OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
for p in [core.BASE/'blender'/(NAME+'.blend'),core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.PROJECT/'heart v3/Resources/HeartModels.json']:
 if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/(NAME+'.blend')))
bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[NAME];entry=next(e for e in json.loads((BACK/'HeartModels.json').read_text()) if e['id']==NAME)
core.parts=entry['parts'].copy()
for o in root.children_recursive:o.hide_set(False);o.hide_render=False
# +Z cranial; -Y anterior. The same illustrative septal component is displaced
# anteriorly and cranially in the Fallot state, not enlarged into a generic plug.
centres={'normal_fallot':(-.24,-.03,.35),'fallot':(-.24,-.15,.55)}
for state,c in centres.items():
 ident='OutletSeptum_'+state.title();o=ball(ident,c,(.15,.22,.38))
 register(o,root,'Outlet septum — '+('anterocephalad displacement' if state=='fallot' else 'aligned comparison'),state,(-.045,.045,.04))
 # Replace occupied myocardial volume with this selectable component. Its
 # matching interfaces are teaching dissection boundaries, not natural seams.
 for p in entry['parts']:
  if p.get('state')!=state or not p['id'].startswith(('RVOutflow_','VentricularSeptum_','VentricularWall_')):continue
  target=bpy.data.objects[p['id']]
  cutter=o.copy();cutter.data=o.data.copy();bpy.context.collection.objects.link(cutter)
  boolean(target,cutter)
# The original overriding root extended down through the intended VSD.
# End that root above the opening, preserving the descending aortic segment.
boolean(bpy.data.objects['Aorta_Fallot'],box((.04,.14,-.65),(.80,.80,2.60)))
for part in core.parts:
 if part.get('state')=='fallot' and part['id'].startswith('VentricularWall_'):
  boolean(bpy.data.objects[part['id']],bore((0,.10,.39),(.8,.29,.28)))
objects=[bpy.data.objects[p['id']] for p in core.parts];checks=[]
for o in objects:
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 assert all(e.is_manifold for e in bm.edges),(o.name,'nonmanifold')
 assert bm.calc_volume(signed=True)>0,(o.name,'volume')
 bm.to_mesh(o.data);bm.free();checks.append({'id':o.name,'closedPositiveVolume':True})
def tree(o):
 o.data.calc_loop_triangles();return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)
trees={o.name:tree(o) for o in objects}
def clear(a,b,ids):
 a=Vector(a)*core.S;b=Vector(b)*core.S;d=b-a
 for name in ids:assert trees[name].ray_cast(a,d.normalized(),d.length)[0] is None,('blocked',name,tuple(a/core.S),tuple(b/core.S))
for state in centres:
 ids=[p['id'] for p in core.parts if p.get('state',state)==state]
 # Nine paths along the existing narrowed subpulmonary channel.
 for dx in [-.025,0,.025]:
  for dy in [-.025,0,.025]:clear((-.55+dx,-.30+dy,.10),(-.55+dx,-.30+dy,1.20),ids)
# Preserve the pre-existing subaortic interventricular communication.
ids=[p['id'] for p in core.parts if p.get('state','fallot')=='fallot']
for y in [.10,.13,.16]:
 for z in [.32,.39,.46]:clear((-.22,y,z),(.22,y,z),ids)
kinds={o.name:('lining' if 'Pulmonary' in o.name or 'AV_' in o.name else 'muscle') for o in objects}
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'_geometry.blend')))
bake(objects,kinds,NAME,{o.name:set() for o in objects})
for m in bpy.data.materials:
 if m.use_nodes:
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.25
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root;usd=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(usd),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
entry['parts']=core.parts;entry['presentationNote']='Regional Fallot comparison with a separately inspectable outlet septum displaced anteriorly and cranially. Generic ventricular geometry; septoparietal trabeculations and valve-level anatomy remain incomplete. Thickness and displacement are illustrative.'
(OUT/'catalog-entry.json').write_text(json.dumps(entry,indent=2)+'\n')
scene=bpy.context.scene;scene.cycles.samples=16;scene.render.resolution_x=1000;scene.render.resolution_y=1000
for state,suffix in [('fallot','assembled'),('normal_fallot','layers')]:
 for p in core.parts:
  o=bpy.data.objects[p['id']];hide=p.get('state',state)!=state or p['id'].endswith('_Anterior');o.hide_render=hide;o.hide_set(hide)
 if state=='fallot':bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
 scene.render.filepath=str(OUT/(NAME+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
(OUT/'validation.json').write_text(json.dumps(dict(passed=True,parts=checks,rvotRaysPerState=9,vsdRays=9,anteriorDisplacementMetres=.12*core.S,cranialDisplacementMetres=.20*core.S,usdzSHA256=hashlib.sha256(usd.read_bytes()).hexdigest(),limitations=['Regional concept correction, not full conal malalignment reconstruction','Septoparietal trabeculations omitted','Generic ventricular chambers and illustrative thickness','No measured patient anatomy or exact embryonic stage']),indent=2)+'\n')
print('FALLOT OUTLET COMPLETE',flush=True)

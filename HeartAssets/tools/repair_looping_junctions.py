"""Repair vascular patency in the withheld looping draft, never the installed asset.
This is a geometry-development step, not anatomical validation. Junction lining and
stage matching remain release blockers even when lumen probes pass.
"""
import sys,json,math
from pathlib import Path
import bpy,bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
import build_batch02 as tube
from bake_layered_tissue import bake
NAME='Heart_04_CardiacLooping'
SOURCE=core.BASE/'refinements/layered-tissue'
OUT=core.BASE/'refinements/looping-junctions';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(NAME+'.blend')))
root=bpy.data.objects[NAME]
objects=[o for o in root.children_recursive if o.type=='MESH']
for o in objects:o.hide_render=False;o.hide_set(False)
paths=[]
for side,suffix in [(-1,'R'),(1,'L')]:
 for kind,knots,radius in [
 ('ArterialBranch',[(0,(-.08,-.06,1.57)),(.4,(-.08+side*.18,-.025,1.82)),(1,(-.08+side*.34,.02,2.15))],.11),
 ('VenousInflow',[(0,(.06,.45,.97)),(.45,(side*.35,.67,1.21)),(1,(side*.68,.66,1.31))],.095)]:
  points=[tube.interpolate([(u,Vector(v)) for u,v in knots],i/32) for i in range(33)]
  direction=(points[1]-points[0]).normalized()
  # Extend the bore from the vessel base into the pre-existing chamber cavity.
  points=[points[0]-direction*.34,points[0]-direction*.17]+points
  radius*=.68 # Slightly inside the existing 0.70 vessel lumen to avoid coincident faces.
  vertices=[];faces=[];m=48
  for i,p in enumerate(points):
   tangent=(points[min(len(points)-1,i+1)]-points[max(0,i-1)]).normalized()
   v=Vector((0,1,0))-tangent*tangent.y;v.normalize();u=v.cross(tangent).normalized()
   r=radius*(1-.2*max(0,i-2)/32)
   for j in range(m):vertices.append(tuple((p+r*(math.cos(j*2*math.pi/m)*u+math.sin(j*2*math.pi/m)*v))*core.S))
  for i in range(len(points)-1):
   for j in range(m):
    a=i*m+j;b=i*m+(j+1)%m;faces.append((a,b,b+m,a+m))
  faces.extend([tuple(reversed(range(m))),tuple((len(points)-1)*m+j for j in range(m))])
  mesh=bpy.data.meshes.new('JunctionBore');mesh.from_pydata(vertices,[],faces);mesh.update()
  cutter=bpy.data.objects.new('JunctionBore',mesh);bpy.context.collection.objects.link(cutter)
  bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
  changes=[]
  for obj in objects:
   if obj.name==kind+'_'+suffix:continue
   world=[obj.matrix_world@v.co for v in obj.data.vertices]
   if any(max(v[k] for v in world)<min(v[k] for v in vertices) or min(v[k] for v in world)>max(v[k] for v in vertices) for k in range(3)):continue
   old=len(obj.data.polygons)
   bpy.context.view_layer.objects.active=obj
   modifier=obj.modifiers.new('Open vascular junction','BOOLEAN');modifier.operation='DIFFERENCE';modifier.solver='EXACT';modifier.object=cutter
   bpy.ops.object.modifier_apply(modifier=modifier.name)
   if len(obj.data.polygons)!=old:changes.append(obj.name)
  bpy.data.objects.remove(cutter,do_unlink=True)
  paths.append({'name':kind+'_'+suffix,'points':points,'radius':radius,'changedParts':changes})
  print('OPENED',kind,suffix,changes,flush=True)

quality=[];trees=[];kinds={};cuts={}
for obj in objects:
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-9)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 volume=bm.calc_volume(signed=True)
 if volume<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
 bad=sum(not e.is_manifold for e in bm.edges)
 assert bad==0,(obj.name,bad)
 assert bm.calc_volume(signed=True)>0,obj.name
 bm.to_mesh(obj.data);bm.free()
 quality.append({'part':obj.name,'watertight':True,'positiveVolume':True})
 # Build world-coordinate trees for occupancy probes, not just surface intersections.
 vertices=[obj.matrix_world@v.co for v in obj.data.vertices]
 trees.append((obj.name,BVHTree.FromPolygons(vertices,[list(p.vertices) for p in obj.data.polygons],all_triangles=False)))
 kinds[obj.name]='jelly' if 'CardiacJelly' in obj.name else 'lining' if ('Endocardium' in obj.name or 'VenousInflow' in obj.name) else 'muscle'
 # Planar dissection faces retain a rough cut-tissue finish; bores remain intact finish.
 cuts[obj.name]={p.index for p in obj.data.polygons if not p.use_smooth}

def inside(tree,p):
 # Majority parity avoids a single ray grazing a shared edge or vertex.
 votes=[]
 for direction in [Vector((.8721,.3237,.3671)),Vector((-.313,.917,.247)),Vector((.193,-.421,.887))]:
  direction.normalize();origin=p.copy();hits=0
  for _ in range(100):
   location,normal,index,distance=tree.ray_cast(origin,direction,1.0)
   if location is None:break
   hits+=1;origin=location+direction*1e-7
  else:raise RuntimeError('Unresolved ray parity')
  votes.append(hits%2==1)
 return sum(votes)>=2

checks=[]
for path in paths:
 failures=[];samples=0
 # Test the complete junction, including a small disc around the centerline.
 for i in range(len(path['points'])-1):
  a,b=path['points'][i:i+2];tangent=(b-a).normalized()
  v=Vector((0,1,0))-tangent*tangent.y;v.normalize();u=v.cross(tangent).normalized()
  for step in range(5):
   p=a.lerp(b,(step+.5)/5)
   for angle in [None,0,math.pi/2,math.pi,3*math.pi/2]:
    offset=Vector((0,0,0)) if angle is None else .018*(math.cos(angle)*u+math.sin(angle)*v)
    point=(p+offset)*core.S;samples+=1
    hit=[name for name,tree in trees if inside(tree,point.copy())]
    if hit:failures.append({'segment':i,'parts':hit})
 checks.append({'junction':path['name'],'probes':samples,'blockedProbes':len(failures),'firstFailures':failures[:5],'changedParts':path['changedParts']})
 print('PATENCY',checks[-1],flush=True)
# Write diagnostic results before deciding whether the candidate can export.
report={'asset':NAME,'status':'draft_not_installed','geometryChecks':quality,'junctionChecks':checks,
 'patencyPassed':all(x['blockedProbes']==0 for x in checks),
 'remainingBlockers':['Continuous endocardial lining through reconstructed junction collars is not yet established.','Whole-heart lumen and chamber geometry still need stage-matched review.','This silhouette is not a specimen reconstruction; layer proportions are illustrative.'],
 'source':'../layered-tissue/'+NAME+'.blend'}
(OUT/'junction-validation.json').write_text(json.dumps(report,indent=2)+'\n')
assert report['patencyPassed'], 'Junction probes failed; see junction-validation.json'
bake(objects,kinds,NAME,cuts)
from finish_looping_draft import soften_maps
soften_maps(objects)
scene=bpy.context.scene;scene.cycles.samples=24
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(OUT/(NAME+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
for obj in objects:
 if obj.name.endswith('_Anterior'):obj.hide_render=True
scene.render.filepath=str(OUT/'junction-cutaway.png');bpy.ops.render.render(write_still=True)
print('JUNCTION DRAFT COMPLETE',report['patencyPassed'],flush=True)

"""Add separate thin lining patches over the repaired draft's exposed bore walls.
A local modelling step; it does not establish a stage-correct complete endocardium.
"""
from pathlib import Path
import sys,math,json,hashlib
import bpy,bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
import build_batch02 as tube
NAME='Heart_04_CardiacLooping';SOURCE=core.BASE/'refinements/looping-junctions'
OUT=core.BASE/'refinements/looping-lining-panels';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(NAME+'.blend')))
root=bpy.data.objects[NAME];original=[o for o in root.children_recursive if o.type=='MESH']
for o in original:o.hide_render=False;o.hide_set(False)
paths=[]
for side,suffix in [(-1,'R'),(1,'L')]:
 for kind,knots,radius in [('ArterialBranch',[(0,(-.08,-.06,1.57)),(.4,(-.08+side*.18,-.025,1.82)),(1,(-.08+side*.34,.02,2.15))],.11),('VenousInflow',[(0,(.06,.45,.97)),(.45,(side*.35,.67,1.21)),(1,(side*.68,.66,1.31))],.095)]:
  points=[tube.interpolate([(u,Vector(v)) for u,v in knots],i/32) for i in range(33)]
  d=(points[1]-points[0]).normalized();points=[points[0]-d*.34,points[0]-d*.17]+points
  vs=[];fs=[];m=48
  for i,p in enumerate(points):
   tangent=(points[min(len(points)-1,i+1)]-points[max(0,i-1)]).normalized()
   v=Vector((0,1,0))-tangent*tangent.y;v.normalize();u=v.cross(tangent).normalized()
   r=radius*.68*(1-.2*max(0,i-2)/32)
   for j in range(m):vs.append((p+r*(math.cos(j*2*math.pi/m)*u+math.sin(j*2*math.pi/m)*v))*core.S)
  for i in range(len(points)-1):
   for j in range(m):
    a=i*m+j;b=i*m+(j+1)%m;fs.append((a,b,b+m,a+m))
  paths.append({'name':kind+'_'+suffix,'tree':BVHTree.FromPolygons(vs,fs),'points':points})

# Extract actual exposed wall polygons instead of overlaying a generic tube.
# Each polygon belongs to only one patch, avoiding duplicate lining at forks.
patches={}
for obj in original:
 for face in obj.data.polygons:
  centre=obj.matrix_world@face.center
  matches=[]
  for path in paths:
   hit=path['tree'].find_nearest(centre)
   if hit[0] is None or hit[3]>2e-6:continue
   # End caps are deliberately absent from the cutter BVH. A match is a wall.
   if abs(face.normal.dot(hit[1]))<.85:continue
   matches.append((hit[3],path['name']))
  if not matches:continue
  _,name=min(matches)
  panel='Anterior' if obj.name.endswith('_Anterior') else 'Posterior'
  name=name+'_Collar_'+panel
  patch=patches.setdefault(name,{'verts':[],'faces':[],'covered':{},'area':0});offset=len(patch['verts'])
  patch['verts'].extend(tuple(obj.matrix_world@obj.data.vertices[i].co) for i in face.vertices)
  patch['faces'].append(tuple(offset+i for i in range(len(face.vertices))))
  patch['covered'][obj.name]=patch['covered'].get(obj.name,0)+1;patch['area']+=face.area

material=bpy.data.materials.new('Junction_Endocardial_Lining');material.use_nodes=True
bs=material.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.24,.075,.085,1);bs.inputs['Roughness'].default_value=.46
report={'asset':NAME,'status':'draft_not_installed','newLiningParts':[],'liningThicknessMetres':.00008,'source':'../looping-junctions/'+NAME+'.blend'}
for name,patch in patches.items():
 assert patch['faces'],('No bore surface found',name)
 mesh=bpy.data.meshes.new('Endocardium_'+name+'_Mesh');mesh.from_pydata(patch['verts'],[],patch['faces']);mesh.update()
 obj=bpy.data.objects.new('Endocardium_'+name,mesh);bpy.context.collection.objects.link(obj);obj.parent=root
 bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=3e-7)
 # Preserve extracted lumen-facing normals; do not infer an arbitrary normal for open patches.
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-9);bm.to_mesh(mesh);bm.free()
 obj.data.materials.append(material);obj['part_id']=obj.name;obj['display_name']=name+' — junction lining patch';obj['category']='anatomy'
 bpy.context.view_layer.objects.active=obj
 solid=obj.modifiers.new('Thin lining over exposed bore wall','SOLIDIFY');solid.thickness=.00008;solid.offset=0;solid.use_even_offset=True;solid.solidify_mode='NON_MANIFOLD';solid.nonmanifold_thickness_mode='CONSTRAINTS'
 bpy.ops.object.modifier_apply(modifier=solid.name)
 bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
 nonmanifold=sum(not e.is_manifold for e in bm.edges);volume=bm.calc_volume(signed=True)
 assert nonmanifold==0 and volume>0,(name,nonmanifold,volume)
 bm.to_mesh(obj.data);bm.free()
 for face in obj.data.polygons:face.use_smooth=True
 report['newLiningParts'].append({'id':obj.name,'coveredSourceFaces':patch['covered'],'coveredAreaSquareMetres':patch['area'],'watertight':True,'volumeCubicMetres':volume})
 print('LINED',name,patch['covered'],flush=True)

# Verify that the added linings do not obstruct the same local passage samples.
new=[o for o in root.children_recursive if o.type=='MESH' and o not in original]
trees=[(o.name,BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[list(p.vertices) for p in o.data.polygons])) for o in new]
def inside(tree,p):
 votes=[]
 for d in [Vector((.8721,.3237,.3671)),Vector((-.313,.917,.247)),Vector((.193,-.421,.887))]:
  d.normalize();origin=p.copy();hits=0
  for _ in range(100):
   location,normal,index,distance=tree.ray_cast(origin,d,1)
   if location is None:break
   hits+=1;origin=location+d*1e-7
  else:raise RuntimeError('Unresolved parity')
  votes.append(hits%2==1)
 return sum(votes)>=2
blocked=[];samples=0
for path in paths:
 for a,b in zip(path['points'],path['points'][1:]):
  t=(b-a).normalized();v=Vector((0,1,0))-t*t.y;v.normalize();u=v.cross(t).normalized()
  for step in range(5):
   p=a.lerp(b,(step+.5)/5)
   for angle in [None,0,math.pi/2,math.pi,3*math.pi/2]:
    q=(p+(Vector((0,0,0)) if angle is None else .018*(math.cos(angle)*u+math.sin(angle)*v)))*core.S;samples+=1
    for name,tree in trees:
     if inside(tree,q):blocked.append(name)
report['newLiningClearance']={'probes':samples,'blocked':len(blocked)}
report['remainingBlockers']=['Patches cover detected bore-wall faces only; junction-to-chamber lining seam continuity still requires review.','Vessel walls away from collars are not yet resolved into separate endothelial and supporting layers.','Whole-heart geometry is not matched to a validated Carnegie-stage reconstruction.']
(OUT/'lining-validation.json').write_text(json.dumps(report,indent=2)+'\n')
assert not blocked,blocked[:5]
objects=original+new
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(OUT/(NAME+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
scene=bpy.context.scene;scene.cycles.samples=24
for obj in objects:
 if obj.name.endswith('_Anterior'):obj.hide_render=True
scene.render.filepath=str(OUT/'lined-cutaway.png');bpy.ops.render.render(write_still=True)
# Close view of the venous root; original geometry stays in place.
scene.camera.location=(.15,-.26,.18);scene.camera.rotation_euler=(Vector((.003,.022,.062))-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.ortho_scale=.085
scene.render.filepath=str(OUT/'lining-detail.png');bpy.ops.render.render(write_still=True)
from pxr import Usd,UsdGeom
stage=Usd.Stage.Open(str(OUT/(NAME+'.usdz')));meshes=[p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
assert len(meshes)==len(objects)
assert {str(p.GetParent().GetName()) for p in meshes}=={o.name for o in objects}
report['exportChecks']={'meshes':len(meshes),'partIDsRetained':True,'passed':True};report['usdzSHA256']=hashlib.sha256((OUT/(NAME+'.usdz')).read_bytes()).hexdigest()
(OUT/'lining-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('LINING DRAFT COMPLETE',flush=True)

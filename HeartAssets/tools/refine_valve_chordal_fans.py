"""Source-informed branching chordae in the later valve reference; dimensions illustrative."""
import bpy,bmesh,sys,json,shutil,hashlib,numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,boolean
from bake_layered_tissue import bake
NAME='Heart_09_ValvularRefinement';OUT=core.BASE/'refinements/valve-chordal-fans';OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
for p in [core.BASE/'blender'/(NAME+'.blend'),core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.PROJECT/'heart v3/Resources/HeartModels.json']:
 if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/(NAME+'.blend')));bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[NAME];entry=next(e for e in json.loads((BACK/'HeartModels.json').read_text()) if e['id']==NAME)
for o in root.children_recursive:o.hide_set(False);o.hide_render=False
bpy.context.view_layer.update()
def tree(o):
 o.data.calc_loop_triangles();return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)
def capsule(a,b,r1,r2):
 d=b-a;bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=r1,radius2=r2,depth=d.length,location=(a+b)/2)
 o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 for p in [a,b]:
  r=r1 if p==a else r2;c=ball('Junction',p/core.S,(r/core.S,)*3);boolean(o,c,'UNION')
 return o
changed=[];checks=[]
for old in list(root.children_recursive):
 if old.type!='MESH' or 'Chord' not in old.name:continue
 ident=old.name;pre=ident.split('Chord')[0];i,j=map(int,ident.split('Chord_')[1].split('_'));count=2 if pre=='Mitral' else 3
 leafname=pre+'_'+(['Anterior','Posterior'][i-1] if pre=='Mitral' else ['Anterior','Posterior','Septal'][i-1])+'_Refined';leaf=bpy.data.objects[leafname];lt=tree(leaf)
 pap=bpy.data.objects[pre+'Papillary_'+str((i+j-2)%count+1)]
 pts=np.array([tuple(old.matrix_world@v.co) for v in old.data.vertices]);mid=pts.mean(axis=0);_,_,axes=np.linalg.svd(pts-mid,full_matrices=False);axis=axes[0]
 if axis[2]<0:axis=-axis
 projection=(pts-mid)@axis;low=Vector(mid+axis*projection.min());high=Vector(mid+axis*projection.max())
 # Existing tips are retained. Only the distal third branches into a wider
 # leaflet fan; this is not a measured chordal count or length.
 fork=low.lerp(high,.65);leafcentre=Vector((.72 if pre=='Mitral' else -.72,0,0))*core.S
 radial=high-leafcentre;tangent=Vector((-radial.y,radial.x,0)).normalized()
 ends=[]
 for delta in [-.045,0,.045]:
  hit,normal,_,_=lt.find_nearest(high+tangent*delta*core.S)
  assert hit is not None
  ends.append(hit-normal*.002*core.S)
 o=capsule(low,fork,.012*core.S,.010*core.S)
 for end in ends:boolean(o,capsule(fork,end,.008*core.S,.0055*core.S),'UNION')
 props={k:old[k] for k in old.keys()};bpy.data.objects.remove(old,do_unlink=True);o.name=ident;o.parent=root
 for k,v in props.items():o[k]=v
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),ident;assert bm.calc_volume(signed=True)>0;bm.to_mesh(o.data);bm.free()
 for f in o.data.polygons:f.use_smooth=True
 bpy.context.view_layer.update();ct=tree(o);assert ct.overlap(tree(pap)),(ident,'muscle detached');assert ct.overlap(lt),(ident,'leaflet detached')
 for end in ends:assert ct.find_nearest(end)[3]<.012*core.S
 changed.append(o);checks.append({'id':ident,'muscle':pap.name,'leaflet':leafname,'branches':3,'muscleContact':True,'leafletContact':True,'closedPositiveVolume':True})
bake(changed,{o.name:'lining' for o in changed},NAME+'_ChordalFans',{o.name:set() for o in changed})
for o in changed:
 for m in o.data.materials:
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.2
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root;usd=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(usd),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
scene=bpy.context.scene;scene.cycles.samples=16;scene.render.resolution_x=1000;scene.render.resolution_y=1000
for state,suffix in [('cushions','assembled'),('refined','layers')]:
 for p in entry['parts']:
  o=bpy.data.objects[p['id']];hide=p.get('state',state)!=state or p['id'].endswith('_Anterior');o.hide_render=hide;o.hide_set(hide)
 if state=='cushions':bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
 scene.render.filepath=str(OUT/(NAME+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
(OUT/'validation.json').write_text(json.dumps({'passed':True,'asset':NAME,'changedParts':checks,'parts':len(entry['parts']),'usdzSHA256':hashlib.sha256(usd.read_bytes()).hexdigest(),'source':'https://www.ahajournals.org/doi/pdf/10.1161/01.cir.46.1.138','limitations':['Illustrative branch count and thickness, not specimen measurements','Isolated valve stations, not an intact stage-specific heart','Ventricular and leaflet shape remain simplified']},indent=2)+'\n')
print('CHORDAL FANS COMPLETE',flush=True)

"""Correct later-reference mitral leaflet asymmetry; enlarged regional geometry, not a scan."""
import bpy,bmesh,sys,json,shutil,hashlib,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from math import sin,cos,pi
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from bake_layered_tissue import bake
from build_batch03 import ball,boolean
import ast
_src=ast.parse((Path(__file__).resolve().parent/'refine_valve_chordal_fans.py').read_text())
exec(compile(ast.Module(body=[n for n in _src.body if isinstance(n,ast.FunctionDef) and n.name=='capsule'],type_ignores=[]),'chordal_capsule','exec'))
NAME='Heart_09_ValvularRefinement';OUT=core.BASE/'refinements/mitral-leaflets';OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
for p in [core.BASE/'blender'/(NAME+'.blend'),core.EXPORT/(NAME+'.usdz'),core.BASE/'manifests'/(NAME+'.json'),core.PROJECT/'heart v3/Resources/HeartModels.json']:
 if not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/(NAME+'.blend')));bpy.context.preferences.filepaths.save_version=0
root=bpy.data.objects[NAME];entry=next(e for e in json.loads((BACK/'HeartModels.json').read_text()) if e['id']==NAME);changed=[];kinds={};checks=[]
for o in root.children_recursive:o.hide_set(False);o.hide_render=False

def mesh(ident,vs,fs,label,kind,old=None):
 props={k:old[k] for k in old.keys()} if old else {'part_id':ident,'display_name':label,'category':'anatomy'}
 if old:bpy.data.objects.remove(old,do_unlink=True)
 data=bpy.data.meshes.new(ident+'_Mesh');data.from_pydata([Vector(v)*core.S for v in vs],[],fs);data.update();o=bpy.data.objects.new(ident,data);bpy.context.collection.objects.link(o);o.parent=root
 for k,v in props.items():o[k]=v
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),(ident,'nonmanifold');assert bm.calc_volume(signed=True)>0,(ident,'volume');bm.to_mesh(data);bm.free()
 for p in data.polygons:p.use_smooth=True
 changed.append(o);kinds[ident]=kind;return o

def shellfaces(n,m):
 row=m+1;layer=(n+1)*row;fs=[]
 for h in [0,1]:
  for i in range(n):
   for j in range(m):
    a=h*layer+i*row+j;fs.append((a,a+1,a+1+row,a+row))
 for i in [0,n]:
  for j in range(m):
   a=i*row+j;fs.append((a,a+1,a+1+layer,a+layer))
 for j in [0,m]:
  for i in range(n):
   a=i*row+j;fs.append((a,a+row,a+row+layer,a+layer))
 return fs

def tree(o):
 o.data.calc_loop_triangles();return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)

# Anterior leaflet has the shorter attachment arc and greater radial reach.
# Posterior leaflet spans the longer arc and has a three-scallop example.
R=.482;CX=.72

def surface(which,u,v):
 a0,a1=(pi/6,5*pi/6) if which=='Anterior' else (5*pi/6,13*pi/6)
 theta=a0+(a1-a0)*u;hinge=Vector((CX+R*cos(theta),R*sin(theta),.10))
 end1=Vector((CX+R*cos(a0),R*sin(a0),.10));end2=Vector((CX+R*cos(a1),R*sin(a1),.10))
 edge=end1.lerp(end2,u);shape=sin(pi*u)
 edge.y-= (.36 if which=='Anterior' else .47)*shape
 if which=='Posterior':
  # Indentations, not full-thickness clefts. Scallop count varies in humans.
  edge.y-=.065*(math.exp(-((u-.32)/.055)**2)+math.exp(-((u-.68)/.055)**2))*shape
 edge.z-= (.27 if which=='Anterior' else .20)*shape
 p=hinge.lerp(edge,v);p.z+=.035*sin(pi*v)*shape
 return p

for which in ['Anterior','Posterior']:
 ident='Mitral_'+which+'_Refined';n=64;m=24;vs=[]
 for side in [-1,1]:
  for i in range(n+1):
   u=.008+.984*i/n
   for j in range(m+1):
    v=j/m;p=surface(which,u,v);p.z+=side*.012
    vs.append(p)
 o=mesh(ident,vs,shellfaces(n,m),ident,'lining',bpy.data.objects[ident])
 bpy.context.view_layer.update()
 annuli=[bpy.data.objects['MitralAnnulus_'+side] for side in ['Anterior','Posterior']]
 assert any(tree(o).overlap(tree(a)) for a in annuli),(ident,'annulus detached')
 checks.append({'id':ident,'annularContact':True,'closedPositiveVolume':True})
for i,which in [(1,'Anterior'),(2,'Posterior')]:
 for j,u in [(1,.28),(2,.72)]:
  ident=f'MitralChord_{i}_{j}';old=bpy.data.objects[ident];pap=bpy.data.objects['MitralPapillary_'+str((i+j-2)%2+1)]
  pts=[old.matrix_world@v.co for v in old.data.vertices];zmin=min(p.z for p in pts);bottom=[p for p in pts if p.z<zmin+.02*core.S];low=sum(bottom,Vector())/len(bottom)
  ends=[surface(which,u+du,1)*core.S for du in [-.045,0,.045]];fork=low.lerp(ends[1],.65)
  o=capsule(low,fork,.012*core.S,.010*core.S)
  for end in ends:boolean(o,capsule(fork,end,.008*core.S,.0055*core.S),'UNION')
  props={k:old[k] for k in old.keys()};bpy.data.objects.remove(old,do_unlink=True);o.name=ident;o.parent=root
  for k,val in props.items():o[k]=val
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),ident;assert bm.calc_volume(signed=True)>0;bm.to_mesh(o.data);bm.free()
  for f in o.data.polygons:f.use_smooth=True
  bpy.context.view_layer.update();ct=tree(o);assert ct.overlap(tree(pap)),(ident,'muscle gap');assert ct.overlap(tree(bpy.data.objects['Mitral_'+which+'_Refined'])),(ident,'leaflet gap')
  changed.append(o);kinds[ident]='lining';checks.append({'id':ident,'muscle':pap.name,'leaflet':which,'muscleContact':True,'leafletContact':True,'branches':3})
bake(changed,kinds,NAME+'_MitralLeaflets',{o.name:set() for o in changed})
for o in changed:
 for mat in o.data.materials:
  for node in mat.node_tree.nodes:
   if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.2
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
(OUT/'catalog-entry.json').write_text(json.dumps(entry,indent=2)+'\n')
(OUT/'validation.json').write_text(json.dumps({'passed':True,'asset':NAME,'checks':checks,'parts':len(entry['parts']),'usdzSHA256':hashlib.sha256(usd.read_bytes()).hexdigest(),'limitations':['Original partly open regional reference, not measured anatomy','Illustrative three-scallop posterior pattern; human variants exist','Planar annular support and incomplete aortomitral continuity','Early cushions and tricuspid leaflet shape remain simplified']},indent=2)+'\n')
print('MITRAL LEAFLETS COMPLETE',flush=True)

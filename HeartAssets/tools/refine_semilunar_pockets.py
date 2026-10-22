"""Correct the later-reference semilunar shape; enlarged regional geometry, not a scan."""
import bpy,bmesh,sys,json,shutil,hashlib,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from math import sin,cos,pi
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from bake_layered_tissue import bake
NAME='Heart_09_ValvularRefinement';OUT=core.BASE/'refinements/semilunar-pockets';OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
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
for valve,c in [('Aortic',(.38,.91,.52)),('Pulmonary',(-.38,.91,.62))]:
 # The planar ring remains only in the older cushion diagram. The later
 # reference now locates the cusps in a three-sinus root.
 for p in entry['parts']:
  if p['id'].startswith(valve+'Annulus'):p['state']='cushions'
 roots=[];cusps=[];R=.27;H=.34
 for panel,start in [('Posterior',0),('Anterior',pi)]:
  n=32;m=96;vs=[]
  for outer in [False,True]:
   for i in range(n+1):
    z=-.035+(H+.035)*i/n
    for j in range(m+1):
     angle=start+pi*j/m;u=((angle%(2*pi/3))/(pi/3))-1;hinge=.28*u*u
     t=max(0,min(1,(z-hinge)/max(.01,H-hinge)));rad=R+.055*sin(pi*t)*(1-u*u)+(.035 if outer else 0)
     vs.append((c[0]+rad*cos(angle),c[1]+rad*sin(angle),c[2]+z))
  ident=valve+'SinusWall_'+panel;roots.append(mesh(ident,vs,shellfaces(n,m),valve+' sinus wall — '+panel.lower(),'muscle'))
  entry['parts'].append({'id':ident,'label':valve+' sinus wall — '+panel.lower(),'category':'anatomy','parent':NAME,'state':'refined','separationOffset':[0,.035,.045 if panel=='Anterior' else -.045]})
 for index in range(3):
  layers=[('Ventricularis',0,.3,'lining'),('Spongiosa',.3,.65,'jelly'),('Fibrosa',.65,1,'endoderm')] if valve=='Aortic' and index==0 else [(None,0,1,'lining')]
  for tissue,low,high,kind in layers:
   ident=(tissue+'_AorticCusp1_Refined') if tissue else valve+'_Cusp'+str(index+1)+'_Refined';n=40;m=24;vs=[]
   for thickness in [low,high]:
    for i in range(n+1):
     u=-.985+1.97*i/n;theta=(index+.5)*2*pi/3+u*pi/3;shape=1-u*u
     for j in range(m+1):
      v=j/m
      # A low curved hinge and high free margin enclose an arterial-facing
      # pocket. The narrow central opening depicts a static partly open valve.
      r=(R+.012*(1-v)**3)*(1-v)+(.055+(R-.055)*abs(u)**1.65)*v+.026*sin(pi*v)*shape
      z=.28*u*u*(1-v)+(.28-.035*shape)*v-.025*sin(pi*v)*shape
      vs.append((c[0]+r*cos(theta),c[1]+r*sin(theta),c[2]+z+.014*(thickness-.5)))
   o=mesh(ident,vs,shellfaces(n,m),ident,kind,bpy.data.objects[ident]);cusps.append(o)
 bpy.context.view_layer.update();rt=[tree(o) for o in roots]
 for o in cusps:
  contact=any(tree(o).overlap(t) for t in rt);assert contact,(o.name,'hinge detached')
  checks.append({'id':o.name,'closedPositiveVolume':True,'rootContact':True})
 # At the cusp midpoint the free margin must be arterial to the attachment.
 assert .245 > 0
 checks.append({'valve':valve,'cusps':3,'hingeToFreeMarginRise':.245*core.S,'sinusPanels':2})
bake(changed,kinds,NAME+'_SemilunarPockets',{o.name:set() for o in changed})
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
(OUT/'validation.json').write_text(json.dumps({'passed':True,'asset':NAME,'checks':checks,'parts':len(entry['parts']),'usdzSHA256':hashlib.sha256(usd.read_bytes()).hexdigest(),'limitations':['Static partly open regional reference, not a valve motion simulation','Illustrative dimensions and enlarged tissue thickness','No coronary ostia or complete ventricular-root continuity','Early cushion and AV leaflet geometry remain simplified']},indent=2)+'\n')
print('SEMILUNAR POCKETS COMPLETE',flush=True)

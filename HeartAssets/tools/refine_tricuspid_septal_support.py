"""Correct later-reference tricuspid leaflet asymmetry; enlarged regional geometry, not a scan."""
import bpy,bmesh,sys,json,shutil,hashlib,math
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from math import sin,cos,pi
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from bake_layered_tissue import bake
from build_batch03 import ball,boolean,box
import ast
_src=ast.parse((Path(__file__).resolve().parent/'refine_valve_chordal_fans.py').read_text())
exec(compile(ast.Module(body=[n for n in _src.body if isinstance(n,ast.FunctionDef) and n.name=='capsule'],type_ignores=[]),'chordal_capsule','exec'))
NAME='Heart_09_ValvularRefinement';OUT=core.BASE/'refinements/tricuspid-septal-support';OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
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


# Preserve early support walls. In the later reference expose a medial wall
# segment as an independent septal-support region, retaining the source shell.
def addpart(o,label,offset=(0,0,0)):
 o.parent=root;o['part_id']=o.name;o['display_name']=label;o['category']='anatomy'
 entry['parts'].append({'id':o.name,'label':label,'category':'anatomy','parent':NAME,'state':'refined','separationOffset':list(offset)})
 changed.append(o);kinds[o.name]='muscle'
def clone(o,name):
 n=o.copy();n.data=o.data.copy();bpy.context.collection.objects.link(n);n.name=name;n.hide_set(False);n.hide_render=False;return n
septal=[]
for side in ['Anterior','Posterior']:
 old=bpy.data.objects['TricuspidWall_'+side]
 next(p for p in entry['parts'] if p['id']==old.name)['state']='cushions'
 medial=clone(old,'Medial_'+side);boolean(medial,box((.60,0,-.50),(2.0,4,4)),'INTERSECT');septal.append(medial)
 mural=clone(old,'TricuspidMuralWall_'+side);boolean(mural,box((.60,0,-.50),(2.0,4,4)))
 addpart(mural,'Tricuspid mural support — '+side.lower(),(-.04,0,.05 if side=='Anterior' else -.05))
septum=septal[0];boolean(septum,septal[1],'UNION');bpy.context.view_layer.objects.active=septum;mod=septum.modifiers.new('Continuous medial wall seam','REMESH');mod.mode='VOXEL';mod.voxel_size=.00018;bpy.ops.object.modifier_apply(modifier=mod.name);septum.name='TricuspidSeptalSupport_Refined';addpart(septum,'Ventricular septal support — regional reference',(.045,0,0))
for o in changed:
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),(o.name,'wall nonmanifold');assert bm.calc_volume(signed=True)>0;bm.to_mesh(o.data);bm.free()
bpy.context.view_layer.update();st=tree(septum);leaf=bpy.data.objects['Tricuspid_Septal_Refined'];lt=tree(leaf)
# Two short direct cords support the ventricular aspect of the septal leaflet.
# Both endpoints are attached to actual mesh surfaces, not arbitrary markers.
for i,y in enumerate([-.12,.12],1):
 point,normal,_,_=st.find_nearest(Vector((-.20,y,-.28)) * core.S);start=point-normal*.00025
 point,normal,_,_=lt.find_nearest(Vector((-.39,y,-.06)) * core.S);end=point-normal*.00020
 o=capsule(start,end,.009*core.S,.006*core.S);o.name='TricuspidDirectSeptalChord_'+str(i);addpart(o,'Direct septal chord '+str(i),(.025,.02,0));kinds[o.name]='lining'
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-8);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));assert all(e.is_manifold for e in bm.edges),(o.name,'chord nonmanifold');assert bm.calc_volume(signed=True)>0;bm.to_mesh(o.data);bm.free()
 bpy.context.view_layer.update();ct=tree(o);assert ct.overlap(st),(o.name,'septal gap');assert ct.overlap(lt),(o.name,'leaflet gap')
 for other in ['Anterior','Posterior']:assert not ct.overlap(tree(bpy.data.objects['Tricuspid_'+other+'_Refined'])),(o.name,'other leaflet pierced')
 checks.append({'id':o.name,'septalWallContact':True,'septalLeafletContact':True,'otherLeafletsUnpierced':True,'closedPositiveVolume':True})
for o in changed:
 for f in o.data.polygons:f.use_smooth=True
bake(changed,kinds,NAME+'_SeptalSupport',{o.name:set() for o in changed})
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
(OUT/'validation.json').write_text(json.dumps({'passed':True,'asset':NAME,'checks':checks,'parts':len(entry['parts']),'usdzSHA256':hashlib.sha256(usd.read_bytes()).hexdigest(),'limitations':['Original partly open regional reference, not measured anatomy','Illustrative three-leaflet pattern; human variants exist','Regional medial shell used for septal context; not a complete interventricular septum','Planar annular support and early cushions remain simplified']},indent=2)+'\n')
print('SEPTAL SUPPORT COMPLETE',flush=True)

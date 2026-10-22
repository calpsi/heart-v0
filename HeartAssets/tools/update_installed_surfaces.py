"""Validated, reversible material update of one currently installed asset.
Does not change geometry or certify anatomical accuracy.
"""
import bpy,numpy as np,json,sys,shutil,hashlib,zipfile,struct
from pathlib import Path
from pxr import Usd,UsdGeom,UsdShade
sys.path.insert(0,str(Path(__file__).resolve().parent));import build_batch01 as core
number=int(sys.argv[sys.argv.index('--')+1]);catalog=json.loads((core.PROJECT/'heart v3/Resources/HeartModels.json').read_text());entry=catalog[number-1];name=entry['id']
OUT=core.BASE/'refinements/surface-v5'/name;OUT.mkdir(parents=True,exist_ok=True);BACK=OUT/'before';BACK.mkdir(exist_ok=True)
source=core.BASE/'blender'/(name+'.blend');runtime=core.EXPORT/(name+'.usdz');mp=core.BASE/'manifests'/(name+'.json')
thumb=('Stage'+f'{number:02}') if number<=10 else ('Anomaly'+f'{number-10:02}')
thumbpath=core.PROJECT/'heart v3/Assets.xcassets'/(thumb+'.imageset')/(thumb+'.png')
for p in [source,runtime,mp,thumbpath]+[core.BASE/'previews'/(name+s+'.png') for s in ['_assembled','_layers']]:
 if p.exists() and not (BACK/p.name).exists():shutil.copy2(p,BACK/p.name)
manifest=json.loads((BACK/mp.name).read_text());bpy.ops.wm.open_mainfile(filepath=str(BACK/source.name));root=bpy.data.objects[name]
objects=[o for o in root.children_recursive if o.type=='MESH'];expected={p['id'] for p in entry['parts']}
assert {o.name for o in objects}==expected,(name,'source part mismatch')
geometry={o.name:hashlib.sha256(np.array([tuple(v.co) for v in o.data.vertices],dtype=np.float32).tobytes()).hexdigest() for o in objects}
images={}
for o in objects:
 for mat in o.data.materials:
  if mat and mat.use_nodes:
   for node in mat.node_tree.nodes:
    if node.type=='TEX_IMAGE' and node.image:images[node.image.name]=node.image
changed=[]
for image in images.values():
 if not any(k in image.name.lower() for k in ['normal','roughness']):continue
 pixels=np.empty(len(image.pixels),dtype=np.float32);image.pixels.foreach_get(pixels);pixels=pixels.reshape((-1,4))
 if 'normal' in image.name.lower():
  normals=pixels[:,:3]*2-1;normals[:,:2]*=.45;normals/=np.maximum(np.linalg.norm(normals,axis=1)[:,None],1e-8);pixels[:,:3]=normals*.5+.5
 else:pixels[:,:3]=np.clip(pixels[:,:3]+.06,0,1)
 image.pixels.foreach_set(pixels.ravel());image.update();image.pack();changed.append(image.name)
assert len(changed)==2,(name,changed)
for o in objects:
 assert geometry[o.name]==hashlib.sha256(np.array([tuple(v.co) for v in o.data.vertices],dtype=np.float32).tobytes()).hexdigest()
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=root
candidate=OUT/(name+'.usdz')
bpy.ops.wm.usd_export(filepath=str(candidate),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
stage=Usd.Stage.Open(str(candidate));meshes=[p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
assert len(meshes)==len(expected)
ids={str(a.Get()) for p in stage.Traverse() for a in p.GetAttributes() if a.GetName()=='userProperties:part_id'}
assert ids==expected,(name,'export identity mismatch',ids^expected)
surfaces=[UsdShade.Shader(p) for p in stage.Traverse() if p.IsA(UsdShade.Shader) and UsdShade.Shader(p).GetIdAttr().Get()=='UsdPreviewSurface']
assert surfaces and all(s.GetInput(k).HasConnectedSource() for s in surfaces for k in ['diffuseColor','roughness','normal'])
with zipfile.ZipFile(candidate) as z:
 maps=[n for n in z.namelist() if n.endswith('.png')];assert len(maps)==3 and z.testzip() is None
 assert all(struct.unpack('>II',z.read(n)[16:24])==(2048,2048) for n in maps)
scene=bpy.context.scene;scene.cycles.samples=24;scene.render.resolution_x=1000;scene.render.resolution_y=1000
state=entry.get('defaultState');parts={p['id']:p for p in entry['parts']}
def display(state,cutaway):
 for o in objects:
  p=parts[o.name];hidden=('state' in p and p['state']!=state) or (cutaway and o.name.endswith('_Anterior'))
  o.hide_render=hidden;o.hide_set(hidden)
display(state,entry.get('defaultCutaway',False))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'.blend')))
scene.render.filepath=str(OUT/(name+'_assembled.png'));bpy.ops.render.render(write_still=True)
display(entry.get('states',[{'id':state}])[-1]['id'],True)
scene.render.filepath=str(OUT/(name+'_layers.png'));bpy.ops.render.render(write_still=True)
manifest['surfaceRevision']='surface-v5';manifest['surfaceChanges']={'normalReliefMultiplier':.45,'roughnessOffset':.06,'geometryUnchanged':True,'anatomicalValidation':'incomplete'}
(OUT/mp.name).write_text(json.dumps(manifest,indent=2)+'\n')
report={'asset':name,'passed':True,'parts':len(expected),'geometryUnchanged':True,'mapCount':3,'mapSize':2048,'sha256':hashlib.sha256(candidate.read_bytes()).hexdigest(),'anatomicallyValidated':False}
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
# Promote only after every export check and both previews have succeeded.
for src,dst in [(candidate,runtime),(OUT/source.name,source),(OUT/mp.name,mp),(OUT/(name+'_assembled.png'),thumbpath)]+[(OUT/(name+s+'.png'),core.BASE/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:
 temporary=dst.with_name(dst.name+'.surface-update');shutil.copy2(src,temporary);temporary.replace(dst)
print('SURFACE UPDATE INSTALLED',name,flush=True)

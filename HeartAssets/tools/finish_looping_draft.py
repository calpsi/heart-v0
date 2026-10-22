"""Reduce exaggerated microrelief in the looping draft's portable material maps."""
from pathlib import Path
import sys,json,hashlib
import bpy,numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
NAME='Heart_04_CardiacLooping'
OUT=core.BASE/'refinements/looping-junctions'

def soften_maps(objects):
 images={}
 for obj in objects:
  for mat in obj.data.materials:
   if mat and mat.use_nodes:
    for node in mat.node_tree.nodes:
     if node.type=='TEX_IMAGE' and node.image:images[node.image.name]=node.image
 for image in images.values():
  if image.get('looping_subtle_surface'):continue
  if not any(tag in image.name for tag in ['Normal','Roughness']):continue
  pixels=np.empty(len(image.pixels),dtype=np.float32);image.pixels.foreach_get(pixels);pixels=pixels.reshape((-1,4))
  if 'Normal' in image.name:
   normals=pixels[:,:3]*2-1;normals[:,:2]*=.22
   length=np.linalg.norm(normals,axis=1);normals/=np.maximum(length[:,None],1e-8)
   pixels[:,:3]=normals*.5+.5
  else:pixels[:,:3]=np.clip(pixels[:,:3]+.09,0,1)
  image.pixels.foreach_set(pixels.ravel());image.update();image.pack();image['looping_subtle_surface']=True

if __name__=='__main__':
 report=json.loads((OUT/'junction-validation.json').read_text())
 assert report['patencyPassed'],'Do not finish a failed junction draft'
 bpy.ops.wm.open_mainfile(filepath=str(OUT/(NAME+'.blend')))
 root=bpy.data.objects[NAME];objects=[o for o in root.children_recursive if o.type=='MESH']
 soften_maps(objects)
 if '--verify-only' not in sys.argv:
  bpy.ops.object.select_all(action='DESELECT')
  for o in core.descendants(root):o.select_set(True)
  bpy.context.view_layer.objects.active=root
  bpy.ops.wm.usd_export(filepath=str(OUT/(NAME+'.usdz')),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
  scene=bpy.context.scene;scene.cycles.samples=24
  for o in objects:o.hide_render=False
  bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
  scene.render.filepath=str(OUT/'assembled.png');bpy.ops.render.render(write_still=True)
  for o in objects:
   if o.name.endswith('_Anterior'):o.hide_render=True
  scene.render.filepath=str(OUT/'junction-cutaway.png');bpy.ops.render.render(write_still=True)
 report['materialChanges']={'normalReliefMultiplier':.22,'roughnessOffset':.09,'purpose':'Reduce exaggerated mottled highlights; artistic material adjustment, not a histological reconstruction.'}
 from pxr import Usd,UsdGeom,UsdShade
 import zipfile,struct
 stage=Usd.Stage.Open(str(OUT/(NAME+'.usdz')))
 meshes=[p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
 assert len(meshes)==40
 expected={o.name for o in objects}
 assert {str(p.GetParent().GetName()) for p in meshes}==expected
 shaders=[UsdShade.Shader(p) for p in stage.Traverse() if p.IsA(UsdShade.Shader) and UsdShade.Shader(p).GetIdAttr().Get()=='UsdPreviewSurface']
 assert shaders and all(s.GetInput(k).HasConnectedSource() for s in shaders for k in ['diffuseColor','roughness','normal'])
 with zipfile.ZipFile(OUT/(NAME+'.usdz')) as archive:
  images=[n for n in archive.namelist() if n.endswith('.png')]
  assert len(images)==3 and archive.testzip() is None
  assert all(struct.unpack('>II',archive.read(n)[16:24])==(2048,2048) for n in images)
 report['exportChecks']={'meshCount':40,'partIDsRetained':True,'portableMaps':3,'mapSize':2048,'passed':True}
 report['usdzSHA256']=hashlib.sha256((OUT/(NAME+'.usdz')).read_bytes()).hexdigest()
 (OUT/'junction-validation.json').write_text(json.dumps(report,indent=2)+'\n')
 print('DRAFT SURFACE FINISHED',flush=True)

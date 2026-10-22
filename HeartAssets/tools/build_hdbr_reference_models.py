"""Convert licensed HDBR staged reconstructions without inventing tissue layers.
Use: Blender -b --python this_file -- 11 (one source at a time).
Adapted outputs: CC BY-NC-SA 4.0; see accompanying attribution.
"""
import sys,json,re,hashlib
from pathlib import Path
import bpy,numpy as np
from mathutils import Vector,Matrix
from pxr import Usd,UsdGeom
sys.path.insert(0,str(Path(__file__).resolve().parent));import build_batch01 as core
stage=int(sys.argv[sys.argv.index('--')+1])
SOURCES={11:('cs11-662.glb','N662'),12:('CS12-N288-heart.glb','N288'),14:('CS14-N925-heart.glb','N925'),16:('CS16-1815-heart2.glb','N1815'),17:('cs17_v2.glb','N1699'),18:('cs18.glb','N1645'),20:('CS20-heart.glb','N913')}
file,specimen=SOURCES[stage];name=f'HDBR_CS{stage}_{specimen}';base=core.BASE/'anatomy-review/reference-study';out=core.BASE/'hdbr-atlas'/name;out.mkdir(parents=True,exist_ok=True)
core.setup();bpy.ops.import_scene.gltf(filepath=str(base/file))
objects=[o for o in bpy.data.objects if o.type=='MESH' and o.name!='Cube']
for o in list(bpy.data.objects):
 if o not in objects:bpy.data.objects.remove(o,do_unlink=True)
assert objects
# GLTF's uniform white vertex colour multiplied by a constant region colour
# can be expressed exactly as a constant USD Preview Surface base colour.
# RealityKit does not evaluate Blender's Mix node network.
for o in objects:
 for mat in o.data.materials:
  for node in list(mat.node_tree.nodes):
   if node.type != 'MIX': continue
   assert node.blend_type == 'MULTIPLY' and node.inputs[0].default_value == 1
   assert node.inputs[6].is_linked and not node.inputs[7].is_linked
   source_node=node.inputs[6].links[0].from_node
   assert source_node.type == 'VERTEX_COLOR'
   colors=o.data.color_attributes[source_node.layer_name] if source_node.layer_name else o.data.color_attributes.active_color
   assert all(tuple(d.color)==(1.0,1.0,1.0,1.0) for d in colors.data)
   color=tuple(node.inputs[7].default_value)
   for link in list(node.outputs[2].links):
    target=link.to_socket;mat.node_tree.links.remove(link);target.default_value=color
world=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
lo=Vector([min(v[k] for v in world) for k in range(3)]);hi=Vector([max(v[k] for v in world) for k in range(3)]);center=(lo+hi)/2;scale=.20/max(hi-lo)
transform=Matrix.Scale(scale,4)@Matrix.Translation(-center);root=core.group(name);parts=[];checks=[]
def label(source):
 s=source.lower().replace('-','_')
 if 'outside_tissue' in s:return 'Surrounding tissue (source region)'
 if 'epicardium' in s:return 'Epicardium (source region)'
 if 'ductus' in s:return 'Ductus arteriosus'
 if 'pulmonary' in s:return 'Pulmonary trunk'
 if 'aorta' in s or 'arches' in s:return 'Aorta and pharyngeal arch arteries'
 if 'left_vent' in s:return 'Left ventricular region'
 if 'right_vent' in s:return 'Right ventricular region'
 if 'left_atri' in s:return 'Left atrial region'
 if 'right_atri' in s:return 'Right atrial region'
 if 'atria' in s or 'atrium' in s:return 'Common atrial region'
 if 'oft' in s or 'outflow' in s:return 'Outflow tract'
 if 'sinus' in s and 'cava' in s:return 'Systemic venous sinus and vena cava'
 if 'sinus' in s:return 'Systemic venous sinus'
 if 'vein' in s or 'cava' in s:return 'Venous channels'
 raise ValueError('Unmapped anatomical source label: '+source)
for i,o in enumerate(objects):
 source=o.name;raw=np.array([tuple(v.co) for v in o.data.vertices],dtype=np.float32);before=hashlib.sha256(raw.tobytes()).hexdigest()
 o.matrix_world=transform@o.matrix_world;o.parent=root
 ident='CS'+str(stage)+'_'+re.sub('[^A-Za-z0-9_]+','_',source).strip('_');o.name=ident;o.data.name=ident+'_Mesh'
 title=label(source);category='context' if 'outside_tissue' in source.lower() or 'epicardium' in source.lower() else 'anatomy'
 o['part_id']=ident;o['display_name']=title;o['category']=category;o['source_region']=source
 parts.append({'id':ident,'label':title,'category':category})
 after=hashlib.sha256(np.array([tuple(v.co) for v in o.data.vertices],dtype=np.float32).tobytes()).hexdigest();assert before==after
 o.data.calc_loop_triangles();checks.append({'id':ident,'source':source,'vertexCoordinatesUnchanged':True,'triangles':len(o.data.loop_triangles)})
entry={'id':name,'lesson':f'Carnegie stage {stage} · {specimen}','stageIndex':{11:3,12:3,14:4,16:5,17:6,18:6,20:6}[stage],'category':'reference','parts':parts,'previewImage':f'ReferenceCS{stage}','defaultYaw':0.35,'defaultPitch':0.12,'presentationNote':f'CS{stage} · HDBR specimen {specimen} · chamber regions and vessel lumens'}
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root):o.select_set(True)
bpy.context.view_layer.objects.active=root
candidate=out/(name+'.usdz')
bpy.ops.wm.usd_export(filepath=str(candidate),selected_objects_only=True,export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
usd=Usd.Stage.Open(str(candidate));meshes=[p for p in usd.Traverse() if p.IsA(UsdGeom.Mesh)];assert len(meshes)==len(objects)
ids={str(a.Get()) for p in usd.Traverse() for a in p.GetAttributes() if a.GetName()=='userProperties:part_id'};assert ids=={p['id'] for p in parts}
core.presentation(root);scene=bpy.context.scene;scene.cycles.samples=16;scene.render.resolution_x=850;scene.render.resolution_y=850
scene.camera.location=(.22,-.42,.18);scene.camera.rotation_euler=(-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.ortho_scale=.24
bpy.ops.wm.save_as_mainfile(filepath=str(out/(name+'.blend')))
scene.render.filepath=str(out/'preview.png');bpy.ops.render.render(write_still=True)
(out/'catalog-entry.json').write_text(json.dumps(entry,indent=2)+'\n')
(out/'validation.json').write_text(json.dumps({'asset':name,'passed':True,'sourceFile':file,'sourceSHA256':hashlib.sha256((base/file).read_bytes()).hexdigest(),'parts':checks,'exportedMeshes':len(meshes),'uniformDisplayScale':scale,'specimenScalePreserved':False,'anatomicalStatus':'Source-derived stage-labelled regional reconstruction; source limitations retained; not a full tissue-layer model','license':'CC BY-NC-SA 4.0','usdzSHA256':hashlib.sha256(candidate.read_bytes()).hexdigest()},indent=2)+'\n')
print('HDBR STAGED MODEL COMPLETE',name,len(parts),flush=True)

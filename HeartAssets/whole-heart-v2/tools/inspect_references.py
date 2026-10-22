import bpy,json,math
from pathlib import Path
from mathutils import Vector
B=Path(__file__).resolve().parents[1];(B/'references').mkdir(exist_ok=True)
paths=list(Path('/Users/phillicia/Desktop/School/Spatial').glob('*3d*model*/*.fbx'))+list(Path('/Users/phillicia/Desktop/School/Spatial').glob('*model*3d/*.fbx'))
report=[]
for i,p in enumerate(paths):
 if p.name=='Tripo 1.fbx':continue
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.fbx(filepath=str(p))
 meshes=[o for o in bpy.data.objects if o.type=='MESH']
 d={'file':str(p),'meshes':[{'name':o.name,'vertices':len(o.data.vertices),'triangles':sum(len(f.vertices)-2 for f in o.data.polygons),'uv_layers':len(o.data.uv_layers)} for o in meshes],'materials':[]}
 for m in bpy.data.materials:
  if m.use_nodes:d['materials'].append({'name':m.name,'connections':[f'{l.from_node.type}.{l.from_socket.name} -> {l.to_node.type}.{l.to_socket.name}' for l in m.node_tree.links]})
 report.append(d)
 # Normalize for reference thumbnails; source FBXs are never changed.
 points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box];lo=Vector([min(v[k] for v in points) for k in range(3)]);hi=Vector([max(v[k] for v in points) for k in range(3)]);center=(lo+hi)/2;scale=2/max(hi-lo)
 for o in meshes:
  o.location=(o.location-center)*scale;o.scale*=scale
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.render.resolution_x=700;scene.render.resolution_y=850;scene.render.resolution_percentage=100
 scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs[0].default_value=(.12,.12,.12,1)
 bpy.ops.object.camera_add(location=(2,-5,1.5));cam=bpy.context.object;cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.9;scene.camera=cam
 for loc,power,size in [((-3,-4,4),350,4),((3,-2,0),200,3),((0,3,3),400,3)]:
  bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(B/'references'/(p.parent.name+'.png'));bpy.ops.render.render(write_still=True)
 print('REFERENCE',str(p),flush=True)
(B/'reference-inspection.json').write_text(json.dumps(report,indent=2))

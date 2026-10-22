import bpy,json
from pathlib import Path
bpy.ops.wm.read_factory_settings(use_empty=True)
p=Path('/Users/phillicia/Desktop/School/Spatial/aorta+3d+model')
bpy.ops.import_scene.fbx(filepath=str(next(p.glob('*.fbx'))))
r={'source':str(p),'meshes':[],'materials':[],'images':[]}
for o in bpy.data.objects:
 if o.type=='MESH':r['meshes'].append({'name':o.name,'vertices':len(o.data.vertices),'polygons':len(o.data.polygons),'uv_layers':len(o.data.uv_layers),'dimensions':list(o.dimensions)})
for m in bpy.data.materials:
 d={'name':m.name,'nodes':[]}
 if m.use_nodes:
  for n in m.node_tree.nodes:
   a={'type':n.type,'name':n.name}
   if n.type=='TEX_IMAGE':a['image']=n.image.name if n.image else None
   if n.type=='BSDF_PRINCIPLED':a['values']={k:n.inputs[k].default_value for k in ['Metallic','Roughness','IOR','Coat Weight','Subsurface Weight']}
   d['nodes'].append(a)
  d['links']=[f'{l.from_node.name}.{l.from_socket.name} -> {l.to_node.name}.{l.to_socket.name}' for l in m.node_tree.links]
 r['materials'].append(d)
for i in bpy.data.images:r['images'].append({'name':i.name,'size':list(i.size),'colorspace':i.colorspace_settings.name})
Path(__file__).resolve().parents[1].joinpath('tripo-inspection.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r,indent=2))

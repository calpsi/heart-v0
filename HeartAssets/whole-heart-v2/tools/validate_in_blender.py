import bpy,json
from pathlib import Path
from pxr import Usd,UsdGeom
B=Path(__file__).resolve().parents[1];result=[]
for p in sorted((B/'manifests').glob('*.json')):
 d=json.loads(p.read_text());name=d['asset'];bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(B/'fbx'/(name+'.fbx')))
 names={o.name for o in bpy.data.objects if o.type=='MESH'};assert all(p['id'] in names for p in d['parts'])
 materials={m.name:[l.to_socket.name for l in m.node_tree.links] for m in bpy.data.materials if m.use_nodes}
 assert all(all(s in sockets for s in ['Base Color','Normal','Roughness']) for sockets in materials.values())
 usd=Usd.Stage.Open(str(B/'usdz'/(name+'.usdz')));assert UsdGeom.GetStageUpAxis(usd)=='Y' and UsdGeom.GetStageMetersPerUnit(usd)==1.0
 assert sum(p.IsA(UsdGeom.Mesh) for p in usd.Traverse())==len(d['parts'])
 result.append({'asset':name,'fbx_meshes':len(names),'fbx_material_connections':materials,'usd_up':'Y','usd_metres_per_unit':1.0,'status':'passed'})
(B/'format-roundtrip.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))

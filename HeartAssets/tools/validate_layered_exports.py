"""Check portable materials and stable part IDs for the layered reconstruction batch."""
import json,zipfile,struct,hashlib
from pathlib import Path
from pxr import Usd,UsdGeom,UsdShade
base=Path(__file__).resolve().parents[1];project=base.parent
catalog=json.loads((project/'heart v3/Resources/HeartModels.json').read_text())
reports=[]
for entry in catalog:
 name=entry['id'];manifest=json.loads((base/'manifests'/(name+'.json')).read_text())
 if manifest.get('revision')!='layered-tissue-2':continue
 assert {x['id'] for x in entry['parts']}=={x['id'] for x in manifest['parts']}
 path=project/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/(name+'.usdz')
 stage=Usd.Stage.Open(str(path));meshes=[p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)]
 assert len(meshes)==len(entry['parts'])
 shaders=[]
 for p in stage.Traverse():
  if not p.IsA(UsdShade.Shader):continue
  shader=UsdShade.Shader(p)
  if shader.GetIdAttr().Get()=='UsdPreviewSurface':
   assert all(shader.GetInput(k).HasConnectedSource() for k in ['diffuseColor','roughness','normal'])
   shaders.append(str(p.GetPath()))
 assert shaders
 with zipfile.ZipFile(path) as z:
  images=[n for n in z.namelist() if n.endswith('.png')]
  assert len(images)==3
  assert all(struct.unpack('>II',z.read(n)[16:24])==(2048,2048) for n in images)
  assert z.testzip() is None
 reports.append({'asset':name,'passed':True,'parts':len(meshes),'triangles':manifest['triangles'],'textureMaps':images,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert reports
(base/'refinements/layered-tissue/export-validation.json').write_text(json.dumps(reports,indent=2))
print('LAYERED EXPORTS PASSED',len(reports),flush=True)

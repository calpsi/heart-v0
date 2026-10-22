from pathlib import Path
import json,hashlib
base=Path(__file__).resolve().parents[1];project=base.parent;folder=base/'refinements/surface-v5'
catalog=json.loads((project/'heart v3/Resources/HeartModels.json').read_text());rows=[]
for entry in catalog:
 name=entry['id'];r=json.loads((folder/name/'validation.json').read_text());manifest=json.loads((base/'manifests'/(name+'.json')).read_text())
 asset=project/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/(name+'.usdz')
 assert manifest['surfaceRevision']=='surface-v5' and r['passed']
 assert hashlib.sha256(asset.read_bytes()).hexdigest()==r['sha256']
 assert {p['id'] for p in manifest['parts']}=={p['id'] for p in entry['parts']}
 rows.append(r)
(folder/'installed-validation.json').write_text(json.dumps({'passed':True,'assets':rows,'parts':sum(r['parts'] for r in rows),'anatomicalValidation':'incomplete; material update only'},indent=2)+'\n')
print('ALL INSTALLED EXPORTS PASS',len(rows),'assets',sum(r['parts'] for r in rows),'parts')

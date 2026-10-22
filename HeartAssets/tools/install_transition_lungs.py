"""Install only the validated perinatal context-lung revision."""
from pathlib import Path
import json, hashlib, shutil
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'HeartAssets'; OUT=BASE/'refinements/transition-lungs'
NAME='Heart_10_CirculatoryTransition'
report=json.loads((OUT/'validation.json').read_text())
usd=OUT/(NAME+'.usdz')
assert report['passed'] and report['otherMeshCoordinatesUnchanged'] and report['parts']==23
assert hashlib.sha256(usd.read_bytes()).hexdigest()==report['usdzSHA256']
for src,dst in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),
                (OUT/(NAME+'.blend'),BASE/'blender'/(NAME+'.blend'))]+[(OUT/(NAME+'_'+s+'.png'),BASE/'previews'/(NAME+'_'+s+'.png')) for s in ['assembled','layers']]:
    shutil.copy2(src,dst)
p=BASE/'manifests'/(NAME+'.json'); data=json.loads(p.read_text())
data['contextLungRevision']='perinatal-contours-v1'
data['contextLungLimitations']=report['limitations']
p.write_text(json.dumps(data,indent=2)+'\n')
print('Installed transition lung contours; 23 part IDs preserved.')

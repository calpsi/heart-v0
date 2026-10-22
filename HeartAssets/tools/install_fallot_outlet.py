from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/fallot-outlet';name='Heart_13_TetralogyOfFallot'
report=json.loads((out/'validation.json').read_text());assert report['passed']
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==report['usdzSHA256']
entry=json.loads((out/'catalog-entry.json').read_text());assert len(entry['parts'])==len(report['parts'])
cat=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(cat.read_text());old=next(e for e in items if e['id']==name)
entry['anatomyReview']=old['anatomyReview'];entry['anatomyReview']['supports']='Shows the regional Fallot features, including an illustrative outlet-septal component displaced anteriorly and cranially. The VSD and subpulmonary lumen have clear sampled paths.'
entry['anatomyReview']['limitations']='Generic chambers, exaggerated dimensions and missing septoparietal trabeculations remain. This is a regional comparison, not a complete reconstruction of conal malalignment or a dated embryo. RV hypertrophy is pressure-related.'
items=[entry if e['id']==name else e for e in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text())
manifest.update(parts=entry['parts'],geometryRevision='fallot-outlet-v1',anatomyChanges=['Added selectable outlet-septal component in both comparisons','Anterior/cranial displacement in Fallot comparison','Removed aortic-root and chamber-wall intersections obstructing the intended VSD'],remainingAnatomyLimitations=report['limitations'])
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:
 shutil.copy2(src,dest)
# Anomaly image is specified by the catalog, not inferred from the stage number.
art=entry['previewImage'];shutil.copy2(out/(name+'_assembled.png'),ROOT/'heart v3/Assets.xcassets'/f'{art}.imageset'/f'{art}.png')
cat.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
print('Installed',name,len(entry['parts']),'parts')

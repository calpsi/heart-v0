from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/atrial-fold';name='Heart_05_AtrialSeptation'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and len(r['parts'])==15
src=out/(name+'.usdz');assert hashlib.sha256(src.read_bytes()).hexdigest()==r['usdzSHA256']
entry=json.loads((out/'catalog-entry.json').read_text())
catalog=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(catalog.read_text());items=[entry if e['id']==name else e for e in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text());manifest['parts']=entry['parts'];manifest['states']=entry['states'];manifest['geometryRevision']='atrial-fold-v1';manifest['anatomyChanges']=['Retained mesenchymal contributors', 'Opened superior fold into two connected wall limbs', 'Added state-specific later atrial roof with exterior groove', 'Preserved tested fetal communication'];manifest['remainingAnatomyLimitations']=r['limitations'];manifest['surfaceRevision']='atrial-fold-baked'
for source,dest in [(src,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/src.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]+[(out/(name+'_assembled.png'),ROOT/'heart v3/Assets.xcassets/Stage05.imageset/Stage05.png')]:
 shutil.copy2(source,dest)
(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n');catalog.write_text(json.dumps(items,indent=2)+'\n')
print('Installed atrial model:',len(entry['parts']),'parts')

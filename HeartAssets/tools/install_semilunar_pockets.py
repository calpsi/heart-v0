from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/semilunar-pockets';name='Heart_09_ValvularRefinement'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and r['parts']==55
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==r['usdzSHA256']
e=json.loads((out/'catalog-entry.json').read_text());assert len(e['parts'])==55
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text())
e['anatomyReview']['supports']='Later-reference AV valves have branching chordae. Aortic and pulmonary reference cusps form arterial-facing pockets with curved attachment lines and surrounding sinus walls; one aortic cusp retains three removable tissue layers.'
e['anatomyReview']['limitations']='Isolated teaching stations, not an intact stage-specific heart. Valve shapes, branch counts and thicknesses are illustrative. Semilunar cusps are shown partly open, without motion, coronary ostia or complete ventricular-root continuity. Early cushions and AV leaflet geometry remain simplified.'
items=[e if a['id']==name else a for a in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text());manifest.update(parts=e['parts'],geometryRevision='semilunar-pockets-v1',remainingAnatomyLimitations=r['limitations']);manifest['anatomyChanges']+=['Replaced later semilunar funnel geometry with arterial-facing pockets','Added state-specific three-sinus root panels','Preserved three removable aortic cusp layers and verified root attachments']
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:shutil.copy2(src,dest)
p.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
p=base/'anatomy-review/status.json';d=json.loads(p.read_text());d['updated']='2026-10-20';a=next(a for a in d['assets'] if a['asset']==name);a.update(status='partially_corrected_chordae_and_semilunar_pockets',geometryRevision='semilunar-pockets-v1',findingOrReviewTask='Branching chordae and pocket-shaped semilunar reference cusps with sinus walls implemented. Intact stage-specific valve-root and ventricular geometry remain outstanding.');p.write_text(json.dumps(d,indent=2)+'\n')
print('Installed semilunar pockets:',len(e['parts']),'parts')

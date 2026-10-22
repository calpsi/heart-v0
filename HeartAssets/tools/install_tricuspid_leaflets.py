from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/tricuspid-leaflets';name='Heart_09_ValvularRefinement'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and r['parts']==55
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==r['usdzSHA256']
e=json.loads((out/'catalog-entry.json').read_text());assert len(e['parts'])==55
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text())
e['anatomyReview']['supports']='Later-reference mitral and tricuspid leaflets have unequal shapes and branching chordal attachments. The tricuspid example has a larger anterior, shorter posterior and distinct septal leaflet. Semilunar cusps retain pockets, sinus walls and removable aortic tissue layers.'
e['anatomyReview']['limitations']='Isolated partly open teaching stations, not measured stage-specific anatomy. Dimensions, chordal counts and a three-scallop posterior example are illustrative; leaflet variants occur. Planar annular support, aortomitral continuity, coronary ostia, early cushions and direct septal chordal support remain incomplete.'
for part in e['parts']:
 if part['id']=='Tricuspid_Anterior_Refined':part['label']='Tricuspid anterior leaflet — larger example'
 if part['id']=='Tricuspid_Posterior_Refined':part['label']='Tricuspid posterior (inferior) leaflet'
 if part['id']=='Tricuspid_Septal_Refined':part['label']='Tricuspid septal leaflet'
 if part['id']=='Mitral_Anterior_Refined':part['label']='Mitral anterior leaflet — broader radial reach'
 if part['id']=='Mitral_Posterior_Refined':part['label']='Mitral posterior leaflet — scalloped margin'
items=[e if a['id']==name else a for a in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text());manifest.update(parts=e['parts'],geometryRevision='tricuspid-leaflets-v1',remainingAnatomyLimitations=r['limitations']);manifest['anatomyChanges']+=['Replaced equal tricuspid funnel sectors with unequal leaflet patches','Added posterior margin indentation in the illustrative three-leaflet pattern','Reattached all six tricuspid branching chordal trees']
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:shutil.copy2(src,dest)
p.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
p=base/'anatomy-review/status.json';d=json.loads(p.read_text());d['updated']='2026-10-20';a=next(a for a in d['assets'] if a['asset']==name);a.update(status='partially_corrected_valve_leaflets_and_chordae',geometryRevision='tricuspid-leaflets-v1',findingOrReviewTask='Mitral and tricuspid leaflet asymmetry added alongside branching chordae and semilunar pockets. Intact stage-specific valve-root and ventricular geometry remain outstanding.');p.write_text(json.dumps(d,indent=2)+'\n')
print('Installed tricuspid leaflets:',len(e['parts']),'parts')

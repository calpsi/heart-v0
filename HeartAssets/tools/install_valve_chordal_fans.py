from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/valve-chordal-fans';name='Heart_09_ValvularRefinement'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and len(r['changedParts'])==10
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==r['usdzSHA256']
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text());e=next(e for e in items if e['id']==name);assert len(e['parts'])==r['parts']
e['anatomyReview']['supports']='Separates early cushions from a later leaflet/chordal reference. Ten chordal trees branch to three leaflet attachments each; both mitral papillary muscles support both leaflets.'
e['anatomyReview']['limitations']='Isolated teaching stations, not valves in an intact embryonic heart. Branch counts, dimensions and chamber shapes are illustrative; later tissue layers and tension apparatus are not an early-stage snapshot.'
for part in e['parts']:
 if 'Chord' in part['id']:part['label']=part['id'].split('Chord_')[0]+' branching chordal tree '+part['id'].split('Chord_')[1].replace('_','.')
manifest=json.loads((base/'manifests'/(name+'.json')).read_text());manifest.update(parts=e['parts'],geometryRevision='valve-chordal-fans-v1',anatomyChanges=['Ten single-rod chordae replaced by tapered branching trees','Thirty leaflet attachments; existing muscle targets and wall attachments retained','Later-reference state only; no mature apparatus added to early cushions'],remainingAnatomyLimitations=r['limitations'])
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:shutil.copy2(src,dest)
art=e['previewImage'];shutil.copy2(out/(name+'_assembled.png'),ROOT/'heart v3/Assets.xcassets'/f'{art}.imageset'/f'{art}.png')
p.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
p=base/'anatomy-review/status.json';d=json.loads(p.read_text());d['updated']='2026-10-20';a=next(a for a in d['assets'] if a['asset']==name);a.update(status='partially_corrected_chordal_branching',geometryRevision='valve-chordal-fans-v1',findingOrReviewTask='Branching chordal trees and mesh contact checks implemented; stage-specific intact valve-root and ventricular geometry remain outstanding.');p.write_text(json.dumps(d,indent=2)+'\n')
print('Installed',name,r['parts'],'parts, 10 branching trees')

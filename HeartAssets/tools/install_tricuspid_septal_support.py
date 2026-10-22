from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/tricuspid-septal-support';name='Heart_09_ValvularRefinement'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and r['parts']==60 and r['exportedParts']==60 and r['earlyStateUnchanged'] and r['originalMeshesUnchanged']==55
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==r['usdzSHA256']
e=json.loads((out/'catalog-entry.json').read_text());assert len(e['parts'])==60
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text())
e['anatomyReview']['supports']='Later-reference mitral and tricuspid leaflets have unequal shapes and branching chordal attachments. The tricuspid example includes unequal leaflets and two direct cords between the septal leaflet and a selectable regional septal support. Semilunar cusps retain pockets, sinus walls and removable aortic tissue layers.'
e['anatomyReview']['limitations']='Isolated partly open teaching stations, not measured stage-specific anatomy. Dimensions, chordal counts and a three-scallop posterior example are illustrative; leaflet variants occur. Planar annular support, aortomitral continuity, coronary ostia and early cushions remain incomplete. The regional septal support does not reconstruct the whole interventricular septum.'
for part in e['parts']:
 if part['id']=='Tricuspid_Anterior_Refined':part['label']='Tricuspid anterior leaflet — larger example'
 if part['id']=='Tricuspid_Posterior_Refined':part['label']='Tricuspid posterior (inferior) leaflet'
 if part['id']=='Tricuspid_Septal_Refined':part['label']='Tricuspid septal leaflet'
 if part['id']=='Mitral_Anterior_Refined':part['label']='Mitral anterior leaflet — broader radial reach'
 if part['id']=='Mitral_Posterior_Refined':part['label']='Mitral posterior leaflet — scalloped margin'
items=[e if a['id']==name else a for a in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text());manifest.update(parts=e['parts'],geometryRevision='tricuspid-septal-support-v1',remainingAnatomyLimitations=r['limitations']);manifest['anatomyChanges']+=['Added two direct septal cords with confirmed tissue contacts','Separated the medial support region from later-reference mural wall panels','Preserved the original early-cushion wall geometry']
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:shutil.copy2(src,dest)
p.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
p=base/'anatomy-review/status.json';d=json.loads(p.read_text());d['updated']='2026-10-21';a=next(a for a in d['assets'] if a['asset']==name);a.update(status='partially_corrected_valve_leaflets_and_chordae',geometryRevision='tricuspid-septal-support-v1',findingOrReviewTask='Direct septal support correction completed in the regional valve reference, alongside unequal AV leaflets and semilunar pockets. Full stage-specific anatomy remains unvalidated.');p.write_text(json.dumps(d,indent=2)+'\n')
print('Installed direct septal support:',len(e['parts']),'parts')

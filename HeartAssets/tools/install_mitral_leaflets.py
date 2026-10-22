from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'HeartAssets';out=base/'refinements/mitral-leaflets';name='Heart_09_ValvularRefinement'
r=json.loads((out/'validation.json').read_text());assert r['passed'] and r['parts']==55
usd=out/(name+'.usdz');assert hashlib.sha256(usd.read_bytes()).hexdigest()==r['usdzSHA256']
e=json.loads((out/'catalog-entry.json').read_text());assert len(e['parts'])==55
p=ROOT/'heart v3/Resources/HeartModels.json';items=json.loads(p.read_text())
e['anatomyReview']['supports']='Later-reference mitral leaflets have unequal attachment arcs and radial reach, with a three-scallop posterior margin and branching chordae from both papillary muscles. Semilunar cusps retain pockets, sinus walls and removable aortic tissue layers.'
e['anatomyReview']['limitations']='Isolated partly open teaching stations, not measured stage-specific anatomy. Dimensions, chordal counts and a three-scallop posterior example are illustrative; leaflet variants occur. Planar annular support, aortomitral continuity, coronary ostia, early cushions and tricuspid morphology remain incomplete.'
for part in e['parts']:
 if part['id']=='Mitral_Anterior_Refined':part['label']='Mitral anterior leaflet — broader radial reach'
 if part['id']=='Mitral_Posterior_Refined':part['label']='Mitral posterior leaflet — scalloped margin'
items=[e if a['id']==name else a for a in items]
manifest=json.loads((out/'before'/(name+'.json')).read_text());manifest.update(parts=e['parts'],geometryRevision='mitral-leaflets-v1',remainingAnatomyLimitations=r['limitations']);manifest['anatomyChanges']+=['Replaced equal mitral funnel halves with unequal anterior/posterior leaflets','Added posterior scallop indentations','Reattached branching chordae to the new free margins, preserving both-leaflet papillary supply']
for src,dest in [(usd,ROOT/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/usd.name),(out/(name+'.blend'),base/'blender'/(name+'.blend'))]+[(out/(name+s+'.png'),base/'previews'/(name+s+'.png')) for s in ['_assembled','_layers']]:shutil.copy2(src,dest)
p.write_text(json.dumps(items,indent=2)+'\n');(base/'manifests'/(name+'.json')).write_text(json.dumps(manifest,indent=2)+'\n')
p=base/'anatomy-review/status.json';d=json.loads(p.read_text());d['updated']='2026-10-20';a=next(a for a in d['assets'] if a['asset']==name);a.update(status='partially_corrected_valve_leaflets_and_chordae',geometryRevision='mitral-leaflets-v1',findingOrReviewTask='Mitral leaflet asymmetry and posterior scallops added alongside branching chordae and semilunar pockets. Intact stage-specific valve-root and ventricular geometry remain outstanding.');p.write_text(json.dumps(d,indent=2)+'\n')
print('Installed mitral leaflets:',len(e['parts']),'parts')

from pathlib import Path
import json,shutil,hashlib,math
root=Path(__file__).resolve().parents[2]; base=root/'HeartAssets/hdbr-atlas'; entries=[]; reports=[]
for folder in sorted(base.glob('HDBR_CS*')):
    entry=json.loads((folder/'catalog-entry.json').read_text()); report=json.loads((folder/'validation.json').read_text())
    assert report['passed'] and all(p['vertexCoordinatesUnchanged'] for p in report['parts'])
    stage=int(entry['id'].split('_')[1][2:]); entry['stageIndex']={11:3,12:3,14:4,16:5,17:6,18:6,20:6}[stage]
    for i,part in enumerate(entry['parts']):
        angle=2*math.pi*i/len(entry['parts'])
        part['separationOffset']=[round(.055*math.cos(angle),5),round(.055*math.sin(angle),5),.025 if i%2 else -.025]
    source=folder/(entry['id']+'.usdz'); dest=root/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/source.name
    assert hashlib.sha256(source.read_bytes()).hexdigest()==report['usdzSHA256']
    shutil.copy2(source,dest)
    image=root/'heart v3/Assets.xcassets'/(entry['previewImage']+'.imageset'); image.mkdir(exist_ok=True)
    shutil.copy2(folder/'preview.png',image/'preview.png')
    (image/'Contents.json').write_text(json.dumps({'images':[{'filename':'preview.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))
    entries.append(entry); reports.append(report)
resources=root/'heart v3/Resources'
(resources/'HeartReferenceModels.json').write_text(json.dumps(entries,indent=2))
notice='''HDBR Atlas embryonic heart reconstructions

Source: HDBR Atlas (https://hdbratlas.org)
Models: https://hdbratlas.org/interactive/heart.html
Terms: https://hdbratlas.org/terms.html
Licence: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International
https://creativecommons.org/licenses/by-nc-sa/4.0/

The seven HDBR_CS* USDZ assets and their derived previews are adapted from HDBR Atlas and distributed under CC BY-NC-SA 4.0. This notice does not license the application's code or unrelated assets. Non-commercial educational use only.

Changes: converted GLB to USDZ in Blender, uniformly enlarged and centered for display, assigned readable region names and selection IDs, simplified an equivalent constant-colour shader for RealityKit compatibility, removed non-anatomical Cube helper objects, and generated preview images. Source mesh vertex coordinates and region colours retained. Original physical scale is not represented. No endorsement by HDBR is implied.

These models represent segmented anatomical regions, including chamber regions and vessel lumens. They do not provide complete tissue layers or every embryonic structure. Missing structures must not be interpreted as absent in the embryo. Carnegie stage and specimen IDs are retained; stage groups in the app are navigation aids, not exact calendar-age equivalences.

Requested references:
Kerwin et al. (2010). The HUDSEN Atlas: a three-dimensional (3D) spatial framework for studying gene expression in the developing human brain. Journal of Anatomy 217(4):289–299. https://doi.org/10.1111/j.1469-7580.2010.01290.x
Gerrelli et al. (2015). Enabling research with human embryonic and fetal tissue resources. Development 142:3073–3076. https://doi.org/10.1242/dev.122820

Source files and SHA-256 provenance are recorded in HDBR-Sources.json.
'''
(resources/'HDBR-Attribution.txt').write_text(notice); (base/'LICENSE-AND-ATTRIBUTION.txt').write_text(notice)
shutil.copy2(root/'HeartAssets/anatomy-review/reference-study/sources.json',resources/'HDBR-Sources.json')
(base/'installed-validation.json').write_text(json.dumps({'assets':reports,'parts':sum(len(r['parts']) for r in reports),'passed':True},indent=2))
p=root/'heart v3/ReferencesView.swift';p.write_text(p.read_text().replace('01283.x','01290.x'))
print(len(entries),'models;',sum(len(r['parts']) for r in reports),'regions installed')

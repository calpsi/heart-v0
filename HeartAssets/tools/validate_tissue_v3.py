"""Verify exported tissue maps, catalog identities and saved refinement state."""
import json,zipfile,struct
from pathlib import Path
from pxr import Usd,UsdShade,UsdGeom
B=Path(__file__).resolve().parents[1];P=B.parent
catalog=json.loads((P/'heart v3/Resources/HeartModels.json').read_text())
reports=[]
for entry in catalog:
    name=entry['id'];manifest=json.loads((B/'manifests'/(name+'.json')).read_text())
    if manifest.get('revision')!='tissue-v3':continue
    assert {p['id'] for p in entry['parts']}=={p['id'] for p in manifest['parts']},(name,'catalog part mismatch')
    path=P/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'/(name+'.usdz')
    stage=Usd.Stage.Open(str(path));surfaces=[]
    for prim in stage.Traverse():
        if prim.IsA(UsdShade.Shader):
            shader=UsdShade.Shader(prim)
            if shader.GetIdAttr().Get()=='UsdPreviewSurface':
                for channel in ['diffuseColor','roughness','normal']:
                    assert shader.GetInput(channel).HasConnectedSource(),(name,channel,'texture connection missing')
                surfaces.append(str(prim.GetPath()))
    assert surfaces,(name,'missing PBR shader')
    images=[]
    with zipfile.ZipFile(path) as archive:
        for member in archive.namelist():
            if not member.endswith('.png'):continue
            data=archive.read(member);assert data[:8]==b'\x89PNG\r\n\x1a\n'
            dimensions=struct.unpack('>II',data[16:24]);assert dimensions==(2048,2048),(name,dimensions)
            images.append(member)
    assert len(images)==3,(name,'expected one three-map atlas')
    reports.append({'asset':name,'passed':True,'catalogParts':len(entry['parts']),'pbrChannels':['diffuseColor','roughness','normal'],'textures':images,'textureResolution':2048,'bytes':path.stat().st_size})
(B/'refinements/tissue-v3/export-validation.json').write_text(json.dumps(reports,indent=2))
print('TISSUE EXPORT VALIDATION PASSED',len(reports),flush=True)

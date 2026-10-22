import json,struct,zipfile
from pathlib import Path
from PIL import Image
B=Path(__file__).resolve().parents[1];report=[]
for p in sorted((B/'manifests').glob('*.json')):
 d=json.loads(p.read_text());n=d['asset'];assert all(c['nonmanifold_edges']==0 and c['signed_volume']>0 for c in d['checks'])
 data=(B/'glb'/(n+'.glb')).read_bytes();magic,ver,length=struct.unpack_from('<4sII',data);assert magic==b'glTF' and ver==2 and length==len(data)
 clen,ctype=struct.unpack_from('<II',data,12);g=json.loads(data[20:20+clen]);names={n.get('name') for n in g['nodes']};assert all(p['id'] in names for p in d['parts'])
 assert all('bufferView' in i for i in g['images'])
 assert all('normalTexture' in m and 'baseColorTexture' in m['pbrMetallicRoughness'] and 'metallicRoughnessTexture' in m['pbrMetallicRoughness'] for m in g['materials'])
 with zipfile.ZipFile(B/'usdz'/(n+'.usdz')) as z:
  assert z.testzip() is None;assert any(x.endswith('.usdc') for x in z.namelist());assert len([x for x in z.namelist() if x.endswith('.png')])>=9
 assert (B/'fbx'/(n+'.fbx')).stat().st_size>1000000
 for view in ['Anterior','Posterior']:
  im=Image.open(B/'previews'/(n+'_'+view+'.png'));assert im.size==(1400,1700) and im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
 report.append({'asset':n,'parts':len(d['parts']),'triangles':sum(c['triangles'] for c in d['checks']),'glb_MB':round(len(data)/1024**2,1),'status':'passed'})
assert len(report)==4
(B/'validation.json').write_text(json.dumps({'status':'passed','scope':'Manifold positive-volume tissue meshes; GLB hierarchy and embedded PBR maps; USDZ archive; FBX presence; front/rear preview transparency. Not expert anatomical or physiological validation.','assets':report},indent=2));print(json.dumps(report,indent=2))

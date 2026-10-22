"""Validate portable containers and their correspondence with Blender part manifests."""
import json,struct,zipfile
from pathlib import Path
from PIL import Image
BASE=Path(__file__).resolve().parents[1]
report=[]
for manifest in sorted((BASE/'manifests').glob('*.json')):
 d=json.loads(manifest.read_text());name=d['asset'];row={'asset':name,'parts':len(d['parts']),'checks':[]}
 assert all(c['vertices']>0 and c['nonmanifold_edges']==0 and c['volume_m3']>0 for c in d['checks']),name
 row['checks'].append('All original tissue meshes nonempty, manifold and positive volume')
 for variant in ['Cutaway','Full']:
  path=BASE/'glb'/(name+'_'+variant+'.glb');data=path.read_bytes();magic,version,length=struct.unpack_from('<4sII',data)
  assert magic==b'glTF' and version==2 and length==len(data)
  chunklen,chunktype=struct.unpack_from('<II',data,12);assert chunktype==0x4E4F534A
  g=json.loads(data[20:20+chunklen]);names={n.get('name') for n in g['nodes']}
  expected={p['id'] for p in d['parts'] if variant=='Full' or p['role']!='removable_front'}
  assert expected<=names,(name,variant,expected-names)
  assert all('bufferView' in im for im in g['images'])
  assert all('baseColorTexture' in m['pbrMetallicRoughness'] and 'normalTexture' in m for m in g['materials'])
  if variant=='Cutaway':assert not {'AtrialWall_Anterior','VentricularWall_Anterior'}&names
  row[variant+'_glb']={'bytes':len(data),'mesh_nodes':len(expected),'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),'embedded_images':len(g['images'])}
  zpath=BASE/'usdz'/(name+'_'+variant+'.usdz')
  with zipfile.ZipFile(zpath) as z:
   assert z.testzip() is None
   assert any(n.endswith(('.usdc','.usd','.usda')) for n in z.namelist())
   textures=[n for n in z.namelist() if n.lower().endswith(('.png','.jpg','.jpeg'))]
   assert len(textures)>=12
   assert all(x.compress_type==zipfile.ZIP_STORED for x in z.infolist())
  row[variant+'_usdz']={'bytes':zpath.stat().st_size,'embedded_textures':len(textures)}
  row['checks'].append(variant+': GLB hierarchy, PBR images and container passed; USDZ archive and embedded texture checks passed')
 preview=BASE/'previews'/(name+'.png')
 with Image.open(preview) as im:
  assert im.mode=='RGBA';lo,hi=im.getchannel('A').getextrema();assert lo==0 and hi==255
  row['preview']={'size':im.size,'alpha':'transparent background, opaque anatomy'}
 report.append(row)
assert len(report)==4,'Expected four stages'
(BASE/'validation.json').write_text(json.dumps({'status':'passed','assets':report,'scope':'Mesh structure and export containers; not expert anatomical validation or an in-headset test'},indent=2))
print(json.dumps(report,indent=2))

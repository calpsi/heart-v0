import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pxr import Usd,UsdGeom
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'HeartAssets/refinements/mitral-leaflets';name='Heart_09_ValvularRefinement'
def hashes():
 return {o.name:hashlib.sha256(str([(tuple(v.co)) for v in o.data.vertices]).encode()).hexdigest() for o in bpy.data.objects if o.type=='MESH' and o.parent and o.parent.name==name}
bpy.ops.wm.open_mainfile(filepath=str(out/'before'/(name+'.blend')));before=hashes()
bpy.ops.wm.open_mainfile(filepath=str(out/(name+'.blend')));after=hashes();expected={'Mitral_Anterior_Refined','Mitral_Posterior_Refined'}|{f'MitralChord_{i}_{j}' for i in [1,2] for j in [1,2]};changed={n for n in before if before[n]!=after[n]};assert changed==expected,(changed,expected)
def tree(ident):
 o=bpy.data.objects[ident];o.data.calc_loop_triangles();return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)
a=tree('Mitral_Anterior_Refined');b=tree('Mitral_Posterior_Refined');assert not a.overlap(b),'Leaflets intersect'
for x in [.70,.72,.74]:
 for y in [-.18,-.17,-.16]:
  start=Vector((x,y,.30))*.065;end=Vector((x,y,-.30))*.065;d=end-start
  for t in [a,b]:assert t.ray_cast(start,d.normalized(),d.length)[0] is None,'Leaflet opening obstructed'
entry=json.loads((out/'catalog-entry.json').read_text());stage=Usd.Stage.Open(str(out/(name+'.usdz')));ids={str(attr.Get()) for p in stage.Traverse() for attr in p.GetAttributes() if attr.GetName()=='userProperties:part_id'};assert ids=={p['id'] for p in entry['parts']};assert len([p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)])==55
p=out/'validation.json';d=json.loads(p.read_text());d.update(unchangedOtherMeshes=len(before)-6,changedMeshes=sorted(changed),leafletIntersection=False,clearLeafletOpeningPaths=9,exportedParts=55);p.write_text(json.dumps(d,indent=2)+'\n');print('MITRAL PRESERVATION, OPENING, EXPORT PASS')

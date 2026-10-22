import bpy,sys,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pxr import Usd,UsdGeom
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'HeartAssets/refinements/semilunar-pockets';name='Heart_09_ValvularRefinement'
e=json.loads((out/'catalog-entry.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(out/(name+'.blend')))
ids={p['id'] for p in e['parts']};stage=Usd.Stage.Open(str(out/(name+'.usdz')));meshes=[p for p in stage.Traverse() if p.IsA(UsdGeom.Mesh)];exported={str(a.Get()) for p in stage.Traverse() for a in p.GetAttributes() if a.GetName()=='userProperties:part_id'};assert len(meshes)==len(ids)==55 and exported==ids
alltrees=[]
for p in e['parts']:
 if p.get('state','refined')!='refined':continue
 o=bpy.data.objects[p['id']];o.data.calc_loop_triangles();alltrees.append((o.name,BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)))
for x,z in [(.38,.52),(-.38,.62)]:
 for dx in [-.018,0,.018]:
  for dy in [-.018,0,.018]:
   a=Vector((x+dx,.91+dy,z-.05))*.065;b=Vector((x+dx,.91+dy,z+.40))*.065;d=b-a
   for ident,t in alltrees:assert t.ray_cast(a,d.normalized(),d.length)[0] is None,('blocked valve opening',ident,dx,dy)
p=out/'validation.json';r=json.loads(p.read_text());r.update(exportedMeshes=55,exportedIDsMatch=True,clearCentralPathsPerValve=9);p.write_text(json.dumps(r,indent=2)+'\n');print('EXPORT IDS AND BOTH OPEN VALVE PATHS PASS')

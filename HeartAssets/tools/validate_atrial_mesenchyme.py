"""Focused geometric regression checks, not anatomical certification."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
BASE=Path(__file__).resolve().parents[1]/'refinements/atrial-mesenchyme';NAME='Heart_05_AtrialSeptation'
bpy.ops.wm.open_mainfile(filepath=str(BASE/(NAME+'.blend')))
entry=json.loads((BASE/'catalog-entry.json').read_text());S=.065
def tree(name):
 o=bpy.data.objects[name];o.data.calc_loop_triangles()
 return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices],[tuple(t.vertices) for t in o.data.loop_triangles],all_triangles=True)
trees={p['id']:tree(p['id']) for p in entry['parts']};results=[]
for a,b in [('MesenchymalCap_Early','SeptumPrimum_Early'),('DorsalMesenchymalProtrusion_Early','MesenchymalCap_Early'),('DorsalMesenchymalProtrusion_Early','CushionAnchor_Dorsal'),('DorsalMesenchymalProtrusion_Early','AtrialWall_Posterior'),('MesenchymalComplex_Later','DorsalContribution_Later')]:
 overlap=len(trees[a].overlap(trees[b]));results.append({'a':a,'b':b,'intersectingFaces':overlap});assert overlap>0,(a,b,'detached')
# Cross the early primary opening between septal and cushion tissues.
# Restrict to the opening's central window, inside the surrounding atrial wall.
probes=0
for y in [-.08,0,.08]:
 for z in [0,.07,.14]:
  origin=Vector((-.25*S,y*S,z*S));direction=Vector((1,0,0))
  for part in entry['parts']:
   if part.get('state','early')!='early' or part['id'].startswith(('AtrialWall','AVCanal')):continue
   hit=trees[part['id']].ray_cast(origin,direction,.5*S)
   assert hit[0] is None,('Primary opening blocked',part['id'],y,z)
  probes+=1
report={'passed':True,'contacts':results,'earlyOpeningCrossingProbes':probes,'scope':'Local contact and opening checks only; enlarged schematic proportions not validated against histology'}
(BASE/'junction-validation.json').write_text(json.dumps(report,indent=2)+'\n');print(report)

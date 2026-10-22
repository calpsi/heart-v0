"""Focused geometric probes, not clinical or comprehensive anatomy validation."""
import bpy,json
from pathlib import Path
from mathutils import Vector
from pxr import Usd,UsdGeom
B=Path(__file__).resolve().parents[1];S=.065;results=[]
def hits(names,y,z):
 for name in names:
  o=bpy.data.objects.get(name)
  if not o:continue
  origin=o.matrix_world.inverted()@Vector((-2*S,y*S,z*S));direction=(o.matrix_world.inverted().to_3x3()@Vector((1,0,0))).normalized()
  if o.ray_cast(origin,direction,distance=4*S)[0]:return True
 return False
for path in sorted((B/'blender').glob('*.blend')):
 bpy.ops.wm.open_mainfile(filepath=str(path));stage=int(path.stem.split('_')[1]);tests={}
 tests['superior_ventricular_gap_matches_stage']=hits(['MuscularInterventricularSeptum','MembranousSeptalClosure'],.05,0)==(stage>=3)
 tests['cushion_fusion_matches_stage']=hits(['DorsalEndocardialCushion','VentralEndocardialCushion'],0,.245)==(stage>=2)
 tests['ostium_primum_matches_stage']=hits(['SeptumPrimum'],.05,.44)==(stage>=2)
 if stage>=2:tests['ostium_secundum_is_real_hole']=not hits(['SeptumPrimum'],.18,1.09)
 if stage>=3:
  tests['foramen_ovale_rim_has_lower_opening']=not hits(['SeptumSecundum'],.02,.70)
  tests['primum_flap_overlaps_lower_opening']=hits(['SeptumPrimum'],.02,.70)
  tests['secundum_overlaps_upper_primum_opening']=hits(['SeptumSecundum'],.18,1.09)
 for variant in ['Cutaway','Full']:
  usd=Usd.Stage.Open(str(B/'usdz'/(path.stem+'_'+variant+'.usdz')))
  tests[variant+'_usd_Y_up']=UsdGeom.GetStageUpAxis(usd)=='Y'
  tests[variant+'_usd_metres']=UsdGeom.GetStageMetersPerUnit(usd)==1.0
  tests[variant+'_usd_has_meshes']=sum(p.IsA(UsdGeom.Mesh) for p in usd.Traverse())>20
 results.append({'asset':path.stem,'tests':tests})
print(json.dumps(results,indent=2))
(B/'anatomy-probes.json').write_text(json.dumps({'scope':'Local geometry probes at named landmarks; not comprehensive lumen connectivity, physiology, or expert anatomy validation','assets':results},indent=2))
assert len(results)==4
assert all(all(r['tests'].values()) for r in results)

import bpy,bmesh,json,hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pxr import Usd,UsdGeom
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'HeartAssets/refinements/tricuspid-septal-support';name='Heart_09_ValvularRefinement'
def hashes():
 return {o.name:hashlib.sha256(str([tuple(v.co) for v in o.data.vertices]).encode()).hexdigest() for o in bpy.data.objects if o.type=='MESH' and o.parent and o.parent.name==name}
def volume(o):
 bm=bmesh.new();bm.from_mesh(o.data);v=abs(bm.calc_volume(signed=True));bm.free();return v
bpy.ops.wm.open_mainfile(filepath=str(out/'before'/(name+'.blend')));before=hashes();originalVolume=sum(volume(bpy.data.objects['TricuspidWall_'+p]) for p in ['Anterior','Posterior']);old=next(e for e in json.loads((out/'before/HeartModels.json').read_text()) if e['id']==name)
bpy.ops.wm.open_mainfile(filepath=str(out/(name+'.blend')));after=hashes();assert all(before[n]==after[n] for n in before),'Original meshes changed'
e=json.loads((out/'catalog-entry.json').read_text());early=lambda entry:{p['id'] for p in entry['parts'] if p.get('state','cushions')=='cushions'};assert early(old)==early(e),'Early state changed'
replacementVolume=sum(volume(bpy.data.objects[n]) for n in ['TricuspidMuralWall_Anterior','TricuspidMuralWall_Posterior','TricuspidSeptalSupport_Refined']);difference=abs(replacementVolume-originalVolume)/originalVolume;assert difference<.03,difference
stage=Usd.Stage.Open(str(out/(name+'.usdz')));ids={str(a.Get()) for p in stage.Traverse() for a in p.GetAttributes() if a.GetName()=='userProperties:part_id'};assert ids=={p['id'] for p in e['parts']} and len(ids)==60
p=out/'validation.json';r=json.loads(p.read_text());r.update(originalMeshesUnchanged=len(before),earlyStateUnchanged=True,wallVolumeRelativeDifference=difference,exportedParts=60);p.write_text(json.dumps(r,indent=2)+'\n');print('SEPTAL SUPPORT PRESERVATION AND EXPORT PASS',difference)

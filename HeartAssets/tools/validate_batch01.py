"""Validate source topology and the actual exported USDZ hierarchy/materials."""
import bpy, bmesh, json, zipfile, sys, argparse
from pathlib import Path
from pxr import Usd, UsdGeom, UsdShade, Sdf

base=Path(__file__).resolve().parents[1]
exports=base.parent/'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'
parser=argparse.ArgumentParser();parser.add_argument('--stage',type=int)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
reports=[]
for manifest_path in sorted((base/'manifests').glob('*.json')):
    if args.stage is not None and not manifest_path.name.startswith(f'Heart_{args.stage:02}_'):continue
    manifest=json.loads(manifest_path.read_text())
    name=manifest['asset']
    bpy.ops.wm.open_mainfile(filepath=str(base/'blender'/(name+'.blend')))
    triangles=0; mesh_reports=[]
    for part in manifest['parts']:
        obj=bpy.data.objects[part['id']]
        bm=bmesh.new(); bm.from_mesh(obj.data)
        nonmanifold=sum(not e.is_manifold for e in bm.edges)
        volume=bm.calc_volume(signed=True)
        assert nonmanifold==0,(obj.name,nonmanifold)
        assert volume>0,(obj.name,'inverted or zero-volume surface',volume)
        bm.free()
        obj.data.calc_loop_triangles()
        count=len(obj.data.loop_triangles); triangles+=count
        mesh_reports.append({'id':obj.name,'triangles':count,'nonmanifold_edges':nonmanifold})
    # Verify that the teaching apertures are empty geometry, not painted marks.
    def ray_hits(part_id, start, direction, distance=1000):
        from mathutils import Vector
        obj=bpy.data.objects[part_id]
        inv=obj.matrix_world.inverted()
        origin=inv @ (Vector(start)*0.065)
        local_direction=(inv.to_3x3() @ Vector(direction)).normalized()
        return obj.ray_cast(origin,local_direction,distance=distance*0.065)[0]
    if name=='Heart_05_AtrialSeptation':
        assert not ray_hits('SeptumPrimum_Early',(-.4,0,.1),(1,0,0)), 'Ostium primum obstructed'
        assert ray_hits('SeptumPrimum_Early',(-.4,0,1),(1,0,0)), 'Primum roof missing'
        assert not ray_hits('SeptumPrimum_Later',(-.4,0,.99),(1,0,0)), 'Ostium secundum obstructed'
        assert ray_hits('SeptumPrimum_Later',(-.4,0,.1),(1,0,0)), 'Lower flap missing'
        assert not ray_hits('SeptumSecundum_Later',(-.4,0,.2),(1,0,0)), 'Foramen ovale rim obstructed'
    if name=='Heart_06_EndocardialCushions':
        for part_id in ['CushionSuperior_Unfused','CushionInferior_Unfused']:
            assert not ray_hits(part_id,(0,0,1),(0,0,-1)), 'Unfused gap obstructed'
        for part_id, y in [('CushionSuperior_Fused',.1),('CushionInferior_Fused',-.1)]:
            assert ray_hits(part_id,(0,y,1),(0,0,-1)), 'Fused bridge missing'
        for side in [-.65,.65]:
            for part in manifest['parts']:
                if part.get('state') in [None,'fused']:
                    assert not ray_hits(part['id'],(side,0,1),(0,0,-1)), 'AV opening obstructed'
    if name=='Heart_07_VentricularSeptation':
        for part_id in ['MuscularSeptum_Open','AVSeptalContribution','OutletSeptalContribution']:
            assert not ray_hits(part_id,(-.4,-.18,.51),(1,0,0)), 'Interventricular communication obstructed'
        assert ray_hits('MuscularSeptum_Open',(-.4,0,-.5),(1,0,0)), 'Muscular septum missing'
        assert ray_hits('MembranousSeptum_Closed',(-.4,-.18,.51),(1,0,0)), 'Closure patch missing'
        for x,prefix in [(.43,'SubaorticOutlet'),(-.43,'SubpulmonaryOutlet')]:
            for panel in ['Anterior','Posterior']:
                assert not ray_hits(prefix+'_'+panel,(x,-.28,2),(0,0,-1)), 'Outlet lumen obstructed'
    if name=='Heart_08_OutflowSeptation':
        from mathutils import Vector
        from math import sin,cos,pi
        for t in [.15,.35,.55,.75,.95]:
            angle=pi*.5*t
            c=Vector((.12*sin(pi*t),0,-1.15+2.6*t));u=Vector((cos(angle),sin(angle),0));v=Vector((-sin(angle),cos(angle),0))
            for ridge in ['Septal','Parietal']:
                assert not ray_hits(ridge+'Ridge_Ridges',c-u*.2,u,.4), 'Early central passage obstructed'
            assert ray_hits('SeptalRidge_Divided',c-u*.2,u,.4), 'Late partition incomplete'
            for side in [-1,1]:
                for ridge in ['Septal','Parietal']:
                    assert not ray_hits(ridge+'Ridge_Divided',c+side*.28*v-u*.15,u,.3), 'One divided channel obstructed'
        for x,prefix in [(-.28,'AorticTrunk'),(.28,'PulmonaryTrunk')]:
            for panel in ['Anterior','Posterior']:
                assert not ray_hits(prefix+'_'+panel,(x,0,2.3),(0,0,-1)), 'Trunk outlet obstructed'
        assert sum('CuspPrimordium' in p['id'] for p in manifest['parts'])==6
    if name=='Heart_09_ValvularRefinement':
        ids={p['id'] for p in manifest['parts']}
        for valve,count in [('Mitral',2),('Tricuspid',3),('Aortic',3),('Pulmonary',3)]:
            early=[p for p in manifest['parts'] if p['id'].startswith(valve+'_') and p.get('state')=='cushions']
            assert len(early)==count, (valve,'incorrect leaflet count')
        assert len([p for p in manifest['parts'] if 'Chord_' in p['id']])==10
        assert len([p for p in manifest['parts'] if 'Papillary_' in p['id']])==5
        for layer in ['Fibrosa','Spongiosa','Ventricularis']:
            assert layer+'_AorticCusp1_Refined' in ids
        # The central opening is not capped by a hidden leaflet face.
        for x,y in [(.72,0),(-.72,0),(.38,.91),(-.38,.91)]:
            for part in manifest['parts']:
                if part.get('state') in ['cushions','refined'] and 'Chord_' not in part['id']:
                    assert not ray_hits(part['id'],(x,y,1.5),(0,0,-1),2), 'Valve orifice capped'
    if name=='Heart_10_CirculatoryTransition':
        from mathutils import Vector
        assert not ray_hits('AtrialSeptum',(-.09,0,.78),(1,0,0),.19), 'Foramen rim obstructed'
        assert not ray_hits('ForamenFlap_Fetal',(-.09,0,.78),(1,0,0),.19), 'Fetal flap closes entry'
        assert ray_hits('ForamenFlap_Transition',(-.09,0,.78),(1,0,0),.19), 'Postnatal flap not apposed'
        c=Vector((.66,-.24,1.25));t=Vector((.73,.49,.31)).normalized();u=Vector((0,1,0)).cross(t).normalized()
        assert not ray_hits('Ductus_Fetal',c-u*.06,u,.12), 'Fetal duct lumen obstructed'
        assert ray_hits('Ductus_Transition',c-u*.06,u,.12), 'Duct lumen did not narrow'
        assert not ray_hits('Ductus_Transition',c-u*.012,u,.024), 'Transition falsely shows complete obliteration'
        t=Vector((.31,.16,.14)).normalized()
        assert not ray_hits('PulmonaryArtery',(.35,-.40,1.11),t,.23), 'Pulmonary duct junction blocked'
    if name=='Heart_11_VentricularSeptalDefect':
        # Test a finite cross-septal path, so the distant chamber wall does not
        # count as an obstruction. All active meshes must leave the gap clear.
        for part in manifest['parts']:
            if part.get('state') in [None,'defect']:
                assert not ray_hits(part['id'],(-.38,-.18,.51),(1,0,0),.76), ('VSD obstructed',part['id'])
        assert ray_hits('MembranousSeptum_Closed',(-.38,-.18,.51),(1,0,0),.76), 'Intact ventricular comparison has a hole'
        assert ray_hits('MuscularSeptum_Open',(-.38,0,-.5),(1,0,0),.76), 'Inferior muscular septum absent'
        assert len([p for p in manifest['parts'] if p['id'].startswith('AorticCusp_')])==3
    if name=='Heart_12_AtrialSeptalDefect':
        for y,z in [(0,.52),(.10,.52),(0,.65)]:
            for part in manifest['parts']:
                if part.get('state') in [None,'defect']:
                    assert not ray_hits(part['id'],(-.38,y,z),(1,0,0),.76), ('ASD obstructed',part['id'])
            assert ray_hits('FossaFloor_Intact',(-.38,y,z),(1,0,0),.76), 'Intact oval fossa has a hole'
        assert ray_hits('FossaFloor_Defect',(-.38,.30,.52),(1,0,0),.76), 'Residual fossa tissue absent'
        assert ray_hits('AtrialSeptalRim',(-.38,.48,.52),(1,0,0),.76), 'Oval fossa rim absent'
    if name=='Heart_13_TetralogyOfFallot':
        for part in manifest['parts']:
            if part.get('state')=='fallot':
                assert not ray_hits(part['id'],(-.17,.10,.39),(1,0,0),.34), ('Fallot VSD blocked',part['id'])
        assert ray_hits('VentricularSeptum_Normal_Fallot',(-.17,.10,.39),(1,0,0),.34), 'Comparison VSD remains open'
        for panel in ['Anterior','Posterior']:
            assert not ray_hits('RVOutflow_Normal_Fallot_'+panel,(-.55,-.30,.88),(1,0,0),.14), 'Normal RVOT too narrow'
        assert ray_hits('RVOutflow_Fallot_Posterior',(-.55,-.29,.88),(1,0,0),.14), 'Fallot narrowing absent'
        assert not ray_hits('RVOutflow_Fallot_Posterior',(-.55,-.29,.88),(1,0,0),.05), 'Fallot falsely shows atresia'
        # The same short radial segment lies in thickened RV muscle only.
        assert ray_hits('VentricularWall_R_Fallot_Posterior',(-.86,.10,-.40),(-1,0,0),.12), 'RV thickening absent'
        assert not ray_hits('VentricularWall_R_Normal_Fallot_Posterior',(-.86,.10,-.40),(-1,0,0),.12), 'Normal RV wall unexpectedly thick'
        # Both sides of the septal crest enter the overriding aortic mouth.
        for x in [-.12,.16]:
            for part in manifest['parts']:
                if part.get('state')=='fallot':
                    assert not ray_hits(part['id'],(x,.14,.36),(0,0,1),.45), ('Overriding mouth obstructed',part['id'])
    if name=='Heart_14_TranspositionGreatArteries':
        # Independent expected root positions: true origins must connect to
        # the appropriate ventricular cavity and retain an open proximal bore.
        for state,ao,pa in [('tga',(-.47,-.36),(.44,.20)),('normal',(.43,.16),(-.55,-.30))]:
            for prefix,(x,y) in [('Aorta',ao),('PulmonaryTrunk',pa)]:
                obj=bpy.data.objects[prefix+'_'+state.title()]
                points=[obj.matrix_world @ v.co for v in obj.data.vertices]
                # The sampled curve tilts the mouth plane slightly. Include
                # the whole initial ring, not just its lowest edge vertices.
                mouth=[v for v in points if v.z < .04*.065]
                assert len(mouth)>=64, 'Incomplete proximal mouth rings'
                assert abs(sum(v.x for v in mouth)/len(mouth)/.065-x)<.01, 'Wrong ventricular origin X'
                assert abs(sum(v.y for v in mouth)/len(mouth)/.065-y)<.01, 'Wrong ventricular origin Y'
                for part in manifest['parts']:
                    if part.get('state') in [None,state]:
                        assert not ray_hits(part['id'],(x,y,.06),(0,0,1),.74), ('Proximal artery blocked',part['id'],state)
            assert ray_hits('VentricularSeptum_'+state.title(),(-.2,0,-.4),(1,0,0),.4), 'Unintended ventricular communication'
        for part in manifest['parts']:
            if part.get('state') in [None,'tga']:
                assert not ray_hits(part['id'],(-.25,1.0,1.02),(1,0,0),.5), ('Atrial mixing path blocked',part['id'])
        assert ray_hits('AtrialSeptum_Normal',(-.25,1.0,1.02),(1,0,0),.5), 'Normal atrial comparison open'
    if name=='Heart_15_AorticCoarctation':
        assert ray_hits('AorticIsthmus_Coarctation_Posterior',(1.05,-.06,.72),(0,1,0),.13), 'Coarctation narrowing absent'
        for panel in ['Anterior','Posterior']:
            assert not ray_hits('AorticIsthmus_Normal_'+panel,(1.05,-.06,.72),(0,1,0),.13), 'Open comparison still narrowed'
        # Both states retain an axial channel; coarctation is not interruption.
        for state in ['coarctation','normal']:
            for part in manifest['parts']:
                if part.get('state') in [None,state]:
                    assert not ray_hits(part['id'],(1.05,-.06,.21),(0,0,1),.64), ('Aortic channel capped',part['id'])
        assert 'LeftSubclavian_Posterior' in {p['id'] for p in manifest['parts']}
    if name=='Heart_16_PatentDuctusArteriosus':
        from mathutils import Vector
        start=Vector((.55,-.40,.40));end=Vector((1.05,0,.58));delta=end-start
        for part in manifest['parts']:
            if part.get('state') in [None,'patent']:
                assert not ray_hits(part['id'],start,delta.normalized(),delta.length), ('Patent duct path blocked',part['id'])
        assert ray_hits('PulmonaryTrunk_Closed',start,delta.normalized(),delta.length), 'Closed pulmonary wall has a residual ductal hole'
        assert any(ray_hits('AorticIsthmus_Closed_'+panel,start,delta.normalized(),delta.length) for panel in ['Anterior','Posterior']), 'Closed aortic wall has a residual ductal hole'
        normal=Vector((-.8,1,0)).normalized()
        assert any(ray_hits('Ductus_Patent_'+panel,(.80,-.20,.49),normal,.20) for panel in ['Anterior','Posterior']), 'Ductal wall missing'
        assert ray_hits('Ligamentum_Closed',(.69,-.14,.60),(0,0,-1),.20), 'Closed remnant missing'
    usdz=exports/(name+'.usdz')
    stage=Usd.Stage.Open(str(usdz))
    assert stage and stage.GetDefaultPrim()
    assert UsdGeom.GetStageUpAxis(stage)=='Y'
    assert UsdGeom.GetStageMetersPerUnit(stage)==1
    prims=list(stage.Traverse())
    names={p.GetName() for p in prims}
    for part in manifest['parts']:
        assert part['id'] in names,('missing exported part',part['id'])
    usd_meshes=[p for p in prims if p.IsA(UsdGeom.Mesh)]
    assert len(usd_meshes)==len(manifest['parts'])
    for p in usd_meshes:
        binding=UsdShade.MaterialBindingAPI(p).ComputeBoundMaterial()[0]
        assert binding,('missing material',str(p.GetPath()))
    assert not any(p.IsA(UsdGeom.Camera) for p in prims)
    with zipfile.ZipFile(usdz) as archive:
        textures=[n for n in archive.namelist() if n.lower().endswith('.png')]
        assert textures,'no embedded textures'
        assert archive.testzip() is None
    report={'asset':name,'mesh_count':len(usd_meshes),'triangles':triangles,
            'embedded_textures':len(textures),'usdz_bytes':usdz.stat().st_size,
            'metres_per_unit':1,'up_axis':'Y','parts':mesh_reports}
    reports.append(report)
    manifest['triangles']=triangles
    manifest_path.write_text(json.dumps(manifest,indent=2))
validated_now=list(reports)
for revision in ('tissue-v3','tissue-v4'):
    progress_path=base/'refinements'/revision/'progress.json'
    if progress_path.exists():
        progress=json.loads(progress_path.read_text())
        for item in progress['stages'].values():
            current=json.loads((base/'manifests'/(item['asset']+'.json')).read_text())
            if current.get('revision')==revision and any(r['asset']==item['asset'] for r in validated_now):
                item['status']='source topology and USDZ validated; runtime check pending'
        progress_path.write_text(json.dumps(progress,indent=2))
if args.stage is not None and (base/'validation.json').exists():
    previous=json.loads((base/'validation.json').read_text())
    names={r['asset'] for r in reports}
    reports=sorted([r for r in previous if r['asset'] not in names]+reports,key=lambda r:r['asset'])
(base/'validation.json').write_text(json.dumps(reports,indent=2))
print('VALIDATION PASSED',json.dumps([{k:v for k,v in r.items() if k!='parts'} for r in validated_now]),flush=True)

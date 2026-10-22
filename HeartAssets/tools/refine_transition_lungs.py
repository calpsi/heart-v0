"""Refine perinatal orientation lungs; illustrative contours, not scan geometry."""
import bpy, bmesh, json, math, shutil, hashlib, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_batch01 as core

NAME = 'Heart_10_CirculatoryTransition'
OUT = core.BASE / 'refinements/transition-lungs'
BACK = OUT / 'before'
BACK.mkdir(parents=True, exist_ok=True)
for source in [core.BASE/'blender'/(NAME+'.blend'), core.EXPORT/(NAME+'.usdz'), core.BASE/'manifests'/(NAME+'.json')]:
    if not (BACK/source.name).exists(): shutil.copy2(source, BACK/source.name)
bpy.ops.wm.open_mainfile(filepath=str(BACK/(NAME+'.blend')))
bpy.context.preferences.filepaths.save_version = 0
root = bpy.data.objects[NAME]
entry = next(e for e in json.loads((core.PROJECT/'heart v3/Resources/HeartModels.json').read_text()) if e['id'] == NAME)
unchanged = {o.name: [tuple(v.co) for v in o.data.vertices] for o in root.children_recursive if o.type == 'MESH' and not o.name.startswith('Lung_')}
checks = []
for suffix, side in [('R', -1), ('L', 1)]:
    o = bpy.data.objects['Lung_'+suffix]
    # Retain topology, UVs, material, object transform and part metadata.
    for v in o.data.vertices:
        x,y,z = (c/core.S for c in v.co)
        t = max(-1., min(1., z/.85))
        # Rounded apex, wider basal contour, and a broad diaphragmatic base.
        height = .88*t if t >= 0 else -.73*(-t)**.42
        width = (1.12-.32*t) * (1.05 if suffix == 'R' else .94)
        x *= width
        y *= 1.40-.16*t
        medial = max(0., -side*x/.5)
        anterior = max(0., -y/.45)
        # Left anteromedial indentation accommodates the heart; the lungs
        # remain laterally displaced in this regional teaching assembly.
        if suffix == 'L':
            notch = .17*math.exp(-((height+.12)/.30)**2)*medial*anterior
            x += notch
        # Shallow surface fissures: oblique on both lungs; horizontal on right.
        oblique = math.exp(-((height-(.12+1.05*y))/.033)**2)
        horizontal = math.exp(-((height-.23)/.025)**2)*max(0., min(1., (.15-y)/.20)) if suffix == 'R' else 0.
        indent = 1.-.085*oblique-.065*horizontal
        v.co = (x*indent*core.S, y*indent*core.S, height*core.S)
    o.data.update()
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges), o.name
    volume=bm.calc_volume(signed=True); assert volume>0, o.name
    bm.to_mesh(o.data); bm.free()
    checks.append({'part':o.name,'manifold':True,'volume':volume,'vertices':len(o.data.vertices)})
for name, coordinates in unchanged.items():
    assert coordinates == [tuple(v.co) for v in bpy.data.objects[name].data.vertices], name
assert all(bpy.data.objects.get(p['id']) is not None for p in entry['parts'])
bpy.ops.object.select_all(action='DESELECT')
for o in core.descendants(root): o.hide_set(False); o.hide_render=False; o.select_set(True)
bpy.context.view_layer.objects.active=root
usd=OUT/(NAME+'.usdz')
bpy.ops.wm.usd_export(filepath=str(usd), selected_objects_only=True, export_animation=False,
    export_materials=True, generate_preview_surface=True, generate_materialx_network=False,
    export_textures_mode='NEW', export_custom_properties=True, convert_orientation=True,
    export_global_up_selection='Y', export_global_forward_selection='NEGATIVE_Z',
    export_lights=False, export_cameras=False, triangulate_meshes=True,
    root_prim_path='/HeartAsset', convert_scene_units='METERS', meters_per_unit=1)
scene=bpy.context.scene
scene.render.resolution_x=1000; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.cycles.samples=16
for state, suffix in [('fetal','assembled'),('transition','layers')]:
    for p in entry['parts']:
        o=bpy.data.objects[p['id']]
        hidden=p.get('state',state)!=state or p['id'].endswith('_Anterior')
        o.hide_render=hidden; o.hide_set(hidden)
    if state=='fetal': bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(NAME+'.blend')))
    scene.render.filepath=str(OUT/(NAME+'_'+suffix+'.png'))
    bpy.ops.render.render(write_still=True)
(OUT/'validation.json').write_text(json.dumps({'passed':True,'asset':NAME,'parts':len(entry['parts']),
    'checks':checks,'otherMeshCoordinatesUnchanged':True,'usdzSHA256':hashlib.sha256(usd.read_bytes()).hexdigest(),
    'limitations':['Illustrative perinatal lung contours, not a fetal scan reconstruction',
    'Fissures are surface grooves, not independently separable lobes',
    'Lungs remain displaced laterally for teaching; no inflation or perfusion simulation']},indent=2)+'\n')
print('TRANSITION LUNGS VALIDATED', flush=True)

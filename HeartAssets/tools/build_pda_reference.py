"""Author matched PDA/closed-remnant regional anatomy for HeartV0 (Blender 5.2).
Reuses the project batch08 vessel arrangement, not a patient specimen. True
communicating lumens, smooth tapered vessels and three independently movable
parts. Surface grain is illustrative, not microscopic/histological evidence.
Run: Blender --background --factory-startup --python this_file
"""
import bpy, bmesh, json, math, sys
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi
BASE = Path(__file__).resolve().parents[1]
ROOT = BASE.parent
OUT = ROOT / 'heart v3/Resources/HeartProject'
WORK = BASE / 'authored/pda'
WORK.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(Path(__file__).parent))
from build_batch05 import samples
S = .065
# Same anatomical coordinates as the existing V0 regional model: +X patient
# left, +Z superior, -Y anterior. No unrelated whole-heart shape is deformed.
AO = [(-.65,.06,-1.1),(-.69,.04,-.2),(-.64,.02,.68),(-.46,.08,1.31),
      (.03,.17,1.64),(.57,.17,1.55),(.96,.12,1.15),(1.06,.10,.59),(1.10,.13,-.25),(1.16,.18,-1.2)]
BRANCHES = [[(-.48,.08,1.28),(-.60,.10,1.78),(-.80,.11,2.10)],
            [(.06,.17,1.64),(.12,.20,1.94),(.18,.21,2.20)],
            [(.67,.16,1.47),(.94,.20,1.81),(1.20,.25,2.04)]]
PA = [(-.98,-.56,-.94),(-.77,-.55,-.20),(-.28,-.43,.39),(.30,-.29,.52),(.80,-.18,.48),(1.62,-.10,.37)]
RP = [(-.28,-.43,.39),(-.53,.12,.48),(-1.12,.28,.37),(-1.55,.30,.30)]
DUCT = [(.39,-.27,.515),(.62,-.16,.56),(.84,.01,.63),(1.055,.10,.66)]


def clear():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)


def sweep(name, knots, radius):
    pts = samples(knots, steps=12)
    vs=[]; fs=[]; n=64
    for i,p in enumerate(pts):
        t=i/(len(pts)-1)
        tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        ref=Vector((0,1,0))
        if abs(ref.dot(tangent))>.94: ref=Vector((1,0,0))
        u=ref.cross(tangent).normalized(); v=tangent.cross(u).normalized()
        r=radius(t)
        for j in range(n):
            a=2*pi*j/n
            vs.append(tuple(S*(p+r*(cos(a)*u+sin(a)*v))))
    for i in range(len(pts)-1):
        for j in range(n):
            a=i*n+j; b=i*n+(j+1)%n
            fs.append((a,b,b+n,a+n))
    fs += [tuple(reversed(range(n))),tuple((len(pts)-1)*n+j for j in range(n))]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(vs,[],fs); mesh.update()
    o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o)
    return o


def boolean(a,b,operation):
    bpy.context.view_layer.objects.active=a
    m=a.modifiers.new(operation,'BOOLEAN'); m.operation=operation; m.solver='MANIFOLD'; m.object=b
    bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.data.objects.remove(b,do_unlink=True)


def copy(o):
    c=o.copy(); c.data=o.data.copy(); bpy.context.collection.objects.link(c); return c


def extended(path, amount=.45):
    p=[Vector(v) for v in path]
    p[0]-=(p[1]-p[0]).normalized()*amount
    p[-1]+=(p[-1]-p[-2]).normalized()*amount
    return p


def arterial(name,inner=False):
    offset=.055 if inner else 0
    a=sweep(name,extended(AO,.16) if inner else AO,lambda t:.29-.045*t+.012*sin(pi*t)-offset)
    for i,path in enumerate(BRANCHES):
        b=sweep('Branch',extended(path,.18) if inner else path,lambda t:.125-.025*t-(.038 if inner else 0))
        boolean(a,b,'UNION')
    return a


def pulmonary(name,inner=False):
    a=sweep(name,extended(PA,.18) if inner else PA,lambda t:.275-.105*t-(.05 if inner else 0))
    b=sweep('RightBranch',extended(RP,.20) if inner else RP,lambda t:.19-.05*t-(.045 if inner else 0))
    boolean(a,b,'UNION'); return a


def material(name,rgb):
    # Shared runtime grain and roughness, explicit UVs; a subtle portable normal
    # map adds fine relief without moving the vessel walls or junctions.
    m=bpy.data.materials.new(name); m.use_nodes=True
    tree=m.node_tree; p=tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*rgb,1); p.inputs['Roughness'].default_value=.48
    grain=tree.nodes.new('ShaderNodeTexImage')
    grain.image=bpy.data.images.load(str(ROOT/'heart v3/Resources/MorphTissueGrain.png'),check_existing=True)
    # Bake palette into RGB texture for portable USD Preview Surface, no procedural nodes.
    import numpy as np
    pix=np.array(grain.image.pixels[:]).reshape((-1,4)); value=pix[:,:3].mean(axis=1)
    img=bpy.data.images.new(name+'_Color',width=256,height=256)
    data=np.ones((len(value),4),dtype=np.float32)
    for k,c in enumerate(rgb): data[:,k]=np.clip(c*(.90+.10*value),0,1)
    img.pixels.foreach_set(data.ravel()); img.filepath_raw=str(WORK/(name+'.png')); img.file_format='PNG'; img.save()
    grain.image=img; tree.links.new(grain.outputs['Color'],p.inputs['Base Color'])
    rough=tree.nodes.new('ShaderNodeTexImage'); rough.image=bpy.data.images.load(str(ROOT/'heart v3/Resources/MorphTissueRoughness.png'),check_existing=True)
    rough.image.colorspace_settings.name='Non-Color'
    # The live morph multiplies this map by the shared 0.48 roughness. Bake
    # that factor for USD rather than exporting the almost-matte raw map.
    rp=np.array(rough.image.pixels[:],dtype=np.float32).reshape((-1,4)); rp[:,:3]*=.48
    ri=bpy.data.images.new(name+'_Roughness',width=256,height=256); ri.colorspace_settings.name='Non-Color'; ri.pixels.foreach_set(rp.ravel())
    ri.filepath_raw=str(WORK/(name+'_roughness.png')); ri.file_format='PNG'; ri.save()
    rough.image=ri; tree.links.new(rough.outputs['Color'],p.inputs['Roughness'])
    # Low-amplitude finite differences in the same grain; no invented tissue bands.
    pixels=value.reshape(256,256); gx=np.roll(pixels,-1,axis=1)-np.roll(pixels,1,axis=1); gy=np.roll(pixels,-1,axis=0)-np.roll(pixels,1,axis=0)
    normal=np.ones((256,256,4),dtype=np.float32); normal[:,:,0]=.5-.12*gx; normal[:,:,1]=.5-.12*gy; normal[:,:,2]=1
    nm=bpy.data.images.new(name+'_Normal',width=256,height=256); nm.colorspace_settings.name='Non-Color'; nm.pixels.foreach_set(normal.ravel())
    nm.filepath_raw=str(WORK/(name+'_normal.png')); nm.file_format='PNG'; nm.save()
    tex=tree.nodes.new('ShaderNodeTexImage'); tex.image=nm
    node=tree.nodes.new('ShaderNodeNormalMap'); tree.links.new(tex.outputs['Color'],node.inputs['Color']); tree.links.new(node.outputs['Normal'],p.inputs['Normal'])
    return m


def finish(o,mat):
    o.data.materials.clear(); o.data.materials.append(mat)
    bm=bmesh.new(); bm.from_mesh(o.data); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(o.data); bm.free()
    for p in o.data.polygons: p.use_smooth=True
    bpy.ops.object.select_all(action='DESELECT'); o.select_set(True); bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15192,island_margin=.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    bm=bmesh.new(); bm.from_mesh(o.data)
    bad=sum(not e.is_manifold for e in bm.edges); volume=bm.calc_volume(signed=False); bm.free()
    assert bad==0 and volume>0, (o.name,bad,volume)
    return {'part':o.name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'nonManifoldEdges':bad,'volume':volume}


def export(state):
    clear()
    ao=arterial('Aorta'); pa=pulmonary('PulmonaryArteries')
    # Make the duct end precisely at parent-vessel EXTERIORS. Parents have bored
    # mouths in the open state: no opaque hidden wall across either junction.
    duct=sweep('Ductus' if state=='patent' else 'Ligament',DUCT,lambda t:(.115+.05*t*t) if state=='patent' else .038+.006*sin(pi*t))
    boolean(duct,copy(ao),'DIFFERENCE'); boolean(duct,copy(pa),'DIFFERENCE')
    aobore=arterial('AorticLumen',True); pabore=pulmonary('PulmonaryLumen',True)
    boolean(ao,aobore,'DIFFERENCE'); boolean(pa,pabore,'DIFFERENCE')
    if state=='patent':
        for o in [ao,pa,duct]:
            boolean(o,sweep('DuctLumen',DUCT,lambda t:.070+.05*t*t),'DIFFERENCE')
    stats=[]
    for o,mat in [(ao,material('AorticTissue',(.72,.48,.35))),
                  (pa,material('PulmonaryTissue',(.39,.60,.57))),
                  (duct,material('DuctalTissue' if state=='patent' else 'FibrousRemnant',(.70,.39,.43) if state=='patent' else (.70,.60,.46)))]:
        stats.append(finish(o,mat))
    # Ray through the real duct centre must cross no wall in the patent state;
    # closed state must retain both parent-vessel walls and a solid remnant.
    origin=Vector(DUCT[0])*S; target=Vector(DUCT[-1])*S; direction=(target-origin).normalized(); distance=(target-origin).length
    blockers=[]
    for o in [ao,pa,duct]:
        hit,point,_,_=o.ray_cast(origin,direction,distance=distance)
        if hit: blockers.append(o.name)
    assert (not blockers if state=='patent' else 'Aorta' in blockers and 'PulmonaryArteries' in blockers), (state,blockers)
    name='PDA_Patent' if state=='patent' else 'PDA_Closed'
    parent=bpy.data.objects.new('DuctalRegion',None); bpy.context.collection.objects.link(parent)
    for o in [ao,pa,duct]: o.parent=parent
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.wm.usd_export(filepath=str(OUT/(name+'.usdz')),selected_objects_only=True,
        export_animation=False,export_materials=True,generate_preview_surface=True,
        generate_materialx_network=False,export_textures_mode='NEW',
        convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',
        convert_scene_units='METERS',meters_per_unit=1.0)
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK/(name+'.blend')))
    return {'asset':name,'parts':stats,'ductCentreRayBlockers':blockers}

bpy.context.preferences.filepaths.save_version=0
report={'kind':'original regional teaching reconstruction','base':'HeartV0 batch08 arrangement, reauthored smooth vessel networks',
        'source':'https://www.merckmanuals.com/professional/pediatrics/congenital-cardiovascular-anomalies/patent-ductus-arteriosus-pda',
        'limitations':['Not a scanned specimen or patient measurement','No microscopic layer segmentation or haemodynamic simulation',
                       'Open and closed anatomical endpoints; not instantaneous birth closure','No complete heart/chambers or distal vessels'],
        'models':[export('patent'),export('closed')]}
(WORK/'validation.json').write_text(json.dumps(report,indent=2))
print('PDA_AUTHORED_PASS',json.dumps(report),flush=True)

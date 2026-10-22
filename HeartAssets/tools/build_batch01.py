"""Run in Blender 5.2: --background --factory-startup --python this_file.
Original illustrative embryology meshes; all exported parts remain independent.
"""
import bpy, bmesh, math, json, argparse, sys
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi

BASE = Path(__file__).resolve().parents[1]
PROJECT = BASE.parent
EXPORT = PROJECT / 'Packages/RealityKitContent/Sources/RealityKitContent/RealityKitContent.rkassets/HeartAssets'
EXPORT.mkdir(parents=True, exist_ok=True)
S = 0.065  # metres per modelling unit; deliberately enlarged teaching models
parts = []

def group(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj

def material(name, color, roughness=.4):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    p = mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = roughness
    # An image-based base colour survives USD Preview Surface conversion.
    import numpy as np
    size = 256
    yy, xx = np.mgrid[0:size, 0:size] / size
    variation = 1 + .035*np.sin(xx*2*pi*13 + np.sin(yy*2*pi*7)) + .025*np.cos(yy*2*pi*19+xx*2*pi*5)
    pixels = np.ones((size, size, 4), dtype=np.float32)
    # Image pixels are sRGB; convert the supplied linear colour for the image.
    for k, c in enumerate(color):
        pixels[:,:,k] = np.clip((1.055*c**(1/2.4)-.055)*variation, 0, 1)
    img = bpy.data.images.new(name+'_Albedo', width=size, height=size)
    img.pixels.foreach_set(pixels.ravel())
    img.pack()
    tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = img
    mat.node_tree.links.new(tex.outputs['Color'], p.inputs['Base Color'])
    return mat

def mesh(name, verts, faces, mat, parent, label, category='anatomy'):
    data = bpy.data.meshes.new(name+'_Mesh')
    data.from_pydata([tuple(S*a for a in v) for v in verts], [], faces)
    data.update()
    bm=bmesh.new(); bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(data); bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = len(poly.vertices) == 4
    # Cylindrical/surface coordinates supplied per generated vertex.
    uv = data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        for li in poly.loop_indices:
            v = data.vertices[data.loops[li].vertex_index].co / S
            uv.data[li].uv = ((v.x+2)/4, (v.z+2)/4)
    obj['part_id'] = name
    obj['display_name'] = label
    obj['category'] = category
    parts.append({'id':name, 'label':label, 'category':category, 'parent':parent.name})
    return obj

def ellipsoid(name, center, radii, mat, parent, label):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=24, location=tuple(S*c for c in center))
    obj=bpy.context.object
    obj.name=name
    obj.scale=tuple(S*r for r in radii)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.parent=parent
    obj.data.materials.append(mat)
    for p in obj.data.polygons: p.use_smooth=True
    obj['part_id']=name
    obj['display_name']=label
    parts.append({'id':name,'label':label,'category':'context','parent':parent.name})
    return obj

def ribbon(name, a0, a1, radius, width, depth, y, mat, parent, label):
    # Closed crescent-shaped tissue volume with rounded cross-section.
    vs=[]; fs=[]; n=80; m=24
    for i in range(n+1):
        t=i/n; a=a0+(a1-a0)*t
        taper=.25+.75*sin(pi*t)**.45
        for j in range(m):
            b=2*pi*j/m
            r=radius+width*cos(b)*taper
            vs.append((r*cos(a), y+depth*sin(b)*taper, .22+r*sin(a)))
    for i in range(n):
        for j in range(m):
            a=i*m+j; b=i*m+(j+1)%m
            fs.append((a,b,b+m,a+m))
    fs.extend([tuple(reversed(range(m))), tuple(n*m+j for j in range(m))])
    return mesh(name,vs,fs,mat,parent,label)

def shell(name, side, r0, r1, start, end, mat, parent, label):
    # True hollow shell; longitudinal cut edges and annular ends are closed.
    n=40; m=16; vs=[]; fs=[]
    for radius in (r0,r1):
        for i in range(n+1):
            t=i/n; z=-1.30+2.6*t
            cx=side*(.52+.11*cos(2*pi*t))
            bulge=1+.14*sin(pi*t)**2
            for j in range(m+1):
                a=start+(end-start)*j/m
                ripple=1+.009*sin(23*t+3*a)*sin(pi*t)
                vs.append((cx+radius*bulge*cos(a)*ripple, radius*bulge*sin(a)*ripple, z))
    stride=m+1; layer=(n+1)*stride
    for k in range(2):
        off=k*layer
        for i in range(n):
            for j in range(m):
                a=off+i*stride+j
                face=(a,a+1,a+stride+1,a+stride)
                fs.append(face if k==1 else tuple(reversed(face)))
    for i in (0,n):
        for j in range(m):
            a=i*stride+j
            f=(a,a+layer,a+layer+1,a+1)
            fs.append(f if i==n else tuple(reversed(f)))
    for j in (0,m):
        for i in range(n):
            a=i*stride+j
            f=(a,a+stride,a+stride+layer,a+layer)
            fs.append(f if j==0 else tuple(reversed(f)))
    return mesh(name,vs,fs,mat,parent,label)

def setup():
    global parts
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    parts=[]
    bpy.context.preferences.filepaths.save_version=0
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC'
    scene.render.engine='CYCLES'
    scene.cycles.device='CPU'
    scene.cycles.samples=24
    scene.cycles.use_denoising=True
    scene.render.resolution_x=1200; scene.render.resolution_y=1200
    scene.render.resolution_percentage=100
    scene.world.color=(.18,.18,.18)
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast'
    scene.view_settings.exposure=-1.5
    return {
        'muscle':material('Embryonic_Myocardium',(.43,.105,.115)),
        'mesoderm':material('Splanchnic_Mesoderm',(.57,.24,.235)),
        'lining':material('Endocardium',(.61,.30,.28),.32),
        'jelly':material('Cardiac_Jelly',(.72,.51,.38),.3),
        'endoderm':material('Endoderm',(.59,.39,.26),.48),
        'neural':material('Neural_Plate',(.50,.36,.38),.46),
        'cord':material('Angioblastic_Cords',(.40,.065,.082),.36),
    }

def stage01(m):
    root=group('Heart_01_CardiogenicRegion')
    tissues=group('Tissues',root); cords=group('VascularPrecursors',root); context=group('EmbryonicContext',root)
    ellipsoid('Endoderm_Context',(0,.19,-.12),(1.58,.07,1.84),m['endoderm'],context,'Endoderm (schematic context)')
    ellipsoid('NeuralPlate_Context',(0,.05,-.43),(.46,.09,1.12),m['neural'],context,'Developing neural plate (orientation context)')
    ribbon('CardiogenicCrescent',-.15*pi,1.15*pi,1.07,.25,.12,-.08,m['mesoderm'],tissues,'Cardiogenic crescent / primary heart field')
    # Left and right cords are separate superficial teaching structures.
    ribbon('AngioblasticCord_L',.52*pi,1.13*pi,1.075,.042,.04,-.205,m['cord'],cords,'Left angioblastic cord (enlarged)')
    ribbon('AngioblasticCord_R',-.13*pi,.48*pi,1.075,.042,.04,-.205,m['cord'],cords,'Right angioblastic cord (enlarged)')
    return root

def stage02(m):
    root=group('Heart_02_PairedHeartTubes')
    context=group('EmbryonicContext',root)
    ellipsoid('Endoderm_Context',(0,.30,0),(1.26,.075,1.60),m['endoderm'],context,'Endoderm (schematic context)')
    for side, suffix in [(-1,'L'),(1,'R')]:
        g=group('Tube_'+suffix,root)
        for layer,r0,r1,key,label in [
            ('Myocardium',.218,.29,'muscle','Myocardial mantle'),
            ('CardiacJelly',.154,.214,'jelly','Cardiac jelly'),
            ('Endocardium',.123,.150,'lining','Endocardial lining')]:
            for panel,a,b in [('Posterior',0,pi),('Anterior',pi,2*pi)]:
                shell(layer+'_'+suffix+'_'+panel,side,r0,r1,a,b,m[key],g,label+' — '+suffix+', '+panel.lower()+' panel')
    return root

def presentation(root):
    scene=bpy.context.scene
    bpy.ops.object.camera_add(location=(.24,-.61,.23))
    camera=bpy.context.object; camera.name='PreviewCamera'
    camera.rotation_euler=(Vector((0,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO'; camera.data.ortho_scale=.30
    scene.camera=camera
    for name,loc,power,size in [('Key',(-.25,-.4,.35),16,.32),('Fill',(.30,-.10,.15),8,.26),('Rim',(0,.25,.3),20,.22)]:
        bpy.ops.object.light_add(type='AREA',location=loc)
        light=bpy.context.object; light.name='Preview_'+name; light.data.energy=power; light.data.shape='DISK'; light.data.size=size
        light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.film_transparent=True
    for area in bpy.context.screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_distance=.4
            area.spaces.active.region_3d.view_location=(0,0,0)
            area.spaces.active.shading.type='MATERIAL'

def descendants(root):
    return [root]+list(root.children_recursive)

def export(root, number):
    name=root.name
    bpy.ops.object.select_all(action='DESELECT')
    for obj in descendants(root): obj.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.usd_export(filepath=str(EXPORT/(name+'.usdz')),selected_objects_only=True,
        export_animation=False,export_materials=True,generate_preview_surface=True,
        generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,
        convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,
        root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
    report={'asset':name,'status':'illustrative_prototype','batch':1,'units':'metres',
        'display_scale':'enlarged teaching model; not embryo life size',
        'usd_up_axis':'Y','coordinate_note':'Blender +Z cranial, -Y viewing side; USD +Y cranial, +Z viewing side. L/R IDs denote anatomical sides in dorsal-style schematic view.',
        'parts':parts,'triangles':sum(len(o.data.polygons)*2 for o in descendants(root) if o.type=='MESH')}
    (BASE/'manifests'/(name+'.json')).write_text(json.dumps(report,indent=2))
    presentation(root)
    bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'blender'/(name+'.blend')))
    bpy.context.scene.render.filepath=str(BASE/'previews'/(name+'_assembled.png'))
    bpy.ops.render.render(write_still=True)
    if number==1:
        bpy.data.objects['Endoderm_Context'].location.y+=.075
        bpy.data.objects['NeuralPlate_Context'].location.y+=.035
        bpy.data.objects['VascularPrecursors'].location.y-=.045
    else:
        for obj in descendants(root):
            if obj.name.endswith('_Anterior'):
                obj.hide_render=True
    bpy.context.scene.render.filepath=str(BASE/'previews'/(name+'_layers.png'))
    bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,flush=True)

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    parser=argparse.ArgumentParser(); parser.add_argument('--stage',type=int,choices=[1,2],required=True)
    number=parser.parse_args(args).stage
    m=setup(); root=(stage01 if number==1 else stage02)(m)
    export(root,number)

"""Rebuild cardiac looping with chamber ballooning and portable tissue PBR maps.
Run one model: Blender --background --factory-startup --python this_file.
All geometry and texture pixels are original; reference video is visual guidance.
"""
import sys, math, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy, numpy as np
from mathutils import Vector
from math import sin, cos, pi
import build_batch01 as core
import build_batch02 as tube

ROOT='Heart_04_CardiacLooping'

def image(name,pixels,noncolor=False):
    h,w=pixels.shape[:2];img=bpy.data.images.new(name,width=w,height=h)
    if noncolor: img.colorspace_settings.name='Non-Color'
    img.pixels.foreach_set(pixels.astype(np.float32).ravel());img.pack()
    return img

def tissue(name,color,kind):
    size=1024;yy,xx=np.mgrid[0:size,0:size]/size
    rng=np.random.default_rng(731)
    field=np.zeros((size,size));height=np.zeros_like(field)
    for frequency,weight in [(2,.3),(5,.2),(11,.12),(27,.07),(61,.035),(139,.012)]:
        phase=rng.uniform(0,2*pi,3)
        field+=weight*np.sin(2*pi*(frequency*xx+.29*frequency*yy)+phase[0])*np.cos(2*pi*(.31*frequency*xx+frequency*yy)+phase[1])
    warped=xx+.028*np.sin(2*pi*yy*3)+.012*np.sin(2*pi*yy*11)
    fibers=np.sin(2*pi*(warped*180+.15*yy*17))
    height=.00045*field
    capillaries=np.zeros_like(field)
    if kind=='muscle':
        for k in range(12):
            track=(k+.5)/12+.017*np.sin(2*pi*(yy*(2+k%3))+k)
            capillaries+=np.exp(-((xx-track)/.0009)**2)*(.2+.8*np.sin(pi*yy)**2)
    rgb=np.zeros((size,size,4));rgb[:,:,3]=1
    for k,c in enumerate(color):
        srgb=c
        rgb[:,:,k]=np.clip(srgb*(1+.25*field)*(1-capillaries*(.07 if k==0 else .17)),0,1)
    rough=np.ones_like(rgb);rough[:,:,:3]=np.clip((.46 if kind=='muscle' else .34)+.1*field[:,:,None],.25,.62)
    gy,gx=np.gradient(height);gx*=size;gy*=size
    normal=np.ones_like(rgb);n=np.stack([-gx,-gy,np.ones_like(gx)],axis=2);n/=np.linalg.norm(n,axis=2)[:,:,None]
    normal[:,:,:3]=n*.5+.5
    mat=bpy.data.materials.new(name);mat.use_nodes=True;mat.diffuse_color=(*color,1)
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF')
    bs.inputs['Roughness'].default_value=.46
    bs.inputs['Coat Weight'].default_value=.06
    bs.inputs['Coat Roughness'].default_value=.36
    for suffix,pixels,noncolor,target in [('Albedo',rgb,False,'Base Color'),('Roughness',rough,True,'Roughness'),('Normal',normal,True,None)]:
        tex=nodes.new('ShaderNodeTexImage');tex.image=image(name+'_'+suffix,pixels,noncolor)
        if target: links.new(tex.outputs['Color'],bs.inputs[target])
        else:
            nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.4
            links.new(tex.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
    return mat

def branch(name,knots,radius,mat,label):
    # A hollow branch with annular rims; junctions are anatomical landmarks,
    # not a reconstructed embryonic vascular tree.
    points=[tube.interpolate([(u,Vector(v)) for u,v in knots],i/32) for i in range(33)]
    axes=[]
    for i,p in enumerate(points):
        tangent=(points[min(32,i+1)]-points[max(0,i-1)]).normalized()
        v=Vector((0,1,0))-tangent*tangent.y;v.normalize();axes.append((v.cross(tangent).normalized(),v))
    vs=[];fs=[];m=32;n=33
    for f in [.7,1]:
        for i,p in enumerate(points):
            u,v=axes[i];r=radius*(1-.2*i/32)
            for j in range(m):vs.append(p+f*r*(cos(j*2*pi/m)*u+sin(j*2*pi/m)*v))
    layer=n*m
    for k in range(2):
        for i in range(n-1):
            for j in range(m):
                a=k*layer+i*m+j;b=k*layer+i*m+(j+1)%m
                face=(a,b,b+m,a+m);fs.append(face if k else tuple(reversed(face)))
    for i in [0,n-1]:
        for j in range(m):
            a=i*m+j;b=i*m+(j+1)%m;fs.append((a,b,b+layer,a+layer))
    obj=core.mesh(name,vs,fs,mat,root,label)
    for poly in obj.data.polygons:poly.use_smooth=poly.index<(n-1)*m*2
    return obj

import bmesh

def apply(obj,modifier):
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)

def sphere_blob(center,radii):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=32,location=tuple(core.S*c for c in center))
    obj=bpy.context.object;obj.scale=tuple(core.S*r for r in radii)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return obj

def clip_cell(name,seed,other_seeds,front):
    bpy.ops.mesh.primitive_cube_add(size=6*core.S)
    obj=bpy.context.object;obj.name=name
    bm=bmesh.new();bm.from_mesh(obj.data)
    planes=[]
    for other in other_seeds:
        normal=Vector(other)-Vector(seed)
        if normal.length>.001: planes.append(((Vector(other)+Vector(seed))*.5,normal))
    planes.append((Vector((0,seed[1],0)),Vector((0,1 if front else -1,0))))
    for point,normal in planes:
        geom=list(bm.verts)+list(bm.edges)+list(bm.faces)
        bmesh.ops.bisect_plane(bm,geom=geom,dist=1e-7,plane_co=point*core.S,plane_no=normal.normalized(),clear_outer=True,clear_inner=False)
        edges=[e for e in bm.edges if e.is_boundary]
        if edges:bmesh.ops.holes_fill(bm,edges=edges,sides=0)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
    return obj

core.setup();root=core.group(ROOT)
mats={'muscle':tissue('Looping_Myocardium',(.28,.048,.061),'muscle'),
      'jelly':tissue('Looping_CardiacJelly',(.48,.27,.16),'jelly'),
      'lining':tissue('Looping_Endocardium',(.40,.17,.15),'lining')}
blobs=[]
for c,r in [((.38,-.20,-.43),(.63,.48,.72)),((-.40,-.25,-.27),(.47,.42,.60)),
            ((.38,.30,.61),(.48,.38,.44)),((-.18,.39,.75),(.35,.28,.32)),
            ((.37,.08,.16),(.23,.28,.28))]:blobs.append(sphere_blob(c,r))
for i in range(16):
    t=i/15;blobs.append(sphere_blob((-.39+.28*t,-.19+.09*t,.22+1.40*t),(.22-.075*t,.21-.075*t,.19)))
bpy.ops.object.select_all(action='DESELECT')
for obj in blobs:obj.select_set(True)
bpy.context.view_layer.objects.active=blobs[0];bpy.ops.object.join();sculpt=blobs[0];sculpt.name='WorkingChamberSurface'
mod=sculpt.modifiers.new('Continuous organic tissue','REMESH');mod.mode='VOXEL';mod.voxel_size=.033*core.S;mod.use_smooth_shade=True;apply(sculpt,mod)
mod=sculpt.modifiers.new('Chamber smoothing','SMOOTH');mod.factor=.9;mod.iterations=7;apply(sculpt,mod)
# A real hollow inner surface: solidify each layer against the same chamber surface.
seeds=[(0,.45,1.0),(.38,.30,.62),(.48,.05,.16),(.40,-.20,-.48),(-.40,-.25,-.30),(-.27,-.15,1.03)]
for region,(segment,label,_,_) in enumerate(tube.SEGMENTS):
    parent=core.group(segment,root)
    for layer,start,thickness,key in [('Myocardium',0,.075,'muscle'),('CardiacJelly',.075,.018,'jelly'),('Endocardium',.093,.012,'lining')]:
        for side,front in [('Posterior',False),('Anterior',True)]:
            obj=bpy.data.objects.new(layer+'_'+segment+'_'+side,sculpt.data.copy());bpy.context.collection.objects.link(obj);obj.location=sculpt.location.copy()
            # The remeshed object retains its original mesh origin.
            if start:
                bm=bmesh.new();bm.from_mesh(obj.data);bm.normal_update()
                for vert in bm.verts:vert.co-=vert.normal*(start*core.S)
                bm.to_mesh(obj.data);bm.free()
            sol=obj.modifiers.new('Hollow tissue layer','SOLIDIFY');sol.thickness=thickness*core.S;sol.offset=-1;sol.use_even_offset=False;apply(obj,sol)
            cell=clip_cell('WorkingCutCell',seeds[region],seeds,front)
            cut=obj.modifiers.new('Independent teaching region','BOOLEAN');cut.operation='INTERSECT';cut.solver='MANIFOLD';cut.object=cell;apply(obj,cut)
            bpy.data.objects.remove(cell,do_unlink=True)
            assert len(obj.data.polygons)>0,obj.name
            obj.parent=parent;obj.data.materials.clear();obj.data.materials.append(mats[key])
            uv=obj.data.uv_layers.new(name='UVMap')
            for poly in obj.data.polygons:
                poly.use_smooth=True
                for li in poly.loop_indices:
                    v=obj.matrix_world @ obj.data.vertices[obj.data.loops[li].vertex_index].co /core.S
                    uv.data[li].uv=((v.x+1.4)/2.8,(v.z+1.3)/3.5)
            # Transfer shading from the uncut sculpture so selectable region
            # boundaries do not introduce artificial grooves in the assembled view.
            transfer=obj.modifiers.new('Continuous surface normals','DATA_TRANSFER')
            transfer.object=sculpt;transfer.use_loop_data=True
            transfer.data_types_loops={'CUSTOM_NORMAL'};transfer.loop_mapping='POLYINTERP_NEAREST'
            apply(obj,transfer)
            normals=[]
            for poly in obj.data.polygons:
                for li in poly.loop_indices:
                    normal=obj.data.corner_normals[li].vector.copy()
                    alignment=normal.dot(poly.normal)
                    if abs(alignment)<.5: normal=poly.normal.copy()
                    elif alignment<0: normal=-normal
                    normals.append(normal)
            obj.data.normals_split_custom_set(normals)
            obj['part_id']=obj.name;obj['display_name']=f'{label} — {layer.lower()}, {side.lower()} panel';obj['category']='anatomy'
            core.parts.append({'id':obj.name,'label':obj['display_name'],'category':'anatomy','parent':parent.name})
bpy.data.objects.remove(sculpt,do_unlink=True)
for side,suffix in [(-1,'R'),(1,'L')]:
    branch('ArterialBranch_'+suffix,[(0,(-.08,-.06,1.57)),(.4,(-.08+side*.18,-.025,1.82)),(1,(-.08+side*.34,.02,2.15))],.11,mats['muscle'],'Paired arterial outflow — '+suffix+' (orientation landmark)')
    branch('VenousInflow_'+suffix,[(0,(.06,.45,.97)),(.45,(side*.35,.67,1.21)),(1,(side*.68,.66,1.31))],.095,mats['lining'],'Venous inflow — '+suffix+' (orientation landmark)')
# Export only the model hierarchy; all materials use texture-supported USD inputs.
bpy.ops.object.select_all(action='DESELECT')
for obj in core.descendants(root):obj.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(ROOT+'.usdz')),selected_objects_only=True,
    export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,
    export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,
    export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,
    export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
core.presentation(root);scene=bpy.context.scene
scene.cycles.samples=48;scene.view_settings.exposure=-1.4
scene.camera.location=(.19,-.62,.20)
scene.camera.rotation_euler=(Vector((0,.005,.045))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=.26
bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(ROOT+'.blend')))
scene.render.filepath=str(core.BASE/'previews'/(ROOT+'_assembled.png'));bpy.ops.render.render(write_still=True)
for obj in core.descendants(root):
    if obj.name.endswith('_Anterior'):obj.hide_render=True
scene.render.filepath=str(core.BASE/'previews'/(ROOT+'_layers.png'));bpy.ops.render.render(write_still=True)
report={'asset':ROOT,'status':'original_educational_refinement','batch':2,'revision':'looping-v2',
        'units':'metres','usd_up_axis':'Y','parts':core.parts,
        'reference':'https://www.youtube.com/watch?v=a0qyagIgBPw',
        'coordinate_note':'Blender +Z cranial, -Y anterior; anatomical right -X. USD Y-up.',
        'limitations':['Illustrative established loop, not segmented specimen or clinically validated anatomy',
            'Static model; no deformation or contraction',
            'Layer thickness enlarged; branch junctions are orientation landmarks, not continuous vascular reconstruction'],
        'changes':['Ballooned atrial/ventricular regions and narrower AV canal','Asymmetric atrial and ventricular chamber masses',
            'Voxel-blended chamber masses, hollow layered walls and continuous surface normals','1024-pixel albedo, roughness and tangent normal maps',
            'Four separate inflow/outflow landmarks; original 36 tissue IDs retained']}
(core.BASE/'manifests'/(ROOT+'.json')).write_text(json.dumps(report,indent=2))
print('COMPLETED looping-v2',flush=True)

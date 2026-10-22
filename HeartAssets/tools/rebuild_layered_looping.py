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
import shutil
OUT=core.BASE/'refinements/layered-tissue';OUT.mkdir(parents=True,exist_ok=True)
BACK=OUT/'before'/ROOT;BACK.mkdir(parents=True,exist_ok=True)
for source in [core.BASE/'blender'/(ROOT+'.blend'),core.EXPORT/(ROOT+'.usdz'),core.BASE/'manifests'/(ROOT+'.json'),core.BASE/'previews'/(ROOT+'_layers.png'),core.BASE/'previews'/(ROOT+'_assembled.png')]:
    if not (BACK/source.name).exists():shutil.copy2(source,BACK/source.name)
original_manifest=json.loads((BACK/(ROOT+'.json')).read_text())


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
    planes.append((Vector((0,seed[1]-(.03 if seed[0]<0 else .10),0)),Vector((0,1 if front else -1,0))))
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
            # Build both interfaces from identical source normals. Shared offsets
            # keep adjacent tissue boundaries coincident as their thickness varies.
            bm=bmesh.new();bm.from_mesh(sculpt.data);bm.normal_update()
            outer=[];inner=[]
            for v in bm.verts:
                pos=(v.co+sculpt.location)/core.S
                x,y,z=pos
                muscle=.075*(1+.17*cos(3*z)*sin(2*x+1))
                jelly=.018*(1+.42*math.exp(-((z-.18)/.40)**2))
                lining=.009
                lo,hi={'Myocardium':(0,muscle),'CardiacJelly':(muscle,muscle+jelly),'Endocardium':(muscle+jelly,muscle+jelly+lining)}[layer]
                outer.append(tuple(v.co-v.normal*(lo*core.S)))
                inner.append(tuple(v.co-v.normal*(hi*core.S)))
            bm.verts.ensure_lookup_table();bm.verts.index_update()
            faces=[tuple(v.index for v in f.verts) for f in bm.faces]
            count=len(outer);faces+= [tuple(count+i for i in reversed(f)) for f in list(faces)]
            data=bpy.data.meshes.new(obj.name+'_LayerShell');data.from_pydata(outer+inner,[],faces);data.update();obj.data=data;bm.free()
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
# Verify all reconstructed volumes before baking or exporting.
from bake_layered_tissue import bake
kinds={};cut_faces={}
for obj in root.children_recursive:
    if obj.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(obj.name,'nonmanifold')
    volume=bm.calc_volume(signed=True)
    assert abs(volume)>1e-12,(obj.name,'zero-volume tissue shell',volume)
    if volume<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
    assert bm.calc_volume(signed=True)>0,(obj.name,'nonpositive volume')
    bm.to_mesh(obj.data);bm.free()
    kinds[obj.name]='jelly' if 'CardiacJelly' in obj.name else ('lining' if 'Endocardium' in obj.name or 'VenousInflow' in obj.name else 'muscle')
    cuts=set()
    for segment_index,(segment,_,_,_) in enumerate(tube.SEGMENTS):
        if '_'+segment+'_' not in obj.name:continue
        seed=Vector(seeds[segment_index]);planes=[(Vector((0,seed.y-(.03 if seed.x<0 else .10),0)),Vector((0,1,0)))]
        for other in seeds:
            n=Vector(other)-seed
            if n.length>.001:planes.append(((Vector(other)+seed)*.5,n.normalized()))
        for face in obj.data.polygons:
            centre=(obj.matrix_world@face.center)/core.S
            if any(abs((centre-point).dot(normal))<.0001 and abs(face.normal.dot(normal))>.995 for point,normal in planes):cuts.add(face.index)
    cut_faces[obj.name]=cuts
bake([o for o in root.children_recursive if o.type=='MESH'],kinds,ROOT,cut_faces)
assert {p['id'] for p in original_manifest['parts']}==set(kinds)
bpy.ops.object.select_all(action='DESELECT')
for obj in core.descendants(root):obj.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.wm.usd_export(filepath=str(OUT/(ROOT+'.usdz')),selected_objects_only=True,
    export_animation=False,export_materials=True,generate_preview_surface=True,generate_materialx_network=False,
    export_textures_mode='NEW',export_custom_properties=True,convert_orientation=True,
    export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',export_lights=False,
    export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1)
core.presentation(root);scene=bpy.context.scene
scene.cycles.samples=40;scene.view_settings.exposure=-1.15
scene.camera.location=(.23,-.62,.22)
scene.camera.rotation_euler=(Vector((0,.005,.045))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=.27
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(ROOT+'.blend')))
scene.render.filepath=str(OUT/(ROOT+'_assembled.png'));bpy.ops.render.render(write_still=True)
for obj in root.children_recursive:
    if obj.name.endswith('_Anterior'):obj.hide_render=True
scene.render.filepath=str(OUT/(ROOT+'_layers.png'));bpy.ops.render.render(write_still=True)
for obj in root.children_recursive:
    if obj.type!='MESH':continue
    if obj.name.endswith('_Anterior'):obj.hide_render=False;obj.location.x+=.09
    if obj.name.startswith('Endocardium'):obj.location.x-=.055
scene.camera.data.ortho_scale=.38
scene.render.filepath=str(OUT/(ROOT+'_separated.png'));bpy.ops.render.render(write_still=True)
report=original_manifest
report.update(status='draft_requires_stage_specific_anatomical_review',revision='layered-tissue-2',detailChanges=[
 'Reconstructed variable-thickness muscle, cardiac jelly and thinner endocardial lining with matching interface offsets',
 'Shallower anterior dissection retains more chamber wall and cavity depth',
 'Distinct cut-tissue and intact surface materials with three embedded 2048px maps',
 'All 40 selectable part identities retained; vascular branches remain orientation landmarks'],
 referenceVideo={'url':'https://www.facebook.com/share/r/1CzT4A9CPz/','viewed':True,'note':'Local video sampled across 51.78 seconds; loop silhouette and surface appearance used as visual guidance'},
 appearanceLimit='Original illustrative reconstruction, not scan-derived or validated photorealism. No claim of continuous branch-to-chamber vascular lumens.')
for o in root.children_recursive:
    if o.type=='MESH':o.data.calc_loop_triangles()
report['triangles']=sum(len(o.data.loop_triangles) for o in root.children_recursive if o.type=='MESH')
(OUT/(ROOT+'.json')).write_text(json.dumps(report,indent=2))
print('LAYERED LOOPING COMPLETE',flush=True)

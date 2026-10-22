"""Two focused septation teaching models with discrete early/later states.
Run one stage per Blender invocation. Coordinates: +X anatomical left,
+Z cranial, -Y anterior. Original geometry, not patient-derived anatomy.
"""
import bpy, bmesh, sys, argparse, json, math
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
S=core.S

def ball(name,center,radii,material=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=40,location=tuple(S*v for v in center))
    o=bpy.context.object;o.name=name;o.scale=tuple(S*v for v in radii)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if material:o.data.materials.append(material)
    for p in o.data.polygons:p.use_smooth=True
    return o

def box(center,size):
    bpy.ops.mesh.primitive_cube_add(size=1,location=tuple(S*v for v in center))
    o=bpy.context.object;o.scale=tuple(S*v for v in size)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return o

def bore(center,radii,axis='X'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=80,radius=1,depth=1,location=tuple(S*v for v in center))
    o=bpy.context.object
    # Default cylinder is along Z; radii are world X,Y,Z scale after rotation.
    if axis=='X': o.rotation_euler[1]=math.pi/2;o.scale=(S*radii[2],S*radii[1],S*radii[0])
    else:o.scale=tuple(S*v for v in radii)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return o

def boolean(o,cutter,operation='DIFFERENCE'):
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Anatomical opening','BOOLEAN');mod.operation=operation;mod.solver='EXACT';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)

def register(o,parent,label,state=None,offset=(0,0,0)):
    o.parent=parent;o['part_id']=o.name;o['display_name']=label;o['category']='anatomy'
    # Explicit USD-space separation vectors (metres), independent of name heuristics.
    p={'id':o.name,'label':label,'category':'anatomy','parent':parent.name,'separationOffset':list(offset)}
    if state:p['state']=state
    core.parts.append(p)
    # Validate source immediately; exact booleans can create awkward seams.
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(o.name,'nonmanifold')
    assert bm.calc_volume(signed=True)>0,(o.name,'volume')
    bm.to_mesh(o.data);bm.free()
    return o

def chamber(root,m):
    for panel,side in [('Anterior',-1),('Posterior',1)]:
        o=ball('AtrialWall_'+panel,(0,0,.5),(1.15,.75,.95),m['muscle'])
        boolean(o,ball('Inner',(0,0,.5),(1.06,.66,.86)))
        boolean(o,box((0,side*1.5,0),(4,3,5)),'INTERSECT')
        boolean(o,bore((0,0,-.52),(.56,.35,.64),axis='Z'))
        register(o,root,'Common atrial wall — '+panel.lower()+' teaching panel',offset=(0,0,-side*.065))

def canal(root,m,wide=False):
    # Open cranial/caudal ends; no capped solid cylinder standing in for a lumen.
    rx,ry=(1.1,.72) if wide else (.64,.43)
    z0,z1=(-.38,.38) if wide else (-.72,-.28)
    n=64
    for panel,a0,a1 in [('Posterior',0,math.pi),('Anterior',math.pi,2*math.pi)]:
        vs=[];fs=[]
        for radius in [1,.88]:
            for z in [z0,z1]:
                for i in range(n+1):
                    a=a0+(a1-a0)*i/n
                    vs.append((rx*radius*math.cos(a),ry*radius*math.sin(a),z))
        row=n+1
        for i in range(n):
            fs.extend([(i,i+1,i+1+row,i+row),(2*row+i,3*row+i,3*row+i+1,2*row+i+1),
                       (i,2*row+i,2*row+i+1,i+1),(row+i,row+i+1,3*row+i+1,3*row+i)])
        for i in [0,n]:fs.append((i,i+row,i+3*row,i+2*row))
        o=core.mesh('AVCanalWall_'+panel,vs,fs,m['muscle'],root,'Atrioventricular canal wall — '+panel.lower()+' panel')
        core.parts[-1]['separationOffset']=[0,-.025,.055 if panel=='Anterior' else -.055]

def atrial(root,m):
    chamber(root,m);canal(root,m)
    for side in [-1,1]:
        o=ball('CushionAnchor_'+('Dorsal' if side==1 else 'Ventral'),(0,side*.19,-.29),(.26,.25,.13),m['jelly'])
        register(o,root,'Endocardial cushion anchor — '+('dorsal' if side==1 else 'ventral'),offset=(0,-.035,-side*.025))
    early=ball('SeptumPrimum_Early',(.03,0,.57),(.045,.66,.86),m['lining'])
    # Inferior aperture remains continuous with the canal: ostium primum.
    boolean(early,bore((.03,0,-.15),(.5,.52,.58)))
    register(early,root,'Septum primum — ostium primum below free edge','early',(.045,.025,0))
    late=ball('SeptumPrimum_Later',(.035,0,.57),(.036,.66,.86),m['lining'])
    boolean(late,bore((.035,0,.99),(.5,.24,.21)))
    # Deflect the lower flap into the left atrial side; retain upper attachment.
    for v in late.data.vertices:
        world_z=(v.co.z+late.location.z)/S
        v.co.x+=S*.16*max(0,min(1,(.82-world_z)/.95))**1.5
    register(late,root,'Septum primum — ostium secundum and open lower flap','later',(.05,0,0))
    second=ball('SeptumSecundum_Later',(-.095,0,.62),(.09,.66,.81),m['muscle'])
    boolean(second,bore((-.095,0,.05),(.6,.38,.58)))
    register(second,root,'Septum secundum — incomplete rim of foramen ovale','later',(-.05,0,0))

def cushions(root,m):
    canal(root,m,True)
    for side,suffix in [(-1,'R'),(1,'L')]:
        o=ball('LateralCushion_'+suffix,(side*.93,0,0),(.19,.26,.23),m['jelly'])
        boolean(o,bore((0,0,0),(1.09,.71,2),axis='Z'),'INTERSECT')
        register(o,root,('Right' if side==-1 else 'Left')+' lateral AV cushion',offset=(side*.04,0,0))
    for state in ['unfused','fused']:
        for side,name in [(1,'Superior'),(-1,'Inferior')]:
            if state=='unfused':
                o=ball('Cushion'+name+'_Unfused',(0,side*.50,0),(.32,.37,.30),m['jelly'])
            else:
                o=ball('Cushion'+name+'_Fused',(0,0,0),(.32,.73,.30),m['jelly'])
                boolean(o,box((0,side*1.5,0),(4,3,4)),'INTERSECT')
            boolean(o,bore((0,0,0),(1.09,.71,2),axis='Z'),'INTERSECT')
            register(o,root,name+' AV cushion — '+('separate' if state=='unfused' else 'fused at midline'),state,(0,0,-side*.05))

def export(root,number,states):
    name=root.name
    bpy.ops.object.select_all(action='DESELECT')
    for o in core.descendants(root):o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,
        export_animation=False,export_materials=True,generate_preview_surface=True,
        generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,
        convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,
        root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
    data={'asset':name,'batch':3,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
          'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior. USD +Y cranial and +Z anterior.',
          'display_scale':'enlarged regional teaching model; not embryo life size',
          'states':states,'defaultState':states[0]['id'],'defaultCutaway':number==5,'parts':core.parts,
          'limitations':['Focused regional anatomy, not a whole-heart reconstruction','Discrete structural snapshots; no continuous tissue growth or fluid simulation','Exaggerated tissue thickness and openings for inspection','Requires anatomical teaching review before assessed use']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root)
    camera=bpy.context.scene.camera
    camera.location=(-.48,-.58,.20) if number==5 else (.18,-.34,.65)
    target=Vector((0,0,.018 if number==5 else 0))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale=.22 if number==5 else .19
    def display(state,cutaway):
        for p in core.parts:
            o=bpy.data.objects[p['id']]
            hidden=(p.get('state',state)!=state) or (cutaway and p['id'].endswith('_Anterior'))
            o.hide_render=hidden;o.hide_set(hidden)
    display(states[0]['id'],number==5)
    bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [(states[0]['id'],'assembled'),(states[1]['id'],'layers')]:
        display(state,number==5)
        bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'))
        bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--stage',required=True,type=int,choices=[5,6])
    number=parser.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup()
    root=core.group('Heart_05_AtrialSeptation' if number==5 else 'Heart_06_EndocardialCushions')
    (atrial if number==5 else cushions)(root,m)
    states=([{'id':'early','label':'Early · ostium primum'},{'id':'later','label':'Later · overlapping septa'}] if number==5
        else [{'id':'unfused','label':'Before fusion'},{'id':'fused','label':'After fusion'}])
    export(root,number,states)

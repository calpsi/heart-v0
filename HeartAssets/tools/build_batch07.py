"""Regional Fallot and d-TGA anatomy with matched structural comparisons.
Run one model at a time. These are original educational illustrations, not scans.
"""
import bpy, sys, json, argparse
from pathlib import Path
from math import sin, cos, pi
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball, box, bore, boolean, register
from build_batch04 import tube
from build_batch05 import sweep

def tag_last(state):
    core.parts[-1]['state']=state

def av_path(x):
    return [(x,.43,.03),(x,.45,.24),(x,.65,.55),(x,.80,.90)]

def rvot(root,state,m):
    # Open half-shells expose the actual narrowed lumen in cutaway.
    levels=[(.04,.23),(.35,.23),(.65,.19),(.88,.085),(1.08,.13),(1.25,.16)] if state=='fallot' else [(z,.23) for z in [.04,.35,.65,.88,1.08,1.25]]
    for panel,a0 in [('Posterior',0),('Anterior',pi)]:
        n=40;row=n+1;vs=[];fs=[]
        for surface in ['outer','inner']:
            for z,r in levels:
                for j in range(row):
                    a=a0+pi*j/n;radius=.30 if surface=='outer' else r
                    vs.append((-.55+radius*cos(a),-.30+radius*sin(a),z))
        layer=row*len(levels)
        for h in [0,1]:
            for i in range(len(levels)-1):
                for j in range(n):
                    a=h*layer+i*row+j;fs.append((a,a+1,a+1+row,a+row))
        for i in [0,len(levels)-1]:
            for j in range(n):
                a=i*row+j;fs.append((a,a+1,a+1+layer,a+layer))
        for j in [0,n]:
            for i in range(len(levels)-1):
                a=i*row+j;fs.append((a,a+row,a+row+layer,a+layer))
        core.mesh('RVOutflow_'+state.title()+'_'+panel,vs,fs,m['muscle'],root,
                  ('Narrowed' if state=='fallot' else 'Comparison')+' right ventricular outflow — '+panel.lower())
        tag_last(state);core.parts[-1]['separationOffset']=[-.045,.025,.05 if panel=='Anterior' else -.05]

def ventricle(root,state,m,ports,hypertrophy=False,with_atria=False):
    for side,suffix in [(-1,'R'),(1,'L')]:
        inner=(.90,.53,.90) if hypertrophy and side<0 else (1.04,.67,.98)
        for facing,panel in [(-1,'Anterior'),(1,'Posterior')]:
            o=ball('VentricularWall_'+suffix+'_'+state.title()+'_'+panel,(0,0,-.40),(1.16,.79,1.10),m['muscle'])
            boolean(o,ball('Cavity',(0,0,-.40),inner))
            boolean(o,box((side*1.5,0,0),(3,4,5)),'INTERSECT')
            boolean(o,box((0,facing*1.5,0),(4,3,5)),'INTERSECT')
            for x,y,r in ports:boolean(o,bore((x,y,.55),(r,r,1.6),axis='Z'))
            for x in [-.51,.51]:
                if with_atria:
                    boolean(o,sweep(root,'AVBore','temporary',av_path(x),.17,None,m['lining'],record=False))
                else:boolean(o,bore((x,.43,.38),(.23,.23,1.0),axis='Z'))
            label=('Right' if side<0 else 'Left')+' ventricular wall'
            if hypertrophy and side<0:label+=' — thickened'
            register(o,root,label+' — '+state+' '+panel.lower(),state,(side*.045,0,-facing*.055))
    o=ball('VentricularSeptum_'+state.title(),(0,0,-.40),(.10,.68,.99),m['muscle'])
    if state=='fallot':
        boolean(o,bore((0,.10,.39),(.8,.29,.28)))
        # The overriding aortic mouth stays open above the septal crest.
        boolean(o,bore((.04,.14,.82),(.235,.235,.95),axis='Z'))
    register(o,root,'Ventricular septum — '+('outlet opening' if state=='fallot' else 'intact'),state,(.045,-.025,0))
    if not with_atria:
        for x,label in [(-.51,'Right'),(.51,'Left')]:
            tube(root,label+'AV_'+state.title(),label+' AV inlet',(x,.43),.23,.05,.66,m['lining'],state)

def arteries(root,state,m):
    if state=='tga':
        ao=[(-.47,-.36,.02),(-.47,-.36,.90),(-.44,-.33,1.75),(.04,-.08,2.16),(.85,.12,2.10),(1.28,.16,1.45),(1.28,.16,.28)]
        pa=[(.44,.20,.02),(.44,.20,.90),(.44,.20,1.48),(.86,.20,1.58),(1.30,.20,1.46)]
        right=[(.44,.20,1.48),(-.30,.24,1.51),(-1.25,.26,1.35)]
        ao_label='Aorta from right ventricle';pa_label='Pulmonary trunk from left ventricle'
    elif state=='fallot':
        ao=[(.04,.14,.35),(.04,.14,1.08),(.20,.16,1.80),(.75,.17,2.13),(1.25,.18,1.62),(1.28,.18,.28)]
        pa=[(-.55,-.30,1.20),(-.55,-.30,1.43),(-.08,-.34,1.65),(.55,-.35,1.63),(1.18,-.28,1.43)]
        right=[(-.08,-.34,1.65),(-.64,-.16,1.70),(-1.27,.06,1.51)]
        ao_label='Overriding aorta — mouth spans ventricular septum';pa_label='Pulmonary trunk beyond narrowed outflow'
    else:
        ao=[(.43,.16,.02),(.43,.16,.90),(.48,.16,1.72),(.85,.18,2.12),(1.26,.18,1.58),(1.28,.18,.28)]
        pa=[(-.55,-.30,.02),(-.55,-.30,.90),(-.20,-.36,1.50),(.42,-.36,1.62),(1.18,-.28,1.43)]
        right=[(-.20,-.36,1.50),(-.70,-.10,1.62),(-1.27,.06,1.45)]
        ao_label='Aorta from left ventricle';pa_label='Pulmonary trunk from right ventricle'
    # Fallot has a separately selectable narrowed proximal outflow segment.
    if state=='normal_fallot':
        pa=[(-.55,-.30,1.20),(-.55,-.30,1.43),(-.08,-.34,1.65),(.55,-.35,1.63),(1.18,-.28,1.43)]
        right=[(-.08,-.34,1.65),(-.64,-.16,1.70),(-1.27,.06,1.51)]
    ao_outer,ao_inner=(.31,.235) if state=='fallot' else (.26,.20)
    a=sweep(root,'Aorta_'+state.title(),ao_label,ao,ao_outer,ao_inner,m['muscle'],state,(.055,.03,-.025))
    pr=.21 if state=='fallot' else .28;lr=.16 if state=='fallot' else .23
    p=sweep(root,'PulmonaryTrunk_'+state.title(),pa_label,pa,pr,lr,m['lining'],state,(-.05,.025,.03))
    r=sweep(root,'RightPulmonaryBranch_'+state.title(),'Right pulmonary branch',right,.17,.12,m['lining'],state,(-.065,.02,-.03))
    cutter=sweep(root,'BranchBore','temporary',right,.12,None,m['lining'],record=False)
    boolean(p,cutter)
    return [(ao[0][0],ao[0][1],ao_inner),(pa[0][0],pa[0][1],.23 if state=='fallot' else lr)]

def atria(root,m):
    for side,suffix in [(-1,'R'),(1,'L')]:
        for facing,panel in [(-1,'Anterior'),(1,'Posterior')]:
            o=ball('AtrialWall_'+suffix+'_'+panel,(0,1.0,.98),(1.03,.48,.64),m['muscle'])
            boolean(o,ball('AtrialCavity',(0,1.0,.98),(.94,.39,.55)))
            boolean(o,box((side*1.5,1.0,1),(3,4,4)),'INTERSECT')
            boolean(o,box((0,1.0+facing*1.5,1),(4,3,4)),'INTERSECT')
            for x in [-.51,.51]:boolean(o,sweep(root,'AVBore','temporary',av_path(x),.17,None,m['lining'],record=False))
            register(o,root,('Right' if side<0 else 'Left')+' atrial wall — '+panel.lower(),offset=(side*.035,.025,-facing*.045))
    for state in ['tga','normal']:
        o=ball('AtrialSeptum_'+state.title(),(0,1.0,.98),(.075,.40,.55),m['lining'])
        if state=='tga':boolean(o,bore((0,1.0,1.02),(.60,.20,.20)))
        register(o,root,'Atrial septum — '+('illustrative mixing opening' if state=='tga' else 'intact comparison'),state,(.05,.025,0))
    for x,label in [(-.51,'Right'),(.51,'Left')]:
        sweep(root,label+'AV',label+' AV connection',av_path(x),.23,.17,m['lining'],offset=(x*.06,0,-.035))

def build(root,number,m):
    if number==13:
        for state in ['fallot','normal_fallot']:
            ports=arteries(root,state,m)
            ventricle(root,state,m,ports,hypertrophy=state=='fallot')
            rvot(root,state,m)
        return [{'id':'fallot','label':'Tetralogy of Fallot'},{'id':'normal_fallot','label':'Normal comparison'}]
    for state in ['tga','normal']:
        ports=arteries(root,state,m)
        ventricle(root,state,m,ports,with_atria=True)
    atria(root,m)
    return [{'id':'tga','label':'d-TGA'},{'id':'normal','label':'Normal connections'}]

def export(root,number,states):
    name=root.name
    bpy.ops.object.select_all(action='DESELECT')
    for o in core.descendants(root):o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,
        export_animation=False,export_materials=True,generate_preview_surface=True,
        generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,
        convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',
        convert_scene_units='METERS',meters_per_unit=1.0)
    data={'asset':name,'batch':7,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
        'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior; USD +Y cranial, +Z anterior.',
        'states':states,'defaultState':states[0]['id'],'defaultCutaway':True,'parts':core.parts,
        'limitations':['Original regional illustrations, not patient reconstructions; expert anatomy review required',
            'Matched comparisons are alternatives, not repair, development or physiological simulations',
            'Simplified ventricular shape and exaggerated wall thickness; valve leaflets and coronary/arch branches omitted',
            'Fallot shows illustrative RV outflow narrowing; detailed conal malalignment and valve-level stenosis are not separately modeled',
            'd-TGA includes an illustrative atrial communication; no complete systemic/pulmonary return, PDA or VSD',
            'No animated flow, oxygen, pressure, contraction, severity grading or treatment simulation']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root)
    cam=bpy.context.scene.camera;cam.location=(-.44,-.76,.29)
    target=Vector((0,0,.025));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.315
    def display(state):
        for p in core.parts:
            o=bpy.data.objects[p['id']];hide=p.get('state',state)!=state or p['id'].endswith('_Anterior')
            o.hide_render=hide;o.hide_set(hide)
    display(states[0]['id']);bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [(states[0]['id'],'assembled'),(states[1]['id'],'layers')]:
        display(state);bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--stage',type=int,choices=[13,14],required=True)
    number=p.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup();root=core.group('Heart_13_TetralogyOfFallot' if number==13 else 'Heart_14_TranspositionGreatArteries')
    states=build(root,number,m);export(root,number,states)

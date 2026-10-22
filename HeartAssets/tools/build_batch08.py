"""Juxtaductal coarctation and PDA regional teaching assets. One asset per run.
Original geometry; structural comparisons, not time or hemodynamic simulations.
"""
import bpy, sys, json, argparse
from pathlib import Path
from math import sin, cos, pi
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import box, boolean, register
from build_batch05 import sweep

ARCH=[(-.65,0,-1.05),(-.65,0,.20),(-.65,0,.60)]+[(.20+.85*cos(pi-i*pi/24),0,.85+.85*sin(pi-i*pi/24)) for i in range(25)]
HEAD=[('Brachiocephalic','Brachiocephalic trunk',[(-.536,0,1.275),(-.68,0,1.85),(-.86,0,2.15)]),
      ('LeftCarotid','Left common carotid artery',[(.126,0,1.697),(.126,0,1.95),(.126,0,2.22)]),
      ('LeftSubclavian','Left subclavian artery',[(.746,0,1.501),(1.05,0,1.85),(1.18,0,2.15)])]
PA=[(-1.0,-.55,-1.0),(-.75,-.55,-.20),(-.20,-.50,.35),(.55,-.40,.40),(1.55,-.35,.38)]
RP=[(-.20,-.50,.35),(-.75,-.28,.48),(-1.45,.02,.40)]
DUCT=[(.55,-.40,.40),(.80,-.20,.49),(1.05,0,.58)]
LIGAMENT=[(.57,-.16,.40),(.69,-.14,.50),(.82,-.12,.58)]

def cut_panels(root,o,label,state=None,offset=(0,0,0),plane=.003):
    """Split a closed hollow mesh into two closed removable wall sections."""
    name=o.name
    for panel,side in [('Posterior',1),('Anterior',-1)]:
        c=o.copy();c.data=o.data.copy();bpy.context.collection.objects.link(c)
        c.name=name+'_'+panel
        clip(c,box((0,plane+side*2,0),(8,4,8)))
        register(c,root,label+' — '+panel.lower()+' cut',state,
                 (offset[0],offset[1],offset[2]-side*.035))
    bpy.data.objects.remove(o,do_unlink=True)

def clip(o,cutter,operation='INTERSECT'):
    # Manifold clipping keeps the previously drilled branch boundaries intact.
    bpy.context.view_layer.update();bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Teaching cut','BOOLEAN');mod.operation=operation
    mod.solver='MANIFOLD';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)

def isthmus(root,m,state,patent_duct=False):
    levels=[.20,.43,.61,.72,.81,.86,.90]
    inner=[.205,.20,.14,.085,.16,.205,.205] if state=='coarctation' else [.205]*7
    shift=[0,0,-.035,-.06,-.02,0,0] if state=='coarctation' else [0]*7
    # A posterior-biased shelf reduces the true channel rather than painting a band.
    vs=[];fs=[];n=80;row=n;layers=len(levels)*row
    for surface in [0,1]:
        for i,z in enumerate(levels):
            r=.27 if surface==0 else inner[i];cy=0 if surface==0 else shift[i]
            for j in range(n):
                a=2*pi*j/n;vs.append((1.05+r*cos(a),cy+r*sin(a),z))
    for h in [0,1]:
        for i in range(len(levels)-1):
            for j in range(n):
                a=h*layers+i*row+j;b=h*layers+i*row+(j+1)%n
                fs.append((a,b,b+row,a+row))
    for i in [0,len(levels)-1]:
        for j in range(n):
            a=i*row+j;b=i*row+(j+1)%n;fs.append((a,b,b+layers,a+layers))
    o=core.mesh('AorticIsthmus_'+state.title(),vs,fs,m['muscle'],root,'temporary');core.parts.pop()
    if patent_duct:
        boolean(o,sweep(root,'DuctBore','temporary',DUCT,.105,None,m['lining'],record=False))
    label='Aortic isthmus — '+('localized narrowing' if state=='coarctation' else 'open aortic lumen')
    cut_panels(root,o,label,state,(.055,0,0))

def surroundings(root,m):
    a=sweep(root,'AorticArch','temporary',ARCH,.27,.205,m['muscle'],record=False)
    # End the arch exactly at the isthmus interface: overlapping cut faces
    # would flicker when both separately selectable segments are assembled.
    clip(a,box((2.1,0,-1.55),(2.8,4,4.9)),'DIFFERENCE')
    for name,label,path in HEAD:
        boolean(a,sweep(root,'BranchBore','temporary',path,.085,None,m['lining'],record=False))
        branch=sweep(root,name,'temporary',path,.135,.085,m['muscle'],record=False)
        # Trim the branch at the arch exterior to avoid intraluminal stubs and
        # overlapping coplanar cut faces at the separately selectable junction.
        boolean(branch,sweep(root,'ArchEnvelope','temporary',ARCH,.27,None,m['muscle'],record=False))
        cut_panels(root,branch,label,offset=(path[-1][0]*.025,.04,0))
    cut_panels(root,a,'Ascending aorta and arch',offset=(-.04,.025,0))
    d=sweep(root,'DescendingAorta','temporary',[(1.05,0,.20),(1.05,0,-.40),(1.05,0,-1.25)],.27,.205,m['muscle'],record=False)
    cut_panels(root,d,'Descending thoracic aorta',offset=(.055,-.025,0))

def pulmonary(root,m,state=None,patent=False):
    suffix='_'+state.title() if state else ''
    p=sweep(root,'PulmonaryTrunk'+suffix,'temporary',PA,.25,.18,m['lining'],record=False)
    boolean(p,sweep(root,'RightBranchBore','temporary',RP,.11,None,m['lining'],record=False))
    if patent:boolean(p,sweep(root,'DuctBore','temporary',DUCT,.105,None,m['lining'],record=False))
    # Keep the trunk whole: oblique vessel cuts would obscure the ductal mouth.
    register(p,root,'Pulmonary trunk and left pulmonary branch'+(' — patent ductal mouth' if patent else ''),state,(-.04,.015,.04))
    r=sweep(root,'RightPulmonaryBranch'+suffix,'Right pulmonary branch',RP,.16,.11,m['lining'],state,(-.05,.015,-.03))

def build(root,number,m):
    surroundings(root,m)
    if number==15:
        pulmonary(root,m)
        for state in ['coarctation','normal']:isthmus(root,m,state)
        sweep(root,'Ligamentum','Ligamentum arteriosum — ductal attachment landmark',LIGAMENT,.045,None,m['endoderm'],offset=(.035,.025,.035))
        return [{'id':'coarctation','label':'Coarctation'},{'id':'normal','label':'Open comparison'}]
    for state in ['patent','closed']:
        isthmus(root,m,state,patent_duct=state=='patent')
        pulmonary(root,m,state,patent=state=='patent')
    d=sweep(root,'Ductus_Patent','temporary',DUCT,.155,.105,m['cord'],record=False)
    # An oblique cut follows the duct axis (y=.8*x-.84). A tiny shared
    # plane offset avoids Boolean degeneracies at existing mesh vertices.
    name=d.name
    for panel,side in [('Posterior',1),('Anterior',-1)]:
        c=d.copy();c.data=d.data.copy();bpy.context.collection.objects.link(c);c.name=name+'_'+panel
        normal=Vector((-.8,1,0)).normalized();center=Vector((.80,-.20,.49))+(side*2+.003)*normal
        cutter=box(center,(8,4,8));cutter.rotation_euler[2]=__import__('math').atan(.8)
        clip(c,cutter)
        register(c,root,'Patent ductus lumen — '+panel.lower()+' cut','patent',(.04,.025,-side*.035))
    bpy.data.objects.remove(d,do_unlink=True)
    sweep(root,'Ligamentum_Closed','Ligamentum arteriosum — closed remnant',LIGAMENT,.045,None,m['endoderm'],'closed',(.035,.025,.035))
    return [{'id':'patent','label':'Patent ductus'},{'id':'closed','label':'Closed remnant'}]

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
    data={'asset':name,'batch':8,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
        'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior; USD +Y cranial, +Z anterior.',
        'states':states,'defaultState':states[0]['id'],'defaultCutaway':True,'parts':core.parts,
        'limitations':['Enlarged regional vessel illustrations; not patient anatomy or severity grading',
            'Coarctation depicts one localized eccentric narrowing; diffuse arch hypoplasia and collaterals are omitted',
            'PDA compares patent and anatomically closed states, not immediate birth closure or a treatment sequence',
            'Closed parent-vessel walls are restored; the ligament has no lumen',
            'No chambers, coronary anatomy, complete distal branches, flow, pressure, oxygen or closure animation',
            'Expert anatomical review required before assessed teaching use']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root);cam=bpy.context.scene.camera;cam.location=(.14,-.72,.36)
    cam.rotation_euler=(Vector((0,0,.028))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.29
    def display(state):
        for p in core.parts:
            o=bpy.data.objects[p['id']];hide=p.get('state',state)!=state or p['id'].endswith('_Anterior')
            o.hide_render=hide;o.hide_set(hide)
    display(states[0]['id']);bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [(states[0]['id'],'assembled'),(states[1]['id'],'layers')]:
        display(state);bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--stage',type=int,choices=[15,16],required=True)
    number=p.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup();root=core.group('Heart_15_AorticCoarctation' if number==15 else 'Heart_16_PatentDuctusArteriosus')
    states=build(root,number,m);export(root,number,states)

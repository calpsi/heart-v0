"""Regional ventricular and outflow septation illustrations, one asset per run.
Original geometry; enlarged static states, not a whole-heart reconstruction.
"""
import bpy,sys,json,math,argparse
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,box,bore,boolean,register
from math import sin,cos,pi

def tube(root,name,label,center,radius,z0,z1,m,state=None):
    for panel,a0 in [('Posterior',0),('Anterior',pi)]:
        vs=[];fs=[];n=40
        for r in [radius,radius-.055]:
            for z in [z0,z1]:
                for i in range(n+1):
                    a=a0+pi*i/n;vs.append((center[0]+r*cos(a),center[1]+r*sin(a),z))
        row=n+1
        for i in range(n):
            fs.extend([(i,i+1,i+1+row,i+row),(2*row+i,3*row+i,3*row+i+1,2*row+i+1),
                (i,2*row+i,2*row+i+1,i+1),(row+i,row+i+1,3*row+i+1,3*row+i)])
        for i in [0,n]:fs.append((i,i+row,i+3*row,i+2*row))
        core.mesh(name+'_'+panel,vs,fs,m,root,label+' — '+panel.lower()+' panel')
        core.parts[-1]['separationOffset']=[center[0]*.05,.02,.04 if panel=='Anterior' else -.04]
        if state:core.parts[-1]['state']=state

def septal_blank(name,m):
    return ball(name,(0,0,-.15),(.12,.72,1.06),m)

def communication():return bore((0,-.18,.51),(.8,.235,.22))

def ventricular(root,m):
    for side,suffix in [(-1,'R'),(1,'L')]:
        for facing,panel in [(-1,'Anterior'),(1,'Posterior')]:
            o=ball('VentricularWall_'+suffix+'_'+panel,(0,0,-.15),(1.18,.80,1.18),m['muscle'])
            boolean(o,ball('Cavity',(0,0,-.15),(1.07,.69,1.07)))
            boolean(o,box((side*1.5,0,0),(3,4,5)),'INTERSECT')
            boolean(o,box((0,facing*1.5,0),(4,3,5)),'INTERSECT')
            # Superior open junctions provide two AV inlets and outlet access.
            for x,y in [(-.52,.20),(.52,.20),(-.43,-.28),(.43,-.28)]:
                boolean(o,bore((x,y,1.1),(.25,.25,1.0),axis='Z'))
            register(o,root,('Right' if side==-1 else 'Left')+' ventricular wall — '+panel.lower()+' panel',offset=(side*.035,0,-facing*.055))
    for state in ['open','closed']:
        o=septal_blank('MuscularSeptum_'+state.title(),m['muscle'])
        boolean(o,communication());boolean(o,box((0,0,-1.3),(2,3,3.4)),'INTERSECT') # crest at z=.4
        register(o,root,'Muscular ventricular septum — '+('open communication' if state=='open' else 'closure state'),state,(.05,-.025,0))
    for sign,name,label in [(1,'AVSeptalContribution','AV cushion contribution'),(-1,'OutletSeptalContribution','Proximal outlet cushion contribution')]:
        o=septal_blank(name,m['jelly'])
        boolean(o,communication());boolean(o,box((0,0,1.7),(2,3,2.6)),'INTERSECT') # z>=.4
        boolean(o,box((0,sign*1.5,0),(2,3,4)),'INTERSECT')
        register(o,root,label,offset=(0,.025,-sign*.035))
    o=septal_blank('MembranousSeptum_Closed',m['lining']);boolean(o,communication(),'INTERSECT')
    register(o,root,'Membranous septal closure — enlarged teaching patch','closed',(-.05,.025,0))
    tube(root,'SubaorticOutlet','Left ventricular subaortic outlet',(.43,-.28),.25,.74,1.52,m['lining'],'closed')
    tube(root,'SubpulmonaryOutlet','Right ventricular subpulmonary outlet',(-.43,-.28),.25,.74,1.52,m['lining'],'closed')
    # Small fused trabecular ribs on the posterior ventricular surface.
    for side,suffix in [(-1,'R'),(1,'L')]:
        for k in range(3):
            x=side*(.45+.14*k)
            o=ball('Trabecula_'+suffix+str(k+1),(x,.49-.06*k,-.38+.12*k),(.10,.10,.29),m['muscle'])
            register(o,root,('Right' if side==-1 else 'Left')+' ventricular trabecular ridge '+str(k+1),offset=(side*.04,0,-.035))

def frame(t):
    # A schematic quarter-turn makes nonparallel lumen paths inspectable.
    # This is not a prescribed embryological rotation angle.
    angle=pi*.5*t
    return Vector((.12*sin(pi*t),0,-1.15+2.6*t)),Vector((cos(angle),sin(angle),0)),Vector((-sin(angle),cos(angle),0))

def loft(root,name,label,section,m,state=None,offset=(0,0,0)):
    vs=[];fs=[];n=64;count=len(section)
    for i in range(n+1):
        c,u,v=frame(i/n)
        for a,b in section:vs.append(c+a*u+b*v)
    for i in range(n):
        for j in range(count):
            a=i*count+j;b=i*count+(j+1)%count;fs.append((a,b,b+count,a+count))
    fs.extend([tuple(reversed(range(count))),tuple(n*count+j for j in range(count))])
    core.mesh(name,vs,fs,m,root,label)
    core.parts[-1]['separationOffset']=list(offset)
    if state:core.parts[-1]['state']=state

def outflow(root,m):
    # Cutaway follows the twisted tube's two opposite half-shells.
    for panel,start in [('Posterior',0),('Anterior',pi)]:
        section=[]
        for r,indices in [(.56,range(33)),(.48,range(32,-1,-1))]:
            section += [(r*cos(start+pi*i/32),r*sin(start+pi*i/32)) for i in indices]
        loft(root,'OutflowWall_'+panel,'Truncoconal wall — '+panel.lower()+' teaching panel',section,m['muscle'],offset=(0,0,.065 if panel=='Anterior' else -.065))
    for side,name in [(1,'Septal'),(-1,'Parietal')]:
        for state in ['ridges','divided']:
            if state=='ridges':
                section=[(side*(.40+.10*cos(2*pi*j/24)),.095*sin(2*pi*j/24)) for j in range(24)]
            else:
                section=[(side*a,b) for a,b in [(0,-.085),(.50,-.085),(.50,.085),(0,.085)]]
            loft(root,name+'Ridge_'+state.title(),name.lower()+' outflow cushion — '+('opposing ridge' if state=='ridges' else 'fused partition'),section,m['jelly'],state,(side*.045,0,0))
    end,u,v=frame(1)
    for side,name in [(1,'Aortic'),(-1,'Pulmonary')]:
        c=end+side*.28*v
        tube(root,name+'Trunk',name+' trunk outlet',(c.x,c.y),.24,1.38,2.05,m['muscle'],'divided')
        for k in range(3):
            a=2*pi*k/3
            o=ball(name+'CuspPrimordium_'+str(k+1),(c.x+.158*cos(a),c.y+.158*sin(a),1.70),(.068,.068,.075),m['lining'])
            register(o,root,name+' semilunar cusp primordium '+str(k+1),'divided',(side*.03,.035,0))
    for i,t in enumerate([.25,.43,.61,.79],1):
        c,u,v=frame(t);c+=(1 if i%2 else -1)*.395*u-.11*v
        o=ball('NeuralCrestMarker_'+str(i),c,(.038,.038,.05),m['cord'])
        register(o,root,'Neural-crest contribution marker '+str(i)+' (schematic)','ridges',(.025,0,.035))
        core.parts[-1]['category']='context';o['category']='context'

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
    data={'asset':name,'batch':4,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
        'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior; USD +Y cranial, +Z anterior. Outflow is a regional schematic, not a registered whole-heart coordinate system.',
        'display_scale':'enlarged regional illustration, not embryo life size','states':states,'defaultState':states[0]['id'],
        'defaultCutaway':True,'parts':core.parts,'limitations':[
            'Discrete structural snapshots; no tissue-growth, blood-flow or flap animation',
            'Simplified regional anatomy with exaggerated thickness; requires expert teaching review',
            'No atria, coronary arteries, arch branches or complete venous connections',
            'Ventricular outlet alignment and outflow twist are illustrative, not exact human staging',
            'Semilunar structures are rounded primordia, not functional mature valve leaflets']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root)
    cam=bpy.context.scene.camera;cam.location=(-.40,-.65,.20) if number==7 else (.25,-.65,.27)
    target=Vector((0,0,0 if number==7 else .025));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=.245 if number==7 else .265
    def display(state):
        for p in core.parts:
            o=bpy.data.objects[p['id']];hide=p.get('state',state)!=state or p['id'].endswith('_Anterior')
            o.hide_render=hide;o.hide_set(hide)
    display(states[0]['id']);bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [(states[0]['id'],'assembled'),(states[1]['id'],'layers')]:
        display(state);bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--stage',required=True,type=int,choices=[7,8])
    number=parser.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup();root=core.group('Heart_07_VentricularSeptation' if number==7 else 'Heart_08_OutflowSeptation')
    (ventricular if number==7 else outflow)(root,m)
    states=([{'id':'open','label':'Open communication'},{'id':'closed','label':'Septal closure'}] if number==7 else
        [{'id':'ridges','label':'Opposing ridges'},{'id':'divided','label':'Divided outflow'}])
    export(root,number,states)

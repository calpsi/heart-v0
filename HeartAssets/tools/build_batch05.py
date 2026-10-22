"""Valve refinement and perinatal shunt teaching models. Build one at a time.
Original enlarged illustrations; discrete states, no physiological simulation.
"""
import bpy,sys,json,argparse,math
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_batch01 as core
from build_batch03 import ball,box,bore,boolean,register
from build_batch04 import tube
S=core.S

def tag(state=None,offset=(0,0,0),context=False):
    p=core.parts[-1];p['separationOffset']=list(offset)
    if state:p['state']=state
    if context:p['category']='context'

def leaf(root,name,label,c,radius,a0,a1,thickness,m,state,lower=0,upper=1):
    vs=[];fs=[];n=24;k=10
    # A curved, open leaflet with a free central edge. All margins have thickness.
    for height in [lower,upper]:
        for i in range(k+1):
            t=i/k;r=radius*(.24+.76*t)
            for j in range(n+1):
                a=a0+(a1-a0)*j/n
                z=c[2]-.32*(1-t)**.75+.025*sin(pi*j/n)*(1-t)
                vs.append((c[0]+r*cos(a),c[1]+r*sin(a),z+thickness*(height-.5)))
    row=n+1;layer=(k+1)*row
    for h in [0,1]:
        for i in range(k):
            for j in range(n):
                a=h*layer+i*row+j;fs.append((a,a+1,a+1+row,a+row))
    for i in [0,k]:
        for j in range(n):
            a=i*row+j;fs.append((a,a+1,a+1+layer,a+layer))
    for j in [0,n]:
        for i in range(k):
            a=i*row+j;fs.append((a,a+row,a+row+layer,a+layer))
    core.mesh(name,vs,fs,m,root,label);tag(state,(0,.025+(lower+upper)*.014,0))

def cord(root,name,start,end,m,state):
    a=Vector(start)*S;b=Vector(end)*S
    bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.012*S,depth=(b-a).length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    o.data.materials.append(m)
    register(o,root,name.replace('_',' '),state,(0,0,.025))

def valves(root,m):
    for name,c,count,r in [('Mitral',(.72,0,.10),2,.48),('Tricuspid',(-.72,0,.10),3,.50),
                            ('Aortic',(.38,.91,.52),3,.27),('Pulmonary',(-.38,.91,.62),3,.27)]:
        av=name in ['Mitral','Tricuspid']
        tube(root,name+'Annulus',name+' annular support',c[:2],r+.05,c[2]-.04,c[2]+.07,m['muscle'])
        if av:
            for panel,side in [('Anterior',-1),('Posterior',1)]:
                o=ball(name+'Wall_'+panel,(c[0],c[1],-.25),(.61,.57,1.15),m['muscle'])
                boolean(o,ball('Inner',(c[0],c[1],-.25),(.53,.49,1.05)))
                boolean(o,box((c[0],c[1],-1.5),(2,2,3.1)),'INTERSECT')
                boolean(o,box((c[0],side*1.5,0),(2,3,4)),'INTERSECT')
                register(o,root,name+' ventricular support — '+panel.lower()+' cut',offset=(.04 if c[0]>0 else -.04,0,-side*.05))
        for i in range(count):
            a0=2*pi*i/count+.025;a1=2*pi*(i+1)/count-.025
            lname=(['Anterior','Posterior'][i] if name=='Mitral' else ['Anterior','Posterior','Septal'][i] if name=='Tricuspid' else 'Cusp'+str(i+1))
            for state,thick in [('cushions',.095),('refined',.035)]:
                if name=='Aortic' and i==0 and state=='refined':
                    for tissue,lo,hi,key in [('Ventricularis',0,.3,'lining'),('Spongiosa',.3,.65,'jelly'),('Fibrosa',.65,1,'endoderm')]:
                        leaf(root,tissue+'_AorticCusp1_Refined',tissue+' — enlarged aortic cusp layer',c,r,a0,a1,thick,m[key],state,lo,hi)
                else:
                    leaf(root,name+'_'+lname+'_'+state.title(),name+' '+lname.lower()+' — '+state,c,r,a0,a1,thick,m['lining'],state)
        if av:
            pap_count=2 if name=='Mitral' else 3
            tips=[]
            for i in range(pap_count):
                a=2*pi*(i+.5)/pap_count
                tip=(c[0]+.28*cos(a),.28*sin(a),-.63)
                o=ball(name+'Papillary_'+str(i+1),(tip[0],tip[1],-.87),(.105,.105,.25),m['muscle'])
                register(o,root,name+' papillary muscle '+str(i+1),state='refined',offset=(0,-.035,0));tips.append(tip)
            # Two tethers per leaflet to different muscle tips, without assigning
            # a single muscle exclusively to one mitral leaflet.
            for i in range(count):
                for j in range(2):
                    a=2*pi*(i+.30+.40*j)/count
                    free=(c[0]+r*.24*cos(a),r*.24*sin(a),c[2]-.32+.025*sin(pi*(.30+.40*j)))
                    cord(root,name+'Chord_'+str(i+1)+'_'+str(j+1),free,tips[(i+j)%pap_count],m['lining'],'refined')

# Smooth sampled paths for open-ended, hollow vessel meshes.
def samples(knots,steps=10):
    pts=[Vector(p) for p in knots];result=[]
    for i in range(len(pts)-1):
        p0=pts[max(0,i-1)];p1=pts[i];p2=pts[i+1];p3=pts[min(len(pts)-1,i+2)]
        for j in range(steps):
            t=j/steps
            result.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
    result.append(pts[-1]);return result

def sweep(root,name,label,knots,outer,inner,m,state=None,offset=(0,0,0),record=True):
    pts=samples(knots);vs=[];fs=[];n=len(pts);sides=32;axes=[]
    for i,p in enumerate(pts):
        t=(pts[min(i+1,n-1)]-pts[max(0,i-1)]).normalized()
        ref=Vector((0,1,0))
        if abs(t.dot(ref))>.95:ref=Vector((1,0,0))
        u=ref.cross(t).normalized();v=t.cross(u).normalized();axes.append((u,v))
    radii=[outer,inner] if inner else [outer]
    for r in radii:
        for p,(u,v) in zip(pts,axes):
            for j in range(sides):vs.append(p+r*(cos(2*pi*j/sides)*u+sin(2*pi*j/sides)*v))
    layer=n*sides
    for h in range(len(radii)):
        for i in range(n-1):
            for j in range(sides):
                a=h*layer+i*sides+j;b=h*layer+i*sides+(j+1)%sides
                fs.append((a,b,b+sides,a+sides))
    if inner:
        for i in [0,n-1]:
            for j in range(sides):
                a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+layer,a+layer))
    else:
        fs.extend([tuple(reversed(range(sides))),tuple((n-1)*sides+j for j in range(sides))])
    o=core.mesh(name,vs,fs,m,root,label)
    if record:tag(state,offset)
    else:core.parts.pop()
    return o

def birth(root,m):
    # Four-chamber spatial context with real hollow cavities and removable fronts.
    for region,cz,rz,rx,ry in [('Atrium',.73,.57,1.02,.62),('Ventricle',-.55,.80,1.02,.72)]:
        for side,suffix in [(-1,'R'),(1,'L')]:
            for facing,panel in [(-1,'Anterior'),(1,'Posterior')]:
                o=ball(region+'Wall_'+suffix+'_'+panel,(0,0,cz),(rx,ry,rz),m['muscle'])
                boolean(o,ball('Cavity',(0,0,cz),(rx-.085,ry-.085,rz-.085)))
                boolean(o,box((side*1.5,0,0),(3,4,5)),'INTERSECT')
                boolean(o,box((0,facing*1.5,0),(4,3,5)),'INTERSECT')
                for x in [-.48,.48]:boolean(o,bore((x,0,.17),(.25,.25,.7),axis='Z'))
                if region=='Ventricle':
                    for x in [-.43,.43]:boolean(o,bore((x,-.33,.15),(.21,.21,.65),axis='Z'))
                register(o,root,('Right' if side<0 else 'Left')+' '+region.lower()+' wall — '+panel.lower()+' cut',offset=(side*.035,0,-facing*.05))
    o=ball('VentricularSeptum',(0,0,-.55),(.09,.67,.78),m['muscle']);register(o,root,'Ventricular septum',offset=(.045,-.015,0))
    o=ball('AtrialSeptum',(0,0,.73),(.07,.56,.55),m['muscle']);boolean(o,bore((0,0,.78),(.5,.21,.24)))
    register(o,root,'Atrial septal rim around foramen ovale',offset=(-.04,.025,0))
    for state in ['fetal','transition']:
        o=ball('ForamenFlap_'+state.title(),(.065,0,.78),(.025,.26,.29),m['lining'])
        if state=='fetal':
            for vert in o.data.vertices:
                world_z=(vert.co.z+o.location.z)/S
                vert.co.x+=S*.30*max(0,(1.07-world_z)/.58)
        register(o,root,'Foramen ovale flap — '+('open toward left atrium' if state=='fetal' else 'apposed after birth'),state,(.065,0,0))
    for x,name in [(-.48,'RightAV'),(.48,'LeftAV')]:tube(root,name,name+' junction', (x,0),.28,.05,.37,m['lining'])
    aorta=[(.43,-.33,-.12),(.47,-.42,.85),(.57,-.12,1.48),(1.05,.10,1.55),(1.32,.13,.94),(1.32,.13,-.8)]
    pa=[(-.43,-.33,-.12),(-.38,-.66,.63),(-.08,-.60,1.10),(.35,-.40,1.11),(.85,-.25,.99)]
    branch=[(-.08,-.60,1.10),(-.60,-.38,1.0),(-1.18,-.10,.76)]
    duct=[(.35,-.40,1.11),(.66,-.24,1.25),(1.08,.09,1.42),(1.30,.13,1.02)]
    # Both duct ends overlap the main lumens. Remove the main-wall material
    # along the patent duct bore before exporting the independent objects.
    ao=sweep(root,'Aorta','Ascending aorta, arch and descending segment',aorta,.21,.145,m['muscle'],offset=(.05,.035,-.025))
    pul=sweep(root,'PulmonaryArtery','Pulmonary trunk and left pulmonary branch',pa,.20,.135,m['lining'],offset=(-.045,.025,.03))
    rp=sweep(root,'RightPulmonaryArtery','Right pulmonary artery',branch,.145,.095,m['lining'],offset=(-.05,.01,-.03))
    for target in [ao,pul]:
        cutter=sweep(root,'DuctBore','temporary',duct,.115,None,m['lining'],record=False);boolean(target,cutter)
    cutter=sweep(root,'BranchBore','temporary',branch,.095,None,m['lining'],record=False);boolean(pul,cutter)
    # Ensure branch mouth itself has no parent-wall plug.
    for state,r in [('fetal',.115),('transition',.035)]:
        sweep(root,'Ductus_'+state.title(),'Ductus arteriosus — '+('patent fetal lumen' if state=='fetal' else 'constricting, still patent'),duct,.16,r,m['cord'],state,(.055,.05,.035))
    for side,suffix in [(-1,'R'),(1,'L')]:
        o=ball('Lung_'+suffix,(side*1.69,.24,.20),(.42,.30,.85),m['mesoderm'])
        register(o,root,('Right' if side<0 else 'Left')+' lung (orientation context)',offset=(side*.05,0,-.03))
        core.parts[-1]['category']='context';o['category']='context'


def export(root,number,states):
    name=root.name
    bpy.ops.object.select_all(action='DESELECT')
    for o in core.descendants(root):o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,export_animation=False,
        export_materials=True,generate_preview_surface=True,generate_materialx_network=False,export_textures_mode='NEW',
        export_custom_properties=True,convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',convert_scene_units='METERS',meters_per_unit=1.0)
    data={'asset':name,'batch':5,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
        'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior. USD +Y cranial, +Z anterior. Valve assemblies are spaced apart for teaching.',
        'display_scale':'enlarged educational illustration, not patient or embryo dimensions',
        'states':states,'defaultState':states[0]['id'],'defaultCutaway':True,'parts':core.parts,
        'limitations':['Discrete illustrative states; no flow, pressure, contraction or inflation simulation',
            'Exaggerated wall/leaflet thickness and simplified spatial relationships; anatomical review required',
            'Birth model omits complete pulmonary venous/systemic returns, coronary vessels and arch branches',
            'Ductus narrowing and flap apposition depict different aspects of a gradual transition, not simultaneous complete anatomical closure',
            'Three-layer cusp segmentation is a simplified teaching section, not histology']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root);cam=bpy.context.scene.camera
    cam.location=(.25,-.65,.50) if number==9 else (-.32,-.70,.29)
    target=Vector((0,0,0));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.26 if number==9 else .33
    def display(state):
        for p in core.parts:
            hide=p.get('state',state)!=state or p['id'].endswith('_Anterior')
            o=bpy.data.objects[p['id']];o.hide_render=hide;o.hide_set(hide)
    display(states[0]['id']);bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [(states[0]['id'],'assembled'),(states[1]['id'],'layers')]:
        display(state);bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--stage',type=int,choices=[9,10],required=True)
    number=p.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup();root=core.group('Heart_09_ValvularRefinement' if number==9 else 'Heart_10_CirculatoryTransition')
    (valves if number==9 else birth)(root,m)
    states=([{'id':'cushions','label':'Early cushions'},{'id':'refined','label':'Later anatomy reference'}] if number==9 else
        [{'id':'fetal','label':'Before birth'},{'id':'transition','label':'After birth · transitioning'}])
    export(root,number,states)

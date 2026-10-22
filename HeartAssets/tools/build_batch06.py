"""Two regional congenital septal-defect illustrations, built one at a time.
Intact/defect comparisons are alternatives, not a developmental or repair sequence.
"""
import bpy, sys, json, argparse
from pathlib import Path
from math import pi
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_batch01 as core
import build_batch04 as regional
from build_batch03 import ball, box, bore, boolean, register
from build_batch05 import leaf

def vsd(root, m):
    regional.ventricular(root, m)
    # Reuse the regional ventricular envelope, replacing developmental states
    # with an intact comparison and a perimembranous tissue deficiency.
    for p in list(core.parts):
        if p['id'] == 'MuscularSeptum_Closed':
            bpy.data.objects.remove(bpy.data.objects[p['id']], do_unlink=True)
            core.parts.remove(p)
        elif p['id'] == 'MembranousSeptum_Closed':
            p['state'] = 'intact'
            p['label'] = 'Membranous region — intact comparison tissue'
        else:
            p.pop('state', None)
    for p in core.parts:
        if p['id'] == 'MuscularSeptum_Open':
            p['label'] = 'Muscular ventricular septum — inferior defect border'
        elif p['id'] == 'AVSeptalContribution':
            p['label'] = 'Superior septal rim beside tricuspid attachment'
            bpy.data.objects[p['id']].data.materials.clear()
            bpy.data.objects[p['id']].data.materials.append(m['lining'])
        elif p['id'] == 'OutletSeptalContribution':
            p['label'] = 'Outlet septal rim below aortic root'
        bpy.data.objects[p['id']]['display_name'] = p['label']
    # Leaflets provide nearby landmarks, not a complete mature valve apparatus.
    for i in range(3):
        leaf(root, 'AorticCusp_'+str(i+1), 'Aortic cusp '+str(i+1)+' (orientation landmark)',
             (.43,-.28,1.24), .195, 2*pi*i/3+.02, 2*pi*(i+1)/3-.02, .03, m['lining'], None)
    o=ball('TricuspidSeptalLeaflet',(-.19,.21,.69),(.19,.23,.035),m['lining'])
    register(o,root,'Tricuspid septal leaflet (orientation landmark)',offset=(-.045,.03,0))

def asd(root,m):
    for side,suffix in [(-1,'R'),(1,'L')]:
        for facing,panel in [(-1,'Anterior'),(1,'Posterior')]:
            o=ball('AtrialWall_'+suffix+'_'+panel,(0,0,.5),(1.15,.75,.95),m['muscle'])
            boolean(o,ball('Cavity',(0,0,.5),(1.06,.66,.86)))
            boolean(o,box((side*1.5,0,0),(3,4,5)),'INTERSECT')
            boolean(o,box((0,facing*1.5,0),(4,3,5)),'INTERSECT')
            for x in [-.52,.52]:boolean(o,bore((x,-.15,-.40),(.28,.28,.95),axis='Z'))
            if side<0:boolean(o,bore((-.64,.18,.5),(.19,.19,3.2),axis='Z'))
            register(o,root,('Right' if side<0 else 'Left')+' atrial wall — '+panel.lower()+' panel',offset=(side*.045,0,-facing*.055))
    o=ball('AtrialSeptalRim',(0,0,.5),(.09,.68,.87),m['muscle'])
    boolean(o,bore((0,0,.52),(.6,.36,.40)))
    register(o,root,'Rim around oval fossa (enlarged)',offset=(.045,0,0))
    for state in ['defect','intact']:
        o=ball('FossaFloor_'+state.title(),(.018,0,.52),(.037,.405,.455),m['lining'])
        if state=='defect':boolean(o,bore((0,0,.52),(.6,.22,.265)))
        register(o,root,'Oval fossa floor — '+('secundum tissue deficiency' if state=='defect' else 'intact comparison'),state,(-.045,0,0))
    for x,name,label in [(-.52,'RightAV','Right AV junction'),(.52,'LeftAV','Left AV junction')]:
        regional.tube(root,name,label,(x,-.15),.28,-.58,-.03,m['lining'])
    regional.tube(root,'SuperiorCavalMouth','Superior caval opening',(-.64,.18),.19,1.03,1.65,m['muscle'])
    regional.tube(root,'InferiorCavalMouth','Inferior caval opening',(-.64,.18),.19,-.65,-.03,m['muscle'])
    for i in range(4):
        o=ball('RightPectinate_'+str(i+1),(-.67-.065*i,.41-.07*i,.55),(.055,.055,.30-.025*i),m['muscle'])
        register(o,root,'Right atrial pectinate ridge '+str(i+1)+' (schematic)',offset=(-.04,0,-.035))

def export(root,number):
    name=root.name
    states=[{'id':'defect','label':'Perimembranous VSD' if number==11 else 'Secundum ASD'},
            {'id':'intact','label':'Intact septum'}]
    bpy.ops.object.select_all(action='DESELECT')
    for o in core.descendants(root):o.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.wm.usd_export(filepath=str(core.EXPORT/(name+'.usdz')),selected_objects_only=True,
        export_animation=False,export_materials=True,generate_preview_surface=True,
        generate_materialx_network=False,export_textures_mode='NEW',export_custom_properties=True,
        convert_orientation=True,export_global_up_selection='Y',export_global_forward_selection='NEGATIVE_Z',
        export_lights=False,export_cameras=False,triangulate_meshes=True,root_prim_path='/HeartAsset',
        convert_scene_units='METERS',meters_per_unit=1.0)
    data={'asset':name,'batch':6,'status':'illustrative_prototype','units':'metres','usd_up_axis':'Y',
        'coordinate_note':'Blender +X anatomical left, +Z cranial, -Y anterior; USD +Y cranial, +Z anterior.',
        'display_scale':'Enlarged regional illustration, not patient dimensions',
        'states':states,'defaultState':'defect','defaultCutaway':True,'parts':core.parts,
        'limitations':['Regional anatomy with exaggerated thickness; anatomical review required',
            'Intact and defect states are structural comparisons, not repair or growth animations',
            'Only perimembranous VSD or secundum ASD is represented; other subtypes are not modeled',
            'No blood flow, pressure, chamber enlargement, conduction pathways or complete valve apparatus',
            'Incomplete whole-heart and venous context; the ASD is a tissue deficiency, not a PFO flap']}
    (core.BASE/'manifests'/(name+'.json')).write_text(json.dumps(data,indent=2))
    core.presentation(root)
    cam=bpy.context.scene.camera;cam.location=(-.62,-.52,.24)
    target=Vector((0,0,0 if number==11 else .032))
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale=.235
    def display(state):
        for p in core.parts:
            o=bpy.data.objects[p['id']]
            hide=p.get('state',state)!=state or p['id'].endswith('_Anterior')
            o.hide_render=hide;o.hide_set(hide)
    display('defect');bpy.ops.wm.save_as_mainfile(filepath=str(core.BASE/'blender'/(name+'.blend')))
    for state,suffix in [('defect','assembled'),('intact','layers')]:
        display(state);bpy.context.scene.render.filepath=str(core.BASE/'previews'/(name+'_'+suffix+'.png'))
        bpy.ops.render.render(write_still=True)
    print('COMPLETED',name,len(core.parts),'parts',flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--stage',type=int,choices=[11,12],required=True)
    number=p.parse_args(sys.argv[sys.argv.index('--')+1:]).stage
    m=core.setup();root=core.group('Heart_11_VentricularSeptalDefect' if number==11 else 'Heart_12_AtrialSeptalDefect')
    (vsd if number==11 else asd)(root,m)
    export(root,number)

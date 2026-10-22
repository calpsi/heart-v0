"""Original symbolic 3D UI art. Decorative branding, not anatomical models."""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector
from math import sin, cos, pi, sqrt
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'HeartAssets/ui'; OUT.mkdir(exist_ok=True)
ASSETS=ROOT/'heart v3/Assets.xcassets'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version=0

def mat(name,color,metal=0,rough=.28):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    p.inputs['Coat Weight'].default_value=.3
    return m
rose=mat('Rose lacquer',(.65,.065,.18),.1)
blush=mat('Blush porcelain',(.93,.48,.58),.15)
ivory=mat('Warm ivory',(.92,.76,.70),0,.4)
edge=mat('Book cover',(.36,.025,.09),.1)

def mesh(name,vs,fs,m):
    data=bpy.data.meshes.new(name);data.from_pydata(vs,[],fs);data.update()
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.data.materials.append(m)
    for p in data.polygons:p.use_smooth=True
    return o

# A rounded, closed heart-shaped lens with real front/back surfaces.
N=128; R=20; vs=[];fs=[]
for side in (-1,1):
    start=len(vs);vs.append((0,side*.34,0))
    for ring in range(1,R+1):
        r=ring/R
        for j in range(N):
            t=2*pi*j/N
            x=sin(t)**3
            z=(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))/17+.12
            vs.append((x*r,side*.34*sqrt(max(0,1-r*r)),z*r))
    for j in range(N):fs.append((start,start+1+j,start+1+(j+1)%N))
    for ring in range(R-1):
        for j in range(N):
            a=start+1+ring*N+j;b=start+1+ring*N+(j+1)%N
            fs.append((a,b,b+N,a+N))
# Merge the two equators for a watertight silhouette.
heart=mesh('HeartEmblem',vs,fs,rose)
bm=bmesh.new();bm.from_mesh(heart.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(heart.data);bm.free()

bpy.ops.mesh.primitive_torus_add(major_radius=1.3,minor_radius=.045,major_segments=96,minor_segments=12,rotation=(pi/2+.25,.35,-.3))
ring=bpy.context.object;ring.name='ExplorationOrbit';ring.data.materials.append(blush)
for p in ring.data.polygons:p.use_smooth=True
bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,radius=.12,location=(1.15,-.40,.4))
bead=bpy.context.object;bead.name='OrbitMarker';bead.data.materials.append(ivory)
for p in bead.data.polygons:p.use_smooth=True

def cube(name,loc,scale,m,rotation=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object;o.name=name;o.scale=scale;o.rotation_euler[1]=rotation
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bevel=o.modifiers.new('Rounded edges','BEVEL');bevel.width=.065;bevel.segments=4
    o.modifiers.new('Soft normals','WEIGHTED_NORMAL');o.data.materials.append(m)
    return o
book=[]
for side in (-1,1):
    book.append(cube('Cover', (side*.55,.20,-.54),(1.12,.14,1.48),edge,side*-.14))
    book.append(cube('Pages', (side*.54,.085,-.50),(1.00,.10,1.35),ivory,side*-.14))
book.append(cube('Bookmark',(.64,-.005,-1.08),(.15,.06,.5),blush))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
scene.render.film_transparent=True;scene.view_settings.view_transform='AgX'
scene.world.color=(.22,.22,.22)
bpy.ops.object.camera_add(location=(1.4,-7,2.1))
cam=bpy.context.object;cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.5;scene.camera=cam
for loc,energy,size in [((-3,-4,5),650,4),((3,-2,1),400,3),((0,3,3),900,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=energy;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()

def render(name):
    scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
    folder=ASSETS/(name+'.imageset');folder.mkdir(exist_ok=True)
    import shutil
    shutil.copy2(OUT/(name+'.png'),folder/(name+'.png'))
    (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':name+'.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2))

for o in book:o.hide_render=True
ring.hide_render=True;bead.hide_render=True
render('HeartHero')
ring.hide_render=False;bead.hide_render=False
render('ExploreHeart')
ring.hide_render=True;bead.hide_render=True
for o in book:o.hide_render=False
heart.scale=(.62,.62,.62);heart.location=(0,-.18,.42)
render('GuidedHeart')
for o in book:o.hide_render=True
heart.scale=(1,1,1);heart.location=(0,0,0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'HeartUI.blend'))
# Native visionOS icon: independently rendered depth layers.
import shutil
stack=ASSETS/'AppIcon.solidimagestack'
def icon_layer(layer,source):
    folder=stack/(layer+'.solidimagestacklayer')/'Content.imageset'
    shutil.copy2(source,folder/'Icon.png')
    (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'Icon.png','idiom':'vision','scale':'2x'}],'info':{'author':'xcode','version':1}},indent=2))
icon_layer('Front',OUT/'HeartHero.png')
heart.hide_render=True;ring.hide_render=False;bead.hide_render=False
scene.render.filepath=str(OUT/'AppOrbit.png');bpy.ops.render.render(write_still=True)
icon_layer('Middle',OUT/'AppOrbit.png')
ring.hide_render=True;bead.hide_render=True
scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.13,.015,.055,1)
scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=1
scene.render.film_transparent=False
scene.render.filepath=str(OUT/'AppBackground.png');bpy.ops.render.render(write_still=True)
icon_layer('Back',OUT/'AppBackground.png')
print('UI ICONS COMPLETE',flush=True)

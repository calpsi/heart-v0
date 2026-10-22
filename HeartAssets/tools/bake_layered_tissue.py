"""Bake continuous 3D tissue fields into one portable UV atlas per asset.
This avoids discontinuous patches at UV seams and texture stretching on cut walls.
"""
import bpy
from tissue_v3_materials import PALETTE

def bake(objects, kinds, asset, cut_faces):
    palette = {
        'muscle': ((.45,.135,.17),.40),
        'lining': ((.55,.285,.305),.31),
        'jelly': ((.64,.49,.40),.43),
        'muscle_cut': ((.56,.255,.26),.50),
        'lining_cut': ((.65,.40,.39),.43),
        'jelly_cut': ((.73,.60,.49),.51),
    }
    palette.update(endoderm=((.48,.30,.24),.62),endoderm_cut=((.48,.30,.24),.62))
    mats={}
    for kind in palette:
        color,rough=palette[kind];m=bpy.data.materials.new('Bake_'+kind);m.use_nodes=True
        n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
        tex=n.new('ShaderNodeTexCoord')
        # Object coordinates through a shared identity empty give coherent world-metre fields.
        anchor=bpy.data.objects.get('TissueCoordinates')
        if not anchor:
            anchor=bpy.data.objects.new('TissueCoordinates',None);bpy.context.collection.objects.link(anchor)
        tex.object=anchor
        def noise(scale,detail):
            a=n.new('ShaderNodeTexNoise');a.inputs['Scale'].default_value=scale;a.inputs['Detail'].default_value=detail;a.inputs['Roughness'].default_value=.7;l.new(tex.outputs['Object'],a.inputs['Vector']);return a
        broad=noise(62,3);fine=noise(540,3);micro=noise(2100,2)
        ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.12;ramp.color_ramp.elements[1].position=.88
        # Convert specified display sRGB colours to shader linear values.
        def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
        ramp.color_ramp.elements[0].color=tuple(linear(c*.74) for c in color)+(1,)
        ramp.color_ramp.elements[1].color=tuple(linear(min(c*1.18,1)) for c in color)+(1,)
        mix=n.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.inputs[0].default_value=.32;l.new(broad.outputs['Fac'],mix.inputs[1]);l.new(fine.outputs['Fac'],mix.inputs[2]);l.new(mix.outputs['Color'],ramp.inputs['Fac']);l.new(ramp.outputs['Color'],p.inputs['Base Color'])
        r=n.new('ShaderNodeMapRange');r.inputs['To Min'].default_value=rough-.065;r.inputs['To Max'].default_value=rough+.065;l.new(fine.outputs['Fac'],r.inputs['Value']);l.new(r.outputs['Result'],p.inputs['Roughness'])
        # Long, softly branching grain: stretched noise, not painted shadows.
        stretch=n.new('ShaderNodeVectorMath');stretch.operation='MULTIPLY'
        stretch.inputs[1].default_value=(1.0,1.0,.23 if kind.startswith('muscle') else .65)
        l.new(tex.outputs['Object'],stretch.inputs[0])
        l.new(stretch.outputs['Vector'],fine.inputs['Vector'])
        b=n.new('ShaderNodeBump');b.inputs['Strength'].default_value=.55;b.inputs['Distance'].default_value=.00006 if kind.startswith('endoderm') else (.0005 if kind.endswith('_cut') else .00035);l.new(fine.outputs['Fac'],b.inputs['Height'])
        b2=n.new('ShaderNodeBump');b2.inputs['Strength'].default_value=.35;b2.inputs['Distance'].default_value=.00009;l.new(micro.outputs['Fac'],b2.inputs['Height']);l.new(b.outputs['Normal'],b2.inputs['Normal']);l.new(b2.outputs['Normal'],p.inputs['Normal'])
        mats[kind]=m
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:
        o.hide_set(False);o.hide_render=False;o.select_set(True);o.data.materials.clear()
        o.data.materials.append(mats[kinds[o.name]])
        o.data.materials.append(mats[kinds[o.name]+'_cut'])
        for poly in o.data.polygons: poly.material_index = int(poly.index in cut_faces[o.name] if isinstance(cut_faces[o.name], set) else poly.index >= cut_faces[o.name])
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.2,island_margin=.008);bpy.ops.object.mode_set(mode='OBJECT')
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
    scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True;scene.render.bake.margin=12
    images={}
    for suffix,typ in [('Color','DIFFUSE'),('Roughness','ROUGHNESS'),('Normal','NORMAL')]:
        img=bpy.data.images.new(asset+'_'+suffix,2048,2048,alpha=False)
        if suffix!='Color':img.colorspace_settings.name='Non-Color'
        for m in mats.values():
            for node in m.node_tree.nodes:node.select=False
            node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=img;node.select=True;m.node_tree.nodes.active=node
        bpy.ops.object.bake(type=typ);img.pack();images[suffix]=img
    portable=bpy.data.materials.new('LayeredTissue_Baked');portable.use_nodes=True
    n=portable.node_tree.nodes;l=portable.node_tree.links;p=n.get('Principled BSDF')
    for suffix,img in images.items():
        t=n.new('ShaderNodeTexImage');t.image=img
        if suffix=='Normal':
            normal=n.new('ShaderNodeNormalMap');l.new(t.outputs['Color'],normal.inputs['Color']);l.new(normal.outputs['Normal'],p.inputs['Normal'])
        else:l.new(t.outputs['Color'],p.inputs['Base Color' if suffix=='Color' else suffix])
    for o in objects:o.data.materials.clear();o.data.materials.append(portable)
    bpy.data.objects.remove(anchor,do_unlink=True)
    return images

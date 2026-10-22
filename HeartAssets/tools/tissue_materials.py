"""Portable image-based tissue materials shared by refined assets."""
import bpy, numpy as np
from math import pi

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


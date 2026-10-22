"""Original neutral studio HDR environment for tissue shading in RealityKit."""
import bpy,numpy as np
from pathlib import Path
B=Path(__file__).resolve().parents[2]
n=1024;y,x=np.mgrid[:n//2,:n];theta=(x+.5)/n*2*np.pi-np.pi;phi=np.pi/2-(y+.5)/(n//2)*np.pi
v=np.stack([np.sin(theta)*np.cos(phi),np.sin(phi),np.cos(theta)*np.cos(phi)],axis=-1)
rgb=np.ones((n//2,n,4),np.float32);rgb[:,:,:3]=.24
for direction,energy,width in [((-.55,.65,.8),6,.065),((.8,.1,.7),1.4,.13),((-.4,.4,-.9),3,.055)]:
 d=np.array(direction);d=d/np.linalg.norm(d);power=energy*np.exp((np.sum(v*d,axis=-1)-1)/width)
 rgb[:,:,:3]+=power[:,:,None]
img=bpy.data.images.new('HeartTissueStudio',n,n//2,float_buffer=True);img.pixels.foreach_set(rgb.ravel());img.file_format='OPEN_EXR'
folder=B/'heart v3/Resources/HeartTissueStudio.skybox';folder.mkdir(parents=True,exist_ok=True)
img.filepath_raw=str(folder/'HeartTissueStudio.exr');img.save()
print('STUDIO ENVIRONMENT SAVED',img.filepath_raw)

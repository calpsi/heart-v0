from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
B=Path(__file__).resolve().parents[1]
F='/System/Library/Fonts/Supplemental/Arial.ttf';FB='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(s,b=False):return ImageFont.truetype(FB if b else F,s)
files=sorted((B/'previews').glob('*_Anterior.png'));assert len(files)==4
labels=[('Around week 4','Looped heart · common outflow'),('Weeks 5–6','Chamber expansion · outlet remodeling'),('Around week 7','Separate aortic and pulmonary outflows'),('Around week 8','Fetal heart exterior · major vessels')]
im=Image.new('RGB',(2400,2750),(31,33,39));d=ImageDraw.Draw(im)
d.text((85,58),'Whole embryonic heart',font=font(74,True),fill=(243,234,224));d.text((90,156),'Complete exterior models  /  four developmental stages',font=font(32),fill=(181,188,204))
for i,(p,(age,desc)) in enumerate(zip(files,labels)):
 x=70+(i%2)*1170;y=252+(i//2)*1180
 d.rounded_rectangle((x,y,x+1120,y+1130),radius=25,fill=(43,46,54),outline=(67,71,81),width=2)
 d.text((x+40,y+30),age,font=font(38,True),fill=(243,234,224))
 a=Image.open(p).convert('RGBA');a.thumbnail((1030,940),Image.Resampling.LANCZOS);im.paste(a,(x+(1120-a.width)//2,y+95),a)
 d.text((x+40,y+1050),desc,font=font(27),fill=(195,199,210))
d.text((85,2650),'Approximate post-fertilization ages. Identification colors. Enlarged teaching models; not specimen reconstructions.',font=font(27),fill=(162,172,190))
im.save(B/'previews'/'WholeHeart_Overview.jpg',quality=95)
# Week-eight front and rear comparison.
im=Image.new('RGB',(2400,1700),(31,33,39));d=ImageDraw.Draw(im)
d.text((80,55),'Week 8 · complete exterior',font=font(64,True),fill=(243,234,224));d.text((85,140),'Textured 3D anatomy with hollow vessel stumps',font=font(30),fill=(181,188,204))
for i,view in enumerate(['Anterior','Posterior']):
 p=files[3] if i==0 else Path(str(files[3]).replace('_Anterior','_Posterior'));a=Image.open(p).convert('RGBA');a.thumbnail((1130,1330),Image.Resampling.LANCZOS);im.paste(a,(i*1170+(1170-a.width)//2+30,250),a);d.text((90+i*1170,212),view+' view',font=font(32,True),fill=(243,234,224))
d.text((85,1630),'Intact exterior • Separate anatomical parts • PBR textures • Complementary internal cutaways are in partitioning-v1',font=font(26),fill=(162,172,190))
im.save(B/'previews'/'Week08_FrontAndBack.jpg',quality=95)

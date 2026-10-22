from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
B=Path(__file__).resolve().parents[1]
FONT='/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(s,b=False):return ImageFont.truetype(BOLD if b else FONT,s)
W,H=2400,2830
im=Image.new('RGB',(W,H),(25,28,35));d=ImageDraw.Draw(im)
d.text((100,72),'Partitioning the heart',font=font(74,True),fill=(246,237,227))
d.text((104,171),'Four developmental snapshots  /  anterior cutaway',font=font(32),fill=(184,191,203))
labels=[('01','Around week 4','Septation begins',['Primum descends from the atrial roof.','A muscular ridge rises between the ventricles.']),('02','Weeks 5–6','Cushions meet',['The AV cushion complex divides the inlet.','An upper opening develops in septum primum.']),('03','Around week 7','Ventricular closure',['The superior ventricular gap closes.','Overlapping atrial septa retain a fetal passage.']),('04','Around week 8','Four-chamber arrangement',['Tricuspid and mitral valves continue developing.','The foramen ovale remains open before birth.'])]
files=sorted((B/'previews').glob('HeartPartition_*.png'))
assert len(files)==4
for idx,(file,lab) in enumerate(zip(files,labels)):
 col=idx%2;row=idx//2;x=90+col*1160;y=270+row*1190
 d.rounded_rectangle((x,y,x+1120,y+1145),radius=28,fill=(35,39,48),outline=(61,65,76),width=2)
 n,age,title,lines=lab
 d.text((x+42,y+33),n,font=font(28,True),fill=(225,154,142));d.text((x+100,y+27),age,font=font(36,True),fill=(246,237,227))
 a=Image.open(file).convert('RGBA');a.thumbnail((890,850),Image.Resampling.LANCZOS)
 im.paste(a,(x+(1120-a.width)//2,y+103),a)
 d.text((x+42,y+952),title,font=font(35,True),fill=(246,237,227))
 for j,line in enumerate(lines):d.text((x+42,y+1010+j*42),line,font=font(26),fill=(197,202,212))
d.text((100,2687),'Ages are approximate and measured after fertilization. Developmental processes overlap.',font=font(27),fill=(177,184,197))
d.text((100,2732),'Original teaching models • Enlarged anatomy • Vessels omitted • Not a specimen reconstruction',font=font(26),fill=(144,153,170))
im.save(B/'previews'/'Partitioning_Overview.jpg',quality=94)
# Labeled endpoint, keeping leaders outside the anatomy whenever possible.
canvas=Image.new('RGB',(2000,1700),(25,28,35));d=ImageDraw.Draw(canvas)
d.text((70,55),'Week 8 · chamber partitioning',font=font(58,True),fill=(246,237,227))
d.text((74,132),'Anatomical right is on the image left. Fetal atrial communication is retained.',font=font(26),fill=(184,191,203))
a=Image.open(files[3]).convert('RGBA');a.thumbnail((1150,1320),Image.Resampling.LANCZOS);ox=(2000-a.width)//2;oy=230;canvas.paste(a,(ox,oy),a)
def callout(text,px,py,tx,ty,right=False):
 pt=(ox+int(px/1400*a.width),oy+int(py/1600*a.height));end=(tx,ty+18);elbow=(1470 if right else 480,ty+18)
 d.line([pt,elbow,end],fill=(210,172,156),width=2);d.ellipse((pt[0]-5,pt[1]-5,pt[0]+5,pt[1]+5),fill=(246,215,183));d.text((tx+10 if right else tx,ty-19),text,font=font(27),fill=(246,237,227))
callout('Right atrium',480,435,65,480)
callout('Tricuspid valve',520,780,65,785)
callout('Right ventricle',440,1160,65,1120)
callout('Foramen ovale / flap',655,490,1500,405,True)
callout('Left atrium',930,420,1500,590,True)
callout('Mitral valve',870,770,1500,810,True)
callout('Left ventricle',925,1160,1500,1130,True)
d.text((74,1590),'Leaflets and supporting structures are simplified developing primordia.',font=font(26),fill=(184,191,203))
canvas.save(B/'previews'/'Week08_Labeled.jpg',quality=94)
canvas=Image.new('RGB',(2000,1700),(25,28,35));d=ImageDraw.Draw(canvas)
d.text((70,55),'Around week 4 · septation begins',font=font(58,True),fill=(246,237,227))
d.text((74,132),'The partitions are growing, with open communication above and below the cushions.',font=font(26),fill=(184,191,203))
a=Image.open(files[0]).convert('RGBA');a.thumbnail((1150,1320),Image.Resampling.LANCZOS);ox=(2000-a.width)//2;oy=230;canvas.paste(a,(ox,oy),a)
callout('Common atrial space',480,435,65,470)
callout('Dorsal AV cushion',635,650,65,770)
callout('Developing ventricle',440,1160,65,1130)
callout('Septum primum',726,440,1500,380,True)
callout('Ostium primum',732,600,1500,610,True)
callout('Ventral AV cushion',715,710,1500,850,True)
callout('Muscular ventricular septum',715,1160,1500,1140,True)
d.text((74,1590),'The common AV passage lies between the cushions; the ventricular opening is above the muscular ridge.',font=font(25),fill=(184,191,203))
canvas.save(B/'previews'/'Week04_Labeled.jpg',quality=94)

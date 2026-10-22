from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
base=Path(__file__).resolve().parents[1];project=base.parent;folder=base/'refinements/surface-v5'
catalog=json.loads((project/'heart v3/Resources/HeartModels.json').read_text());size=280;label=48
out=Image.new('RGB',(size*4,(size+label)*4),(30,26,31));draw=ImageDraw.Draw(out)
font=ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc',13)
for i,item in enumerate(catalog):
 name=item['id'];im=Image.open(folder/name/(name+'_assembled.png')).convert('RGBA');im.thumbnail((size,size))
 x=(i%4)*size;y=(i//4)*(size+label);out.paste(im,(x+(size-im.width)//2,y),im)
 title=item['lesson'];words=title.split();lines=['']
 for word in words:
  trial=(lines[-1]+' '+word).strip()
  if draw.textlength(trial,font=font)>size-24:lines.append(word)
  else:lines[-1]=trial
 for j,line in enumerate(lines[:2]):draw.text((x+12,y+size+4+j*16),line,font=font,fill=(245,223,231))
out.save(folder/'all-installed-assets.jpg',quality=90)

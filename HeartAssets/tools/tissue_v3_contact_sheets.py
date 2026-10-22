"""Build before/after contact sheets from actual Blender renders (no retouching)."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
B=Path(__file__).resolve().parents[1];R=B/'refinements/tissue-v3'
font=ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc',22)
completed=json.loads((R/'progress.json').read_text())['stages']
for batch in range(4):
    canvas=Image.new('RGB',(1200,4*470),(24,23,29));draw=ImageDraw.Draw(canvas)
    for row,number in enumerate(range(batch*4+1,batch*4+5)):
        if str(number) not in completed:continue
        name=completed[str(number)]['asset']
        for col,path in enumerate([R/'before'/name/(name+'_assembled.png'),B/'previews'/(name+'_assembled.png')]):
            im=Image.open(path).convert('RGBA');im.thumbnail((560,420))
            canvas.paste(im,(col*600+(600-im.width)//2,row*470+40),im)
            draw.text((col*600+20,row*470+12),f'{number:02}  '+('Before' if col==0 else 'Tissue revision'),font=font,fill=(245,223,230))
    canvas.save(R/f'comparison-{batch+1:02}.jpg',quality=92)

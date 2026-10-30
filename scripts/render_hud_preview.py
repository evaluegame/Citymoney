#!/usr/bin/env python3
"""Composite the exported client GUI onto its matching geometry render for review.

This is an offline layout preview, not a Roblox screenshot or engine playtest.
"""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parents[1]
layout=json.loads((root / sys.argv[1]).read_text())
canvas=Image.open(root / sys.argv[2]).convert("RGBA")
assert canvas.size==(layout["width"],layout["height"])
regular="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
bold="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

for item in layout["elements"]:
    x,y,w,h=(round(item[k]) for k in ("x","y","w","h"))
    if w<1 or h<1:
        continue
    layer=Image.new("RGBA",canvas.size)
    draw=ImageDraw.Draw(layer)
    radius=min(round(item["corner"]),min(w,h)//2)
    if item["alpha"]>0:
        draw.rounded_rectangle((x,y,x+w,y+h),radius=radius,fill="#"+item["bg"]+f'{round(item["alpha"]*255):02x}')
    if item["stroke"]:
        stroke=item["stroke"]
        draw.rounded_rectangle((x,y,x+w,y+h),radius=radius,outline="#"+stroke["color"]+f'{round(stroke["alpha"]*255):02x}',width=max(1,round(stroke["width"])))
    if item["text"]:
        font=ImageFont.truetype(bold if "Bold" in item["font"] or "Black" in item["font"] else regular,max(8,round(item["size"])))
        lines=[]
        for paragraph in item["text"].splitlines():
            if item["wrap"]:
                line=""
                for word in paragraph.split():
                    candidate=(line+" "+word).strip()
                    if line and draw.textlength(candidate,font=font)>w-4:
                        lines.append(line);line=word
                    else:
                        line=candidate
                lines.append(line)
            else:
                while len(paragraph)>1 and draw.textlength(paragraph,font=font)>w-3:
                    paragraph=paragraph[:-2]+"…"
                lines.append(paragraph)
        line_height=font.size+2
        lines=lines[:max(1,h//line_height)]
        top=y+(h-len(lines)*line_height)/2
        for i,line in enumerate(lines):
            tx=x if item["align"]=="Left" else x+(w-draw.textlength(line,font=font))/2
            draw.text((tx,top+i*line_height),line,font=font,fill="#"+item["fg"])
    canvas=Image.alpha_composite(canvas,layer)

label=Image.new("RGBA",canvas.size)
draw=ImageDraw.Draw(label)
font=ImageFont.truetype(regular,11)
draw.text((canvas.width-440,canvas.height-17),"LAYOUT PREVIEW · Client UI + scene geometry · Not a Studio screenshot",font=font,fill=(35,65,100,220))
canvas=Image.alpha_composite(canvas,label).convert("RGB")
destination=root/sys.argv[3]
destination.parent.mkdir(parents=True,exist_ok=True)
canvas.save(destination)
print("Layout preview:",destination)

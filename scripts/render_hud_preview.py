#!/usr/bin/env python3
"""Composite the exported client GUI onto its matching geometry render for review.

This is an offline layout preview, not a Roblox screenshot or engine playtest.
"""
from pathlib import Path
import json
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFont
from preview_fonts import ensure_fonts

root=Path(__file__).resolve().parents[1]
layout=json.loads((root / sys.argv[1]).read_text())
canvas=Image.open(root / sys.argv[2]).convert("RGBA")
assert canvas.size==(layout["width"],layout["height"])
regular="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
bold="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
thai_regular,thai_bold=ensure_fonts()

for item in layout["elements"]:
    x,y,w,h=(round(item[k]) for k in ("x","y","w","h"))
    if w<1 or h<1:
        continue
    layer=Image.new("RGBA",canvas.size)
    draw=ImageDraw.Draw(layer)
    radius=min(round(item["corner"]),min(w,h)//2)
    if item["alpha"]>0:
        draw.rounded_rectangle((x,y,x+w,y+h),radius=radius,fill="#"+item["bg"]+f'{round(item["alpha"]*255):02x}')
    if item["class"]=="ViewportFrame" and len(sys.argv)>4:
        preview=Image.open(root/sys.argv[4]).convert("RGBA").resize((w,h),Image.Resampling.LANCZOS)
        mask=Image.new("L",(w,h));ImageDraw.Draw(mask).rounded_rectangle((0,0,w,h),radius=radius,fill=255)
        layer.paste(preview,(x,y),mask)
    if item["stroke"]:
        stroke=item["stroke"]
        draw.rounded_rectangle((x,y,x+w,y+h),radius=radius,outline="#"+stroke["color"]+f'{round(stroke["alpha"]*255):02x}',width=max(1,round(stroke["width"])))
    if item["text"] and item.get("textAlpha",1)>0:
        thai=any('\u0e00'<=char<='\u0e7f' for char in item["text"])
        font_path=(thai_bold if "Bold" in item["font"] or "Black" in item["font"] else thai_regular) if thai else (bold if "Bold" in item["font"] or "Black" in item["font"] else regular)
        font=ImageFont.truetype(font_path,max(1,int(item["size"]) if item["name"].startswith("DeedLabel") else round(item["size"])))
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
                while len(paragraph)>1 and draw.textlength(paragraph,font=font)>w-2:
                    paragraph=paragraph[:-2]+"…"
                lines.append(paragraph)
        line_height=font.size*(1.25 if thai else 1.1) if item["name"].startswith("DeedLabel") else font.size*(1.3 if thai else 1)+2
        lines=lines[:max(1,int(h//line_height))]
        top=y+(h-len(lines)*line_height)/2
        for i,line in enumerate(lines):
            tx=x if item["align"]=="Left" else x+(w-draw.textlength(line,font=font))/2
            draw.text((tx,top+i*line_height),line,font=font,fill="#"+item["fg"]+f'{round(item.get("textAlpha",1)*255):02x}')
    if item.get("rotation"):
        layer=layer.rotate(-item["rotation"],resample=Image.Resampling.BICUBIC,center=(x+w/2,y+h/2))
    if item.get("clip"):
        clip=item["clip"]
        left,top=round(clip["x"]),round(clip["y"])
        right,bottom=round(clip["x"]+clip["w"]),round(clip["y"]+clip["h"])
        if right<=left or bottom<=top:
            continue
        mask=Image.new("L",canvas.size)
        ImageDraw.Draw(mask).rectangle((left,top,right-1,bottom-1),fill=255)
        layer.putalpha(ImageChops.multiply(layer.getchannel("A"),mask))
    canvas=Image.alpha_composite(canvas,layer)

label=Image.new("RGBA",canvas.size)
draw=ImageDraw.Draw(label)
font=ImageFont.truetype(regular,11)
caption="LAYOUT PREVIEW · Not a Studio screenshot" if canvas.width<800 else "LAYOUT PREVIEW · Client UI + scene geometry · Not a Studio screenshot"
if len(sys.argv)>5:
    caption=sys.argv[5]
draw.text((max(8,canvas.width-8-draw.textlength(caption,font=font)),canvas.height-17),caption,font=font,fill=(35,65,100,220))
canvas=Image.alpha_composite(canvas,label).convert("RGB")
destination=root/sys.argv[3]
destination.parent.mkdir(parents=True,exist_ok=True)
canvas.save(destination)
print("Layout preview:",destination)

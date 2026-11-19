from PIL import Image, ImageOps
import glob,os
os.makedirs('out',exist_ok=True)
for f in sorted(glob.glob('img/ex*.png')):
    im=Image.open(f).convert('RGB'); w,h=im.size
    im=im.crop((0,0,w,h-90)); w,h=im.size           # drop the hint bar
    g=ImageOps.invert(im.convert('L')).point(lambda v:255 if v>120 else 0)  # dark ink only (skip grid dots)
    bb=g.getbbox(); pad=50
    c=im.crop((max(bb[0]-pad,0),max(bb[1]-pad,0),min(bb[2]+pad,w),min(bb[3]+pad,h)))
    # whiten the dotted background
    px=c.load()
    bgc=Image.new('RGB',c.size,(255,255,255))
    mask=c.convert('L').point(lambda v:255 if v<190 else (int((215-v)*10) if v<215 else 0))
    bgc.paste(c,mask=mask)
    if bgc.width>1400: bgc=bgc.resize((1400,int(bgc.height*1400/bgc.width)),Image.LANCZOS)
    bgc.save('out/'+os.path.basename(f),optimize=True)
print('ok')

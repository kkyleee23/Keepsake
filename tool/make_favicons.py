# Makes the web favicons and home-screen icons.
#   python3 tool/make_favicons.py   (run from the project root; needs Pillow)
# Tabs get the leaf seal (readable at 16 px); home screens get the mascot icon.
import math, sys
from PIL import Image, ImageDraw
OUT='web'
ACCENT=(46,107,79); PAPER=(241,241,235)

def seal_points(cx,cy,r,n=14,amp=0.05,steps=560):
    pts=[]
    for i in range(steps):
        t=i/steps*2*math.pi
        rr=r*(1+amp*math.sin(t*n))
        pts.append((cx+math.cos(t)*rr, cy+math.sin(t)*rr))
    return pts

def quad(p0,p1,p2,n=60):
    return [((1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t*t*p2[0], (1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t*t*p2[1]) for t in [i/n for i in range(n+1)]]

def leaf_points(x,y,w,h):
    P=lambda a,b:(x+a*w,y+b*h)
    a,b=P(0.08,0.92),P(0.95,0.06)
    return quad(a,P(-0.02,0.22),b)+quad(b,P(1.02,0.80),a)

def seal(size, ss=8, pad=0.04, rim=True):
    S=size*ss; im=Image.new('RGBA',(S,S),(0,0,0,0)); d=ImageDraw.Draw(im)
    r=S*(0.5-pad)/1.05
    d.polygon(seal_points(S/2,S/2,r,amp=0.05 if size>16 else 0.02),fill=ACCENT+(255,))
    if rim and size>=48:
        w=max(1,int(r*0.05))
        d.ellipse([S/2-r*0.76,S/2-r*0.76,S/2+r*0.76,S/2+r*0.76],outline=(255,255,255,70),width=w)
    lw=r*(1.3 if size<=16 else 1.05)  # bigger leaf where pixels are scarce
    d.polygon(leaf_points(S/2-lw/2,S/2-lw/2,lw,lw),fill=(255,255,255,245))
    # midrib, only where it can be seen
    if size>=32:
        d.line([(S/2-lw*0.34,S/2+lw*0.34),(S/2+lw*0.2,S/2-lw*0.2)],fill=ACCENT+(150,),width=max(1,int(lw*0.05)))
    return im.resize((size,size),Image.LANCZOS)

# Tab favicons: the seal.
seal(32).save(f'{OUT}/favicon.png')
ico=[seal(s) for s in (16,32,48)]
ico[2].save(f'{OUT}/favicon.ico',sizes=[(16,16),(32,32),(48,48)],append_images=ico[:2])

# SVG version of the seal for crisp tabs on modern browsers.
pts=seal_points(32,32,30/1.05*1.0)
path='M'+' L'.join(f'{x:.2f},{y:.2f}' for x,y in pts[::4])+' Z'
r=30/1.05; lw=r*1.05; x0=32-lw/2; y0=32-lw/2
P=lambda a,b:(x0+a*lw,y0+b*lw)
a,b=P(0.08,0.92),P(0.95,0.06); c1=P(-0.02,0.22); c2=P(1.02,0.80)
leaf=f'M{a[0]:.2f},{a[1]:.2f} Q{c1[0]:.2f},{c1[1]:.2f} {b[0]:.2f},{b[1]:.2f} Q{c2[0]:.2f},{c2[1]:.2f} {a[0]:.2f},{a[1]:.2f} Z'
svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <title>Keepsake</title>
  <path d="{path}" fill="#2E6B4F"/>
  <circle cx="32" cy="32" r="{r*0.76:.2f}" fill="none" stroke="#FFFFFF" stroke-opacity="0.28" stroke-width="{r*0.06:.2f}"/>
  <path d="{leaf}" fill="#FFFFFF"/>
  <line x1="{32-lw*0.34:.2f}" y1="{32+lw*0.34:.2f}" x2="{32+lw*0.2:.2f}" y2="{32-lw*0.2:.2f}" stroke="#2E6B4F" stroke-opacity="0.6" stroke-width="{lw*0.05:.2f}" stroke-linecap="round"/>
</svg>
'''
open(f'{OUT}/favicon.svg','w').write(svg)

# Home-screen icons: the mascot app icon.
icon=Image.open('assets/brand/icon_1024.png').convert('RGBA')
for s in (192,512):
    icon.resize((s,s),Image.LANCZOS).save(f'{OUT}/icons/Icon-{s}.png',optimize=True)
icon.convert('RGB').resize((180,180),Image.LANCZOS).save(f'{OUT}/icons/apple-touch-icon.png',optimize=True)
# Maskable: the mascot inside the 80% safe zone on brand green, so any mask
# shape (circle, squircle) keeps the whole face. Same sage as the launcher
# icon so they always match.
fg=Image.open('assets/brand/icon_foreground.png').convert('RGBA')
bb=fg.getbbox(); fg=fg.crop(bb)
for s in (192,512):
    bg=Image.new('RGBA',(s,s),icon.getpixel((4,4))[:3]+(255,))
    m=fg.copy(); m.thumbnail((int(s*0.62),int(s*0.62)),Image.LANCZOS)
    bg.paste(m,((s-m.width)//2,(s-m.height)//2+int(s*0.02)),m)
    bg.save(f'{OUT}/icons/Icon-maskable-{s}.png',optimize=True)
print('ok')

"""Die-cut mascot stickers for the envelope.

Takes the mascot poses in assets/brand/states/, adds a smooth white border
and a faint edge (like a vinyl sticker), and writes 256 px PNGs to
assets/stickers/. Run: python3 tool/make_stickers.py
"""
from PIL import Image, ImageFilter, ImageChops

POSES = {
    'pup_wave': 'waving',
    'pup_hug': 'hugging',
    'pup_cheer': 'celebrating',
    'pup_gift': 'gift',
    'pup_read': 'reading',
    'pup_sleep': 'sleepy',
}
OUT = 256
BORDER = 11      # white border, in output pixels
EDGE = 1.6       # faint outer edge


def grow(alpha, px):
    """Round dilation: blur the mask and keep everything a little lit."""
    a = alpha.filter(ImageFilter.GaussianBlur(px / 2))
    return a.point(lambda v: 255 if v > 6 else int(v * 255 / 6))


def smooth(alpha):
    """Soft, even edge."""
    a = alpha.filter(ImageFilter.GaussianBlur(1.2))
    return a.point(lambda v: max(0, min(255, (v - 96) * 3)))


for name, pose in POSES.items():
    src = Image.open(f'assets/brand/states/{pose}.png').convert('RGBA')
    src = src.crop(src.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox())
    inner = OUT - 2 * (BORDER * 2 + 8)  # room for the whole border
    k = inner / max(src.size)
    src = src.resize((max(1, round(src.width * k)), max(1, round(src.height * k))), Image.LANCZOS)
    canvas = Image.new('RGBA', (OUT, OUT), (0, 0, 0, 0))
    canvas.alpha_composite(src, ((OUT - src.width) // 2, (OUT - src.height) // 2))

    a = canvas.getchannel('A').point(lambda v: 255 if v > 40 else 0)
    cut = smooth(grow(a, BORDER * 2))
    edge = smooth(grow(cut, EDGE * 2))

    out = Image.new('RGBA', (OUT, OUT), (0, 0, 0, 0))
    out.paste((214, 205, 186, 255), mask=edge)       # faint paper edge
    out.paste((255, 255, 253, 255), mask=cut)        # white die-cut
    out.alpha_composite(canvas)
    out.save(f'assets/stickers/{name}.png', optimize=True)
    print('wrote', name)

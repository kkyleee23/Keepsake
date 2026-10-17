# Makes the seamless paper textures in assets/textures/.
#   python3 tool/make_paper_textures.py   (run from the project root;
#   needs numpy, scipy and Pillow)
#
# Each paper is built the way real paper looks up close:
#   1. formation: soft low-frequency cloudiness from uneven pulp
#   2. tooth: fine high-frequency grain
#   3. fibers: thin curved strands, some darker, some lighter
#   4. relief: the layers are treated as a height map and lit from the top
#      left, so the surface reads as embossed, not as a flat colour
# Noise is made in the frequency domain, so it wraps around and the tiles
# repeat seamlessly; fibers are drawn with wrap-around for the same reason.
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

N = 768
OUT = 'assets/textures'
os.makedirs(OUT, exist_ok=True)


def periodic_noise(rng, beta, lo=0.0, hi=1.0):
    """Seamless noise with a 1/f^beta spectrum between lo..hi (fractions of Nyquist)."""
    white = rng.standard_normal((N, N))
    f = np.fft.fftfreq(N)
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt(fx ** 2 + fy ** 2) / 0.5
    filt = np.where((r > lo) & (r <= hi), 1.0 / np.maximum(r, 1e-3) ** beta, 0.0)
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * filt))
    out -= out.mean()
    return out / (out.std() + 1e-9)


def fibers(rng, count, length, width, wavy=0.35, ss=2):
    """Height-ish layer of thin curved strands, values in -1..1, seamless."""
    S = N * ss
    img = Image.new('F', (S, S), 0.0)
    d = ImageDraw.Draw(img)
    for _ in range(count):
        x0, y0 = rng.uniform(0, S), rng.uniform(0, S)
        ang = rng.uniform(0, math.pi)
        L = rng.uniform(*length) * ss
        bend = rng.uniform(-wavy, wavy)
        val = rng.choice([-1.0, 1.0]) * rng.uniform(0.4, 1.0)
        w = max(1, int(round(rng.uniform(*width) * ss)))
        pts = []
        for i in range(12):
            t = i / 11
            a = ang + bend * (t - 0.5) * 2
            pts.append((x0 + math.cos(a) * L * t, y0 + math.sin(a) * L * t))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                d.line([(x + ox, y + oy) for x, y in pts], fill=val, width=w)
    arr = np.asarray(img.resize((N, N), Image.BILINEAR))
    return np.clip(arr, -1, 1)


def flecks(rng, count, size, colors, ss=2):
    """Small irregular inclusions (seed-paper petals, kraft specks). RGBA, seamless."""
    S = N * ss
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(count):
        cx, cy = rng.uniform(0, S), rng.uniform(0, S)
        r = rng.uniform(*size) * ss
        col = tuple(int(round(c * 255)) for c in colors[rng.integers(len(colors))])
        pts = []
        k = rng.integers(5, 9)
        for i in range(k):
            a = i / k * 2 * math.pi
            rr = r * rng.uniform(0.45, 1.0)
            pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * rng.uniform(0.4, 1.0)))
        for ox in (-S, 0, S):
            for oy in (-S, 0, S):
                d.polygon([(x + ox, y + oy) for x, y in pts], fill=col)
    img = img.filter(ImageFilter.GaussianBlur(0.6 * ss))
    return np.asarray(img.resize((N, N), Image.LANCZOS)).astype(np.float32) / 255


def tint_fibers(rgb, arr, dark, lightc, amt):
    """Paint fibers in their own colour: negative values dark, positive light."""
    d = np.clip(-arr, 0, 1)[..., None] * amt
    l = np.clip(arr, 0, 1)[..., None] * amt
    rgb = rgb * (1 - d) + np.array(dark) * d
    return rgb * (1 - l) + np.array(lightc) * l


def light(height, strength):
    """Lambert-ish shading from a height map, light from the top left."""
    gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) / 2
    gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) / 2
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    n = np.sqrt(nx ** 2 + ny ** 2 + nz ** 2)
    lx, ly, lz = -0.55, -0.55, 0.63
    return (nx * lx + ny * ly + nz * lz) / n / lz - 1.0  # 0 on flat ground


def compose(base, layers, relief, shade_amt, seed_flecks=None, fiber_tint=None):
    """base: RGB 0..1. layers: list of (array, brightness_amount, height_amount)."""
    rgb = np.ones((N, N, 3)) * np.array(base)
    height = np.zeros((N, N))
    bright = np.zeros((N, N))
    for arr, b_amt, h_amt in layers:
        bright += arr * b_amt
        height += arr * h_amt
    rgb = rgb * (1 + bright[..., None])
    if fiber_tint is not None:
        arr, col, amt = fiber_tint
        m = np.clip(np.abs(arr), 0, 1)[..., None] * amt
        rgb = rgb * (1 - m) + np.array(col) * m
    shade = light(height, relief)
    rgb = rgb * (1 + shade[..., None] * shade_amt)
    # Keep the paper's colour honest: shading adds texture, not a grey cast.
    rgb = rgb * (np.array(base) / rgb.reshape(-1, 3).mean(0))
    if seed_flecks is not None:
        a = seed_flecks[..., 3:4]
        rgb = rgb * (1 - a) + seed_flecks[..., :3] * a
    return np.clip(rgb, 0, 1)


def save(name, rgb):
    Image.fromarray((rgb * 255).astype(np.uint8)).save(
        f'{OUT}/{name}.jpg', quality=88, optimize=True, progressive=True)
    print(name, os.path.getsize(f'{OUT}/{name}.jpg') // 1024, 'KB')


def hexc(h):
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


rng = np.random.default_rng(7)

def soft_tooth():
    # Paper grain: fine, but not pixel-sharp (that reads as stucco).
    return periodic_noise(rng, 0.6, 0.08, 0.55)

# Cream letter paper: cotton-rich, quiet formation, soft tooth, faint fibers.
formation = periodic_noise(rng, 1.6, 0.004, 0.08)
tooth = soft_tooth()
fib = fibers(rng, 1100, (8, 30), (0.6, 1.0), 0.5)
save('paper_cream', compose(hexc('#FBF7EE'),
     [(formation, 0.010, 0.3), (tooth, 0.006, 0.45), (fib, 0.018, 0.35)], 0.9, 0.18))

# Kraft: unbleached; what makes it read as kraft is the streaky fibers.
formation = periodic_noise(rng, 1.8, 0.003, 0.06)
tooth = soft_tooth()
fib = fibers(rng, 2400, (20, 90), (0.8, 1.6), 0.25)
fib2 = fibers(rng, 1800, (6, 24), (0.6, 1.0), 0.6)
specks = flecks(rng, 200, (0.5, 1.3), [(0.34, 0.22, 0.12, 0.85), (0.48, 0.34, 0.2, 0.7)])
kraft = compose(hexc('#C49B6C'),
                [(formation, 0.03, 0.25), (tooth, 0.008, 0.25), (fib, 0.0, 0.5)],
                0.9, 0.22, seed_flecks=specks)
kraft = tint_fibers(kraft, fib, hexc('#8D6740'), hexc('#DCC09A'), 0.42)
kraft = tint_fibers(kraft, fib2, hexc('#A07A50'), hexc('#D6B78E'), 0.28)
kraft = np.clip(kraft * (np.array(hexc('#C49B6C')) / kraft.reshape(-1, 3).mean(0)), 0, 1)
save('paper_kraft', kraft)

# Sage seed paper: soft green card with tiny petals and seeds pressed in.
formation = periodic_noise(rng, 1.7, 0.004, 0.08)
tooth = soft_tooth()
fib = fibers(rng, 1500, (8, 34), (0.6, 1.1), 0.6)
petals = flecks(rng, 60, (3.6, 7.5), [
    (0.70, 0.40, 0.35, 0.75),   # terracotta petal
    (0.84, 0.62, 0.55, 0.7),    # blush petal
    (0.42, 0.52, 0.38, 0.75),   # leaf green
    (0.99, 0.97, 0.92, 0.9),    # cream fleck
    (0.55, 0.44, 0.30, 0.7),    # seed
])
save('paper_sage', compose(hexc('#E1E6D3'),
     [(formation, 0.016, 0.3), (tooth, 0.008, 0.45), (fib, 0.03, 0.4)], 1.0, 0.22,
     seed_flecks=petals))

# Linen: a fine, even woven stationery finish.
yy, xx = np.mgrid[0:N, 0:N]
period = N / 192  # threads per tile; wraps exactly
slub_x = periodic_noise(rng, 1.4, 0.005, 0.12)
slub_y = periodic_noise(rng, 1.4, 0.005, 0.12)
warp = np.sin(2 * np.pi * xx / period + slub_x * 0.25) * (0.85 + 0.15 * slub_y)
weft = np.sin(2 * np.pi * yy / period + slub_y * 0.25) * (0.85 + 0.15 * slub_x)
weave = (np.maximum(warp, weft) + 0.5 * (warp * weft)) / 1.5
tooth = soft_tooth()
formation = periodic_noise(rng, 1.6, 0.004, 0.08)
save('paper_linen', compose(hexc('#F5EFE3'),
     [(weave, 0.022, 0.5), (formation, 0.010, 0.2), (tooth, 0.004, 0.25)], 1.0, 0.3))

# Book cloth: the same weave, deeper, to be tinted for the cover.
save('cloth', compose(hexc('#EEEAE2'),
     [(weave, 0.05, 0.9), (formation, 0.025, 0.3), (tooth, 0.01, 0.4)], 1.4, 0.45))

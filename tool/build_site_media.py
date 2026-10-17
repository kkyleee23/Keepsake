"""Turns the raw site renders into web-ready images, the opening clip and
the site's fonts.

Run after:  flutter test test/site/site_shots_test.dart --dart-define=SITE=true
Then:       python3 tool/build_site_media.py

Writes website/img/*.webp, website/media/opening.mp4 (+ poster), and
website/fonts/*.woff2 (only the characters the site uses).
"""
import glob
import os
import subprocess

from PIL import Image

RAW = 'build/site_raw'
SITE = 'website'

os.makedirs(f'{SITE}/img', exist_ok=True)
os.makedirs(f'{SITE}/media', exist_ok=True)
os.makedirs(f'{SITE}/fonts', exist_ok=True)

# Screens: 780 px wide is sharp at the size the page shows them (2x).
for path in sorted(glob.glob(f'{RAW}/*.png')):
    name = os.path.splitext(os.path.basename(path))[0]
    im = Image.open(path).convert('RGB')
    w = 780
    im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    im.save(f'{SITE}/img/{name}.webp', 'WEBP', quality=82, method=6)
    print('img', name, im.size)

# The opening clip: H.264 so it plays on every phone, small, starts fast.
frames = sorted(glob.glob(f'{RAW}/clip/f*.png'))
if frames:
    first = Image.open(frames[0]).convert('RGB')
    first.save(f'{SITE}/media/opening-poster.webp', 'WEBP', quality=80)
    subprocess.run([
        'ffmpeg', '-y', '-loglevel', 'error',
        '-framerate', '30', '-i', f'{RAW}/clip/f%04d.png',
        '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '27',
        '-preset', 'slow', '-movflags', '+faststart', '-an',
        f'{SITE}/media/opening.mp4',
    ], check=True)
    # VP9 WebM too: some browsers (open-source Chromium, some Linux builds)
    # can't play H.264. The page offers WebM first, MP4 as the fallback.
    subprocess.run([
        'ffmpeg', '-y', '-loglevel', 'error',
        '-framerate', '30', '-i', f'{RAW}/clip/f%04d.png',
        '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2',
        '-c:v', 'libvpx-vp9', '-pix_fmt', 'yuv420p', '-b:v', '0', '-crf', '36',
        '-row-mt', '1', '-deadline', 'good', '-an',
        f'{SITE}/media/opening.webm',
    ], check=True)
    print('clip', len(frames), 'frames')

# Fonts: Montserrat, subset to Latin so pages load quickly; self-hosted so no
# request goes to a font company.
from fontTools import subset  # noqa: E402

LATIN = ('U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,'
         'U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD')
for weight in ['regular', 'semibold', 'bold']:
    src = f'fonts/montserrat/montserrat_{weight}.ttf'
    out = f'{SITE}/fonts/montserrat-{weight}.woff2'
    subset.main([src, f'--unicodes={LATIN}', '--flavor=woff2',
                 '--layout-features=kern,liga,calt,tnum',
                 f'--output-file={out}'])
    print('font', out, os.path.getsize(out))
# The app's handwriting, only for the live tag demo (it shows what the app does).
subset.main(['fonts/caveat/caveat_variable.ttf', f'--unicodes={LATIN}',
             '--flavor=woff2', f'--output-file={SITE}/fonts/caveat.woff2'])
print('font caveat', os.path.getsize(f'{SITE}/fonts/caveat.woff2'))

"""Render the splash V as Android launcher icons. Requires Pillow.

Run from the repository root: python scripts/generate_android_icons.py
The source geometry and colors match assets/images/vertx_mark.svg.
"""
from pathlib import Path
from math import hypot
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
CHARCOAL = '#242423'
IVORY = '#F0E9E1'
POINTS = ((32, 32), (54, 75), (76, 32))
WIDTH = 2.8


def stroke_polygon():
    """Square caps and miter join, matching the splash's straight-stroke V."""
    a, b, c = POINTS
    length = hypot(b[0] - a[0], b[1] - a[1])
    dx, dy = (b[0] - a[0]) / length, (b[1] - a[1]) / length
    half = WIDTH / 2
    left = (a[0] - dx * half, a[1] - dy * half)
    right = (c[0] + dx * half, c[1] - dy * half)
    nx, ny = dy * half, dx * half
    return [(left[0] - nx, left[1] + ny),
            (b[0], b[1] + half / dx),
            (right[0] + nx, right[1] + ny),
            (right[0] - nx, right[1] - ny),
            (b[0], b[1] - half / dx),
            (left[0] + nx, left[1] - ny)]


def render(size, background, color=IVORY):
    scale = size * 4 / 108
    image = Image.new('RGBA', (size * 4, size * 4), background)
    ImageDraw.Draw(image).polygon(
        [(x * scale, y * scale) for x, y in stroke_polygon()], fill=color)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


if __name__ == '__main__':
    save(render(1024, CHARCOAL), ROOT / 'assets/images/app_icon.png')
    save(render(1024, (0, 0, 0, 0)), ROOT / 'assets/images/app_icon_foreground.png')
    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        folder = RES / f'mipmap-{density}'
        save(render(size, CHARCOAL), folder / 'ic_launcher.png')
        adaptive_size = size * 108 // 48
        save(Image.new('RGB', (adaptive_size, adaptive_size), CHARCOAL),
             folder / 'ic_launcher_background.png')
        save(render(adaptive_size, (0, 0, 0, 0)), folder / 'ic_launcher_foreground.png')
        save(render(adaptive_size, (0, 0, 0, 0), '#FFFFFF'),
             folder / 'ic_launcher_monochrome.png')
    print('Generated Android legacy, adaptive, and monochrome V icons.')

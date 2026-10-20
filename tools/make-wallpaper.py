#!/usr/bin/env python3
"""Generate themes/<name>/wallpaper.png: an original, procedural night-street scene (pure stdlib).
Sky gradient + stars, two skyline layers with lit windows, a warm street lamp and a wet road.
Tinted by each theme's colors.sh. Deterministic (seeded). Run on a PC: python3 tools/make-wallpaper.py
To use your own picture instead, set OMP_WALLPAPER=/path/to/image in ~/.config/omarchy-pad/env.
"""
import math, pathlib, random, re, struct, zlib

W, H = 1920, 1200
ROOT = pathlib.Path(__file__).resolve().parent.parent


def parse(path):
    vals = dict(re.findall(r'^([A-Z0-9_]+)="(#[0-9a-fA-F]{6})"', path.read_text(), re.M))
    return {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in vals.items()}


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def png(path, buf):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(buf[y * W * 3:(y + 1) * W * 3]) for y in range(H))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def put(buf, x, y, col, a=1.0):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 3
        for k in range(3):
            buf[i + k] = max(0, min(255, int(buf[i + k] + (col[k] - buf[i + k]) * a)))


def rect(buf, x0, y0, x1, y1, col, a=1.0):
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            put(buf, x, y, col, a)


def glow(buf, cx, cy, radius, col, strength, squash=1.0):
    for y in range(max(0, int(cy - radius)), min(H, int(cy + radius))):
        for x in range(max(0, int(cx - radius)), min(W, int(cx + radius))):
            d = math.hypot(x - cx, (y - cy) * squash) / radius
            if d < 1:
                put(buf, x, y, col, strength * (1 - d) ** 2)


def render(c):
    rnd = random.Random(7)
    top = mix(c["MANTLE"], (6, 10, 28), 0.75)
    horizon = mix(c["BG"], (36, 52, 96), 0.55)
    buf = bytearray(W * H * 3)
    horizon_y = int(H * 0.62)
    for y in range(H):
        t = min(1.0, y / horizon_y)
        col = mix(top, horizon, t ** 1.5)
        row = bytes(int(v) for v in col) * W
        buf[y * W * 3:(y + 1) * W * 3] = row
    # stars
    for _ in range(260):
        x, y = rnd.randrange(W), rnd.randrange(int(H * 0.5))
        put(buf, x, y, (235, 240, 255), rnd.uniform(0.25, 0.9))
    # skyline: far layer then near layer
    for layer, (base, hmin, hmax, tone, lit) in enumerate([
        (horizon_y, 90, 330, mix(horizon, (10, 14, 30), 0.55), 0.10),
        (horizon_y + 40, 160, 460, mix(top, (4, 6, 14), 0.6), 0.22),
    ]):
        x = -20
        while x < W:
            w = rnd.randrange(70, 190)
            h = rnd.randrange(hmin, hmax)
            rect(buf, x, base - h, x + w, base + 200, tone)
            for wy in range(base - h + 18, base - 10, 26):
                for wx in range(x + 12, x + w - 14, 22):
                    if rnd.random() < lit:
                        warm = rnd.choice([(255, 206, 120), (255, 186, 96), (255, 226, 160)])
                        rect(buf, wx, wy, wx + 8, wy + 12, warm, rnd.uniform(0.55, 0.95))
            x += w + rnd.randrange(-10, 14)
    # road with soft reflection
    road_top = horizon_y + 80
    for y in range(road_top, H):
        t = (y - road_top) / (H - road_top)
        col = mix(mix(top, (8, 10, 22), 0.5), (4, 5, 12), t)
        rect(buf, 0, y, W, y + 1, col)
    # street lamp (warm) with light cone and wet-road reflection
    lx = int(W * 0.30)
    rect(buf, lx - 4, int(H * 0.18), lx + 4, road_top + 40, (12, 14, 24))
    rect(buf, lx - 4, int(H * 0.18), lx + 70, int(H * 0.18) + 8, (12, 14, 24))
    lamp = (lx + 66, int(H * 0.18) + 14)
    glow(buf, lamp[0], lamp[1], 360, (255, 176, 80), 0.62)
    glow(buf, lamp[0], lamp[1], 70, (255, 232, 170), 0.9)
    glow(buf, lamp[0], road_top + 150, 330, (255, 160, 70), 0.30, squash=2.4)
    # distant cool glow near the horizon
    glow(buf, int(W * 0.72), horizon_y - 40, 420, c["BLUE"], 0.20, squash=1.6)
    glow(buf, int(W * 0.15), int(H * 0.1), 380, c["MAUVE"], 0.10)
    return buf


for d in sorted((ROOT / "themes").iterdir()):
    f = d / "colors.sh"
    if f.exists():
        png(d / "wallpaper.png", render(parse(f)))
        print("wrote", d / "wallpaper.png")

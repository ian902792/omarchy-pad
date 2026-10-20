#!/usr/bin/env python3
"""Generate themes/<name>/wallpaper.png from each theme's colors.sh (pure stdlib).
Dark vertical gradient (BG -> MANTLE) with two soft glows (MAUVE top-right, BLUE bottom-left).
Run on a PC: python3 tools/make-wallpaper.py
"""
import math, pathlib, re, struct, zlib

W, H = 1920, 1200
ROOT = pathlib.Path(__file__).resolve().parent.parent


def parse(path):
    vals = dict(re.findall(r'^([A-Z0-9_]+)="(#[0-9a-fA-F]{6})"', path.read_text(), re.M))
    return {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in vals.items()}


def png(path, rows):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + r for r in rows)
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def render(c):
    bg, mantle, mauve, blue = c["BG"], c["MANTLE"], c["MAUVE"], c["BLUE"]
    glows = [((0.85, 0.15), 0.55, mauve, 0.22), ((0.12, 0.90), 0.60, blue, 0.18)]
    rows = []
    for y in range(H):
        t = y / (H - 1)
        base = [bg[i] + (mantle[i] - bg[i]) * t for i in range(3)]
        row = bytearray()
        for x in range(W):
            px = list(base)
            for (cx, cy), radius, col, strength in glows:
                d = math.hypot((x / W - cx) * (W / H), y / H - cy) / radius
                if d < 1.0:
                    a = strength * (1 - d) ** 2
                    for i in range(3):
                        px[i] += (col[i] - px[i]) * a
            row += bytes(int(max(0, min(255, v))) for v in px)
        rows.append(bytes(row))
    return rows


for d in sorted((ROOT / "themes").iterdir()):
    f = d / "colors.sh"
    if f.exists():
        png(d / "wallpaper.png", render(parse(f)))
        print("wrote", d / "wallpaper.png")

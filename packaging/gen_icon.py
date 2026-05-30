#!/usr/bin/env python3
"""Generate icon.png (a simple fan) using only the standard library.

Rendered at 2x and box-downsampled for light anti-aliasing. Produces a 256x256
RGBA PNG: a blue rounded square with six white fan blades and a hub.
"""
import math
import os
import struct
import zlib

# Write into the repo's data/ directory regardless of the current directory.
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "icon.png")
SIZE = 256
SS = 2                      # supersampling factor
S = SIZE * SS               # working resolution


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


BG_TOP = (59, 130, 246)     # #3b82f6
BG_BOT = (30, 64, 175)      # #1e40af
WHITE = (255, 255, 255)


def render():
    cx = cy = (S - 1) / 2.0
    corner = 0.1875 * S            # radius 48 at 256 scale
    # Blade ellipse (local frame): centred above the hub, pointing outward.
    bcx, bcy = 0.085 * S, -0.21 * S   # sideways lean -> blades look like a spinning fan
    brx, bry = 0.10 * S, 0.20 * S
    hub_r = 0.118 * S
    hub_inner = 0.055 * S
    angles = [math.radians(k * 60) for k in range(6)]

    px = bytearray(S * S * 4)
    for y in range(S):
        for x in range(S):
            # rounded-square mask (corners only)
            ddx = max(corner - x, x - (S - 1 - corner), 0.0)
            ddy = max(corner - y, y - (S - 1 - corner), 0.0)
            inside_bg = (ddx * ddx + ddy * ddy) <= corner * corner

            i = (y * S + x) * 4
            if not inside_bg:
                px[i + 3] = 0          # transparent outside the rounded square
                continue

            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)

            color = lerp(BG_TOP, BG_BOT, y / (S - 1))   # background gradient

            # hub
            if r <= hub_r:
                color = WHITE if r > hub_inner else lerp(BG_TOP, BG_BOT, y / (S - 1))
            else:
                # six rotated blades
                for a in angles:
                    ca, sa = math.cos(a), math.sin(a)
                    xb = dx * ca + dy * sa
                    yb = -dx * sa + dy * ca
                    ex = (xb - bcx) / brx
                    ey = (yb - bcy) / bry
                    if ex * ex + ey * ey <= 1.0:
                        color = WHITE
                        break

            px[i] = color[0]
            px[i + 1] = color[1]
            px[i + 2] = color[2]
            px[i + 3] = 255
    return px


def downsample(src):
    out = bytearray(SIZE * SIZE * 4)
    for y in range(SIZE):
        for x in range(SIZE):
            acc = [0, 0, 0, 0]
            for sy in range(SS):
                for sx in range(SS):
                    si = ((y * SS + sy) * S + (x * SS + sx)) * 4
                    for c in range(4):
                        acc[c] += src[si + c]
            di = (y * SIZE + x) * 4
            for c in range(4):
                out[di + c] = acc[c] // (SS * SS)
    return out


def write_png(path, w, h, rgba):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(h):
        raw.append(0)                          # filter type 0
        raw += rgba[y * w * 4:(y + 1) * w * 4]
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)   # 8-bit RGBA
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    write_png(OUT, SIZE, SIZE, downsample(render()))
    print("wrote", OUT)

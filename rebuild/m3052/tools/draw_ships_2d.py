#!/usr/bin/env python3
"""Paint Abyssal Dominion's original ship sprites directly in 2D.

No 3D models: each heading is drawn with 2D shapes (curved hull outline,
hull side band, deck, castles, sails, rigging, flag) using gradients,
plank lines and an outline, then packed into the game's sprite atlas
layout (4 headings NE, NW, SW, SE x 2 rows: furled sails, full sails).

usage: python3 tools/draw_ships_2d.py [--preview OUT.png] [--only N]
"""
import argparse, json, math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/original/ships'
SS = 3                     # paint at 3x, then downsample for clean edges
SQUASH = 0.58              # vertical squash of the chart plane (2.5D oblique look)
HEADINGS = {'NE': 45, 'NW': 135, 'SW': 225, 'SE': 315}


def rgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


DESIGNS = [
    dict(name='Glutkiel', size=(2048, 1024), length=1.0, beam=0.27, masts=[(0.30, 1.0, 3), (-0.02, 1.12, 3), (-0.30, 0.82, 2)], rig='square', hull='#5a3520', band='#b8432c', sail='#efe3c6', trim='#e0b75a', flag='#c43a2a', castle=0.20, fore=0.12, guns=6),
    dict(name='Seegrasbrigg', size=(1024, 512), length=0.9, beam=0.27, masts=[(0.22, 0.95, 3), (-0.12, 1.02, 3)], rig='square', hull='#3d4630', band='#5f8a4a', sail='#e3e8d2', trim='#c9b77a', flag='#3f8f5a', castle=0.16, fore=0.1, guns=5),
    dict(name='Kupferschwalbe', size=(1024, 512), length=0.82, beam=0.25, masts=[(0.08, 1.0, 1)], rig='lateen', hull='#6a4126', band='#c27a3c', sail='#f4ddb0', trim='#e0a860', flag='#c27a3c', castle=0.10, fore=0.0, guns=3),
    dict(name='Brandungsläufer', size=(1024, 512), length=0.95, beam=0.27, masts=[(0.28, 0.95, 3), (-0.04, 1.05, 3), (-0.30, 0.78, 2)], rig='square', hull='#4a3626', band='#2e5f9a', sail='#f3eee2', trim='#d2b06a', flag='#2e5f9a', castle=0.18, fore=0.1, guns=6),
    dict(name='Sonnenthron', size=(2048, 1024), length=1.05, beam=0.30, masts=[(0.30, 1.0, 3), (-0.02, 1.16, 4), (-0.30, 0.86, 3)], rig='square', hull='#5a3b18', band='#e0b43c', sail='#f7e8b8', trim='#f2cf63', flag='#e0b43c', castle=0.26, fore=0.14, guns=7),
    dict(name='Frostwacht', size=(2048, 1024), length=1.0, beam=0.27, masts=[(0.30, 1.0, 3), (-0.02, 1.12, 3), (-0.30, 0.82, 2)], rig='square', hull='#2f4152', band='#9fd2ee', sail='#eef7fc', trim='#cfe9f7', flag='#6fb7e0', castle=0.20, fore=0.12, guns=6),
    dict(name='Mitternachtsfalke', size=(2048, 1024), length=1.0, beam=0.26, masts=[(0.26, 1.02, 3), (-0.12, 1.1, 3)], rig='square', hull='#24212c', band='#7a56a0', sail='#4a4258', trim='#b9a3d8', flag='#9a6ad0', castle=0.18, fore=0.1, guns=6),
    dict(name='Hafenwächter', size=(2048, 1024), length=1.05, beam=0.29, masts=[(0.30, 1.0, 3), (-0.02, 1.12, 3), (-0.30, 0.84, 2)], rig='square', hull='#26364d', band='#e2ddcd', sail='#f5f1e6', trim='#e2c47a', flag='#2c5aa0', castle=0.24, fore=0.13, guns=7),
    dict(name='Tiefseekrone', size=(2048, 1024), length=1.08, beam=0.30, masts=[(0.31, 1.02, 3), (-0.01, 1.18, 4), (-0.30, 0.86, 3)], rig='square', hull='#173034', band='#2fb5a8', sail='#d4ece7', trim='#7fe0d2', flag='#2fb5a8', castle=0.26, fore=0.14, guns=8),
    dict(name='Gebeinsegler', size=(1024, 512), length=0.92, beam=0.26, masts=[(0.22, 0.98, 3), (-0.12, 1.04, 3)], rig='square', hull='#cfc4a8', band='#6d6352', sail='#9a917e', trim='#efe6cf', flag='#3a3328', castle=0.16, fore=0.1, guns=5),
    dict(name='Aschenläufer', size=(1024, 512), length=0.95, beam=0.26, masts=[(0.28, 0.98, 3), (-0.04, 1.05, 3), (-0.30, 0.78, 2)], rig='square', hull='#2e211a', band='#ff7a2a', sail='#6a4636', trim='#ffb070', flag='#ff7a2a', castle=0.18, fore=0.1, guns=6),
    dict(name='Rabenschwinge', size=(2048, 1024), length=1.02, beam=0.28, masts=[(0.30, 1.0, 3), (-0.02, 1.12, 3), (-0.30, 0.82, 2)], rig='square', hull='#1d1c21', band='#a3342c', sail='#36353c', trim='#d8d2c4', flag='#d8d2c4', castle=0.22, fore=0.12, guns=7),
    dict(name='Perlmuttgaleone', size=(2048, 1024), length=1.08, beam=0.31, masts=[(0.31, 1.0, 3), (-0.01, 1.16, 4), (-0.30, 0.86, 3)], rig='square', hull='#e6dfd2', band='#5a8fb0', sail='#fcf8ee', trim='#c9a85a', flag='#5a8fb0', castle=0.28, fore=0.14, guns=8),
    dict(name='Eisenkeil', size=(1024, 512), length=0.9, beam=0.28, masts=[(0.18, 0.88, 2), (-0.16, 0.92, 2)], rig='square', hull='#3c3e43', band='#8a8f96', sail='#cfccc2', trim='#b0b4ba', flag='#7a1f1f', castle=0.14, fore=0.1, guns=6),
    dict(name='Nebelschmuggler', size=(1024, 512), length=0.78, beam=0.23, masts=[(0.04, 0.95, 1)], rig='gaff', hull='#43392c', band='#7c6a4c', sail='#c2bba9', trim='#a99878', flag='#4a4a4a', castle=0.08, fore=0.0, guns=2),
    dict(name='Geisterflut', size=(2048, 1024), length=1.0, beam=0.27, masts=[(0.30, 1.0, 3), (-0.02, 1.12, 3), (-0.30, 0.82, 2)], rig='square', hull='#28403f', band='#7fbfa8', sail='#b6e0d2', trim='#a8f0dc', flag='#5fd0b0', castle=0.2, fore=0.12, guns=6),
]


class Painter:
    """2D chart-plane painter: plan coords (x forward, y starboard) -> screen."""

    def __init__(self, size, heading_deg, scale, origin):
        self.W, self.H = size
        a = math.radians(heading_deg)
        self.fwd = np.array([math.cos(a), -math.sin(a) * SQUASH])        # bow direction on screen
        self.stb = np.array([math.sin(a), math.cos(a) * SQUASH])         # starboard direction on screen
        self.s, self.o = scale, np.array(origin)
        self.img = Image.new('RGBA', size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        # which hull side faces the viewer (positive screen-y = toward the viewer)
        self.near = 1 if self.stb[1] > 0 else -1

    def p(self, x, y, up=0.0):
        v = self.o + self.s * (x * self.fwd + y * self.stb)
        return (float(v[0]), float(v[1] - up * self.s))

    def poly(self, pts, fill, outline=None, width=0):
        self.d.polygon(pts, fill=fill, outline=outline, width=width)

    def gradient_poly(self, pts, top, bottom, axis=None):
        """Fill a polygon with a vertical (or given axis) gradient."""
        mask = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(mask).polygon(pts, fill=255)
        bbox = mask.getbbox()
        if not bbox: return
        x0, y0, x1, y1 = bbox
        h = max(1, y1 - y0)
        grad = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        t = np.linspace(0, 1, y1 - y0)[:, None]
        for i in range(3):
            grad[..., i] = (top[i] + (bottom[i] - top[i]) * t).astype(np.uint8)
        grad[..., 3] = 255
        layer = Image.fromarray(grad, 'RGBA')
        self.img.paste(layer, (x0, y0), mask.crop(bbox))

    def line(self, a, b, fill, width):
        self.d.line([a, b], fill=fill, width=max(1, int(width)))


def half_beam(t, B):
    """Plan half-beam along the keel; t=0 stern, t=1 bow."""
    if t < 0.5:
        return B * (0.70 + 0.30 * math.sin(math.pi / 2 * t / 0.5))
    return max(B * math.cos(math.pi / 2 * (t - 0.5) / 0.5) ** 0.75, 0.0)


def paint_ship(d, heading, size, scale, origin, furled):
    P = Painter(size, heading, scale, origin)
    L, B = d['length'], d['beam'] / 2
    hull, band, trim = rgb(d['hull']), rgb(d['band']), rgb(d['trim'])
    sail, flag = rgb(d['sail']), rgb(d['flag'])
    deck_col = (150, 112, 70) if sum(hull) < 500 else (176, 160, 130)
    ink = (26, 18, 12, 255)
    N = 40
    ts = [i / N for i in range(N + 1)]
    xs = [(t - 0.5) * L for t in ts]
    sheer = [0.10 + 0.06 * (1 - t) ** 2.2 + 0.03 * t ** 4 for t in ts]          # deck height (stern and bow rise)
    port = [P.p(x, -half_beam(t, B), sh) for x, t, sh in zip(xs, ts, sheer)]
    stbd = [P.p(x, half_beam(t, B), sh) for x, t, sh in zip(xs, ts, sheer)]
    wl_port = [P.p(x, -half_beam(t, B) * 0.92, 0.0) for x, t in zip(xs, ts)]
    wl_stbd = [P.p(x, half_beam(t, B) * 0.92, 0.0) for x, t in zip(xs, ts)]
    # --- hull side facing the viewer (rail line down to the waterline)
    rail = stbd if P.near > 0 else port
    water = wl_stbd if P.near > 0 else wl_port
    side = rail + water[::-1]
    P.gradient_poly(side, shade(hull, 1.15), shade(hull, 0.62))
    # stern transom: visible when the stern points toward the viewer
    stern_toward = P.fwd[1] < 0
    if stern_toward:
        tr = [port[0], stbd[0], wl_stbd[0], wl_port[0]]
        P.gradient_poly(tr, shade(hull, 1.0), shade(hull, 0.55))
        for k in range(3):  # stern windows
            u = (k + 1) / 4
            a = (port[0][0] + (stbd[0][0] - port[0][0]) * u, port[0][1] + (stbd[0][1] - port[0][1]) * u)
            r = 0.012 * scale
            P.d.ellipse([a[0] - r, a[1] + r * 0.6, a[0] + r, a[1] + r * 2.4], fill=(255, 214, 120, 255))
    # planking: curves parallel to the rail
    for f in (0.22, 0.42, 0.62, 0.8):
        pts = [(r[0] + (w[0] - r[0]) * f, r[1] + (w[1] - r[1]) * f) for r, w in zip(rail, water)]
        P.d.line(pts, fill=shade(hull, 0.55) + (255,), width=max(1, int(scale * 0.0035)))
    # painted band under the rail
    band_top = [(r[0] + (w[0] - r[0]) * 0.08, r[1] + (w[1] - r[1]) * 0.08) for r, w in zip(rail, water)]
    band_bot = [(r[0] + (w[0] - r[0]) * 0.20, r[1] + (w[1] - r[1]) * 0.20) for r, w in zip(rail, water)]
    P.gradient_poly(band_top + band_bot[::-1], shade(band, 1.15), shade(band, 0.8))
    # gun ports on the visible side
    for t in np.linspace(0.22, 0.78, d['guns']):
        i = int(t * N)
        r, w = rail[i], water[i]
        c = (r[0] + (w[0] - r[0]) * 0.4, r[1] + (w[1] - r[1]) * 0.4)
        s = scale * 0.016
        P.d.rectangle([c[0] - s, c[1] - s * 0.8, c[0] + s, c[1] + s * 0.8], fill=(22, 16, 12, 255), outline=shade(trim, 0.8) + (255,))
    # waterline shadow
    P.d.line(water, fill=(20, 26, 34, 200), width=max(2, int(scale * 0.01)))
    # --- deck
    deck = port + stbd[::-1]
    P.gradient_poly(deck, shade(deck_col, 1.12), shade(deck_col, 0.9))
    for k in range(-3, 4):  # deck planks along the keel
        y = k * B / 4.2
        pts = [P.p(x, y * (half_beam(t, B) / B), sh - 0.002) for x, t, sh in zip(xs, ts, sheer) if half_beam(t, B) > abs(y) * 0.9]
        if len(pts) > 1: P.d.line(pts, fill=shade(deck_col, 0.78) + (255,), width=max(1, int(scale * 0.0025)))
    # rail outline (both sides) and gilded trim on the near side
    P.d.line(port, fill=shade(hull, 0.5) + (255,), width=max(2, int(scale * 0.008)))
    P.d.line(stbd, fill=shade(hull, 0.5) + (255,), width=max(2, int(scale * 0.008)))
    P.d.line(rail, fill=trim + (255,), width=max(1, int(scale * 0.005)))
    # --- castles drawn as raised decks
    def castle(t0, t1, height, shrink):
        seg = [i for i, t in enumerate(ts) if t0 <= t <= t1]
        top_p = [P.p(xs[i], -half_beam(ts[i], B) * shrink, sheer[i] + height) for i in seg]
        top_s = [P.p(xs[i], half_beam(ts[i], B) * shrink, sheer[i] + height) for i in seg]
        base = [P.p(xs[i], (1 if P.near > 0 else -1) * half_beam(ts[i], B) * shrink, sheer[i]) for i in seg]
        near_top = top_s if P.near > 0 else top_p
        P.gradient_poly(near_top + base[::-1], shade(hull, 1.1), shade(hull, 0.75))
        end_i = seg[0] if P.fwd[1] < 0 else seg[-1]  # the castle face toward the viewer
        P.gradient_poly([top_p[seg.index(end_i)], top_s[seg.index(end_i)], P.p(xs[end_i], half_beam(ts[end_i], B) * shrink, sheer[end_i]), P.p(xs[end_i], -half_beam(ts[end_i], B) * shrink, sheer[end_i])], shade(hull, 1.0), shade(hull, 0.7))
        P.gradient_poly(top_p + top_s[::-1], shade(deck_col, 1.15), shade(deck_col, 0.95))
        P.d.line(top_p, fill=trim + (255,), width=max(1, int(scale * 0.005)))
        P.d.line(top_s, fill=trim + (255,), width=max(1, int(scale * 0.005)))
        for t in np.linspace(t0 + 0.02, t1 - 0.02, max(2, int((t1 - t0) / 0.05))):  # lit windows
            i = int(t * N); b = near_top[min(range(len(seg)), key=lambda j: abs(seg[j] - i))]
            r = scale * 0.008
            P.d.rectangle([b[0] - r, b[1] + r * 1.4, b[0] + r, b[1] + r * 3.0], fill=(255, 210, 120, 255))
    if d['castle'] > 0: castle(0.0, d['castle'], 0.07, 0.95)
    if d['fore'] > 0: castle(0.86, 0.86 + d['fore'] * 0.8, 0.04, 0.7)
    # --- bowsprit
    bow = P.p(0.5 * L, 0, sheer[-1] + 0.01)
    tip = P.p(0.5 * L + 0.2, 0, sheer[-1] + 0.09)
    P.line(bow, tip, (74, 52, 34, 255), scale * 0.012)
    # --- masts and sails, far masts first
    masts = sorted(d['masts'], key=lambda m: P.p(m[0] * L, 0)[1])
    wood = (78, 56, 36, 255)
    rope = (40, 30, 22, 170)
    for mx, mh, tiers in masts:
        x = mx * L
        t = mx + 0.5
        base_h = 0.10 + 0.06 * (1 - t) ** 2.2
        H = 0.62 * mh
        foot = P.p(x, 0, base_h)
        top = P.p(x, 0, base_h + H)
        # shrouds to both rails
        for side in (-1, 1):
            for k in (-0.04, 0.0, 0.04):
                P.line(P.p(x + k, side * half_beam(t, B), base_h), P.p(x, 0, base_h + H * 0.82), rope, scale * 0.003)
        P.line(foot, top, wood, scale * 0.016)
        if d['rig'] == 'square':
            for k in range(tiers):
                z1 = base_h + H * (0.93 - k * 0.29)
                z0 = z1 - H * 0.27
                w = (0.42 - 0.06 * k) * (d['beam'] / 0.27) ** 0.6
                ya, yb = P.p(x, -w / 2, z1), P.p(x, w / 2, z1)
                P.line(ya, yb, wood, scale * 0.01)
                if furled:
                    fa, fb = P.p(x, -w / 2.1, z1 - 0.012), P.p(x, w / 2.1, z1 - 0.012)
                    P.line(fa, fb, shade(sail, 0.9) + (255,), scale * 0.022)
                    continue
                belly = 0.07 if P.fwd[1] < 0 else 0.07   # cloth bulges toward the bow
                pts = []
                M = 14
                for j in range(M + 1):      # top edge (straight along the yard)
                    u = j / M; pts.append(P.p(x, (u - 0.5) * w, z1 - 0.005))
                for j in range(M + 1):      # leech down the starboard side, then the curved foot
                    v = j / M; pts.append(P.p(x + belly * math.sin(math.pi * v) * 0.6, w / 2 * (1 - 0.06 * v), z1 - v * (z1 - z0)))
                for j in range(M, -1, -1):
                    u = j / M; pts.append(P.p(x + belly * math.sin(math.pi * u), (u - 0.5) * w * 0.94, z0 + 0.025 * math.sin(math.pi * u)))
                for j in range(M, -1, -1):
                    v = j / M; pts.append(P.p(x + belly * math.sin(math.pi * v) * 0.6, -w / 2 * (1 - 0.06 * v), z1 - v * (z1 - z0)))
                lit = P.fwd[1] > 0          # we see the sunlit front of the sail when the bow points at us
                P.gradient_poly(pts, shade(sail, 1.05 if lit else 0.97), shade(sail, 0.82 if lit else 0.74))
                # cloth seams and a soft highlight in the belly
                for j in range(1, 5):
                    u = j / 5
                    P.d.line([P.p(x + 0.004, (u - 0.5) * w * 0.98, z1 - 0.01), P.p(x + belly * math.sin(math.pi * u), (u - 0.5) * w * 0.94, z0 + 0.03 * math.sin(math.pi * u))],
                             fill=shade(sail, 0.78) + (200,), width=max(1, int(scale * 0.0025)))
                P.d.line(pts, fill=shade(sail, 0.55) + (255,), width=max(1, int(scale * 0.004)))
        else:
            z_top, z_bot = base_h + H * 0.98, base_h + 0.06
            aft = 0.36 if d['rig'] == 'lateen' else 0.3
            if furled:
                P.line(P.p(x, 0, z_bot + 0.02), P.p(x - aft, 0, z_bot + 0.02), shade(sail, 0.9) + (255,), scale * 0.02)
            else:
                M = 16
                pts = [P.p(x + (0.1 if d['rig'] == 'lateen' else 0), 0, z_top)]
                for j in range(M + 1):
                    v = j / M
                    pts.append(P.p(x - aft * v + (0.1 * (1 - v) if d['rig'] == 'lateen' else 0), 0.05 * math.sin(math.pi * v), z_top - (z_top - z_bot) * (v ** 0.7 if d['rig'] == 'lateen' else 0.15 * v)))
                pts += [P.p(x - aft, 0, z_bot), P.p(x, 0, z_bot)]
                P.gradient_poly(pts, shade(sail, 1.05), shade(sail, 0.8))
                P.d.line(pts + [pts[0]], fill=shade(sail, 0.55) + (255,), width=max(1, int(scale * 0.004)))
            P.line(P.p(x, 0, z_bot), P.p(x - aft, 0, z_bot), wood, scale * 0.01)
        # pennant
        P.line(top, P.p(x, 0, base_h + H + 0.04), wood, scale * 0.008)
        fl = P.p(x, 0, base_h + H + 0.04)
        wave = [(fl[0] - k * scale * 0.012 * (1 if P.fwd[0] > 0 else -1), fl[1] + scale * 0.006 * math.sin(k * 1.3)) for k in range(9)]
        P.d.line(wave, fill=flag + (255,), width=max(2, int(scale * 0.014)))
    # jib from bowsprit to the foremast
    fx = max(m[0] for m in d['masts']) * L
    ft = 0.10 + 0.06 * (1 - (fx / L + 0.5)) ** 2.2
    if not furled and d['rig'] == 'square':
        jib = [tip, P.p(fx + 0.02, 0, ft + 0.62 * 0.8), P.p(fx + 0.1, 0, ft + 0.05)]
        P.gradient_poly(jib, shade(sail, 1.0), shade(sail, 0.78))
        P.d.line(jib + [jib[0]], fill=shade(sail, 0.55) + (255,), width=max(1, int(scale * 0.004)))
    P.line(tip, P.p(fx, 0, ft + 0.62 * 0.85), (40, 30, 22, 200), scale * 0.003)
    return P.img


def outline(img, color=(22, 16, 12)):
    a = np.asarray(img).astype(np.float32)
    al = a[..., 3]
    grown = Image.fromarray(al.astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    g = np.asarray(grown).astype(np.float32)
    ring = np.clip(g - al, 0, 255)
    out = a.copy()
    f = al[..., None] / 255
    out[..., :3] = a[..., :3] * f + np.array(color) * (1 - f)
    out[..., 3] = np.maximum(al, ring)
    return Image.fromarray(out.astype(np.uint8), 'RGBA')


def render(d):
    W, H = d['size']
    cw, ch = W // 4, H // 2
    scale = cw * 0.62 * SS
    sheet = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    for col, (name, hd) in enumerate(HEADINGS.items()):
        for row, furled in ((0, True), (1, False)):
            big = paint_ship(d, hd, (cw * SS, ch * SS), scale, (cw * SS / 2, ch * SS * 0.66), furled)
            bbox = big.getbbox()
            # keep every frame at the same magnification; only recentre horizontally
            dx = cw * SS / 2 - (bbox[0] + bbox[2]) / 2
            big = paint_ship(d, hd, (cw * SS, ch * SS), scale, (cw * SS / 2 + dx, ch * SS * 0.66), furled)
            small = big.resize((cw, ch), Image.LANCZOS)
            sheet.alpha_composite(outline(small), (col * cw, row * ch))
    return sheet


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--preview'); ap.add_argument('--only', type=int)
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    picks = [args.only] if args.only else range(1, len(DESIGNS) + 1)
    for i in picks:
        d = DESIGNS[i - 1]
        sheet = render(d)
        if args.preview:
            bg = Image.new('RGBA', sheet.size, (30, 72, 112, 255)); bg.alpha_composite(sheet)
            bg.convert('RGB').resize((1024, 512), Image.LANCZOS).save(args.preview); return
        sheet.save(OUT / f'ad_ship_{i:02d}.png', optimize=True)
        print(f'ad_ship_{i:02d}.png', d['name'])
    (OUT / 'catalog.json').write_text(json.dumps([{'file': f'ad_ship_{i:02d}', 'name': d['name']} for i, d in enumerate(DESIGNS, 1)], indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()

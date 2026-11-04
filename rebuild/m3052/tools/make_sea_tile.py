"""Builds the seamless royal-blue sea tile used by ocean.gdshader.

Every layer is band-limited periodic noise, so the 512 px tile repeats without seams.
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image

SIZE = 512
rng = np.random.default_rng(3059)
fy, fx = np.meshgrid(np.fft.fftfreq(SIZE), np.fft.fftfreq(SIZE), indexing='ij')
radius = np.sqrt(fx * fx + fy * fy)


def periodic(mask):
    field = np.real(np.fft.ifft2(np.fft.fft2(rng.normal(size=(SIZE, SIZE))) * mask))
    return (field - field.mean()) / field.std()


clouds = periodic(np.exp(-(radius / 0.006) ** 2))
swell = periodic(np.exp(-((np.sqrt((fx * 1.25) ** 2 + (fy * 0.8) ** 2) - 0.03) / 0.016) ** 2))
grain = periodic(np.exp(-((radius - 0.30) / 0.14) ** 2))
fleck = periodic(np.exp(-((radius - 0.12) / 0.06) ** 2))

base = np.array([9.0, 70.0, 133.0])
tone = 1.0 + 0.075 * clouds[..., None] * np.array([0.6, 0.9, 1.0]) + 0.03 * swell[..., None]
color = base * tone + 6.5 * grain[..., None] + 2.5 * fleck[..., None] * np.array([0.5, 0.8, 1.0])
sparkle = np.clip(fleck * 0.5 + grain, 0, None) ** 3
sparkle = np.where(rng.random((SIZE, SIZE)) < 0.05, sparkle, 0.0)
color += sparkle[..., None] * np.array([7.0, 11.0, 14.0])
Image.fromarray(np.clip(color, 0, 255).astype(np.uint8), 'RGB').save(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'assets/ui/painted/sea_tile.png', optimize=True)

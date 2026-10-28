"""Reproducible, tileable surface finish for the live morphs.

Uses the restrained multiscale variation of the earlier V0 tissue authoring
script, without copying a baked atlas onto unrelated geometry. This is visual
surface grain, not a histology map or additional anatomical structure.
"""
import math
from pathlib import Path
import struct
import zlib

SIZE = 256
DESTINATION = Path(__file__).resolve().parents[2] / "heart v3/Resources"


def png(path, pixels):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    scanlines = b"".join(b"\x00" + bytes(pixels[y * SIZE * 3:(y + 1) * SIZE * 3]) for y in range(SIZE))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(scanlines, 9)) + chunk(b"IEND", b""))


grain, roughness = [], []
for y in range(SIZE):
    for x in range(SIZE):
        u, v = x / SIZE, y / SIZE
        # Integer frequencies tile exactly; phase and scale are deterministic.
        field = sum(weight * math.sin(2 * math.pi * (a * u + b * v) + phase)
                    for a, b, weight, phase in [(3, 2, .44, .7), (7, -5, .27, 1.9),
                                               (19, 13, .18, 2.3), (43, -31, .11, .4)])
        grain.extend([round(255 * (.94 + .06 * field))] * 3)
        # Stored in linear space; multiply by the common 0.48 roughness.
        roughness.extend([round(255 * (.90 + .10 * field))] * 3)
png(DESTINATION / "MorphTissueGrain.png", grain)
png(DESTINATION / "MorphTissueRoughness.png", roughness)
print("Generated two 256×256 seamless morph finish maps.")

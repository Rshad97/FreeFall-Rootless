#!/usr/bin/env python3
"""Original FreeFall descending chirp with a two-note landing. No sampled audio."""
import math
from pathlib import Path
import struct
import wave

out = Path(__file__).resolve().parents[1] / 'layout/Library/FreeFallRootless/RashadDrop.wav'
out.parent.mkdir(parents=True, exist_ok=True)
rate = 48000
samples = []
phase = 0.0
for i in range(int(1.45 * rate)):
    t = i / rate
    if t < 0.95:
        frequency = 1450 * (190 / 1450) ** (t / 0.95)
        envelope = min(1, t / 0.015) * min(1, (0.95 - t) / 0.04)
    else:
        u = t - 0.95
        frequency = 660 if u < 0.22 else 440
        v = u if u < 0.22 else u - 0.22
        envelope = min(1, v / 0.008) * math.exp(-12 * v) * min(1, (1.45 - t) / 0.03)
    phase += 2 * math.pi * frequency / rate
    value = 0.65 * envelope * (math.sin(phase) + 0.20 * math.sin(2 * phase)) / 1.2
    samples.append(struct.pack('<h', round(32767 * value)))
with wave.open(str(out), 'wb') as wav:
    wav.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    wav.writeframes(b''.join(samples))
print(out)

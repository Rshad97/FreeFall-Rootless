#!/usr/bin/env python3
"""Reject incomplete or iOS-incompatible audio packages before publishing."""
from pathlib import Path
import hashlib
import plistlib
import wave

root = Path(__file__).resolve().parents[1]
prefs = plistlib.loads((root / 'freefallprefs/Resources/Root.plist').read_bytes())
picker = next(i for i in prefs['items'] if i.get('key') == 'selectedSound')
assert len(picker['validValues']) == len(picker['validTitles']) == 8
assert picker['default'] == 'FreeFallScream'
hashes = set()
for name in picker['validValues']:
    if name == 'Custom':
        continue  # User-imported at runtime, never a packaged placeholder.
    path = root / 'layout/Library/FreeFallRootless' / (name + '.wav')
    with wave.open(str(path), 'rb') as audio:
        assert (audio.getnchannels(), audio.getsampwidth(), audio.getframerate()) == (1, 2, 48000), name
        duration = audio.getnframes() / audio.getframerate()
        assert 0 < duration <= 30, name
        frames = audio.readframes(audio.getnframes())
        assert any(frames), name
        hashes.add(hashlib.sha256(frames).hexdigest())
        print(f'{name}: PCM mono 48kHz 16-bit, {duration:.2f}s')
assert len(hashes) == 7, 'Duplicate audio'
print('PASS: all seven distinct selectable sounds are packaged and compatible.')

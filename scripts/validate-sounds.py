#!/usr/bin/env python3
"""Reject incomplete or iOS-incompatible audio packages before publishing."""
from pathlib import Path
import hashlib
import plistlib
import wave

root = Path(__file__).resolve().parents[1]
prefs = plistlib.loads((root / 'freefallprefs/Resources/Root.plist').read_bytes())
picker = next(i for i in prefs['items'] if i.get('key') == 'selectedSound')
assert len(picker['validValues']) == len(picker['validTitles']) == 9
assert picker['default'] == 'FreeFallScream'
impact = next(i for i in prefs['items'] if i.get('key') == 'impactSound')
assert impact['validValues'] == picker['validValues']
assert impact['validTitles'] == picker['validTitles']
import re
names = re.findall(r'@"([^"]+)"', (root / 'FFShared.h').read_text().split('return @[')[1].split('];')[0])
assert names == picker['validValues'], 'Runtime and picker sounds differ'
assert any(i.get('key') == 'include_Chicken' for i in prefs['items'])
assert hashlib.sha256((root / 'layout/Library/FreeFallRootless/Chicken.wav').read_bytes()).hexdigest() == 'ac047c21147e9327bd08183994630fdc211e483d53b1275ca6cdb6276b882934', 'Recorded chicken asset changed'
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
assert len(hashes) == 8, 'Duplicate audio'
print('PASS: all eight distinct selectable sounds are packaged and compatible.')

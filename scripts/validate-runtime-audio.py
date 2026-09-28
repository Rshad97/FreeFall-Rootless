#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
tweak = (root / 'Tweak.xm').read_text()
makefile = (root / 'Makefile').read_text()
prefs = (root / 'freefallprefs/FFRRootListController.m').read_text()

assert '#import <AudioToolbox/AudioToolbox.h>' in tweak
assert 'AudioServicesCreateSystemSoundID' in tweak
assert 'AudioServicesPlaySystemSound' in tweak
assert 'AudioServicesDisposeSystemSoundID' in tweak
assert 'AVAudioPlayer' not in tweak
assert '#import <AVFoundation/AVFoundation.h>' not in tweak
assert 'AudioToolbox' in makefile
assert ' AVFoundation ' not in f' {makefile} '
assert 'AVAudioPlayer' in prefs
print('PASS: SpringBoard runtime uses System Sound Services; AVAudioPlayer remains settings-preview only.')

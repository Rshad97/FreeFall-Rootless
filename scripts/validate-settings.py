#!/usr/bin/env python3
import plistlib
from pathlib import Path
root = Path(__file__).resolve().parents[1]
items = plistlib.loads((root/'freefallprefs/Resources/Root.plist').read_bytes())['items']
keys = [i['key'] for i in items if 'key' in i]
assert len(keys) == len(set(keys)), 'Duplicate preference keys'
for key in ['selectedSound','shuffle','impactEnabled','impactSound','pocketMode','eventLogging','quietEnabled','quietStart','quietEnd']:
    assert key in keys, key
cooldown = next(i for i in items if i.get('key') == 'cooldownSeconds')
assert cooldown['default'] == 1 and cooldown['validValues'] == [1, 3, 5, 10]
assert cooldown['PostNotification'] == 'com.rashad.freefallrootless/ReloadPrefs'
controller = (root/'freefallprefs/FFRRootListController.m').read_text()
for item in items:
    if 'action' in item:
        assert f'(void){item["action"]}' in controller, item['action']
    if item.get('key') in ['impactEnabled','pocketMode','eventLogging','quietEnabled']:
        assert item['default'] is False
info = plistlib.loads((root/'freefallprefs/Resources/Info.plist').read_bytes())
assert info['CFBundleShortVersionString'] == '3.3.0'
assert 'Version: 3.3.0\n' in (root/'control').read_text()
print('PASS: eight-feature settings, action wiring, safe defaults and version metadata.')

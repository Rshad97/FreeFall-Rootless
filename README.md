# FreeFall Rootless

An open-source rootless port of the classic **FreeFall** jailbreak tweak for modern Dopamine/ElleKit environments. The tweak monitors accelerometer data and plays a configurable WAV sound when a free-fall event is detected.

## Status

- Version: **3.2.2**
- Package ID: `com.rashad.freefallrootless`
- Rootless package layout (`/var/jb`)
- SpringBoard injection through ElleKit
- PreferenceLoader settings pane
- Live preference reload through Darwin notifications
- Tested successfully on an **A12 iPhone XS Max running Dopamine 3 rootless**

## Features

### New in 3.2.0

All controls are under **Settings → FreeFall Rootless**:

1. **Preview Selected Sound / Preview Shuffle**: hear sounds without dropping the device.
2. **Shuffle Pool**: include only sounds you want. An empty pool is silent; a single sound can repeat.
3. **Import / Trim Custom Sound**: choose a Files audio document, preview a section and save 0.2–10 seconds. One custom slot, converted locally to mono 48 kHz 16-bit WAV. Failed imports keep the old file. DRM and undecodable formats are rejected.
4. **Play on Impact**: opt-in separate sound following a detected fall and threshold crossing. Stops the falling sound; timeouts do not trigger it.
5. **Pocket Mode**: experimental, off by default. Suppresses triggers while proximity is covered when available and requires 60 ms low acceleration. May miss short falls. iOS proximity monitoring may blank the display: disable this mode if it interferes with normal use or calls.
6. **Live Calibration**: live acceleration in g and manual threshold sliders. Save explicitly. Not an automatic calibration guarantee. Never drop your phone to test.
7. **Event Logging / History**: opt-in, local-only; 200 detailed events and 90 days of daily fall totals. Counts cover only detected events while logging is enabled. No network transmission.
8. **Quiet Hours**: local-time start/end hours including overnight; equal hours mean all-day silence. Logging continues if enabled. Intentional previews still play.

Custom audio and local history live under `/var/mobile/Library/Application Support/FreeFallRootless/`, outside the package. Existing thresholds and sound selection are preserved. Additional detection/logging/quiet options default off. Hardware detection is best-effort, not a damage-prevention feature.

SpringBoard fall/impact playback uses System Sound Services for short PCM WAV effects, matching the stable pre-3.2 runtime path and avoiding dependence on SpringBoard's shared AVAudioSession. AVAudioPlayer is used only in the Settings bundle for previews and custom-audio editing. Device sound settings may still affect audibility. Device testing is still necessary; CI is not a SpringBoard simulator.

- Enable/disable switch
- Adjustable free-fall sensitivity
- Adjustable impact/reset threshold
- CoreMotion callback-based monitoring instead of a polling timer
- Cooldown/reset logic to avoid repeated triggers during one fall
- Seven additional bundled sounds: Rashad Drop (original), Laser, Phaser, Power Down, Zap, Digital Alarm, Real Chicken (field recording)
- Selected Sound picker and Shuffle switch in Settings → FreeFall Rootless → Sounds
- Shuffle selects a playable sound on every fall and avoids consecutive repeats
- Replaceable WAV sound at `/var/jb/Library/FreeFallRootless/FreeFallScream.wav`

## Project layout

- `Tweak.xm` — CoreMotion detection and sound playback logic
- `FreeFallRootless.plist` — SpringBoard injection filter
- `Makefile` — Theos tweak build configuration
- `control` — Debian package metadata
- `layout/` — Rootless package resources and PreferenceLoader entry
- `freefallprefs/` — Settings bundle
- `.github/workflows/build.yml` — macOS GitHub Actions build
- `scripts/` — on-device build/ABI conversion helpers

## Recommended build: macOS / GitHub Actions

The cleanest way to build modern arm64e SpringBoard tweaks is with current Xcode/macOS.

With Theos installed:

```sh
export THEOS="$HOME/theos"
sh ./scripts/fetch-wilhelm-scream.sh
make clean package FINALPACKAGE=1
```

The resulting package is written to `packages/`.

The repository also includes a GitHub Actions workflow. Run **Build Rootless DEB** from the Actions tab.

## On-device build (Dopamine / NewTerm)

On-device compilation can produce the older arm64e ABI. If that happens, use **Allemande** to convert the final Mach-O files before installing the package.

See `docs/ON_DEVICE_BUILD.md`.

The combined helper is:

```sh
sh ./scripts/build-on-device.sh
```

## Preferences

PreferenceLoader entry:

`/var/jb/Library/PreferenceLoader/Preferences/FreeFallRootless.plist`

Preference bundle:

`/var/jb/Library/PreferenceBundles/FreeFallRootlessPrefs.bundle`

Preferences domain:

`com.rashad.freefallrootless`

Darwin reload notification:

`com.rashad.freefallrootless/ReloadPrefs`

## Sound

The default sound is the classic **Wilhelm Scream**. Build scripts fetch the CC0 1.6-second Wikimedia Commons clip and convert it to a System Sound compatible WAV: mono, 48 kHz, 16-bit linear PCM. This is important because iOS System Sound Services only supports short sounds (30 seconds or less) in linear PCM/IMA4 inside CAF, AIF, or WAV containers.

Installed path:

`/var/jb/Library/FreeFallRootless/FreeFallScream.wav`

See `AUDIO_LICENSE.md` for source and licensing information.

## Credits

- Original FreeFall concept/tweak: **Steven Rolfe**
- alexPNG FreeFall fork used as the historical source base
- Rootless/Dopamine port: **Rashad**

## License

GPL-3.0. See `LICENSE`.


## Repository maintenance

The `gh-pages` branch is the shared **Rashad Repo** Sileo source. Its publisher preserves both FreeFall Rootless and NFCCard packages.


NFCCard 0.3.6 has been synchronized into the shared source.

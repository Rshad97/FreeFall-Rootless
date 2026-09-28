# 3.2.1 — 2026-09-28

- Fixed a 3.2.0 runtime audio regression when a real free-fall event is detected in SpringBoard.
- Restored System Sound Services for injected fall/impact playback instead of AVAudioPlayer.
- Kept AVAudioPlayer only inside the Settings bundle for previews and custom-audio editing.
- Avoids changing or depending on SpringBoard's shared AVAudioSession category.
- Recreates the imported Custom SystemSoundID safely when the custom file changes.
- Added CI validation to prevent AVAudioPlayer from returning to the SpringBoard runtime path.
- Synchronized package, preference-bundle and source metadata to 3.2.1.

# 3.2.0 — 2026-09-28

- Added selected, Shuffle and impact sound previews in Settings.
- Added per-sound Shuffle inclusion controls; empty pool is silent.
- Added Files audio import with start/duration trim, preview, mono PCM conversion and atomic replacement of one custom slot.
- Added opt-in impact sound with a separate picker; timeout never counts as impact.
- Added experimental opt-in proximity/pocket filtering and 60 ms low-g confirmation.
- Added live accelerometer calibration with manual threshold saving.
- Added opt-in on-device event history (200 entries) and separate daily totals (90 days).
- Added quiet hours with overnight/all-day handling in the device's local timezone.
- Added native logic, selection and production importer tests to CI.
- Runtime/hardware behavior still requires validation on a supported jailbroken device.

# 3.1.0 — 2026-09-27

- Added six sounds: original Rashad Drop plus five CC0 Kenney effects.
- Added Selected Sound and live Shuffle settings; Shuffle avoids consecutive repeats.
- Retained Wilhelm Scream as the default and fallback sound.
- Serialized audio and motion state on the main queue; cached sound IDs across preference changes.

# Changelog

## 3.0.2

- Fixed Wilhelm Scream playback in the Sileo/GitHub build.
- Previous 3.0.1 package mistakenly embedded the full 39.27-second USC source WAV; iOS System Sound Services only supports sounds 30 seconds or shorter.
- Build now downloads the CC0 1.6-second Wikimedia Commons Wilhelm clip.
- Converts audio to mono 48 kHz, 16-bit linear PCM WAV for System Sound compatibility.
- Added runtime logging when AudioServicesCreateSystemSoundID fails.
- Sileo repository metadata is now generated from the built DEB instead of hardcoding the version.

## 3.0.1

- Changed the default fall sound to the classic Wilhelm Scream.
- Added scripts/fetch-wilhelm-scream.sh to fetch the CC0 WAV from the USC/Sunset Editorial collection on Internet Archive.
- Updated the on-device build helper and GitHub Actions workflow to fetch the Wilhelm sound before packaging.
- Added AUDIO_LICENSE.md with CC0 source and licensing information.

## 3.0.0

- Ported package to Theos rootless scheme.
- Updated SpringBoard injection for ElleKit/Dopamine.
- Added rootless resource paths through ROOT_PATH_NS().
- Replaced legacy accelerometer polling with CoreMotion update callbacks.
- Removed legacy ringer-state dependency.
- Added cooldown/reset handling to prevent repeated triggers in a single fall.
- Added PreferenceLoader settings for enable state and sensitivity thresholds.
- Added live preference reload using a Darwin notification.
- Fixed PreferenceLoader rootless bundle discovery with explicit bundlePath.
- Fixed settings controller registration with detail and isController.
- Fixed Root.plist structure so settings specifiers render correctly.
- Added macOS GitHub Actions build workflow.
- Added on-device Allemande helper scripts/documentation.

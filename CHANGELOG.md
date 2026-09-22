# Changelog

## 3.0.1

- Changed the default fall sound to the classic Wilhelm Scream.
- Added `scripts/fetch-wilhelm-scream.sh` to fetch the CC0 WAV from the USC/Sunset Editorial collection on Internet Archive.
- Updated the on-device build helper and GitHub Actions workflow to fetch the Wilhelm sound before packaging.
- Added `AUDIO_LICENSE.md` with CC0 source and licensing information.

## 3.0.0

- Ported package to Theos rootless scheme.
- Updated SpringBoard injection for ElleKit/Dopamine.
- Added rootless resource paths through `ROOT_PATH_NS()`.
- Replaced legacy accelerometer polling with CoreMotion update callbacks.
- Removed legacy ringer-state dependency.
- Added cooldown/reset handling to prevent repeated triggers in a single fall.
- Added PreferenceLoader settings for enable state and sensitivity thresholds.
- Added live preference reload using a Darwin notification.
- Fixed PreferenceLoader rootless bundle discovery with explicit `bundlePath`.
- Fixed settings controller registration with `detail` and `isController`.
- Fixed `Root.plist` structure so settings specifiers render correctly.
- Added macOS GitHub Actions build workflow.
- Added on-device Allemande helper scripts/documentation.

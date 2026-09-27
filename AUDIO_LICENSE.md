# Audio asset: Wilhelm Scream

FreeFall Rootless uses the classic **Wilhelm Scream** as its default fall sound.

The build helper downloads the short Wikimedia Commons clip:

- File: `Wilhelm_Scream.ogg`
- Duration: about 1.6 seconds
- License: **CC0 1.0 Universal / public-domain dedication**
- Source: https://commons.wikimedia.org/wiki/File:Wilhelm_Scream.ogg

Wikimedia Commons documents that this short clip was trimmed from the USC/Sunset Editorial sound-effects collection hosted by Internet Archive, around the 0:27 mark of the original recording.

For compatibility with iOS System Sound Services, the build converts the OGG to:

- WAV container
- Linear PCM
- 16-bit
- Mono
- 48 kHz
- Under 30 seconds

The GPL-3.0 license applies to the FreeFall Rootless source code. The Wilhelm audio retains its CC0 status.

## Added in 3.1.0

RashadDrop.wav is an original synthesized effect created for this project, licensed under the project GPL-3.0 license. Reproduce it with `python3 scripts/generate-rashad-drop.py`. No third-party samples.

The following five effects are by Kenney (https://kenney.nl), dedicated to CC0:
Source: https://opengameart.org/content/63-digital-sound-effects-lasers-phasers-space-etc
Download: https://opengameart.org/sites/default/files/Digital_SFX_Set.zip
Archive SHA-256: 022f0f4b73da55989567fe2b373c8af89d74f5d015257e293cab497ca606d063

Converted to mono, 48 kHz, 16-bit PCM WAV with FFmpeg.

| Bundled file | Source file |
|---|---|
| Laser.wav | laser1.mp3 |
| Phaser.wav | phaserDown1.mp3 |
| PowerDown.wav | highDown.mp3 |
| Zap.wav | zapThreeToneDown.mp3 |
| Alarm.wav | threeTone1.mp3 |

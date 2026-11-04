# M64 Android Test APK

Target artifact: `builds/android/AbyssalDominion_M64_Test.apk`

Required:
- Godot 4.7.2 stable
- matching 4.7.2 export templates
- Android export/signing dependencies configured for Godot

Build:
`GODOT_BIN=/path/to/godot tools/build_m64_android.sh`

The script uses the existing `Android` export preset and performs a debug export suitable for device testing. M64's preset metadata is version 0.64.0 / code 64.

This repository does not treat an APK as valid unless Godot completed the export successfully. A ZIP renamed to `.apk` is never accepted.

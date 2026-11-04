# M149 Validation Report

Validated on 2026-09-01 with the available Godot 4.5.1 supplemental runtime. The project target remains Godot 4.7.2 Compatibility.

## Passed gates

- All 378 JSON files parse.
- M149 static runtime integration check passes.
- Godot editor reload completed without script, parse or import errors.
- `M149_P1_REGIONAL_RUNTIME_PASS`.
- Regression tests M148, M147, M146, M145 and M144 pass.
- Eight-second headless startup smoke window completed without script, parse, invalid-call or assertion errors.
- Version identity is 0.149.0 / build 149 across project and export presets.
- Existing 24 regional GLBs, 27 admin content types, 18 admin modules and 59 RBAC permissions remain intact.

## Verified integration

- Crimson Sea resolves three regional monsters and its canonical Admiral.
- Drowned Reach resolves four regional monsters and its canonical Admiral.
- Regional spawn defaults remain local fallback values and are overrideable through data/admin/server snapshots.
- Regional island, nature and harbor slots resolve through the M148 swap manifest.
- Platform presentation keeps Web preview below Android/iOS and desktop/macOS quality budgets.
- Visual profiles never own collision, combat, progression, rewards or economy.

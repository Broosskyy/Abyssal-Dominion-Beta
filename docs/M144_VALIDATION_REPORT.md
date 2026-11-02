# M144 Validation Report

Date: 2026-09-01

## Passed

- Project JSON passes the M144 integrity checker.
- Metadata is versioned as `0.144.0` / Android code `144`.
- Coverage remains 18 admin modules, 27 content types and 59 permissions.
- Local workflow cannot enter `approved`, `scheduled`, `active` or `rolled_back`.
- Gateway contract includes draft, review, approval, publish, schedule, rollback, asset, snapshot and audit operations.
- Supplemental Godot 4.5.1 headless editor scan completes without script or parse errors.
- Runtime adapter test and startup smoke test pass.

## Not certified here

- Exact Godot 4.7.2 native exports; matching export templates are unavailable here.
- Android, iOS, macOS and Windows device/store signing.
- Admin HTTP backend; the gateway remains a disconnected contract adapter.
- Multiplayer/crossplay authority; this still requires the Abyssal Dominion service.

The 4.5.1 scan is supplementary evidence, not a substitute for the 4.7.2 export/device matrix.

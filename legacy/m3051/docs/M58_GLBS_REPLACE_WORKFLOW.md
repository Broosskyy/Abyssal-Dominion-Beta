# M58 — Final GLB Replace Workflow

1. Export final model as `.glb`.
2. Keep +Y up, +Z forward, meter units, gameplay center/waterline at Y=0.
3. Do not embed gameplay scripts, collision, cameras, navigation or water.
4. Place the GLB below `res://assets/production/models/`.
5. Add only a visual override in `data/visual_overrides.json`.
6. Open the M58 Asset QA / Replacement Lab and filter `M58 GLB WAVE`.
7. Check scale, pivot, waterline, forward direction, silhouette and mobile readability.
8. If the override is absent or invalid, the existing fallback remains active.

Recommended first path:
`res://assets/production/models/ship_small.glb`

Example override:
```json
"ship_small": {
  "path": "res://assets/production/models/ship_small.glb",
  "fit_reference": true,
  "scale": [1,1,1],
  "offset": [0,0,0],
  "rotation_degrees": [0,0,0]
}
```

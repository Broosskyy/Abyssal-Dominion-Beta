# Asset import rules

## Canonical orientation

- Forward/bow: +Z
- Stern: -Z
- Starboard: +X
- Port: -X
- Up: +Y
- Pivot: centered at the waterline

## Preferred format

- Models and embedded animations: GLB/glTF 2.0
- Textures: PNG, WebP or KTX2 where appropriate
- Audio: OGG for general playback, WAV only where low-latency/raw quality is required

## Ship scene contract

Every authored ship scene should expose:

- `ShipRoot`
- `Visual`
- `Collision`
- `Sockets/CannonPort_*`
- `Sockets/CannonStarboard_*`
- `Sockets/WakeLeft` and `WakeRight`
- `Sockets/ImpactCenter`
- `Anchors/Nameplate`
- `Anchors/Selection`
- `Audio`

## Production boundary

`assets/reference_only/` is excluded from every export. Licensed production-ready assets go under `assets/production/` and receive source/license metadata before inclusion.

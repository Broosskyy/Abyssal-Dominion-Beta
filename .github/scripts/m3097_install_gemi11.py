#!/usr/bin/env python3
"""M3097: install independent Gemi11 skin 30 without modifying skins 0..29."""
from pathlib import Path
import hashlib, json, shutil, struct, sys

if len(sys.argv) != 3:
    raise SystemExit("Usage: m3097_install_gemi11.py /path/to/repository /path/to/staged/assets")
repo = Path(sys.argv[1]).resolve()
source = Path(sys.argv[2]).resolve()
project = repo / "rebuild" / "m3052"
if not (project / "sea_map.gd").is_file() or not (project / "ship_mesh_layer.gd").is_file():
    raise SystemExit("Not the Abyssal Dominion Beta project")
asset_dir = project / "assets" / "player" / "test_ships"
filenames = ("gemi11_uv.glb", "gemi11_uv_eight.png", "gemi11_uv_preview.png")
for name in filenames:
    f = source / name
    if not f.is_file() or f.stat().st_size < 1000:
        raise RuntimeError(f"Missing or empty M3097 asset: {f}")

raw = (source / "gemi11_uv.glb").read_bytes()
digest = hashlib.sha256(raw).hexdigest()
EXPECTED_SHA256 = "e7b25db9b5db8573564441c8d942ceca166ab0b8aaa1f27796a75f882e78ac4b"
if digest != EXPECTED_SHA256:
    raise RuntimeError("The GLB does not match the exact uploaded user model")
if raw[:4] != b"glTF" or struct.unpack_from("<I", raw, 8)[0] != len(raw):
    raise RuntimeError("Gemi11 GLB header/size invalid")
json_length, chunk_type = struct.unpack_from("<II", raw, 12)
if chunk_type != 0x4E4F534A:
    raise RuntimeError("GLB JSON chunk missing")
metadata = json.loads(raw[20:20 + json_length])
assert len(metadata["meshes"]) == 3 and len(metadata["images"]) == 1

from PIL import Image
with Image.open(source / "gemi11_uv_eight.png") as atlas:
    assert atlas.size == (2560, 320) and atlas.getbbox() is not None
with Image.open(source / "gemi11_uv_preview.png") as preview:
    assert preview.size == (640, 640) and preview.getbbox() is not None

replacement_files = {}
def replace(name: str, old: str, new: str) -> None:
    if name not in replacement_files:
        replacement_files[name] = (project / name).read_text(encoding="utf-8")
    text = replacement_files[name]
    found = text.count(old)
    if found != 1:
        raise RuntimeError(f"{name}: expected exactly one occurrence of {old[:90]!r}; found {found}")
    replacement_files[name] = text.replace(old, new)

name = "ship_mesh_layer.gd"
replace(name,
    'const TEST_SHIP_SKINS := {27:"crimson_voyager",28:"test_ship_2",29:"base_basic_pbr"}',
    'const TEST_SHIP_SKINS := {27:"crimson_voyager",28:"test_ship_2",29:"base_basic_pbr",30:"gemi11_uv"}')
replace(name,
    '"base_basic_gameplay_shaded":preload("res://assets/player/test_ships/base_basic_gameplay_shaded.glb")',
    '"base_basic_gameplay_shaded":preload("res://assets/player/test_ships/base_basic_gameplay_shaded.glb"),\n\t"gemi11_uv":preload("res://assets/player/test_ships/gemi11_uv.glb")')
replace(name,
    '"base_basic_gameplay_shaded":Vector3(0,0,1)}',
    '"base_basic_gameplay_shaded":Vector3(0,0,1),"gemi11_uv":Vector3(0,0,1)}')
replace(name,
    '"base_basic_gameplay_shaded":[1.896816,0.0,1.460584,-0.000345,0.000428,-90.0]',
    '"base_basic_gameplay_shaded":[1.896816,0.0,1.460584,-0.000345,0.000428,-90.0],\n\t# M3097 original GLB dimensions; local +Z prow, Y up.\n\t"gemi11_uv":[36.973776,-0.753792,27.774979,0.043137,1.132746,-90.0]')
replace(name,
    '"base_basic_gameplay_pbr":0.614,"base_basic_gameplay_shaded":0.614}',
    '"base_basic_gameplay_pbr":0.614,"base_basic_gameplay_shaded":0.614,"gemi11_uv":10.362028}')
replace(name,
    '"base_basic_gameplay_pbr":0.42,"base_basic_gameplay_shaded":0.42',
    '"base_basic_gameplay_pbr":0.42,"base_basic_gameplay_shaded":0.42,"gemi11_uv":7.20')

name = "sea_map.gd"
replace(name,
    '"base_basic_pbr":preload("res://assets/player/test_ships/base_basic_pbr_eight.png")',
    '"base_basic_pbr":preload("res://assets/player/test_ships/base_basic_pbr_eight.png"),\n\t"gemi11_uv":preload("res://assets/player/test_ships/gemi11_uv_eight.png")')
replace(name,
    '"base_basic_pbr":preload("res://assets/player/test_ships/base_basic_pbr_preview.png")',
    '"base_basic_pbr":preload("res://assets/player/test_ships/base_basic_pbr_preview.png"),\n\t"gemi11_uv":preload("res://assets/player/test_ships/gemi11_uv_preview.png")')
replace(name,
    'const TEST_SHIP_KEYS := ["crimson_voyager","test_ship_2","base_basic_pbr"]',
    'const TEST_SHIP_KEYS := ["crimson_voyager","test_ship_2","base_basic_pbr","gemi11_uv"]')
replace(name,
    'const TEST_SHIP_LENGTHS := [128.0,152.0,158.0]',
    'const TEST_SHIP_LENGTHS := [128.0,152.0,158.0,154.0]')
replace(name,
    'var test_names=["Crimson Voyager · Startschiff","TEST · Totenkopf-Galeere","TEST · Schattenkriegsschiff"]',
    'var test_names=["Crimson Voyager · Startschiff","TEST · Totenkopf-Galeere","TEST · Schattenkriegsschiff","TEST 2 · Gemi11 UV korrigiert"]')
replace(name,
    'if skin>=27 and skin<=29:return TEST_SHIP_LENGTHS[skin-27]',
    'if skin>=27 and skin<=30:return TEST_SHIP_LENGTHS[skin-27]')
replace(name,
    'Die 3 kostenlosen GLB-Testschiffe stehen oben.',
    'Die vier kostenlosen GLB-Testschiffe stehen oben, darunter Gemi11 als eigener Testplatz.')
replace(name,
    '# Put starter and both free testing hulls first; sort old designs below.',
    '# Put all four GLB testing hulls first, without removing other designs.')

name = "simulation.gd"
replace(name, 'const TEST_SKIN_MAX := 29', 'const TEST_SKIN_MAX := 30')

name = "tests/ui_test.gd"
replace(name,
    'check(game.skins.size()==30,"27 original ship designs plus three playable GLB test ships are listed")',
    'check(game.skins.size()==31,"27 original designs plus four playable GLB ships, including Gemi11")')
replace(name,
    'check(game.TEST_SHIP_LENGTHS==[128.0,152.0,158.0],"M3087 normalized player test hull silhouettes use three coherent size tiers")',
    'check(game.TEST_SHIP_LENGTHS==[128.0,152.0,158.0,154.0],"M3097 Gemi11 is independently sized without changing previous hulls")')
replace(name,
    'for skin_id in [27,28,29]:',
    'for skin_id in [27,28,29,30]:')
replace(name,
    'for model_key in ["crimson_voyager","test_ship_2","base_basic_pbr","base_basic_gameplay_pbr","base_basic_gameplay_shaded"]:',
    'for model_key in ["crimson_voyager","test_ship_2","base_basic_pbr","base_basic_gameplay_pbr","base_basic_gameplay_shaded","gemi11_uv"]:')
replace(name,
    'var fresh=game.SIM.new()',
    'check(str(game.skins[30].mesh_key)=="gemi11_uv","M3097 Gemi11 occupies separate skin 30 in shipyard")\n'
    '\tgame.sim.player.skin=30\n'
    '\tgame.mesh_layer.set_render_mode("3d")\n'
    '\tcheck(game.mesh_layer.can_render_actor(game.sim.player),"M3097 Gemi11 renders as real GLB in 3D")\n'
    '\tgame.mesh_layer.sync_fleet([game.sim.player],game.camera,game.get_viewport_rect().size)\n'
    '\tcheck(str(game.mesh_layer.model_instance_keys.get(0,""))=="gemi11_uv","M3097 Gemi11 GLB instance is independent")\n'
    '\tgame.mesh_layer.set_render_mode(old_comparison_mode)\n'
    '\tgame.sim.player.skin=old_comparison_skin\n'
    '\tvar fresh=game.SIM.new()')
replace(name,
    'fresh.player.skin=27\n\tcheck(fresh.restore_save(fresh_save)',
    'fresh.player.skin=30\n\tcheck(fresh.restore_save(fresh.export_save()) and int(fresh.player.skin)==30,"M3097 Gemi11 skin persists across save/load")\n'
    '\tfresh.player.skin=27\n\tcheck(fresh.restore_save(fresh_save)')

# Write as one CI operation after every asset and source precondition passed.
asset_dir.mkdir(parents=True, exist_ok=True)
for filename in filenames:
    shutil.copy2(source / filename, asset_dir / filename)
for name, text in replacement_files.items():
    (project / name).write_text(text, encoding="utf-8")
print("M3097 Gemi11 installed: original GLB SHA256", digest)
print("Added skin 30 as independent test ship; skins 0..29 untouched")
print("Updated files:", sorted(replacement_files))

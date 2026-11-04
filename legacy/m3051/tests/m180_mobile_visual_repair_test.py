import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
contract = json.loads((r / "data/m180_mobile_visual_repair.json").read_text())
regional = json.loads((r / "data/m150_p1_regional_visual_acceptance.json").read_text())
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())
layout = (r / "scripts/ui/nautical_layout.gd").read_text()
hud = (r / "scripts/ui/nautical_hud.gd").read_text()
water = (r / "scripts/visual/water_surface.gd").read_text()
admin = (r / "scripts/admin/admin_overlay.gd").read_text()
meta = (r / "scripts/ui/meta_systems_panel.gd").read_text()
input_code = (r / "scripts/gameplay/player_input.gd").read_text()
badge = (r / "scripts/ui/m159_admin_badge.gd").read_text()

assert release["build_number"] >= 180
assert contract["milestone"] == "M180"
assert contract["mobile_hud"]["wide_reference_navigation"] == ["KARTE", "WERFT", "LOG", "ARSENAL", "MENÜ"]
assert contract["authority"]["gameplay_or_economy_values_changed"] is False
assert contract["water"]["large_white_glare_is_acceptable"] is False

default = regional["default_profile"]
assert default["sun_energy"] <= 0.92
assert default["water"]["surface_roughness"] >= 0.58
assert default["water"]["specular_strength"] <= 0.24
for token in ["surface_roughness", "specular_strength", "METALLIC = 0.0", "NORMAL_MAP_DEPTH = 0.22"]:
    assert token in water
for token in ["w / sx < 1450.0", "mobile_nav", "nav_map", "nav_log", "enforce_runtime_non_overlap", "items_picker_center.x"]:
    assert token in layout
assert 'if not compact and not bool(layout.get("touch_density",false))' in hud
for token in ["NauticalTheme.create()", "runtime.changed.connect(_refresh)", "shade.visible=open", "InputDeviceProfile.touch_like", "PlayerInput"]:
    assert token in admin
for token in ["add_to_group(\"meta_systems_panel\")", "func open()", "shade.show()", "meta_panel_open"]:
    assert token in meta
assert "admin_panel_open" in input_code and "meta_panel_open" in input_code
assert "not InputDeviceProfile.touch_like" in badge
for content_type in ["mobile_hud_composition_profile", "water_surface_presentation_profile", "modal_menu_layout_profile"]:
    assert content_type in registry["content_types"]

# Mirror the M180 landscape combat geometry at the supplied 2340x1080 device class.
def rect(cx, cy, radius): return (cx-radius, cy-radius, cx+radius, cy+radius)
def intersects(a, b, gap=3):
    return not (a[2]+gap <= b[0]-gap or b[2]+gap <= a[0]-gap or a[3]+gap <= b[1]-gap or b[3]+gap <= a[1]-gap)
w, h, sx = 2340.0, 1080.0, 1.55
fire_r, picker_r, small = 50*sx, 36*sx, 28*sx
fire = (w-fire_r-18*sx, h-fire_r-22*sx)
ammo = (fire[0]-fire_r-picker_r-22*sx, fire[1]+4*sx)
items = (ammo[0]-picker_r*2-14*sx, ammo[1])
centers = {
    "fire": (*fire, fire_r), "ammo": (*ammo, picker_r), "items": (*items, picker_r),
    "repair": (ammo[0], ammo[1]-picker_r-small-12*sx, small),
    "boost": (items[0], items[1]-picker_r-small-12*sx, small),
    "target": (fire[0], fire[1]-fire_r-small-12*sx, small),
}
boxes = {k: rect(*v) for k, v in centers.items()}
for i, a in enumerate(boxes):
    for b in list(boxes)[i+1:]: assert not intersects(boxes[a], boxes[b]), (a, b)

print("M180 MOBILE VISUAL/UI/WATER REPAIR PASS")

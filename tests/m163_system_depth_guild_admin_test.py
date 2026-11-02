from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
for p in r.rglob("*.json"):
    json.loads(p.read_text(encoding="utf-8"))
d=json.loads((r/"data/m163_system_depth_and_guild.json").read_text(encoding="utf-8"))
assert d["milestone"]=="M163"
assert len(d["special_deck_depth"])>=6
assert len(d["ammo_profiles"])>=12
assert len(d["harpoon_profiles"])>=8
assert len(d["consumables_and_materials"])>=20
assert len(d["cannon_visual_stages"])>=20
g=d["guild"]
assert len(g["ranks"])>=7 and len(g["buildings"])>=6 and len(g["towers"])>=5
assert g["treasury"]["server_authoritative"] and g["siege"]["server_authoritative"]
assert len(d["admin_editors"])>=6
registry=json.loads((r/"data/admin_content_type_registry.json").read_text(encoding="utf-8"))["content_types"]
for t in ["ammo_profile","ammo_effect","harpoon_family","cannon_visual_stage","guild_building_level","guild_tower_level","guild_treasury_rule","admin_editor_schema"]: assert t in registry
boot=(r/"scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
assert "M163SystemDepthCatalog" in boot
inv=(r/"scripts/progression/player_inventory.gd").read_text(encoding="utf-8")
for fn in ["selected_harpoon","select_harpoon","harpoon_profile","m163_ammo_profile","m163_consume_effect_item"]: assert f"func {fn}" in inv
visual=(r/"scripts/visual/m159_ship_extension_visuals.gd").read_text(encoding="utf-8")
assert "CannonMasteryVFX" in visual and "_rebuild_cannon_mastery" in visual
guild=(r/"scripts/guild/m159_guild_island_depth.gd").read_text(encoding="utf-8")
assert "guild_tower_hunter_01" in guild and "guild_ward_foundry_01" in guild
rel=json.loads((r/"data/release_identity.json").read_text(encoding="utf-8"))
assert rel["build_number"]>=163 and rel["master_concept"]=="V3.8"
print("M163 SYSTEM DEPTH + GUILD + ADMIN PASS")

from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
for p in r.rglob("*.json"): json.loads(p.read_text(encoding="utf-8"))
d=json.loads((r/"data/m164_no_code_combat_guild_ui.json").read_text(encoding="utf-8"))
assert d["milestone"]=="M164"
assert len(d["ammo_extensions"])>=6 and len(d["harpoon_extensions"])>=3
assert len(d["cannon_evolution"])==5 and len(d["guild_island_modules"])>=5 and len(d["new_items"])>=8
assert len(d["guild_upgrade_curves"]["building_levels"])==10 and len(d["guild_upgrade_curves"]["tower_levels"])==10
combat=(r/"scripts/combat/combat_catalog.gd").read_text(encoding="utf-8")
for fn in ["cannon_rows","ammo_rows","cannon_count","ammo_count","ammo_id"]: assert f"func {fn}" in combat
weapons=(r/"scripts/gameplay/ship_weapons.gd").read_text(encoding="utf-8")
assert "CombatCatalog.cannon_count()" in weapons and "CombatCatalog.ammo_count()" in weapons and "CombatCatalog.ammo_id(ammo_index)" in weapons
inv=(r/"scripts/progression/player_inventory.gd").read_text(encoding="utf-8")
assert "func _is_runtime_ammo" in inv and "CombatCatalog.cannon_count()" in inv and "CombatCatalog.ammo_count()" in inv
guild=(r/"scripts/guild/m159_guild_island_depth.gd").read_text(encoding="utf-8")
for x in ["guild_watch_beacon_01","guild_repair_dock_01","guild_resource_pier_01","guild_war_room_01","guild_relic_vault_01"]: assert x in guild
reg=json.loads((r/"data/admin_content_type_registry.json").read_text(encoding="utf-8"))["content_types"]
for t in ["guild_island_module","guild_upgrade_curve","cannon_evolution_stage","item_family","runtime_editor_schema"]: assert t in reg
rel=json.loads((r/"data/release_identity.json").read_text(encoding="utf-8"))
assert rel["build_number"]>=164 and rel["master_concept"]=="V3.8"
print("M164 NO-CODE COMBAT + GUILD + UI PASS")

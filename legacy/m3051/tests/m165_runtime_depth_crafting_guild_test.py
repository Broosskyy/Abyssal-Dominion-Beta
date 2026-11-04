from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
count=0
for p in r.rglob("*.json"):
 json.loads(p.read_text(encoding="utf-8"));count+=1
d=json.loads((r/"data/m165_runtime_effects_crafting_guild.json").read_text(encoding="utf-8"))
assert d["milestone"]=="M165" and len(d["harpoon_runtime_profiles"])>=11
assert len(d["crafting_recipes"])>=6 and len(d["crafting_stations"])>=4 and len(d["guild_tower_specializations"])==5
support=(r/"scripts/gameplay/support_payload_catalog.gd").read_text(encoding="utf-8")
assert "_m165_harpoons" in support and "harpoon_runtime_profiles" in support
weapons=(r/"scripts/gameplay/ship_weapons.gd").read_text(encoding="utf-8")
for x in ["damage_mult","range_mult","reload_mult","status_effect","effect_duration"]: assert x in weapons
inv=(r/"scripts/progression/player_inventory.gd").read_text(encoding="utf-8")
assert "func craft_m165_recipe" in inv and "harpoon_reefspike" in inv and "harpoon_dreadfang" in inv
hub=(r/"scripts/ui/m160_progression_hub.gd").read_text(encoding="utf-8")
assert '"crafting"' in hub and "M165" in hub and "craft_m165_recipe" in hub
reg=json.loads((r/"data/admin_content_type_registry.json").read_text(encoding="utf-8"))["content_types"]
for t in ["crafting_recipe","crafting_station","guild_tower_specialization","combat_effect_primitive","cannon_visual_stage"]:assert t in reg
rel=json.loads((r/"data/release_identity.json").read_text(encoding="utf-8"))
assert rel["build_number"]>=165 and rel["master_concept"]=="V3.8"
print(f"M165 RUNTIME DEPTH + CRAFTING + GUILD PASS | {count} JSON")

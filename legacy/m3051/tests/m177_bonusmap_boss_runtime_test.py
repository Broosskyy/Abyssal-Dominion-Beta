import json, pathlib

r = pathlib.Path(__file__).resolve().parents[1]
release = json.loads((r / "data/release_identity.json").read_text())
assert release["build_number"] >= 177
data = json.loads((r / "data/m177_bonusmap_boss_runtime.json").read_text())
assert set(data["maps"]) == {"silver", "gold", "abyss", "legendary"}
assert sum(len(v["mechanics"]) for v in data["maps"].values()) == 10
assert data["bonus_objectives"]["no_death"]["client_grant"] is False
assert data["authority"]["presentation_may_grant"] is False

runtime = (r / "scripts/gameplay/bonusmap_boss_mechanics.gd").read_text()
director = (r / "scripts/world/bonusmap_wave_director.gd").read_text()
void = (r / "scripts/gameplay/void_monster_mechanics.gd").read_text()
hud = (r / "scripts/ui/game_hud.gd").read_text()
registry = json.loads((r / "data/admin_content_type_registry.json").read_text())
for token in ["target_damage", "repair_block", "target_status", "boss_barrier", "boss_enrage", "danger_telegraph", "cooldowns"]:
    assert token in runtime
assert "BonusMapBossMechanics.new()" in director
assert "bonus_no_death" in director
assert "M177BonusMapBossRuntimeCatalog.reward_rarity" in director
assert "health.normalized()" in void and "health.health" not in void
assert 'boss_mechanic_label' in hud and 'warning_y:float=(geometry.top as Rect2).end.y+8.0' in hud
for content_type in ["bonusmap_boss_runtime_profile", "boss_mechanic_profile", "bonus_objective_profile"]:
    assert content_type in registry["content_types"]
print("M177 DISTINCT BONUSMAP BOSS RUNTIME PASS")

#!/usr/bin/env python3
"""Data and wiring checks; not a substitute for tests/m10_encounters_test.gd."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    data = json.loads((ROOT / "data/encounters.json").read_text())
    director = (ROOT / "scripts/world/encounter_director.gd").read_text()
    world = (ROOT / "scripts/world/world_map_system.gd").read_text()
    health = (ROOT / "scripts/gameplay/ship_health.gd").read_text()
    save = (ROOT / "scripts/core/game_state.gd").read_text()
    exports = (ROOT / "export_presets.cfg").read_text()
    checks = {}
    checks["three_biomes"] = set(data["biomes"]) == {"tropical", "desert", "snow"}
    checks["four_bounded_slots"] = data["population"] == 4 and all(len(v["slots"]) == 4 for v in data["biomes"].values())
    checks["valid_archetype_references"] = all(k in data["archetypes"] for b in data["biomes"].values() for k in b["slots"])
    checks["distinct_compositions"] = len({tuple(b["slots"]) for b in data["biomes"].values()}) == 3
    checks["positive_counters_and_delays"] = all(b["required_kills"] > 0 and b["respawn_seconds"] > 1.35 for b in data["biomes"].values())
    checks["positive_stats_and_rewards"] = all(all(p[k] > 0 for k in ("hull", "damage", "speed", "xp", "coins")) for p in data["archetypes"].values())
    checks["valid_weapon_indices"] = all(0 <= p["cannon"] < 3 and 0 <= p["ammo"] < 3 for p in data["archetypes"].values())
    checks["explicit_test_provenance"] = "not recovered production" in data["provenance"]
    checks["six_export_data_filters"] = exports.count('include_filter="data/*.json"') == 6
    checks["old_enemy_reposition_removed"] = "_reposition_enemies" not in world
    checks["sector_detaches_old_content"] = "remove_child(sector_content)" in world
    checks["director_owns_respawn"] = "health.auto_respawn = false" in director and "if not auto_respawn:" in health
    checks["lethal_guard_before_signal"] = health.index("is_sunk = true") < health.index("ship_sunk.emit")
    checks["encounter_persistence"] = '"encounters": world_map.encounters.export_state()' in save and "world_map.encounters.import_state" in save
    checks["deferred_reward_owner_guard"] = "owner_root != content" in director
    checks["headless_test_present"] = (ROOT / "tests/m10_encounters_test.gd").is_file()
    report = {"milestone": "M10", "kind": "data_and_source_contracts", "passed": all(checks.values()), "checks_passed": sum(checks.values()), "checks_total": len(checks), "checks": checks}
    (ROOT / "docs/m10_encounter_validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

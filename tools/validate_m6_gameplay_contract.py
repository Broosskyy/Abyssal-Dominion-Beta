#!/usr/bin/env python3
"""Static validation for the M6 persistence/progression contract."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def has(path: str, *needles: str) -> bool:
    text = (ROOT / path).read_text(encoding="utf-8")
    return all(needle in text for needle in needles)


def main() -> int:
    sample = {"save_version": 1, "player": {"health": 880.0}, "world": {"sector": [2, 1]}}
    canonical = json.dumps(sample, separators=(",", ":"), sort_keys=True)
    envelope = {"payload": sample, "checksum": hashlib.sha256(canonical.encode()).hexdigest()}
    round_trip = json.loads(json.dumps(envelope))
    round_trip_text = json.dumps(round_trip["payload"], separators=(",", ":"), sort_keys=True)
    checksum_ok = hashlib.sha256(round_trip_text.encode()).hexdigest() == round_trip["checksum"]
    bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
    checks = {
        "m6_or_newer_version": any(
            has("project.godot", f'config/version="0.{version}.0"')
            for version in range(6, 100)
        ),
        "user_save_path": has("scripts/core/game_state.gd", "user://seefight_save_v1.json"),
        "backup_save": has("scripts/core/game_state.gd", "BACKUP_PATH", "_read_valid_payload(BACKUP_PATH)"),
        "checksum_guard": has("scripts/core/game_state.gd", "sha256_text", "checksum"),
        "autosave": has("scripts/core/game_state.gd", "12.0", "save_now()"),
        "focus_save": has("scripts/core/game_state.gd", "NOTIFICATION_APPLICATION_FOCUS_OUT"),
        "sector_restore": has("scripts/world/world_map_system.gd", "restore_sector"),
        "checkpoint_restore": has("scripts/core/game_state.gd", "_restore_checkpoint", "respawn_position"),
        "progression": has("scripts/progression/player_progression.gd", "xp_to_next_level", "purchase_upgrade"),
        "three_upgrades": has("scripts/progression/player_progression.gd", '"hull"', '"cannon"', '"sails"'),
        "mission_rotation": has("scripts/progression/mission_system.gd", "sink_hostiles", "collect_salvage", "harbor_route"),
        "loot_binding": has("scripts/gameplay/loot_pickup.gd", "add_coins", "record_loot"),
        "dock_binding": has("scripts/world/port_interaction.gd", "record_dock", "toggle_shop"),
        "mobile_shop": has("scripts/ui/game_hud.gd", '"HULL"', '"CANNON"', '"SAILS"', '"CLOSE"'),
        "module_order": bootstrap.find('progression.name = "Progression"') < bootstrap.find('player_input.name = "PlayerInput"'),
        "save_round_trip_model": checksum_ok,
    }
    report = {"milestone": "M6", "passed": all(checks.values()), "checks_passed": sum(checks.values()), "checks_total": len(checks), "checks": checks}
    (ROOT / "docs/m6_gameplay_validation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

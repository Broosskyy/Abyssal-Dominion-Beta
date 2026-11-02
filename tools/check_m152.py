#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

identity = load("release_identity.json")
meta = load("m152_v38_meta_systems.json")
companions = load("m152_companion_catalog.json")
artifacts = load("m152_artifact_catalog.json")
afk = load("m152_afk_reward_profiles.json")
types = load("admin_content_type_registry.json")
guard = load("m150_master_ship_progression_guard.json")

require(identity["milestone"] == "M152" and identity["client_version"] == "0.152.0" and identity["build_number"] == 152, "release identity not M152")
require(identity["master_concept"] == "V3.8", "master concept not V3.8")
require(meta["resolution"]["v38_is_additive"] and "100 regular" in meta["resolution"]["ship_direction"], "V3.8 resolution regressed")
require(guard["starter_ships"]["count"] == 3 and guard["regular_ship_classes"]["count"] == 100, "binding ship progression regressed")
require(len(companions["companions"]) == 6 and companions["active_slots_initial"] == 1, "companion foundation incomplete")
require(len({row["role"] for row in companions["companions"]}) == 6, "companion role variety incomplete")
require(len(artifacts["artifacts"]) == 6 and artifacts["initial_active_slots"] == 2, "artifact foundation incomplete")
require(len(afk["profiles"]) == 4 and afk["caps"]["default_seconds"] == 28800, "AFK profiles or cap incomplete")
require(afk["claim"]["idempotent"] and afk["claim"]["client_clock_forbidden_online"], "AFK authority guard incomplete")
for row in afk["profiles"]:
    encoded = json.dumps(row).lower()
    require(all(forbidden.lower() not in encoded for forbidden in afk["forbidden_rewards"]), f"forbidden AFK reward in {row['id']}")

for row in companions["companions"]:
    assets = row["assets"]
    for field in ("model", "icon", "portrait", "vfx", "audio"):
        require(assets.get(field), f"missing companion asset slot {field}: {row['id']}")
    require((ROOT / assets["icon"].removeprefix("res://")).is_file(), f"missing companion icon: {row['id']}")
for row in artifacts["artifacts"]:
    require((ROOT / row["icon"].removeprefix("res://")).is_file(), f"missing artifact icon: {row['id']}")
require((ROOT / "assets/production/ui/m152/afk_harbor_operations.svg").is_file(), "missing AFK graphic")

require(len(types["content_types"]) == 30, "admin content type count regressed")
for name in ("companion", "artifact", "afk_reward_profile"):
    require(name in types["content_types"], f"missing admin content type: {name}")

bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
panel = (ROOT / "scripts/ui/meta_systems_panel.gd").read_text(encoding="utf-8")
service = (ROOT / "scripts/meta/afk_reward_service.gd").read_text(encoding="utf-8")
require("CompanionRuntime.new()" in bootstrap and "ArtifactLoadout.new()" in bootstrap and "AfkRewardService.new()" in bootstrap, "M152 runtime not bootstrapped")
require("MetaSystemsPanel.new()" in bootstrap and "custom_minimum_size.y=52" in panel, "mobile meta UI missing")
require("M152 ADMIN COMMAND" in overlay and "meta_status_label" in overlay, "M152 admin status missing")
require("claims.has(claim_id)" in service and "LOCAL_PREVIEW_ONLY" in service, "AFK idempotency/local boundary missing")

print("M152_CHECK_PASS")
print(f"companions={len(companions['companions'])} artifacts={len(artifacts['artifacts'])} afk_profiles={len(afk['profiles'])} admin_types={len(types['content_types'])}")
print("ship_direction=3_starters/100_regular/P1-P5 web=preview_only global=locked")

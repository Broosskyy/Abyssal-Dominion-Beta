#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

types = load("admin_content_type_registry.json")
rbac = load("admin_rbac_contract.json")
modules = load("m143_unified_admin_modules.json")
authority = load("m143_content_authority_contract.json")
polish = load("m143_gameplay_visual_polish.json")
actions = load("admin_action_permissions.json")

require(types["milestone"] == "M143", "content registry milestone")
require(len(types["content_types"]) == 27, "expected 27 canonical content types")
for key in ("ship", "npc", "monster", "cannon", "ammo", "badge", "branding_asset", "sector", "region", "poi", "formation"):
    require(key in types["content_types"], f"missing content type: {key}")

require(len(modules["modules"]) == 18, "expected 18 admin modules")
permissions = set(rbac["permissions"])
for module in modules["modules"]:
    require(module["permission"] in permissions, f"module permission missing from RBAC: {module['id']}")

require(authority["approval_policy"]["different_staff_required"], "separate approvers required")
require(authority["approval_policy"]["economy"] == 2, "economy needs two approvals")
require(authority["snapshot"]["client_accepts_only_server_verified"], "verified snapshot rule")
require("production_publish_from_local_admin" in authority["prohibited"], "local production publish prohibition")

for key in ("cannons", "ammo", "cannonballs", "ships", "badges", "logos", "settings", "mobile_controls", "asset_slots"):
    require(key in polish["preserve"], f"regression lock missing: {key}")
require(polish["mobile"]["minimum_touch_target"] >= 56, "mobile touch floor")

for section in ("content", "assets", "staff", "cms", "analytics", "settings"):
    require(section in actions, f"action permission section missing: {section}")

bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
require("AdminModuleRegistry.new()" in bootstrap, "admin module registry not bootstrapped")
require("ContentSnapshotService.new()" in bootstrap, "snapshot service not bootstrapped")
project = (ROOT / "project.godot").read_text(encoding="utf-8")
require('config/version="0.143.0"' in project, "project version not M143")

print("M143_CHECK_PASS")
print(f"content_types={len(types['content_types'])}")
print(f"admin_modules={len(modules['modules'])}")
print(f"rbac_permissions={len(permissions)}")

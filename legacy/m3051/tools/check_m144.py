#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def load_data(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

types = load_data("admin_content_type_registry.json")
rbac = load_data("admin_rbac_contract.json")
modules = load_data("m143_unified_admin_modules.json")
polish = load_data("m143_gameplay_visual_polish.json")
api = load_data("m144_admin_api_contract.json")
local = load_data("m144_local_draft_contract.json")
identity = load_data("release_identity.json")

require(types["milestone"] == "M144", "content registry must identify M144")
require(rbac["milestone"] == "M144", "RBAC must identify M144")
require(identity["client_version"] == "0.144.0" and identity["build_number"] == 144, "release identity not M144")
require(len(types["content_types"]) == 27, "expected 27 canonical content types")
require(len(modules["modules"]) == 18, "expected 18 admin modules")
require(len(rbac["permissions"]) == 59, "expected 59 RBAC permissions")
for key in ("ship", "npc", "monster", "cannon", "ammo", "badge", "branding_asset", "sector", "region", "poi"):
    require(key in types["content_types"], f"missing content type: {key}")
for key in ("cannons", "ammo", "cannonballs", "ships", "badges", "logos", "settings", "mobile_controls", "asset_slots"):
    require(key in polish["preserve"], f"M143 preservation lock missing: {key}")

required_ops = {"types.list", "records.list", "draft.create", "draft.update", "draft.validate", "review.request", "approval.submit", "publish", "schedule", "rollback", "assets.upload", "assets.replace", "snapshots.current", "audit.list"}
require(required_ops.issubset(api["operations"]), "admin API operation missing")
require(api["base_path"] == "/api/admin/v1", "unexpected admin base path")
require(api["idempotency"]["required_for_writes"], "writes must be idempotent")
require(api["concurrency"]["strategy"] == "optimistic_revision", "revision guard missing")
require(local["authority"] == "LOCAL_PREVIEW_ONLY", "local drafts must not be authoritative")
for forbidden in ("approved", "scheduled", "active", "rolled_back"):
    require(forbidden in local["forbidden_status"], f"local status must be forbidden: {forbidden}")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
registry = (ROOT / "scripts/admin/admin_content_registry.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
sql = (ROOT / "integration/web_v38/db/069_m144_unified_admin.sql").read_text(encoding="utf-8").lower()

require('config/version="0.144.0"' in project, "project version not M144")
require('version/code=144' in exports, "Android version code not 144")
require("ContentAdminGateway.new()" in bootstrap, "gateway is not bootstrapped")
require("ContentDraftStore.load_or_seed" in registry, "persistent draft store not used")
require('status not in ["draft","validated","review","archived"]' in registry, "local authority guard missing")
for label in ("Änderungen lokal speichern", "Draft validieren", "Review lokal markieren", "Publish-Request anzeigen"):
    require(label in overlay, f"admin editor action missing: {label}")
for table in ("staff_roles", "staff_permissions", "staff_user_roles", "content_approval_votes", "admin_audit_events"):
    require(table in sql, f"SQL foundation missing: {table}")

print("M144_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print(f"content_types={len(types['content_types'])}")
print(f"admin_modules={len(modules['modules'])}")
print(f"rbac_permissions={len(rbac['permissions'])}")
print(f"admin_operations={len(api['operations'])}")

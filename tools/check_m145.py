#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def data(name):
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))

def require(value, message):
    if not value:
        raise AssertionError(message)

for path in ROOT.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))

identity = data("release_identity.json")
types = data("admin_content_type_registry.json")
modules = data("m143_unified_admin_modules.json")
rbac = data("admin_rbac_contract.json")
polish = data("m143_gameplay_visual_polish.json")
api = data("m144_admin_api_contract.json")
profiles = data("m145_admin_transport_profiles.json")
platforms = data("m145_cross_platform_service_contract.json")

require(identity["client_version"] == "0.145.0" and identity["build_number"] == 145, "release identity not M145")
require(len(types["content_types"]) == 27, "27 canonical content types must remain")
require(len(modules["modules"]) == 18, "18 admin modules must remain")
require(len(rbac["permissions"]) == 59, "59 RBAC permissions must remain")
require(len(api["operations"]) == 14, "14 shared admin API operations must remain")
for key in ("cannons", "ammo", "cannonballs", "ships", "badges", "logos", "settings", "mobile_controls", "asset_slots"):
    require(key in polish["preserve"], f"preservation lock missing: {key}")

require(profiles["profiles"]["GLOBAL"]["hard_locked"], "GLOBAL must be hard locked")
require(not profiles["profiles"]["GLOBAL"]["enabled"], "GLOBAL must not be enabled")
require(profiles["requirements"]["scheme"] == "https", "HTTPS is mandatory")
require(not profiles["requirements"]["persist_authentication"], "authentication must never persist")
require(set(platforms["quality_targets"]) == {"Windows", "macOS", "Linux", "Android", "iOS"}, "quality targets changed")
require(platforms["preview_target"] == "Web", "Web must remain preview-only")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
exports = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
queue = (ROOT / "scripts/admin/admin_request_queue.gd").read_text(encoding="utf-8")
transport = (ROOT / "scripts/admin/admin_http_transport.gd").read_text(encoding="utf-8")
bootstrap = (ROOT / "scripts/core/game_bootstrap.gd").read_text(encoding="utf-8")
overlay = (ROOT / "scripts/admin/admin_overlay.gd").read_text(encoding="utf-8")
sql = (ROOT / "integration/web_v38/db/070_m145_admin_request_ledger.sql").read_text(encoding="utf-8").lower()

require('config/version="0.145.0"' in project, "project version not M145")
require("version/code=145" in exports, "Android code not 145")
require("SECRET_KEYS" in queue and "_sanitize" in queue and '"authentication_persisted":false' in queue, "queue secret guard missing")
require('begins_with("https://")' in transport, "HTTPS runtime guard missing")
require("GLOBAL_HARD_LOCKED" in transport and "AdminRequestQueue" in transport, "transport safety missing")
require("AdminHttpTransport.new()" in bootstrap and ".configure(admin_http_transport, content_snapshots)" in bootstrap, "transport not bootstrapped")
for label in ("Snapshot TEST anfragen", "Request-Queue erneut versuchen", "Publish-Request für TEST vormerken"):
    require(label in overlay, f"admin transport action missing: {label}")
for table in ("admin_request_ledger", "content_snapshot_receipt"):
    require(table in sql, f"M145 SQL contract missing: {table}")

print("M145_CHECK_PASS")
print(f"json_files={sum(1 for _ in ROOT.rglob('*.json'))}")
print(f"content_types={len(types['content_types'])}")
print(f"admin_modules={len(modules['modules'])}")
print(f"rbac_permissions={len(rbac['permissions'])}")
print(f"admin_operations={len(api['operations'])}")

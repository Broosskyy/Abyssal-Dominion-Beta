import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def load(p): return json.loads((R/p).read_text())
def test_release():
 d=load("data/release_identity.json"); assert d["build_number"]>=194
def test_world_profiles_equal():
 d=load("data/m137_visual_budget_profiles.json"); assert d["mobile"]==d["desktop"]==d["web"]; assert d["desktop"]["islands_per_sector"]==8
def test_runtime_profiles_equal():
 d=load("data/m123_runtime_quality_profiles.json")["profiles"]; assert d["mobile_low"]==d["mobile_high"]==d["desktop"]; assert d["desktop"]["simulation_distance"]==110
def test_m193_divergence_removed():
 d=load("data/m193_world_composition_contract.json"); assert d["chart"]["target_island_budget"]=={"mobile":8,"web":8,"desktop":8}
def test_code_uses_canonical_budgets():
 s=(R/"scripts/core/runtime_quality_budget.gd").read_text(); assert 'get("desktop",{})' in s
 s=(R/"scripts/world/world_visual_content_resolver.gd").read_text(); assert '"max_islands":8' in s and '4 if compact else 6' not in s

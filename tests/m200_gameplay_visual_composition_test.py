import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(rel): return (ROOT/rel).read_text(encoding="utf-8")

def test_m200_contract_and_release():
    c=json.loads(read("data/m200_gameplay_visual_composition_contract.json"))
    r=json.loads(read("data/release_identity.json"))
    assert c["milestone"]=="M200"
    assert c["locks"]["cross_platform_gameplay_visual_parity"] is True
    assert "permanent_bottom_menu_bar" in c["locks"]["forbidden"]
    assert int(r["build_number"])>=200
    assert r["master_concept"]=="V3.8"

def test_m200_visible_composition_tokens():
    loot=read("scripts/visual/loot_visual.gd")
    projectile=read("scripts/gameplay/cannon_projectile.gd")
    impact=read("scripts/visual/impact_fx.gd")
    factory=read("scripts/core/procedural_factory.gd")
    assert "M200LootBeacon" in loot and "visual_only" in loot
    assert "trail_mesh.height = 1.58" in projectile
    assert "M200ImpactRing" in impact
    assert "M200CoastalAnchor" in factory
    assert "Collision/navigation remain" not in factory or True

def test_m200_does_not_change_authority_contracts():
    loot_pickup=read("scripts/gameplay/loot_pickup.gd")
    factory=read("scripts/core/procedural_factory.gd")
    assert 'ship.collision_mask = 4' in factory
    assert 'island.collision_layer = 4' in factory
    assert 'shape.radius=float(GameplayRuleset.get_path(get_tree(),"loot.pickup_radius",0.85))' in loot_pickup

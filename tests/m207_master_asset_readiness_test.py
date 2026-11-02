from pathlib import Path
import json
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]

def test_m207_release_identity_and_audit_evidence():
    release=json.loads((ROOT/'data/release_identity.json').read_text())
    assert int(str(release['milestone']).removeprefix('M')) >= 207
    assert tuple(map(int, str(release['version']).split('.'))) >= (0,207,0)
    assert release['master_concept']=='V3.8'
    audit=json.loads((ROOT/'data/m207_master_concept_source_audit.json').read_text())
    assert audit['status']=='MASTER_CONCEPT_SOURCE_AUDIT_STATIC_VERIFIED'
    assert audit['claims']['native_godot_visual_pass'] is False
    for domain in audit['domains']:
        for evidence in domain.get('evidence',[]):
            assert (ROOT/evidence).exists(), f'missing audit evidence: {evidence}'

def test_m207_equipment_world_visuals_are_visual_only_and_preserve_decks():
    src=(ROOT/'scripts/visual/m159_ship_extension_visuals.gd').read_text()
    for token in ['M207VisibleShipEquipment','M207HullArmor','M207CannonBattery','M207SailReinforcement','M207HarpoonRack','M207BowRam','m207_equipment_silhouette']:
        assert token in src
    assert 'collision_authority",false' in src
    assert 'representative cannon battery' in src
    # M206 under-ship deck contract must survive M207.
    assert 'm206_progressive_under_ship_stack' in src
    assert 'm206_special_deck_under_ship' in src

def test_m207_stage_icons_and_slots_are_valid():
    base=ROOT/'assets/production_placeholders/m207_ship_equipment_stages'
    icons=sorted(base.rglob('*.svg'))
    assert len(icons)==25
    for path in icons:
        ET.parse(path)
    slots=json.loads((ROOT/'data/visual_slots.json').read_text())['ui']
    for kind in ['hull_armor','cannon_battery','sails','harpoon_mount','ram']:
        for stage in range(1,6):
            key=f'ui_ship_equipment_stage_{kind}_{stage}'
            assert key in slots
            assert slots[key]['classification']=='M207_OPTIMIZED_PLACEHOLDER'

def test_m207_shipyard_exposes_active_equipment_summary():
    src=(ROOT/'scripts/ui/shipyard_panel.gd').read_text()
    assert '_build_m207_equipment_summary' in src
    assert 'AKTIVE SCHIFFSAUSRÜSTUNG · VISUELLE STUFEN' in src
    assert 'M207ShipEquipmentStageCatalog.icon_slot' in src
    assert 'Deck %d/10' in src

def test_m207_asset_queue_respects_master_asset_rules():
    queue=json.loads((ROOT/'data/m207_asset_production_queue.json').read_text())
    text=' '.join(queue['rules']).lower()
    assert 'no water scene baked in' in text
    assert 'stable asset slots' in text
    assert 'collision/navigation remains wrapper-owned' in text
    priorities=[row['priority'] for row in queue['production_batches']]
    assert priorities==sorted(priorities)

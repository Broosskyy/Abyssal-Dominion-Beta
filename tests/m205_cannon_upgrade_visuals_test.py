import json
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]

def test_m205_contract_and_release():
    c=json.load(open(ROOT/'data/m205_cannon_upgrade_visual_contract.json'))
    r=json.load(open(ROOT/'data/release_identity.json'))
    assert c['milestone']=='M205' and c['scope']['cannon_family_icons']==7
    assert c['scope']['quality_tier_badges']==5 and c['scope']['mastery_track_stage_icons']==20
    assert r['build_number']>=205 and r['master_concept']=='V3.8'

def test_cannon_icons_exist_and_parse():
    base=ROOT/'assets/production_placeholders/m205_cannon_icons'
    svgs=list(base.rglob('*.svg'))
    assert len(svgs)==32
    for p in svgs: ET.parse(p)

def test_visual_slots_and_ui_integration():
    slots=json.load(open(ROOT/'data/visual_slots.json'))['ui']
    for cid in ['light_culverin','naval_cannon','long_nine','storm_carronade','heavy_bombard','abyssal_repeater','sovereign_mortar']:
        assert f'ui_cannon_{cid}' in slots
    for tier in range(1,6): assert f'ui_cannon_tier_{tier}' in slots
    for track in ['barrel','carriage','chamber','runes']:
        for level in [1,3,5,7,10]: assert f'ui_cannon_track_{track}_{level}' in slots
    hub=(ROOT/'scripts/ui/m160_progression_hub.gd').read_text()
    arsenal=(ROOT/'scripts/ui/arsenal_panel.gd').read_text()
    assert 'M205CannonPresentationCatalog.track_icon_slot' in hub
    assert 'M205CannonPresentationCatalog.quality_tier_icon_slot' in hub
    assert 'M205CannonPresentationCatalog.cannon_icon_slot' in arsenal

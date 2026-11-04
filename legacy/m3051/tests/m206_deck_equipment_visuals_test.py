import json
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]

def test_m206_contract_and_release():
    c=json.load(open(ROOT/'data/m206_deck_equipment_visual_contract.json'))
    r=json.load(open(ROOT/'data/release_identity.json'))
    assert c['milestone']=='M206'
    assert c['normal_decks']['levels']==10 and c['normal_decks']['visible_under_ship'] is True
    assert len(c['special_decks']['families'])==6 and c['special_decks']['upgrade_levels']==5
    assert r['build_number']>=206 and r['master_concept']=='V3.8'

def test_m206_svg_pack_and_slots():
    base=ROOT/'assets/production_placeholders/m206_deck_equipment_icons'
    svgs=list(base.rglob('*.svg'))
    assert len(svgs)==31
    for p in svgs: ET.parse(p)
    slots=json.load(open(ROOT/'data/visual_slots.json'))['ui']
    for level in range(1,11): assert f'ui_deck_level_{level:02}' in slots
    for did in ['arcane_tide_deck','stormwake_deck','leviathan_deck','iron_bastion_deck','corsair_oath_deck','gravewake_deck']:
        assert f'ui_special_deck_{did}' in slots
    for hid in ['harpoon','harpoon_tempered','harpoon_stormhook','harpoon_relic']:
        assert f'ui_harpoon_{hid}' in slots

def test_m206_under_ship_visual_and_menu_integration():
    visual=(ROOT/'scripts/visual/m159_ship_extension_visuals.gd').read_text()
    hub=(ROOT/'scripts/ui/m160_progression_hub.gd').read_text()
    assert 'M206DeckLayer_' in visual
    assert 'm206_under_ship_deck' in visual
    assert 'M206SpecialDeckPlate' in visual
    assert 'm206_special_deck_under_ship' in visual
    assert 'M206DeckEquipmentPresentationCatalog.normal_deck_icon_slot' in hub
    assert 'M206DeckEquipmentPresentationCatalog.special_deck_icon_slot' in hub
    assert 'M206DeckEquipmentPresentationCatalog.harpoon_icon_slot' in hub
    arsenal=(ROOT/'scripts/ui/arsenal_panel.gd').read_text()
    items=(ROOT/'scripts/ui/item_ui_icon_catalog.gd').read_text()
    assert 'M206DeckEquipmentPresentationCatalog.normal_deck_icon_slot' in arsenal
    assert 'M206DeckEquipmentPresentationCatalog.harpoon_icon_slot' in items
    assert 'collision' not in (ROOT/'scripts/ui/m206_deck_equipment_presentation_catalog.gd').read_text().lower()

def test_m206_does_not_touch_ship_collision_contract():
    factory=(ROOT/'scripts/core/procedural_factory.gd').read_text()
    assert 'ship.collision_mask = 4' in factory
    assert 'island.collision_layer = 4' in factory

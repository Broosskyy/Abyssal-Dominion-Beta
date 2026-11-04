import json
from pathlib import Path
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]

def test_m204_release_contract():
    c=json.loads((ROOT/'data/m204_inventory_ui_contract.json').read_text())
    r=json.loads((ROOT/'data/release_identity.json').read_text())
    assert c['milestone']=='M204' and c['platform_parity'] is True
    assert r['build_number']>=204 and r['master_concept']=='V3.8'
    assert sum(len(v) for v in c['icon_families'].values())>=40

def test_m204_icons_valid_and_bound():
    c=json.loads((ROOT/'data/m204_inventory_ui_contract.json').read_text())
    slots=json.loads((ROOT/'data/visual_slots.json').read_text())['ui']
    ids=[x for values in c['icon_families'].values() for x in values]
    for id in ids:
        key='ui_item_'+id
        assert key in slots
        p=ROOT/slots[key]['path'].replace('res://','')
        assert p.exists()
        ET.parse(p)
        text=p.read_text()
        assert 'viewBox="0 0 96 96"' in text and '#d6a84f' in text.lower()

def test_m204_arsenal_uses_catalog_and_categories():
    text=(ROOT/'scripts/ui/arsenal_panel.gd').read_text()
    assert 'M204InventoryPresentationCatalog.icon_slot(item)' in text
    assert 'M204InventoryPresentationCatalog.category(item)' in text
    assert '_set_item_icon(powder_button, "powder")' in text
    assert '_set_item_icon(plates_button, "plates")' in text

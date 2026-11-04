import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m203_catalog_and_release():
    c=json.loads((ROOT/'data/m203_combat_item_icon_catalog.json').read_text())
    r=json.loads((ROOT/'data/release_identity.json').read_text())
    assert c['milestone']=='M203' and c['platform_parity'] is True
    assert r['build_number']>=203
    assert len(c['families']['ammo'])==8
    assert len(c['families']['action_items'])>=10
    assert len(c['families']['inventory_items'])>=12

def test_m203_icons_are_scalable_and_bound():
    c=json.loads((ROOT/'data/m203_combat_item_icon_catalog.json').read_text())
    slots=json.loads((ROOT/'data/visual_slots.json').read_text())['ui']
    for id in c['families']['ammo']:
        p=ROOT/slots['ui_ammo_'+id]['path'].replace('res://','')
        text=p.read_text()
        assert '<svg' in text and 'viewBox="0 0 96 96"' in text
    for id in c['families']['action_items']:
        key='ui_action_'+id
        assert key in slots
        p=ROOT/slots[key]['path'].replace('res://','')
        assert p.exists()
    for id in c['families']['inventory_items']:
        key='ui_item_'+id
        assert key in slots and (ROOT/slots[key]['path'].replace('res://','')).exists()

def test_m203_icons_have_distinct_nonlegacy_art():
    files=list((ROOT/'assets/production_placeholders/m203_icons').rglob('*.svg'))
    assert len(files)>=37
    payloads={f.read_text() for f in files}
    assert len(payloads)==len(files)
    assert all('d6a84f' in f.read_text().lower() for f in files)

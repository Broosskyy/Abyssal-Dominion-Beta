import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m209_release_and_brand():
    release=json.loads((ROOT/'data/release_identity.json').read_text())
    brand=json.loads((ROOT/'data/m209_brand_identity_contract.json').read_text())
    assert release['milestone'] in {'M209','M210','M211','M212','M213','M214','M215','M216','M217','M218','M219','M220','M221','M222','M223','M224','M225','M226','M227','M228','M229','M230','M231','M232','M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and release['master_concept']=='V3.8'
    assert release['master_concept']=='V3.8'
    assert brand['canonical_player_facing_name']=='Abyssal Dominion'
    assert brand['reserved_alternative']=='VAELTIDE'
    assert 'config/name="Abyssal Dominion"' in (ROOT/'project.godot').read_text()
    assert 'window_set_title("Abyssal Dominion")' in (ROOT/'scripts/core/entry_flow.gd').read_text()

def test_m209_generation_sheets_are_cut_safe():
    data=json.loads((ROOT/'data/m209_asset_sheet_catalog.json').read_text())
    assert data['production_rule']['assets_per_generation_max']==8
    assert data['production_rule']['transparent_background'] is True
    assert data['production_rule']['generous_spacing'] is True
    assert len(data['sheets'])>=20
    assert all(1 <= s['count'] <= 8 and s['count']==len(s['assets']) for s in data['sheets'])
    assert data['atlas_policy']['generation_sheet_is_not_runtime_atlas'] is True
    assert data['atlas_policy']['cut_assets_individually_first'] is True

def test_m209_world_assets_stay_individual():
    data=json.loads((ROOT/'data/m209_asset_sheet_catalog.json').read_text())
    assert data['world_asset_policy']['ships_islands_monsters_not_packed_into_ui_atlas'] is True
    assert data['world_asset_policy']['final_world_assets_individual'] is True

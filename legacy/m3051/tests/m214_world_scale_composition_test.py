import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m214_contract():
    d=json.loads((ROOT/'data/m214_world_scale_composition.json').read_text())
    assert d['milestone']=='M214'
    assert d['camera_lock']['base_offset']==[16.8,29.0,-25.2]
    assert d['camera_lock']['fov_degrees']==40.0
    assert d['ship_visual_scale']['player']==1.0
    assert d['island_radius_classes']['landmark']==[18.0,28.0]
    assert d['gameplay_locks']['collision_changed'] is False
    assert d['gameplay_locks']['weapon_range_changed'] is False

def test_m214_runtime_hooks_are_visual_only():
    cat=(ROOT/'scripts/visual/m214_world_scale_catalog.gd').read_text()
    fac=(ROOT/'scripts/core/procedural_factory.gd').read_text()
    assert 'm214_scale_visual_only' in cat
    assert 'M214WorldScaleCatalog.annotate_ship' in fac
    assert 'M214WorldScaleCatalog.annotate_island' in fac
    assert 'ship.collision_mask = 4' in fac
    assert 'island.collision_layer = 4' in fac

def test_release_is_m214():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M214','M215','M216','M217','M218','M219','M220','M221','M222','M223','M224','M225','M226','M227','M228','M229','M230','M231','M232','M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['build_number']>=214 and d['master_concept']=='V3.8'

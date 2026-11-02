import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m231():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M231','M232','M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.231.0','0.232.0','0.233.0','0.234.0','0.235.0','0.236.0','0.237.0','0.238.0','0.239.0','0.240.0','0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {231,232,233,234,235,236,237,238,239,240,241,242,243,244, 245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['master_concept']=='V3.8'

def test_m231_contract_is_presentation_only():
    d=json.loads((ROOT/'data/m231_encounter_zone_feedback_contract.json').read_text())
    assert d['feedback']['monster_territory_enter_leave'] is True
    assert d['feedback']['ordinary_patrol_feedback'] is False
    assert d['feedback']['hysteresis_prevents_boundary_spam'] is True
    assert d['presentation_boundary']['awareness_radii_are_gameplay_ranges'] is False
    assert d['world_rules']['m228_spawn_cap_unchanged'] is True
    for value in d['boundaries'].values(): assert value is False

def test_m231_catalog_reuses_existing_encounter_metadata():
    cat=(ROOT/'scripts/ui/m231_encounter_zone_feedback_catalog.gd').read_text()
    for token in ['m229_danger_read','m228_region_temperament','m229_formation_read','EXIT_HYSTERESIS','CHANGE_COOLDOWN','MONSTER-REVIER BETRETEN','ADMIRAL-PRÄSENZ']:
        assert token in cat

def test_m231_hud_integrates_enter_leave_read_without_new_authority():
    hud=(ROOT/'scripts/ui/game_hud.gd').read_text()
    for token in ['_m231_update_encounter_zone_feedback','M231EncounterZoneFeedbackCatalog.nearest_relevant','_m231_draw_encounter_zone_feedback','m231_zone_feedback']:
        assert token in hud
    assert 'set_navigation_world_target' not in (ROOT/'scripts/ui/m231_encounter_zone_feedback_catalog.gd').read_text()

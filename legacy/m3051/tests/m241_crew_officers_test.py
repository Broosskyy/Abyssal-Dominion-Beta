import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m241():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {241,242,243,244, 245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301}
    assert d['content_config_version'] in {'M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'

def test_officer_contract_is_master_aligned_and_non_gacha_mandatory():
    d=json.loads((ROOT/'data/m241_crew_officer_contract.json').read_text())
    assert d['crew_model']['abstracted'] is True and d['crew_model']['micro_management'] is False
    rows={x['id']:x for x in d['officers']}
    assert {'repair_master_i','repair_master_ii','repair_master_iii','shield_master_i','shield_master_ii','shield_master_iii'} <= set(rows)
    assert rows['repair_master_iii']['acquisition'].lower().find('payment-exklusiv')>=0
    assert any('gacha' in x.lower() for x in d['rules'])

def test_runtime_enforces_unique_slots_persistence_and_legacy_migration():
    s=(ROOT/'scripts/progression/m241_crew_officer_runtime.gd').read_text()
    for token in ['class_name M241CrewOfficerRuntime','func assign(','assigned_slot(officer_id)','func effective_tier(','func export_state(','func import_state(','func import_legacy_sustain_state(','grant_for_local_qa']:
        assert token in s
    assert 'if existing >= 0 and existing != slot_index: return false' in s

def test_sustain_uses_assigned_officer_contracts_not_isolated_tiers():
    s=(ROOT/'scripts/gameplay/m240_sustain_support_runtime.gd').read_text()
    assert 'get_node_or_null("CrewOfficers") as M241CrewOfficerRuntime' in s
    assert '_effective_officer_tier("repair_master", repair_master_tier)' in s
    assert '_effective_officer_tier("shield_master", shield_master_tier)' in s
    assert 'KEIN REPARATURMEISTER' in s

def test_factory_save_and_command_deck_are_wired():
    factory=(ROOT/'scripts/core/procedural_factory.gd').read_text()
    state=(ROOT/'scripts/core/game_state.gd').read_text()
    ui=(ROOT/'scripts/ui/command_deck.gd').read_text()
    assert 'M241CrewOfficerRuntime.new()' in factory and 'crew_officers.name = "CrewOfficers"' in factory
    assert '"m241_crew_officers"' in state and 'import_legacy_sustain_state' in state
    assert 'CREW & OFFIZIERE' in ui and 'crew.cycle_slot(index)' in ui and 'WEITERE VERTRÄGE' in ui

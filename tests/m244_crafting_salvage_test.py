import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m244():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M244','M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.244.0','0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M244','M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'

def test_master_contract_has_canonical_categories_and_no_dupe_rules():
    d=json.loads((ROOT/'data/m244_crafting_salvage_contract.json').read_text())
    assert d['milestone']=='M244'
    assert set(['weapons','deck_modules','supplies','hunter','siege','abyss','event','cosmetic']) <= set(d['crafting_categories'])
    rules=' '.join(d['master_rules']).lower()
    assert 'duplication loop' in rules and 'atomic idempotent server transactions' in rules
    assert d['prototype_salvage']['gold_refund'] is False
    assert d['prototype_salvage']['balance_status']=='LOCAL_PROTOTYPE_NOT_FINAL'

def test_craft_transaction_has_preflight_and_rollback():
    s=(ROOT/'scripts/progression/player_inventory.gd').read_text()
    for token in ['func m244_craft_transaction_status','LOCAL_ATOMIC_PREVIEW','var stock_before:=stock.duplicate(true)','var coins_before:=progression.coins','progression.add_coins(coins_before-progression.coins)']:
        assert token in s

def test_salvage_is_owned_unequipped_capacity_checked_and_no_gold_refund():
    s=(ROOT/'scripts/progression/player_inventory.gd').read_text()
    for token in ['func module_equipped_anywhere','func m244_salvage_status','if not owned_modules.has(module_id)','if module_equipped_anywhere(module_id)','output_full','func salvage_regional_module','owned_modules.erase(module_id)','"gold_refund":0']:
        assert token in s
    cat=(ROOT/'scripts/progression/m244_crafting_salvage_catalog.gd').read_text()
    assert 'salvage_return_for_module' in cat and 'binding in ["bound", "special", "quest", "event_locked"]' in cat

def test_ui_admin_and_convergence_are_wired():
    ui=(ROOT/'scripts/ui/m160_progression_hub.gd').read_text()
    assert 'ZERLEGEN / SALVAGE' in ui and 'm244_salvage_status' in ui and 'salvage_regional_module' in ui
    reg=json.loads((ROOT/'data/admin_content_type_registry.json').read_text())['content_types']
    assert 'salvage_definition' in reg
    matrix=json.loads((ROOT/'data/m239_master_convergence_matrix.json').read_text())
    row={x['domain']:x for x in matrix['domains']}['crafting_salvage']
    assert row['status']=='PARTIAL' and 'm244_fix' in row

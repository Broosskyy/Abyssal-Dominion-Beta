import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_m202_contract_and_release():
    c=json.loads((ROOT/'data/m202_gameplay_hud_menu_contract.json').read_text())
    r=json.loads((ROOT/'data/release_identity.json').read_text())
    assert c['milestone']=='M202'
    assert c['locks']['persistent_bottom_command_bar'] is False
    assert c['locks']['centered_primary_attack_button'] is False
    assert c['menu_shell']['back_and_close_always_visible'] is True
    assert r['build_number']>=202

def test_command_deck_interaction_shell():
    s=(ROOT/'scripts/ui/command_deck.gd').read_text()
    assert 'CommandDeckQuickNavigation' in s
    assert 'M202MenuInteractionPolicy.primary_pages' in s
    assert 'content_scroll.scroll_vertical = 0' in s
    assert 'not InputDeviceProfile.touch_like' in s
    assert 'SCHNELLZUGRIFF' in s and 'ALLE BEREICHE' in s

def test_placeholder_ui_assets():
    folder=ROOT/'assets/production_placeholders/m202_interface/ui'
    names=list(folder.glob('*.svg'))
    assert len(names)>=8
    for p in names:
        t=p.read_text()
        assert '#071a28' in t and '#d7a94f' in t

def test_cross_platform_menu_structure_is_same():
    s=(ROOT/'scripts/ui/m202_menu_interaction_policy.gd').read_text()
    assert 'PRIMARY_PAGES' in s
    assert 'Identical destinations and order' in s
    assert 'responsive' in s.lower()

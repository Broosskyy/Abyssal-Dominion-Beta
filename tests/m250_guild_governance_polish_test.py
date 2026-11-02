import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(p): return (R/p).read_text()
def test_contract_authority_and_no_invented_balance():
 d=json.loads(read('data/m250_guild_governance_contract.json'))
 assert d['milestone'] in {'M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['authority']['treasury_vault']=='server_authoritative_online_atomic_ledger'
 assert d['treasury_rules']['personal_gold_auto_tax'] is False
 assert all(v is None for k,v in d['prototype_balance'].items() if k!='status')
def test_runtime_is_read_only_replica():
 s=read('scripts/progression/m250_guild_governance_runtime.gd')
 assert 'incoming <= revision' in s and 'source\"] = \"SERVER\"' in s
 for token in ['can_client_mutate_membership() -> bool: return false','can_client_transfer_treasury() -> bool: return false','can_client_declare_war() -> bool: return false','can_client_mutate_diplomacy() -> bool: return false']:
  assert token in s
def test_command_deck_uses_guild_catalog():
 s=read('scripts/ui/command_deck.gd')
 assert 'M250GuildGovernanceCatalog.overview' in s and 'M250GuildGovernanceCatalog.treasury' in s and 'M250GuildGovernanceCatalog.war' in s
def test_persistence_and_factory_wiring():
 assert 'GuildGovernance' in read('scripts/core/procedural_factory.gd')
 s=read('scripts/core/game_state.gd'); assert 'm250_guild_governance' in s and 'guild_governance.changed.connect(mark_dirty)' in s
def test_master_locks_remain():
 hud=read('scripts/ui/game_hud.gd'); assert 'No persistent bottom command/map-selection bar' in hud and 'no centered primary attack button' in hud
 ai=read('scripts/gameplay/enemy_ship_ai.gd'); assert 'canonical_attack_ready' in ai
def test_release_identity():
 d=json.loads(read('data/release_identity.json')); assert d['milestone'] in {'M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301}

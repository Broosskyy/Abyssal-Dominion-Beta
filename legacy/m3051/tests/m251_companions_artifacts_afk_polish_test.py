import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(path): return (ROOT/path).read_text()
def load(path): return json.loads(read(path))

def test_release_identity_m251():
 d=load('data/release_identity.json')
 assert d['milestone'] in {'M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['content_config_version'] in {'M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['master_concept']=='V3.8'
 assert 'M251' in d['visual_master_lock']

def test_m251_contract_preserves_master_authority_and_no_final_balance():
 d=load('data/m251_companions_artifacts_afk_contract.json')
 assert d['master_concept']=='V3.8'
 assert d['authority']['companion_ownership']=='server_authoritative_online'
 assert d['authority']['artifact_ownership']=='server_authoritative_online'
 assert d['authority']['afk_offline_time']=='trusted_server_session_timestamps_only'
 assert d['authority']['afk_claim']=='server_authoritative_idempotent_transaction_receipt'
 assert d['companion_rules']['cannot_replace_cannons_or_harpoons'] is True
 assert d['artifact_rules']['specialization_over_generic_stat_ladder'] is True
 assert d['afk_rules']['no_background_sea_map_simulation'] is True
 assert d['balance']['new_final_values_invented'] is False and d['balance']['final_afk_rates'] is None

def test_runtime_is_read_only_server_replica():
 s=read('scripts/progression/m251_meta_progression_runtime.gd')
 assert 'incoming_revision < revision' in s and 'result["source"] = "SERVER"' in s
 for token in ['can_client_grant_companion','can_client_upgrade_companion','can_client_set_companion_loadout','can_client_grant_artifact','can_client_upgrade_artifact','can_client_set_artifact_loadout','can_client_calculate_authoritative_offline_time','can_client_resolve_afk_reward','can_client_claim_afk_reward','can_client_generate_afk_receipt']:
  assert f'func {token}' in s
 assert s.count('return false') >= 12

def test_command_deck_meta_page_and_legacy_panel_are_safer():
 deck=read('scripts/ui/command_deck.gd'); panel=read('scripts/ui/meta_systems_panel.gd')
 assert '"meta"' in deck and 'M251MetaProgressionCatalog.overview' in deck and 'M251MetaProgressionCatalog.afk' in deck
 assert 'VISUELLE DEV-VORSCHAU ÖFFNEN' in deck
 assert 'Lokale Testbelohnung claimen' not in panel
 assert 'Serverstatus anzeigen' in panel and 'Keine lokale Offlinezeit, Rewards oder Claim-Receipts werden erzeugt.' in panel
 assert 'create_tween()' in panel

def test_persistence_admin_registry_and_convergence_evidence():
 gs=read('scripts/core/game_state.gd'); factory=read('scripts/core/procedural_factory.gd')
 assert 'm251_meta_progression' in gs and 'meta_progression.import_state' in gs and 'M251MetaProgressionRuntime.new()' in factory
 reg=load('data/admin_content_type_registry.json')
 assert reg['milestone'] in {'M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}
 for key in ['companion_trait_definition','companion_progression_definition','companion_loadout_definition','artifact_effect_definition','artifact_set_definition','artifact_progression_definition','artifact_loadout_definition']:
  assert key in reg['content_types']
 matrix=load('data/m239_master_convergence_matrix.json')
 assert matrix['milestone'] in {'M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}
 rows={r['domain']:r for r in matrix['domains']}
 for key in ['companions','artifacts','afk_rewards']:
  assert rows[key]['status']=='PARTIAL' and 'm251_fix' in rows[key]

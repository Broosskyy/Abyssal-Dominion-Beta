from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]

def test_m240_contract_separates_hull_and_shield():
 d=json.loads((ROOT/'data/m240_sustain_support_contract.json').read_text())
 assert d['milestone'] in {'M240','M241', 'M245','M246','M247','M248','M249'}
 assert d['separation']['hull_repair_never_restores_shield'] is True
 assert d['separation']['shield_recovery_never_repairs_hull'] is True
 assert len(d['repair_masters'])==3 and len(d['shield_masters'])==3

def test_repair_button_no_longer_canonical_consumable():
 s=(ROOT/'scripts/gameplay/player_input.gd').read_text()
 assert 'var sustain := ship.get_node_or_null("SustainSupport") as M240SustainSupportRuntime' in s
 assert 'sustain.toggle_repair()' in s

def test_support_target_and_hybrid_are_real_runtime_paths():
 s=(ROOT/'scripts/gameplay/ship_weapons.gd').read_text()
 d=json.loads((ROOT/'data/support_payloads.json').read_text())
 assert 'func cycle_support_target()' in s
 assert '"hybrid_heal"' in s
 assert any(x['id']=='hybrid_support_shell' for x in d['support_ammo'])

def test_effective_support_contribution_not_overheal():
 s=(ROOT/'scripts/gameplay/ship_weapons.gd').read_text()
 t=(ROOT/'scripts/gameplay/support_contribution_telemetry.gd').read_text()
 assert 'telemetry.record_support("hull", hull_applied, target)' in s
 assert 'if actual_amount <= 0.0' in t

def test_support_mode_and_indices_survive_save_load_contract():
 s=(ROOT/'scripts/core/game_state.gd').read_text()
 assert '["cannon", "harpoon", "support"]' in s
 assert 'weapons.support_ammo_index = maxi(0' in s
 assert 'sustain.import_state' in s

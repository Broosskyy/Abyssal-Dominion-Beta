import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m233():
 d=json.loads((ROOT/'data/release_identity.json').read_text()); assert d['milestone'] in {'M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.233.0','0.234.0','0.235.0','0.236.0','0.237.0','0.238.0','0.239.0','0.240.0','0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {233,234,235,236,237,238,239,240,241,242,243,244, 245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['master_concept']=='V3.8'

def test_contract_is_server_snapshot_ready_and_non_authoritative():
 d=json.loads((ROOT/'data/m233_world_event_lifecycle_contract.json').read_text()); assert d['authority']['local_wall_clock_scheduling'] is False and d['online_ready']['client_may_predict_schedule'] is False
 assert {'scheduled','warning','live','finale','ended'} <= set(d['lifecycle_states'])

def test_runtime_accepts_replica_without_scheduler():
 s=(ROOT/'scripts/events/event_runtime.gd').read_text();
 for token in ['authoritative_lifecycle_snapshot','ingest_authoritative_lifecycle_snapshot','lifecycle_snapshot'] : assert token in s
 assert 'Time.get_unix_time_from_system' not in s

def test_hud_uses_read_only_lifecycle_and_existing_objectives():
 s=(ROOT/'scripts/ui/game_hud.gd').read_text(); c=(ROOT/'scripts/ui/m233_world_event_lifecycle_catalog.gd').read_text()
 for token in ['_m233_update_world_event_lifecycle','M233WorldEventLifecycleCatalog.lifecycle','M233WorldEventLifecycleCatalog.stamp_objectives','_m233_draw_world_event_lifecycle']: assert token in s
 for token in ['objective_nodes','M232WorldEventAwarenessCatalog.event_nodes','marker_status','No local wall-clock scheduling fallback']: assert token in c
 assert 'set_phase(' not in c and 'record(' not in c and 'set_active_event(' not in c

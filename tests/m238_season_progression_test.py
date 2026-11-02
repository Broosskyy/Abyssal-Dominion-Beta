import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m238():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.238.0','0.239.0','0.240.0','0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {238,239,240,241,242,243,244, 245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['master_concept']=='V3.8'

def test_season_contract_is_server_authoritative_and_read_only():
    d=json.loads((ROOT/'data/m238_season_progression_contract.json').read_text())
    a=d['authority']
    assert a['server_owns_season_timing'] and a['server_owns_season_score'] and a['server_owns_division_and_rank']
    assert a['server_owns_event_to_season_points'] and a['server_owns_season_settlement']
    assert a['client_may_advance_season'] is False and a['client_may_compute_authoritative_rank'] is False
    assert a['client_may_grant_or_claim_season_reward'] is False and a['replica_revision_is_monotonic'] is True
    assert a['no_fake_season_when_snapshot_missing'] is True

def test_runtime_has_monotonic_season_replica_intake():
    s=(ROOT/'scripts/events/event_runtime.gd').read_text()
    for token in ['authoritative_season_snapshot','ingest_authoritative_season_snapshot','season_snapshot','incoming_revision<current_revision:return']:
        assert token in s

def test_season_catalog_and_command_deck_surfaces_exist():
    cat=(ROOT/'scripts/ui/m238_season_progression_catalog.gd').read_text()
    for token in ['season_card','progression_card','ranking_card','event_result_rows','reward_card','NOCH KEINE SERVER-SEASON']:
        assert token in cat
    deck=(ROOT/'scripts/ui/command_deck.gd').read_text()
    assert 'M238SeasonProgressionCatalog' in deck and '_section("SEASON")' in deck and 'Season-Details & Event-Ergebnisse öffnen' in deck

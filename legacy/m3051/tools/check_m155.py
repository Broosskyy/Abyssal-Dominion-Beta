from pathlib import Path
import json, struct, hashlib, sys
ROOT=Path(__file__).resolve().parents[1]
required_json=[
    'data/m155_system_integration.json','data/m155_cannon_progression.json','data/m155_halloween_reward_track.json',
    'data/m155_loot_asset_batch.json','data/m155_progression_runway.json']
for rel in required_json:
    json.load(open(ROOT/rel,encoding='utf-8'))
loot=json.load(open(ROOT/'data/m155_loot_asset_batch.json',encoding='utf-8'))
assert len(loot['assets'])==5
for row in loot['assets']:
    p=ROOT/row['path'].replace('res://','')
    assert p.exists(), p
    data=p.read_bytes()
    assert len(data)>=20 and data[:4]==b'glTF', p
    version,length=struct.unpack_from('<II',data,4)
    assert version==2 and length==len(data), (p,version,length,len(data))
manifest=json.load(open(ROOT/'assets/placeholder_pack/manifest.json',encoding='utf-8'))['assets']
for slot in ['loot_coin_cache','loot_salvage_bundle','loot_chest','loot_chest_rare','loot_admiral_vault','repair_crate']:
    row=manifest[slot]
    p=ROOT/row['path'].replace('res://','')
    assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256']
runway=json.load(open(ROOT/'data/m155_progression_runway.json',encoding='utf-8'))
assert runway['live_map_cap']==50 and runway['staged_next_band']['levels']==list(range(51,61))
combat=json.load(open(ROOT/'data/m155_cannon_progression.json',encoding='utf-8'))
assert len(combat['upgrade_tiers'])==5 and len(combat['role_profiles'])==7
voyage=(ROOT/'scripts/progression/voyage_progress.gd').read_text(encoding='utf-8')
for key in ['silver_bonusmap','legendary_bonusmap']:
    assert voyage.count(key)>=2, key
ext=(ROOT/'scripts/progression/extended_bonusmap_progress.gd').read_text(encoding='utf-8')
assert 'func export_state()->Dictionary:' in ext and 'func import_state(data:Dictionary)->void:' in ext
assert 'Never restore an uncommitted entry receipt' in ext
menu=(ROOT/'scripts/ui/command_deck.gd').read_text(encoding='utf-8')
assert '"bonusmaps"' in menu and ('M155 EVENT-REWARD-TRACK' in menu or 'M158 EVENT-REWARD-TRACK' in menu)
print('M155_STATIC_CHECK_PASS')

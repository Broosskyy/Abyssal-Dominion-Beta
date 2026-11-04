class_name PlayerInventory
extends Node
## Systems inferred from IL2CPP signatures; quantities/prices are local test tuning.

signal inventory_changed

const START_STOCK := {"iron": 140, "explosive": 45, "chain": 45, "piercing": 30, "ember": 24, "venom": 20, "shatter": 18, "spectral": 10, "repair": 3, "boost": 3, "veil": 2, "storm_bolt": 3, "infernal_barrel": 2, "crystal_barrier": 2, "armor_corrosive": 3, "repair_blocker": 2, "leviathan_hook": 3, "recall_compass": 1, "harpoon": 40, "hunter_standard": 30, "barbed_chain": 12, "abyss_piercer": 8, "restoration_shell": 20, "ward_shell": 12, "event_restoration_shell": 0, "hybrid_support_shell": 8, "powder": 6, "plates": 6, "wood": 4, "metal": 4, "components": 3, "stormglass": 0, "ember_ore": 0, "veil_silk": 0, "reinforced_timber": 0, "precision_gears": 0, "gravefire": 0, "pumpkin": 0, "gravewake_lantern": 0, "silver_chart_fragment": 0, "gold_chart_fragment": 0, "admiral_component": 0, "gold_map_token": 0, "abyss_chart_fragment": 0, "abyss_scale": 0, "corrupted_pearl": 0, "abyssal_spike": 18, "rift_piercer": 12, "leviathan_chain": 8, "ancient_guardian_fragment": 0, "legendary_fragment": 0, "ancient_relic_core": 0, "dominion_shard": 0, "legendary_command_seal": 0, "dominion_crest": 0, "crystal_blessing": 1, "sea_chart": 3, "repair_crew": 2, "smoke_screen": 2, "war_banner": 0, "tower_parts": 0, "guild_timber": 0, "guild_steel": 0, "enchanted_rope": 0, "cannon_oil": 2, "monster_bait": 1, "admiral_seal": 0, "harpoon_tempered": 12, "harpoon_stormhook": 6, "harpoon_relic": 0, "ward_tonic": 1, "powder_charge": 1, "hunter_flare": 1, "siege_repair_kit": 0, "arcane_shard": 0, "storm_shot": 0, "wardbreaker": 0, "hunter_shell": 0, "harpoon_abyssal": 0, "harpoon_chainbite": 0, "harpoon_sunsteel": 0, "harpoon_ghostline": 0, "ward_crystal": 0, "siege_powder": 0, "talent_compass": 0, "frostwake": 0, "sunburst": 0, "siege_core": 0, "frostwake_powder": 0, "sun_core_fragment": 0, "guild_masonry": 0, "ward_resin": 0, "master_gunlock": 0, "talent_chart": 0, "citadel_blueprint": 0, "siege_beacon": 0, "harpoon_reefspike": 0, "harpoon_moonchain": 0, "harpoon_dreadfang": 0}
const AMMO_IDS := ["iron", "explosive", "chain", "piercing", "ember", "venom", "shatter", "spectral", "gravefire"]
const OFFERS := {
	"harpoon": {"amount": 30, "price": 35},
	"iron": {"amount": 60, "price": 30},
	"explosive": {"amount": 30, "price": 60},
	"chain": {"amount": 30, "price": 45},
	"piercing": {"amount": 20, "price": 55},
	"ember": {"amount": 20, "price": 65},
	"venom": {"amount": 20, "price": 65},
	"shatter": {"amount": 15, "price": 70},
	"spectral": {"amount": 10, "price": 90},
	"repair": {"amount": 1, "price": 40},
	"boost": {"amount": 1, "price": 35},
	"veil": {"amount": 1, "price": 85},
	"storm_bolt": {"amount": 1, "price": 70},
	"infernal_barrel": {"amount": 1, "price": 80},
	"crystal_barrier": {"amount": 1, "price": 85},
	"armor_corrosive": {"amount": 1, "price": 75},
	"repair_blocker": {"amount": 1, "price": 90},
	"leviathan_hook": {"amount": 1, "price": 75},
	"recall_compass": {"amount": 1, "price": 110},
	"powder": {"amount": 6, "price": 45},
	"plates": {"amount": 6, "price": 50},
}
const MAX_STOCK := 9999
const MAX_DECK := 10
const HARBOR_BUNDLE_PRICE := 120
const EMERGENCY_IRON_STOCK := 30
const REPAIR_BASE_FEE := 8
const REPAIR_GOLD_PER_100_HULL := 4
const QUICK_SLOT_COUNT := 4
const DEFAULT_QUICK_SLOTS := [
	{"id":"iron", "kind":"ammo"},
	{"id":"repair", "kind":"item"},
	{"id":"boost", "kind":"item"},
	{"id":"veil", "kind":"item"},
]

var stock: Dictionary = START_STOCK.duplicate()
var owned_cannons := 3
var powder_enabled := false
var plates_enabled := false
var deck_levels: Dictionary = {}
# M162 data-driven long-term progression state. Definitions/costs live in m162_system_runtime.json.
var special_deck_levels: Dictionary = {}
var equipped_special_deck_by_ship: Dictionary = {}
var talent_ranks: Dictionary = {}
var talent_points_unspent := 0
var citadel_levels: Dictionary = {}
var cannon_track_levels: Dictionary = {}
var selected_harpoon_by_ship: Dictionary = {}
var crafting_station_levels: Dictionary = {}
var loadouts_by_ship: Dictionary = {}
var quickslots_by_ship: Dictionary = {}
var owned_modules: Dictionary = {}
var equipped_modules_by_ship: Dictionary = {}
var saved_loadouts: Dictionary:
	get:
		var id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
		if not loadouts_by_ship.has(id): loadouts_by_ship[id] = {"A": {"cannon": 1, "ammo": 0, "mode": "cannon"}, "B": {"cannon": 0, "ammo": 2, "mode": "cannon"}}
		return loadouts_by_ship[id]
	set(value):
		loadouts_by_ship[roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP] = value

@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var progression: PlayerProgression = ship.get_node("Progression") as PlayerProgression
@onready var roster: PlayerShipRoster = ship.get_node("ShipRoster") as PlayerShipRoster


func _is_runtime_ammo(id:String)->bool:
	for row in CombatCatalog.ammo_rows():
		if row is Dictionary and str(row.get("id",""))==id:return true
	return false

func runtime_ammo_ids()->Array[String]:
	return CombatCatalog.ammo_ids()
func runtime_ammo_index(id:String)->int:
	return CombatCatalog.ammo_index_by_id(id)
func cannon_purchase_cap()->int:return int(inventory_rule("owned_cannons_max",6))
func cannon_purchase_price()->int:return int(inventory_rule("cannon_purchase_price",150))
func max_deck_level()->int:return int(inventory_rule("max_deck",MAX_DECK))

func grant_dominion_drop(level:int,elite:bool,admiral:bool)->Dictionary:
	if level<46:return {}
	var shards:=2 if admiral else (1 if elite else 0)
	var seals:=1 if admiral else 0
	if shards>0:set_count("dominion_shard",count("dominion_shard")+shards)
	if seals>0:set_count("legendary_command_seal",count("legendary_command_seal")+seals)
	return {"dominion_shard":shards,"legendary_command_seal":seals}

func item_exists(item:String)->bool:
	return START_STOCK.has(item) or DynamicItemDefinition.exists(get_tree(),item)
func max_stock_for(item:String)->int:
	var fallback:=int(GameplayRuleset.rule_value(get_tree(),"inventory.max_stock_default",MAX_STOCK))
	return DynamicItemDefinition.stack_limit(get_tree(),item,fallback)
func inventory_rule(path:String,fallback:Variant)->Variant:
	return GameplayRuleset.rule_value(get_tree(),"inventory."+path,fallback)

func count(item: String) -> int:
	return int(stock.get(item, 0))


func set_count(item: String, amount: int) -> void:
	if not item_exists(item):return
	stock[item] = clampi(amount, 0, max_stock_for(item))
	inventory_changed.emit()


func consume(item: String, amount: int = 1) -> bool:
	if amount <= 0 or not item_exists(item) or count(item) < amount:
		return false
	set_count(item, count(item) - amount)
	return true


func deck_level() -> int:
	return int(deck_levels.get(roster.selected_ship_id, 0))


func activate_crystal_blessing(duration:float=120.0)->bool:
	if count("crystal_blessing")<=0:return false
	if not consume("crystal_blessing",1):return false
	ship.set_meta("crystal_blessing_active",true)
	ship.set_meta("crystal_blessing_until",Time.get_ticks_msec()/1000.0+maxf(1.0,duration))
	inventory_changed.emit()
	return true

func _m162_catalog() -> M162SystemCatalog:
	return get_tree().get_first_node_in_group("m162_system_catalog") as M162SystemCatalog

func _m163_catalog() -> M163SystemDepthCatalog:
	return get_tree().get_first_node_in_group("m163_system_depth_catalog") as M163SystemDepthCatalog

func selected_harpoon()->String:
	return str(selected_harpoon_by_ship.get(roster.selected_ship_id,"harpoon"))
func runtime_harpoon_profiles()->Array:
	var modern:=_m165_catalog()
	if modern!=null and not modern.harpoons().is_empty():return modern.harpoons()
	var legacy:=_m163_catalog()
	return legacy.harpoon_profiles() if legacy!=null else []
func runtime_harpoon_ids()->Array[String]:
	var ids:Array[String]=[]
	for row in runtime_harpoon_profiles():
		if row is Dictionary:
			var id:=str(row.get("id",""));if not id.is_empty():ids.append(id)
	return ids
func select_harpoon(id:String)->bool:
	if harpoon_profile(id).is_empty() or count(id)<=0:return false
	selected_harpoon_by_ship[roster.selected_ship_id]=id
	inventory_changed.emit()
	return true
func harpoon_profile(id:String="")->Dictionary:
	var chosen:=selected_harpoon() if id.is_empty() else id
	for row in runtime_harpoon_profiles():
		if row is Dictionary and str(row.get("id",""))==chosen:return (row as Dictionary).duplicate(true)
	return {}
func m163_ammo_profile(id:String)->Dictionary:
	var cat:=_m163_catalog();return cat.definition("ammo_profiles",id) if cat!=null else {}
func m163_consume_effect_item(id:String)->bool:
	var cat:=_m163_catalog();if cat==null:return false
	var d:=cat.definition("consumables_and_materials",id);if d.is_empty() or int(d.get("duration",0))<=0 or count(id)<=0:return false
	if not consume(id,1):return false
	ship.set_meta("m163_effect_"+str(d.get("effect","")),{"until":Time.get_ticks_msec()/1000.0+float(d.get("duration",0)),"value":d.get("value",0),"source":id})
	inventory_changed.emit();return true

func special_deck_level(id:String)->int:return int(special_deck_levels.get(id,0))
func special_deck_upgrade_status(id:String)->Dictionary:
	if not at_port():return {"ok":false,"state":"not_in_port","label":"Nur im Hafen verfügbar"}
	var cat:=_m162_catalog();if cat==null:return {"ok":false,"state":"unknown_definition","label":"Spezialdeck-Katalog fehlt"}
	var d:=cat.definition("special_decks",id);if d.is_empty():return {"ok":false,"state":"unknown_definition","label":"Unbekanntes Spezialdeck"}
	var level:=special_deck_level(id);var max_level:=int(d.get("max_level",5))
	if level>=max_level:return {"ok":false,"state":"max_level","label":"Maximalstufe erreicht","level":level,"max_level":max_level}
	var costs:Array=d.get("upgrade_costs",[]);var cost:=int(costs[level]) if level<costs.size() else 999999
	if progression==null or progression.coins<cost:return {"ok":false,"state":"insufficient_gold","label":"%d Gold benötigt"%cost,"gold":cost,"level":level,"max_level":max_level}
	return {"ok":true,"state":"ready","label":"Bereit","gold":cost,"level":level,"max_level":max_level}
func talent_spend_status(id:String)->Dictionary:
	var cat:=_m162_catalog();if cat==null:return {"ok":false,"state":"unknown_definition","label":"Talent-Katalog fehlt"}
	var d:=cat.definition("talent_nodes",id);if d.is_empty():return {"ok":false,"state":"unknown_definition","label":"Unbekanntes Talent"}
	var rank:=talent_rank(id);var max_rank:=int(d.get("max_rank",1));var point_cost:=int(d.get("point_cost",1))
	if rank>=max_rank:return {"ok":false,"state":"max_level","label":"Maximalrang erreicht","rank":rank,"max_rank":max_rank}
	if talent_points_unspent<point_cost:return {"ok":false,"state":"missing_points","label":"%d Talentpunkt(e) benötigt"%point_cost,"points":point_cost,"rank":rank,"max_rank":max_rank}
	for req in d.get("requires",[]):
		if talent_rank(str(req))<=0:return {"ok":false,"state":"missing_prerequisite","label":"Voraussetzung fehlt: %s"%str(req),"requires":str(req),"rank":rank,"max_rank":max_rank}
	return {"ok":true,"state":"ready","label":"Bereit","points":point_cost,"rank":rank,"max_rank":max_rank}
func citadel_upgrade_status(id:String)->Dictionary:
	if not at_port():return {"ok":false,"state":"not_in_port","label":"Nur im Hafen verfügbar"}
	var cat:=_m162_catalog();if cat==null:return {"ok":false,"state":"unknown_definition","label":"Kastell-Katalog fehlt"}
	var d:=cat.definition("citadel_branches",id);if d.is_empty():return {"ok":false,"state":"unknown_definition","label":"Unbekannter Kastellzweig"}
	var level:=citadel_level(id);var max_level:=int(d.get("max_level",10))
	if level>=max_level:return {"ok":false,"state":"max_level","label":"Maximalstufe erreicht","level":level,"max_level":max_level}
	var costs:Array=d.get("gold_curve",[]);var cost:=int(costs[level]) if level<costs.size() else 999999
	if progression==null or progression.coins<cost:return {"ok":false,"state":"insufficient_gold","label":"%d Gold benötigt"%cost,"gold":cost,"level":level,"max_level":max_level}
	return {"ok":true,"state":"ready","label":"Bereit","gold":cost,"level":level,"max_level":max_level}
func cannon_track_upgrade_status(id:String)->Dictionary:
	if not at_port():return {"ok":false,"state":"not_in_port","label":"Nur im Hafen verfügbar"}
	var cat:=_m162_catalog();if cat==null:return {"ok":false,"state":"unknown_definition","label":"Kanonen-Katalog fehlt"}
	var d:=cat.definition("cannon_upgrade_tracks",id);if d.is_empty():return {"ok":false,"state":"unknown_definition","label":"Unbekannter Ausbaupfad"}
	var level:=cannon_track_level(id);var max_level:=int(d.get("max_level",10))
	if level>=max_level:return {"ok":false,"state":"max_level","label":"Maximalstufe erreicht","level":level,"max_level":max_level}
	var costs:Array=d.get("gold_curve",[]);var oils:Array=d.get("oil_curve",[]);var gold:=int(costs[level]) if level<costs.size() else 999999;var oil:=int(oils[level]) if level<oils.size() else 0
	if progression==null or progression.coins<gold:return {"ok":false,"state":"insufficient_gold","label":"%d Gold benötigt"%gold,"gold":gold,"oil":oil,"level":level,"max_level":max_level}
	if count("cannon_oil")<oil:return {"ok":false,"state":"missing_material","label":"%d Kanonenöl benötigt"%oil,"gold":gold,"oil":oil,"level":level,"max_level":max_level}
	return {"ok":true,"state":"ready","label":"Bereit","gold":gold,"oil":oil,"level":level,"max_level":max_level}
func _refresh_m162_derived_stats()->void:
	if progression!=null:progression._apply_upgrades()
func _selected_ship_id() -> String:
	return roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP

func equipped_special_deck()->String:
	return str(equipped_special_deck_by_ship.get(_selected_ship_id(), ""))
func upgrade_special_deck(id:String)->bool:
	var status:=special_deck_upgrade_status(id);if not bool(status.get("ok",false)):return false
	var level:=special_deck_level(id);var cost:=int(status.get("gold",0))
	progression.add_coins(-cost);special_deck_levels[id]=level+1;_refresh_m162_derived_stats();inventory_changed.emit();return true
func equip_special_deck(id:String)->bool:
	if special_deck_level(id)<=0:return false
	equipped_special_deck_by_ship[_selected_ship_id()]=id;_refresh_m162_derived_stats();inventory_changed.emit();return true
func talent_rank(id:String)->int:return int(talent_ranks.get(id,0))
func grant_talent_points(amount:int)->void:talent_points_unspent=maxi(0,talent_points_unspent+amount);inventory_changed.emit()
func spend_talent_point(id:String)->bool:
	var status:=talent_spend_status(id);if not bool(status.get("ok",false)):return false
	var rank:=talent_rank(id);var point_cost:=int(status.get("points",1))
	talent_points_unspent-=point_cost;talent_ranks[id]=rank+1;_refresh_m162_derived_stats();inventory_changed.emit();return true
func citadel_level(id:String)->int:return int(citadel_levels.get(id,0))
func upgrade_citadel(id:String)->bool:
	var status:=citadel_upgrade_status(id);if not bool(status.get("ok",false)):return false
	var level:=citadel_level(id);var cost:=int(status.get("gold",0))
	progression.add_coins(-cost);citadel_levels[id]=level+1;_refresh_m162_derived_stats();inventory_changed.emit();return true
func cannon_track_level(id:String)->int:return int(cannon_track_levels.get(id,0))
func upgrade_cannon_track(id:String)->bool:
	var status:=cannon_track_upgrade_status(id);if not bool(status.get("ok",false)):return false
	var level:=cannon_track_level(id);var gold:=int(status.get("gold",0));var oil:=int(status.get("oil",0))
	progression.add_coins(-gold)
	if oil>0:
		consume("cannon_oil",oil)
	cannon_track_levels[id]=level+1
	_refresh_m162_derived_stats()
	inventory_changed.emit()
	return true

func m162_effect_pct(key:String)->float:
	var cat:=_m162_catalog();if cat==null:return 0.0
	var total:=0.0
	var deck_id:=equipped_special_deck()
	if not deck_id.is_empty():
		var d:=cat.definition("special_decks",deck_id);total+=float((d.get("effects_per_level_pct",{}) as Dictionary).get(key,0.0))*special_deck_level(deck_id)
	for row in cat.citadel_branches():
		var id:=str(row.get("id",""));total+=float((row.get("effects_per_level_pct",{}) as Dictionary).get(key,0.0))*citadel_level(id)
	for row in cat.cannon_tracks():
		var id:=str(row.get("id",""));total+=float((row.get("effects_per_level_pct",{}) as Dictionary).get(key,0.0))*cannon_track_level(id)
	for row in cat.talent_nodes():
		var id:=str(row.get("id",""));if str(row.get("effect_key",""))==key:total+=float(row.get("effect_per_rank_pct",0.0))*talent_rank(id)
	return total
func m162_multiplier(key:String)->float:return maxf(0.1,1.0+m162_effect_pct(key)/100.0)

func cannon_capacity() -> int:
	return 3 + deck_level()


func volley_size() -> int:
	return mini(owned_cannons, cannon_capacity())


func at_port() -> bool:
	if not ship.has_meta("nearby_port"):
		return false
	var port = ship.get_meta("nearby_port", null)
	var health := ship.get_node("Health") as ShipHealth
	return is_instance_valid(port) and port is PortInteraction and port.nearby_player == ship and not health.is_sunk


func effective_offers()->Dictionary:
	var registry:=LiveConfigRegistry.current(get_tree())
	return registry.dictionary("economy.shop_offers",OFFERS) if registry!=null else OFFERS
func economy_value(key:String,fallback:int)->int:
	var registry:=LiveConfigRegistry.current(get_tree())
	return int(registry.value_at("economy."+key,fallback)) if registry!=null else fallback

func purchase(item: String) -> bool:
	if not at_port() or not effective_offers().has(item):
		return false
	var offer: Dictionary = effective_offers()[item]
	if progression.coins < int(offer.price) or count(item) + int(offer.amount) > max_stock_for(item):
		return false
	progression.add_coins(-int(offer.price))
	set_count(item, count(item) + int(offer.amount))
	return true


func catalog_offer_status(offer: Dictionary) -> Dictionary:
	if not at_port(): return {"ok":false,"label":"Nur im Hafen"}
	if str(offer.get("kind", "")) != "soft_currency" or str(offer.get("currency", "gold")) != "gold": return {"ok":false,"label":"Nicht lokal kaufbar"}
	var item := str(offer.get("content_id", "")); var amount := int(offer.get("amount", 0)); var price := int(offer.get("price", -1))
	if item.is_empty() or amount <= 0 or price < 0: return {"ok":false,"label":"Angebot ungültig"}
	if progression.coins < price: return {"ok":false,"label":"Gold fehlt"}
	if count(item) + amount > max_stock_for(item): return {"ok":false,"label":"Lager voll"}
	return {"ok":true,"label":"Bereit"}

func harbor_bundle_status() -> Dictionary:
	if not at_port(): return {"ok":false,"label":"Nur im Hafen"}
	var price:=int(inventory_rule("harbor_bundle.price",HARBOR_BUNDLE_PRICE))
	if progression.coins < price: return {"ok":false,"label":"Gold fehlt"}
	var targets:=GameplayRuleset.dictionary(get_tree(),"inventory.harbor_bundle.targets",{"iron":240,"explosive":60,"chain":60,"repair":5,"boost":5})
	for item in targets:
		if count(item) < int(targets[item]): return {"ok":true,"label":"Bereit · %d Gold"%price}
	return {"ok":false,"label":"Vorrat bereits voll"}

func harbor_repair_status() -> Dictionary:
	var quote:=harbor_repair_quote()
	if quote < 0: return {"ok":false,"label":"Nur im Hafen"}
	if quote == 0: return {"ok":false,"label":"Rumpf vollständig"}
	if progression.coins < quote: return {"ok":false,"label":"Gold fehlt · %d"%quote}
	return {"ok":true,"label":"Bereit · %d Gold"%quote}

func purchase_catalog_offer(offer: Dictionary) -> bool:
	# M161: generic soft-currency shop transaction. Offer amount/price/content are data, not UI code.
	if not at_port() or str(offer.get("kind", "")) != "soft_currency": return false
	if str(offer.get("currency", "gold")) != "gold": return false
	var item := str(offer.get("content_id", ""))
	var amount := int(offer.get("amount", 0))
	var price := int(offer.get("price", -1))
	if item.is_empty() or amount <= 0 or price < 0: return false
	if progression.coins < price or count(item) + amount > max_stock_for(item): return false
	progression.add_coins(-price)
	set_count(item, count(item) + amount)
	return true



func current_region_id() -> String:
	var world := get_tree().get_first_node_in_group("world_map") as WorldMapSystem
	if world == null: return ""
	return RegionalHarborEconomy.region_for_level(world.current_map_level())


func purchase_regional(item: String) -> bool:
	if not at_port(): return false
	var region_id := current_region_id()
	if region_id.is_empty(): return false
	var offer := RegionalHarborEconomy.offer(region_id, item)
	if offer.is_empty(): return false
	var amount := int(offer.get("amount", 0))
	var price := int(offer.get("price", 0))
	if amount <= 0 or progression.coins < price or count(item) + amount > max_stock_for(item):
		return false
	progression.add_coins(-price)
	set_count(item, count(item) + amount)
	return true


func grant_regional_salvage(region_id: String, boss: bool = false) -> void:
	var item := ""
	match region_id:
		"stormreach": item = "stormglass"
		"ember_shoals": item = "ember_ore"
		"veil_sea": item = "veil_silk"
		"cursed_dominion": item = "cursed_doubloon"
		_: return
	set_count(item,count(item)+(3 if boss else 1))

func grant_silver_bonusmap_fragment(map_level:int,elite:bool=false,boss:bool=false)->bool:
	if map_level<12:return false
	var amount:=3 if boss else (2 if elite else 1)
	set_count("silver_chart_fragment",count("silver_chart_fragment")+amount)
	return true

func grant_gold_bonusmap_fragment(map_level:int,elite:bool=false,boss:bool=false)->bool:
	if map_level<18:return false
	var amount:=3 if boss else (2 if elite else 1)
	set_count("gold_chart_fragment",count("gold_chart_fragment")+amount)
	if boss:set_count("admiral_component",count("admiral_component")+1)
	return true

func grant_ancient_guardian_drop(map_level:int,admiral:bool=false)->int:
	if map_level<31:return 0
	var amount:=2 if admiral else 1
	set_count("ancient_guardian_fragment",count("ancient_guardian_fragment")+amount)
	if admiral:set_count("legendary_fragment",count("legendary_fragment")+1)
	return amount

func grant_abyss_progression_drop(map_level:int,elite:bool=false,boss:bool=false)->bool:
	if map_level<26:return false
	var amount:=3 if boss else (2 if elite else 1)
	set_count("abyss_scale",count("abyss_scale")+amount)
	if elite or boss:set_count("abyss_chart_fragment",count("abyss_chart_fragment")+(2 if boss else 1))
	if boss:set_count("corrupted_pearl",count("corrupted_pearl")+1)
	return true

func purchase_cannon() -> bool:
	var cap:=int(inventory_rule("owned_cannons_max",6))
	var price:=int(inventory_rule("cannon_purchase_price",150))
	if not at_port() or owned_cannons >= cap or progression.coins < price:return false
	progression.add_coins(-price)
	owned_cannons += 1
	inventory_changed.emit()
	return true


func deck_price() -> int:
	return int(inventory_rule("deck_price_base",180))+int(inventory_rule("deck_price_step",120))*deck_level()


func purchase_deck() -> bool:
	if not at_port() or deck_level() >= int(inventory_rule("max_deck",MAX_DECK)) or progression.coins < deck_price():
		return false
	progression.add_coins(-deck_price())
	deck_levels[roster.selected_ship_id] = deck_level() + 1
	inventory_changed.emit()
	return true


func purchase_harbor_bundle() -> bool:
	if not at_port() or progression.coins < int(inventory_rule("harbor_bundle.price",HARBOR_BUNDLE_PRICE)):
		return false
	var targets:=GameplayRuleset.dictionary(get_tree(),"inventory.harbor_bundle.targets",{"iron":240,"explosive":60,"chain":60,"repair":5,"boost":5})
	var changed := false
	for item in targets:
		if count(item) < int(targets[item]):
			changed = true
	if not changed:
		return false
	progression.add_coins(-int(inventory_rule("harbor_bundle.price",HARBOR_BUNDLE_PRICE)))
	for item in targets:
		stock[item] = maxi(count(item), int(targets[item]))
	inventory_changed.emit()
	return true



func toggle_supply(id: String) -> bool:
	if id == "powder": powder_enabled = not powder_enabled
	elif id == "plates": plates_enabled = not plates_enabled
	else: return false
	inventory_changed.emit()
	return true


func consume_powder_for_salvo() -> float:
	if not powder_enabled or count("powder") <= 0: return 1.0
	if not consume("powder", 1): return 1.0
	return float(CombatSupportContracts.read().get("supplies", {}).get("powder", {}).get("local_damage_multiplier", 1.0))


func consume_plate_for_hit() -> float:
	if not plates_enabled or count("plates") <= 0: return 0.0
	if not consume("plates", 1): return 0.0
	return clampf(float(CombatSupportContracts.read().get("supplies", {}).get("plates", {}).get("local_damage_reduction", 0.0)), 0.0, 0.75)


func craft(recipe_id: String) -> bool:
	if not at_port(): return false
	var recipe := EquipmentEconomyContracts.recipe(recipe_id)
	if recipe.is_empty(): return false
	var gold := int(recipe.get("gold", 0))
	if progression.coins < gold: return false
	var materials: Dictionary = recipe.get("materials", {})
	for material in materials:
		if count(str(material)) < int(materials[material]): return false
	var output: Dictionary = recipe.get("output", {})
	for item in output:
		if count(str(item)) + int(output[item]) > MAX_STOCK: return false
	progression.add_coins(-gold)
	for material in materials: set_count(str(material), count(str(material)) - int(materials[material]))
	for item in output: set_count(str(item), count(str(item)) + int(output[item]))
	return true


func save_loadout(slot: String, weapons: ShipWeapons) -> bool:
	if slot not in ["A", "B"] or weapons == null:
		return false
	saved_loadouts[slot] = {"cannon": weapons.cannon_index, "ammo": weapons.ammo_index, "mode": weapons.weapon_mode}
	inventory_changed.emit()
	return true


func apply_loadout(slot: String, weapons: ShipWeapons) -> bool:
	if not saved_loadouts.has(slot) or weapons == null:
		return false
	var data: Dictionary = saved_loadouts[slot]
	weapons.cannon_index = posmod(int(data.get("cannon", 1)), CombatCatalog.cannon_count())
	weapons.ammo_index = posmod(int(data.get("ammo", 0)), CombatCatalog.ammo_count())
	weapons.weapon_mode = str(data.get("mode", "cannon"))
	weapons.loadout_changed.emit()
	return true


func loadout_summary(slot: String) -> String:
	if not saved_loadouts.has(slot):
		return "Empty"
	var data: Dictionary = saved_loadouts[slot]
	var cannon: Dictionary = CombatCatalog.cannon(int(data.get("cannon", 1)))
	var ammo: Dictionary = CombatCatalog.ammo(int(data.get("ammo", 0)))
	return "Harpune" if data.get("mode", "cannon") == "harpoon" else "%s + %s" % [str(cannon.name), str(ammo.name)]



func quickslots() -> Array:
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	if not quickslots_by_ship.has(ship_id):
		quickslots_by_ship[ship_id] = DEFAULT_QUICK_SLOTS.duplicate(true)
	var values: Array = quickslots_by_ship[ship_id]
	while values.size() < QUICK_SLOT_COUNT:
		values.append({})
	return values


func quickslot(index: int) -> Dictionary:
	if index < 0 or index >= QUICK_SLOT_COUNT:
		return {}
	var values := quickslots()
	return (values[index] as Dictionary).duplicate(true) if values[index] is Dictionary else {}


func assign_quickslot(index: int, id: String, kind: String) -> bool:
	if index < 0 or index >= QUICK_SLOT_COUNT:
		return false
	if not _valid_quick_binding(id, kind):
		return false
	var values := quickslots()
	values[index] = {"id": id, "kind": kind}
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	quickslots_by_ship[ship_id] = values
	inventory_changed.emit()
	return true


func _valid_quick_binding(id: String, kind: String) -> bool:
	if kind == "ammo":
		return _is_runtime_ammo(id)
	if kind == "mode":
		return id == "harpoon"
	if kind == "supply":
		return id in ["powder", "plates"]
	if kind == "item":
		return not ActionItemCatalog.item(id).is_empty()
	return false


func quick_binding_kind(id: String) -> String:
	if _is_runtime_ammo(id):
		return "ammo"
	if id == "harpoon":
		return "mode"
	if id in ["powder", "plates"]:
		return "supply"
	if not ActionItemCatalog.item(id).is_empty():
		return "item"
	return ""



func build_regional_module(module_id: String) -> bool:
	if not at_port() or owned_modules.has(module_id): return false
	var definition := RegionalEquipmentCatalog.module(module_id)
	if definition.is_empty() or str(definition.get("region", "")) != current_region_id(): return false
	var cost: Dictionary = definition.get("cost", {})
	var gold := int(cost.get("gold", 0))
	if progression.coins < gold: return false
	var materials: Dictionary = cost.get("materials", {})
	for material in materials:
		if count(str(material)) < int(materials[material]): return false
	progression.add_coins(-gold)
	for material in materials:
		set_count(str(material), count(str(material)) - int(materials[material]))
	owned_modules[module_id] = {"built": true}
	inventory_changed.emit()
	return true


func equip_module(module_id: String) -> bool:
	if not owned_modules.has(module_id): return false
	var definition := RegionalEquipmentCatalog.module(module_id)
	if definition.is_empty(): return false
	var slot := str(definition.get("slot", ""))
	if slot.is_empty(): return false
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	if not equipped_modules_by_ship.has(ship_id): equipped_modules_by_ship[ship_id] = {}
	equipped_modules_by_ship[ship_id][slot] = module_id
	inventory_changed.emit()
	return true


func equipped_module(slot: String) -> String:
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	var slots: Variant = equipped_modules_by_ship.get(ship_id, {})
	return str(slots.get(slot, "")) if slots is Dictionary else ""


func module_modifier(key: String, fallback: float = 1.0) -> float:
	var result := fallback
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	var slots: Variant = equipped_modules_by_ship.get(ship_id, {})
	if not slots is Dictionary: return result
	for slot in slots:
		var module_id := str(slots[slot])
		var effects: Dictionary = RegionalEquipmentCatalog.module(module_id).get("effects", {})
		if not effects.has(key): continue
		if key.ends_with("_add"):
			result += float(effects[key])
		else:
			result *= float(effects[key])
	return result


func module_summary() -> String:
	var ship_id := roster.selected_ship_id if roster != null else BeginnerRules.START_SHIP
	var slots: Variant = equipped_modules_by_ship.get(ship_id, {})
	if not slots is Dictionary or slots.is_empty(): return "Keine regionalen Module ausgerüstet"
	var rows: Array[String] = []
	for slot in ["weapon", "defense", "support", "mobility"]:
		var id := str(slots.get(slot, ""))
		if not id.is_empty():
			rows.append("%s: %s" % [slot.capitalize(), str(RegionalEquipmentCatalog.module(id).get("label", id))])
	return " · ".join(rows)

func emergency_standard_ammo() -> bool:
	# M36 PL1-5 safety net: only an empty standard-ammo stock is rescued.
	# Normal restocking remains a Gold sink through the harbor merchant.
	if count("iron") > 0:
		return false
	set_count("iron", EMERGENCY_IRON_STOCK)
	return true


func harbor_repair_quote() -> int:
	if not at_port():
		return -1
	var health := ship.get_node("Health") as ShipHealth
	var missing := maxf(0.0, health.max_health - health.current_health)
	if missing <= 0.01:
		return 0
	return economy_value("repair.base_fee",REPAIR_BASE_FEE) + ceili(missing / 100.0) * economy_value("repair.gold_per_100_hull",REPAIR_GOLD_PER_100_HULL)


func purchase_harbor_repair() -> bool:
	var quote := harbor_repair_quote()
	if quote < 0:
		return false
	var health := ship.get_node("Health") as ShipHealth
	if quote == 0:
		return true
	if progression.coins < quote:
		return false
	progression.add_coins(-quote)
	health.repair(health.max_health)
	inventory_changed.emit()
	return true


func resupply_basics() -> void:
	# Compatibility alias retained for old callers. No free repair charges or full ammo refill.
	emergency_standard_ammo()



func _m165_catalog() -> M165RuntimeDepthCatalog:
	return get_tree().get_first_node_in_group("m165_runtime_depth_catalog") as M165RuntimeDepthCatalog

func _m166_catalog() -> M166ProductionDepthCatalog:
	return get_tree().get_first_node_in_group("m166_production_depth_catalog") as M166ProductionDepthCatalog

func _m168_catalog() -> M168RuntimeAuditCatalog:
	return get_tree().get_first_node_in_group("m168_runtime_audit_catalog") as M168RuntimeAuditCatalog
func crafting_station_level(id:String)->int:return int(crafting_station_levels.get(id,0))
func crafting_station_upgrade_cost(id:String)->int:
	var cat:=_m168_catalog();return cat.station_upgrade_cost(id,crafting_station_level(id)) if cat!=null else 0
func upgrade_crafting_station(id:String)->bool:
	if not at_port():return false
	var cat:=_m168_catalog();if cat==null:return false
	var row:=cat.station(id);if row.is_empty():return false
	var level:=crafting_station_level(id);var max_level:=int(row.get("max_level",10))
	if level>=max_level:return false
	var cost:=cat.station_upgrade_cost(id,level)
	if cost<=0 or progression.coins<cost:return false
	progression.add_coins(-cost);crafting_station_levels[id]=level+1;inventory_changed.emit();return true
func _recipe_station_ready(recipe:Dictionary)->bool:
	var station:=str(recipe.get("station",""))
	if station.is_empty():return true
	var required:=maxi(1,int(recipe.get("station_level",1)))
	return crafting_station_level(station)>=required

func m165_recipe_status(id:String)->Dictionary:
	var cat:=_m165_catalog()
	var next:=_m166_catalog()
	if cat==null and next==null:return {"ok":false,"state":"unknown_recipe","label":"Rezept nicht verfügbar"}
	var recipe:Dictionary=next.recipe(id) if next!=null else {}
	if recipe.is_empty() and cat!=null:recipe=cat.recipe(id)
	if recipe.is_empty():return {"ok":false,"state":"unknown_recipe","label":"Rezept nicht verfügbar"}
	if not at_port():return {"ok":false,"state":"not_in_port","label":"Nur im Hafen herstellbar"}
	var station:=str(recipe.get("station",""))
	var required:=maxi(1,int(recipe.get("station_level",1))) if not station.is_empty() else 0
	if not _recipe_station_ready(recipe):return {"ok":false,"state":"station_locked","label":"%s Stufe %d benötigt"%[station.replace("_"," ").capitalize(),required]}
	var prog:=get_parent().get_node_or_null("Progression") as PlayerProgression
	if prog==null:return {"ok":false,"state":"runtime_missing","label":"Progression nicht verfügbar"}
	var gold:=int(recipe.get("gold",0))
	if prog.coins<gold:return {"ok":false,"state":"insufficient_gold","label":"%d Gold benötigt"%gold}
	var missing:Array[String]=[]
	for need in recipe.get("inputs",[]):
		if need is Dictionary:
			var iid:=str(need.get("id",""));var amount:=int(need.get("amount",0));var have:=count(iid)
			if have<amount:missing.append("%s %d/%d"%[iid.replace("_"," ").capitalize(),have,amount])
	if not missing.is_empty():return {"ok":false,"state":"missing_materials","label":"Fehlt: "+", ".join(PackedStringArray(missing))}
	var output:Dictionary=recipe.get("output",{}) as Dictionary
	var oid:=str(output.get("id",""));var amount:=int(output.get("amount",0))
	if oid.is_empty() or amount<=0:return {"ok":false,"state":"invalid_output","label":"Ungültiger Output"}
	if count(oid)+amount>max_stock_for(oid):return {"ok":false,"state":"output_full","label":"Lagerlimit für %s erreicht"%oid.replace("_"," ").capitalize()}
	return {"ok":true,"state":"ready","label":"Bereit","recipe":recipe}

func m244_craft_transaction_status(id:String)->Dictionary:
	var status:=m165_recipe_status(id)
	status["transaction"]="LOCAL_ATOMIC_PREVIEW"
	status["category"]=M244CraftingSalvageCatalog.recipe_category(id)
	status["online_authority"]="SERVER_REQUIRED"
	return status

func craft_m165_recipe(id:String)->bool:
	var cat:=_m165_catalog()
	var next:=_m166_catalog()
	if cat==null and next==null:return false
	var recipe:Dictionary=next.recipe(id) if next!=null else {}
	if recipe.is_empty() and cat!=null:recipe=cat.recipe(id)
	if recipe.is_empty():return false
	var status:=m244_craft_transaction_status(id)
	if not bool(status.get("ok",false)):return false
	var progression:=get_parent().get_node_or_null("Progression") as PlayerProgression
	if progression==null:return false
	var gold:=int(recipe.get("gold",0))
	var output:Dictionary=recipe.get("output",{}) as Dictionary
	var oid:=str(output.get("id",""));var amount:=int(output.get("amount",0))
	var stock_before:=stock.duplicate(true)
	var coins_before:=progression.coins
	for need in recipe.get("inputs",[]):
		if need is Dictionary and not consume(str(need.get("id","")),int(need.get("amount",0))):
			stock=stock_before
			inventory_changed.emit()
			return false
	progression.add_coins(-gold)
	if count(oid)+amount>max_stock_for(oid):
		stock=stock_before
		progression.add_coins(coins_before-progression.coins)
		inventory_changed.emit()
		return false
	set_count(oid,count(oid)+amount)
	inventory_changed.emit()
	return true

func module_equipped_anywhere(module_id:String)->bool:
	for ship_id in equipped_modules_by_ship:
		var slots:Variant=equipped_modules_by_ship[ship_id]
		if not slots is Dictionary:continue
		for slot in slots:
			if str(slots[slot])==module_id:return true
	return false

func m244_salvage_status(module_id:String)->Dictionary:
	if not at_port():return {"ok":false,"state":"not_in_port","label":"Nur im Hafen zerlegbar"}
	if not owned_modules.has(module_id):return {"ok":false,"state":"not_owned","label":"Modul nicht im Besitz"}
	var definition:=RegionalEquipmentCatalog.module(module_id)
	if definition.is_empty():return {"ok":false,"state":"unknown_module","label":"Moduldefinition fehlt"}
	if module_equipped_anywhere(module_id):return {"ok":false,"state":"equipped","label":"Vor dem Zerlegen auf allen Schiffen ablegen"}
	var returns:=M244CraftingSalvageCatalog.salvage_return_for_module(module_id,definition)
	if returns.is_empty():return {"ok":false,"state":"salvage_blocked","label":"Dieses gebundene/spezielle Modul ist nicht zerlegbar"}
	for material in returns:
		if not item_exists(str(material)):return {"ok":false,"state":"invalid_return","label":"Ungültige Salvage-Ressource"}
		if count(str(material))+int(returns[material])>max_stock_for(str(material)):
			return {"ok":false,"state":"output_full","label":"Lagerlimit für %s erreicht"%str(material).replace("_"," ").capitalize()}
	return {"ok":true,"state":"ready","label":"Bereit zum Zerlegen","returns":returns,"gold_refund":0,"authority":"LOCAL_PREVIEW"}

func salvage_regional_module(module_id:String)->bool:
	var status:=m244_salvage_status(module_id)
	if not bool(status.get("ok",false)):return false
	var stock_before:=stock.duplicate(true)
	var owned_before:=owned_modules.duplicate(true)
	owned_modules.erase(module_id)
	var returns:Dictionary=status.get("returns",{}) as Dictionary
	for material in returns:
		var item_id:=str(material);var target:=count(item_id)+int(returns[material])
		if target>max_stock_for(item_id):
			stock=stock_before;owned_modules=owned_before;inventory_changed.emit();return false
		set_count(item_id,target)
	inventory_changed.emit()
	return true

func export_state() -> Dictionary:
	return {"stock": stock.duplicate(), "owned_cannons": owned_cannons, "deck_levels": deck_levels.duplicate(), "saved_loadouts": saved_loadouts.duplicate(true), "loadouts_by_ship": loadouts_by_ship.duplicate(true), "quickslots_by_ship": quickslots_by_ship.duplicate(true), "owned_modules": owned_modules.duplicate(true), "equipped_modules_by_ship": equipped_modules_by_ship.duplicate(true), "powder_enabled": powder_enabled, "plates_enabled": plates_enabled, "special_deck_levels": special_deck_levels.duplicate(true), "equipped_special_deck_by_ship": equipped_special_deck_by_ship.duplicate(true), "talent_ranks": talent_ranks.duplicate(true), "talent_points_unspent": talent_points_unspent, "citadel_levels": citadel_levels.duplicate(true), "cannon_track_levels": cannon_track_levels.duplicate(true), "selected_harpoon_by_ship": selected_harpoon_by_ship.duplicate(true), "crafting_station_levels": crafting_station_levels.duplicate(true)}


func import_state(data: Dictionary) -> void:
	stock = START_STOCK.duplicate()
	var saved_stock = data.get("stock", {})
	if saved_stock is Dictionary:
		for item in START_STOCK:
			stock[item]=_safe_int(saved_stock.get(item,START_STOCK[item]),int(START_STOCK[item]),0,max_stock_for(item))
		for item in saved_stock:
			var item_id:=str(item)
			if not START_STOCK.has(item_id) and item_exists(item_id):
				stock[item_id]=_safe_int(saved_stock[item],0,0,max_stock_for(item_id))
	var cannon_start:=int(inventory_rule("owned_cannons_start",3))
	owned_cannons=_safe_int(data.get("owned_cannons",cannon_start),cannon_start,1,int(inventory_rule("owned_cannons_max",6)))
	powder_enabled = bool(data.get("powder_enabled", false))
	plates_enabled = bool(data.get("plates_enabled", false))
	deck_levels.clear()
	loadouts_by_ship.clear()
	quickslots_by_ship.clear()
	owned_modules.clear()
	equipped_modules_by_ship.clear()
	special_deck_levels.clear()
	equipped_special_deck_by_ship.clear()
	talent_ranks.clear()
	citadel_levels.clear()
	cannon_track_levels.clear()
	selected_harpoon_by_ship.clear()
	crafting_station_levels.clear()
	talent_points_unspent=_safe_int(data.get("talent_points_unspent",0),0,0,999)
	saved_loadouts = {"A": {"cannon": 1, "ammo": 0}, "B": {"cannon": 0, "ammo": 2}}
	var saved_presets = data.get("saved_loadouts", {})
	if saved_presets is Dictionary:
		for slot in ["A", "B"]:
			if saved_presets.has(slot) and saved_presets[slot] is Dictionary:
				var preset: Dictionary = saved_presets[slot]
				saved_loadouts[slot] = _validated_preset(preset)
	var per_ship: Variant = data.get("loadouts_by_ship", {})
	if per_ship is Dictionary:
		for id in per_ship:
			if not ShipCatalog.has_ship(str(id)) or not roster.owns_ship(str(id)) or not per_ship[id] is Dictionary: continue
			loadouts_by_ship[id] = {}
			for slot in ["A", "B"]:
				var preset: Variant = per_ship[id].get(slot, {})
				loadouts_by_ship[id][slot] = _validated_preset(preset if preset is Dictionary else {})
	var saved_quickslots: Variant = data.get("quickslots_by_ship", {})
	if saved_quickslots is Dictionary:
		for ship_id in saved_quickslots:
			if not ShipCatalog.has_ship(str(ship_id)) or not roster.owns_ship(str(ship_id)):
				continue
			var raw_slots: Variant = saved_quickslots[ship_id]
			if not raw_slots is Array:
				continue
			var validated: Array = []
			for i in QUICK_SLOT_COUNT:
				if i < raw_slots.size() and raw_slots[i] is Dictionary:
					var raw: Dictionary = raw_slots[i]
					var qid := str(raw.get("id", ""))
					var qkind := str(raw.get("kind", quick_binding_kind(qid)))
					validated.append({"id": qid, "kind": qkind} if _valid_quick_binding(qid, qkind) else DEFAULT_QUICK_SLOTS[i].duplicate())
				else:
					validated.append(DEFAULT_QUICK_SLOTS[i].duplicate())
			quickslots_by_ship[str(ship_id)] = validated
	var saved_modules: Variant = data.get("owned_modules", {})
	if saved_modules is Dictionary:
		for module_id in saved_modules:
			if not RegionalEquipmentCatalog.module(str(module_id)).is_empty():
				owned_modules[str(module_id)] = {"built": true}
	var saved_equipped: Variant = data.get("equipped_modules_by_ship", {})
	if saved_equipped is Dictionary:
		for ship_id in saved_equipped:
			if not ShipCatalog.has_ship(str(ship_id)) or not roster.owns_ship(str(ship_id)): continue
			var raw_slots: Variant = saved_equipped[ship_id]
			if not raw_slots is Dictionary: continue
			var validated := {}
			for slot in ["weapon", "defense", "support", "mobility"]:
				var module_id := str(raw_slots.get(slot, ""))
				var definition := RegionalEquipmentCatalog.module(module_id)
				if owned_modules.has(module_id) and not definition.is_empty() and str(definition.get("slot", "")) == slot:
					validated[slot] = module_id
			equipped_modules_by_ship[str(ship_id)] = validated
	var saved_decks = data.get("deck_levels", {})
	if saved_decks is Dictionary:
		for id in saved_decks:
			if ShipCatalog.has_ship(str(id)) and roster.owns_ship(str(id)):
				deck_levels[str(id)] = _safe_int(saved_decks[id], 0, 0, MAX_DECK)
	var m162_cat:=_m162_catalog()
	if m162_cat!=null:
		var saved_special:Variant=data.get("special_deck_levels",{})
		if saved_special is Dictionary:
			for id in saved_special:
				var d:=m162_cat.definition("special_decks",str(id));if not d.is_empty():special_deck_levels[str(id)]=_safe_int(saved_special[id],0,0,int(d.get("max_level",5)))
		var saved_talents:Variant=data.get("talent_ranks",{})
		if saved_talents is Dictionary:
			for id in saved_talents:
				var d:=m162_cat.definition("talent_nodes",str(id));if not d.is_empty():talent_ranks[str(id)]=_safe_int(saved_talents[id],0,0,int(d.get("max_rank",1)))
		var saved_cit:Variant=data.get("citadel_levels",{})
		if saved_cit is Dictionary:
			for id in saved_cit:
				var d:=m162_cat.definition("citadel_branches",str(id));if not d.is_empty():citadel_levels[str(id)]=_safe_int(saved_cit[id],0,0,int(d.get("max_level",10)))
		var saved_tracks:Variant=data.get("cannon_track_levels",{})
		if saved_tracks is Dictionary:
			for id in saved_tracks:
				var d:=m162_cat.definition("cannon_upgrade_tracks",str(id));if not d.is_empty():cannon_track_levels[str(id)]=_safe_int(saved_tracks[id],0,0,int(d.get("max_level",10)))
	var m168_cat:=_m168_catalog()
	if m168_cat!=null:
		var saved_stations:Variant=data.get("crafting_station_levels",{})
		if saved_stations is Dictionary:
			for row in m168_cat.stations():
				if row is Dictionary:
					var sid:=str(row.get("id",""))
					crafting_station_levels[sid]=_safe_int(saved_stations.get(sid,0),0,0,int(row.get("max_level",10)))
	var saved_harpoons:Variant=data.get("selected_harpoon_by_ship",{})
	if saved_harpoons is Dictionary:
		var m163_cat:=_m163_catalog()
		for ship_id in saved_harpoons:
			var hid:=str(saved_harpoons[ship_id])
			if ShipCatalog.has_ship(str(ship_id)) and m163_cat!=null and not m163_cat.definition("harpoon_profiles",hid).is_empty():selected_harpoon_by_ship[str(ship_id)]=hid
	var saved_equipped_special:Variant=data.get("equipped_special_deck_by_ship",{})
	if saved_equipped_special is Dictionary:
		for ship_id in saved_equipped_special:
			var deck_id:=str(saved_equipped_special[ship_id])
			if ShipCatalog.has_ship(str(ship_id)) and special_deck_level(deck_id)>0:equipped_special_deck_by_ship[str(ship_id)]=deck_id
	inventory_changed.emit()


func _safe_int(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return int(clampf(float(value), float(minimum), float(maximum)))

func _validated_preset(data: Dictionary) -> Dictionary:
	return {"cannon": _safe_int(data.get("cannon", 1), 1, 0, CombatCatalog.cannon_count() - 1),
		"ammo": _safe_int(data.get("ammo", 0), 0, 0, CombatCatalog.ammo_count() - 1),
		"mode": "harpoon" if data.get("mode") == "harpoon" else "cannon"}

class_name PlayerProgression
extends Node

signal progression_changed

const UPGRADE_KEYS := ["hull", "cannon", "sails"]

var level := 1
var xp := 0
var coins := 250
var upgrades := {"hull": 0, "cannon": 0, "sails": 0}
var shop_open := false

var _base_health := 1000.0
var _base_damage := 72.0
var _base_speed := 6.5

@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var health: ShipHealth = get_parent().get_node("Health") as ShipHealth
@onready var weapons: ShipWeapons = get_parent().get_node("Weapons") as ShipWeapons


func rule(path:String,fallback:Variant)->Variant:return GameplayRuleset.rule_value(get_tree(),"player_progression."+path,fallback)

func _ready() -> void:
	level=int(rule("start_level",level));xp=int(rule("start_xp",xp));coins=int(rule("start_gold",coins))
	_base_health = health.max_health
	_base_damage = weapons.damage
	_base_speed = ship.cruise_speed
	ship.set_meta("coins", coins)
	_apply_upgrades()


func xp_to_next_level() -> int:
	return int(float(rule("xp_curve.base",100.0))*pow(float(level),float(rule("xp_curve.exponent",1.35))))


func xp_progress() -> float:
	return clamp(float(xp) / max(1.0, float(xp_to_next_level())), 0.0, 1.0)


func add_xp(amount: int) -> void:
	var roster := ship.get_node_or_null("ShipRoster") as PlayerShipRoster
	if roster != null: roster.earn_ship_xp(amount)
	xp += max(0, amount)
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
		if inventory != null: inventory.grant_talent_points(1)
		coins += int(rule("level_up_gold.base",75))+level*int(rule("level_up_gold.per_level",15))
	ship.set_meta("coins", coins)
	progression_changed.emit()


func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)
	ship.set_meta("coins", coins)
	progression_changed.emit()


func upgrade_cost(kind: String) -> int:
	if not upgrades.has(kind):
		return 999999
	return int(rule("upgrade.cost_base",110))+int(upgrades[kind])*int(rule("upgrade.cost_step",135))


func purchase_upgrade(kind: String) -> bool:
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	if inventory == null or not upgrades.has(kind):
		return false
	var current_level := int(upgrades[kind])
	if current_level >= int(rule("upgrade.max_level",10)):
		return false
	var cost := upgrade_cost(kind)
	if coins < cost:
		return false
	coins -= cost
	upgrades[kind] = current_level + 1
	ship.set_meta("coins", coins)
	_apply_upgrades()
	progression_changed.emit()
	return true


func toggle_shop() -> bool:
	if ship.get_meta("command_open", false) or ship.get_meta("settings_open", false) or ship.get_meta("journal_open", false) or ship.get_meta("inventory_open", false): return false
	if shop_open:
		shop_open = false
		progression_changed.emit()
		return true
	if ship.has_meta("nearby_port"):
		shop_open = true
		ship.stop_ship()
		progression_changed.emit()
		return true
	return false


func export_state() -> Dictionary:
	return {"level": level, "xp": xp, "coins": coins, "upgrades": upgrades.duplicate(true)}


func import_state(data: Dictionary) -> void:
	level = max(1, int(data.get("level", 1)))
	xp = max(0, int(data.get("xp", 0)))
	coins = max(0, int(data.get("coins", 250)))
	var saved_upgrades: Dictionary = data.get("upgrades", {})
	for key in UPGRADE_KEYS:
		upgrades[key] = clamp(int(saved_upgrades.get(key, 0)),0,int(rule("upgrade.max_level",10)))
	ship.set_meta("coins", coins)
	_apply_upgrades()
	progression_changed.emit()


func set_ship_base_stats(health_value: float, damage_value: float, speed_value: float) -> void:
	_base_health = health_value
	_base_damage = damage_value
	_base_speed = speed_value
	_apply_upgrades()
	progression_changed.emit()


func _apply_upgrades() -> void:
	var previous_max: float = max(1.0, health.max_health)
	var health_ratio: float = health.current_health / previous_max
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	var hull_mult := inventory.m162_multiplier("hull_pct") if inventory != null else 1.0
	health.max_health=_base_health*(1.0+int(upgrades.hull)*float(rule("upgrade.hull_per_level",0.12)))*hull_mult
	health.current_health = clamp(health.max_health * health_ratio, 1.0, health.max_health)
	weapons.damage=_base_damage*(1.0+int(upgrades.cannon)*float(rule("upgrade.cannon_per_level",0.10)))
	var speed_mult := inventory.m162_multiplier("movement_pct") if inventory != null else 1.0
	ship.cruise_speed=_base_speed*(1.0+int(upgrades.sails)*float(rule("upgrade.sails_per_level",0.045)))*speed_mult

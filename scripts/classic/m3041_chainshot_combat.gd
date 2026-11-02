extends "res://scripts/classic/m304_shipyard_hud.gd"
## M304.1: real chain-shot gameplay inspired by the ammunition systems observed
## in sea-combat references. All assets here are ORIGINAL to Abyssal Dominion.
## The third-party Unity APKs are research input ONLY and are not distributed.
const CHAIN_ICON: Texture2D = preload("res://assets/classic/original_ui/chainshot.svg")
const CHAIN_DAMAGE := 12
const CHAIN_RIGGING_SECONDS := 6.0
const CHAIN_AMMO_RESTOCK_COST := 20
const CHAIN_AMMO_RESTOCK_AMOUNT := 15
var chainballs: int = 18
var _ammo_chain: Button
var _restock_chain_button: Button

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304.1 · NORDMEER 10/2"
	_refresh()


func _make_hud() -> void:
	super._make_hud()
	_ammo_chain = _create_ammo_button("KETTENGESCHOSS", CHAIN_ICON, Callable(self, "_select_chain"))
	_ammo_chain.name = "AmmoQuick_KETTE"
	_restock_chain_button = _control("KETTENGESCHOSSE · +15 / 20 GOLD", Callable(self, "_restock_chain"))
	_restock_chain_button.name = "ChainShotRestock"
	# Place the ammunition counter at the bottom of the live shipyard.
	_ui_root.remove_child(_restock_chain_button)
	_yard_panel.add_child(_restock_chain_button)


func _layout_hud() -> void:
	super._layout_hud()
	if _ammo_chain == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var compact := screen.y < 540.0 or screen.x < 1024.0
	var margin := 10.0 if compact else 16.0
	var button_height := 46.0 if compact else 54.0
	var button_width := 62.0 if compact else 76.0
	var gap := 4.0
	var total_width := button_width * 3.0 + gap * 2.0
	var x := (screen.x - total_width) * 0.5
	var y := screen.y - button_height - margin
	_place(_ammo_cannon, x, y, button_width, button_height)
	_place(_ammo_harpoon, x + button_width + gap, y, button_width, button_height)
	_place(_ammo_chain, x + (button_width + gap) * 2.0, y, button_width, button_height)
	if _restock_chain_button != null and _yard_panel != null:
		var bounds := _yard_panel.size
		_place(_restock_chain_button, 16.0, bounds.y - 102.0, bounds.x - 32.0, 43.0)


func _select_chain() -> void:
	if chainballs <= 0:
		hint = "Kettengeschosse leer · Nachschub in der Werft"
		_refresh()
		return
	weapon_mode = "chain"
	firing = false
	reload = 0.0
	hint = "Kettengeschosse: Segel beschädigen · Gegner 6 Sek. geschwächt"
	_refresh()


func _restock_chain() -> void:
	if gold < CHAIN_AMMO_RESTOCK_COST:
		hint = "20 Gold für 15 Kettengeschosse benötigt"
	else:
		gold -= CHAIN_AMMO_RESTOCK_COST
		chainballs += CHAIN_AMMO_RESTOCK_AMOUNT
		hint = "+15 Kettengeschosse geladen"
	_refresh()


func _refresh() -> void:
	super._refresh()
	if _ammo_chain == null:
		return
	_ammo_chain.text = str(chainballs)
	_ammo_chain.disabled = chainballs <= 0
	_style_ammo_slot(_ammo_chain, weapon_mode == "chain")
	if weapon_mode == "chain" and harpoon_button != null:
		harpoon_button.text = "KETTE · %d" % chainballs
	if _restock_chain_button != null:
		_restock_chain_button.disabled = gold < CHAIN_AMMO_RESTOCK_COST


func _fire() -> void:
	if weapon_mode != "chain":
		super._fire()
		return
	if ship == null or target < 0 or target >= enemies.size():
		firing = false
		hint = "Erst ein Schiff als Ziel auswählen"
		_refresh()
		return
	var enemy: Dictionary = enemies[target]
	var actor: Node3D = enemy["node"]
	if str(enemy.get("kind", "ship")) != "ship":
		firing = false
		hint = "Kettengeschosse nur gegen Schiffe · Harpune für Monster"
		_refresh()
		return
	if int(enemy["hp"]) <= 0 or not is_instance_valid(actor):
		firing = false
		hint = "Ziel bereits versenkt"
		_refresh()
		return
	var distance: float = ship.position.distance_to(actor.position)
	if distance > 42.0:
		hint = "Kettengeschoss außer Reichweite · näher heranfahren"
		_refresh()
		return
	if chainballs <= 0:
		firing = false
		hint = "Kettengeschosse leer"
		_refresh()
		return
	chainballs -= 1
	var muzzle := ship.global_position + Vector3(0.0, 2.6, 0.0) + ship.global_transform.basis.x * 1.6
	_emit_puff(muzzle, Color(0.87, 0.79, 0.66, 0.52), 0.65)
	_launch_chainshot(muzzle, actor, target)
	hint = "Kettengeschoss abgefeuert"
	_refresh()


func _launch_chainshot(start: Vector3, actor: Node3D, index: int) -> void:
	if _projectile_layer == null or not is_instance_valid(actor):
		return
	var projectile := Node3D.new()
	projectile.name = "PhysicalChainShot"
	_projectile_layer.add_child(projectile)
	projectile.global_position = start
	var dark_steel := StandardMaterial3D.new()
	dark_steel.albedo_color = Color("3a454a")
	dark_steel.metallic = 0.85
	dark_steel.roughness = 0.32
	for offset in [-0.64, 0.64]:
		var ball := SphereMesh.new()
		ball.radius = 0.28
		ball.height = 0.56
		_add_mesh(projectile, ball, dark_steel, Vector3(offset, 0.0, 0.0))
	var link := CylinderMesh.new()
	link.top_radius = 0.06
	link.bottom_radius = 0.06
	link.height = 1.25
	var chain := _add_mesh(projectile, link, dark_steel, Vector3.ZERO)
	chain.rotation.z = PI * 0.5
	var duration: float = clampf(start.distance_to(actor.global_position) / 34.0, 0.33, 0.93)
	_active_shots += 1
	var flight := create_tween()
	flight.tween_method(Callable(self, "_move_chainshot").bind(projectile, actor, start),
		0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	flight.tween_callback(Callable(self, "_chain_impact").bind(index, actor))
	flight.tween_callback(Callable(self, "_finish_shot").bind(projectile))


func _move_chainshot(progress: float, projectile: Node3D, actor: Node3D, start: Vector3) -> void:
	if not is_instance_valid(projectile) or not is_instance_valid(actor):
		return
	var finish := actor.global_position + Vector3(0.0, 2.4, 0.0)
	projectile.global_position = start.lerp(finish, progress) + Vector3.UP * sin(progress * PI) * 1.45
	projectile.rotation.y += 0.21


func _chain_impact(index: int, actor: Node3D) -> void:
	if index < 0 or index >= enemies.size() or not is_instance_valid(actor):
		return
	var enemy: Dictionary = enemies[index]
	if int(enemy["hp"]) <= 0:
		return
	# Actual combat consequence: rigging damage halves hostile outgoing
	# cannon damage for 6 seconds. No fake speed penalty on static NPCs.
	enemy["rigged_until_ms"] = Time.get_ticks_msec() + int(CHAIN_RIGGING_SECONDS * 1000.0)
	enemies[index] = enemy
	_damage_number(actor.global_position, "SEGEL BESCHÄDIGT", Color("94ced2"))
	_player_impact(index, actor, CHAIN_DAMAGE)


func _enemy_attack() -> void:
	if ship == null or hull <= 0:
		return
	var attackers := 0
	for enemy: Dictionary in enemies:
		if attackers >= 2:
			break
		if str(enemy.get("kind", "ship")) != "ship" or int(enemy["hp"]) <= 0:
			continue
		var actor: Node3D = enemy["node"]
		if not is_instance_valid(actor) or actor.position.distance_to(ship.position) > 23.0:
			continue
		attackers += 1
		var weakened: bool = int(enemy.get("rigged_until_ms", 0)) > Time.get_ticks_msec()
		var damage: int = 2 if weakened else 5
		var muzzle := actor.global_position + Vector3(0.0, 2.5, 0.0)
		_emit_puff(muzzle, Color(0.91, 0.72, 0.56, 0.5), 0.55)
		_spawn_shot(muzzle, ship, Color("ffa07b"),
			Callable(self, "_enemy_impact").bind(damage), false)

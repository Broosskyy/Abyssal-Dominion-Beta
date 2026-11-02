extends "res://scripts/classic/m3036_unified_sea_map.gd"
## M303.7: local, visually simulated naval combat + heading-coupled sailing.
## Keeps M303.6 HUD/world/sprite packs and all local gameplay state.
## No authority/networking is implied: projectiles and damage are local.
const SEA_MAX_SPEED := 11.0
const SEA_ACCEL := 14.0
const SEA_TURN_RATE := 112.0
const SEA_MIN_ZOOM := 34.5 # previous limit was 44 (about 22% closer)
const CANNON_DAMAGE := 24
const HARPOON_DAMAGE := 20

var _projectile_layer: Node3D
var _active_shots := 0

func _ready() -> void:
	super._ready()
	_projectile_layer = Node3D.new()
	_projectile_layer.name = "M3037ProjectileEffects"
	add_child(_projectile_layer)
	hint = "Wasser: Kurs · Schiff: Ziel · FEUER: Angreifen"
	_refresh()


func _sail(delta: float) -> void:
	if ship == null:
		return
	var ship_sprite := ship.get_node_or_null("ShipSprite")
	if route.is_empty():
		_sea_speed = move_toward(_sea_speed, 0.0, SEA_ACCEL * delta)
		if ship_sprite != null and ship_sprite.has_method("set_moving"):
			ship_sprite.set_moving(false)
		if _wake_visual != null:
			_wake_visual.visible = false
		return
	var gap: Vector3 = route[0] - ship.position
	gap.y = 0.0
	var distance := gap.length()
	if distance < 0.8:
		route.remove_at(0)
		if route.is_empty():
			_sea_speed = 0.0
		return
	var heading := atan2(-gap.x, -gap.z)
	ship.rotation.y = rotate_toward(ship.rotation.y, heading, deg_to_rad(SEA_TURN_RATE) * delta)
	var angle := absf(angle_difference(ship.rotation.y, heading))
	# Rotation before translation: no "sliding sideways" toward the target.
	# At sharp turns we slow down, then advance only in the direction of the bow.
	var alignment := clampf((0.65 - angle) / 0.40, 0.0, 1.0)
	var approach := clampf((distance - 0.4) / 5.0, 0.0, 1.0)
	var desired_speed := SEA_MAX_SPEED * alignment * approach
	_sea_speed = move_toward(_sea_speed, desired_speed, SEA_ACCEL * delta)
	var bow := Vector3(-sin(ship.rotation.y), 0.0, -cos(ship.rotation.y))
	var step := minf(_sea_speed * delta, distance)
	var next_point := ship.position + bow * step
	if step > 0.001 and _blocked(next_point):
		route.clear()
		_sea_speed = 0.0
		hint = "Küste blockiert den Kurs · anderes Ziel wählen"
		_refresh()
		return
	ship.position = next_point
	if ship_sprite != null:
		if ship_sprite.has_method("set_heading"):
			ship_sprite.set_heading(ship.rotation.y)
		if ship_sprite.has_method("set_moving"):
			ship_sprite.set_moving(_sea_speed > 0.3)
	if _wake_visual != null:
		_wake_visual.visible = _sea_speed > 0.6
		_wake_visual.scale.z = 0.25 + 0.65 * _sea_speed / SEA_MAX_SPEED


func _fire() -> void:
	if ship == null or target < 0 or target >= enemies.size():
		firing = false
		hint = "Erst einen Gegner auswählen"
		_refresh()
		return
	var enemy: Dictionary = enemies[target]
	var enemy_node: Node3D = enemy["node"]
	if int(enemy["hp"]) <= 0 or not is_instance_valid(enemy_node):
		firing = false
		hint = "Ziel bereits versenkt"
		_refresh()
		return
	var monster := str(enemy.get("kind", "ship")) == "monster"
	if (monster and weapon_mode != "harpoon") or (not monster and weapon_mode != "cannon"):
		firing = false
		hint = "Harpunen gegen Monster · Kanonen gegen Schiffe"
		_refresh()
		return
	var distance := ship.position.distance_to(enemy_node.position)
	if distance > (35.0 if monster else 42.0):
		# Preserve auto-fire: the player can continue to approach the enemy.
		hint = "Außer Reichweite (%d m) · näher heranfahren" % roundi(distance)
		_refresh()
		return
	if (monster and harpoons <= 0) or (not monster and cannonballs <= 0):
		firing = false
		hint = "Keine passende Munition"
		_refresh()
		return
	if monster:
		harpoons -= 1
	else:
		cannonballs -= 1
	var enemy_index := target
	var damage := HARPOON_DAMAGE if monster else CANNON_DAMAGE
	var muzzle := ship.global_position + Vector3(0.0, 2.6, 0.0) + ship.global_transform.basis.x * 1.6
	_emit_puff(muzzle, Color(0.95, 0.84, 0.61, 0.55), 0.6)
	_spawn_shot(muzzle, enemy_node, Color("7ce5ed") if monster else Color("ffc36d"),
			Callable(self, "_player_impact").bind(enemy_index, enemy_node, damage), monster)
	hint = "Harpune abgefeuert" if monster else "Kanone abgefeuert"
	_refresh()


func _enemy_attack() -> void:
	if ship == null or hull <= 0:
		return
	var attackers := 0
	for enemy in enemies:
		if attackers >= 2:
			break
		if str(enemy.get("kind", "ship")) != "ship" or int(enemy["hp"]) <= 0:
			continue
		var enemy_node: Node3D = enemy["node"]
		if not is_instance_valid(enemy_node) or enemy_node.position.distance_to(ship.position) > 23.0:
			continue
		attackers += 1
		var muzzle := enemy_node.global_position + Vector3(0.0, 2.5, 0.0)
		_emit_puff(muzzle, Color(0.91, 0.72, 0.56, 0.5), 0.55)
		_spawn_shot(muzzle, ship, Color("ffa07b"), Callable(self, "_enemy_impact").bind(5), false)


func _spawn_shot(origin: Vector3, destination: Node3D, tint: Color, hit_callback: Callable, harpoon: bool) -> void:
	if _projectile_layer == null or not is_instance_valid(destination):
		return
	var projectile := MeshInstance3D.new()
	projectile.name = "Harpoon" if harpoon else "Cannonball"
	var sphere := SphereMesh.new()
	sphere.radius = 0.25 if harpoon else 0.34
	sphere.height = 0.50 if harpoon else 0.68
	projectile.mesh = sphere
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = tint
	glow.emission_enabled = true
	glow.emission = tint
	glow.emission_energy_multiplier = 1.5
	projectile.material_override = glow
	_projectile_layer.add_child(projectile)
	projectile.global_position = origin
	var distance := origin.distance_to(destination.global_position)
	var flight := clampf(distance / 34.0, 0.28, 0.85)
	_active_shots += 1
	var tween := create_tween()
	tween.tween_method(Callable(self, "_move_shot").bind(projectile, destination, origin),
			0.0, 1.0, flight).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(hit_callback)
	tween.tween_callback(Callable(self, "_finish_shot").bind(projectile))


func _move_shot(progress: float, projectile: Node3D, destination: Node3D, start: Vector3) -> void:
	if not is_instance_valid(projectile) or not is_instance_valid(destination):
		return
	var endpoint := destination.global_position + Vector3(0.0, 2.6, 0.0)
	projectile.global_position = start.lerp(endpoint, progress) + Vector3.UP * sin(progress * PI) * 1.3


func _finish_shot(projectile: Node3D) -> void:
	_active_shots = maxi(0, _active_shots - 1)
	if is_instance_valid(projectile):
		projectile.queue_free()


func _player_impact(index: int, actor: Node3D, damage: int) -> void:
	if index < 0 or index >= enemies.size() or not is_instance_valid(actor):
		return
	var enemy: Dictionary = enemies[index]
	if int(enemy["hp"]) <= 0:
		return
	enemy["hp"] = maxi(0, int(enemy["hp"]) - damage)
	enemies[index] = enemy
	_impact_flash(actor.global_position + Vector3(0.0, 2.6, 0.0), Color("ffd28a"))
	_damage_number(actor.global_position, "-%d" % damage, Color("ffe49b"))
	var plate: Label3D = enemy["plate"]
	if is_instance_valid(plate):
		plate.text = "%s · %d HP" % [str(enemy["name"]), int(enemy["hp"])]
	hint = "Treffer · %d Schaden" % damage
	if int(enemy["hp"]) <= 0:
		_impact_flash(actor.global_position + Vector3(0.0, 2.4, 0.0), Color("ff744d"))
		_create_loot(actor.position, 45 if str(enemy.get("kind", "")) == "monster" else 25)
		var sinking := create_tween()
		sinking.tween_property(actor, "position:y", actor.position.y - 3.0, 0.75)
		sinking.tween_callback(Callable(self, "_hide_sunken_ship").bind(actor))
		kills += 1
		if target == index:
			target = -1
			firing = false
		hint = "Gegner versenkt · Beute einsammeln"
	_refresh()


func _hide_sunken_ship(actor: Node3D) -> void:
	if is_instance_valid(actor):
		actor.visible = false


func _enemy_impact(damage: int) -> void:
	if ship == null:
		return
	_impact_flash(ship.global_position + Vector3(0.0, 2.4, 0.0), Color("ff786a"))
	_damage_number(ship.global_position, "-%d" % damage, Color("ff8b79"))
	hull = maxi(0, hull - damage)
	hint = "Gegnerischer Treffer · Rumpf %d" % hull
	if hull <= 0:
		firing = false
		route.clear()
		_sea_speed = 0.0
		ship.position = Vector3(0.0, 0.65, 0.0)
		hull = 100
		hint = "Schiff gesunken · Respawn am Startpunkt"
	_refresh()


func _impact_flash(at: Vector3, tint: Color) -> void:
	if _projectile_layer == null:
		return
	var flash := MeshInstance3D.new()
	flash.name = "ImpactFlash"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.75)
	flash.material_override = mat
	_projectile_layer.add_child(flash)
	flash.global_position = at
	flash.scale = Vector3.ONE * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * 2.4, 0.4)
	tween.tween_property(flash, "transparency", 1.0, 0.4)
	tween.chain().tween_callback(flash.queue_free)


func _emit_puff(at: Vector3, tint: Color, size: float) -> void:
	if _projectile_layer == null:
		return
	var smoke := MeshInstance3D.new()
	smoke.name = "MuzzleSmoke"
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	smoke.mesh = sphere
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = tint
	smoke.material_override = material
	_projectile_layer.add_child(smoke)
	smoke.global_position = at
	var tween := create_tween().set_parallel(true)
	tween.tween_property(smoke, "scale", Vector3.ONE * 2.0, 0.45)
	tween.tween_property(smoke, "transparency", 1.0, 0.45)
	tween.chain().tween_callback(smoke.queue_free)


func _damage_number(at: Vector3, text_value: String, tint: Color) -> void:
	if _projectile_layer == null:
		return
	var number := Label3D.new()
	number.name = "FloatingDamage"
	number.text = text_value
	number.font_size = 72
	number.pixel_size = 0.025
	number.outline_size = 7
	number.modulate = tint
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_projectile_layer.add_child(number)
	number.global_position = at + Vector3(0.0, 5.0, 0.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(number, "position", number.position + Vector3.UP * 3.2, 0.85)
	tween.tween_property(number, "modulate:a", 0.0, 0.85)
	tween.chain().tween_callback(number.queue_free)


func _zoom_in() -> void:
	zoom = maxf(SEA_MIN_ZOOM, zoom - 6.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		var scale_factor := (event as InputEventMagnifyGesture).factor
		if scale_factor > 0.0:
			zoom = clampf(zoom / scale_factor, SEA_MIN_ZOOM, 135.0)
			get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

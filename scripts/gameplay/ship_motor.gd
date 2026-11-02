class_name ShipMotor
extends CharacterBody3D

@export var is_player := false
@export var cruise_speed := 6.5
@export var acceleration := 3.2
@export var turn_speed_degrees := 56.0

var throttle_input := 0.0
var turn_input := 0.0
var current_speed := 0.0
var speed_effects: Dictionary = {}


func add_speed_effect(id: String, multiplier: float, duration: float) -> void:
	speed_effects[id] = {"multiplier": clampf(multiplier, 0.1, 3.0), "remaining": maxf(duration, 0.0)}


func tick_speed_effects(delta: float) -> void:
	for id in speed_effects.keys():
		speed_effects[id].remaining -= delta
		if speed_effects[id].remaining <= 0.0:
			speed_effects.erase(id)


func effective_speed() -> float:
	var result := cruise_speed
	var inventory := get_node_or_null("Inventory") as PlayerInventory
	if inventory != null:
		result *= inventory.module_modifier("speed_mult", 1.0)
	result *= clampf(float(get_meta("ancient_speed_mult",1.0)),0.9,1.10)
	for effect in speed_effects.values():
		result *= float(effect.multiplier)
	return result


func _physics_process(delta: float) -> void:
	tick_speed_effects(delta)
	var navigation_pivot := is_player and bool(get_meta("navigation_pivoting", false))
	var acceleration_scale := 4.0 if navigation_pivot else 1.0
	current_speed = move_toward(current_speed, throttle_input * effective_speed(), acceleration * acceleration_scale * delta)
	var turn_scale: float = 1.0 if navigation_pivot else lerp(0.35, 1.0, clamp(abs(current_speed) / max(cruise_speed, 0.01), 0.0, 1.0))
	var navigation_turn_assist := 1.12 if navigation_pivot else 1.0
	rotate_y(deg_to_rad(turn_input * turn_speed_degrees * navigation_turn_assist * turn_scale * delta))
	velocity = global_transform.basis.z.normalized() * current_speed
	velocity.y = 0.0
	move_and_slide()
	position.y = 0.55


func stop_ship() -> void:
	current_speed = 0.0
	throttle_input = 0.0
	turn_input = 0.0
	velocity = Vector3.ZERO

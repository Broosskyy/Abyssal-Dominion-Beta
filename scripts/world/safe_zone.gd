class_name SafeZone
extends Area3D

var spawn_position := Vector3.ZERO
var zone_name := "Safe Harbor"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body is ShipMotor:
		return
	body.set_meta("in_safe_zone", true)
	body.set_meta("safe_zone_name", zone_name)
	if body.is_in_group("player"):
		var health := body.get_node_or_null("Health") as ShipHealth
		if health != null:
			health.respawn_position = spawn_position


func _on_body_exited(body: Node3D) -> void:
	if not body is ShipMotor:
		return
	body.set_meta("in_safe_zone", false)
	body.remove_meta("safe_zone_name")

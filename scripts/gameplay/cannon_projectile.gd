class_name CannonProjectile
extends Area3D

const ImpactFxScript = preload("res://scripts/visual/impact_fx.gd")
const WaterSplashScript = preload("res://scripts/visual/water_splash.gd")

var source_ship: Node3D
var travel_velocity := Vector3.ZERO
var damage := 0.0
var armor_pierce := 0.0
var slow := 0.0
var trail_color := Color("ff752c")
var life_seconds := 3.0
var consumed := false
var render_visual := true
var critical_hit := false
var locked_target: ShipMotor
var visual_id := "cannonball"
var range_remaining := 60.0
var status_effect := "none"
var effect_power := 0.0
var effect_duration := 0.0
var ammo_id := "iron"


func _ready() -> void:
	add_to_group("sector_projectiles")
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if render_visual:
		_build_visual()
	# Reduced rendering never removes collision shapes or logical projectiles.
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.14
	collision.shape = shape
	add_child(collision)


func _build_visual() -> void:

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.30
	mesh_instance.mesh = sphere
	mesh_instance.material_override = ProceduralFactory.material(Color("151619"), 0.25, 0.8)
	add_child(mesh_instance)
	if AssetVisualLibrary.placeholders(get_tree()) and AssetVisualLibrary.install(self, visual_id, Vector3.ONE * 0.8) != null:
		mesh_instance.hide()
	var trail := MeshInstance3D.new()
	trail.name = "Trail" # M215 keeps projectile direction readable at master-reference zoom
	var trail_mesh := CylinderMesh.new()
	trail_mesh.top_radius = 0.032
	trail_mesh.bottom_radius = 0.115
	trail_mesh.height = 1.58
	trail.mesh = trail_mesh
	trail.rotation_degrees.x = 90.0
	trail.position.z = -0.84
	var trail_material := StandardMaterial3D.new()
	trail_material.albedo_color = Color(trail_color, 0.64)
	trail_material.emission_enabled = true
	trail_material.emission = trail_color
	trail_material.emission_energy_multiplier = 2.45
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail.material_override = trail_material
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.set_meta("visual_only", true)
	trail.set_meta("m215_reference_zoom_readability", true)
	add_child(trail)

func configure(source: Node3D, spawn_position: Vector3, velocity_value: Vector3, damage_value: float, pierce_value: float = 0.0, slow_value: float = 0.0, color_value: Color = Color("ff752c"), effect_id: String = "none", effect_strength: float = 0.0, effect_time: float = 0.0, ammo_visual_id: String = "iron") -> void:
	source_ship = source
	global_position = spawn_position
	travel_velocity = velocity_value
	damage = damage_value
	armor_pierce = pierce_value
	slow = slow_value
	trail_color = color_value
	status_effect = effect_id
	effect_power = effect_strength
	effect_duration = effect_time
	ammo_id = ammo_visual_id
	var trail := get_node_or_null("Trail") as MeshInstance3D
	if trail != null and trail.material_override is StandardMaterial3D:
		trail.material_override.albedo_color = Color(trail_color, 0.64)
		trail.material_override.emission = trail_color
	_apply_ammo_visual_profile()
	if travel_velocity.length_squared() > 0.01:
		look_at(global_position + travel_velocity.normalized(), Vector3.UP, true)


func _apply_ammo_visual_profile() -> void:
	if not render_visual:
		return
	var trail := get_node_or_null("Trail") as MeshInstance3D
	if trail == null:
		return
	var mesh := trail.mesh as CylinderMesh
	if mesh != null:
		match ammo_id:
			"chain":
				mesh.top_radius = 0.05; mesh.bottom_radius = 0.11; mesh.height = 0.95
			"piercing":
				mesh.top_radius = 0.018; mesh.bottom_radius = 0.055; mesh.height = 1.75
			"ember":
				mesh.top_radius = 0.04; mesh.bottom_radius = 0.13; mesh.height = 1.55
			"venom":
				mesh.top_radius = 0.05; mesh.bottom_radius = 0.12; mesh.height = 1.45
			"shatter":
				mesh.top_radius = 0.03; mesh.bottom_radius = 0.10; mesh.height = 1.25
			"spectral":
				mesh.top_radius = 0.025; mesh.bottom_radius = 0.10; mesh.height = 1.9
			"explosive":
				mesh.top_radius = 0.055; mesh.bottom_radius = 0.15; mesh.height = 1.25
			_:
				pass
	var material := trail.material_override as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = 2.8 if ammo_id in ["ember", "venom", "spectral"] else 2.0
	if ammo_id in ["ember", "venom", "spectral", "shatter", "chain"]:
		_add_secondary_trail()

func _add_secondary_trail() -> void:
	var secondary := MeshInstance3D.new()
	secondary.name = "SecondaryTrail"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.045 if ammo_id != "spectral" else 0.065
	mesh.height = 1.0 if ammo_id == "chain" else 1.65
	secondary.mesh = mesh
	secondary.rotation_degrees.x = 90.0
	secondary.position = Vector3(0.08 if ammo_id in ["chain", "shatter"] else 0.0, 0.05, -0.82)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(trail_color.lightened(0.2), 0.42)
	mat.emission_enabled = true
	mat.emission = trail_color.lightened(0.18)
	mat.emission_energy_multiplier = 3.2
	secondary.material_override = mat
	add_child(secondary)

func _physics_process(delta: float) -> void:
	if consumed: return
	if not is_instance_valid(locked_target) or (locked_target.get_node("Health") as ShipHealth).is_sunk:
		queue_free()
		return
	var aim := locked_target.global_position + Vector3.UP * 0.3
	var offset := aim - global_position
	var step := minf(travel_velocity.length() * delta, minf(offset.length(), range_remaining))
	var next := global_position + offset.normalized() * step
	var query := PhysicsRayQueryParameters3D.create(global_position, next, collision_mask)
	if is_instance_valid(source_ship) and source_ship is CollisionObject3D: query.exclude = [source_ship.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_on_body_entered(hit.collider)
		if consumed: return
	global_position = next
	range_remaining -= step
	if offset.length() <= step + 0.15:
		_on_body_entered(locked_target)
		return
	if offset.length_squared() > 0.001: look_at(global_position + offset.normalized(), Vector3.UP, true)
	life_seconds -= delta
	if life_seconds <= 0.0 or range_remaining <= 0:
		_spawn_water_splash()
		queue_free()


func _spawn_water_splash() -> void:
	if not render_visual or is_queued_for_deletion():
		return
	var splash: WaterSplash = WaterSplashScript.new()
	splash.name = "WaterSplash"
	GameScope.owner_of(self).add_child(splash)
	splash.global_position = Vector3(global_position.x, 0.08, global_position.z)


func _on_body_entered(body: Node3D) -> void:
	if consumed or is_queued_for_deletion():
		return
	if is_instance_valid(source_ship):
		if body == source_ship:
			return
		if body.is_in_group("ships") and body.is_in_group("player") == source_ship.is_in_group("player"):
			return
	consumed = true
	var health := body.get_node_or_null("Health") as ShipHealth
	if health != null and body == locked_target:
		var attacker: Node3D = source_ship if is_instance_valid(source_ship) else null
		health.apply_damage(damage, attacker, armor_pierce, slow, critical_hit)
		if status_effect != "none": health.apply_ammo_effect(status_effect, effect_power, effect_duration, attacker)
		CombatVfx.ammo_impact(get_tree(), status_effect, global_position, ammo_id)
	if render_visual:
		var impact: ImpactFx = ImpactFxScript.new()
		impact.name = "ImpactFX"
		GameScope.owner_of(self).add_child(impact)
		impact.global_position = global_position
	queue_free()

class_name ShipWake
extends Node3D

var port_wake: MeshInstance3D
var starboard_wake: MeshInstance3D
var stern_foam: MeshInstance3D
var bow_foam: MeshInstance3D
var center_turbulence: MeshInstance3D
var m215_stern_break: MeshInstance3D
var m215_wake_spine: MeshInstance3D
@onready var ship: ShipMotor = get_parent() as ShipMotor


func _ready() -> void:
	port_wake = _create_wake_strip("WakePort", -0.74)
	starboard_wake = _create_wake_strip("WakeStarboard", 0.74)
	stern_foam = _create_stern_foam()
	bow_foam = _create_bow_foam()
	center_turbulence = _create_center_turbulence()
	m215_stern_break = _create_m215_stern_break()
	m215_wake_spine = _create_m215_wake_spine()
	add_child(port_wake)
	add_child(starboard_wake)
	add_child(stern_foam)
	add_child(bow_foam)
	add_child(center_turbulence)
	add_child(m215_stern_break)
	add_child(m215_wake_spine)


func _process(_delta: float) -> void:
	var speed_ratio: float = clamp(abs(ship.current_speed) / max(ship.cruise_speed, 0.01), 0.0, 1.15)
	var turn_ratio: float = clamp(abs(ship.turn_input), 0.0, 1.0)
	var settings := ClientSettings.current(get_tree())
	var motion := 0.35 if settings != null and settings.values.reduced_motion else 1.0
	var pulse := 0.96 + sin(Time.get_ticks_msec() * 0.0055 * motion) * 0.04
	var length: float = lerp(0.5, 6.6, minf(speed_ratio, 1.0))
	var opacity: float = lerp(0.0, 0.52, minf(speed_ratio, 1.0)) * pulse
	for index in 2:
		var strip := port_wake if index == 0 else starboard_wake
		strip.scale.z = length
		strip.scale.x = lerp(0.82, 1.22, turn_ratio)
		strip.position.z = -2.3 - length * 0.5
		strip.rotation_degrees.y = (-5.0 if index == 0 else 5.0) + ship.turn_input * (9.0 if index == 0 else -9.0)
		var wake_material := strip.material_override as StandardMaterial3D
		wake_material.albedo_color.a = opacity
	stern_foam.scale = Vector3(lerp(0.55, 1.55, minf(speed_ratio, 1.0)), 1.0, lerp(0.45, 1.35, minf(speed_ratio, 1.0)))
	var stern_material := stern_foam.material_override as StandardMaterial3D
	stern_material.albedo_color.a = lerp(0.0, 0.38, minf(speed_ratio, 1.0)) * pulse
	bow_foam.scale = Vector3(lerp(0.55, 1.35, minf(speed_ratio, 1.0)), 1.0, lerp(0.45, 1.0, minf(speed_ratio, 1.0)))
	var bow_material := bow_foam.material_override as StandardMaterial3D
	bow_material.albedo_color.a = lerp(0.0, 0.34, minf(speed_ratio, 1.0)) * pulse
	center_turbulence.scale = Vector3(lerp(0.45, 1.05, minf(speed_ratio, 1.0)), 1.0, lerp(0.55, 4.8, minf(speed_ratio, 1.0)))
	center_turbulence.position.z = -2.25 - center_turbulence.scale.z * 0.48
	var center_material := center_turbulence.material_override as StandardMaterial3D
	center_material.albedo_color.a = lerp(0.0, 0.20, minf(speed_ratio, 1.0)) * pulse

	# M215: long-range reference readability. These are visual-only wake layers and
	# never affect ship collision, movement speed, steering, or navigation.
	m215_stern_break.scale = Vector3(lerp(0.50, 1.45, minf(speed_ratio, 1.0)), 1.0, lerp(0.35, 1.20, minf(speed_ratio, 1.0)))
	var break_material := m215_stern_break.material_override as StandardMaterial3D
	break_material.albedo_color.a = lerp(0.0, 0.46, minf(speed_ratio, 1.0)) * pulse
	m215_wake_spine.scale = Vector3(lerp(0.35, 0.82, minf(speed_ratio, 1.0)), 1.0, lerp(0.75, 5.8, minf(speed_ratio, 1.0)))
	m215_wake_spine.position.z = -2.45 - m215_wake_spine.scale.z * 0.54
	var spine_material := m215_wake_spine.material_override as StandardMaterial3D
	spine_material.albedo_color.a = lerp(0.0, 0.16, minf(speed_ratio, 1.0)) * pulse


func _create_wake_strip(strip_name: String, x_position: float) -> MeshInstance3D:
	var strip := MeshInstance3D.new()
	strip.name = strip_name
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.48, 1.0)
	strip.mesh = plane
	strip.position = Vector3(x_position, -0.48, -2.4)
	strip.material_override = _foam_material()
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return strip


func _create_stern_foam() -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	foam.name = "SternFoam"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.4, 1.25)
	foam.mesh = plane
	foam.position = Vector3(0.0, -0.475, -2.45)
	foam.material_override = _foam_material()
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return foam



func _create_bow_foam() -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	foam.name = "BowFoam"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.75, 0.8)
	foam.mesh = plane
	foam.position = Vector3(0.0, -0.47, 2.35)
	foam.material_override = _foam_material()
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return foam


func _create_center_turbulence() -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	foam.name = "M191CenterTurbulence"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.64, 1.0)
	foam.mesh = plane
	foam.position = Vector3(0.0, -0.49, -2.8)
	foam.material_override = _foam_material()
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	foam.set_meta("visual_only", true)
	return foam

func _create_m215_stern_break() -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	foam.name = "M215SternBreak"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.72
	torus.outer_radius = 0.90
	torus.rings = 18
	torus.ring_segments = 5
	foam.mesh = torus
	foam.position = Vector3(0.0, -0.50, -2.35)
	foam.scale = Vector3(1.0, 0.18, 0.62)
	foam.material_override = _foam_material()
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	foam.set_meta("visual_only", true)
	return foam


func _create_m215_wake_spine() -> MeshInstance3D:
	var foam := MeshInstance3D.new()
	foam.name = "M215WakeSpine"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.52, 1.0)
	foam.mesh = plane
	foam.position = Vector3(0.0, -0.505, -3.1)
	foam.material_override = _foam_material()
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	foam.set_meta("visual_only", true)
	return foam

func _foam_material() -> StandardMaterial3D:
	var wake_material := StandardMaterial3D.new()
	wake_material.albedo_color = Color(0.78, 0.95, 0.98, 0.0)
	wake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wake_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wake_material.vertex_color_use_as_albedo = true
	return wake_material

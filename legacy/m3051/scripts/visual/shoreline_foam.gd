class_name ShorelineFoam
extends MeshInstance3D

var radius := 5.0
var aspect := Vector2.ONE
var phase := 0.0
var pulse := 0.0


func _ready() -> void:
	add_to_group("shoreline_foam")
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.86
	torus.outer_radius = radius * 0.98
	var rings := WorldVisualBudgetCatalog.int_value(get_tree(), "shoreline_segments", 36)
	torus.rings = rings
	torus.ring_segments = 6 if rings <= 24 else (8 if rings <= 36 else 10)
	mesh = torus
	position.y = -0.08
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.76, 0.94, 0.96, 0.28)
	material.emission_enabled = true
	material.emission = Color("9ee8ee")
	material.emission_energy_multiplier = 0.38
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = material
	_add_m199_inner_break(rings)
	phase = radius * 0.71
	scale = Vector3(aspect.x, 1.0, aspect.y)


func _process(_delta: float) -> void:
	var settings := ClientSettings.current(get_tree())
	var motion := 0.30 if settings != null and settings.values.reduced_motion else 1.0
	pulse = sin(Time.get_ticks_msec() * 0.0018 * motion + phase) * (0.012 if motion < 1.0 else 0.022)
	scale = Vector3(aspect.x * (1.0 + pulse), 1.0, aspect.y * (1.0 + pulse))


func _add_m199_inner_break(rings:int) -> void:
	# M199 visual-master pass: a softer second shore break gives islands a readable
	# shallow-water edge without changing collision/navigation or island footprint.
	var inner:=MeshInstance3D.new()
	inner.name="M199InnerShoreBreak"
	var torus:=TorusMesh.new()
	torus.inner_radius=radius*0.78
	torus.outer_radius=radius*0.84
	torus.rings=rings
	torus.ring_segments=6 if rings<=24 else (8 if rings<=36 else 10)
	inner.mesh=torus
	inner.position.y=-0.095
	inner.scale=Vector3(aspect.x,1.0,aspect.y)
	inner.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(0.52,0.88,0.92,0.12)
	m.emission_enabled=true
	m.emission=Color("75d6df")
	m.emission_energy_multiplier=0.18
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	inner.material_override=m
	inner.set_meta("visual_only",true)
	add_child(inner)

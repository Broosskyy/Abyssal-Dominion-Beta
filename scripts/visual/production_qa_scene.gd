class_name ProductionQaScene
extends Node3D
@export var mode := "canonical_scale"

func _ready() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = true
	add_child(light)
	var env := WorldEnvironment.new()
	add_child(env)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("14374a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b9d5e2")
	environment.ambient_light_energy = 0.7
	env.environment = environment
	var camera := Camera3D.new()
	camera.position = Vector3(18, 22, 24)
	camera.rotation_degrees = Vector3(-42, 35, 0)
	camera.current = true
	add_child(camera)
	_build_reference_objects()
	_build_measurement_guides()
	_build_labels()
	_apply_mode_preset(camera)

func _build_reference_objects() -> void:
	var positions := [Vector3(-8,0,0), Vector3(-2,0,0), Vector3(5,0,0), Vector3(12,0,0)]
	var scales := [Vector3(2,0.7,5), Vector3(3,1,7), Vector3(5,1.5,10), Vector3(8,2.2,8)]
	for i in positions.size():
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = scales[i]
		body.mesh = box
		body.position = positions[i] + Vector3(0, scales[i].y*0.5, 0)
		body.set_meta("qa_placeholder", true)
		add_child(body)


func _build_measurement_guides() -> void:
	for x in range(-12, 17, 2):
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.025, 0.02, 22.0)
		marker.mesh = box
		marker.position = Vector3(float(x), 0.015, 0)
		add_child(marker)
	for z in range(-10, 13, 2):
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(30.0, 0.02, 0.025)
		marker.mesh = box
		marker.position = Vector3(2, 0.015, float(z))
		add_child(marker)


func _build_labels() -> void:
	var labels := [
		["SMALL SHIP", Vector3(-8, 2.2, 0)],
		["MEDIUM SHIP", Vector3(-2, 2.7, 0)],
		["LARGE SHIP", Vector3(5, 3.2, 0)],
		["ISLAND / HARBOR MASS", Vector3(12, 4.0, 0)],
	]
	for data in labels:
		var label := Label3D.new()
		label.text = str(data[0])
		label.position = data[1]
		label.font_size = 28
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _apply_mode_preset(camera: Camera3D) -> void:
	if mode.contains("mobile"):
		camera.fov = 48
		camera.position = Vector3(15, 19, 23)
	elif mode.contains("gameplay_camera"):
		camera.fov = 42
		camera.position = Vector3(18, 22, 24)
	elif mode.contains("lod"):
		camera.fov = 50
		camera.position = Vector3(28, 30, 38)
	elif mode.contains("material"):
		camera.fov = 36
		camera.position = Vector3(14, 14, 18)
	camera.look_at(Vector3(2, 0, 0))

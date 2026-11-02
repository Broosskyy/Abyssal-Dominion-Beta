class_name M290FirstSortieVisualRig
extends Node3D
## Replaceable world-guidance placeholder. It never owns collision, navigation or target selection.

var target: Node3D
var target_kind := "NONE"
var marker_root: Node3D


func _ready() -> void:
	set_meta("presentation_only", true)
	set_meta("placeholder_replacement_ready", true)
	set_meta("ship_model_strategy", "ONE_COMPLETE_GLB_PER_SHIP")
	marker_root = Node3D.new()
	marker_root.name = "FirstSortieGuidancePlaceholder"
	add_child(marker_root)
	_build_placeholder()
	marker_root.visible = false
	set_process(true)


func bind_target(value: Node3D, kind: String) -> void:
	target = value
	target_kind = kind
	if marker_root != null: marker_root.visible = target != null and kind not in ["NONE", "PLAYER"]


func _process(_delta: float) -> void:
	if marker_root == null or target == null or not is_instance_valid(target):
		if marker_root != null: marker_root.visible = false
		return
	marker_root.visible = target_kind not in ["NONE", "PLAYER"]
	global_position = target.global_position + Vector3.UP * 4.6
	marker_root.rotation.y += 0.008
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.08
	marker_root.scale = Vector3.ONE * pulse


func _build_placeholder() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "RouteRingPlaceholder"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.72
	torus.outer_radius = 0.92
	ring.mesh = torus
	ring.material_override = _material(Color(0.96, 0.72, 0.22, 0.78), true)
	marker_root.add_child(ring)
	var mast := MeshInstance3D.new()
	mast.name = "GuidanceMastPlaceholder"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.045
	cylinder.bottom_radius = 0.07
	cylinder.height = 1.8
	mast.mesh = cylinder
	mast.position.y = 0.9
	mast.material_override = _material(Color("d7a94f"), false)
	marker_root.add_child(mast)
	var beacon := MeshInstance3D.new()
	beacon.name = "ObjectiveBeaconPlaceholder"
	var sphere := SphereMesh.new()
	sphere.radius = 0.19
	sphere.height = 0.38
	beacon.mesh = sphere
	beacon.position.y = 1.85
	beacon.material_override = _material(Color("61d6ef"), true)
	marker_root.add_child(beacon)


func _material(color: Color, emissive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
	return material


func can_change_navigation_or_collision() -> bool: return false
func can_select_target_or_confirm_objective() -> bool: return false
func can_modify_ship_model_parts() -> bool: return false


class_name VisualQA
extends Node
## Debug-only, opt-in ?qa=1 fixtures. Renders the real scene; never generates art.

static func requested() -> bool:
	return OS.is_debug_build() and OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('qa') === '1'"))


func _ready() -> void:
	if not requested():
		set_process(false)
		return
	JavaScriptBridge.eval("window.sfQAReady = true; window.sfQARequest = null;")
	_freeze.call_deferred()


func _process(_delta: float) -> void:
	var player := get_parent().get_node("WorldMapSystem").player as ShipMotor
	var snapshot := {"inventory_open": player.get_meta("inventory_open", false), "ammo": (player.get_node("Inventory") as PlayerInventory).count("iron")}
	JavaScriptBridge.eval("window.sfQARuntime = " + JSON.stringify(snapshot) + ";")
	var value = JavaScriptBridge.eval("JSON.stringify(window.sfQARequest || null)")
	if not value is String or value == "null":
		return
	JavaScriptBridge.eval("window.sfQARequest = null;")
	var request = JSON.parse_string(value)
	if not request is Dictionary:
		return
	var world := get_parent().get_node("WorldMapSystem") as WorldMapSystem
	var ship := world.player
	var camera := get_viewport().get_camera_3d() as IsometricCameraRig
	match str(request.get("fixture", "")):
		"ship_detail":
			camera.zoom_factor = 0.78
		"harbor":
			ship.position = Vector3(-18, 0.55, 9)
			camera.zoom_factor = 1.45
		"snow":
			world.restore_sector(Vector2i(0, 2))
			ship.position = Vector3.ZERO + Vector3.UP * 0.55
			camera.zoom_factor = 1.45
		"wide":
			camera.zoom_factor = 1.45
		"arsenal":
			var ui := get_parent().get_node("HUDLayer/ArsenalPanel") as ArsenalPanel
			if not ui.shade.visible:
				ui.toggle()
	_freeze.call_deferred()


func _freeze() -> void:
	var world := get_parent().get_node("WorldMapSystem") as WorldMapSystem
	world.set_process(false)
	world.encounters.set_process(false)
	for ship in get_tree().get_nodes_in_group("ships"):
		ship.set_physics_process(false)
		if ship.has_node("EnemyAI"):
			ship.get_node("EnemyAI").set_process(false)
	JavaScriptBridge.eval("window.sfQAFixtureReady = true;")

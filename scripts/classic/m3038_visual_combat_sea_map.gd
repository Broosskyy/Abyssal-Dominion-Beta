extends "res://scripts/classic/m3037_combat_sea_map.gd"
## M303.8: actual local-game presentation, NOT a mockup.
## Original reusable ammo 3D meshes + SVG quickslots, existing SeaBattles and
## SeaOfBones private ship/island sprites, no changed network/gameplay authority.

const CANNON_ICON: Texture2D = preload("res://assets/classic/original_ui/cannonball.svg")
const HARPOON_ICON: Texture2D = preload("res://assets/classic/original_ui/harpoon.svg")
const AMMO_BAR_MIN_WIDTH := 144.0

var _ammo_cannon: Button
var _ammo_harpoon: Button
var _target_ring: MeshInstance3D
var _ammo_state := ""

func _ready() -> void:
	super._ready()
	_target_ring = MeshInstance3D.new()
	_target_ring.name = "M3038TargetIndicator"
	var ring := TorusMesh.new()
	ring.inner_radius = 2.6
	ring.outer_radius = 2.85
	_target_ring.mesh = ring
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.64, 0.30, 0.72)
	_target_ring.material_override = mat
	add_child(_target_ring)
	_target_ring.visible = false
	_hud_header.text = "ABYSSAL DOMINION  ·  M303.8  ·  NORDMEER 10/2"
	_refresh()


func _make_hud() -> void:
	super._make_hud()
	_ammo_cannon = _create_ammo_button("KANONEN", CANNON_ICON, Callable(self, "_choose_cannon"))
	_ammo_harpoon = _create_ammo_button("HARPUNEN", HARPOON_ICON, Callable(self, "_choose_harpoon"))


func _create_ammo_button(tip: String, artwork: Texture2D, action: Callable) -> Button:
	var button := _control("0", action)
	button.name = "AmmoQuick_" + tip
	button.icon = artwork
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.tooltip_text = tip + " · Tippen zum Auswählen"
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("f7e4b8"))
	return button


func _layout_hud() -> void:
	super._layout_hud()
	if _ammo_cannon == null or _ammo_harpoon == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var small := screen.y < 540.0 or screen.x < 1024.0
	var margin := 10.0 if small else 16.0
	var button_height := 46.0 if small else 54.0
	var button_width := 66.0 if small else 82.0
	var gap := 6.0
	var bar_width := button_width * 2.0 + gap
	var left := (screen.x - bar_width) * 0.5
	var y := screen.y - button_height - margin
	_place(_ammo_cannon, left, y, button_width, button_height)
	_place(_ammo_harpoon, left + button_width + gap, y, button_width, button_height)
	# The existing left/right action groups are kept; their touch rectangles
	# remain separate from this compact middle quickbar.


func _refresh() -> void:
	super._refresh()
	if _ammo_cannon == null or _ammo_harpoon == null:
		return
	_ammo_cannon.text = str(cannonballs)
	_ammo_harpoon.text = str(harpoons)
	_ammo_cannon.disabled = cannonballs <= 0
	_ammo_harpoon.disabled = harpoons <= 0
	var state := str(weapon_mode) + ":" + str(_ammo_cannon.disabled) + ":" + str(_ammo_harpoon.disabled)
	if state != _ammo_state:
		_ammo_state = state
		_style_ammo_slot(_ammo_cannon, weapon_mode == "cannon")
		_style_ammo_slot(_ammo_harpoon, weapon_mode == "harpoon")


func _style_ammo_slot(button: Button, selected: bool) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("64451e") if selected else Color("102737f2")
	background.border_color = Color("f4c66c") if selected else Color("66717a")
	background.set_border_width_all(2 if selected else 1)
	background.set_corner_radius_all(7)
	background.content_margin_left = 5.0
	background.content_margin_right = 5.0
	button.add_theme_stylebox_override("normal", background)
	button.add_theme_stylebox_override("hover", background)
	button.add_theme_stylebox_override("focus", background)


func _choose_cannon() -> void:
	_select_ammo("cannon")

func _choose_harpoon() -> void:
	_select_ammo("harpoon")

func _select_ammo(mode: String) -> void:
	if mode not in ["cannon", "harpoon"]:
		return
	if mode == weapon_mode:
		hint = "Kanonen gewählt" if mode == "cannon" else "Harpunen gewählt"
	else:
		weapon_mode = mode
		firing = false
		reload = 0.0
		hint = "Kanonen gegen Schiffe" if mode == "cannon" else "Harpunen gegen Monster"
	_refresh()


func _process(delta: float) -> void:
	super._process(delta)
	if _target_ring == null:
		return
	var active := target >= 0 and target < enemies.size()
	if active:
		var enemy: Dictionary = enemies[target]
		active = int(enemy["hp"]) > 0
		if active:
			var enemy_node: Node3D = enemy["node"]
			active = is_instance_valid(enemy_node)
			if active:
				_target_ring.global_position = enemy_node.global_position + Vector3(0.0, -0.18, 0.0)
				_target_ring.rotation.y += delta * 0.55
	_target_ring.visible = active


func _spawn_shot(origin: Vector3, destination: Node3D, tint: Color, hit_callback: Callable, harpoon: bool) -> void:
	if _projectile_layer == null or not is_instance_valid(destination):
		return
	var shot := Node3D.new()
	shot.name = "Harpoon" if harpoon else "IronCannonball"
	_projectile_layer.add_child(shot)
	shot.global_position = origin
	if harpoon:
		_build_harpoon(shot)
	else:
		_build_iron_ball(shot)
	var distance := origin.distance_to(destination.global_position)
	var duration := clampf(distance / (42.0 if harpoon else 34.0), 0.30, 0.94)
	_active_shots += 1
	var tween := create_tween()
	tween.tween_method(Callable(self, "_move_real_ammo").bind(shot, destination, origin, harpoon),
		0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(hit_callback)
	tween.tween_callback(Callable(self, "_finish_shot").bind(shot))


func _build_iron_ball(parent: Node3D) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.72
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("343f4a")
	iron.metallic = 0.78
	iron.roughness = 0.37
	_add_mesh(parent, sphere, iron, Vector3.ZERO)
	# Small fixed specular patch gives the dark cannonball a recognizable edge,
	# without making it look like glowing magic ammunition.
	var highlight := SphereMesh.new()
	highlight.radius = 0.075
	highlight.height = 0.15
	var silver := StandardMaterial3D.new()
	silver.albedo_color = Color("a7b0b4")
	silver.metallic = 0.85
	_add_mesh(parent, highlight, silver, Vector3(-0.16, 0.20, -0.23))


func _build_harpoon(parent: Node3D) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("825d3b")
	wood.roughness = 0.82
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("c5d3d5")
	steel.metallic = 0.72
	steel.roughness = 0.28
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.072
	shaft.bottom_radius = 0.085
	shaft.height = 1.65
	var shaft_mesh := _add_mesh(parent, shaft, wood, Vector3.ZERO)
	shaft_mesh.rotation.x = -PI * 0.5  # spear points along local -Z
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.21
	tip.height = 0.56
	var point_mesh := _add_mesh(parent, tip, steel, Vector3(0.0, 0.0, -1.06))
	point_mesh.rotation.x = -PI * 0.5
	for side in [-1.0, 1.0]:
		var barb := BoxMesh.new()
		barb.size = Vector3(0.24, 0.045, 0.37)
		var barb_mesh := _add_mesh(parent, barb, steel, Vector3(side * 0.12, 0.0, -0.72))
		barb_mesh.rotation.y = side * 0.38
	var fin := BoxMesh.new()
	fin.size = Vector3(0.45, 0.07, 0.3)
	_add_mesh(parent, fin, wood, Vector3(0.0, 0.0, 0.68))


func _add_mesh(parent: Node3D, mesh: Mesh, material: Material, offset: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	parent.add_child(instance)
	return instance


func _move_real_ammo(progress: float, shot: Node3D, destination: Node3D, start: Vector3, harpoon: bool) -> void:
	if not is_instance_valid(shot) or not is_instance_valid(destination):
		return
	var end := destination.global_position + Vector3(0.0, 2.4, 0.0)
	var height := sin(progress * PI) * (0.9 if harpoon else 1.6)
	shot.global_position = start.lerp(end, progress) + Vector3.UP * height
	if harpoon:
		var direction := end - shot.global_position
		if direction.length() > 0.08:
			shot.look_at(end, Vector3.UP)
	else:
		shot.rotation.x += 0.08


func _player_impact(index: int, actor: Node3D, damage: int) -> void:
	if is_instance_valid(actor):
		_water_impact(actor.global_position)
	super._player_impact(index, actor, damage)


func _enemy_impact(damage: int) -> void:
	if is_instance_valid(ship):
		_water_impact(ship.global_position)
	super._enemy_impact(damage)


func _water_impact(at: Vector3) -> void:
	if _projectile_layer == null:
		return
	var ring := TorusMesh.new()
	ring.inner_radius = 0.92
	ring.outer_radius = 1.10
	var splash := MeshInstance3D.new()
	splash.name = "WaterSplashRing"
	splash.mesh = ring
	var whitewater := StandardMaterial3D.new()
	whitewater.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	whitewater.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	whitewater.albedo_color = Color(0.66, 0.87, 0.91, 0.65)
	splash.material_override = whitewater
	_projectile_layer.add_child(splash)
	splash.global_position = Vector3(at.x, 0.12, at.z)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(splash, "scale", Vector3.ONE * 2.8, 0.58)
	tween.tween_property(splash, "transparency", 1.0, 0.58)
	tween.chain().tween_callback(splash.queue_free)


## Reuse the audited reference-art ship slots when spawning a denser local fleet.
## Never create NPC_6+ with missing source images and fall back to 2D placeholders.
func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	var source_label := label
	if label.begins_with("NPC_"):
		var number := label.substr(4).to_int()
		if number >= 5:
			source_label = "NPC_%d" % posmod(number, 5)
	var holder: Node3D = super._asset(file, where, factor, source_label, atlas)
	holder.name = label
	return holder


func _build_world() -> void:
	super._build_world()
	# Existing SeaBattles / SeaOfBones ship sheets; real shootable/patrol ships.
	# The first five NPCs and the monster remain unchanged.
	var patrols := [
		{"where": Vector3(-76.0, 0.65, -57.0), "name": "Nordmeer-Wache"},
		{"where": Vector3(3.0, 0.65, 57.0), "name": "Sturmfregatte"},
		{"where": Vector3(86.0, 0.65, 67.0), "name": "Schatzjäger"}
	]
	for config in patrols:
		var index: int = enemies.size()
		var vessel: Node3D = _asset(ENEMY, config["where"], 0.8, "NPC_%d" % index, CORSAIR_ATLAS)
		var tag: Label3D = _nameplate(vessel, str(config["name"]), Color("e9be80"))
		enemies.append({
			"node": vessel, "name": config["name"],
			"hp": 100, "plate": tag, "kind": "ship"
		})


func _create_loot(where: Vector3, amount: int) -> void:
	# Real pickup world object; keeps the existing reward and proximity logic.
	var chest := Node3D.new()
	chest.name = "LootChest_%d" % loot_items.size()
	chest.position = where
	add_child(chest)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("62402a")
	wood.roughness = 0.88
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("c59c50")
	brass.metallic = 0.68
	brass.roughness = 0.42
	var body := BoxMesh.new()
	body.size = Vector3(2.0, 0.92, 1.2)
	_add_mesh(chest, body, wood, Vector3(0.0, 0.65, 0.0))
	var lid := BoxMesh.new()
	lid.size = Vector3(2.08, 0.25, 1.27)
	_add_mesh(chest, lid, wood, Vector3(0.0, 1.24, 0.0))
	for x in [-0.75, 0.75]:
		var strap := BoxMesh.new()
		strap.size = Vector3(0.19, 0.33, 1.31)
		_add_mesh(chest, strap, brass, Vector3(x, 1.12, 0.0))
	var lock := BoxMesh.new()
	lock.size = Vector3(0.3, 0.3, 0.13)
	_add_mesh(chest, lock, brass, Vector3(0.0, 0.89, -0.66))
	_nameplate(chest, "BEUTE · %d GOLD" % amount, Color("ffda76"))
	loot_items.append({"node": chest, "gold": amount})


func _world_click(screen: Vector2) -> void:
	# World taps select ships, treasure or course without hijacking HUD buttons.
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.y) > 0.001:
		var t := -origin.y / direction.y
		if t >= 0.0:
			var hit := origin + direction * t
			# Enemy targeting has priority on overlapping tap positions.
			var enemy_nearby := false
			for entry in enemies:
				if int(entry["hp"]) <= 0:
					continue
				var actor: Node3D = entry["node"]
				if Vector2(hit.x, hit.z).distance_to(Vector2(actor.position.x, actor.position.z)) < 6.0:
					enemy_nearby = true
					break
			if not enemy_nearby:
				for drop in loot_items:
					var crate: Node3D = drop["node"]
					if not is_instance_valid(crate):
						continue
					if Vector2(hit.x, hit.z).distance_to(Vector2(crate.position.x, crate.position.z)) < 5.0:
						_course(crate.position)
						hint = "Beute angefahren · in Reichweite automatisch einsammeln"
						_refresh()
						return
	super._world_click(screen)

extends "res://scripts/classic/m3034_fullscreen_sea_map.gd"
## M303.5: classic SeaBattles-style asset bridge (LOCAL preview, not networked).
## One visual choice per ship: proprietary local test sprite OR original 16-way
## placeholder atlas OR existing Godot GLB. No gameplay dependency on visuals.
const ASSET_BRIDGE = preload("res://scripts/classic/m3035_render_adapter.gd")
var _graphics_button: Button
var _asset_mode := "private_sprite"
var _sea_speed := 0.0
var _wake_visual: MeshInstance3D

func _ready() -> void:
	_asset_mode = str(get_tree().root.get_meta("m3035_graphic_mode", "private_sprite"))
	ASSET_BRIDGE.active_pack = "captainofsea" if _asset_mode == "captain_sprite" else ("seaofbones" if _asset_mode == "seaofbones_sprite" else "seabattles")
	super._ready()

func _uses_private_art() -> bool:
	return _asset_mode in ["private_sprite", "seaofbones_sprite", "captain_sprite"]


func _asset(file: String, where: Vector3, scale_factor: float, label: String, atlas_path: String = "") -> Node3D:
	if _uses_private_art():
		if ASSET_BRIDGE.has_local_actor(label):
			var holder := Node3D.new()
			holder.name = label
			holder.position = where
			add_child(holder)
			var adapter := ASSET_BRIDGE.new()
			adapter.name = "ShipSprite" if label == "PlayerShip" or label.begins_with("NPC_") or label == "SeaMonster" else "IslandVisual"
			holder.add_child(adapter)
			var source: String = ASSET_BRIDGE.local_path(label)
			var entry: Dictionary = ASSET_BRIDGE.actor_config(label)
			var success := false
			if label.begins_with("NPC_") or label == "PlayerShip" or label == "SeaMonster":
				success = adapter.set_ship_atlas(source, int(entry.get("columns", 4)), int(entry.get("rows", 2)), float(entry.get("world_width", 5.6)) * scale_factor, float(entry.get("heading_offset", 0.0)))
			else:
				var radius := 12.0
				for obstacle in islands:
					var center: Vector3 = obstacle["position"]
					if center.distance_to(where) < 0.5:
						radius = float(obstacle["radius"])
						break
				success = adapter.set_island_image(source, radius * 2.2)
			if success:
				if label == "PlayerShip" or label.begins_with("NPC_") or label == "SeaMonster":
					adapter.configure_frames(entry)
					adapter.set_heading(holder.rotation.y)
				return holder
			holder.queue_free()
	if _asset_mode == "complete_3d":
		return super._asset(file, where, scale_factor, label, "")
	return super._asset(file, where, scale_factor, label, atlas_path)


func _make_ocean() -> void:
	# Optional local texture slot. The baseline still works entirely offline
	# with the existing lightweight wave shader.
	var ocean: Dictionary = ASSET_BRIDGE.pack_config().get("ocean", {})
	var water_path: String = ASSET_BRIDGE._path_for(str(ocean.get("path", "ocean/water.png")))
	if not _uses_private_art() or water_path.is_empty():
		super._make_ocean()
		return
	var texture: Texture2D = ASSET_BRIDGE._read_texture(water_path)
	if texture == null:
		super._make_ocean()
		return
	var water := MeshInstance3D.new()
	water.name = "SeaBattlesReferenceOcean"
	var plane := PlaneMesh.new()
	plane.size = Vector2(280, 210)
	water.mesh = plane
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D sea_tex : source_color; void fragment() { vec2 uv = fract(UV * vec2(8.0, 8.0) + vec2(TIME * 0.004, TIME * 0.002)); ALBEDO = texture(sea_tex, uv).rgb; }"
	if str(ocean.get("usage", "diffuse")) == "noise":
		# Packed source wave/noise data modulates our ocean shading; never display it as albedo.
		shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D sea_tex : repeat_enable, filter_linear_mipmap; void fragment() { vec2 p = UV * vec2(12.0, 9.0); float a = dot(texture(sea_tex, p + vec2(TIME * 0.012, TIME * 0.007)).rgb, vec3(0.3333)); float b = dot(texture(sea_tex, p * 1.37 - vec2(TIME * 0.008, TIME * 0.004)).rgb, vec3(0.3333)); ALBEDO = mix(vec3(0.018, 0.105, 0.145), vec3(0.045, 0.25, 0.29), clamp((a+b)*0.7, 0.0, 1.0)); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("sea_tex", texture)
	water.material_override = material
	add_child(water)


func _build_world() -> void:
	super._build_world()
	# Thin restrained stern wake. Visual only; fixes M302's broad white-fan issue.
	_wake_visual = MeshInstance3D.new()
	_wake_visual.name = "ClassicSternWake"
	var surface := PlaneMesh.new()
	surface.size = Vector2(0.95, 5.4)
	_wake_visual.mesh = surface
	_wake_visual.position = Vector3(0.0, -0.43, -3.0)
	var foam := StandardMaterial3D.new()
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.albedo_color = Color(0.76, 0.91, 0.94, 0.24)
	foam.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	_wake_visual.material_override = foam
	_wake_visual.visible = false
	ship.add_child(_wake_visual)


func _sail(delta: float) -> void:
	var ship_display := ship.get_node_or_null("ShipSprite")
	if ship_display != null and ship_display.has_method("set_moving"):
		ship_display.set_moving(not route.is_empty())
	if route.is_empty():
		_sea_speed = move_toward(_sea_speed, 0.0, 20.0 * delta)
		if _wake_visual != null:
			_wake_visual.visible = false
		return
	var displacement := route[0] - ship.position
	displacement.y = 0.0
	if displacement.length() < 0.8:
		route.remove_at(0)
		if route.is_empty():
			_sea_speed = 0.0
		return
	var direction := displacement.normalized()
	# Ported from M302 motor feel: measured acceleration and rotation rate,
	# with course-following independent of the heading/sprite presentation.
	var desired_speed := minf(11.0, maxf(3.0, displacement.length() * 2.0))
	_sea_speed = move_toward(_sea_speed, desired_speed, 19.0 * delta)
	var next_point := ship.position + direction * minf(_sea_speed * delta, displacement.length())
	if _blocked(next_point):
		route.clear()
		_sea_speed = 0.0
		hint = "Küste erreicht – neuer Kurs nötig"
		_refresh()
		return
	ship.position = next_point
	var desired_heading := atan2(-direction.x, -direction.z)
	ship.rotation.y = rotate_toward(ship.rotation.y, desired_heading, deg_to_rad(112.0) * delta)
	var appearance := ship.get_node_or_null("ShipSprite")
	if appearance != null and appearance.has_method("set_heading"):
		appearance.set_heading(ship.rotation.y)
	if _wake_visual != null:
		_wake_visual.visible = _sea_speed > 0.3
		_wake_visual.scale.z = 0.35 + 0.7 * _sea_speed / 11.0


func _make_hud() -> void:
	super._make_hud()
	_graphics_button = _control("GRAFIK: 2D/3D", Callable(self,"_switch_graphics"))
	_graphics_button.add_theme_font_size_override("font_size", 12)
	_hud_header.text = "ABYSSAL DOMINION  ·  NORDMEER 10/2  ·  M303.5"
	if _uses_private_art():
		_apply_private_hud()
		var config: Dictionary = ASSET_BRIDGE.pack_config()
		if not config.is_empty():
			_hud_header.text = "ABYSSAL DOMINION · M303.5 · LOKAL: " + str(config.get("source_label", "Privat"))

func _apply_private_hud() -> void:
	for control: Node in _ui_root.get_children():
		if control is Button:
			for state: String in ["normal", "hover", "pressed"]:
				var path: String = ASSET_BRIDGE._path_for("ui/button_" + state + ".png")
				var texture: Texture2D = ASSET_BRIDGE._read_texture(path)
				if texture == null:
					continue
				var style := StyleBoxTexture.new()
				style.texture = texture
				# Full stretch keeps the source frame within compact HUD buttons.
				# Large source-pixel slice margins exceed mobile button dimensions.
				style.texture_margin_left = 0.0
				style.texture_margin_right = 0.0
				style.texture_margin_top = 0.0
				style.texture_margin_bottom = 0.0
				style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
				style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
				style.content_margin_left = 4.0
				style.content_margin_right = 4.0
				style.content_margin_top = 3.0
				style.content_margin_bottom = 3.0
				(control as Button).add_theme_stylebox_override(state, style)

func _fire() -> void:
	var ammo_before := cannonballs + harpoons
	super._fire()
	if not _uses_private_art() or ammo_before == cannonballs + harpoons:
		return
	var effect: Dictionary = ASSET_BRIDGE.pack_config().get("shot_effect", {})
	var texture: Texture2D = ASSET_BRIDGE._read_texture(ASSET_BRIDGE._path_for(str(effect.get("path", "effects/smoke.png"))))
	if texture == null:
		return
	var smoke := Sprite3D.new()
	smoke.texture = texture
	smoke.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	smoke.shaded = false
	smoke.pixel_size = float(effect.get("world_width", 3.6)) / float(texture.get_width())
	add_child(smoke)
	smoke.global_position = ship.global_position + Vector3(0, 2, 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(smoke, "modulate:a", 0.0, 0.65)
	tween.tween_property(smoke, "scale", Vector3.ONE * 2.0, 0.65)
	tween.chain().tween_callback(smoke.queue_free)


func _layout_hud() -> void:
	super._layout_hud()
	if _graphics_button == null:
		return
	var v := get_viewport().get_visible_rect().size
	var bar_height := 34.0 if v.x < 1024.0 or v.y < 540.0 else 44.0
	_place(_graphics_button, v.x * 0.44, bar_height + 8.0, minf(v.x * 0.24, 170.0), 36.0)
	_graphics_button.text = _mode_name()


func _mode_name() -> String:
	if _asset_mode == "private_sprite":
		return "GRAFIK: SEABATTLES"
	if _asset_mode == "seaofbones_sprite":
		return "GRAFIK: SEA OF BONES"
	if _asset_mode == "complete_3d":
		return "GRAFIK: 3D"
	return "GRAFIK: 2D"


func _switch_graphics() -> void:
	if _asset_mode == "private_sprite":
		_asset_mode = "seaofbones_sprite"
	elif _asset_mode == "seaofbones_sprite":
		_asset_mode = "complete_3d"
	elif _asset_mode == "complete_3d":
		_asset_mode = "placeholder_sprite"
	else:
		_asset_mode = "private_sprite"
	get_tree().root.set_meta("m3035_graphic_mode", _asset_mode)
	# Asset-reload is a LOCAL-TEST reset; no durable save or online state exists.
	get_tree().reload_current_scene()


# M303.5: local NPC cruise presentation only; affects no server state.
var _npc_animation_clock := 0.0
var _npc_initial_positions: Array[Vector3] = []


func _process(delta: float) -> void:
	super._process(delta)
	if enemies.is_empty():
		return
	if _npc_initial_positions.is_empty():
		for data in enemies:
			var node: Node3D = data["node"]
			_npc_initial_positions.append(node.position)
	_npc_animation_clock += delta
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if str(enemy.get("kind", "")) != "ship" or int(enemy["hp"]) <= 0:
			continue
		var ship_node: Node3D = enemy["node"]
		var initial := _npc_initial_positions[i]
		var t := _npc_animation_clock * (0.24 + float(i % 3) * 0.04) + float(i) * 1.4
		var next_target := initial + Vector3(sin(t) * 4.5, 0.0, cos(t * 0.85) * 4.0)
		var travel := next_target - ship_node.position
		travel.y = 0.0
		if travel.length() < 0.08:
			continue
		var toward := travel.normalized()
		var candidate := ship_node.position + toward * minf(delta * 2.1, travel.length())
		if _blocked(candidate):
			continue
		ship_node.position = candidate
		ship_node.rotation.y = lerp_angle(ship_node.rotation.y, atan2(-toward.x, -toward.z), minf(1.0, delta * 2.5))
		var sprite := ship_node.get_node_or_null("ShipSprite")
		if sprite != null:
			if sprite.has_method("set_moving"):
				sprite.set_moving(true)
			sprite.set_heading(ship_node.rotation.y)

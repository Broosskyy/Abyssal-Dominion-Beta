extends "res://scripts/classic/m3035_seabattles_core.gd"
## One game presentation; two interchangeable artwork sources, no scene reset.
var _portrait: TextureRect
var _hull_bar: ProgressBar
var _captain_title: Label
var _captain_numbers: Label
var _target_numbers: Label
var _target_bar: ProgressBar
var _area_label: Label
var _menu_button: Button
var _options: Panel
var _options_title: Label
var _pack_button: Button
var _options_close: Button
var _build_label: Label
var _portrait_pack := ""
var _width_cache: Dictionary = {}

func _ready() -> void:
	# Never shrink mobile text below 1x; scale high-resolution screens upward.
	_sync_ui_scale()
	var mode := str(get_tree().root.get_meta("m3035_graphic_mode", "private_sprite"))
	if mode not in ["private_sprite", "seaofbones_sprite", "captain_sprite", "original_fleet"]:
		get_tree().root.set_meta("m3035_graphic_mode", "private_sprite")
	super._ready()

func _style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("091b28ed")
	box.border_color = Color("9b8254")
	box.set_border_width_all(1)
	box.set_corner_radius_all(7)
	return box

func _control(title: String, method: Callable) -> Button:
	var button := super._control(title, method)
	for state: String in ["normal", "hover", "pressed"]:
		var style := _style()
		style.bg_color = Color("122c3d") if state == "normal" else (Color("244353") if state == "hover" else Color("655134"))
		button.add_theme_stylebox_override(state, style)
	button.add_theme_font_size_override("font_size", 14)
	return button

func _make_bar(parent: Control, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("020c14")
	background.set_corner_radius_all(3)
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	foreground.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)
	parent.add_child(bar)
	return bar

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UnifiedHud"
	add_child(layer)
	_ui_root = Control.new()
	_ui_root.name = "SafeFullViewport"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui_root)
	_hud_bar = _panel(_ui_root)
	_hud_header = _label(_ui_root, "ABYSSAL DOMINION", 17)
	_area_label = _label(_ui_root, "NORDMEER 10/2", 13)
	_area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_menu_button = _control("MENÜ", Callable(self, "_toggle_options"))
	_hud_player_frame = _panel(_ui_root)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(_portrait)
	_captain_title = _label(_ui_root, "KAPITÄN", 15)
	_captain_numbers = _label(_ui_root, "", 13)
	_hull_bar = _make_bar(_ui_root, Color("74bfa6"))
	_hud_mini_frame = _panel(_ui_root)
	mini = MINI_MAP.new()
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_mini_frame.add_child(mini)
	_hud_target_frame = _panel(_ui_root)
	target_text = _label(_ui_root, "", 15)
	target_text.clip_text = true
	_target_numbers = _label(_ui_root, "", 12)
	_target_bar = _make_bar(_ui_root, Color("c99369"))
	_hud_status_frame = _panel(_ui_root)
	status = _label(_ui_root, "", 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.max_lines_visible = 2
	status.clip_text = true
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for key: String in ["center", "left", "right", "zoom_out", "zoom_in"]:
		var titles := {"center": "ZENTRIEREN", "left": "◀", "right": "▶", "zoom_out": "−", "zoom_in": "+"}
		var actions := {"center": "_recenter", "left": "_pan_left", "right": "_pan_right", "zoom_out": "_zoom_out", "zoom_in": "_zoom_in"}
		_hud_controls[key] = _control(titles[key], Callable(self, actions[key]))
	_hud_controls["repair"] = _control("REPARATUR", Callable(self, "_repair"))
	harpoon_button = _control("KANONEN", Callable(self, "_harpoon"))
	attack_button = _control("FEUER", Callable(self, "_toggle_fire"))
	_hud_controls["weapon"] = harpoon_button
	_hud_controls["fire"] = attack_button
	var fire_style := _style()
	fire_style.bg_color = Color("5b4930")
	attack_button.add_theme_stylebox_override("normal", fire_style)
	_options = _panel(_ui_root)
	_options.name = "OptionsPanel"
	var menu_style := _style()
	menu_style.bg_color = Color("091b28")
	_options.add_theme_stylebox_override("panel", menu_style)
	_options.mouse_filter = Control.MOUSE_FILTER_STOP
	_options.visible = false
	_options_title = _label(_options, "DARSTELLUNG", 17)
	_pack_button = _control("", Callable(self, "_switch_graphics"))
	_full_button = _control("VOLLBILD", Callable(self, "_fullscreen"))
	_options_close = _control("SCHLIESSEN", Callable(self, "_toggle_options"))
	_build_label = _label(_options, "M303.6 · Lokaler Test", 12)
	for button: Button in [_pack_button, _full_button, _options_close]:
		_ui_root.remove_child(button)
		_options.add_child(button)
	_hud_portrait_backdrop = _panel(_ui_root)
	_hud_portrait_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_portrait_label = _label(_hud_portrait_backdrop, "Bitte ins Querformat drehen", 20)
	_hud_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _layout_hud() -> void:
	if _ui_root == null:
		return
	_sync_ui_scale()
	var screen := get_viewport().get_visible_rect().size
	var w := screen.x
	var h := screen.y
	var small := h < 540.0 or w < 1024.0
	var m := 10.0 if small else 16.0
	var header := 36.0 if small else 42.0
	var button_h := 46.0 if small else 54.0
	var bottom := h - button_h - m
	_place(_hud_bar, 0, 0, w, header)
	_place(_hud_header, m + 3, 4, w * 0.5, header - 8)
	_hud_header.add_theme_font_size_override("font_size", 15 if small else 18)
	_place(_menu_button, w - m - 72, 5, 72, header - 10)
	_place(_area_label, w - m - 260, 5, 174, header - 10)
	var card_w := 242.0 if small else 268.0
	var card_y := header + m
	_place(_hud_player_frame, m, card_y, card_w, 96)
	_place(_portrait, m + 6, card_y + 6, 76, 82)
	_place(_captain_title, m + 88, card_y + 8, card_w - 100, 24)
	_place(_hull_bar, m + 88, card_y + 40, card_w - 102, 8)
	_place(_captain_numbers, m + 88, card_y + 55, card_w - 102, 34)
	var edge := clampf(h * 0.22, 84, 136)
	_place(_hud_mini_frame, w - m - edge, card_y, edge, edge)
	_place(mini, 4, 4, edge - 8, edge - 8)
	var target_w := 208.0 if small else 242.0
	var target_x := w - m - target_w
	var target_y := card_y + edge + 8
	_place(_hud_target_frame, target_x, target_y, target_w, 78)
	_place(target_text, target_x + 10, target_y + 6, target_w - 20, 24)
	_place(_target_bar, target_x + 10, target_y + 36, target_w - 20, 7)
	_place(_target_numbers, target_x + 10, target_y + 49, target_w - 20, 20)
	var x := m
	for key: String in ["center", "left", "right", "zoom_out", "zoom_in"]:
		var width := (88.0 if small else 106.0) if key == "center" else (40.0 if small else 48.0)
		_place(_hud_controls[key], x, bottom, width, button_h)
		x += width + 5
	var repair_w := 100.0 if small else 126.0
	var weapon_w := 112.0 if small else 146.0
	var fire_w := 100.0 if small else 136.0
	var right_x := w - m - repair_w - weapon_w - fire_w - 12
	_place(_hud_controls["repair"], right_x, bottom, repair_w, button_h)
	_place(harpoon_button, right_x + repair_w + 6, bottom, weapon_w, button_h)
	_place(attack_button, right_x + repair_w + weapon_w + 12, bottom, fire_w, button_h)
	var status_w := minf(w - 2 * m, 620.0)
	_place(_hud_status_frame, (w - status_w) * 0.5, bottom - 48, status_w, 38)
	_place(status, (w - status_w) * 0.5 + 12, bottom - 46, status_w - 24, 34)
	var menu_w := minf(310.0, w - 2 * m)
	_place(_options, w - menu_w - m, header + m, menu_w, 260)
	_place(_options_title, 18, 14, menu_w - 36, 28)
	_place(_pack_button, 18, 58, menu_w - 36, 46)
	_place(_full_button, 18, 116, menu_w - 36, 40)
	_place(_options_close, 18, 168, menu_w - 36, 40)
	_place(_build_label, 18, 222, menu_w - 36, 22)
	_hud_portrait_backdrop.visible = w < h
	_place(_hud_portrait_backdrop, 0, 0, w, h)
	_place(_hud_portrait_label, w * 0.1, h * 0.25, w * 0.8, h * 0.5)

func _sync_ui_scale() -> void:
	var physical := Vector2(get_window().size)
	var factor := maxf(1.0, minf(physical.x / 1280.0, physical.y / 720.0))
	var desired := Vector2i((physical / factor).round()) if factor > 1.0 else Vector2i.ZERO
	if get_window().content_scale_size != desired:
		get_window().content_scale_size = desired

func _refresh() -> void:
	if _captain_numbers == null:
		return
	_hull_bar.value = hull
	_captain_numbers.text = "RUMPF %d / 100\nGOLD %d · SIEGE %d" % [hull, gold, kills]
	status.text = hint.replace("Testtreffer", "Treffer").replace(" (lokale Demo)", "")
	var selected := target >= 0 and target < enemies.size()
	for control: Control in [_hud_target_frame, target_text, _target_bar, _target_numbers]:
		control.visible = selected
	if selected:
		var enemy: Dictionary = enemies[target]
		var maximum := 140 if str(enemy.kind) == "monster" else 100
		target_text.text = str(enemy.name)
		_target_bar.max_value = maximum
		_target_bar.value = int(enemy.hp)
		_target_numbers.text = "LEBEN %d / %d · %d m" % [int(enemy.hp), maximum, roundi(ship.position.distance_to(enemy.node.position))]
	attack_button.text = "STOPP" if firing else "FEUER"
	harpoon_button.text = "HARPUNEN · %d" % harpoons if weapon_mode == "harpoon" else "KANONEN · %d" % cannonballs
	_pack_button.text = "GRAFIKEN: SEA OF BONES" if _asset_mode == "seaofbones_sprite" else "GRAFIKEN: SEABATTLES"
	if _portrait_pack != _asset_mode and ship != null:
		var adapter := ship.get_node_or_null("ShipSprite")
		if adapter != null and adapter.get("visual") != null:
			var sprite: Sprite3D = adapter.visual
			var texture := AtlasTexture.new()
			texture.atlas = sprite.texture
			var cell := Vector2(sprite.texture.get_width() / sprite.hframes, sprite.texture.get_height() / sprite.vframes)
			# Show the intact first frame until a verified HP-dependent damaged portrait exists.
			var frame := 0
			texture.region = Rect2(Vector2(frame % sprite.hframes, frame / sprite.hframes).floor() * cell, cell)
			_portrait.texture = texture
		_portrait_pack = _asset_mode

func _toggle_options() -> void:
	_options.visible = not _options.visible

func _switch_graphics() -> void:
	_asset_mode = "seaofbones_sprite" if _asset_mode == "private_sprite" else "private_sprite"
	ASSET_BRIDGE.active_pack = "seaofbones" if _asset_mode == "seaofbones_sprite" else "seabattles"
	get_tree().root.set_meta("m3035_graphic_mode", _asset_mode)
	_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
	for i in enemies.size():
		var entry: Dictionary = enemies[i]
		var monster := str(entry.kind) == "monster"
		_replace_visual(entry.node, MONSTER if monster else ENEMY, 0.8, "SeaMonster" if monster else "NPC_%d" % i, "" if monster else CORSAIR_ATLAS)
	_refresh()

func _replace_visual(actor: Node3D, file: String, factor: float, label: String, atlas: String = "") -> void:
	var replacement := _asset(file, actor.position, factor, label, atlas)
	for child: Node in actor.get_children():
		if child is Label3D or child == _wake_visual:
			continue
		actor.remove_child(child)
		child.queue_free()
	for child: Node in replacement.get_children():
		replacement.remove_child(child)
		actor.add_child(child)
	replacement.free()
	var adapter := actor.get_node_or_null("ShipSprite")
	if adapter != null and adapter.has_method("set_heading"):
		adapter.set_heading(actor.rotation.y)
		if adapter.has_method("set_moving"):
			adapter.set_moving(not route.is_empty() if actor == ship else true)

func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	# Coastline and water belong to the shared world, independent of ship skins.
	var previous_pack := ASSET_BRIDGE.active_pack
	if label.begins_with("Island_"):
		ASSET_BRIDGE.active_pack = "seabattles"
	var holder := super._asset(file, where, factor, label, atlas)
	ASSET_BRIDGE.active_pack = previous_pack
	var adapter := holder.get_node_or_null("ShipSprite")
	if adapter != null and adapter.get("visual") != null:
		var sprite: Sprite3D = adapter.visual
		var key := sprite.texture.resource_path
		if key.is_empty():
			key = str(sprite.texture.get_instance_id())
		if not _width_cache.has(key):
			var image := sprite.texture.get_image()
			if image.is_compressed():
				image.decompress()
			var cell := Vector2i(image.get_width() / sprite.hframes, image.get_height() / sprite.vframes)
			var extent := 1
			for frame in sprite.hframes * sprite.vframes:
				var rectangle := image.get_region(Rect2i(Vector2i(frame % sprite.hframes, frame / sprite.hframes) * cell, cell)).get_used_rect()
				extent = maxi(extent, rectangle.size.x)
			_width_cache[key] = extent
		sprite.pixel_size = (12.0 if label == "SeaMonster" else 7.6 * factor) / float(_width_cache[key])
	return holder

func _nameplate(anchor: Node3D, value: String, tint: Color) -> Label3D:
	var tag := super._nameplate(anchor, value, tint)
	tag.font_size = 48
	tag.outline_size = 5
	tag.position.y = 9.0
	return tag

func _process(delta: float) -> void:
	super._process(delta)
	var pixels := 13.0 * camera.size / (48.0 * maxf(1.0, get_viewport().get_visible_rect().size.y))
	for anchor: Node3D in [ship] + enemies.map(func(entry: Dictionary) -> Node3D: return entry.node):
		for child: Node in anchor.get_children():
			if child is Label3D:
				child.pixel_size = pixels

func _make_ocean() -> void:
	var water := MeshInstance3D.new()
	water.name = "UnifiedOcean"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(280, 210)
	water.mesh = mesh
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D waves : repeat_enable, filter_linear_mipmap; void fragment(){ vec2 p=UV*vec2(6.1,4.7); float a=texture(waves,p+vec2(TIME*.002,TIME*.001)).r; float b=texture(waves,mat2(vec2(.74,.67),vec2(-.67,.74))*p*1.73-vec2(TIME*.001,TIME*.002)).r; float swell=sin(UV.x*13.0+UV.y*8.0+TIME*.06)*.5+.5; float c=clamp((a+b)*.5,0.0,1.0); ALBEDO=vec3(.016,.105,.145)+vec3(.018,.040,.045)*(c-.35)+vec3(.003,.009,.010)*swell; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	var texture: Texture2D = ASSET_BRIDGE._read_texture("res://assets/classic/private_seabattles/ocean/wave_noise.png")
	if texture == null:
		var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.5,0.5,0.5,1))
		texture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("waves", texture)
	water.material_override = material
	add_child(water)

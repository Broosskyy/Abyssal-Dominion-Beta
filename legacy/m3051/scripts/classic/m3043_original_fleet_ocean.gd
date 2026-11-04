extends "res://scripts/classic/m3042_navigation_hud_stability.gd"
## M304.3: original in-game 3D ships, procedural ocean and live damage state.
## Full graphical mode is available without third-party reference sprites.
const ORIGINAL_VESSEL = preload("res://scripts/classic/m3043_original_vessel.gd")
const SHIP_EMBLEM: Texture2D = preload("res://assets/classic/original_ui/captain_ship.svg")
const ORIGINAL_SEA_SHADER := "shader_type spatial; render_mode cull_disabled; void fragment() { vec2 q=UV*vec2(37.0,29.0); float sw=sin(q.x*1.83+TIME*0.37)*sin(q.y*1.47-TIME*0.29); float lw=sin(q.x*0.66+q.y*1.21+TIME*0.23); float ripple=sin(q.x*3.11-q.y*2.31+TIME*1.23); float crest=smoothstep(0.77,1.19,sw*0.51+lw*0.51+ripple*0.13+0.56); vec3 deep=vec3(0.018,0.095,0.143); vec3 light=vec3(0.055,0.211,0.237); ALBEDO=mix(deep,light,clamp(0.5+sw*0.22+lw*0.26,0.0,1.0)); ALBEDO+=vec3(0.20,0.24,0.23)*crest*0.19; ROUGHNESS=mix(0.40,0.18,crest); METALLIC=0.04; SPECULAR=0.72; }"

var _fleet_enabled := false
var _original_mode_button: Button


func _ready() -> void:
	# New installs start with original gameplay graphics. Test scripts may
	# explicitly opt into the older locally-staged research sprites.
	if not get_tree().root.has_meta("m3035_graphic_mode"):
		get_tree().root.set_meta("m3035_graphic_mode", "original_fleet")
	super._ready()
	_fleet_enabled = _asset_mode == "original_fleet"
	if _fleet_enabled and camera != null:
		zoom = 64.0
		camera.size = 64.0
	_hud_header.text = "ABYSSAL DOMINION · M304.3"
	_refresh()



func _make_hud() -> void:
	super._make_hud()
	_original_mode_button = _control("ORIGINAL 3D", Callable(self, "_toggle_original_fleet"))
	_original_mode_button.name = "OriginalFleetToggle"
	_original_mode_button.tooltip_text = "Eigene echte 3D-Schiffsmodelle aktivieren"
	_ui_root.remove_child(_original_mode_button)
	_options.add_child(_original_mode_button)


func _ship_profile(label: String) -> String:
	if label == "PlayerShip":
		if _ship_class_index == 1:
			return "frigate"
		if _ship_class_index == 2:
			return "ghost"
		return "brig"
	if label.begins_with("NPC_"):
		var index := label.substr(4).to_int()
		if index == 10:
			return "frigate"
		if index == 11 or index == 2:
			return "ghost"
		var variants := ["raider", "sloop", "brig", "frigate", "sloop"]
		return variants[posmod(index, variants.size())]
	return "brig"


func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	if _asset_mode == "original_fleet" and (label == "PlayerShip" or label.begins_with("NPC_")):
		var holder := Node3D.new()
		holder.name = label
		holder.position = where
		add_child(holder)
		var original := ORIGINAL_VESSEL.new()
		original.name = "OriginalVessel"
		holder.add_child(original)
		original.configure(_ship_profile(label), factor * 0.76)
		return holder
	return super._asset(file, where, factor, label, atlas)


func _make_ocean() -> void:
	super._make_ocean()
	if _asset_mode != "original_fleet":
		return
	var water := get_node_or_null("UnifiedOcean") as MeshInstance3D
	if water == null:
		return
	var ocean := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = ORIGINAL_SEA_SHADER
	ocean.shader = shader
	water.material_override = ocean


func _apply_player_coating() -> void:
	if _asset_mode == "original_fleet":
		return
	super._apply_player_coating()



func _switch_graphics() -> void:
	# Preserve legacy two-pack toggle for all existing regression tests.
	_asset_mode = "seaofbones_sprite" if _asset_mode == "private_sprite" else "private_sprite"
	_apply_graphics_mode()


func _toggle_original_fleet() -> void:
	_asset_mode = "private_sprite" if _asset_mode == "original_fleet" else "original_fleet"
	_apply_graphics_mode()


func _apply_graphics_mode() -> void:
	_fleet_enabled = _asset_mode == "original_fleet"
	ASSET_BRIDGE.active_pack = "captainofsea" if _asset_mode == "captain_sprite" else ("seaofbones" if _asset_mode == "seaofbones_sprite" else "seabattles")
	get_tree().root.set_meta("m3035_graphic_mode", _asset_mode)
	if ship != null:
		_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
	for i in enemies.size():
		var entry: Dictionary = enemies[i]
		var vessel: Node3D = entry["node"]
		if not is_instance_valid(vessel):
			continue
		var monster := str(entry.get("kind", "ship")) == "monster"
		_replace_visual(vessel, MONSTER if monster else ENEMY, 0.8,
			"SeaMonster" if monster else "NPC_%d" % i, "" if monster else CORSAIR_ATLAS)
	_apply_fleet_palette()
	_apply_player_coating()
	if _coating_button != null:
		_coating_button.text = "WERFT · SCHIFFE"
	var water := get_node_or_null("UnifiedOcean") as MeshInstance3D
	if water != null and _fleet_enabled:
		var shader := Shader.new()
		shader.code = ORIGINAL_SEA_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		water.material_override = material
	_portrait_pack = ""
	if camera != null and _fleet_enabled:
		zoom = 64.0
	_refresh()



func _cycle_player_coating() -> void:
	# The original hull is chosen by the purchased class, not by an art tint.
	if _asset_mode == "original_fleet":
		hint = "Neues Schiff in der Werft erwerben und ausrüsten"
		_refresh()
		return
	super._cycle_player_coating()


func _refresh() -> void:
	super._refresh()
	if _original_mode_button != null:
		_original_mode_button.text = "ORIGINAL 3D ✓" if _asset_mode == "original_fleet" else "ORIGINAL 3D AKTIVIEREN"
	if _pack_button != null:
		if _asset_mode == "original_fleet":
			_pack_button.text = "REFERENZ 2D ANZEIGEN"
		elif _asset_mode == "private_sprite":
			_pack_button.text = "GRAFIK: REFERENZ 2D"
		else:
			_pack_button.text = "GRAFIK: REFERENZ 3D/SPRITES"
	if ship == null:
		return
	var local_art: Node = ship.get_node_or_null("OriginalVessel")
	if local_art != null:
		local_art.set_hull_ratio(float(hull) / 100.0)
		if _portrait != null:
			_portrait.texture = SHIP_EMBLEM
			_portrait_pack = _asset_mode
	for entry: Dictionary in enemies:
		var actor: Node3D = entry["node"]
		if not is_instance_valid(actor):
			continue
		var model: Node = actor.get_node_or_null("OriginalVessel")
		if model != null:
			var max_hp: float = float(entry.get("max_hp", 140 if str(entry.get("kind", "")) == "monster" else 100))
			model.set_hull_ratio(float(entry.get("hp", 0)) / maxf(max_hp, 1.0))


func _process(delta: float) -> void:
	super._process(delta)
	if ship == null or _asset_mode != "original_fleet":
		return
	var vessel: Node = ship.get_node_or_null("OriginalVessel")
	if vessel != null:
		vessel.set_moving(_sea_speed > 0.5)


func _layout_hud() -> void:
	super._layout_hud()
	if _original_mode_button == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var w := minf(305.0, screen.x - 16.0)
	var h := minf(322.0, screen.y - (36.0 if screen.y < 540.0 else 42.0) - 16.0)
	_place(_original_mode_button, 12.0, 41.0, w - 24.0, 40.0)
	_place(_pack_button, 12.0, 87.0, w - 24.0, 39.0)
	_place(_full_button, 12.0, 133.0, w - 24.0, 36.0)
	_place(_coating_button, 12.0, 175.0, w - 24.0, 39.0)
	_place(_options_close, 12.0, 222.0, w - 24.0, 38.0)
	_place(_build_label, 12.0, h - 27.0, w - 24.0, 18.0)


func _purchase_or_equip(index: int) -> void:
	super._purchase_or_equip(index)
	if ship != null and _asset_mode == "original_fleet":
		var model: Node = ship.get_node_or_null("OriginalVessel")
		if model != null:
			# Does not replace gameplay ship identity or reset hull.
			model.set_hull_ratio(float(hull) / 100.0)

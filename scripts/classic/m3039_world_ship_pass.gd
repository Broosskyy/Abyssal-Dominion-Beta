extends "res://scripts/classic/m3038_visual_combat_sea_map.gd"
## M303.9 world readability and ship diversity pass.
## Existing audited SeaBattles / SeaOfBones sprite packs remain the source.
## All new patrols are real targetable NPCs, not decorative 2D mockups.

const WORLD_SHIP_VARIANTS: Array[Dictionary] = [
	{"name": "Schmuggler-Karavelle", "position": Vector3(16, 0.65, 31), "hp": 70, "class": "light", "gold": 18, "tint": Color("d5bf91"), "scale": 0.88},
	{"name": "Eisenfregatte", "position": Vector3(49, 0.65, -7), "hp": 155, "class": "armored", "gold": 52, "tint": Color("a6b0b9"), "scale": 1.17},
	{"name": "Geisterkorsar", "position": Vector3(-31, 0.65, 51), "hp": 130, "class": "spectral", "gold": 45, "tint": Color("83d9bf"), "scale": 1.08}
]
const START_ZOOM := 72.0
const PLAYER_COATINGS: Array[Dictionary] = [
	{"name": "Kapitänssegler", "actor": "PlayerShip", "tint": Color.WHITE, "scale": 1.0},
	{"name": "Eisenfregatte", "actor": "NPC_0", "tint": Color("bac6d4"), "scale": 1.14},
	{"name": "Geistersegler", "actor": "NPC_2", "tint": Color("9ad9c8"), "scale": 1.12}
]
var _shore_halos: Array[MeshInstance3D] = []
var _coating_index := 0
var _coating_button: Button

func _ready() -> void:
	super._ready()
	zoom = START_ZOOM
	if camera != null:
		camera.size = START_ZOOM
	_hud_header.text = "ABYSSAL DOMINION  ·  M303.9  ·  NORDMEER 10/2"
	_fix_stern_wake()
	_reduce_target_ring()
	_apply_fleet_palette()
	_apply_player_coating()
	_refresh()


func _build_world() -> void:
	super._build_world()
	# Additional coastlines are placed inside the initial visible chart, at
	# navigable distances from the player. The extra sprites are sourced from
	# original audited island slots 2 and 3, not fallback GLBs.
	var shores: Array[Dictionary] = [
		{"at": Vector3(-35.0, 0.0, 12.0), "r": 8.5, "slot": "Island_6", "file": ISLAND_ROCK},
		{"at": Vector3(37.0, 0.0, 35.0), "r": 8.0, "slot": "Island_7", "file": ISLAND_TROPICAL}
	]
	for entry: Dictionary in shores:
		var at: Vector3 = entry["at"]
		var radius: float = entry["r"]
		islands.append({"position": at, "radius": radius})
		_asset(str(entry["file"]), at, 1.55, str(entry["slot"]))
		_add_shallow_water(at, radius)
	for ship_data: Dictionary in WORLD_SHIP_VARIANTS:
		var index: int = enemies.size()
		var node: Node3D = _asset(ENEMY, ship_data["position"], 0.83, "NPC_%d" % index, CORSAIR_ATLAS)
		var plate: Label3D = _nameplate(node, str(ship_data["name"]), Color("dec39c"))
		enemies.append({
			"node": node,
			"name": ship_data["name"],
			"hp": ship_data["hp"],
			"max_hp": ship_data["hp"],
			"kind": "ship",
			"class": ship_data["class"],
			"loot_gold": ship_data["gold"],
			"variant_tint": ship_data["tint"],
			"variant_scale": ship_data["scale"],
			"plate": plate
		})


func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	# There are four audited island variants and five NPC bindings. Reuse
	# supported texture slots rather than silently substituting placeholders.
	var slot := label
	if label == "PlayerShip" and _coating_index > 0:
		slot = str(PLAYER_COATINGS[_coating_index]["actor"])
	if label.begins_with("Island_"):
		var number: int = label.substr(7).to_int()
		if number >= 4:
			slot = "Island_%d" % posmod(number, 4)
	var node: Node3D = super._asset(file, where, factor, slot, atlas)
	node.name = label
	return node


func _add_shallow_water(at: Vector3, radius: float) -> void:
	var shallows := MeshInstance3D.new()
	shallows.name = "CoastalShallows"
	var disc := PlaneMesh.new()
	disc.size = Vector2.ONE * radius * 3.2
	shallows.mesh = disc
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, cull_disabled, blend_mix, depth_draw_never; void fragment() { float r=length(UV-vec2(0.5)); float coast=smoothstep(0.47,0.22,r); float fade=smoothstep(0.50,0.31,r); ALBEDO=vec3(0.12,0.47,0.49); ALPHA=(coast*0.16+fade*0.08)*(1.0-smoothstep(0.17,0.31,r)); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	shallows.material_override = mat
	shallows.position = Vector3(at.x, 0.07, at.z)
	add_child(shallows)
	_shore_halos.append(shallows)


func _make_ocean() -> void:
	super._make_ocean()
	var sea: MeshInstance3D = get_node_or_null("UnifiedOcean") as MeshInstance3D
	if sea == null:
		return
	var shader_mat: ShaderMaterial = sea.material_override as ShaderMaterial
	if shader_mat == null:
		return
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D waves : repeat_enable, filter_linear_mipmap; void fragment(){ vec2 uv=UV*vec2(6.4,5.1); float n=texture(waves,uv+vec2(TIME*.002,TIME*.001)).r; float k=texture(waves,uv*1.63-vec2(TIME*.0015,TIME*.001)).r; float highlights=smoothstep(0.59,0.89,n*.62+k*.38); float swell=sin(UV.x*18.0+UV.y*11.0+TIME*.13)*.5+.5; ALBEDO=vec3(.028,.145,.197)+vec3(.032,.077,.080)*clamp((n+k)*.5,.0,1.0)+vec3(.027,.062,.065)*highlights+vec3(.002,.010,.015)*swell; }"
	shader_mat.shader = shader


func _fix_stern_wake() -> void:
	if _wake_visual == null:
		return
	# Previously the ship had one large rectangular white plane positioned
	# toward its bow; this is the visible "flat fan" in Android screenshots.
	_wake_visual.mesh = null
	_wake_visual.position = Vector3(0.0, -0.57, 2.7)
	for child in _wake_visual.get_children():
		child.queue_free()
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.name = "PortWake" if side < 0 else "StarboardWake"
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(0.17, 3.8)
		strip.mesh = mesh
		strip.position = Vector3(side * 0.55, 0.0, 0.95)
		strip.rotation.y = side * 0.16
		var foam := StandardMaterial3D.new()
		foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		foam.albedo_color = Color(0.57, 0.78, 0.81, 0.31)
		foam.cull_mode = BaseMaterial3D.CULL_DISABLED
		strip.material_override = foam
		_wake_visual.add_child(strip)
	_wake_visual.visible = false


func _reduce_target_ring() -> void:
	if _target_ring == null:
		return
	var ring := TorusMesh.new()
	ring.inner_radius = 1.6
	ring.outer_radius = 1.88
	_target_ring.mesh = ring
	_target_ring.position.y = 0.1


func _apply_fleet_palette() -> void:
	for entry: Dictionary in enemies:
		if not entry.has("variant_tint"):
			continue
		var vessel: Node3D = entry["node"]
		if not is_instance_valid(vessel):
			continue
		var adapter: Node = vessel.get_node_or_null("ShipSprite")
		if adapter == null:
			continue
		var sprite: Sprite3D = adapter.get("visual") as Sprite3D
		if sprite == null:
			continue
		sprite.modulate = entry["variant_tint"]
		sprite.pixel_size *= float(entry["variant_scale"])
		var label: Label3D = entry["plate"]
		if is_instance_valid(label):
			label.modulate = entry["variant_tint"]


func _switch_graphics() -> void:
	super._switch_graphics()
	_apply_fleet_palette()
	_apply_player_coating()


func _refresh() -> void:
	super._refresh()
	if target < 0 or target >= enemies.size() or _target_bar == null:
		return
	var enemy: Dictionary = enemies[target]
	if not enemy.has("max_hp"):
		return
	var maximum: int = int(enemy["max_hp"])
	_target_bar.max_value = maximum
	_target_bar.value = int(enemy["hp"])
	if _target_numbers != null:
		var vessel: Node3D = enemy["node"]
		_target_numbers.text = "LEBEN %d / %d · %d m" % [
			int(enemy["hp"]), maximum, roundi(ship.position.distance_to(vessel.position))
	]


func _player_impact(index: int, actor: Node3D, damage: int) -> void:
	# Treasure class rewards are applied through the same physical chest
	# collection mechanic, not by adding currency instantly.
	var class_gold := 0
	var actor_hp := 0
	if index >= 0 and index < enemies.size():
		var enemy: Dictionary = enemies[index]
		actor_hp = int(enemy["hp"])
		class_gold = int(enemy.get("loot_gold", 0))
	super._player_impact(index, actor, damage)
	if actor_hp > 0 and actor_hp <= damage and class_gold > 0 and is_instance_valid(actor):
		# Base combat already spawns a chest with 25 gold for ship kills.
		# Extra class rewards appear in a second nearby collectible chest.
		_create_loot(actor.position + Vector3(2.6, 0.0, 0.0), class_gold)


func _make_hud() -> void:
	super._make_hud()
	_coating_button = _control("SCHIFFSBESCHICHTUNG", Callable(self, "_cycle_player_coating"))
	_coating_button.name = "ShipCoatingSelector"
	_ui_root.remove_child(_coating_button)
	_options.add_child(_coating_button)
	_coating_button.tooltip_text = "Wechselt die Schiffsoptik ohne Rücksetzen von HP, Kurs oder Beute"


func _layout_hud() -> void:
	super._layout_hud()
	if _coating_button == null or _options == null:
		return
	var bounds := get_viewport().get_visible_rect().size
	var margin := 10.0 if bounds.y < 540.0 or bounds.x < 1024.0 else 16.0
	var menu_width := minf(310.0, bounds.x - 2.0 * margin)
	_place(_options, bounds.x - menu_width - margin, 42.0 + margin, menu_width, 315.0)
	_place(_coating_button, 18.0, 216.0, menu_width - 36.0, 42.0)
	_place(_build_label, 18.0, 270.0, menu_width - 36.0, 22.0)


func _cycle_player_coating() -> void:
	if ship == null:
		return
	_coating_index = (_coating_index + 1) % PLAYER_COATINGS.size()
	# Keep the SAME player node and gameplay state, swapping only the visual
	# source sheet by way of the existing live sprite replacement adapter.
	_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
	_apply_player_coating()
	hint = "Schiffsbeschichtung: " + str(PLAYER_COATINGS[_coating_index]["name"])
	_refresh()


func _apply_player_coating() -> void:
	if ship == null:
		return
	var adapter: Node = ship.get_node_or_null("ShipSprite")
	if adapter == null:
		return
	var sprite: Sprite3D = adapter.get("visual") as Sprite3D
	if sprite == null:
		return
	sprite.modulate = PLAYER_COATINGS[_coating_index]["tint"]
	# Called on a fresh source adapter (not every frame).
	sprite.pixel_size *= float(PLAYER_COATINGS[_coating_index]["scale"])
	if _coating_button != null:
		_coating_button.text = "SCHIFF: " + str(PLAYER_COATINGS[_coating_index]["name"])

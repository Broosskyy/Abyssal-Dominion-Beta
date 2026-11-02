extends Node3D
## Abyssal Dominion M303 — independent, LOCAL classic-sea-chart prototype.
## No live multiplayer, no authoritative combat, no real economy.

const SHIP = "res://assets/production_placeholders/p0/ship_medium.glb"
const ENEMY = "res://assets/production_placeholders/m295/npc_raider_01.glb"
const ISLAND_SNOW = "res://assets/placeholder_pack/models/island_snow.glb"
const ISLAND_ROCK = "res://assets/placeholder_pack/models/island_rock.glb"
const ISLAND_TROPICAL = "res://assets/placeholder_pack/models/island_tropical.glb"
const MINI_MAP = preload("res://scripts/classic/classic_minimap.gd")
const SHIP_SPRITE = preload("res://scripts/classic/classic_ship_visual.gd")
const ROUTE_PLANNER = preload("res://scripts/classic/classic_route_planner.gd")
const MONSTER = "res://assets/placeholder_pack/models/monster_kraken.glb"
const CAPTAIN_ATLAS = "res://assets/classic/sprites/captain_16dir.svg"
const CORSAIR_ATLAS = "res://assets/classic/sprites/corsair_16dir.svg"
const OFFSET = Vector3(0.0, 68.0, 43.0)

var ship: Node3D
var camera: Camera3D
var enemies: Array[Dictionary] = []
var islands: Array[Dictionary] = []
var loot_items: Array[Dictionary] = []
var gold := 0
var cannonballs := 100
var harpoons := 60
var kills := 0
var hull := 100
var weapon_mode := "cannon"
var repair_cooldown := 0.0
var enemy_attack_timer := 3.0
var route: Array[Vector3] = []
var target := -1
var firing := false
var reload := 0.0
var zoom := 82.0
var pan := Vector3.ZERO
var mouse_panning := false
var status: Label
var target_text: Label
var attack_button: Button
var harpoon_button: Button
var mini: Control
var hint := "Auf Wasser tippen = Kurs setzen"


func _ready() -> void:
	_make_ocean()
	_make_light()
	_build_world()
	_make_camera()
	_make_hud()
	_refresh()


func _make_ocean() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(280, 210)
	water.mesh = plane
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; void fragment() { vec2 p=UV*vec2(84.0,65.0); float w=sin(p.x*1.5+TIME*.42)*sin(p.y*1.3-TIME*.38); float c=sin(p.x*2.3+p.y*1.4+TIME*.65); ALBEDO=vec3(.026,.155,.225)+vec3(.025,.048,.060)*(w+c)*.5; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	water.material_override = material
	add_child(water)


func _make_light() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -24, 0)
	light.light_energy = 1.4
	add_child(light)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b3045")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a7b9c6")
	env.ambient_light_energy = 0.75
	world.environment = env
	add_child(world)


func _asset(file: String, where: Vector3, scale_factor: float, label: String, atlas_path: String = "") -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	holder.position = where
	add_child(holder)
	if not atlas_path.is_empty():
		var sheet := SHIP_SPRITE.new()
		sheet.name = "ShipSprite"
		holder.add_child(sheet)
		if sheet.configure(atlas_path, 0.029 * scale_factor):
			return holder
		sheet.queue_free()
	var packed := load(file) as PackedScene
	if packed != null:
		var model := packed.instantiate() as Node3D
		if model != null:
			holder.add_child(model)
			model.scale = Vector3.ONE * scale_factor
	return holder


func _nameplate(anchor: Node3D, text_value: String, tint: Color) -> Label3D:
	var tag := Label3D.new()
	tag.text = text_value
	tag.position.y = 5.0
	tag.font_size = 38
	tag.pixel_size = 0.013
	tag.modulate = tint
	tag.outline_size = 6
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	anchor.add_child(tag)
	return tag


func _build_world() -> void:
	var land := [
		{"p": Vector3(-42,0,-27), "r": 14.0, "mesh": ISLAND_SNOW, "s": 2.5},
		{"p": Vector3(47,0,22), "r": 14.0, "mesh": ISLAND_SNOW, "s": 2.2},
		{"p": Vector3(-89,0,38), "r": 11.0, "mesh": ISLAND_ROCK, "s": 2.0},
		{"p": Vector3(100,0,-42), "r": 13.0, "mesh": ISLAND_TROPICAL, "s": 2.0}
	]
	for i in land.size():
		var item: Dictionary = land[i]
		islands.append({"position": item.p, "radius": item.r})
		_asset(str(item.mesh), item.p, float(item.s), "Island_%d" % i)
	ship = _asset(SHIP, Vector3(0, 0.65, 0), 0.9, "PlayerShip", CAPTAIN_ATLAS)
	_nameplate(ship, "Kapitän", Color("78ec92"))
	var fleet := [
		{"p": Vector3(-13,.65,-25), "name": "Korsar"},
		{"p": Vector3(19,.65,-15), "name": "Plünderer"},
		{"p": Vector3(39,.65,-25), "name": "Schurkenkapitän"},
		{"p": Vector3(-24,.65,29), "name": "Seekrieger"},
		{"p": Vector3(75,.65,12), "name": "Freibeuter"}
	]
	for i in fleet.size():
		var entry: Dictionary = fleet[i]
		var vessel := _asset(ENEMY, entry.p, 0.8, "NPC_%d" % i, CORSAIR_ATLAS)
		var plate := _nameplate(vessel, str(entry.name), Color("f2bd83"))
		enemies.append({"node": vessel, "name": entry.name, "hp": 100, "plate": plate, "kind": "ship"})
	var monster := _asset(MONSTER, Vector3(75, 0.65, -65), 0.8, "SeaMonster")
	var monster_plate := _nameplate(monster, "Seemonster", Color("ef7ac4"))
	enemies.append({"node": monster, "name": "Seemonster", "hp": 140, "plate": monster_plate, "kind": "monster"})


func _make_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.far = 600.0
	camera.current = true
	add_child(camera)
	camera.global_position = ship.global_position + OFFSET
	camera.look_at(ship.global_position)


func _style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("102638e9")
	box.border_color = Color("b99b62")
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box


func _button(title: String, x: float, y: float, w: float, h: float, right: bool, bottom: bool, action: Callable, root: Control) -> Button:
	var b := Button.new()
	b.text = title
	b.position = Vector2(x,y)
	b.size = Vector2(w,h)
	if right:
		b.anchor_left = 1.0
		b.anchor_right = 1.0
	if bottom:
		b.anchor_top = 1.0
		b.anchor_bottom = 1.0
	b.add_theme_stylebox_override("normal", _style())
	b.add_theme_color_override("font_color", Color("f5dcaa"))
	b.add_theme_font_size_override("font_size", 15)
	root.add_child(b)
	b.pressed.connect(action)
	return b


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var top := PanelContainer.new()
	top.anchor_right = 1.0
	top.offset_bottom = 43.0
	top.add_theme_stylebox_override("panel", _style())
	root.add_child(top)
	var nav := Label.new()
	nav.text = "  ABYSSAL DOMINION  |  10/2 NORDMEER          KARTE · QUELLENDEMO          BEWEGEN · ZIELEN · KÄMPFEN · BEUTE"
	nav.add_theme_color_override("font_color", Color("f3d89c"))
	nav.add_theme_font_size_override("font_size", 15)
	top.add_child(nav)
	mini = MINI_MAP.new()
	mini.anchor_left = 1.0
	mini.anchor_right = 1.0
	mini.position = Vector2(-181, 54)
	mini.size = Vector2(165,165)
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(mini)
	status = Label.new()
	status.anchor_top = 1.0
	status.anchor_bottom = 1.0
	status.position = Vector2(19,-63)
	status.size = Vector2(640,50)
	status.add_theme_color_override("font_color", Color("f6ddb2"))
	status.add_theme_font_size_override("font_size", 15)
	root.add_child(status)
	target_text = Label.new()
	target_text.anchor_left = 1.0
	target_text.anchor_right = 1.0
	target_text.position = Vector2(-355,225)
	target_text.size = Vector2(335,50)
	target_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	target_text.add_theme_color_override("font_color", Color("f6ddb2"))
	root.add_child(target_text)
	attack_button = _button("KANONEN START", -205, -91, 185, 58, true, true, Callable(self,"_toggle_fire"), root)
	harpoon_button = _button("MODUS: KANONE", -382, -82, 165, 50, true, true, Callable(self,"_harpoon"), root)
	_button("REPARIEREN", -533, -82, 144, 50, true, true, Callable(self,"_repair"), root)
	_button("+", -69, 228, 49, 45, true, false, Callable(self,"_zoom_in"), root)
	_button("−", -123, 228, 49, 45, true, false, Callable(self,"_zoom_out"), root)
	_button("ZENTRIEREN", 18, -140, 130, 50, false, true, Callable(self,"_recenter"), root)
	_button("KAMERA ◀", 158, -140, 124, 50, false, true, Callable(self,"_pan_left"), root)
	_button("KAMERA ▶", 290, -140, 124, 50, false, true, Callable(self,"_pan_right"), root)


func _process(delta: float) -> void:
	_sail(delta)
	_collect_nearby_loot()
	repair_cooldown = maxf(0.0, repair_cooldown - delta)
	enemy_attack_timer -= delta
	if enemy_attack_timer <= 0.0:
		enemy_attack_timer = 3.0
		_enemy_attack()
	if firing:
		reload -= delta
		if reload <= 0:
			reload = 1.2
			_fire()
	var center := ship.global_position + pan
	camera.global_position = camera.global_position.lerp(center + OFFSET, minf(1.0, 4.0 * delta))
	camera.look_at(center)
	camera.size = lerpf(camera.size, zoom, minf(1.0, 7.0 * delta))
	mini.set("player_position", Vector2(ship.position.x,ship.position.z))
	mini.set("islands", islands)
	var dots: Array[Vector2] = []
	for enemy in enemies:
		if int(enemy.hp) > 0:
			var node: Node3D = enemy.node
			dots.append(Vector2(node.position.x,node.position.z))
	mini.set("enemies", dots)
	mini.queue_redraw()


func _blocked(point: Vector3) -> bool:
	for island in islands:
		var center: Vector3 = island.position
		if Vector2(center.x,center.z).distance_to(Vector2(point.x,point.z)) < float(island.radius) + 2.0:
			return true
	return false


func _course(point: Vector3) -> void:
	point = Vector3(clampf(point.x, -135.0, 135.0), 0.65, clampf(point.z, -100.0, 100.0))
	if _blocked(point):
		hint = "Insel blockiert das Ziel"
		_refresh()
		return
	var coordinates: PackedVector2Array = ROUTE_PLANNER.plan(
		Vector2(ship.position.x, ship.position.z),
		Vector2(point.x, point.z),
		islands
	)
	if coordinates.is_empty():
		if ship.position.distance_to(point) < 0.8:
			hint = "Schiff bereits am Ziel"
		else:
			hint = "Kein sicherer Weg zur Position"
		_refresh()
		return
	route.clear()
	for coordinate in coordinates:
		route.append(Vector3(coordinate.x, 0.65, coordinate.y))
	hint = "Kurs gesetzt · %d Wegpunkte" % route.size()
	_refresh()

func _sail(delta: float) -> void:
	if route.is_empty():
		return
	var gap := route[0] - ship.position
	gap.y = 0
	if gap.length() < 0.8:
		route.remove_at(0)
		return
	var direction := gap.normalized()
	var next := ship.position + direction * minf(11.0 * delta,gap.length())
	if _blocked(next):
		route.clear()
		hint = "Küste erreicht – neues Ziel wählen"
		_refresh()
		return
	ship.position = next
	ship.rotation.y = lerp_angle(ship.rotation.y,atan2(-direction.x,-direction.z),minf(1.0,delta*5.0))
	var display := ship.get_node_or_null("ShipSprite")
	if display != null:
		display.set_heading(ship.rotation.y)


func _world_click(screen: Vector2) -> void:
	var ray_origin := camera.project_ray_origin(screen)
	var ray_direction := camera.project_ray_normal(screen)
	if absf(ray_direction.y) < 0.001:
		return
	var factor := -ray_origin.y / ray_direction.y
	if factor < 0:
		return
	var hit := ray_origin + ray_direction * factor
	var near := 7.0
	var found := -1
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if int(enemy.hp) <= 0:
			continue
		var node: Node3D = enemy.node
		var gap := Vector2(hit.x,hit.z).distance_to(Vector2(node.position.x,node.position.z))
		if gap < near:
			near = gap
			found = i
	if found >= 0:
		target = found
		firing = false
		hint = str(enemies[target].name) + " markiert"
		_refresh()
	else:
		_course(hit)


func _toggle_fire() -> void:
	if target < 0:
		hint = "Zuerst ein Schiff antippen"
	else:
		firing = not firing
		reload = 0.0
		hint = "Dauerfeuer gestartet" if firing else "Dauerfeuer gestoppt"
	_refresh()


func _fire() -> void:
	if target < 0 or target >= enemies.size():
		firing = false
		return
	var enemy: Dictionary = enemies[target]
	var enemy_node: Node3D = enemy["node"]
	if int(enemy["hp"]) <= 0:
		firing = false
		return
	var monster := str(enemy.get("kind", "ship")) == "monster"
	if (monster and weapon_mode != "harpoon") or (not monster and weapon_mode != "cannon"):
		hint = "Monster mit Harpune, Schiffe mit Kanonen angreifen"
		firing = false
	elif ship.position.distance_to(enemy_node.position) > (35.0 if monster else 42.0):
		hint = "Ziel außerhalb der Reichweite"
	elif (monster and harpoons <= 0) or (not monster and cannonballs <= 0):
		hint = "Munition leer"
		firing = false
	else:
		if monster:
			harpoons -= 1
		else:
			cannonballs -= 1
		var damage := 20 if monster else 24
		enemy["hp"] = maxi(0, int(enemy["hp"]) - damage)
		var plate: Label3D = enemy["plate"]
		plate.text = "%s · %d HP" % [str(enemy["name"]), int(enemy["hp"])]
		hint = "Testtreffer · %d Schaden" % damage
		if int(enemy["hp"]) <= 0:
			enemy_node.visible = false
			_create_loot(enemy_node.position, 45 if monster else 25)
			firing = false
			target = -1
			kills += 1
			hint = "Gegner versenkt · Beute einsammeln"
	_refresh()


func _harpoon() -> void:
	weapon_mode = "harpoon" if weapon_mode == "cannon" else "cannon"
	firing = false
	hint = "Harpunen gegen Monster" if weapon_mode == "harpoon" else "Kanonen gegen Schiffe"
	_refresh()


func _repair() -> void:
	if repair_cooldown > 0.0:
		hint = "Reparatur benötigt noch %.0f Sek." % repair_cooldown
	elif hull >= 100:
		hint = "Schiff ist vollständig repariert"
	else:
		hull = min(100, hull + 35)
		repair_cooldown = 18.0
		hint = "Rumpf repariert (lokale Demo)"
	_refresh()


func _enemy_attack() -> void:
	var nearby := 0
	for enemy in enemies:
		if str(enemy.get("kind", "ship")) != "ship" or int(enemy["hp"]) <= 0:
			continue
		var enemy_node: Node3D = enemy["node"]
		if enemy_node.position.distance_to(ship.position) <= 23.0:
			nearby += 1
	if nearby <= 0:
		return
	hull = maxi(0, hull - min(nearby, 2) * 5)
	hint = "Gegnerische Kanonen getroffen! Rumpf: %d" % hull
	if hull <= 0:
		firing = false
		route.clear()
		ship.position = Vector3(0.0, 0.65, 0.0)
		hull = 100
		hint = "Schiff gesunken · lokaler Respawn am Startpunkt"
	_refresh()


func _create_loot(where: Vector3, amount: int) -> void:
	var drop := Node3D.new()
	drop.name = "Loot_%d" % loot_items.size()
	drop.position = where
	add_child(drop)
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.2
	mesh.height = 2.4
	visual.mesh = mesh
	visual.position.y = 1.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f4c55a")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	drop.add_child(visual)
	_nameplate(drop, "BEUTE · %d GOLD" % amount, Color("ffde83"))
	loot_items.append({"node": drop, "gold": amount})


func _collect_nearby_loot() -> void:
	for i in range(loot_items.size() - 1, -1, -1):
		var drop: Dictionary = loot_items[i]
		var node: Node3D = drop["node"]
		if node.position.distance_to(ship.position) <= 5.0:
			gold += int(drop["gold"])
			node.queue_free()
			loot_items.remove_at(i)
			hint = "%d Gold eingesammelt · Gesamt: %d" % [int(drop["gold"]), gold]
			_refresh()


func _zoom_in() -> void:
	zoom = maxf(44.0,zoom-8.0)


func _zoom_out() -> void:
	zoom = minf(135.0,zoom+8.0)


func _recenter() -> void:
	pan = Vector3.ZERO


func _pan_left() -> void:
	pan.x = maxf(-70.0,pan.x-10.0)


func _pan_right() -> void:
	pan.x = minf(70.0,pan.x+10.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_out()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_world_click(event.position)
	elif event is InputEventMouseMotion and mouse_panning:
		pan += Vector3(-event.relative.x,0,-event.relative.y)*zoom/750.0
		pan = pan.limit_length(70.0)


func _refresh() -> void:
	if status != null:
		status.text = "M303.1 · LOKALE DEMO · RUMPF %d/100 · GOLD %d · NPC %d\n%s" % [hull, gold, kills, hint]
	if target_text != null:
		target_text.text = "Kein Ziel" if target < 0 else "%s  ·  %d HP" % [str(enemies[target].name),int(enemies[target].hp)]
	if attack_button != null:
		attack_button.text = "FEUER STOP" if firing else ("HARPUNEN FEUER" if weapon_mode == "harpoon" else "KANONEN FEUER")
	if harpoon_button != null:
		harpoon_button.text = "HARPUNE %d" % harpoons if weapon_mode == "harpoon" else "KUGELN %d" % cannonballs

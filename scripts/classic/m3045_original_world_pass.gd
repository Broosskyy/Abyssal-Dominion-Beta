extends "res://scripts/classic/m3044_naval_hud_ammo_shop.gd"
## M304.5 original environment art integration, real Godot meshes/shader.
## Route obstacles, combat entities, and the existing ship/UI systems stay intact.
const ORIGINAL_ISLAND = preload("res://scripts/classic/m3045_original_island.gd")
const ORIGINAL_KRAKEN = preload("res://scripts/classic/m3045_original_kraken.gd")
const SEA_SHADER := "shader_type spatial; render_mode cull_disabled; varying float swell; void vertex() { vec2 v=VERTEX.xz; swell=sin(v.x*0.56+TIME*0.67)*0.06+sin(v.y*0.43-TIME*0.51)*0.055; VERTEX.y+=swell; } void fragment() { vec2 v=UV*vec2(48.0,36.0); float a=sin(v.x*1.71+TIME*0.74)*sin(v.y*1.23-TIME*0.64); float b=sin(v.x*.61+v.y*.81-TIME*.38); float choppy=sin(v.x*3.31-v.y*2.1+TIME*1.1); float foam=smoothstep(0.69,1.20,(a*.45+b*.48+choppy*.12+.56)); vec3 deep=vec3(.018,.091,.135); vec3 bright=vec3(.049,.212,.222); ALBEDO=mix(deep,bright,clamp(.50+a*.20+b*.27,0.0,1.0))+vec3(.21,.26,.23)*foam*.22; ROUGHNESS=.24+foam*.18; METALLIC=.06; SPECULAR=.67; }"
const COAST_SHADER := "shader_type spatial; render_mode unshaded, cull_disabled, blend_mix, depth_draw_never; void fragment() { vec2 p=UV-vec2(.5); float r=length(p); float wave=.013*sin(atan(p.y,p.x)*17.0+TIME*1.35); float band=1.0-smoothstep(.024,.066,abs(r-(.374+wave))); float scatter=.65+.35*sin(r*75.0-TIME*1.1); ALBEDO=vec3(.65,.86,.80); ALPHA=band*scatter*.32; }"

var _original_coast_effects: Array[MeshInstance3D] = []


func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304.5"
	_build_label.text = "M304.5 · ORIGINAL WORLD PASS"
	_refresh()


func _island_biome(number: int) -> String:
	var biomes := ["snow", "fort", "rock", "tropical", "volcanic", "tropical", "snow", "rock"]
	return biomes[posmod(number, biomes.size())]


func _island_radius(where: Vector3) -> float:
	for island: Dictionary in islands:
		var at: Vector3 = island["position"]
		if at.distance_to(where) < 1.1:
			return float(island["radius"])
	return 11.0


func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	if _asset_mode == "original_fleet":
		if label.begins_with("Island_"):
			var at := Node3D.new()
			at.name = label
			at.position = where
			add_child(at)
			var visual := ORIGINAL_ISLAND.new()
			visual.name = "OriginalLandmass"
			at.add_child(visual)
			var number := label.substr(7).to_int()
			visual.configure(_island_biome(number), _island_radius(where), number)
			return at
		if label == "SeaMonster":
			var monster_holder := Node3D.new()
			monster_holder.name = label
			monster_holder.position = where
			add_child(monster_holder)
			var beast := ORIGINAL_KRAKEN.new()
			beast.name = "OriginalKraken"
			monster_holder.add_child(beast)
			beast.configure(factor)
			return monster_holder
	return super._asset(file, where, factor, label, atlas)


func _make_ocean() -> void:
	super._make_ocean()
	if _asset_mode != "original_fleet":
		return
	var surface := get_node_or_null("UnifiedOcean") as MeshInstance3D
	if surface == null:
		return
	var geometry := surface.mesh as PlaneMesh
	if geometry != null:
		# Subdivisions are GPU displaced, but physics uses the original Y=0 plane.
		geometry.subdivide_width = 70
		geometry.subdivide_depth = 52
	var shader := Shader.new()
	shader.code = SEA_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	surface.material_override = material


func _build_world() -> void:
	super._build_world()
	# Original shoreline foam is a non-colliding shader overlay for each island.
	# The source scene already owns island radii and route-blocking rules.
	var shader := Shader.new()
	shader.code = COAST_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for index in islands.size():
		var entry: Dictionary = islands[index]
		var at: Vector3 = entry["position"]
		var radius: float = float(entry["radius"])
		var coast := MeshInstance3D.new()
		coast.name = "OriginalCoastalFoam_%d" % index
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE * radius * 2.38
		coast.mesh = plane
		coast.material_override = mat
		coast.position = Vector3(at.x, 0.09, at.z)
		coast.visible = _asset_mode == "original_fleet"
		add_child(coast)
		_original_coast_effects.append(coast)


func _apply_graphics_mode() -> void:
	super._apply_graphics_mode()
	# Ships already swap in M304.3; now update land/monster art in-place too.
	for node: Node in get_children():
		if node is Node3D and node.name.begins_with("Island_"):
			var actor := node as Node3D
			_replace_visual(actor, ISLAND_ROCK, 1.0, actor.name)
	for entry: Dictionary in enemies:
		if str(entry.get("kind", "")) != "monster":
			continue
		var actor: Node3D = entry["node"]
		if is_instance_valid(actor):
			_replace_visual(actor, MONSTER, 0.8, "SeaMonster")
	for foam: MeshInstance3D in _original_coast_effects:
		foam.visible = _asset_mode == "original_fleet"
	if _asset_mode == "original_fleet":
		var water := get_node_or_null("UnifiedOcean") as MeshInstance3D
		if water != null:
			var ocean_mat := ShaderMaterial.new()
			var shader := Shader.new()
			shader.code = SEA_SHADER
			ocean_mat.shader = shader
			water.material_override = ocean_mat
	_refresh()


func _refresh() -> void:
	super._refresh()
	for entry: Dictionary in enemies:
		if str(entry.get("kind", "")) != "monster":
			continue
		var actor: Node3D = entry["node"]
		if not is_instance_valid(actor):
			continue
		var kraken: Node = actor.get_node_or_null("OriginalKraken")
		if kraken != null:
			var total_hp := float(entry.get("max_hp", 140))
			kraken.set_hull_ratio(float(entry.get("hp", 0)) / maxf(1.0, total_hp))

class_name M216ShipCombatFx
extends RefCounted
## Presentation-only ship combat effects. Never changes damage, collision, loot or movement authority.

static func _material(color: Color, emission: Color = Color.TRANSPARENT, alpha := true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if alpha: mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission.a > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 2.4
	return mat

static func hit_reaction(ship: Node3D, critical := false) -> void:
	if ship == null or not is_instance_valid(ship) or ship.get_tree() == null: return
	var owner := GameScope.owner_of(ship)
	if owner == null: return
	var ring := MeshInstance3D.new()
	ring.name = "M216HullHitRead"
	var torus := TorusMesh.new(); torus.inner_radius = 0.46; torus.outer_radius = 0.56; torus.rings = 20; torus.ring_segments = 5
	ring.mesh = torus
	var color := Color("ffd267") if critical else Color(0.88, 0.94, 0.98, 0.82)
	var mat := _material(color, Color("ff9a38") if critical else Color.TRANSPARENT)
	ring.material_override = mat; ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.global_position = ship.global_position + Vector3.UP * 0.28
	ring.set_meta("visual_only", true); ring.add_to_group("transient_combat_vfx")
	owner.add_child(ring)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * (2.8 if critical else 2.1), 0.26)
	tween.tween_property(mat, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.26)
	tween.chain().tween_callback(ring.queue_free)
	ship.set_meta("m216_hit_read_until", Time.get_ticks_msec() + 260)

static func sink_burst(ship: Node3D, boss := false) -> void:
	if ship == null or not is_instance_valid(ship): return
	var owner := GameScope.owner_of(ship)
	if owner == null: return
	var root := Node3D.new(); root.name = "M216SinkBurst"; root.global_position = ship.global_position; root.set_meta("visual_only", true)
	owner.add_child(root)
	var smoke_mat := _material(Color(0.12,0.12,0.13,0.62))
	for i in (7 if boss else 4):
		var puff := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 0.34 + i*0.035; sphere.height = sphere.radius*1.7
		puff.mesh = sphere; puff.material_override = smoke_mat.duplicate(); puff.position = Vector3((i%3-1)*0.55,0.35+(i%2)*0.18,(i%2)*0.45)
		root.add_child(puff)
		var tw := puff.create_tween().set_parallel(true); tw.tween_property(puff,"position:y",2.0+0.22*i,1.35); tw.tween_property(puff,"scale",Vector3.ONE*(2.0+0.12*i),1.35)
	var fire := MeshInstance3D.new(); fire.name = "M216SinkFireCore"; var fire_mesh := SphereMesh.new(); fire_mesh.radius=0.42 if boss else 0.30; fire_mesh.height=0.62
	fire.mesh=fire_mesh; fire.material_override=_material(Color(1.0,0.42,0.10,0.86),Color("ff6b1a")); fire.position=Vector3.UP*0.52; root.add_child(fire)
	var debris_mat := _material(Color(0.24,0.15,0.09,0.90))
	for i in (8 if boss else 5):
		var debris := MeshInstance3D.new(); debris.name="M216SinkDebris"; var box:=BoxMesh.new(); box.size=Vector3(0.12,0.07,0.55)
		debris.mesh=box; debris.material_override=debris_mat; debris.position=Vector3.UP*0.42; root.add_child(debris)
		var angle:=TAU*float(i)/float(8 if boss else 5); var target:=Vector3(cos(angle)*(2.3 if boss else 1.55),0.12,sin(angle)*(2.3 if boss else 1.55))
		debris.create_tween().tween_property(debris,"position",target,0.64).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var life := root.create_tween(); life.tween_interval(1.5); life.tween_property(root,"scale",Vector3.ONE*0.82,0.65); life.tween_callback(root.queue_free)

static func respawn_read(ship: Node3D, protection_seconds: float) -> void:
	if ship == null or not is_instance_valid(ship): return
	var owner := GameScope.owner_of(ship); if owner == null: return
	var ring := MeshInstance3D.new(); ring.name="M216RespawnProtectionRing"
	var torus:=TorusMesh.new(); torus.inner_radius=1.55; torus.outer_radius=1.68; torus.rings=28; torus.ring_segments=6; ring.mesh=torus
	var mat:=_material(Color(0.35,0.84,1.0,0.72),Color("55cfff")); ring.material_override=mat; ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.global_position=ship.global_position+Vector3.UP*0.10; ring.set_meta("visual_only",true); owner.add_child(ring)
	var duration:=clampf(protection_seconds,1.0,8.0); var tw:=ring.create_tween().set_parallel(true)
	tw.tween_property(ring,"scale",Vector3.ONE*1.25,duration); tw.tween_property(mat,"albedo_color",Color(0.35,0.84,1.0,0.0),duration); tw.chain().tween_callback(ring.queue_free)

static func loot_drop_read(position: Vector3, boss := false, tree: SceneTree = null) -> void:
	if tree == null or tree.current_scene == null: return
	var ring:=MeshInstance3D.new(); ring.name="M216LootDropBurst"; var torus:=TorusMesh.new(); torus.inner_radius=0.34; torus.outer_radius=0.44; ring.mesh=torus
	var color:=Color("ffd267") if boss else Color("8fd6e5"); var mat:=_material(Color(color.r,color.g,color.b,0.84),color); ring.material_override=mat; ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.global_position=Vector3(position.x,0.18,position.z); ring.set_meta("visual_only",true); ring.add_to_group("transient_combat_vfx"); tree.current_scene.add_child(ring)
	var tw:=ring.create_tween().set_parallel(true); tw.tween_property(ring,"scale",Vector3.ONE*(4.4 if boss else 3.1),0.48); tw.tween_property(mat,"albedo_color",Color(color.r,color.g,color.b,0.0),0.48); tw.chain().tween_callback(ring.queue_free)

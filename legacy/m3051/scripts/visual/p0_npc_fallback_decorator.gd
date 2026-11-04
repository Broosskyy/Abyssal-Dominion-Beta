class_name P0NpcFallbackDecorator
extends RefCounted
## Interim visual-only silhouette differentiation for P0 NPCs.
## Never runs on user replacement GLBs and never owns collision/stats/weapons.

static func apply(visual: Node3D, id: String, user_replacement: bool) -> void:
	if visual == null or user_replacement: return
	if id not in ["npc_friendly_coastal_sloop","npc_scout_01","npc_raider_01","npc_gunship_01","npc_heavy_01"]: return
	# Complete placeholder ships carry their structural silhouette inside the GLB.
	# Preserve this legacy decorator only for older fallback sources.
	if id == "npc_raider_01" and str(visual.get_meta("source_path", "")) == "res://assets/production_placeholders/m295/npc_raider_01.glb": return
	if id == "npc_friendly_coastal_sloop" and str(visual.get_meta("source_path", "")) == "res://assets/production_placeholders/m296/npc_friendly_coastal_sloop.glb": return
	if id == "npc_gunship_01" and str(visual.get_meta("source_path", "")) == "res://assets/production_placeholders/m296/npc_gunship_01.glb": return
	if id == "npc_scout_01" and str(visual.get_meta("source_path", "")) == "res://assets/production_placeholders/m297/npc_scout_01.glb": return
	if id == "npc_heavy_01" and str(visual.get_meta("source_path", "")) == "res://assets/production_placeholders/m297/npc_heavy_01.glb": return
	var old := visual.get_node_or_null("M69RoleSilhouette")
	if old != null: old.queue_free()
	var root := Node3D.new()
	root.name = "M69RoleSilhouette"
	root.set_meta("classification","POLISHED_PROCEDURAL_FALLBACK")
	visual.add_child(root)
	match id:
		"npc_friendly_coastal_sloop":
			_add_box(root,"CoastalDeck",Vector3(0,0.72,-0.55),Vector3(1.25,0.16,1.55),Color("7a5a3d"))
			_add_sail(root,"CoastalSail",Vector3(0,2.0,0.15),Vector2(1.35,1.55),Color("d9d1b8"))
		"npc_scout_01":
			_add_box(root,"ScoutKeel",Vector3(0,-0.08,0.7),Vector3(0.72,0.24,2.55),Color("31434a"))
			_add_sail(root,"ScoutSail",Vector3(0,2.15,0.65),Vector2(1.05,1.8),Color("c4cec6"))
			_add_bowsprit(root,3.45,Color("5b3a22"))
		"npc_raider_01":
			_add_box(root,"RaiderForecastle",Vector3(0,0.76,1.22),Vector3(1.45,0.3,0.82),Color("65382e"))
			_add_box(root,"RaiderStern",Vector3(0,0.85,-1.72),Vector3(1.48,0.42,0.72),Color("4b2c25"))
			_add_sail(root,"RaiderSail",Vector3(0,2.18,0.25),Vector2(1.55,1.65),Color("b9aa91"))
		"npc_gunship_01":
			_add_box(root,"GunDeck",Vector3(0,0.62,0),Vector3(2.58,0.26,2.55),Color("4f3d33"))
			for side in [-1.0,1.0]:
				_add_box(root,"Broadside",Vector3(side*1.46,0.56,0),Vector3(0.18,0.22,2.25),Color("272d31"))
			_add_sail(root,"GunshipSail",Vector3(0,2.0,-0.15),Vector2(1.55,1.45),Color("c2bba7"))
		"npc_heavy_01":
			_add_box(root,"HeavyDeck",Vector3(0,0.75,-0.15),Vector3(2.75,0.34,2.8),Color("3d3430"))
			_add_box(root,"HeavyStern",Vector3(0,1.15,-1.85),Vector3(2.25,0.72,0.9),Color("332b29"))
			_add_box(root,"HeavyForecastle",Vector3(0,1.0,1.65),Vector3(2.0,0.48,0.85),Color("4b3b33"))
			_add_sail(root,"HeavySail",Vector3(0,2.35,-0.1),Vector2(1.8,1.65),Color("aaa697"))
	if id!="npc_friendly_coastal_sloop":
		_add_pirate_pennant(root,id)
		_add_pirate_silhouette_accent(root,id)
		_add_pirate_sail_patch(root,id)
	root.set_meta("p0_role",id)
	root.set_meta("m85_pirate_identity",id!="npc_friendly_coastal_sloop")

static func _mat(color: Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.82
	return m

static func _add_box(root: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var node:=MeshInstance3D.new()
	node.name=name
	node.mesh=FallbackPrimitiveLibrary.box(size)
	node.position=pos
	node.material_override=_mat(color)
	root.add_child(node)

static func _add_sail(root: Node3D, name: String, pos: Vector3, size: Vector2, color: Color) -> void:
	var node:=MeshInstance3D.new()
	node.name=name
	node.mesh=FallbackPrimitiveLibrary.quad(size)
	node.position=pos
	var mat:=_mat(color)
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=mat
	root.add_child(node)

static func _add_bowsprit(root: Node3D, length: float, color: Color) -> void:
	var node:=MeshInstance3D.new()
	node.name="ScoutBowsprit"
	node.mesh=FallbackPrimitiveLibrary.cylinder(0.055,0.085,length)
	node.position=Vector3(0,0.75,2.55)
	node.rotation_degrees.x=72.0
	node.material_override=_mat(color)
	root.add_child(node)


static func _add_pirate_pennant(root:Node3D,id:String)->void:
	var mast_height:=3.15 if id=="npc_heavy_01" else 2.85
	var node:=MeshInstance3D.new()
	node.name="PiratePennant"
	node.mesh=FallbackPrimitiveLibrary.quad(Vector2(0.72,0.34))
	node.position=Vector3(0,mast_height,0.1)
	var color:=Color("7d211f") if id in ["npc_raider_01","npc_gunship_01"] else Color("40342d")
	var mat:=_mat(color)
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=mat
	root.add_child(node)
	var lantern:=MeshInstance3D.new()
	lantern.name="SternLantern"
	lantern.mesh=FallbackPrimitiveLibrary.sphere(0.08,0.16)
	lantern.position=Vector3(0,1.55,-2.35)
	var glow:=_mat(Color("d8a84d"))
	glow.emission_enabled=true
	glow.emission=Color("d8a84d")
	glow.emission_energy_multiplier=1.25
	lantern.material_override=glow
	root.add_child(lantern)


static func _add_pirate_silhouette_accent(root:Node3D,id:String)->void:
	match id:
		"npc_scout_01":
			_add_box(root,"ScoutRaisedBow",Vector3(0,0.84,1.75),Vector3(1.10,0.28,0.52),Color("55402e"))
			_add_box(root,"ScoutRakedStern",Vector3(0,0.72,-1.78),Vector3(0.92,0.22,0.46),Color("3f3128"))
		"npc_raider_01":
			_add_box(root,"RaiderRam",Vector3(0,0.22,2.78),Vector3(0.34,0.26,1.05),Color("3b261b"))
			_add_box(root,"RaiderBrokenRail",Vector3(-0.78,0.98,0.82),Vector3(0.12,0.42,1.15),Color("50301f"))
		"npc_gunship_01":
			_add_box(root,"GunshipSternArch",Vector3(0,1.15,-1.95),Vector3(1.75,0.28,0.35),Color("4d3025"))
			_add_box(root,"GunshipRaisedGunwale",Vector3(0,0.96,0.25),Vector3(2.42,0.18,2.18),Color("46352c"))
		"npc_heavy_01":
			_add_box(root,"HeavyQuarterDeck",Vector3(0,1.55,-1.55),Vector3(1.85,0.28,0.88),Color("3c2a23"))
			_add_box(root,"HeavySternCrown",Vector3(0,1.95,-1.82),Vector3(1.35,0.18,0.42),Color("5a3b25"))


static func _add_pirate_sail_patch(root:Node3D,id:String)->void:
	var socket:=Node3D.new()
	socket.name="PirateSailPatchSlot"
	socket.position=Vector3(0.18,2.1,0.1)
	socket.rotation_degrees.y=8.0
	socket.scale=Vector3.ONE*(1.05 if id=="npc_heavy_01" else 0.82)
	socket.set_meta("production_slot","npc_pirate_sail_patch_01")
	socket.set_meta("visual_only",true)
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,"npc_pirate_sail_patch_01")!=null:return
	var patch:=MeshInstance3D.new()
	patch.mesh=FallbackPrimitiveLibrary.quad(Vector2(0.48,0.34))
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("5d3328");mat.roughness=0.92;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	patch.material_override=mat
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	socket.add_child(patch)

class_name GuildIslandVisualState
extends RefCounted
## Presentation-only visual states. Never computes ownership, war, tower damage or upgrades.

const RELATION_COLORS={
	"neutral_preview":Color("d7a94f"),
	"owned":Color("4fc6b8"),
	"ally":Color("6ccf8f"),
	"enemy":Color("e7775d"),
	"war":Color("ef4b4b")
}

static func apply(root:Node3D)->void:
	if root==null:return
	var old:=root.get_node_or_null("M91VisualState")
	if old!=null:
		root.remove_child(old)
		old.queue_free()
	var layer:=Node3D.new()
	layer.name="M91VisualState"
	layer.set_meta("visual_only",true)
	layer.set_meta("authority","presentation_only")
	root.add_child(layer)
	_add_relation_banner(layer,root)
	for node in root.get_children():
		if not node is Node3D:continue
		if node.has_meta("tower_role") or node.has_meta("facility_id"):
			var previous:=node.get_node_or_null("M91Focus")
			if previous!=null:
				node.remove_child(previous)
				previous.queue_free()
		if node.has_meta("tower_role"):
			_add_tower_ring(layer,node as Node3D)
			_add_hostile_preview(layer,node as Node3D,str(root.get_meta("relation","neutral_preview")))
		elif node.has_meta("facility_id"):_decorate_facility(node as Node3D)
	set_range_preview(root,bool(root.get_meta("range_preview_visible",false)))

static func relation_color(root:Node)->Color:
	return RELATION_COLORS.get(str(root.get_meta("relation","neutral_preview")),RELATION_COLORS.neutral_preview)

static func set_focus(root:Node3D,kind:String,id:String)->void:
	if root==null:return
	root.set_meta("presentation_focus_kind",kind)
	root.set_meta("presentation_focus_id",id)
	for node in root.get_children():
		if not node is Node3D:continue
		var focused:=false
		if kind=="tower":focused=str(node.get_meta("tower_role",""))==id
		elif kind=="facility":focused=str(node.get_meta("facility_id",""))==id
		node.set_meta("presentation_focused",focused)
		node.set_meta("world_selectable_presentation",true)
		node.set_meta("tap_to_sail_authority",false)
		var marker:=node.get_node_or_null("M91Focus") as Node3D
		if marker!=null:marker.visible=focused


static func set_range_preview(root:Node3D,visible:bool)->void:
	if root==null:return
	root.set_meta("range_preview_visible",visible)
	var layer:=root.get_node_or_null("M91VisualState")
	if layer==null:return
	for child in layer.get_children():
		if str(child.name).begins_with("Range_"):child.visible=visible

static func set_tower_damage_state(root:Node3D,role:String,state:String)->bool:
	if root==null or state not in ["intact","damaged","disabled"]:return false
	for node in root.get_children():
		if node is Node3D and str(node.get_meta("tower_role",""))==role:
			node.set_meta("visual_damage_state",state)
			node.set_meta("damage_authoritative",false)
			node.set_meta("damage_state_slot","guild_tower_state_%s_01"%state)
			node.set_meta("permanent_destruction",false)
			_apply_tower_state_visual(node as Node3D,state)
			return true
	return false

static func _apply_tower_state_visual(tower:Node3D,state:String)->void:
	var old:=tower.get_node_or_null("M98DamageState")
	if old!=null:
		tower.remove_child(old)
		old.queue_free()
	var layer:=Node3D.new();layer.name="M98DamageState";layer.set_meta("presentation_only",true);tower.add_child(layer)
	var slot:="guild_tower_state_%s_01"%state
	layer.set_meta("production_slot",slot)
	if AssetVisualLibrary.install(layer,slot)!=null:return
	if state=="intact":return
	var marker:=MeshInstance3D.new()
	marker.mesh=FallbackPrimitiveLibrary.sphere(0.28 if state=="damaged" else 0.34,0.38)
	marker.position=Vector3(0,1.55,0)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("8a4d32") if state=="damaged" else Color("4d5558")
	mat.emission_enabled=state=="damaged";mat.emission=Color("7b2f1d");mat.emission_energy_multiplier=0.55
	marker.material_override=mat;marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.add_child(marker)

static func _add_relation_banner(layer:Node3D,root:Node3D)->void:
	var mast:=MeshInstance3D.new()
	mast.name="RelationMast"
	mast.position=Vector3(0,2.4,-2.6)
	mast.mesh=FallbackPrimitiveLibrary.box(Vector3(0.12,3.4,0.12))
	mast.material_override=EnvironmentMaterialCatalog.harbor_wood()
	mast.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.add_child(mast)
	var flag:=MeshInstance3D.new()
	flag.name="RelationFlag"
	flag.position=Vector3(0.75,3.45,-2.6)
	flag.mesh=FallbackPrimitiveLibrary.box(Vector3(1.45,0.72,0.06))
	flag.material_override=GuildVisualMaterialCache.relation(str(root.get_meta("relation","neutral_preview")))
	flag.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.add_child(flag)

static func _add_tower_ring(layer:Node3D,tower:Node3D)->void:
	var ring:=MeshInstance3D.new()
	ring.name="Range_"+str(tower.get_meta("tower_role","tower"))
	ring.position=tower.position+Vector3(0,0.08,0)
	var radius:=float(tower.get_meta("tower_range",18.0))*0.24
	var torus:=TorusMesh.new()
	torus.inner_radius=maxf(1.0,radius-0.055)
	torus.outer_radius=radius
	ring.mesh=torus
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(relation_color(tower.get_parent()).r,relation_color(tower.get_parent()).g,relation_color(tower.get_parent()).b,0.22)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override=mat
	ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible=false
	ring.set_meta("presentation_only",true)
	ring.set_meta("range_contract_m",float(tower.get_meta("tower_range",0.0)))
	layer.add_child(ring)
	var focus:=MeshInstance3D.new()
	focus.name="M91Focus"
	var focus_mesh:=TorusMesh.new()
	focus_mesh.inner_radius=0.88
	focus_mesh.outer_radius=1.02
	focus.mesh=focus_mesh
	focus.position=Vector3(0,0.07,0)
	var focus_mat:=StandardMaterial3D.new()
	focus_mat.albedo_color=Color("ffd98a")
	focus_mat.emission_enabled=true
	focus_mat.emission=Color("d7a94f")
	focus_mat.emission_energy_multiplier=1.15
	focus_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	focus.material_override=focus_mat
	focus.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	focus.visible=false
	tower.add_child(focus)

static func _add_hostile_preview(layer:Node3D,tower:Node3D,relation:String)->void:
	if relation not in ["enemy","war"]:return
	# The admin relation is a preview, not a server targeting or firing verdict.
	var beacon:=Node3D.new()
	beacon.name="Threat_"+str(tower.get_meta("tower_role","tower"))
	beacon.position=tower.position+Vector3(0,2.15,0)
	beacon.set_meta("production_slot","guild_tower_hostile_beacon_01")
	beacon.set_meta("presentation_only",true)
	beacon.set_meta("hostility_preview_only",true)
	beacon.set_meta("combat_authority",false)
	layer.add_child(beacon)
	if AssetVisualLibrary.install(beacon,"guild_tower_hostile_beacon_01")!=null:return
	var fallback:=MeshInstance3D.new()
	fallback.name="BeaconFallback"
	fallback.mesh=FallbackPrimitiveLibrary.sphere(0.23,0.34)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=RELATION_COLORS[relation]
	mat.emission_enabled=true
	mat.emission=RELATION_COLORS[relation]
	mat.emission_energy_multiplier=0.7
	fallback.material_override=mat
	fallback.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(fallback)

static func _decorate_facility(facility:Node3D)->void:
	facility.set_meta("visual_tier",1)
	facility.set_meta("visual_damage_state","intact")
	facility.set_meta("tier_authoritative",false)
	facility.set_meta("damage_authoritative",false)
	var focus:=MeshInstance3D.new()
	focus.name="M91Focus"
	var ring:=TorusMesh.new()
	ring.inner_radius=1.08
	ring.outer_radius=1.22
	focus.mesh=ring
	focus.position=Vector3(0,0.05,0)
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("ffd98a")
	mat.emission_enabled=true
	mat.emission=Color("d7a94f")
	mat.emission_energy_multiplier=1.05
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	focus.material_override=mat
	focus.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	focus.visible=false
	facility.add_child(focus)

class_name LootPickup
extends Area3D

signal presentation_collected(receipt: Dictionary)

const M215LootCollectionFxScript = preload("res://scripts/visual/m215_loot_collection_fx.gd")
const M219WorldReadabilityCatalogScript = preload("res://scripts/ui/m219_world_readability_catalog.gd")

var loot_type := "coins"
var amount := 25
var lifetime := 45.0
var loot_table_id := ""
var loot_seed := 0
var base_y := 0.9
var collected := false
var loot_tier := "common"
var display_label := "SALVAGE"
var proximity_collect_radius := 4.25


func _ready() -> void:
	add_to_group("loot")
	add_to_group("world_poi_markers")
	set_meta("poi_kind", "loot")
	set_meta("poi_label", display_label)
	set_meta("marker_slot", "marker_loot")
	var m219_priority := M219WorldReadabilityCatalogScript.loot_priority(loot_tier, loot_type)
	set_meta("marker_priority", maxi(WorldMarkerPriorityCatalog.priority("loot"), m219_priority))
	set_meta("m219_loot_priority", m219_priority)
	set_meta("m219_readability_tier", loot_tier)
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	LootVisual.build(self, loot_type == "repair", loot_type == "admiral_chest", loot_tier, loot_type)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	lifetime=float(GameplayRuleset.rule_value(get_tree(),"loot.pickup_lifetime",lifetime))
	proximity_collect_radius=float(GameplayRuleset.rule_value(get_tree(),"loot.proximity_collect_radius",proximity_collect_radius))
	shape.radius=float(GameplayRuleset.rule_value(get_tree(),"loot.pickup_radius",0.85))
	collision.shape = shape
	add_child(collision)


func _process(delta: float) -> void:
	lifetime -= delta
	rotation.y += delta * 0.22
	position.y = base_y + sin(Time.get_ticks_msec() * 0.004) * 0.18
	# M181 fallback: the visual ship hull is much larger than the original tiny
	# pickup sphere. Proximity collection makes sailing visibly near loot reliable
	# even when a device misses the Area3D enter edge during a busy physics frame.
	if not collected:
		var player := get_tree().get_first_node_in_group("player") as ShipMotor
		if player != null and player.global_position.distance_to(global_position) <= proximity_collect_radius:
			_collect(player)
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	_collect(body)


func _collect(body: Node3D) -> void:
	if collected or not body.is_in_group("player"):
		return
	var player_health := body.get_node_or_null("Health") as ShipHealth
	if player_health == null or player_health.is_sunk:
		return
	collected = true
	var health_before := player_health.current_health
	var reward:=maxi(0,roundi(float(amount)*DynamicEventResolver.multiplier(get_tree(),"gold",TrustedTimeService.now(get_tree()))))
	if loot_type == "repair":
		var health := body.get_node_or_null("Health") as ShipHealth
		if health != null:
			health.repair(float(reward))
	else:
		var progression := body.get_node_or_null("Progression") as PlayerProgression
		if progression != null:
			var services:=ServiceLocator.from(get_tree())
			if services!=null and services.wallet!=null:
				services.wallet.add_coins(reward,"loot_pickup")
			else:
				progression.add_coins(reward)
		var inventory := body.get_node_or_null("Inventory") as PlayerInventory
		if inventory != null and loot_type in ["salvage_chest", "admiral_chest"]:
			var material_amount:=int(GameplayRuleset.rule_value(get_tree(),"loot.admiral_material_amount",2)) if loot_type=="admiral_chest" else int(GameplayRuleset.rule_value(get_tree(),"loot.salvage_material_amount",1))
			var materials:=GameplayRuleset.array(get_tree(),"loot.salvage_materials",["wood","metal","components"])
			var material_id:=str(materials[randi()%materials.size()]) if not materials.is_empty() else "wood"
			var services:=ServiceLocator.from(get_tree())
			if services!=null and services.inventory!=null:
				services.inventory.set_count(material_id,inventory.count(material_id)+material_amount)
			else:
				inventory.set_count(material_id, inventory.count(material_id) + material_amount)
			body.set_meta("last_salvage_material", "%s +%d" % [material_id, material_amount])
	if not loot_table_id.is_empty():
		var inventory:=body.get_node_or_null("Inventory") as PlayerInventory
		var dynamic_rewards:=DynamicLootResolver.roll(get_tree(),loot_table_id,loot_seed if loot_seed!=0 else int(Time.get_ticks_msec()))
		for row in dynamic_rewards:
			var item_id:=str(row.get("item_id",""));var qty:=int(row.get("amount",0))
			if inventory!=null and not item_id.is_empty() and qty>0:inventory.set_count(item_id,inventory.count(item_id)+qty)
	var missions:=body.get_node_or_null("Missions") as MissionSystem
	if missions!=null:missions.record_loot()
	QuestActivityBus.emit(get_tree(),"loot",{"content_id":loot_table_id if not loot_table_id.is_empty() else loot_type,"tags":[loot_type,loot_tier],"amount":1})
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	var presentation_catalog := M175FeedbackPresentationCatalog.current(get_tree())
	var presentation := presentation_catalog.reward_presentation("repair" if loot_type == "repair" else loot_tier) if presentation_catalog != null else {}
	if hud != null:
		var material_text := str(body.get_meta("last_salvage_material", ""))
		var reward_text := "%s: +%.0f Rumpf" % [str(presentation.get("label", "BERGUNG")), player_health.current_health - health_before]
		if loot_type != "repair":
			reward_text = "%s: +%d Gold" % [str(presentation.get("label", display_label)), reward]
			if not material_text.is_empty():
				reward_text += " · " + material_text
		# Pickup truth outranks the earlier "loot in water" hint, otherwise a quick
		# collection can be hidden behind the still-active sink notification.
		hud.note_prioritized(reward_text, 8, "reward", maxi(3800, int(presentation.get("notice_ms", 2600))))
	CombatVfx.action(get_tree(), str(presentation.get("vfx_action", "loot_%s" % ("repair" if loot_type == "repair" else loot_tier))), global_position)
	# M215: immediate world-space pickup confirmation, visual-only; rewards and pickup radius are unchanged.
	var pickup_fx := M215LootCollectionFxScript.new()
	pickup_fx.name = "M215LootCollectionFX"
	GameScope.owner_of(self).add_child(pickup_fx)
	pickup_fx.global_position = Vector3(global_position.x, 0.10, global_position.z)
	presentation_collected.emit({"loot_type":loot_type, "loot_tier":loot_tier, "loot_table_id":loot_table_id, "presentation_only":true})
	queue_free()

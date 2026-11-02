extends Control
## Standalone F6 tool; never creates a player, save, account or game simulation.
var selector: OptionButton
var kind_filter: OptionButton
var status_filter: OptionButton
var priority_filter: OptionButton
var all_choices: Array[Dictionary] = []
var details: Label
var art: TextureRect
var view_container: SubViewportContainer
var viewport: SubViewport
var model_root: Node3D
var camera: Camera3D
var choices: Array[Dictionary] = []
var turn := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = NauticalTheme.create()
	var background := ColorRect.new()
	background.color = Color("061a27")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(column)
	var title := Label.new()
	title.text = "M105 · P0 REPLACEMENT DASHBOARD / MOBILE / WORLD QA · keine Spielsimulation"
	column.add_child(title)
	var coverage := ProductionCoverage.report()
	var summary := Label.new()
	summary.text = "Coverage: %d Slots · %d Overrides · Missing P0 %d / P1 %d / P2 %d" % [coverage.total, coverage.overrides, coverage.p0_missing, coverage.p1_missing, coverage.p2_missing]
	column.add_child(summary)
	var p0_summary:=Label.new()
	p0_summary.text=P0ReplacementDashboard.summary_line()
	column.add_child(p0_summary)
	var filters := HBoxContainer.new()
	column.add_child(filters)
	kind_filter = OptionButton.new()
	for label in ["ALL", "MODELS", "UI", "VFX", "AUDIO"]: kind_filter.add_item(label)
	kind_filter.item_selected.connect(func(_i): _rebuild_choices())
	filters.add_child(kind_filter)
	status_filter = OptionButton.new()
	for label in ["ALL STATUS", "ACTIVE", "PREPARED", "PLACEHOLDER/FALLBACK"]: status_filter.add_item(label)
	status_filter.item_selected.connect(func(_i): _rebuild_choices())
	filters.add_child(status_filter)
	priority_filter = OptionButton.new()
	for label in ["ALL PRIORITY", "P0", "P1", "P2", "P0 FIRST 13", "M58 GLB WAVE", "M59 HUD", "M60 TARGET/STATUS", "M61 COMBAT/WORLD", "M62 WORLD/HARBOR", "M63 ENV/VFX", "M65 P0 SHIPS", "M66 SHIP POLISH", "M67 WORLD POLISH", "M68 MONSTER", "M69 P0 NPC", "M70 CONTENT", "M71 WORLD", "M72 POI", "M73 DRESSING", "M74 FEEDBACK", "M75 CLOSURE", "M76 SESSION", "M78 WORLD", "M79 PRIORITY", "M80 CONSOLIDATE", "M81 CLOSURE", "M82 CROSSPLAY", "M86 HUD/WORLD"]: priority_filter.add_item(label)
	priority_filter.item_selected.connect(func(_i): _rebuild_choices())
	filters.add_child(priority_filter)
	selector = OptionButton.new()
	selector.custom_minimum_size.y = 50
	VisualAssetCatalog.ensure_loaded()
	for kind in ["models", "ui", "vfx", "audio"]:
		for id in VisualAssetCatalog.slots.get(kind, {}):
			all_choices.append({"kind": kind, "id": id})
	selector.item_selected.connect(show_asset)
	column.add_child(selector)
	_rebuild_choices()
	var actions := HBoxContainer.new()
	column.add_child(actions)
	for angle in [-45, 45]:
		var rotate := Button.new()
		rotate.text = "Drehen %d°" % angle
		rotate.custom_minimum_size.y = 48
		rotate.pressed.connect(func(): turn += angle; model_root.rotation_degrees.y = turn)
		actions.add_child(rotate)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)
	view_container = SubViewportContainer.new()
	view_container.stretch = true
	view_container.size_flags_vertical = SIZE_EXPAND_FILL
	view_container.custom_minimum_size.y = 180
	column.add_child(view_container)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	view_container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("103444")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d4e8ef")
	environment.environment.ambient_light_energy = 0.75
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_energy = 1.25
	world.add_child(sun)
	model_root = Node3D.new()
	world.add_child(model_root)
	# Thin cyan cross is the unchanged waterline plane, not model geometry.
	for size_value in [Vector3(100, 0.015, 0.03), Vector3(0.03, 0.015, 100)]:
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size_value
		marker.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("3cc6d7")
		marker.material_override = material
		world.add_child(marker)
	camera = Camera3D.new()
	camera.fov = 42
	world.add_child(camera)
	camera.current = true
	art = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = SIZE_EXPAND_FILL
	art.custom_minimum_size.y = 180
	column.add_child(art)
	show_asset(0)



func _priority_for(kind: String, id: String) -> String:
	return ProductionCoverage.priority_for(kind, id)


func _override_diagnostic(kind: String, id: String) -> String:
	var entry: Variant = VisualAssetCatalog.overrides.get(kind, {}).get(id, {})
	if not entry is Dictionary or str(entry.get("path", "")).is_empty():
		return "OVERRIDE: fehlt → Fallback aktiv"
	var path := str(entry.get("path", ""))
	return "OVERRIDE: OK · %s" % path if ResourceLoader.exists(path) else "OVERRIDE: Pfad fehlt · Fallback aktiv"

func _rebuild_choices() -> void:
	if selector == null: return
	choices.clear()
	selector.clear()
	var kind_labels := ["", "models", "ui", "vfx", "audio"]
	var wanted_kind: String = kind_labels[kind_filter.selected] if kind_filter != null else ""
	var wanted_status := status_filter.selected if status_filter != null else 0
	var wanted_priority: String = ["", "P0", "P1", "P2", "P0_FIRST13", "M58_WAVE", "M59_HUD", "M60_TARGET", "M61_COMBAT", "M62_WORLD", "M63_ENV", "M65_SHIPS", "M66_SHIPS", "M67_WORLD", "M68_MONSTER", "M69_NPC", "M70_CONTENT", "M71_WORLD", "M72_POI", "M73_DRESSING", "M74_FEEDBACK", "M75_CLOSURE", "M76_SESSION", "M78_WORLD", "M79_PRIORITY", "M80_CONSOLIDATE", "M81_CLOSURE", "M82_CROSSPLAY", "M86_HUD_WORLD"][priority_filter.selected] if priority_filter != null else ""
	for choice in all_choices:
		var kind := str(choice.kind)
		if not wanted_kind.is_empty() and kind != wanted_kind: continue
		var entry := VisualAssetCatalog.info(kind, str(choice.id))
		var priority := _priority_for(kind, str(choice.id))
		if wanted_priority == "P0_FIRST13" and str(choice.id) not in P0ReplacementQa.ids():continue
		if wanted_priority == "M58_WAVE" and not AssetImportProfileCatalog.is_p0_wave(str(choice.id)): continue
		if wanted_priority == "M59_HUD" and not str(choice.id).begins_with("hud_"): continue
		if wanted_priority == "M60_TARGET" and not (str(choice.id).begins_with("hud_target_") or str(choice.id).begins_with("hud_status_") or str(choice.id).begins_with("hud_icon_") or str(choice.id).begins_with("hud_bar_fill_")): continue
		if wanted_priority == "M61_COMBAT" and not (str(choice.id).begins_with("ui_ammo_") or str(choice.id).begins_with("ui_payload_") or str(choice.id).begins_with("ui_support_") or str(choice.id).begins_with("ui_action_") or str(choice.id).begins_with("world_nameplate_")): continue
		if wanted_priority == "M62_WORLD" and not (str(choice.id).begins_with("world_") or str(choice.id).begins_with("marker_") or str(choice.id).begins_with("service_") or str(choice.id).begins_with("minimap_")): continue
		if wanted_priority == "M63_ENV" and not (str(choice.id).begins_with("vfx_ship_") or str(choice.id).begins_with("vfx_bow_") or str(choice.id).begins_with("vfx_shoreline_") or str(choice.id).begins_with("vfx_shallow_") or str(choice.id).begins_with("vfx_water_") or str(choice.id).begins_with("vfx_hull_") or str(choice.id).begins_with("vfx_safe_zone_")): continue
		if wanted_priority == "M65_SHIPS" and not ShipAssetAcceptance.is_p0_ship(str(choice.id)): continue
		if wanted_priority == "M66_SHIPS" and not ShipAssetAcceptance.is_p0_ship(str(choice.id)): continue
		if wanted_priority == "M67_WORLD" and WorldVisualProfileCatalog.profile(str(choice.id)).is_empty(): continue
		if wanted_priority == "M68_MONSTER" and MonsterVisualProfileCatalog.profile(str(choice.id)).is_empty(): continue
		if wanted_priority == "M69_NPC" and str(choice.id) not in ["npc_friendly_coastal_sloop","npc_scout_01","npc_raider_01","npc_gunship_01","npc_heavy_01"]: continue
		if wanted_priority == "M70_CONTENT" and str(choice.id) not in ["prop_lighthouse_01","prop_dock_wood_01","prop_warehouse_01","prop_market_stall_01","prop_quest_board_01","nature_palm_cluster_01","nature_rock_cluster_01","prop_wreck_small_01","prop_buoy_navigation_01","prop_crate_stack_01"]: continue
		if wanted_priority == "M71_WORLD" and str(choice.id) not in ["island_tropical_small","island_tropical_medium","island_cliff_cove","harbor_havens_reach","prop_lighthouse_01","prop_dock_wood_01","prop_warehouse_01"]: continue
		if wanted_priority == "M72_POI" and str(choice.id) not in ["poi_salvage_cache_01","poi_wreck_site_01","poi_shrine_beacon_01","poi_monster_nest_01","poi_navigation_marker_01","poi_supply_cache_01","nature_reef_cluster_01","nature_driftwood_cluster_01"]: continue
		if wanted_priority == "M73_DRESSING" and str(choice.id) not in ["nature_palm_single_01","nature_rock_small_01","nature_reef_shallow_01","prop_shipwreck_mast_01","prop_anchor_wreck_01","prop_barrel_cluster_01","nature_palm_cluster_01","nature_rock_cluster_01"]: continue
		if wanted_priority == "M74_FEEDBACK" and str(choice.id) not in ["loot_chest_uncommon","loot_chest_rare","loot_chest_epic","loot_chest_legendary","prop_admiral_banner_01","prop_monster_bones_01","prop_salvage_barrels_01","prop_broken_cannon_01"]: continue
		if wanted_priority == "M75_CLOSURE" and str(choice.id) not in ["monster_early_01","monster_early_fin_detail_01","monster_early_crest_detail_01","prop_loot_float_debris_01","prop_wreck_plank_cluster_01","nature_shallow_foam_cluster_01","nature_seaweed_cluster_01"]: continue
		if wanted_priority == "M76_SESSION" and str(choice.id) not in ["prop_harbor_wayfinder_01","prop_salvage_net_01","prop_floating_barrel_01","prop_broken_mast_01","nature_reef_edge_01","prop_warning_buoy_01","prop_loot_float_debris_01","prop_wreck_plank_cluster_01"]: continue
		if wanted_priority == "M78_WORLD" and str(choice.id) not in ["prop_harbor_crane_01","prop_rope_bundle_01","prop_fish_crates_01","prop_harbor_wayfinder_01","prop_salvage_hook_01","poi_wreck_beacon_01","poi_monster_warning_totem_01","prop_wreck_cannon_01","prop_wreck_sail_torn_01","prop_harbor_net_rack_01","prop_harbor_lantern_post_01","nature_reef_marker_01","prop_monster_bone_rib_01"]: continue
		if wanted_priority == "M79_PRIORITY" and str(choice.id) not in ["prop_harbor_net_rack_01","prop_harbor_lantern_post_01","nature_reef_marker_01","prop_monster_bone_rib_01","prop_monster_skull_01","prop_wreck_anchor_chain_01","prop_harbor_signpost_01","prop_harbor_canvas_awning_01","nature_reef_long_01","prop_drift_cargo_01"]: continue
		if wanted_priority == "M80_CONSOLIDATE" and str(choice.id) not in ["prop_harbor_signpost_01","prop_harbor_canvas_awning_01","prop_wreck_cannon_01","prop_wreck_sail_torn_01","prop_wreck_anchor_chain_01","prop_drift_cargo_01","prop_wreck_hull_section_01","prop_wreck_rudder_01","prop_harbor_mooring_post_01","prop_harbor_bell_01","nature_foam_reef_line_01","prop_monster_warning_flag_01"]: continue
		if wanted_priority == "M81_CLOSURE" and str(choice.id) not in ["prop_harbor_mooring_post_01","prop_harbor_bell_01","prop_wreck_hull_section_01","prop_wreck_rudder_01","nature_foam_reef_line_01","prop_monster_warning_flag_01","prop_harbor_barrel_rack_01","prop_harbor_small_boat_01","prop_wreck_mast_broken_02","prop_wreck_rope_tangle_01","nature_shallow_rock_line_01","prop_monster_claw_mark_01"]: continue
		if wanted_priority == "M82_CROSSPLAY" and str(choice.id) not in ["prop_harbor_barrel_rack_01","prop_harbor_small_boat_01","prop_wreck_mast_broken_02","prop_wreck_rope_tangle_01","nature_shallow_rock_line_01","nature_foam_reef_line_01","prop_harbor_rowboat_02","prop_harbor_cargo_pallet_01","prop_wreck_bow_section_01","prop_wreck_cargo_net_01","nature_shallow_sandbar_01","nature_shallow_reef_spur_01","prop_monster_bone_skull_small_01","prop_navigation_post_01"]: continue
		if wanted_priority == "M86_HUD_WORLD" and str(choice.id) not in ["prop_wreck_keel_section_01","prop_wreck_lantern_01","nature_coast_cliff_spur_01","nature_coast_tidepool_01","prop_monster_harpoon_post_01","prop_monster_warning_chain_01","prop_harbor_sailcloth_bundle_01","prop_harbor_cart_01","prop_wreck_cannon_broken_02","prop_wreck_figurehead_01","nature_coast_rock_arch_small_01","nature_coast_shoal_01","prop_monster_bone_spine_01","prop_monster_harpoon_rack_01"]: continue
		if wanted_priority != "" and wanted_priority not in ["P0_FIRST13","M58_WAVE","M59_HUD","M60_TARGET","M61_COMBAT","M62_WORLD","M63_ENV","M65_SHIPS","M66_SHIPS","M67_WORLD","M68_MONSTER","M69_NPC","M70_CONTENT","M71_WORLD","M72_POI","M73_DRESSING","M74_FEEDBACK","M75_CLOSURE","M76_SESSION","M78_WORLD","M79_PRIORITY","M80_CONSOLIDATE","M81_CLOSURE","M82_CROSSPLAY","M86_HUD_WORLD"] and priority != wanted_priority: continue
		var status := str(entry.get("status", "unknown")).to_lower()
		var classification := str(entry.get("classification", "")).to_lower()
		if wanted_status == 1 and status != "active": continue
		if wanted_status == 2 and status != "prepared": continue
		if wanted_status == 3 and "placeholder" not in classification and "fallback" not in classification: continue
		choices.append(choice)
		selector.add_item("%s · %s · %s" % [_priority_for(kind, str(choice.id)), kind.to_upper(), str(choice.id)])
	if choices.is_empty():
		details.text = "Keine Assets für diesen Filter."
		view_container.visible = false
		art.visible = false
	else:
		show_asset(0)


func _family_for(id: String) -> String:
	for prefix in ["ship_main_", "npc_", "island_", "harbor_", "monster_", "ammo_", "status_", "material_", "support_", "payload_"]:
		if id.begins_with(prefix): return prefix.trim_suffix("_")
	return "core"

func show_asset(index: int) -> void:
	var choice := choices[index]
	var entry := VisualAssetCatalog.info(choice.kind, choice.id)
	details.text = "%s · %s\n%s" % [choice.id, entry.get("status", "unknown"), entry.get("consumer", "")]
	if str(choice.id) in P0ReplacementQa.ids():
		var p0:=P0ReplacementQa.status(str(choice.id))
		details.text+="\nP0 FIRST-13 · %s · Reihenfolge %d"%[str(p0.get("runtime_state","UNKNOWN")),int(p0.get("order",0))]
		details.text+="\n"+P0ReplacementDashboard.asset_line(str(choice.id))
		details.text+="\n"+P0ReplacementDashboard.checklist_line(str(choice.id))
	view_container.visible = choice.kind == "models"
	art.visible = choice.kind == "ui"
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if view_container.visible else SubViewport.UPDATE_DISABLED
	if choice.kind == "ui":
		art.texture = VisualAssetCatalog.texture(choice.id)
		details.text += "\n" + art.texture.resource_path
		return
	turn = 0
	model_root.rotation = Vector3.ZERO
	var visual := AssetVisualLibrary.install(model_root, choice.id)
	if visual == null:
		details.text += "\nMODEL LOAD FAILED"
		return
	var bounds: AABB = model_root.get_meta("hud_visual_bounds")
	var radius := maxf(0.25, bounds.size.length())
	var center := bounds.get_center()
	camera.position = center + Vector3(0.7, 0.55, -0.85).normalized() * radius * 1.9
	camera.look_at(center)
	camera.near = maxf(0.001, radius / 1000.0)
	camera.far = maxf(100, radius * 10)
	details.text += "\n%s\nB×H×L: %.2f × %.2f × %.2f m · cyan: Y=0" % [visual.get_meta("source_path"), bounds.size.x, bounds.size.y, bounds.size.z]
	var m105_diag:=GlbDiagnostics.inspect(model_root,str(choice.id))
	details.text+="\nM105 GLB · bounds %s · forward %s · waterline %s · collision %s"%[str(m105_diag.get("bounds_nonzero",false)),str(m105_diag.get("forward_axis","n/a")),str(m105_diag.get("waterline","n/a")),str(m105_diag.get("collision",""))]
	var qa := AssetImportProfileCatalog.qa_lines(str(choice.id), bounds, str(visual.get_meta("source_path","")), str(visual.get_meta("classification","")))
	if not qa.is_empty():
		details.text += "\n\nM58 P0 QA\n" + "\n".join(qa)
		var expected := AssetImportProfileCatalog.expected_override_path(str(choice.id))
		if not expected.is_empty(): details.text += "\nEXPECTED OVERRIDE · " + expected
	if ShipAssetAcceptance.is_p0_ship(str(choice.id)):
		details.text += "\n\nM65 SHIP ACCEPTANCE\n" + "\n".join(ShipAssetAcceptance.acceptance_lines(str(choice.id), bounds))
		details.text += "\n\nSOCKETS\n" + "\n".join(ShipAssetAcceptance.socket_report(model_root, str(choice.id)))
		var m66_profile := ShipVisualProfileCatalog.profile(str(choice.id))
		if not m66_profile.is_empty():
			details.text += "\n\nM66 VISUAL PROFILE\nSILHOUETTE · %s\nPALETTE · %s\nLOD BIAS · %.2f" % [str(m66_profile.get("silhouette","")),str(m66_profile.get("palette","")),float(m66_profile.get("lod_bias",1.0))]
	var m67_profile := WorldVisualProfileCatalog.profile(str(choice.id))
	if not m67_profile.is_empty():
		details.text += "\n\nM67 WORLD PROFILE\nSILHOUETTE · %s\nPALETTE · %s\nVEGETATION · %.2f\nLOD BIAS · %.2f" % [str(m67_profile.get("silhouette","")),str(m67_profile.get("palette","")),float(m67_profile.get("vegetation_density",0.0)),float(m67_profile.get("lod_bias",1.0))]
	if str(choice.id)=="monster_early_01":
		var monster_qa:=MonsterAnimationAdapter.semantic_acceptance(visual)
		details.text+="\n\nM102 MONSTER RIG/ANIMATION\nPLAYER · %s · TREE · %s\nSEMANTIC · %s\nFINAL HERO READY · %s"%[str(monster_qa.get("animation_player",false)),str(monster_qa.get("animation_tree",false)),str(monster_qa.get("semantic",{})),str(monster_qa.get("final_hero_animation_ready",false))]
	var m68_profile := MonsterVisualProfileCatalog.profile(str(choice.id))
	if not m68_profile.is_empty():
		var budget := MonsterVisualProfileCatalog.budget(get_tree())
		details.text += "\n\nM68 MONSTER PROFILE\nSILHOUETTE · %s\nLOD BIAS · %.2f\nMAX TRANSIENT VFX · %d" % [str(m68_profile.get("silhouette","")),float(budget.get("monster_lod_bias",0.94)),int(budget.get("max_monster_transient_vfx",16))]

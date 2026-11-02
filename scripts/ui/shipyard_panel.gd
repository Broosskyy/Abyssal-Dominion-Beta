class_name ShipyardPanel
extends Control
## M53 responsive shipyard preview. Visual-only preview; gameplay state remains in PlayerShipRoster.

var hud: GameHud
var selected_id := ""
var selector: OptionButton
var preview_root: Node3D
var camera: Camera3D
var details_root: VBoxContainer
var milestone_box: VBoxContainer
var viewport: SubViewport
var turn := 0.0
var _last_size := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = NauticalTheme.create()
	mouse_filter = MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	hide()

func open(owner_hud: GameHud, initial_id := "") -> void:
	hud = owner_hud
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	selected_id = initial_id if ShipCatalog.has_ship(initial_id) else roster.selected_ship_id
	_build()
	show()

func close() -> void:
	hide()
	if hud != null: hud.complete_routed_panel(self)
	queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_resized() -> void:
	if not visible: return
	if _last_size.distance_to(size) < 24.0: return
	_last_size = size
	call_deferred("_build")

func _portrait() -> bool:
	return size.y > size.x * 1.12

func _two_column() -> bool:
	return not _portrait() and size.x >= 760.0 * NauticalTheme.density_scale()

func _build() -> void:
	for child in get_children(): child.queue_free()
	_last_size = size
	var shade := ColorRect.new()
	shade.color = Color(0.005,0.02,0.035,0.96)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var edge := 8 if _portrait() else 12
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side, edge)
	add_child(margin)

	var page := VBoxContainer.new()
	margin.add_child(page)

	var header := HBoxContainer.new()
	page.add_child(header)
	var title := Label.new()
	title.text = "SCHIFFSWERFT · AUSWAHL & VERGLEICH"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header,"Schließen",close)

	selector = OptionButton.new()
	selector.custom_minimum_size.y = 56 * NauticalTheme.density_scale()
	var ids := _ship_ids()
	for id in ids:
		var profile := ShipCatalog.profile_by_id(id)
		selector.add_item("%s · %s%s" % [profile.display_name, _state_text(id), " · AUSGEWÄHLT" if id == selected_id else ""])
		if id == selected_id: selector.select(selector.item_count - 1)
	selector.item_selected.connect(func(index): selected_id = ids[index]; _refresh(); _refresh_selector_labels(ids))
	page.add_child(selector)

	var content: Control
	if _two_column():
		content = HBoxContainer.new()
	else:
		content = VBoxContainer.new()
	content.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(content)

	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = SIZE_EXPAND_FILL
	preview_column.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(preview_column)
	_build_preview(preview_column)

	var details_scroll := ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	details_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	details_scroll.custom_minimum_size = Vector2(300, 200 if _two_column() else 240) * NauticalTheme.density_scale()
	content.add_child(details_scroll)

	details_root = VBoxContainer.new()
	details_root.size_flags_horizontal = SIZE_EXPAND_FILL
	details_scroll.add_child(details_root)
	milestone_box = VBoxContainer.new()

	_refresh()

func _build_preview(parent: VBoxContainer) -> void:
	var preview := SubViewportContainer.new()
	preview.stretch = true
	preview.size_flags_vertical = SIZE_EXPAND_FILL
	preview.size_flags_horizontal = SIZE_EXPAND_FILL
	var min_h := 190 if size.x < 430 * NauticalTheme.density_scale() else (220 if _portrait() else 260)
	preview.custom_minimum_size = Vector2(280, min_h) * NauticalTheme.density_scale()
	parent.add_child(preview)

	viewport = SubViewport.new()
	viewport.own_world_3d = true
	preview.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0d3444")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d9ebef")
	env.ambient_light_energy = 0.75
	env_node.environment = env
	world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-32,0)
	sun.light_energy = 1.3
	world.add_child(sun)

	preview_root = Node3D.new()
	world.add_child(preview_root)

	var waterline := MeshInstance3D.new()
	var waterbox := BoxMesh.new()
	waterbox.size = Vector3(24,0.02,24)
	waterline.mesh = waterbox
	waterline.position.y = -0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08,0.32,0.40,0.42)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	waterline.material_override = mat
	world.add_child(waterline)

	camera = Camera3D.new()
	camera.fov = 40 if _portrait() else 38
	camera.current = true
	world.add_child(camera)

	var rotate_row := HBoxContainer.new()
	parent.add_child(rotate_row)
	_button(rotate_row,"↶ 45°",func(): turn -= 45; preview_root.rotation_degrees.y = turn)
	_button(rotate_row,"45° ↷",func(): turn += 45; preview_root.rotation_degrees.y = turn)

func _refresh_selector_labels(ids:Array[String])->void:
	if selector==null:return
	for i in mini(ids.size(),selector.item_count):
		var id:=ids[i];var profile:=ShipCatalog.profile_by_id(id)
		selector.set_item_text(i,"%s · %s%s"%[profile.display_name,_state_text(id)," · AUSGEWÄHLT" if id==selected_id else ""])

func _refresh() -> void:
	if preview_root == null or details_root == null: return
	turn = 0.0
	preview_root.rotation = Vector3.ZERO
	var visual := ShipyardVisualResolver.install_preview(preview_root, selected_id)
	if visual != null:
		var bounds: AABB = preview_root.get_meta("hud_visual_bounds", AABB(Vector3.ZERO,Vector3(4,3,8)))
		var radius := maxf(2.0,bounds.size.length())
		var center := bounds.get_center()
		var distance_mult := 1.82 if _portrait() else 1.65
		camera.position = center + Vector3(0.85,0.62,-0.95).normalized() * radius * distance_mult
		camera.look_at(center)
		camera.near = 0.01
		camera.far = maxf(100.0,radius*12.0)
	_refresh_details()

func _refresh_details() -> void:
	for child in details_root.get_children(): child.queue_free()
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var voyage := player.get_node("Voyage") as VoyageProgress
	var current_id := roster.selected_ship_id
	var current_level := roster.mastery_level(current_id)
	var selected_level := roster.mastery_level(selected_id) if roster.owns_ship(selected_id) else 1
	var profile := ShipCatalog.mastery_scaled_profile(selected_id, selected_level)
	var deltas := ShipCatalog.stat_deltas(current_id,current_level,selected_id,selected_level)

	var heading := _label(details_root, str(profile.display_name).to_upper())
	heading.add_theme_font_size_override("font_size", roundi(18 * NauticalTheme.density_scale()))
	_label(details_root, str(profile.role))
	_add_stat(details_root,"Rumpf",float(profile.hull),float(deltas.hull),1350.0,0)
	_add_stat(details_root,"Schaden",float(profile.damage),float(deltas.damage),120.0,0)
	_add_stat(details_root,"Speed",float(profile.speed),float(deltas.speed),10.0,2)
	_add_stat(details_root,"Armor",float(profile.armor)*100.0,float(deltas.armor)*100.0,50.0,1)
	_add_stat(details_root,"Turn",float(profile.turn_speed),float(deltas.turn_speed),90.0,0)

	var level := roster.mastery_level(selected_id) if roster.owns_ship(selected_id) else 1
	var xp := roster.mastery_xp(selected_id) if roster.owns_ship(selected_id) else 0
	var need := ShipMasteryCatalog.xp_to_next(level)
	_label(details_root,"MASTERY %d/%d · %s" % [level,ShipMasteryCatalog.max_level(),"MAX" if level>=ShipMasteryCatalog.max_level() else "%d/%d XP" % [xp,need]])
	var mastery_bar := ProgressBar.new()
	mastery_bar.max_value = 1.0
	mastery_bar.value = roster.mastery_progress(selected_id) if roster.owns_ship(selected_id) else 0.0
	mastery_bar.show_percentage = false
	mastery_bar.custom_minimum_size.y = 18 * NauticalTheme.density_scale()
	details_root.add_child(mastery_bar)

	var diagnostic := ShipCardPipeline.diagnostic(selected_id)
	var model_text := "FINAL GLB" if bool(diagnostic.model_override) else "PLACEHOLDER/FALLBACK"
	var card_text := "FINAL CARD" if bool(diagnostic.card_override) else "GENERIC CARD"
	_label(details_root,"ASSET STATUS · Model: %s · Card: %s" % [model_text,card_text])
	_label(details_root,"Slots · %s · %s" % [str(diagnostic.model_slot),str(diagnostic.card_slot)])

	if selected_id == current_id:
		_build_m207_equipment_summary(details_root,player)
	else:
		_label(details_root,"AUSRÜSTUNGSANSICHT · Schiff auswählen/ausrüsten, um den aktiven Deck-, Waffen- und Modulstand zu sehen.")

	milestone_box = VBoxContainer.new()
	details_root.add_child(milestone_box)
	_label(milestone_box,"MEILENSTEINE")
	for milestone_level in range(2,ShipMasteryCatalog.max_level()+1):
		var presentation := MasteryRewardHooks.presentation_for(milestone_level)
		var reached := level >= milestone_level
		var row := HBoxContainer.new()
		milestone_box.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(34,34) * NauticalTheme.density_scale()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = VisualAssetCatalog.texture(str(presentation.badge_slot))
		row.add_child(icon)
		var row_text := "%s · %s" % [str(presentation.label), "ERREICHT" if reached else "OFFEN"]
		_label(row,row_text)
		if reached and not bool(presentation.reward_bound):
			_label(milestone_box,str(presentation.reward_text))

	if roster.owns_ship(selected_id) and roster.selected_ship_id != selected_id:
		_button(details_root,"Im Hafen ausrüsten",func(): _equip(roster))
	elif not roster.owns_ship(selected_id):
		var definition := MainProgressionFleet.design(selected_id)
		if not definition.is_empty():
			var req := int(definition.get("unlock",{}).get("map_level",999))
			_label(details_root,("Eligible · noch durch vorgesehenen Kampf-/Progressions-Meilenstein erspielen." if voyage.map_level() >= req else "Eligibility ab Kartenlevel %d · aktuell %d" % [req,voyage.map_level()]))

func _add_stat(parent: Control, label_text: String, value: float, delta: float, max_value: float, decimals: int) -> void:
	var row := VBoxContainer.new()
	parent.add_child(row)
	var head := HBoxContainer.new()
	row.add_child(head)
	var label := _label(head,label_text)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	_label(head,("%.*f" % [decimals,value]) + "  " + _delta(delta,decimals))
	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.value = clampf(value,0.0,max_value)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14 * NauticalTheme.density_scale()
	row.add_child(bar)

func _equip(roster: PlayerShipRoster) -> void:
	var ok := roster.equip_owned_ship(selected_id)
	if hud != null: hud.note("Schiff ausgerüstet" if ok else "Schiff nicht verfügbar oder aktuell nicht wechselbar")
	_refresh_details()

func _ship_ids() -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	for p in ShipCatalog.SHIPS:
		var id:=str(p.id)
		if id.is_empty() or seen.has(id):continue
		seen[id]=true;result.append(id)
	for d in MainProgressionFleet.data().get("designs",[]):
		var id:=str(d.id)
		if id.is_empty() or seen.has(id):continue
		seen[id]=true;result.append(id)
	return result

func _state_text(id: String) -> String:
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return ""
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	if roster.selected_ship_id == id: return "AKTIV"
	if roster.owns_ship(id): return "BESITZ"
	var definition := MainProgressionFleet.design(id)
	if definition.is_empty(): return "STARTER"
	var req := int(definition.get("unlock",{}).get("map_level",999))
	var voyage := player.get_node("Voyage") as VoyageProgress
	return ("ELIGIBLE" if voyage.map_level() >= req else "KL %d" % req)

func _delta(value: float, decimals: int) -> String:
	if absf(value) < pow(10.0,-maxi(0,decimals))*0.5: return "±0"
	var fmt := "%+.0f" if decimals == 0 else ("%+.1f" if decimals == 1 else "%+.2f")
	return fmt % value

func _label(parent: Control, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 56 * NauticalTheme.density_scale()
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _build_m207_equipment_summary(parent:Control,player:ShipMotor)->void:
	var progression:=player.get_node_or_null("Progression") as PlayerProgression
	var inventory:=player.get_node_or_null("Inventory") as PlayerInventory
	if progression==null or inventory==null:return
	_label(parent,"AKTIVE SCHIFFSAUSRÜSTUNG · VISUELLE STUFEN")
	var grid:=GridContainer.new();grid.columns=2 if size.x<620*NauticalTheme.density_scale() else 5;parent.add_child(grid)
	var rows:=[
		{"kind":"hull_armor","label":"Rumpf","level":int(progression.upgrades.get("hull",0))},
		{"kind":"cannon_battery","label":"Kanonen","level":int(progression.upgrades.get("cannon",0))},
		{"kind":"sails","label":"Segel","level":int(progression.upgrades.get("sails",0))},
		{"kind":"harpoon_mount","label":"Harpune","level":maxi(1,inventory.special_deck_level(inventory.equipped_special_deck())) if not inventory.selected_harpoon().is_empty() else 0},
		{"kind":"ram","label":"Bugramme","level":int(progression.upgrades.get("hull",0)) if int(progression.upgrades.get("hull",0))>=7 else 0}
	]
	for row in rows:
		var card:=VBoxContainer.new();card.custom_minimum_size=Vector2(92,86)*NauticalTheme.density_scale();grid.add_child(card)
		var icon:=TextureRect.new();icon.custom_minimum_size=Vector2(48,48)*NauticalTheme.density_scale();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture=VisualAssetCatalog.texture(M207ShipEquipmentStageCatalog.icon_slot(str(row.kind),int(row.level)));card.add_child(icon)
		var label:=Label.new();label.text="%s · %s"%[str(row.label),M207ShipEquipmentStageCatalog.stage_label(int(row.level))];label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;card.add_child(label)
	_label(parent,"DECKS UNTER DEM SCHIFF · sichtbarer Ausbau")
	var deck_row:=HBoxContainer.new();deck_row.size_flags_horizontal=SIZE_EXPAND_FILL;parent.add_child(deck_row)
	var normal_icon:=TextureRect.new();normal_icon.custom_minimum_size=Vector2(48,48)*NauticalTheme.density_scale();normal_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;normal_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;normal_icon.texture=VisualAssetCatalog.texture(M210InterfaceAssetRuntimeCatalog.deck_slot(inventory.deck_level()));deck_row.add_child(normal_icon)
	var special_id:=inventory.equipped_special_deck()
	var stack_text:="Deck %d/10 · Normale Decks als Stapel direkt unter dem Rumpf"%inventory.deck_level()
	if not special_id.is_empty():
		var special_icon:=TextureRect.new();special_icon.custom_minimum_size=Vector2(48,48)*NauticalTheme.density_scale();special_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;special_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;special_icon.texture=VisualAssetCatalog.texture(M210InterfaceAssetRuntimeCatalog.special_deck_slot(special_id));deck_row.add_child(special_icon)
		stack_text += " · Spezialdeck darunter: "+special_id.replace("_"," ").capitalize()
	_label(parent,stack_text)
	_label(parent,"Harpune · %s"%inventory.selected_harpoon().replace("_"," ").capitalize())

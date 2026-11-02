class_name ArsenalPanel
extends Control
## M204 compatibility resolver: M204InventoryPresentationCatalog.icon_slot(item) now wrapped by M210.
## Native controls provide scrolling, focus and touch-sized hit targets.

var player: ShipMotor
var inventory: PlayerInventory
var progression: PlayerProgression
var weapons: ShipWeapons
var opener: Button
var shade: ColorRect
var panel: PanelContainer
var summary: Label
var rows: Dictionary = {}
var cannon_button: Button
var deck_button: Button
var save_a_button: Button
var save_b_button: Button
var close_button: Button
var powder_button: Button
var plates_button: Button
var craft_buttons: Dictionary = {}
var _refresh_elapsed := 0.0


func _ready() -> void:
	theme = NauticalTheme.create()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("arsenal_ui")
	inventory = player.get_node("Inventory") as PlayerInventory
	progression = player.get_node("Progression") as PlayerProgression
	weapons = player.get_node("Weapons") as ShipWeapons
	opener = _button("ARSENAL", toggle)
	opener.tooltip_text = "Munition, Items, Vorräte und Schiffsausrüstung"
	opener.add_theme_stylebox_override("normal", NauticalHud.box_style())
	opener.add_theme_color_override("font_color", NauticalHud.LIGHT)
	opener.add_theme_font_size_override("font_size", roundi(11 * NauticalTheme.density_scale()))
	add_child(opener)
	shade = ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	shade.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	close_button = _button("ARSENAL — CLOSE [I / ESC]", toggle)
	column.add_child(close_button)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 10)
	scroll.add_child(items)
	# M171: build rows from inventory + runtime combat/action catalogs + effective offers.
	var arsenal_ids: Array[String] = []
	for raw_stock_id in PlayerInventory.START_STOCK.keys():
		var stock_id := str(raw_stock_id)
		if stock_id not in arsenal_ids: arsenal_ids.append(stock_id)
	for ammo_id in CombatCatalog.ammo_ids():
		if ammo_id not in arsenal_ids: arsenal_ids.append(ammo_id)
	for action_id in ActionItemCatalog.item_ids():
		if action_id not in arsenal_ids: arsenal_ids.append(action_id)
	for raw_offer_id in inventory.effective_offers().keys():
		var offer_id := str(raw_offer_id)
		if offer_id not in arsenal_ids: arsenal_ids.append(offer_id)
	arsenal_ids.sort_custom(func(a:String,b:String):
		var ca:=M204InventoryPresentationCatalog.category(a)
		var cb:=M204InventoryPresentationCatalog.category(b)
		var oa:=M208UnifiedInterfaceCatalog.category_order(ca)
		var ob:=M208UnifiedInterfaceCatalog.category_order(cb)
		return a < b if oa == ob else oa < ob)
	var previous_category := ""
	for arsenal_id in arsenal_ids:
		var category := M204InventoryPresentationCatalog.category(arsenal_id)
		if category != previous_category:
			_add_category_header(items, category)
			previous_category = category
		_add_item(items, arsenal_id)
	powder_button = _button("", _toggle_supply.bind("powder")); _set_item_icon(powder_button, "powder"); items.add_child(powder_button)
	plates_button = _button("", _toggle_supply.bind("plates")); _set_item_icon(plates_button, "plates"); items.add_child(plates_button)
	for recipe_id in ["repair_supply", "powder_supply", "plate_supply"]:
		var craft_button := _button("", _craft.bind(recipe_id)); items.add_child(craft_button); craft_buttons[recipe_id] = craft_button
	cannon_button = _button("", _buy_cannon)
	_set_equipment_icon(cannon_button, "cannon")
	items.add_child(cannon_button)
	deck_button = _button("", _buy_deck)
	_set_equipment_icon(deck_button, "deck")
	items.add_child(deck_button)
	save_a_button = _button("AKTUELLES KAMPFSET ALS LOADOUT A SPEICHERN", _save_loadout.bind("A"))
	items.add_child(save_a_button)
	save_b_button = _button("AKTUELLES KAMPFSET ALS LOADOUT B SPEICHERN", _save_loadout.bind("B"))
	items.add_child(save_b_button)
	var note := Label.new()
	note.text = "M171: Arsenal uses runtime item/ammo names and effective offers; touch/scroll behavior remains mobile-safe.\nPowder is consumed only by a valid cannon salvo; plates only by valid incoming damage."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items.add_child(note)
	shade.hide()
	resized.connect(_layout)
	_layout()
	_refresh()


func _button(title: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.clip_text = true
	result.custom_minimum_size.y = 52 * NauticalTheme.density_scale()
	result.pressed.connect(action)
	return result


func _set_item_icon(button: Button, id: String) -> void:
	var texture := VisualAssetCatalog.texture(ItemUiIconCatalog.slot(id))
	if texture != null:
		button.icon = texture
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)

func _set_equipment_icon(button: Button, id: String) -> void:
	var slot := M205CannonPresentationCatalog.cannon_icon_slot(CombatCatalog.cannon(weapons.cannon_index).get("id", "naval_cannon")) if id == "cannon" else M206DeckEquipmentPresentationCatalog.normal_deck_icon_slot(maxi(inventory.deck_level(),1)) if id == "deck" else id
	var texture := VisualAssetCatalog.texture(slot)
	if texture != null:
		button.icon = texture
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40)



func _add_category_header(items: VBoxContainer, category: String) -> void:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	items.add_child(header)
	var title := Label.new()
	title.text = category
	title.add_theme_font_size_override("font_size", roundi(13 * NauticalTheme.density_scale()))
	title.add_theme_color_override("font_color", NauticalHud.GOLD)
	header.add_child(title)
	var hint := Label.new()
	hint.text = M208UnifiedInterfaceCatalog.category_hint(category)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", roundi(10 * NauticalTheme.density_scale()))
	hint.add_theme_color_override("font_color", NauticalHud.TEXT.darkened(0.15))
	header.add_child(hint)

func _add_item(items: VBoxContainer, item: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", NauticalTheme.graphic_style("card"))
	items.add_child(card)
	var box := VBoxContainer.new()
	card.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var texture := VisualAssetCatalog.texture(M210InterfaceAssetRuntimeCatalog.item_slot(item))
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(56, 48) * NauticalTheme.density_scale()
		row.add_child(icon)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var category := Label.new()
	category.text = M204InventoryPresentationCatalog.category(item)
	category.add_theme_font_size_override("font_size", roundi(10 * NauticalTheme.density_scale()))
	category.add_theme_color_override("font_color", NauticalHud.GOLD)
	text_column.add_child(category)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(title)
	var select: Button
	if CombatCatalog.ammo_index_by_id(item) >= 0 or item == "harpoon":
		select = _button("AUSRÜSTEN", _select_ammo.bind(item))
		select.custom_minimum_size.x = 90 * NauticalTheme.density_scale()
		row.add_child(select)
	var buy: Button = null
	if inventory.effective_offers().has(item):
		buy = _button("", _buy.bind(item))
		box.add_child(buy)
	rows[item] = {"title": title, "buy": buy, "select": select}


func _layout() -> void:
	if not is_instance_valid(panel):
		return
	var safe := _safe_rect()
	var opener_rect: Rect2 = NauticalLayout.calculate(safe).actions.arsenal
	opener.position = opener_rect.position
	opener.size = opener_rect.size
	panel.add_theme_stylebox_override("panel", NauticalHud.box_style())
	var sx := NauticalTheme.density_scale()
	panel.size = Vector2(minf(620 * sx, safe.size.x - 24 * sx), maxf(120, safe.size.y - 24 * sx))
	panel.position = safe.get_center() - panel.size * 0.5


func _safe_rect() -> Rect2:
	var visible_rect := get_viewport_rect()
	if OS.has_feature("android") or OS.has_feature("ios"):
		var usable := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if usable.size.x > 0 and screen.x > 0 and screen.y > 0:
			var factor := visible_rect.size / Vector2(screen)
			return Rect2(Vector2(usable.position) * factor, Vector2(usable.size) * factor)
	return visible_rect


func _input(event: InputEvent) -> void:
	if player.get_meta("journal_open", false) or player.get_meta("command_open", false) or player.get_meta("settings_open", false):
		return
	if event.is_action_pressed("inventory_toggle") or (shade.visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	opener.visible = not shade.visible and not player.get_meta("journal_open", false) and not player.get_meta("command_open", false) and not player.get_meta("settings_open", false)
	_refresh_elapsed += delta
	if shade.visible and _refresh_elapsed >= 0.2:
		_refresh_elapsed = 0.0
		_refresh()


func toggle() -> void:
	if player.get_meta("journal_open", false) or player.get_meta("command_open", false) or player.get_meta("settings_open", false):
		return
	shade.visible = not shade.visible
	player.set_meta("inventory_open", shade.visible)
	opener.visible = not shade.visible
	if shade.visible:
		progression.shop_open = false
		for hud in get_tree().get_nodes_in_group("hud"):
			hud.global_map_open = false
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()
		close_button.grab_focus()
	else:
		opener.release_focus()
		close_button.release_focus()
	_refresh()


func _refresh() -> void:
	var port := inventory.at_port()
	var location := "HARBOR — SUPPLIES AVAILABLE" if port else "AT SEA — BUY AT HARBOR"
	var cannon:=CombatCatalog.cannon(weapons.cannon_index)
	var role:=CombatCatalog.cannon_role_profile(cannon)
	var tier:=CombatCatalog.cannon_upgrade_tier(int(progression.upgrades.get("cannon",0)))
	var preferred:=CombatCatalog.preferred_ammo_ids(cannon)
	summary.text = "%s | %d coins\nCannons: %d owned / %d capacity / %d per broadside\n%s · %s · M158 Runtime Tier %d %s\nStärke: %s · Tradeoff: %s\nEmpfohlene Munition: %s" % [
		location, progression.coins, inventory.owned_cannons,
		inventory.cannon_capacity(), inventory.volley_size(),str(cannon.get("name","Cannon")),str(cannon.get("role","balanced")).to_upper(),int(tier.get("tier",1)),str(tier.get("label","")),str(role.get("strength","flexible")),str(role.get("tradeoff","none")),", ".join(preferred)]
	var effective_offers := inventory.effective_offers()
	for item in rows:
		var row: Dictionary = rows[item]
		var item_name: String = item.replace("_", " ").capitalize()
		var ammo_idx := CombatCatalog.ammo_index_by_id(item)
		if ammo_idx >= 0: item_name = str(CombatCatalog.ammo(ammo_idx).get("name", item_name))
		else:
			var action_def := ActionItemCatalog.item(item)
			if not action_def.is_empty(): item_name = str(action_def.get("name", item_name))
		row.title.text = "%s × %d" % [item_name, inventory.count(item)]
		if row.buy != null:
			var offer: Dictionary = effective_offers.get(item, {}) as Dictionary
			row.buy.visible = not offer.is_empty()
			if not offer.is_empty():
				row.buy.text = "Buy %d — %d coins" % [int(offer.get("amount", 0)), int(offer.get("price", 0))]
				row.buy.disabled = not port or progression.coins < int(offer.get("price", 0)) or inventory.count(item) + int(offer.get("amount", 0)) > inventory.max_stock_for(item)
		if row.select != null:
			row.select.text = "Selected" if weapons.ammo_id() == item else "Select"
	_set_equipment_icon(cannon_button, "cannon")
	_set_equipment_icon(deck_button, "deck")
	cannon_button.text = "Buy cannon — %d coins (%d/%d owned)" % [inventory.cannon_purchase_price(), inventory.owned_cannons, inventory.cannon_purchase_cap()]
	cannon_button.disabled = not port or inventory.owned_cannons >= inventory.cannon_purchase_cap() or progression.coins < inventory.cannon_purchase_price()
	deck_button.text = "Upgrade this ship's deck — %d coins (%d/%d)" % [inventory.deck_price(), inventory.deck_level(), inventory.max_deck_level()]
	deck_button.disabled = not port or inventory.deck_level() >= inventory.max_deck_level() or progression.coins < inventory.deck_price()
	save_a_button.text = "Save Loadout A — %s" % inventory.loadout_summary("A")
	save_b_button.text = "Save Loadout B — %s" % inventory.loadout_summary("B")
	powder_button.text = "Black Powder: %s — %d stock" % ["ON" if inventory.powder_enabled else "OFF", inventory.count("powder")]
	plates_button.text = "Armor Plates: %s — %d stock" % ["ON" if inventory.plates_enabled else "OFF", inventory.count("plates")]
	for recipe_id in craft_buttons:
		var recipe := EquipmentEconomyContracts.recipe(recipe_id)
		craft_buttons[recipe_id].text = "Craft %s — %d Gold" % [recipe_id.replace("_", " ").capitalize(), int(recipe.get("gold", 0))]
		craft_buttons[recipe_id].disabled = not port


func _select_ammo(item: String) -> void:
	if item == "harpoon":
		weapons.select_mode("harpoon")
		_refresh()
		return
	weapons.select_mode("cannon")
	weapons.ammo_index = CombatCatalog.ammo_index_by_id(item)
	weapons.loadout_changed.emit()
	_refresh()


func _buy(item: String) -> void:
	inventory.purchase(item)
	_refresh()


func _buy_cannon() -> void:
	inventory.purchase_cannon()
	_refresh()


func _buy_deck() -> void:
	inventory.purchase_deck()
	_refresh()


func _save_loadout(slot: String) -> void:
	inventory.save_loadout(slot, weapons)
	_refresh()


func _toggle_supply(id: String) -> void:
	inventory.toggle_supply(id)
	_refresh()

func _craft(recipe_id: String) -> void:
	if not inventory.craft(recipe_id):
		player.set_meta("dock_message", "CRAFTING REQUIREMENTS NOT MET")
		player.set_meta("dock_message_until", Time.get_ticks_msec() / 1000.0 + 2.0)
	_refresh()

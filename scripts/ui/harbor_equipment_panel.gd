class_name HarborEquipmentPanel
extends Control
## M50 dedicated PL6-15 equipment/harbor UI. Uses stable gameplay data; no live backend claims.

var hud: GameHud
var panel: PanelContainer
var body: VBoxContainer
var tab := "modules"

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	resized.connect(_on_resized)
	theme = NauticalTheme.create()
	mouse_filter = MOUSE_FILTER_STOP
	hide()

func _on_resized()->void:
	if visible: call_deferred("_rebuild")

func open(owner_hud: GameHud, initial_tab := "modules") -> void:
	hud = owner_hud
	tab = initial_tab
	_rebuild()
	show()

func close() -> void:
	hide()
	if hud != null: hud.complete_routed_panel(self)
	queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.04, 0.92)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", NauticalHud.box_style())
	add_child(panel)
	var edge := 8 if size.x < 700 * NauticalTheme.density_scale() else 18
	panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, edge)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side, 8 if size.x < 700 * NauticalTheme.density_scale() else 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "AUSRÜSTUNGSZENTRUM · GLOBAL + LOKALE DIENSTE"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_add_button(header, "Schließen", close)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	column.add_child(tabs)
	var tab_labels := {"modules":"MODULE","services":"MARKT","specialization":"BUILD","abyss":"ABYSS","ancient":"ANCIENT","trials":"PRÜFUNG","bonusmaps":"BONUS","production":"ASSETS"}
	for id in ["modules","services","specialization","abyss","ancient","trials","bonusmaps","production"]:
		var label = str(tab_labels.get(id,id.to_upper())) if size.x < 700 * NauticalTheme.density_scale() else id.to_upper()
		_add_button(tabs, label, func(value=id): tab=value; _rebuild())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	_build_content()

func _build_content() -> void:
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var inventory := player.get_node("Inventory") as PlayerInventory
	var region := inventory.current_region_id()
	var harbor := RegionalHarborEconomy.harbor(region) if not region.is_empty() else {}
	if not region.is_empty():
		_add_label("%s · %s" % [str(harbor.get("service_label", region)), str(harbor.get("specialty",""))])
	elif tab in ["modules","services"]:
		_add_label("Regionaler Markt an diesem Hafen noch nicht konfiguriert.")
	match tab:
		"modules":
			if not region.is_empty():_build_modules(inventory, region)
		"services":
			if not region.is_empty():_build_services(inventory, harbor)
		"specialization": _build_specialization(player,inventory)
		"abyss": _build_abyss(player,inventory)
		"ancient": _build_ancient(player,inventory)
		"trials": _build_trials(player,inventory)
		"bonusmaps": _build_bonusmaps(player,inventory)
		"production": _build_production(inventory)

func _build_trials(player:ShipMotor,inventory:PlayerInventory)->void:
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	var runtime:=player.get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if voyage==null or runtime==null:return
	_add_label("PIRATENPRÜFUNGEN · SPIELBARE STUFEN")
	_add_label(runtime.summary())
	var level:=voyage.map_level()
	if level in [40,45,50,55,60] and runtime.active_level==0:
		_add_button(body,"Prüfung %d starten"%level,func():_result(runtime.start(level,inventory)))
	elif runtime.active_level>0:
		_add_label("Aktiv: PL%d · Fortschritt bleibt im Save erhalten."%runtime.active_level)
		if runtime.complete(runtime.active_level) and inventory.at_port():
			_add_button(body,"Prüfung %d abgeben"%runtime.active_level,func():_result(_claim_runtime_trial(voyage,runtime.active_level)))

func _claim_runtime_trial(voyage:VoyageProgress,level:int)->bool:
	match level:
		40:return voyage.claim_post_beginner_trial40()
		45:return voyage.claim_post_beginner_trial45()
		50:return voyage.claim_post_beginner_trial50()
		55:return voyage.claim_post_beginner_trial55()
		60:return voyage.claim_post_beginner_trial60()
	return false

func _build_modules(inventory: PlayerInventory, region: String) -> void:
	_add_label("AUSGERÜSTET · " + inventory.module_summary())
	for id in RegionalEquipmentCatalog.ids_for_region(region):
		var d := RegionalEquipmentCatalog.module(id)
		var owned := inventory.owned_modules.has(id)
		_add_label("%s · T%d · %s" % [d.get("label",id), int(d.get("tier",1)), str(d.get("slot","")).to_upper()])
		_add_label(_effect_text(d.get("effects", {})))
		if owned:
			_add_button(body, "Ausrüsten", func(mid=id): _result(inventory.equip_module(mid)))
		else:
			var cost: Dictionary = d.get("cost",{})
			_add_label("Kosten: %d Gold · %s" % [int(cost.get("gold",0)), _materials_text(cost.get("materials",{}))])
			_add_button(body, "Bauen", func(mid=id): _result(inventory.build_regional_module(mid)))

func _build_services(inventory: PlayerInventory, harbor: Dictionary) -> void:
	_add_label("REGIONALER MARKT")
	for id in harbor.get("purchase_offers", {}):
		var offer: Dictionary = harbor.purchase_offers[id]
		_add_button(body, "%s ×%d · %d Gold" % [str(id).replace("_"," ").capitalize(), int(offer.get("amount",0)), int(offer.get("price",0))], func(item=id): _result(inventory.purchase_regional(str(item))))
	_add_label("MATERIALIEN · Stormglass %d · Ember %d · Veil %d · Timber %d · Gears %d" % [inventory.count("stormglass"), inventory.count("ember_ore"), inventory.count("veil_silk"), inventory.count("reinforced_timber"), inventory.count("precision_gears")])

func _build_specialization(player:ShipMotor,inventory:PlayerInventory)->void:
	var voyage:=player.get_node("Voyage") as VoyageProgress
	var spec:=player.get_node_or_null("BuildSpecialization") as BuildSpecialization
	if spec==null:return
	_add_label("BUILD-SPEZIALISIERUNG · ab Kartenlevel 21")
	_add_label("Aktiv: "+spec.summary())
	if voyage.map_level()<21:_add_label("Noch gesperrt.");return
	for id in spec.ids():
		var d:=spec.profile(id)
		_add_label("%s · %s · Trade-off: %s"%[str(d.get("label",id)),str(d.get("focus","")),str(d.get("tradeoff",""))])
		_add_button(body,"Wählen · "+str(d.get("label",id)),func(bid=id):_result(spec.select(bid,voyage.map_level(),inventory)))

func _start_bonusmap(player:ShipMotor,kind:String,progress:Node,map_level:int,inventory:PlayerInventory)->void:
	var entered:=false
	if kind=="gold":entered=(progress as GoldBonusMapProgress).enter(map_level,inventory)
	elif kind=="abyss":entered=(progress as AbyssBonusMapProgress).enter(map_level,inventory)
	else:entered=(progress as ExtendedBonusMapProgress).enter(map_level,inventory)
	if not entered:_result(false);return
	var world:=get_tree().get_first_node_in_group("world_map") as WorldMapSystem
	if world==null or not world.enter_bonusmap_instance(kind):
		if kind=="gold":(progress as GoldBonusMapProgress).rollback_entry(inventory)
		elif kind=="abyss":(progress as AbyssBonusMapProgress).rollback_entry(inventory)
		else:(progress as ExtendedBonusMapProgress).rollback_entry(inventory)
		_result(false);return
	if kind=="gold":(progress as GoldBonusMapProgress).commit_entry()
	elif kind=="abyss":(progress as AbyssBonusMapProgress).commit_entry()
	else:(progress as ExtendedBonusMapProgress).commit_entry()
	_result(true)

func _build_abyss(player:ShipMotor,inventory:PlayerInventory)->void:
	var voyage:=player.get_node("Voyage") as VoyageProgress
	var corruption:=player.get_node_or_null("AbyssCorruption") as AbyssCorruption
	_add_label("ABYSS · ab Kartenlevel 26 · freiwilliges Risk/Reward")
	if voyage.map_level()<26:_add_label("Noch gesperrt.");return
	if corruption!=null:
		_add_label(corruption.summary())
		_add_label("Corruption ist niemals heimlich Pflicht: bewusst behalten für Reward-Multiplikator oder im Hafen vollständig reinigen.")
		_add_button(body,"Corruption bewusst behalten",func():_result(corruption.set_retained(true,voyage.map_level())))
		_add_button(body,"Corruption reinigen / deaktivieren",func():_result(corruption.cleanse(inventory)))
	_add_label("Abyss-Schuppen: %d · Abyss-Fragmente: %d · Corrupted Pearls: %d"%[inventory.count("abyss_scale"),inventory.count("abyss_chart_fragment"),inventory.count("corrupted_pearl")])
	var abyss_map:=player.get_node_or_null("AbyssBonusMapProgress") as AbyssBonusMapProgress
	if abyss_map!=null:
		_add_label(abyss_map.status_text())
		if not abyss_map.active:
			_add_button(body,"Abyss-Bonusmap starten · %d %s"%[abyss_map.entry_cost(),abyss_map.entry_item().replace("_"," ").capitalize()],func():_start_bonusmap(player,"abyss",abyss_map,voyage.map_level(),inventory))
	_add_label("Abyssal Harpoons: Abyssal Spike · Rift Piercer · Leviathan Chain")
	_add_label("Corruption Gear / Advanced Castles: stabile Equipment-Hooks vorbereitet; finale Balance/Items folgen.")

func _build_ancient(player:ShipMotor,inventory:PlayerInventory)->void:
	var voyage:=player.get_node("Voyage") as VoyageProgress
	_add_label("ANCIENT GUARDIANS · PL31–35")
	if voyage.map_level()<31:_add_label("Noch gesperrt.");return
	_add_label("Guardian-Fragmente: %d · Legendary-Fragmente: %d · Relic Cores: %d"%[inventory.count("ancient_guardian_fragment"),inventory.count("legendary_fragment"),inventory.count("ancient_relic_core")])
	_add_label("Ancient Guardian: Relic Barrier · Titan Spawn: Pressure Pulse · passende Abyss-Harpunen empfohlen.")
	var forge:=player.get_node_or_null("LegendaryFragmentForge") as LegendaryFragmentForge
	if forge!=null:_add_button(body,"5 Legendary-Fragmente → Ancient Relic Core",func():_result(forge.craft(inventory)))
	var prep:=player.get_node_or_null("WorldBossPrep") as WorldBossPrep
	if prep!=null:prep.refresh_inventory(inventory);_add_label("WORLD BOSS PREP · "+prep.summary())
	var ancient:=player.get_node_or_null("AncientEquipment") as AncientEquipment
	if ancient!=null:
		for row in ancient.data().get("items",[]):
			var id:=str(row.get("id",""));var label:=str(row.get("label",id))
			if id in ancient.owned:_add_button(body,("✓ " if ancient.equipped==id else "")+label,func(item_id=id):_result(ancient.equip(item_id)))
			else:_add_button(body,label+" · 1 Relic Core",func(item_id=id):_result(ancient.craft(item_id,inventory)))
	if voyage.map_level()==35:_add_label("PL35 · beide Mechaniken + Guardian/Titan/Admiral + Relic Core erforderlich.")

func _build_bonusmaps(player:ShipMotor,inventory:PlayerInventory)->void:
	var voyage:=player.get_node("Voyage") as VoyageProgress
	var gold:=player.get_node_or_null("GoldBonusMapProgress") as GoldBonusMapProgress
	_add_label("BONUSMAPS · optionale Progressionsbeschleuniger")
	_add_label("Silver-Fragmente: %d · Gold-Fragmente: %d · Admiral-Komponenten: %d"%[inventory.count("silver_chart_fragment"),inventory.count("gold_chart_fragment"),inventory.count("admiral_component")])
	var silver:=player.get_node_or_null("SilverBonusMapProgress") as ExtendedBonusMapProgress
	if silver!=null:
		_add_label(silver.status_text())
		if not silver.active:
			var scfg:=silver.config();var slvl:=int(scfg.get("eligibility_level",99));var scost:=int(scfg.get("entry_cost",0));var sitem:=str(scfg.get("entry_item",""))
			if voyage.map_level()>=slvl:_add_button(body,"Silver-Bonusmap starten · %d %s"%[scost,sitem.replace("_"," ").capitalize()],func():_start_bonusmap(player,"silver",silver,voyage.map_level(),inventory))
	if gold!=null:
		_add_label(gold.status_text())
		if not gold.active:
			var gd:=gold.data();var entry:Dictionary=gd.get("entry",{}) as Dictionary;var gcost:=int(entry.get("gold_chart_fragments",12));var glvl:=int(gd.get("eligibility_level",18))
			if voyage.map_level()>=glvl:_add_button(body,"Gold-Bonusmap starten · %d Gold-Fragmente"%gcost,func():_start_bonusmap(player,"gold",gold,voyage.map_level(),inventory))
		elif gold.active:_add_label("Fortschritt läuft über qualifizierte NPC-/Elite-/Admiral-Sinks. Piratenprüfungen werden nicht übersprungen.")
	var legendary:=player.get_node_or_null("LegendaryBonusMapProgress") as ExtendedBonusMapProgress
	if legendary!=null and voyage.map_level()>=36:
		_add_label(legendary.status_text())
		if not legendary.active:
			var lcfg:=legendary.config();var lcost:=int(lcfg.get("entry_cost",0));var litem:=str(lcfg.get("entry_item",""))
			_add_button(body,"Legendary-Bonusmap starten · %d %s"%[lcost,litem.replace("_"," ").capitalize()],func():_start_bonusmap(player,"legendary",legendary,voyage.map_level(),inventory))

func _build_production(inventory: PlayerInventory) -> void:
	var report := ProductionCoverage.report()
	_add_label("PRODUCTION COVERAGE · %d Slots · %d Overrides · %d Fallback/Missing" % [report.total, report.overrides, report.missing])
	_add_label("P0 Missing: %d · P1 Missing: %d · P2 Missing: %d" % [report.p0_missing, report.p1_missing, report.p2_missing])
	_add_label("Finale Assets bleiben austauschbar über stabile Slots; fehlende Overrides blockieren Gameplay nicht.")

func _effect_text(effects: Dictionary) -> String:
	var rows: Array[String] = []
	for key in effects:
		var value := float(effects[key])
		if key.ends_with("_mult"): rows.append("%s %+.0f%%" % [str(key).trim_suffix("_mult").replace("_"," "), (value-1.0)*100.0])
		elif key.ends_with("_add"): rows.append("%s %+.1f%%" % [str(key).trim_suffix("_add").replace("_"," "), value*100.0])
	return " · ".join(rows)

func _materials_text(materials: Dictionary) -> String:
	var rows: Array[String] = []
	for id in materials: rows.append("%s ×%d" % [str(id).replace("_"," ").capitalize(), int(materials[id])])
	return " · ".join(rows)

func _add_label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	return label

func _add_button(parent: Control, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 56 * NauticalTheme.density_scale()
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _result(ok: bool) -> void:
	if hud != null: hud.note("Erfolgreich" if ok else "Voraussetzungen prüfen")
	_rebuild()

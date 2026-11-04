class_name CommandDeck
extends Control
## M202 compatibility vocabulary: SCHNELLZUGRIFF / ALLE BEREICHE.
## Real Controls: release activation, keyboard focus and native touch scrolling.
var hud: GameHud
var panel: PanelContainer
var body: VBoxContainer
var event_status: Label
var title_label: Label
var context_label: Label
var back_button: Button
var picker: OptionButton
var content_scroll: ScrollContainer
var quick_navigation: GridContainer
var active_page := "home"
var page_history: Array[String] = []
var m249_card_reveal_index := 0
var pages := ["home", "progress", "equipment", "bonusmaps", "quests", "events", "shop", "bazaar", "harbor", "social", "guild", "rankings", "achievements", "meta", "log", "systems", "help", "admin"]

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = NauticalTheme.create()
	mouse_filter = MOUSE_FILTER_STOP
	resized.connect(_layout)
	hide()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()

func open_page(page: String) -> void:
	if page not in available_pages(): page = "home"
	active_page = page
	m249_card_reveal_index = 0
	hud.menu_page = page
	event_status = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.04, 0.85)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", NauticalHud.box_style())
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	back_button = _button(header, "‹ ZURÜCK", go_back)
	back_button.custom_minimum_size.x = 104.0 * NauticalTheme.density_scale()
	back_button.disabled = page_history.is_empty() and page == "home"
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(heading)
	title_label = _label_to(heading, hud._menu_title(page).to_upper(), 20, NauticalHud.LIGHT)
	context_label = _label_to(heading, _page_context(page), 12, NauticalHud.TEXT)
	var close_button := _button(header, "SCHLIESSEN ×", hud.close_menu)
	close_button.custom_minimum_size.x = 118.0 * NauticalTheme.density_scale()
	_label_to(column, "SCHNELLZUGRIFF · WICHTIGE BEREICHE", 11, NauticalHud.GOLD)
	quick_navigation = GridContainer.new()
	quick_navigation.name = "CommandDeckQuickNavigation"
	quick_navigation.columns = M202MenuInteractionPolicy.quick_columns(hud.layout().safe.size)
	quick_navigation.add_theme_constant_override("h_separation", 6)
	quick_navigation.add_theme_constant_override("v_separation", 6)
	column.add_child(quick_navigation)
	for quick_id in M202MenuInteractionPolicy.primary_pages(available_pages()):
		var quick := _button(quick_navigation, M202MenuInteractionPolicy.quick_label(quick_id), func(id=quick_id): navigate(id))
		_set_menu_icon(quick, quick_id)
		quick.disabled = quick_id == page
		quick.tooltip_text = _page_context(quick_id)
	_label_to(column, "BEREICH WECHSELN", 11, NauticalHud.GOLD)
	picker = OptionButton.new()
	picker.name = "CommandDeckDestinationPicker"
	picker.custom_minimum_size.y = _touch_height()
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	var visible_pages := available_pages()
	for id in visible_pages: picker.add_item(hud._menu_title(id))
	picker.select(maxi(0, visible_pages.find(page)))
	picker.item_selected.connect(func(index): navigate(visible_pages[index]), CONNECT_DEFERRED)
	column.add_child(picker)
	var navigation_hint := _label_to(column, M210InterfaceAssetRuntimeCatalog.combat_kind_label("mode") + " · Menüs schließen jederzeit mit Zurück/Esc; die Seekarte bleibt Hauptspiel.", 10, NauticalHud.TEXT.darkened(0.18))
	navigation_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_scroll = ScrollContainer.new()
	content_scroll.name = "ContentScroll"
	content_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_scroll.scroll_deadzone = 18
	column.add_child(content_scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	content_scroll.add_child(body)
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	var missions := player.get_node("Missions") as MissionSystem
	var inventory := player.get_node("Inventory") as PlayerInventory
	var weapons := player.get_node("Weapons") as ShipWeapons
	var voyage := player.get_node("Voyage") as VoyageProgress
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var progression := player.get_node("Progression") as PlayerProgression
	var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	if page in ["progress", "equipment", "bonusmaps", "quests", "events", "shop"]:
		_status_card(M185MenuStatusCatalog.context(player))
	match page:
		"home":
			_label("KOMMANDODECK")
			_label("Die Seekarte bleibt das Hauptspiel. Öffne nur den Bereich, den du jetzt brauchst; Zurück führt immer eine Ebene hoch.")
			_status_card(M185MenuStatusCatalog.context(player))
			_status_card(tracking.status_card() if tracking != null else {"title":"ZIEL-TRACKING", "state":"NICHT VERFÜGBAR", "detail":"Tracking-Runtime fehlt.", "tone":"locked"}, true)
			var flow := get_tree().get_first_node_in_group("entry_flow") as EntryFlow
			_section("AUF SEE")
			for id in ["progress", "quests", "bonusmaps", "events"]:
				_destination_button(id)
			_section("SCHIFF & AUSRÜSTUNG")
			for id in ["equipment", "shop", "bazaar"]:
				_destination_button(id)
			_section("WELT & HAFEN")
			_destination_button("harbor")
			_section("KAPITÄN & GEMEINSCHAFT")
			for id in ["social", "guild", "rankings", "achievements", "meta", "log"]:
				_destination_button(id)
			_button(body, "Schiffs-Mastery", func(): _open_mastery("home"))
			_button(body, "Hauptprogression · Track", func(): _open_progression_track("home"))
			_button(body, "Schiffswerft · 3D Preview", func(): _open_shipyard("home", roster.selected_ship_id))
			_section("SYSTEM")
			_destination_button("systems")
			_destination_button("help")
			if "admin" in available_pages(): _destination_button("admin")
			if flow != null:
				_button(body, "Systemeinstellungen", func(): hud.close_menu(); flow.open_sea_settings())
				_button(body, "Speichern & zur Startseite", func(): hud.close_menu(); flow.return_home())
		"bonusmaps":
			_label("BONUSMAPS · INSTANZEN, BOSSE & BELOHNUNGEN")
			_label("Jede Karte zeigt Zugang, Fragmente und Fortschritt vor dem Start. Der Verbrauch wird erst nach erfolgreichem Instanz-Routing bestätigt.")
			var silver:=player.get_node_or_null("SilverBonusMapProgress") as ExtendedBonusMapProgress
			var gold:=player.get_node_or_null("GoldBonusMapProgress") as GoldBonusMapProgress
			var abyss:=player.get_node_or_null("AbyssBonusMapProgress") as AbyssBonusMapProgress
			var legendary:=player.get_node_or_null("LegendaryBonusMapProgress") as ExtendedBonusMapProgress
			_status_card(M185MenuStatusCatalog.bonusmap("silver",silver,voyage.map_level(),inventory), true)
			_status_card(M185MenuStatusCatalog.bonusmap("gold",gold,voyage.map_level(),inventory), true)
			_status_card(M185MenuStatusCatalog.bonusmap("abyss",abyss,voyage.map_level(),inventory), true)
			_status_card(M185MenuStatusCatalog.bonusmap("legendary",legendary,voyage.map_level(),inventory), true)
			_label("BELOHNUNGSVORSCHAU & BOSSPROFILE")
			for bonus_kind in ["silver","gold","abyss","legendary"]:
				_label("%s · %s"%[bonus_kind.capitalize(),M157BonusMapRewardCatalog.completion_summary(bonus_kind)])
				_label("  Boss: "+M158BonusMapBossCatalog.summary(bonus_kind))
			_label("Start/Entry bleibt Hafen-gebunden und verbraucht die jeweilige Kartenwährung erst nach erfolgreichem Instanz-Routing.")
			_section("SPECIAL PVE · ORAKEL / KOMPASS-SYSTEM")
			var special_pve_oracle := player.get_node_or_null("SpecialPveOracle") as M245SpecialPveOracleRuntime
			_status_card(M245SpecialPveOracleCatalog.status_card(special_pve_oracle), true)
			_status_card(M245SpecialPveOracleCatalog.pool_card(special_pve_oracle), true)
			_status_card(M245SpecialPveOracleCatalog.last_reward_card(special_pve_oracle), true)
			_label("SÄULEN · Bonusmaps · Admiral Hunts · World Bosses · Monster Hunts · Treasure Expeditions · Secret Routes · Abyss Rifts · Seasonal PvE")
			_label("Tide Essence bleibt Arbeitsname. Der finale Lore-Name ist laut V3.8 noch nicht festgelegt.")
			_button(body,"Bonusmap-Hafenpanel öffnen",func():
				var screen:=HarborEquipmentPanel.new()
				get_tree().root.add_child(screen)
				hud.route_panel(screen,"bonusmaps")
				screen.open(hud,"bonusmaps"))
		"quests":
			_section("KERN- & STORYAUFTRAG")
			var mission := missions.current_mission()
			_status_card({"title":str(mission.get("title","Aktiver Auftrag")), "state":"AKTIV · %d/%d"%[missions.progress,int(mission.get("target",1))], "detail":missions.presentation_hint()+" · Belohnung %d Gold / %d XP"%[int(mission.get("coins",0)),int(mission.get("xp",0))], "tone":"active", "progress":float(missions.progress)/float(maxi(1,int(mission.get("target",1))))}, true)
			_tracking_controls(tracking, "core", str(mission.get("id", "")), 0)
			_section("REGION")
			var dynamic_quests:=player.get_node_or_null("DynamicQuestRuntime") as DynamicQuestRuntime
			var region_rows:=dynamic_quests.summary() if dynamic_quests!=null else []
			if region_rows.is_empty():
				_status_card({"title":"REGIONALE AUFTRÄGE", "state":"KEINE AKTIVEN", "detail":"Auf dieser Seekarte ist aktuell kein datengetriebener Regionalauftrag aktiv.", "tone":"locked"})
			else:
				for row in region_rows:
					var dynamic_id := str(row.get("id", ""))
					var objectives := DynamicQuestResolver.objectives(get_tree(), dynamic_id)
					if objectives.is_empty():
						_status_card({"title":str(row.get("name",dynamic_id)), "state":"KEIN ZIEL", "detail":"Der veröffentlichte Auftrag enthält kein auflösbares Ziel.", "tone":"warning"})
					else:
						for objective_index in range(objectives.size()):
							var objective: Dictionary = objectives[objective_index] if objectives[objective_index] is Dictionary else {}
							var current := int((row.get("progress", {}) as Dictionary).get(str(objective_index), 0))
							var target := maxi(1, int(objective.get("target", 1)))
							_status_card({"title":str(row.get("name",dynamic_id)), "state":"ABGESCHLOSSEN" if bool(row.get("completed",false)) else "%d/%d"%[current,target], "detail":str(objective.get("label", "Qualifizierte Weltaktion")), "tone":"ready" if bool(row.get("completed",false)) else "active", "progress":float(current)/float(target)}, true)
							if not bool(row.get("completed", false)): _tracking_controls(tracking, "dynamic", dynamic_id, objective_index)
			_section("TÄGLICH & WÖCHENTLICH")
			_label("Reset: täglich 00:00 UTC · wöchentlich Montag 00:00 UTC")
			for kind in MissionSystem.DAILY_GOALS:
				_label("%s: Tag %d/%d · Woche %d/%d" % [kind, missions.daily_progress[kind], MissionSystem.DAILY_GOALS[kind], missions.weekly_progress[kind], MissionSystem.WEEKLY_GOALS[kind]])
			_requirement_button(body, "Tagesziel-Belohnung abholen", {"ok":missions.daily_complete() and not missions.daily_claimed,"label":"BEREIT" if missions.daily_complete() and not missions.daily_claimed else ("ABGEHOLT" if missions.daily_claimed else "ZIELE OFFEN")}, func(): _claim(missions.claim_daily()))
			_requirement_button(body, "Wochenziel-Belohnung abholen", {"ok":missions.weekly_complete() and not missions.weekly_claimed,"label":"BEREIT" if missions.weekly_complete() and not missions.weekly_claimed else ("ABGEHOLT" if missions.weekly_claimed else "ZIELE OFFEN")}, func(): _claim(missions.claim_weekly()))
			_section("JÄGER, GILDE & EVENT")
			_status_card({"title":"JÄGERAUFTRÄGE", "state":"KEIN VERTRAG", "detail":"Monsterziele erscheinen hier, sobald ein Hunter-Vertrag aktiv ist.", "tone":"locked"})
			_status_card({"title":"GILDENAUFTRÄGE", "state":"SERVER ERFORDERLICH", "detail":"Keine lokalen Gildenbelohnungen oder erfundenen Online-Fortschritte.", "tone":"locked"})
			var quest_event:=get_tree().get_first_node_in_group("event_runtime") as EventRuntime
			_status_card({"title":"EVENTAUFTRÄGE", "state":"AKTIV" if quest_event!=null and quest_event.is_active() else "KEIN EVENT", "detail":quest_event.title() if quest_event!=null and quest_event.is_active() else "Derzeit ist kein saisonaler Auftrag aktiv.", "tone":"active" if quest_event!=null and quest_event.is_active() else "locked"})
			if quest_event != null and quest_event.is_active():
				for event_quest in quest_event.relevant_quests(3):
					var event_quest_id := str(event_quest.get("id", ""))
					_label("%s · %s" % [str(event_quest.get("label", event_quest_id)), quest_event.quest_progress_text(event_quest_id)])
					_tracking_controls(tracking, "event", event_quest_id, 0)
		"events", "bonus":
			var event_runtime := get_tree().get_first_node_in_group("event_runtime") as EventRuntime
			if event_runtime != null and event_runtime.is_active():
				_status_card({"title":event_runtime.title(), "state":"PHASE %d · %s"%[event_runtime.phase,event_runtime.phase_label()], "detail":"%d %s · World Meter %d%%"%[event_runtime.currency,event_runtime.currency_label(),roundi(event_runtime.meter_ratio()*100.0)], "tone":"active", "progress":event_runtime.meter_ratio()}, true)
				event_status = _label(event_runtime.title().to_upper())
				_label(event_runtime.subtitle())
				_label("Seekarte bleibt Hauptspiel. Eventphase, Halloween-Weltlayer, Eventmunition und Tactical Item sind lokal testbar. Claims/Shop bleiben Preview und keine Live-Rewards.")
				_label("PHASE %d · %s"%[event_runtime.phase,event_runtime.phase_label()])
				var m158_phase:=M158HalloweenCatalog.phase(event_runtime.phase)
				if not m158_phase.is_empty():_label("ZIEL · "+str(m158_phase.get("objective","")))
				_label("%s: %d · World Meter: %d %%" % [event_runtime.currency_label(), event_runtime.currency, roundi(event_runtime.meter_ratio() * 100.0)])
				# M236: dedicated read-only ranking/contribution view inside Events.
				var m236_snapshot:=M236EventRankingViewCatalog.view_snapshot(event_runtime)
				_section("EVENT-LEISTUNG & RANG")
				_label(M236EventRankingViewCatalog.authority_label(m236_snapshot))
				_status_card(M236EventRankingViewCatalog.personal_card(m236_snapshot),true)
				_status_card(M236EventRankingViewCatalog.group_card(m236_snapshot),true)
				for contribution_row in M236EventRankingViewCatalog.contribution_rows(m236_snapshot):
					_label("%s · %.0f"%[str(contribution_row.get("label","Beitrag")),float(contribution_row.get("value",0.0))])
				var threshold:=M236EventRankingViewCatalog.threshold_progress(m236_snapshot)
				_status_card({"title":"NÄCHSTE SCHWELLE","state":str(threshold.get("label","")),"detail":"Nur Darstellung der servergelieferten Schwelle; keine clientseitige Qualifikation.","tone":"info","progress":float(threshold.get("ratio",0.0))},true)
				_status_card(M236EventRankingViewCatalog.qualification_card(m236_snapshot),true)
				_status_card(M236EventRankingViewCatalog.reward_card(m236_snapshot),true)
				var personal_board:=M236EventRankingViewCatalog.leaderboard_rows(m236_snapshot,false)
				if personal_board.is_empty():
					_label("RANGLISTE · Noch kein serverseitiger Leaderboard-Ausschnitt verfügbar. Keine simulierten Spieler.")
				else:
					_label("RANGLISTE · TOP %d · SERVER-SNAPSHOT"%personal_board.size())
					for board_row in personal_board:
						_label("#%d · %s · %.0f Beitrag%s"%[int(board_row.get("rank",0)),str(board_row.get("name","")),float(board_row.get("contribution",0.0))," · DU" if bool(board_row.get("is_self",false)) else ""])
				# M237: past event continuity is a separate server-owned read-only snapshot.
				_section("EVENT-HISTORIE")
				var m237_history:=M237EventHistoryCatalog.snapshot(event_runtime)
				_label(M237EventHistoryCatalog.authority_label(m237_history))
				var m237_rows:=M237EventHistoryCatalog.history_rows(m237_history)
				if m237_rows.is_empty():
					_label("Noch keine serverbestätigten vergangenen Events. Keine simulierten Platzierungen oder Stufen.")
				else:
					for history_row in m237_rows.slice(0,8):
						_status_card(M237EventHistoryCatalog.history_card(history_row),true)
				_section("REWARD-RECEIPTS")
				var m237_receipts:=M237EventHistoryCatalog.receipt_rows(m237_history)
				if m237_receipts.is_empty():
					_label("Keine serverbestätigten Reward-Receipts im Snapshot.")
				else:
					for receipt_row in m237_receipts.slice(0,8):
						_status_card(M237EventHistoryCatalog.receipt_card(receipt_row),true)
				# M238: season progression is a separate server-owned read-only aggregate above events/history.
				_section("SEASON")
				var m238_season:=M238SeasonProgressionCatalog.snapshot(event_runtime)
				_label(M238SeasonProgressionCatalog.authority_label(m238_season))
				_status_card(M238SeasonProgressionCatalog.season_card(m238_season),true)
				if str(m238_season.get("source",""))=="authoritative_snapshot":
					_status_card(M238SeasonProgressionCatalog.progression_card(m238_season),true)
					_status_card(M238SeasonProgressionCatalog.ranking_card(m238_season),true)
					for season_event_row in M238SeasonProgressionCatalog.event_result_rows(m238_season).slice(0,6):
						_status_card(M238SeasonProgressionCatalog.event_result_card(season_event_row),true)
					_status_card(M238SeasonProgressionCatalog.reward_card(m238_season),true)
				_label("EVENT-AUFTRÄGE")
				for q in event_runtime.quest_rows():
					var event_id := str(q.get("id", ""))
					_label("%s · %s · +%d %s"%[str(q.get("label","")),event_runtime.quest_progress_text(event_id),int(q.get("reward_currency",0)),event_runtime.currency_label()])
					if not event_runtime.quest_complete(event_id): _tracking_controls(tracking, "event", event_id, 0)
				_label("MEILENSTEINE")
				for row in event_runtime.milestone_rows():
					var mid := str(row.get("id", ""))
					var target := int(row.get("score", 0))
					var reward := str(row.get("reward_label", "Reward"))
					_button(body, "Meilenstein %d · %s" % [target, reward], func(): _result(event_runtime.claim_preview(mid), "Preview-Meilenstein markiert", "Noch nicht erreicht oder bereits markiert"))
				_label("EVENT-BELOHNUNGSPFAD · LOKALE VORSCHAU")
				for reward_row in event_runtime.reward_track_rows():
					var reward_score:=int(reward_row.get("score",0))
					var reward_label:=str(reward_row.get("label","Event Reward"))
					_button(body,"%d Score · %s · %s"%[reward_score,reward_label,event_runtime.reward_track_preview_status(reward_score)],func(target=reward_score):
						_result(event_runtime.reward_track_preview_claim(target),"Reward-Preview markiert","Score fehlt oder bereits markiert"))
				for shop_row in event_runtime.active().get("shop", []):
					var sid := str(shop_row.get("id", ""))
					_button(body, "%s · %d %s" % [shop_row.get("label", "Eventitem"), shop_row.get("cost", 0), event_runtime.currency_label()], func(): _result(event_runtime.shop_preview(sid), "Preview-Kauf markiert", "Nicht genug Eventwährung"))
				_label("Combat hooks: Eventmunition, Eventharpune, Event-Heilmunition, Event-Supply und Event-Blessing sind datengetrieben registriert; noch keine finalen Live-Drops oder serverseitigen Claims.")
			else:
				_status_card({"title":"SAISONALES EVENT", "state":"NICHT AKTIV", "detail":"Die Seekarte bleibt unverändert; es werden keine Eventwährung oder Live-Belohnungen simuliert.", "tone":"locked"})
			_label("Legacy lokaler Aktivitätstest: Piratenjagd · %d Jagdmarken · kein servergesteuertes Welt-Event." % voyage.event_tokens)
		"shop":
			# M174 compatibility: harbor-local rows still use _requirement_button + inventory.catalog_offer_status(row) semantics in the dedicated harbor page.
			_label("SHOP & ITEMSHOP")
			_label("Global erreichbar. Lokale Hafenmärkte, Reparatur und Hafenversorgung werden ausschließlich unter HAFEN angezeigt.")
			var commerce:=get_tree().get_first_node_in_group("commerce_catalog") as M161CommerceCatalog
			if commerce==null:
				_label("Commerce Catalog nicht verfügbar.")
			else:
				_label("ITEMSHOP · Real-Money-Produkte sind nur Provider-/Entitlement-Preview. Client gewährt niemals Käufe.")
				for offer in commerce.offers_for_shop("premium_item_shop"):
					if not offer is Dictionary:continue
					var paid:Dictionary=offer
					_button(body,"%s · Preis vom Store-Provider"%str(paid.get("label","Produkt")),func(product=paid):hud.note("PAYMENT PREVIEW · %s · Entitlement erst nach Server-Receipt"%str(product.get("entitlement_id",""))))
			_section("PAYMENT · PURCHASES · ENTITLEMENTS")
			var payment_commerce := get_tree().get_first_node_in_group("payment_commerce_readiness") as M255PaymentCommerceRuntime
			_status_card(M255PaymentCommerceCatalog.overview(payment_commerce), true)
			if payment_commerce != null and str(payment_commerce.snapshot().get("source", "")) == "SERVER":
				for payment_offer in payment_commerce.offer_rows().slice(0,8):
					if payment_offer is Dictionary: _status_card(M255PaymentCommerceCatalog.offer_card(payment_offer), true)
				for purchase_row in payment_commerce.purchase_rows().slice(-5):
					if purchase_row is Dictionary: _status_card(M255PaymentCommerceCatalog.purchase_card(purchase_row), true)
				for entitlement_row in payment_commerce.entitlement_rows().slice(0,8):
					if entitlement_row is Dictionary: _status_card(M255PaymentCommerceCatalog.entitlement_card(entitlement_row), true)
			_status_card(M255PaymentCommerceCatalog.authority_card(), true)
			_label("SCHIFFSAUSBAU · globales Metasystem")
			for kind in PlayerProgression.UPGRADE_KEYS:
				_button(body,"%s verbessern · Stufe %d/10 · %d Gold"%[kind,progression.upgrades[kind],progression.upgrade_cost(kind)],func():_result(progression.purchase_upgrade(kind),"Schiff verbessert","Gold oder Maximalstufe prüfen"))
			for slot in ["A","B"]:
				_button(body,"Loadout "+slot,func():inventory.apply_loadout(slot,weapons);hud.note("Loadout "+slot+" angelegt"))
		"harbor":
			_section("LOKALER HAFEN")
			var harbor_state := M187HarborServiceCatalog.harbor_status(player)
			_status_card({"title":str(harbor_state.get("port_name","Hafen")) if bool(harbor_state.get("available",false)) else "HAFEN", "state":str(harbor_state.get("label","AUF SEE")), "detail":str(harbor_state.get("detail","")), "tone":"ready" if bool(harbor_state.get("available",false)) else "info"}, true)
			_label("Werft, Schiffe, Ausrüstung, normale Quests, Events, Gilde, Rankings und Itemshop bleiben globale Systeme und werden hier nicht dupliziert oder gesperrt.")
			if bool(harbor_state.get("available", false)):
				_section("LOKALE DIENSTE")
				var harbor_commerce:=get_tree().get_first_node_in_group("commerce_catalog") as M161CommerceCatalog
				if harbor_commerce!=null:
					for offer in harbor_commerce.offers_for_shop("harbor_market"):
						if not offer is Dictionary:continue
						var local_offer:Dictionary=offer
						var local_label:="%s · %d %s"%[str(local_offer.get("label",local_offer.get("content_id","Angebot"))),int(local_offer.get("price",0)),str(local_offer.get("currency","gold")).capitalize()]
						_requirement_button(body,local_label,inventory.catalog_offer_status(local_offer),func(offer_row=local_offer.duplicate(true)):_result(inventory.purchase_catalog_offer(offer_row),"Gekauft","Preis, Bestand oder Verfügbarkeit prüfen"))
				_requirement_button(body,"Rumpf reparieren",inventory.harbor_repair_status(),func():_result(inventory.purchase_harbor_repair(),"Rumpf repariert","Schaden und Gold prüfen"))
				_requirement_button(body,"Lokales Versorgungspaket",inventory.harbor_bundle_status(),func():_result(inventory.purchase_harbor_bundle(),"Versorgung gekauft","Gold und Vorrat prüfen"))
				_label("SPEZIELLE HAFENAUFTRÄGE")
				_label("Nur veröffentlichte Aufträge mit requires_harbor=true bzw. quest_scope=harbor gehören hierher. M187 erfindet keine zusätzlichen Quests oder Belohnungen.")
			else:
				_label("Fahre zu einem tatsächlich vorhandenen Hafen. M186-Zielnavigation kann vorhandene Hafen-/Dockziele ansteuern.")
		"progress":
			_status_card({"title":"FORTSCHRITTSEBENEN", "state":"PIRAT PL%d · KARTE KL%d"%[progression.level,voyage.map_level()], "detail":"%s · Schiffslevel %d/10 · Ruhm/Ehre/Battle Rank bleiben getrennte Systeme."%[roster.selected_ship().display_name,roster.ship_level()], "tone":"info"})
			_button(body, "Progression Track öffnen · Eligibility / Rewards / Historie", func(): _open_progression_track("progress"))
			_button(body, "3D-Schiffswerft öffnen · Preview / Statvergleich", func(): _open_shipyard("progress", roster.selected_ship_id))
			_button(body, "Schiffs-Mastery öffnen · 3 Starter + 50 Hauptdesigns", func(): _open_mastery("progress"))

			var world := get_tree().get_first_node_in_group("world_map") as WorldMapSystem
			_label("Standort: %s · Kartenlevel %d" % [world.current_map_name(), world.current_map_level()])
			_label("Pirat Lv.%d · %s: Schiffslevel %d/10" % [progression.level, roster.selected_ship().display_name, roster.ship_level()])
			_label("Schiffs-XP: %d / %d · Verbesserungen und A/B-Ausrüstung gelten nur für dieses Design." % [roster._record(roster.selected_ship_id).xp, 150 * roster.ship_level()])
			_label("Kartenfreigabe %d · Anfängeraufträge %d/5" % [voyage.map_level(), voyage.completed_trials])
			_label("Keine Starterwahl: Swift Barco am Anfang, Clipper nach Auftrag 2, Iron Chalupa nach Auftrag 3. Die Schiffe werden ohne Goldkosten freigeschaltet; wechseln kannst du jederzeit über die globale Werft.")
			_label("ANFÄNGERAUFTRAG %d: In einem Hafen starten. Auf Kartenlevel %d drei Gegner versenken und zwei Beuten bergen, danach erneut einen Hafen anlaufen. Sinken bricht nur den laufenden Auftrag ab." % [mini(5, voyage.map_level()), mini(5, voyage.map_level())])
			_label("Belohnung: " + voyage.next_reward_text())
			_label("Status: %s · Gegner %d/3 · Beute %d/2 · Rückkehr %d/1" % ["ABGESCHLOSSEN" if voyage.beginner_complete() else ("AKTIV" if voyage.trial_active else "IM HAFEN STARTEN"), voyage.trial_counts.sink, voyage.trial_counts.loot, voyage.trial_counts.dock])
			if not voyage.beginner_complete():
				_button(body, "Auftrag beginnen", func(): _result(voyage.start_trial(), "Anfängerauftrag gestartet", "Nur im Hafen; kein zweiter Auftrag gleichzeitig"))
				_button(body, "Auftrag im Hafen abschließen", func(): _result(voyage.claim_trial(), "Kartenfreigabe und Belohnung erhalten", "Ziele auf passendem Kartenlevel, Rückkehr und Hafen prüfen"))
			_label("Piratenlevel, Kartenfreigabe und Schiffslevel sind getrennt. Elite-Einstieg ab Kartenlevel 6 ist ein vorläufiger Testwert; die spätere Hauptdesignreihe fehlt noch.")
			if voyage.legacy_access: _label("Alter Spielstand: bisheriger Kartenzugang bleibt erhalten, zählt aber nicht als erledigte Anfängeraufträge.")
			if voyage.map_level() >= BeginnerRules.ELITE_MAP_LEVEL:
				var region_id := inventory.current_region_id()
				var harbor_profile := RegionalHarborEconomy.harbor(region_id)
				if not harbor_profile.is_empty():
					_label("REGIONALER HAFENSERVICE · %s" % str(harbor_profile.get("service_label", region_id)))
					_label("Spezialisierung: %s" % str(harbor_profile.get("specialty", "")))
					for item_id in harbor_profile.get("purchase_offers", {}):
						var offer: Dictionary = harbor_profile.purchase_offers[item_id]
						_button(body, "%s ×%d · %d Gold" % [str(item_id).replace("_", " ").capitalize(), int(offer.amount), int(offer.price)], func(id = str(item_id)): _result(inventory.purchase_regional(id), "Regional gekauft", "Hafen/Region, Gold oder Bestand prüfen"))
					_label("REGIONALE HERSTELLUNG")
					for recipe_id in harbor_profile.get("recipes", []):
						var recipe := EquipmentEconomyContracts.recipe(str(recipe_id))
						_button(body, "%s · %d Gold" % [str(recipe_id).replace("_", " ").capitalize(), int(recipe.get("gold", 0))], func(id = str(recipe_id)): _result(inventory.craft(id), "Hergestellt", "Materialien, Gold und Hafen prüfen"))

		"equipment":
			_status_card({"title":"AKTIVES LOADOUT", "state":"%s · %s"%[weapons.cannon_name(),weapons.ammo_name()], "detail":"Deck %d/10 · Kanonenkapazität %d · Ausrüstung und Loadouts sind global erreichbar; nur ausdrücklich lokale Rezepte/Marktdienste verlangen einen Hafen."%[inventory.deck_level(),inventory.cannon_capacity()], "tone":"ready"})
			_button(body,"Ausbauzentrum · Decks / Spezialdecks / Kanonen / Talente / Kastell / Gilde",func():
				var hub:=get_tree().root.find_child("M160ProgressionHub",true,false) as M160ProgressionHub
				if hub!=null:
					hud.route_panel(hub,"equipment")
					hub.open(player,hud)
			)
			_button(body, "Ausrüstungszentrum öffnen · Module / Builds / Production", func():
				var screen := HarborEquipmentPanel.new()
				get_tree().root.add_child(screen)
				hud.route_panel(screen,"equipment")
				screen.open(hud, "modules")
			)

			_label("AKTIV: " + weapons.cannon_name() + " · " + weapons.ammo_name())
			_label("SCHIFFSAUSBAU · Deck %d/10 · Kanonenkapazität %d"%[inventory.deck_level(),inventory.cannon_capacity()])
			_label("Spezialdecks: eigene Familien statt generischer Motor-/Panzerdecks · datengetrieben und upgradefähig")
			_button(body,"Kristallsegen aktivieren · Bestand %d"%inventory.count("crystal_blessing"),func():_result(inventory.activate_crystal_blessing(),"Kristallsegen aktiv · sichtbarer Aura-Effekt","Kein Kristallsegen im Bestand"))
			_label("Kanonen gegen Schiffe. Harpunen gegen Monster. Zielgebundene Schüsse verfolgen das gewählte Ziel; Inseln blockieren. Ausrichtung verändert den Schaden nicht.")
			_button(body, "Kanonen auswählen", func(): weapons.select_mode("cannon"); open_page("equipment"))
			_button(body, "Harpunen auswählen · Bestand %d" % inventory.count("harpoon"), func(): weapons.select_mode("harpoon"); open_page("equipment"))
			for slot in ["A", "B"]:
				_label("%s / %s: %s" % [roster.selected_ship().display_name, slot, inventory.loadout_summary(slot)])
				_button(body, "Aktuelle Ausrüstung als " + slot + " speichern", func(): inventory.save_loadout(slot, weapons); open_page("equipment"))
				_button(body, "Ausrüstung " + slot + " anwenden", func(): inventory.apply_loadout(slot, weapons); open_page("equipment"))
			_label("REGIONALE MATERIALIEN · Stormglass %d · Ember Ore %d · Veil Silk %d · Timber %d · Gears %d" % [inventory.count("stormglass"), inventory.count("ember_ore"), inventory.count("veil_silk"), inventory.count("reinforced_timber"), inventory.count("precision_gears")])

			_label("REGIONALE MODULE · pro Schiff persistent · Slots: Weapon / Defense / Support / Mobility")
			_label(inventory.module_summary())
			var region_id := inventory.current_region_id()
			if not region_id.is_empty():
				for module_id in RegionalEquipmentCatalog.ids_for_region(region_id):
					var module_def := RegionalEquipmentCatalog.module(module_id)
					var owned := inventory.owned_modules.has(module_id)
					var cost: Dictionary = module_def.get("cost", {})
					var action_text := "AUSRÜSTEN" if owned else "BAUEN · %d Gold" % int(cost.get("gold", 0))
					_button(body, "%s · T%d · %s · %s" % [module_def.get("label", module_id), int(module_def.get("tier", 1)), str(module_def.get("slot", "")).to_upper(), action_text],
						func(id = str(module_id), already_owned = owned): _result(inventory.equip_module(id) if already_owned else inventory.build_regional_module(id), "Modul aktualisiert", "Region/Hafen, Materialien oder Besitz prüfen"))
			var telemetry := player.get_node_or_null("SupportContribution") as SupportContributionTelemetry
			if telemetry != null:
				_label("SUPPORT-TELEMETRIE · lokal, keine Rewards")
				_label(telemetry.summary())

			# M241: Crew remains abstracted; officers are a compact build/loadout layer.
			var crew := player.get_node_or_null("CrewOfficers") as M241CrewOfficerRuntime
			if crew != null:
				_section("CREW & OFFIZIERE")
				_status_card({"title":"OFFICER-LOADOUT", "state":crew.summary(), "detail":"Crew bleibt abstrahiert. Nur zugewiesene Officer-Verträge wirken; Live-Besitz und Progression benötigen später Serverautorität.", "tone":"ready"}, true)
				for slot_index in range(crew.slot_count()):
					var assigned_id := crew.assigned_slots[slot_index]
					var slot_label := crew.officer_label(assigned_id)
					_button(body, "SLOT %d · %s · WECHSELN" % [slot_index + 1, slot_label], func(index=slot_index):
						crew.cycle_slot(index)
						open_page("equipment"))
				_label("BESITZ · lokale Prototype-Roster")
				for officer_row in crew.roster_rows():
					var assigned_slot_index := int(officer_row.get("assigned_slot", -1))
					var assignment := "SLOT %d" % (assigned_slot_index + 1) if assigned_slot_index >= 0 else "NICHT ZUGEWIESEN"
					var traits_text := ", ".join(PackedStringArray(officer_row.get("traits", [])))
					_status_card({"title":str(officer_row.get("label", "Officer")), "state":"%s · Lv.%d · %s" % [str(officer_row.get("quality", "common")).to_upper(), int(officer_row.get("level", 1)), assignment], "detail":"%s · %s" % [str(officer_row.get("role", "Crew")), traits_text], "tone":"active" if assigned_slot_index >= 0 else "info"}, true)
				var officer_progression := player.get_node_or_null("OfficerProgression") as M242OfficerProgressionRuntime
				if officer_progression != null:
					_label("OFFICER-PROGRESSION · Serverwerte haben Vorrang")
					for officer_row in crew.roster_rows():
						var officer_id := str(officer_row.get("id", ""))
						var progression_row := officer_progression.state_for(officer_id, officer_row)
						var next_xp := int(progression_row.get("next_level_xp", -1))
						var xp_read := "%d XP" % int(progression_row.get("xp", 0)) if next_xp < 0 else "%d/%d XP" % [int(progression_row.get("xp", 0)), next_xp]
						_status_card({"title":crew.officer_label(officer_id), "state":"Lv.%d · %s" % [int(progression_row.get("level", 1)), str(progression_row.get("authority", "LOCAL_PREVIEW"))], "detail":"%s · Upgrade: %s" % [xp_read, str(progression_row.get("upgrade_state", "unknown"))], "tone":"ready" if str(progression_row.get("authority", "")) == "SERVER" else "info"}, true)
					_label("ROLLEN-BEREITSCHAFT · keine erfundenen Prozentboni")
					_label("Master Gunner · Cannon Build | Harpoon Master · Hunter | Navigator · Navigation | Shipwright · Hull Sustain | Quartermaster · Supplies | Surgeon · Support")
				var locked_officers := crew.locked_rows()
				if not locked_officers.is_empty():
					_label("WEITERE VERTRÄGE · planbar erspielbar; keine Gacha-Pflicht")
					for locked_row in locked_officers:
						_status_card({"title":str(locked_row.get("label", "Officer")), "state":"NOCH NICHT IM BESITZ", "detail":str(locked_row.get("acquisition", "Ers pielbarer Fortschritt")), "tone":"locked"})

		"guild":
			_section("GILDE · FLOTTE · INSEL")
			var guild_governance := player.get_node_or_null("GuildGovernance") as M250GuildGovernanceRuntime
			_status_card(M250GuildGovernanceCatalog.overview(guild_governance), true)
			_status_card(M250GuildGovernanceCatalog.treasury(guild_governance), true)
			_status_card(M250GuildGovernanceCatalog.diplomacy(guild_governance), true)
			_status_card(M250GuildGovernanceCatalog.war(guild_governance), true)
			_status_card({"title":"GILDENINSEL", "state":"WELTVORSCHAU BEREIT", "detail":"Hafen, Facilities und Türme nutzen bestehende World-Slots; Besitz, Bau und Upgrades bleiben serverautoritativ.", "tone":"info"}, true)
			_label("Rollen & Rechte werden kompakt und kontextuell gezeigt; kritische Aktionen benötigen Permission, Bestätigung und Audit.")
		"rankings":
			_section("PRESTIGE & WETTBEWERB")
			_status_card({"title":"RUHM", "state":"PVE-PRESTIGE", "detail":"Admiräle, Bosse, Monster, Bonusmaps, Events und Exploration; persistente Serverwertung noch nicht verbunden.", "tone":"info"})
			_section("PVP · EHRE · BATTLE RANK")
			var pvp_honor_ranked := player.get_node_or_null("PvpHonorRanked") as M249PvpHonorRankedRuntime
			_status_card(M249PvpHonorRankedCatalog.overview_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.zone_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.honor_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.ranked_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.queue_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.combat_timer_card(pvp_honor_ranked), true)
			_status_card(M249PvpHonorRankedCatalog.authority_card(pvp_honor_ranked), true)
			_section("WANTED & BOUNTIES")
			var wanted_bounty := player.get_node_or_null("WantedBounty") as M243WantedBountyRuntime
			_status_card(M243WantedBountyCatalog.status_card(wanted_bounty), true)
			if wanted_bounty != null:
				for bounty_row in wanted_bounty.active_bounties():
					if bounty_row is Dictionary: _status_card(M243WantedBountyCatalog.bounty_card(bounty_row), true)
			_status_card(M243WantedBountyCatalog.authority_card(wanted_bounty), true)
			_section("AKTIVES EVENT")
			var ranking_event:=M236EventRankingViewCatalog.runtime(get_tree())
			if ranking_event!=null and ranking_event.is_active():
				var ranking_snapshot:=M236EventRankingViewCatalog.view_snapshot(ranking_event)
				_status_card(M236EventRankingViewCatalog.personal_card(ranking_snapshot),true)
				_status_card(M236EventRankingViewCatalog.group_card(ranking_snapshot),true)
				_status_card(M236EventRankingViewCatalog.qualification_card(ranking_snapshot),true)
				_button(body,"Event-Leistung, Schwellen & Belohnungsstatus öffnen",func():navigate("events"))
			else:
				_status_card({"title":"EVENT-RANGLISTE","state":"KEIN AKTIVES EVENT","detail":"Es werden keine lokalen Spieler oder Rangpositionen erfunden.","tone":"locked"})
			_section("SEASON")
			var season_runtime:=M238SeasonProgressionCatalog.runtime(get_tree())
			var season_snapshot:=M238SeasonProgressionCatalog.snapshot(season_runtime)
			_status_card(M238SeasonProgressionCatalog.season_card(season_snapshot),true)
			if str(season_snapshot.get("source",""))=="authoritative_snapshot":
				_status_card(M238SeasonProgressionCatalog.progression_card(season_snapshot),true)
				_status_card(M238SeasonProgressionCatalog.ranking_card(season_snapshot),true)
				_button(body,"Season-Details & Event-Ergebnisse öffnen",func():navigate("events"))
			_section("VERGANGENE EVENTS")
			var history_runtime:=M237EventHistoryCatalog.runtime(get_tree())
			var history_snapshot:=M237EventHistoryCatalog.snapshot(history_runtime)
			var history_rows:=M237EventHistoryCatalog.history_rows(history_snapshot)
			if history_rows.is_empty():
				_status_card({"title":"EVENT-HISTORIE","state":"KEINE SERVERDATEN","detail":"Vergangene Platzierungen und Stufen werden nicht lokal erfunden.","tone":"locked"})
			else:
				for history_row in history_rows.slice(0,3):
					_status_card(M237EventHistoryCatalog.history_card(history_row),true)
				_button(body,"Vollständige Event-Historie öffnen",func():navigate("events"))
		"social":
			_section("SOZIALES · FREUNDE, GRUPPE & CHAT")
			var social := player.get_node_or_null("SocialRuntime") as M248SocialRuntime
			_status_card(M248SocialCatalog.overview_card(social), true)
			_status_card(M248SocialCatalog.group_card(social), true)
			if social != null and str(social.snapshot().get("source", "")) == "SERVER":
				_section("FREUNDE")
				var friends := social.friend_rows()
				if friends.is_empty(): _status_card({"title":"FREUNDE","state":"KEINE SERVERZEILEN","detail":"Freundesliste und Presence werden nicht lokal simuliert.","tone":"info"})
				else:
					for friend_row in friends.slice(0,10):
						if friend_row is Dictionary: _status_card(M248SocialCatalog.friend_card(friend_row), true)
				var members := social.group_member_rows()
				if not members.is_empty():
					_section("FLEET-GRUPPE")
					for member_row in members.slice(0,8):
						if member_row is Dictionary: _status_card(M248SocialCatalog.member_card(member_row), true)
				_section("CHAT · %s" % social.active_channel().to_upper())
				var messages := social.chat_rows(social.active_channel())
				if messages.is_empty(): _status_card({"title":"CHAT","state":"KEINE SERVERNACHRICHTEN","detail":"World/Global, Region, Map, Group, Guild, Alliance, Whisper und System sind vorbereitet.","tone":"info"})
				else:
					for message_row in messages.slice(-12):
						if message_row is Dictionary: _status_card(M248SocialCatalog.chat_card(message_row), true)
			_status_card(M248SocialCatalog.safety_card(social), true)
			_status_card(M248SocialCatalog.authority_card(social), true)
			_section("MAIL · MITTEILUNGEN · CLAIMS")
			var mail_notifications := get_tree().get_first_node_in_group("mail_notification_readiness") as M254MailNotificationRuntime
			_status_card(M254MailNotificationCatalog.overview(mail_notifications), true)
			if mail_notifications != null and str(mail_notifications.snapshot().get("source", "")) == "SERVER":
				for mail_row in mail_notifications.mail_rows().slice(0,10):
					if mail_row is Dictionary: _status_card(M254MailNotificationCatalog.mail_card(mail_row), true)
				for notice_row in mail_notifications.notification_rows().slice(0,6):
					if notice_row is Dictionary: _status_card(M254MailNotificationCatalog.notification_card(notice_row), true)
				for claim_row in mail_notifications.claim_receipt_rows().slice(-4):
					if claim_row is Dictionary: _status_card(M254MailNotificationCatalog.claim_card(claim_row), true)
			_status_card(M254MailNotificationCatalog.authority_card(), true)
		"bazaar":
			_section("SPIELERBASAR & HANDEL")
			var bazaar := player.get_node_or_null("BazaarTrading") as M247BazaarTradingRuntime
			_status_card(M247BazaarTradingCatalog.overview_card(bazaar), true)
			_status_card(M247BazaarTradingCatalog.contract_card(bazaar), true)
			if bazaar != null and str(bazaar.snapshot().get("source", "")) == "SERVER":
				_section("MARKTANGEBOTE")
				var listing_rows := bazaar.filtered_listing_rows()
				if listing_rows.is_empty():
					_status_card({"title":"ANGEBOTE","state":"KEINE SERVER-LISTINGS","detail":"Keine lokalen Preise oder Angebote werden simuliert.","tone":"info"})
				else:
					for listing_row in listing_rows.slice(0,12):
						if listing_row is Dictionary: _status_card(M247BazaarTradingCatalog.listing_card(listing_row), true)
				_section("EIGENE LISTINGS")
				for my_row in bazaar.my_listing_rows().slice(0,6):
					if my_row is Dictionary: _status_card(M247BazaarTradingCatalog.listing_card(my_row), true)
			_status_card(M247BazaarTradingCatalog.authority_card(bazaar), true)
		"meta":
			_section("BEGLEITER · ARTEFAKTE · AFK-REWARDS")
			var meta_progression := player.get_node_or_null("MetaProgression") as M251MetaProgressionRuntime
			_status_card(M251MetaProgressionCatalog.overview(meta_progression), true)
			_status_card(M251MetaProgressionCatalog.companion(meta_progression), true)
			_status_card(M251MetaProgressionCatalog.artifacts(meta_progression), true)
			_status_card(M251MetaProgressionCatalog.afk(meta_progression), true)
			if meta_progression == null or str(meta_progression.snapshot().get("source", "")) != "SERVER":
				var preview := meta_progression.local_definition_preview() if meta_progression != null else {}
				_label("DEFINITIONEN · %d Begleiter · %d Artefakte · %d AFK-Profile" % [int(preview.get("companion_definitions", CompanionCatalog.all().size())), int(preview.get("artifact_definitions", ArtifactCatalog.all().size())), int(preview.get("afk_profiles", AfkRewardCatalog.profiles().size()))])
				_label("Lokale Kataloge zeigen nur Design-/Asset-Readiness. Ownership, Progression, Offlinezeit und Rewards werden nicht simuliert.")
			else:
				var receipts := meta_progression.claim_receipt_rows()
				if not receipts.is_empty():
					_section("LETZTE SERVER-CLAIMS")
					for receipt_row in receipts.slice(-4):
						if receipt_row is Dictionary:
							_label(str((receipt_row as Dictionary).get("summary", (receipt_row as Dictionary).get("receipt_id", "Claim bestätigt"))))
			_status_card(M251MetaProgressionCatalog.authority(meta_progression), true)
			_button(body, "VISUELLE DEV-VORSCHAU ÖFFNEN", func():
				var meta_panel := get_tree().get_first_node_in_group("meta_systems_panel") as MetaSystemsPanel
				if meta_panel != null:
					hud.route_panel(meta_panel, "meta")
					meta_panel.open()
			)
		"achievements":
			_section("ERFOLGE & SAMMLUNGEN")
			var achievement_collections := player.get_node_or_null("AchievementCollections") as M246AchievementCollectionRuntime
			_status_card(M246AchievementCollectionCatalog.overview_card(achievement_collections), true)
			if achievement_collections == null or str(achievement_collections.snapshot().get("source", "")) != "SERVER":
				_status_card(M246AchievementCollectionCatalog.preview_card(achievement_collections), true)
			else:
				_section("AKTIVE & ABGESCHLOSSENE ERFOLGE")
				var achievement_rows := achievement_collections.achievement_rows()
				if achievement_rows.is_empty():
					_status_card({"title":"ERFOLGE","state":"KEINE SERVERZEILEN","detail":"Keine lokalen Abschlüsse oder Rewards werden simuliert.","tone":"locked"})
				else:
					for achievement_row in achievement_rows.slice(0,12):
						if achievement_row is Dictionary: _status_card(M246AchievementCollectionCatalog.achievement_card(achievement_row), true)
				_section("SAMMLUNGEN & CODEX")
				var collection_rows := achievement_collections.collection_rows()
				if collection_rows.is_empty():
					_status_card({"title":"SAMMLUNGEN","state":"KEINE SERVERZEILEN","detail":"Ship Collection, Admiral Codex, Monster Codex, World Discovery, Event Collection und Cosmetics bleiben vorbereitet.","tone":"info"})
				else:
					for collection_row in collection_rows.slice(0,12):
						if collection_row is Dictionary: _status_card(M246AchievementCollectionCatalog.collection_card(collection_row), true)
				var showcase_rows := achievement_collections.profile_showcase_rows()
				if not showcase_rows.is_empty():
					_section("CAPTAIN-PROFIL · BESONDERE ERFOLGE")
					for showcase_row in showcase_rows.slice(0,4):
						if showcase_row is Dictionary: _label(str((showcase_row as Dictionary).get("title", (showcase_row as Dictionary).get("id", "Achievement"))))
			_status_card(M246AchievementCollectionCatalog.authority_card(achievement_collections), true)
		"chat":
			# Compatibility anchor for the original M161 contract: CHAT + STAFF COMMAND CONSOLE.
			_label("CHAT & STAFF-KONSOLE")
			_label("Spielerchat bleibt Online-Funktion. Staff-Befehle werden aus einem Datenkatalog aufgelöst und benötigen server-verifizierte Rollen/Rechte.")
			var commands:=get_tree().get_first_node_in_group("admin_command_registry") as M161AdminCommandRegistry
			if commands!=null:
				var summary:=commands.summary()
				_label("%d Staff-Befehle · %d kritisch · Produktion: SERVER REQUIRED"%[int(summary.get("commands",0)),int(summary.get("critical",0))])
				for def in commands.commands():
					if not def is Dictionary:continue
					var row:Dictionary=def
					_label("/%s · %s · %s · %s"%[str(row.get("id","")),str(row.get("permission","")),str(row.get("risk","read")).to_upper(),str(row.get("description",""))])
				var example:=commands.preview(get_tree(),"/snapshot world")
				_label("Beispiel /snapshot world · autorisiert: %s · keine lokale Ausführung"%str(bool(example.get("authorized",false))))
		"admin":
			var admin:=get_tree().get_first_node_in_group("admin_runtime") as AdminModeRuntime
			if admin==null or not admin.enabled:
				_label("Admin Mode nicht verfügbar.")
			else:
				_label("ADMIN MODE · LOCAL DEVELOPMENT ONLY")
				_label("Keine Aktion ist Live-/Server-Authority. Produktions-Adminrechte müssen später serverseitig authentifiziert werden.")
				_button(body,"Admin Overlay öffnen",func():hud.close_menu();admin.toggle_overlay())
				_button(body,"Halloween AN/AUS",func():admin.toggle_halloween();open_page("admin"))
				_button(body,"Halloween Phase weiter",func():admin.cycle_event_phase();open_page("admin"))
				_button(body,"+100 Eventwährung",func():admin.add_event_currency();open_page("admin"))
				_button(body,"+25 Eventscore",func():admin.event().admin_add_score(25);open_page("admin"))
				_button(body,"Test-Kit + Gold",func():admin.grant_test_kit();open_page("admin"))
				_button(body,"Voll reparieren",func():admin.heal_full())
				_button(body,"Unverwundbarkeit umschalten",func():admin.toggle_invulnerability();open_page("admin"))
				for map_level in [1,2,3,4,5,6,10,15]:
					_button(body,"Teleport Kartenlevel %d"%map_level,func(v=map_level):admin.teleport_level(v))
				_button(body,"Halloween Sloop Combat",func():admin.spawn_event_preview("event_halloween_npc_sloop_01"))
				_button(body,"Halloween Raider Combat",func():admin.spawn_event_preview("event_halloween_npc_raider_01"))
				_button(body,"Halloween Admiral Combat",func():admin.spawn_event_preview("event_halloween_admiral_01"))
				_button(body,"Halloween Monster Combat",func():admin.spawn_event_preview("event_halloween_monster_01"))
				_button(body,"Halloween Boss Combat",func():admin.spawn_event_preview("event_halloween_boss_01"))
				_button(body,"Gildeninsel Relation wechseln",func():admin.cycle_guild_relation();open_page("admin"))
				_button(body,"Gildenturm-Zustand wechseln",func():admin.cycle_guild_tower_state();open_page("admin"))
				_button(body,"Turmreichweiten AN/AUS",func():admin.toggle_guild_range_preview();open_page("admin"))
				_label("BUILD · "+BuildIdentity.compact())
				var locator:=ServiceLocator.from(get_tree())
				_label("SERVICES · "+str(locator.status() if locator!=null else {"configured":false}))
				_label(P0ReplacementDashboard.summary_line())
				_label("P0 FINAL-ART CHECKLIST · 13 Slots · Native-Abnahme weiterhin offen")
				if locator!=null and locator.rewards!=null:
					_label(locator.rewards.receipt_summary())
				var qa_player:=get_tree().get_first_node_in_group("player") as ShipMotor
				if qa_player!=null:
					_label("TEACHING · "+str(BeginnerTeachingRuntime.diagnostics(qa_player)))
					var admin_voyage:=qa_player.get_node_or_null("Voyage") as VoyageProgress
					var post:=qa_player.get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
					if admin_voyage!=null and post!=null and admin_voyage.map_level()>=6 and admin_voyage.map_level()<=10:
						var ml:=admin_voyage.map_level()
						_label("PL6–10 · L%d · XP %d/%d · Boss %s · Ship Lv %d"%[ml,int(post.map_xp.get(ml,0)),Pl6To10ProgressionCatalog.map_xp_goal(ml),str(post.boss_clears.get(ml,false)),(qa_player.get_node("ShipRoster") as PlayerShipRoster).ship_level()])
				_label("STAFF AUTH · NICHT VERIFIZIERT · lokale Development-Tools")
				_button(body,"Seekarte neu aufbauen",func():admin.rebuild_sector())
		"systems":
			_label("ONLINE · ACCOUNT · PERSISTENZ · TRANSPORT")
			_label("Produktionsbereitschaft wird hier absichtlich fail-closed gezeigt. LOCAL ist Entwicklungswerkzeug und keine Live-Vertrauensquelle.")
			var readiness := get_tree().get_first_node_in_group("online_readiness") as M252OnlineReadinessRuntime
			_status_card(M252OnlineReadinessCatalog.overview(readiness), true)
			if readiness != null:
				for row in readiness.capability_rows(): _status_card(M252OnlineReadinessCatalog.capability_card(row), true)
			_status_card(M252OnlineReadinessCatalog.isolation_card(), true)
			_status_card(M252OnlineReadinessCatalog.authority_card(), true)
			_section("WORLD SESSION · PRESENCE · RECONNECT")
			var world_session := get_tree().get_first_node_in_group("world_session_readiness") as M253WorldSessionRuntime
			_status_card(M253WorldSessionCatalog.overview(world_session), true)
			_status_card(M253WorldSessionCatalog.world_card(world_session), true)
			_status_card(M253WorldSessionCatalog.presence_card(world_session), true)
			_status_card(M253WorldSessionCatalog.reconnect_card(world_session), true)
			_status_card(M253WorldSessionCatalog.authority_card(), true)
			_section("REJOIN-KOMMUNIKATION")
			var system_mail := get_tree().get_first_node_in_group("mail_notification_readiness") as M254MailNotificationRuntime
			_status_card(M254MailNotificationCatalog.overview(system_mail), true)
			_label("Kritische Maintenance-/Reconnect-/Versionshinweise dürfen transient im HUD erscheinen; normale Mitteilungen bleiben im Command Deck statt die Seekarte zu überladen.")
			_section("PRODUKTIONSLÜCKE")
			_label("Noch erforderlich: echter Auth-Provider, persistentes Remote-Repository, verifizierter Remote-Transport, autoritativer World/Zone-Server, Live-Presence, server-issued Resume-Flow und Reconnect/Resume-End-to-End-QA.")
			_label("Keine Anzeige auf dieser Seite darf aus einem lokalen Save oder Clientzustand einen verbundenen Live-Service ableiten.")
			_section("TELEMETRIE · ANALYTICS · OBSERVABILITY")
			var telemetry := get_tree().get_first_node_in_group("telemetry_observability_readiness") as M256TelemetryObservabilityRuntime
			_status_card(M256TelemetryObservabilityCatalog.overview(telemetry), true)
			_status_card(M256TelemetryObservabilityCatalog.diagnostic_card(telemetry), true)
			if telemetry != null and str(telemetry.snapshot().get("source", "")) == "SERVER":
				for metric_row in telemetry.health_rows().slice(0,6):
					if metric_row is Dictionary: _status_card(M256TelemetryObservabilityCatalog.metric_card(metric_row), true)
				for alert_row in telemetry.alert_rows().slice(0,4):
					if alert_row is Dictionary: _status_card(M256TelemetryObservabilityCatalog.alert_card(alert_row), true)
			_status_card(M256TelemetryObservabilityCatalog.privacy_card(), true)
			_status_card(M256TelemetryObservabilityCatalog.authority_card(), true)
			_section("RELEASE · FEATURE FLAGS · INCIDENTS")
			var release_ops := get_tree().get_first_node_in_group("release_operations_readiness") as M257ReleaseOperationsRuntime
			_status_card(M257ReleaseOperationsCatalog.overview(release_ops), true)
			_status_card(M257ReleaseOperationsCatalog.minimum_version(release_ops), true)
			_status_card(M257ReleaseOperationsCatalog.feature_flags(release_ops), true)
			_status_card(M257ReleaseOperationsCatalog.incident(release_ops), true)
			_status_card(M257ReleaseOperationsCatalog.deployment(release_ops), true)
			_status_card(M257ReleaseOperationsCatalog.launch_gate(), true)
			_section("BACKUP · PITR · DISASTER RECOVERY")
			var recovery := get_tree().get_first_node_in_group("backup_disaster_recovery_readiness") as M258BackupDisasterRecoveryRuntime
			_status_card(M258BackupDisasterRecoveryCatalog.overview(recovery), true)
			_status_card(M258BackupDisasterRecoveryCatalog.backup(recovery), true)
			_status_card(M258BackupDisasterRecoveryCatalog.restore(recovery), true)
			_status_card(M258BackupDisasterRecoveryCatalog.disaster(recovery), true)
			_status_card(M258BackupDisasterRecoveryCatalog.authority(), true)
			_section("SECURITY · SECRETS · ANTI-ABUSE")
			var security_ops := get_tree().get_first_node_in_group("security_operations_readiness") as M259SecurityOperationsRuntime
			_status_card(M259SecurityOperationsCatalog.overview(security_ops), true)
			_status_card(M259SecurityOperationsCatalog.account(security_ops), true)
			_status_card(M259SecurityOperationsCatalog.secrets(), true)
			_status_card(M259SecurityOperationsCatalog.permissions(security_ops), true)
			_status_card(M259SecurityOperationsCatalog.anti_abuse(security_ops), true)
			_status_card(M259SecurityOperationsCatalog.authority(), true)
			_section("CAPACITY · LOAD · SOAK · PERFORMANCE")
			var capacity_ops := get_tree().get_first_node_in_group("capacity_performance_readiness") as M260CapacityPerformanceRuntime
			_status_card(M260CapacityPerformanceCatalog.overview(capacity_ops), true)
			_status_card(M260CapacityPerformanceCatalog.capacity(capacity_ops), true)
			_status_card(M260CapacityPerformanceCatalog.resilience(capacity_ops), true)
			_status_card(M260CapacityPerformanceCatalog.client_performance(capacity_ops), true)
			_status_card(M260CapacityPerformanceCatalog.bottlenecks(capacity_ops), true)
			_status_card(M260CapacityPerformanceCatalog.authority(), true)
			_section("CRASH · CLIENT HEALTH · QA MATRIX")
			var client_health_ops := get_tree().get_first_node_in_group("crash_client_health_readiness") as M261CrashClientHealthRuntime
			_status_card(M261CrashClientHealthCatalog.overview(client_health_ops), true)
			_status_card(M261CrashClientHealthCatalog.crash(client_health_ops), true)
			_status_card(M261CrashClientHealthCatalog.device_health(client_health_ops), true)
			_status_card(M261CrashClientHealthCatalog.network(client_health_ops), true)
			_status_card(M261CrashClientHealthCatalog.matrix(client_health_ops), true)
			_status_card(M261CrashClientHealthCatalog.authority(), true)
			_section("LAUNCH READINESS · RELEASE CANDIDATE")
			var launch_gate := get_tree().get_first_node_in_group("launch_readiness_gate") as M262LaunchReadinessRuntime
			_status_card(M262LaunchReadinessCatalog.overview(launch_gate), true)
			_status_card(M262LaunchReadinessCatalog.candidate(launch_gate), true)
			_status_card(M262LaunchReadinessCatalog.gates(launch_gate), true)
			_status_card(M262LaunchReadinessCatalog.blockers(launch_gate), true)
			_status_card(M262LaunchReadinessCatalog.authority(), true)
			_section("ONLINE ALPHA · END-TO-END SERVER FLOW")
			var online_alpha := get_tree().get_first_node_in_group("online_alpha_readiness") as M263OnlineAlphaRuntime
			_status_card(M263OnlineAlphaCatalog.overview(online_alpha), true)
			_status_card(M263OnlineAlphaCatalog.flow(online_alpha), true)
			_status_card(M263OnlineAlphaCatalog.persistence(online_alpha), true)
			_status_card(M263OnlineAlphaCatalog.reconnect(online_alpha), true)
			_status_card(M263OnlineAlphaCatalog.authority(), true)
			_section("AUTH · ACCOUNT · PERSISTENT REPOSITORY")
			var account_repo := get_tree().get_first_node_in_group("auth_account_repository_readiness") as M264AuthAccountRepositoryRuntime
			_status_card(M264AuthAccountRepositoryCatalog.overview(account_repo), true)
			_status_card(M264AuthAccountRepositoryCatalog.identity(account_repo), true)
			_status_card(M264AuthAccountRepositoryCatalog.repository(account_repo), true)
			_status_card(M264AuthAccountRepositoryCatalog.conflicts(account_repo), true)
			_status_card(M264AuthAccountRepositoryCatalog.authority(), true)
			_section("PLAYER PROFILE · OWNERSHIP · PERSISTENCE")
			var player_profile_ownership := get_tree().get_first_node_in_group("player_profile_ownership_readiness") as M265PlayerProfileOwnershipRuntime
			_status_card(M265PlayerProfileOwnershipCatalog.overview(player_profile_ownership), true)
			_status_card(M265PlayerProfileOwnershipCatalog.ownership(player_profile_ownership), true)
			_status_card(M265PlayerProfileOwnershipCatalog.loadout(player_profile_ownership), true)
			_status_card(M265PlayerProfileOwnershipCatalog.progression(player_profile_ownership), true)
			_status_card(M265PlayerProfileOwnershipCatalog.authority(), true)
			_section("ECONOMY · INVENTORY · ATOMIC TRANSACTIONS")
			var economy_transactions := get_tree().get_first_node_in_group("economy_inventory_transaction_readiness") as M266EconomyInventoryTransactionRuntime
			_status_card(M266EconomyInventoryTransactionCatalog.overview(economy_transactions), true)
			_status_card(M266EconomyInventoryTransactionCatalog.wallet(economy_transactions), true)
			_status_card(M266EconomyInventoryTransactionCatalog.inventory(economy_transactions), true)
			_status_card(M266EconomyInventoryTransactionCatalog.transactions(economy_transactions), true)
			_status_card(M266EconomyInventoryTransactionCatalog.authority(), true)
			_section("WORLD TRANSPORT · SNAPSHOTS · DELTAS")
			var world_transport := get_tree().get_first_node_in_group("authoritative_world_transport_readiness") as M267AuthoritativeWorldTransportRuntime
			_status_card(M267AuthoritativeWorldTransportCatalog.overview(world_transport), true)
			_status_card(M267AuthoritativeWorldTransportCatalog.sequencing(world_transport), true)
			_status_card(M267AuthoritativeWorldTransportCatalog.entities(world_transport), true)
			_status_card(M267AuthoritativeWorldTransportCatalog.resync_transfer(world_transport), true)
			_status_card(M267AuthoritativeWorldTransportCatalog.authority(), true)
			_section("MOVEMENT · PREDICTION · RECONCILIATION")
			var authoritative_movement := get_tree().get_first_node_in_group("authoritative_movement_readiness") as M268AuthoritativeMovementRuntime
			_status_card(M268AuthoritativeMovementCatalog.overview(authoritative_movement), true)
			_status_card(M268AuthoritativeMovementCatalog.prediction(authoritative_movement), true)
			_status_card(M268AuthoritativeMovementCatalog.reconciliation(authoritative_movement), true)
			_status_card(M268AuthoritativeMovementCatalog.abuse_guards(), true)
			_status_card(M268AuthoritativeMovementCatalog.authority(), true)
			_section("COMBAT · TARGET · FIRE RESOLUTION")
			var authoritative_combat := get_tree().get_first_node_in_group("authoritative_combat_readiness") as M269AuthoritativeCombatRuntime
			_status_card(M269AuthoritativeCombatCatalog.overview(authoritative_combat), true)
			_status_card(M269AuthoritativeCombatCatalog.targeting(authoritative_combat), true)
			_status_card(M269AuthoritativeCombatCatalog.resolution(authoritative_combat), true)
			_status_card(M269AuthoritativeCombatCatalog.settlement(), true)
			_status_card(M269AuthoritativeCombatCatalog.authority(), true)
			_section("COMBAT STATE · RELOAD · EFFECTS · PROJECTILES")
			var combat_state := get_tree().get_first_node_in_group("authoritative_combat_state_readiness") as M270AuthoritativeCombatStateRuntime
			_status_card(M270AuthoritativeCombatStateCatalog.overview(combat_state), true)
			_status_card(M270AuthoritativeCombatStateCatalog.effects(combat_state), true)
			_status_card(M270AuthoritativeCombatStateCatalog.sustain(combat_state), true)
			_status_card(M270AuthoritativeCombatStateCatalog.projectiles(combat_state), true)
			_status_card(M270AuthoritativeCombatStateCatalog.authority(), true)
			_section("TARGETING · AGGRO · PVP · SAFE ZONES")
			var target_authority := get_tree().get_first_node_in_group("targeting_relationship_authority_readiness") as M271TargetingRelationshipAuthorityRuntime
			_status_card(M271TargetingRelationshipAuthorityCatalog.overview(target_authority), true)
			_status_card(M271TargetingRelationshipAuthorityCatalog.relationships(target_authority), true)
			_status_card(M271TargetingRelationshipAuthorityCatalog.zones(target_authority), true)
			_status_card(M271TargetingRelationshipAuthorityCatalog.aggro(target_authority), true)
			_status_card(M271TargetingRelationshipAuthorityCatalog.legality(), true)
			_status_card(M271TargetingRelationshipAuthorityCatalog.authority(), true)
			_section("NPC / MONSTER AI · THREAT · COMBAT BRAIN")
			var ai_brain := get_tree().get_first_node_in_group("npc_monster_ai_combat_brain_readiness") as M272NpcMonsterAICombatBrainRuntime
			_status_card(M272NpcMonsterAICombatBrainCatalog.overview(ai_brain), true)
			_status_card(M272NpcMonsterAICombatBrainCatalog.state_machine(ai_brain), true)
			_status_card(M272NpcMonsterAICombatBrainCatalog.threat(ai_brain), true)
			_status_card(M272NpcMonsterAICombatBrainCatalog.archetypes(), true)
			_status_card(M272NpcMonsterAICombatBrainCatalog.integration(), true)
			_status_card(M272NpcMonsterAICombatBrainCatalog.authority(), true)
			_section("ENCOUNTER · SPAWN · RESPAWN · BOSS PHASES")
			var encounter_orchestration := get_tree().get_first_node_in_group("authoritative_encounter_orchestration_readiness") as M273AuthoritativeEncounterOrchestrationRuntime
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.overview(encounter_orchestration), true)
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.spawns(), true)
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.phases_waves(), true)
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.lifecycle(), true)
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.integration(), true)
			_status_card(M273AuthoritativeEncounterOrchestrationCatalog.authority(), true)
			_section("KILL CREDIT · LOOT · REWARD ELIGIBILITY · PERSISTENCE")
			var reward_persistence := get_tree().get_first_node_in_group("authoritative_kill_credit_reward_persistence_readiness") as M274AuthoritativeKillCreditRewardPersistenceRuntime
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.overview(reward_persistence), true)
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.contribution(), true)
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.eligibility(), true)
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.persistence(), true)
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.settlement(), true)
			_status_card(M274AuthoritativeKillCreditRewardPersistenceCatalog.authority(), true)
			_section("LOOT TABLES · DROP POOLS · GROUP / FLEET DISTRIBUTION")
			var loot_distribution := get_tree().get_first_node_in_group("authoritative_loot_distribution_readiness") as M275AuthoritativeLootDistributionRuntime
			_status_card(M275AuthoritativeLootDistributionCatalog.overview(loot_distribution), true)
			_status_card(M275AuthoritativeLootDistributionCatalog.pools(), true)
			_status_card(M275AuthoritativeLootDistributionCatalog.personal(), true)
			_status_card(M275AuthoritativeLootDistributionCatalog.groups(), true)
			_status_card(M275AuthoritativeLootDistributionCatalog.settlement(), true)
			_status_card(M275AuthoritativeLootDistributionCatalog.authority(), true)
			_section("LOOT ROLL LEDGER · RNG · DUPLICATE · PITY")
			var loot_roll_integrity := get_tree().get_first_node_in_group("authoritative_loot_roll_integrity_readiness") as M276AuthoritativeLootRollIntegrityRuntime
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.overview(loot_roll_integrity), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.ledger(), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.rng(), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.duplicate(), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.pity(), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.settlement(), true)
			_status_card(M276AuthoritativeLootRollIntegrityCatalog.authority(), true)
			_section("REWARD RECEIPT · CLAIM DELIVERY · MAIL FALLBACK · RECOVERY")
			var reward_delivery := get_tree().get_first_node_in_group("authoritative_reward_delivery_readiness") as M277AuthoritativeRewardDeliveryRuntime
			_status_card(M277AuthoritativeRewardDeliveryCatalog.overview(reward_delivery), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.receipts(), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.delivery(), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.mail_fallback(), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.recovery(), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.settlement(), true)
			_status_card(M277AuthoritativeRewardDeliveryCatalog.authority(), true)
			_section("REWARD INBOX · CLAIM QUEUE · OVERFLOW · EXPIRY")
			var reward_inbox := get_tree().get_first_node_in_group("authoritative_reward_inbox_readiness") as M278AuthoritativeRewardInboxRuntime
			_status_card(M278AuthoritativeRewardInboxCatalog.overview(reward_inbox), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.inbox(), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.queue(), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.overflow(), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.expiry(), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.compensation(), true)
			_status_card(M278AuthoritativeRewardInboxCatalog.authority(), true)
			_section("REWARD PRESENTATION · LOOT FEEDBACK · CLAIM UX")
			var reward_presentation := get_tree().get_first_node_in_group("authoritative_reward_presentation_readiness") as M279AuthoritativeRewardPresentationRuntime
			_status_card(M279AuthoritativeRewardPresentationCatalog.overview(reward_presentation), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.seachart_feedback(), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.boss_admiral(), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.badges(), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.claim_ux(), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.hierarchy(), true)
			_status_card(M279AuthoritativeRewardPresentationCatalog.authority(), true)
			_section("REWARD VISUALS · HUD · BOSS REVEAL")
			var reward_visuals := get_tree().get_first_node_in_group("reward_visual_integration_readiness") as M280RewardVisualIntegrationRuntime
			_status_card(M280RewardVisualIntegrationCatalog.overview(reward_visuals), true)
			_status_card(M280RewardVisualIntegrationCatalog.hud(), true)
			_status_card(M280RewardVisualIntegrationCatalog.boss_admiral(), true)
			_status_card(M280RewardVisualIntegrationCatalog.icons(), true)
			_status_card(M280RewardVisualIntegrationCatalog.responsive(), true)
			_status_card(M280RewardVisualIntegrationCatalog.vfx(), true)
			_status_card(M280RewardVisualIntegrationCatalog.authority(), true)
			_section("COMBAT HUD · TARGET · RELOAD · AMMO · STATUS")
			var combat_hud_visuals := get_tree().get_first_node_in_group("combat_hud_convergence_readiness") as M281CombatHudConvergenceRuntime
			_status_card(M281CombatHudConvergenceCatalog.overview(combat_hud_visuals), true)
			_status_card(M281CombatHudConvergenceCatalog.target(), true)
			_status_card(M281CombatHudConvergenceCatalog.reload_ammo(), true)
			_status_card(M281CombatHudConvergenceCatalog.effects(), true)
			_status_card(M281CombatHudConvergenceCatalog.boss(), true)
			_status_card(M281CombatHudConvergenceCatalog.responsive(), true)
			_status_card(M281CombatHudConvergenceCatalog.authority(), true)
			_section("COMBAT FEEDBACK · DAMAGE / HEAL · IMPACT VFX")
			var combat_feedback := get_tree().get_first_node_in_group("combat_event_feedback_readiness") as M282CombatEventFeedbackRuntime
			_status_card(M282CombatEventFeedbackCatalog.overview(combat_feedback), true)
			_status_card(M282CombatEventFeedbackCatalog.coalescing(), true)
			_status_card(M282CombatEventFeedbackCatalog.hit_confirmation(), true)
			_status_card(M282CombatEventFeedbackCatalog.impacts(), true)
			_status_card(M282CombatEventFeedbackCatalog.sea_chart(), true)
			_status_card(M282CombatEventFeedbackCatalog.responsive(), true)
			_status_card(M282CombatEventFeedbackCatalog.authority(), true)
			_section("PROJECTILES · SALVOS · HARPOONS · AUDIO / HAPTICS")
			var projectile_presentation := get_tree().get_first_node_in_group("projectile_salvo_presentation_readiness") as M283ProjectileSalvoPresentationRuntime
			_status_card(M283ProjectileSalvoPresentationCatalog.overview(projectile_presentation), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.cannon(), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.harpoon(), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.impacts(), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.audio_haptics(), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.responsive(), true)
			_status_card(M283ProjectileSalvoPresentationCatalog.authority(), true)
			_section("NAVAL COMBAT IDENTITY · CANNONS · HARPOONS · IMPACT MATERIAL")
			var combat_identity := get_tree().get_first_node_in_group("naval_combat_identity_readiness") as M284NavalCombatIdentityRuntime
			_status_card(M284NavalCombatIdentityCatalog.overview(combat_identity), true)
			_status_card(M284NavalCombatIdentityCatalog.cannon_families(), true)
			_status_card(M284NavalCombatIdentityCatalog.ammo_harpoon(), true)
			_status_card(M284NavalCombatIdentityCatalog.materials(), true)
			_status_card(M284NavalCombatIdentityCatalog.rhythm(), true)
			_status_card(M284NavalCombatIdentityCatalog.audio(), true)
			_status_card(M284NavalCombatIdentityCatalog.authority(), true)
			_section("SHIP DAMAGE · HULL / SHIELD · SINKING / DEFEAT")
			var ship_damage := get_tree().get_first_node_in_group("ship_damage_defeat_presentation_readiness") as M285ShipDamageDefeatPresentationRuntime
			_status_card(M285ShipDamageDefeatPresentationCatalog.overview(ship_damage), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.hit_reactions(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.hull_shield(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.damage_states(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.placeholders(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.sinking(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.cleanup(), true)
			_status_card(M285ShipDamageDefeatPresentationCatalog.authority(), true)
			_section("SHIP DAMAGE OVERLAYS · SEGMENTS · FLOODING · WRECK")
			var damage_escalation := get_tree().get_first_node_in_group("ship_damage_escalation_readiness") as M286ShipDamageEscalationRuntime
			_status_card(M286ShipDamageEscalationCatalog.overview(damage_escalation), true)
			_status_card(M286ShipDamageEscalationCatalog.segments(), true)
			_status_card(M286ShipDamageEscalationCatalog.deck_mast_sails(), true)
			_status_card(M286ShipDamageEscalationCatalog.flooding(), true)
			_status_card(M286ShipDamageEscalationCatalog.sinking_profiles(), true)
			_status_card(M286ShipDamageEscalationCatalog.placeholders(), true)
			_status_card(M286ShipDamageEscalationCatalog.responsive(), true)
			_status_card(M286ShipDamageEscalationCatalog.authority(), true)
			_section("SHIP MOTION IDENTITY · WAKE · WATER · SAIL RESPONSE")
			var motion_identity := get_tree().get_first_node_in_group("ship_motion_identity_readiness") as M287ShipMotionIdentityRuntime
			_status_card(M287ShipMotionIdentityCatalog.overview(motion_identity), true)
			_status_card(M287ShipMotionIdentityCatalog.profiles(), true)
			_status_card(M287ShipMotionIdentityCatalog.wakes(), true)
			_status_card(M287ShipMotionIdentityCatalog.sails(), true)
			_status_card(M287ShipMotionIdentityCatalog.movement_states(), true)
			_status_card(M287ShipMotionIdentityCatalog.responsive(), true)
			_status_card(M287ShipMotionIdentityCatalog.controls(), true)
			_status_card(M287ShipMotionIdentityCatalog.authority(), true)
			_section("NAVAL CONTACT READABILITY · TARGET · THREAT · RANGE")
			var contact_readability := get_tree().get_first_node_in_group("naval_contact_readability_readiness") as M288NavalContactReadabilityRuntime
			_status_card(M288NavalContactReadabilityCatalog.overview(contact_readability), true)
			_status_card(M288NavalContactReadabilityCatalog.relations(), true)
			_status_card(M288NavalContactReadabilityCatalog.targeting(), true)
			_status_card(M288NavalContactReadabilityCatalog.threat_range(), true)
			_status_card(M288NavalContactReadabilityCatalog.priority(), true)
			_status_card(M288NavalContactReadabilityCatalog.offscreen(), true)
			_status_card(M288NavalContactReadabilityCatalog.model_lock(), true)
			_status_card(M288NavalContactReadabilityCatalog.authority(), true)
			_section("PLAYABLE VERTICAL SLICE · CONTENT · NATIVE QA")
			var vertical_slice := get_tree().get_first_node_in_group("playable_vertical_slice_readiness") as M289PlayableVerticalSliceRuntime
			_status_card(M289PlayableVerticalSliceCatalog.overview(vertical_slice), true)
			_status_card(M289PlayableVerticalSliceCatalog.content(), true)
			_status_card(M289PlayableVerticalSliceCatalog.loop(), true)
			_status_card(M289PlayableVerticalSliceCatalog.controls(), true)
			_status_card(M289PlayableVerticalSliceCatalog.combat(), true)
			_status_card(M289PlayableVerticalSliceCatalog.models(), true)
			_status_card(M289PlayableVerticalSliceCatalog.native_qa(vertical_slice), true)
			_status_card(M289PlayableVerticalSliceCatalog.authority(), true)
			_section("FIRST SEA SORTIE · EVENT BINDING · GUIDANCE")
			var first_sortie := get_tree().get_first_node_in_group("first_sortie_integration") as M290FirstSortieIntegrationRuntime
			_status_card(M290FirstSortieCatalog.overview(first_sortie), true)
			_status_card(M290FirstSortieCatalog.event_binding(), true)
			_status_card(M290FirstSortieCatalog.m291_causality(), true)
			_status_card(M290FirstSortieCatalog.m292_guidance(), true)
			_status_card(M290FirstSortieCatalog.m293_world_priority(), true)
			_status_card(M290FirstSortieCatalog.m294_sailing(first_sortie), true)
			_status_card(M290FirstSortieCatalog.guidance(), true)
			_status_card(M290FirstSortieCatalog.models(), true)
			_status_card(M290FirstSortieCatalog.clean_room(), true)
			_status_card(M290FirstSortieCatalog.native_qa(first_sortie), true)
			_status_card(M290FirstSortieCatalog.authority(), true)
		"help":
			_label("Tippen/Klicken aufs Meer: Kurs setzen. Gegner antippen: auswählen. Feuer: Salve auf das gewählte Ziel. Kein automatisches Hinterherfahren.")
			_label("Steuerrad: Kamera verschieben. Zwei Finger: Zoom. ZENTR: Kamera zurück zum Schiff. Desktop zusätzlich WASD, T Zielwechsel, Leertaste Feuer.")
			_label("Zielarchitektur: Android, iOS, Mobile Web, Desktop Web, Windows/macOS/Linux mit gemeinsamem Account/Crossplay. Aktuell bleibt dies ein lokaler Prototyp ohne Server-Authority.")
			_label("Releasekanäle sind architektonisch LOCAL/INTERNAL/TEST/GLOBAL getrennt; dieser Build ist LOCAL_DEVELOPMENT.")
			var local_session:=get_tree().get_first_node_in_group("local_session") as LocalSession
			var auth:=LocalAccountAdapter.new(local_session)
			_label("ACCOUNT BOUNDARY · %s · SERVER VERIFIED: %s"%[auth.state(),str(auth.is_server_verified())])
			_label("AUTH PROVIDER TARGETS · Guest / E-Mail / Google / Apple · Live-Verknüpfung erst mit Backend.")
			var dto:=AccountProfileDto.local_preview(local_session.profile if local_session!=null else {},local_session.guest if local_session!=null else true)
			_label("IDENTITY DTO v%d · %s · revision %d"%[int(dto.get("dto_version",0)),str(dto.get("account_id","")),int(dto.get("revision",0))])
			var tx:=TransactionEnvelope.local("inventory","qa_preview","ship_small",1,0)
			_label("TRANSACTION CONTRACT · idempotent request · revision guard · SERVER VERIFIED: %s"%str(tx.get("server_verified",false)))
			_label("Engine tatsächlich: " + Engine.get_version_info().string + " · Zielversion: 4.7.2, Freigabe separat erforderlich.")
		"log":
			for line in hud.recent_log: _label(line)
		_:
			_label("Online-Funktionen sind noch nicht verbunden. Keine simulierten Spieler, Ranglisten oder LIVE-Anzeigen.")
	show()
	_layout()
	_m249_animate_open()
	if is_instance_valid(content_scroll): content_scroll.scroll_vertical = 0
	# Do not force an OptionButton focus highlight under touch. Keyboard/controller keeps a predictable focus anchor.
	if not InputDeviceProfile.touch_like(hud.layout().safe.size): back_button.grab_focus()

func _m249_animate_open() -> void:
	# M249 presentation-only micro-transition; no gameplay timing or authority depends on it.
	if not is_instance_valid(panel): return
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.985, 0.985)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18)

func _m249_animate_status_card(card: Control) -> void:
	# Short stagger improves hierarchy while avoiding large continuous motion.
	if not is_instance_valid(card): return
	var delay := minf(0.12, float(m249_card_reveal_index) * 0.018)
	m249_card_reveal_index += 1
	card.modulate.a = 0.0
	card.position.x += 5.0 * NauticalTheme.density_scale()
	var target_x := card.position.x - 5.0 * NauticalTheme.density_scale()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(delay)
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(card, "position:x", target_x, 0.14)

func _layout() -> void:
	if not is_instance_valid(panel): return
	var safe: Rect2 = hud.layout().safe
	var sx := NauticalTheme.density_scale()
	var touch_like := InputDeviceProfile.touch_like(safe.size)
	var edge := (8.0 if touch_like else 18.0) * sx
	var policy_width := M202MenuInteractionPolicy.panel_width(safe.size) * sx
	panel.size = Vector2(minf(policy_width, safe.size.x - edge * 2.0), maxf(220.0 * sx, safe.size.y - edge * 2.0))
	if is_instance_valid(quick_navigation): quick_navigation.columns = M202MenuInteractionPolicy.quick_columns(safe.size)
	panel.position = safe.get_center() - panel.size * 0.5

func _button(parent: Node, title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = maxf(_touch_height(), M202MenuInteractionPolicy.touch_height(hud.layout().safe.size) * NauticalTheme.density_scale())
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.clip_text = true
	button.pressed.connect(callback, CONNECT_DEFERRED)
	parent.add_child(button)
	return button

func _requirement_button(parent: Node, title: String, state: Dictionary, callback: Callable) -> void:
	var button:=Button.new()
	button.text=title+" · "+str(state.get("label","Nicht verfügbar"))
	button.disabled=not bool(state.get("ok",false))
	button.custom_minimum_size.y=maxf(_touch_height(),M202MenuInteractionPolicy.touch_height(hud.layout().safe.size)*NauticalTheme.density_scale())
	button.tooltip_text=str(state.get("reason",state.get("label","Nicht verfügbar")))
	button.size_flags_horizontal=SIZE_EXPAND_FILL
	button.clip_text=true
	button.pressed.connect(callback,CONNECT_DEFERRED)
	parent.add_child(button)

func _label(value: String) -> Label:
	return _label_to(body, value)

func _label_to(parent: Node, value: String, font_size := 15, color := NauticalHud.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(font_size * NauticalTheme.density_scale()))
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _touch_height() -> float:
	var safe: Rect2 = hud.layout().safe if hud != null else get_viewport_rect()
	return (56.0 if InputDeviceProfile.touch_like(safe.size) else 50.0) * NauticalTheme.density_scale()

func available_pages() -> Array[String]:
	var result: Array[String] = []
	for id in pages:
		if id == "admin":
			var admin := get_tree().get_first_node_in_group("admin_runtime") as AdminModeRuntime
			var authorization := get_tree().get_first_node_in_group("admin_authorization") as AdminAuthorization
			var local_development := str(get_tree().root.get_meta("environment_id", "")) == "LOCAL_DEVELOPMENT"
			if admin == null or not admin.enabled or (not local_development and (authorization == null or not authorization.surface_allowed())): continue
		result.append(id)
	return result

func navigate(page: String) -> void:
	if page == active_page: return
	if active_page != "": page_history.append(active_page)
	open_page(page)

func go_back() -> void:
	if not page_history.is_empty():
		open_page(page_history.pop_back())
	elif active_page != "home":
		open_page("home")
	else:
		hud.close_menu()

func _status_card(data: Dictionary, show_progress := false) -> void:
	var tone := str(data.get("tone", "info"))
	var accent: Color = {
		"ready": NauticalHud.GREEN,
		"active": NauticalHud.BLUE,
		"warning": NauticalHud.GOLD,
		"danger": NauticalHud.RED,
		"locked": Color(0.38, 0.48, 0.55),
		"info": Color(0.27, 0.72, 0.82)
	}.get(tone, Color(0.27, 0.72, 0.82))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", NauticalHud.panel(Color(0.012, 0.045, 0.065, 0.94), accent, 12.0))
	body.add_child(card)
	var compact_card: bool = InputDeviceProfile.touch_like(hud.layout().safe.size) and hud.layout().safe.size.x < 720.0
	var margin := MarginContainer.new()
	var card_pad := 8 if compact_card else 10
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, card_pad)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var title := _label_to(top, str(data.get("title", "STATUS")).to_upper(), 14 if compact_card else 15, NauticalHud.LIGHT)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var state := _label_to(top, str(data.get("state", "")), 11 if compact_card else 12, accent)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state.clip_text = true
	state.custom_minimum_size.x = minf(152.0 * NauticalTheme.density_scale(), hud.layout().safe.size.x * 0.30)
	_label_to(column, str(data.get("detail", "")), 12 if compact_card else 13, NauticalHud.TEXT)
	if show_progress or data.has("progress"):
		var progress := ProgressBar.new()
		progress.custom_minimum_size.y = 14 * NauticalTheme.density_scale()
		progress.max_value = 1.0
		progress.value = clampf(float(data.get("progress", 0.0)), 0.0, 1.0)
		progress.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = accent
		progress.add_theme_stylebox_override("fill", fill)
		column.add_child(progress)
	_m249_animate_status_card(card)

func _section(value: String) -> void:
	var label := _label(value)
	label.add_theme_font_size_override("font_size", roundi(13 * NauticalTheme.density_scale()))
	label.add_theme_color_override("font_color", NauticalHud.GOLD)

func _tracking_controls(runtime: TrackedQuestRuntime, source: String, quest_id: String, objective_index: int) -> void:
	if runtime == null or quest_id.is_empty(): return
	var selected := runtime.is_tracked(source, quest_id, objective_index)
	_button(body, "NICHT MEHR VERFOLGEN" if selected else "ZIEL VERFOLGEN", func():
		if selected: runtime.untrack()
		else: runtime.track(source, quest_id, objective_index)
		open_page(active_page))
	if selected:
		var has_target := runtime.resolve_target() != null
		_requirement_button(body, "AUF SEEKARTE ANSTEUERN", {"ok":has_target, "label":"KURS SETZEN" if has_target else "KEIN KARTENZIEL"}, func():
			if runtime.navigate_to_target():
				hud.close_menu()
				hud.note_prioritized("KURS AUF VERFOLGTES ZIEL", 3, "navigation", 2400))

func _destination_button(id: String) -> void:
	if id not in available_pages(): return
	var button := _button(body, "%s  ·  %s" % [hud._menu_title(id), _page_context(id)], func(): navigate(id))
	_set_menu_icon(button, id)

func _set_menu_icon(button: Button, page_id: String) -> void:
	var texture := VisualAssetCatalog.texture(M208UnifiedInterfaceCatalog.page_icon_slot(page_id))
	if texture == null: return
	button.icon = texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", roundi(32.0 * NauticalTheme.density_scale()))

func _page_context(id: String) -> String:
	var catalog := get_tree().get_first_node_in_group("m183_command_deck_catalog") as M183CommandDeckCatalog
	if catalog != null: return catalog.context(id)
	return {
		"home":"Alle Bereiche", "progress":"Gebiete, Freischaltungen und Prüfungen", "equipment":"Waffen, Loadouts und Ausbau",
		"bonusmaps":"Instanzen, Zugänge und Belohnungen", "quests":"Aktive und wiederkehrende Aufträge", "events":"Live Objectives und saisonale Inhalte",
		"shop":"Globaler Shop und Itemshop", "bazaar":"Spielerhandel, Listings und Marktpreise", "harbor":"Lokale Dienste und spezielle Hafenaufträge", "social":"Freunde, Fleet-Gruppe und Chat", "guild":"Gilde und Insel", "rankings":"Ruhm, Ehre und Wettbewerb", "achievements":"Erfolge, Sammlungen und Codex", "meta":"Begleiter, Artefakte und begrenzte AFK-Rückkehrboni", "log":"Letzte Ereignisse",
		"systems":"Account, Netzwerk, Telemetrie und Systemstatus", "help":"Steuerung und Einstellungen", "admin":"Autorisierte Werkzeuge"
	}.get(id, "")

func _open_shipyard(return_page: String, ship_id: String) -> void:
	var screen := ShipyardPanel.new()
	get_tree().root.add_child(screen)
	hud.route_panel(screen, return_page)
	screen.open(hud, ship_id)

func _open_progression_track(return_page: String) -> void:
	var screen := ProgressionTrackPanel.new()
	get_tree().root.add_child(screen)
	hud.route_panel(screen, return_page)
	screen.open(hud)

func _open_mastery(return_page: String) -> void:
	var screen := ShipMasteryPanel.new()
	get_tree().root.add_child(screen)
	hud.route_panel(screen, return_page)
	screen.open(hud)

func _process(_delta: float) -> void:
	if visible and is_instance_valid(event_status):
		var runtime := get_tree().get_first_node_in_group("event_runtime") as EventRuntime
		if runtime != null and runtime.is_active():
			event_status.text = runtime.title().to_upper() + " · %d %s · METER %d %%" % [runtime.currency, runtime.currency_label(), roundi(runtime.meter_ratio() * 100.0)]

func _claim(result: Dictionary) -> void:
	hud.note("Noch nicht bereit oder bereits abgeholt" if result.is_empty() else "Belohnung: +%d Gold · +%d EXP" % [result.coins, result.xp])
	open_page(hud.menu_page)

func _result(success: bool, ok_text: String, failure_text: String) -> void:
	hud.note(ok_text if success else failure_text)
	open_page(hud.menu_page)

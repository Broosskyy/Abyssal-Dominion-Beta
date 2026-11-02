class_name M160ProgressionHub
extends Control
## M170 interactive data-driven progression center. Name retained for save/scene compatibility.
var panel:PanelContainer
var body:VBoxContainer
var tab:="decks"
var player:ShipMotor
var hud:GameHud
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;visible=false;set_meta("router_persistent",true)
func open(owner:ShipMotor,owner_hud:GameHud,initial_tab:="decks")->void:
	player=owner;hud=owner_hud;tab=initial_tab
	if hud!=null and hud.routed_panel!=self:hud.route_panel(self,"equipment")
	_rebuild();visible=true;mouse_filter=Control.MOUSE_FILTER_STOP
func toggle()->void:
	if visible:close()
	else:
		var p:=get_tree().get_first_node_in_group("player") as ShipMotor
		var h:=get_tree().get_first_node_in_group("hud") as GameHud
		if p!=null:open(p,h)
func close()->void:
	visible=false;mouse_filter=Control.MOUSE_FILTER_IGNORE
	if hud!=null:hud.complete_routed_panel(self)
func _input(event:InputEvent)->void:
	if visible and event.is_action_pressed("ui_cancel"):
		close();get_viewport().set_input_as_handled()
func _rebuild()->void:
	for c in get_children():c.queue_free()
	var shade:=ColorRect.new();shade.color=Color(0.01,0.02,0.035,0.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
	panel=PanelContainer.new()
	var m167:=get_tree().get_first_node_in_group("m167_ux_content_catalog") as M167UxContentCatalog
	var m168:=get_tree().get_first_node_in_group("m168_runtime_audit_catalog") as M168RuntimeAuditCatalog
	var viewport_size:=get_viewport_rect().size
	var dpi:=float(DisplayServer.screen_get_dpi())
	var profile:=m167.mobile_profile(viewport_size,dpi) if m167!=null else {}
	var margin:=float(profile.get("panel_margin",12.0))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,PRESET_MODE_MINSIZE,margin)
	panel.add_theme_stylebox_override("panel",NauticalHud.box_style());add_child(panel)
	var col:=VBoxContainer.new();panel.add_child(col)
	var header:=HBoxContainer.new();col.add_child(header);_label_to(header,"AUSRÜSTUNG & AUSBAU",true);_button(header,"✕",close)
	var tabs:=HFlowContainer.new();col.add_child(tabs)
	var nav_ids:=["decks","special","cannons","ammo","crafting","talents","citadel","guild","buffs"]
	var compact_tabs:=bool(profile.get("prefer_short_labels",false))
	for id in nav_ids:
		var label=m167.short_tab_label(id) if compact_tabs and m167!=null else id.to_upper()
		if id==tab:label="● "+label
		_button(tabs,label,func(value=id):tab=value;_rebuild())
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body);_content()
func _content()->void:
	if player==null:return
	var inv:=player.get_node("Inventory") as PlayerInventory
	var cat:=get_tree().get_first_node_in_group("m162_system_catalog") as M162SystemCatalog
	var deep:=get_tree().get_first_node_in_group("m163_system_depth_catalog") as M163SystemDepthCatalog
	var m164:=get_tree().get_first_node_in_group("m164_no_code_catalog") as M164NoCodeCatalog
	var m165:=get_tree().get_first_node_in_group("m165_runtime_depth_catalog") as M165RuntimeDepthCatalog
	var m166:=get_tree().get_first_node_in_group("m166_production_depth_catalog") as M166ProductionDepthCatalog
	var m167:=get_tree().get_first_node_in_group("m167_ux_content_catalog") as M167UxContentCatalog
	var m168:=get_tree().get_first_node_in_group("m168_runtime_audit_catalog") as M168RuntimeAuditCatalog
	if cat==null:_label("M162 base catalog fehlt");return
	match tab:
		"decks":
			var deck_level:=inv.deck_level()
			_label("NORMALE DECKS · sichtbar als echter Deckstapel unter dem Schiff · %d/10"%deck_level)
			_presentation_card(M206DeckEquipmentPresentationCatalog.normal_deck_icon_slot(maxi(deck_level,1)),"DECKSTAPEL · %d/10"%deck_level,"%s · Kanonenkapazität %d · jede Stufe ist auch direkt am Schiff ablesbar."%[M206DeckEquipmentPresentationCatalog.normal_deck_stage_label(deck_level),inv.cannon_capacity()])
			_label("Jede Deckstufe erhöht die Kanonenkapazität. Normale Decks bleiben getrennt von Spezialdecks; M206 ändert keine Kapazitäts- oder Kostenwerte.")
			_button(body,"Deck ausbauen · %d Gold"%inv.deck_price(),func():_result(inv.purchase_deck()))
		"special":
			_label("SPEZIALDECKS · eigene Silhouetten, Rollen, VFX und fünf Ausbaustufen")
			_label("Das ausgerüstete Spezialdeck sitzt als zusätzliche visuelle Ebene unter dem normalen Deckstapel und bleibt rein visuell.")
			for row in cat.special_decks():
				var id:=str(row.get("id",""));var level:=inv.special_deck_level(id);var equipped:=inv.equipped_special_deck()==id
				_presentation_card(M206DeckEquipmentPresentationCatalog.special_deck_icon_slot(id),("● AKTIV · " if equipped else "")+str(row.get("label",id)),"Lv.%d/%d · %s · %s"%[level,int(row.get("max_level",5)),str(row.get("role","")),str(row.get("vfx_profile",""))],M206DeckEquipmentPresentationCatalog.special_deck_level_badge(maxi(level,1)))
				if level>0 and not equipped:_button(body,"Ausrüsten",func(deck=id):_result(inv.equip_special_deck(deck)))
				var deck_state:=inv.special_deck_upgrade_status(id)
				_requirement_action("Verbessern",deck_state,func(deck=id):_result(inv.upgrade_special_deck(deck)))
		"cannons":
			_label("KANONEN-AUSBAU · Familien, Qualitätsstufen & vier Mastery-Pfade")
			_label("Jede Kanonenfamilie besitzt eine eigene Silhouette. Mastery-Stufen 1/3/5/7/10 erhalten klar erkennbare visuelle Entwicklungsstufen; Werte/Kosten bleiben datengetrieben.")
			var weapon:=player.get_node("Weapons") as ShipWeapons
			var active_cannon:=CombatCatalog.cannon(weapon.cannon_index)
			var runtime_tier:=CombatCatalog.cannon_upgrade_tier(int(player.progression.upgrades.get("cannon",0)))
			_cannon_summary_card(active_cannon,runtime_tier)
			_label("KANONENFAMILIEN · aktive Familie hervorgehoben")
			for i in CombatCatalog.cannon_count():
				var cannon:=CombatCatalog.cannon(i)
				_cannon_family_card(cannon,i==weapon.cannon_index)
			_label("MASTERY-AUSBAU · sichtbare Stufen 1/3/5/7/10")
			for row in cat.cannon_tracks():
				var id:=str(row.get("id",""));var level:=inv.cannon_track_level(id);var max_level:=int(row.get("max_level",10))
				_cannon_track_card(row,level,max_level)
				_requirement_action("Ausbauen",inv.cannon_track_upgrade_status(id),func(track=id):_result(inv.upgrade_cannon_track(track)))
		"ammo":
			_label("MUNITION & HARPUNEN · M168 Familien, Rollen, Status-Effekte und Raritäten")
			if deep!=null:
				_label("Munition · %d Profile"%deep.ammo_profiles().size())
				for i in CombatCatalog.ammo_count():
					var row:=CombatCatalog.ammo(i);var aid:=str(row.get("id",""));_label("%s · %s · %s"%[row.get("name",row.get("label",aid)),row.get("role",""),aid]);_button(body,"Auswählen",func(idx=i):player.get_node("Weapons").ammo_index=idx;player.get_node("Weapons").select_mode("cannon");_result(true))
				_label("Harpunen · %d Runtime-Profile · aktiv: %s"%[inv.runtime_harpoon_profiles().size(),inv.selected_harpoon()])
				for row in inv.runtime_harpoon_profiles():
					var hid:=str(row.get("id",""));var owned:=inv.count(hid);var active:=inv.selected_harpoon()==hid
					_presentation_card(M206DeckEquipmentPresentationCatalog.harpoon_icon_slot(hid),("● AKTIV · " if active else "")+str(row.get("label",hid)),"%s · x%d · %s"%[str(row.get("family","")),owned,str(row.get("effect",""))])
					if owned>0 and not active:_button(body,"Harpune ausrüsten",func(value=hid):_result(inv.select_harpoon(value)))
			_label("Alle Profile, Statuswerte, Icons, Quellen und Shop-/Loot-Zuordnung bleiben authorbar.")
			if m166!=null:_label("M168 Effekt-Runtime · %d Primitive · Herkunftsgraph · %d Bindings"%[m166.effects().size(),m166.sources().size()])
		"crafting":
			_label("WERKSTATT & HERSTELLUNG · Rezepte, Stationen, Kosten und Outputs datengetrieben")
			if m167!=null:_label("M168 · %d Stations-Ausbaupfade · Herkunfts-/Loot-/Shop-/Quest-Bindings authorbar"%m167.stations().size())
			if m168!=null:
				for station in m168.stations():
					if not station is Dictionary:continue
					var sid:=str(station.get("id",""));var level:=inv.crafting_station_level(sid);var max_level:=int(station.get("max_level",10))
					_label("%s · Stufe %d/%d"%[station.get("label",sid),level,max_level])
					if level<max_level:_button(body,"Station ausbauen · %d Gold"%inv.crafting_station_upgrade_cost(sid),func(value=sid):_result(inv.upgrade_crafting_station(value)))
			if m165!=null:
				var recipes:Array=m166.combined_recipes(m165) if m166!=null else m165.recipes()
				_label("Stationen · %d · Rezepte · %d · Herkunft/Requirements datengetrieben"%[m165.stations().size(),recipes.size()])
				for row in recipes:
					var rid:=str(row.get("id",""));var output:Dictionary=row.get("output",{}) as Dictionary
					var source_text:=""
					if m166!=null:
						var src:=m166.sources_for(str(output.get("id","")))
						if not src.is_empty():source_text=" · Quellen: "+", ".join(PackedStringArray(src))
					_label("%s%s"%[row.get("label",rid),source_text])
					var craft_state:=inv.m165_recipe_status(rid)
					if not bool(craft_state.get("ok",false)):_label("Voraussetzung · "+str(craft_state.get("label","Nicht verfügbar")))
					_button(body,"Herstellen · → %dx %s · %d Gold"%[int(output.get("amount",0)),output.get("id",""),int(row.get("gold",0))],func(value=rid):_result(inv.craft_m165_recipe(value)))
			_label("M244 CRAFTING-KATEGORIEN · "+", ".join(PackedStringArray(M244CraftingSalvageCatalog.categories())))
			_label("ZERLEGEN / SALVAGE · nur ungenutzte, nicht ausgerüstete Regionalmodule · Materialrückgabe vor Commit sichtbar · kein Gold-Refund")
			var salvage_ids:Array=inv.owned_modules.keys()
			salvage_ids.sort()
			if salvage_ids.is_empty():_label("Keine zerlegbaren Regionalmodule im Besitz.")
			for module_id in salvage_ids:
				var definition:=RegionalEquipmentCatalog.module(str(module_id))
				var salvage_state:=inv.m244_salvage_status(str(module_id))
				var return_text:=""
				var returns:Dictionary=salvage_state.get("returns",{}) as Dictionary
				if not returns.is_empty():
					var parts:Array[String]=[]
					for material in returns:parts.append("%s x%d"%[str(material).replace("_"," ").capitalize(),int(returns[material])])
					return_text=" · Rückgabe: "+", ".join(PackedStringArray(parts))
				_label("%s · %s%s"%[definition.get("label",module_id),salvage_state.get("label",""),return_text])
				_button(body,"Zerlegen",func(value=str(module_id)):_result(inv.salvage_regional_module(value)))
		"talents":
			_label("TALENTE · 5 Bäume · 60 Nodes · verfügbare Punkte: %d"%inv.talent_points_unspent)
			for tree in ["navigator","artillery","bulwark","hunter","corsair"]:
				_label(tree.to_upper())
				for row in cat.talent_nodes(tree):
					var id:=str(row.get("id",""));var rank:=inv.talent_rank(id);var title:="%s · %d/%d · %s"%[row.get("label",id),rank,int(row.get("max_rank",1)),row.get("effect_key","")]
					_label(title)
					_requirement_action("Talentpunkt investieren",inv.talent_spend_status(id),func(node_id=id):_result(inv.spend_talent_point(node_id)))
		"citadel":
			_label("KASTELL · sechs Ausbauzweige · je 10 Stufen")
			for row in cat.citadel_branches():
				var id:=str(row.get("id",""));var max_level:=int(row.get("max_level",10))
				_label("%s · %d/%d · %s"%[row.get("label",id),inv.citadel_level(id),max_level,row.get("focus","")])
				_requirement_action("Kastell ausbauen",inv.citadel_upgrade_status(id),func(branch=id):_result(inv.upgrade_citadel(branch)))
		"guild":
			_label("GILDE & GILDENINSEL · Ausbau, Ränge, Kasse, Verteidigung und Belagerung")
			if m167!=null:_label("M168 · Mobile-Interaktionsvertrag aktiv · kritische Mutationen bleiben serverseitig")
			if deep!=null:
				var gd:=deep.guild_data()
				_label("Ränge · %d · datengetriebene Rechte"%(gd.get("ranks",[]) as Array).size())
				for row in deep.guild_rows("ranks"):_label("%s · Priorität %d · %d Rechte"%[row.get("label",row.get("id","")),int(row.get("priority",0)),(row.get("permissions",[]) as Array).size()])
				_label("Gebäude · %d · jeweils bis Stufe 10"%deep.guild_rows("buildings").size())
				if m164!=null:_label("M168 Inselmodule · %d · Upgrade-Kurven + Turm-Spezialisierungen datengetrieben · Live-Bau serverautoritativ"%m164.guild_modules().size())
				for row in deep.guild_rows("buildings"):_label("%s · %s · visuelle Ausbauphasen %s"%[row.get("label",row.get("id","")),row.get("role",""),str(row.get("visual_stages",[]))])
				if m165!=null:_label("Turm-Spezialisierungsbäume · %d · Freischaltungen auf Lv.4/8"%m165.tower_specializations().size())
				_label("Türme · %d · Kanone/Kette/Mörser/Ward/Jäger"%deep.guild_rows("towers").size())
			_label("Kasse, Krieg, Besitzwechsel und echte Bauaufträge bleiben serverautoritativ + auditierbar.")
		"buffs":
			_label("SEGEN & EFFEKTE · Kristallsegen, Spezialdeck-VFX, Gilden-/Event-Auren, Wards und Debuffs")
			_button(body,"Kristallsegen aktivieren",func():_result(inv.activate_crystal_blessing()))
			_label("Icons, Tooltip, Animation und VFX-Profil sind austauschbare Content-/Asset-Slots.")
			if deep!=null:
				_label("M168 Effekt-/Materialkatalog · %d Einträge"%deep.consumables().size())
				for row in deep.consumables():
					if int(row.get("duration",0))>0:
						var iid:=str(row.get("id",""));_button(body,"%s · x%d · %ss"%[row.get("label",iid),inv.count(iid),int(row.get("duration",0))],func(value=iid):_result(inv.m163_consume_effect_item(value)))

func _icon_texture(slot:String)->Texture2D:
	return VisualAssetCatalog.texture(slot)

func _presentation_card(icon_slot:String,title:String,detail:String,badge_slot:String="")->void:
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",NauticalTheme.graphic_style("card"));body.add_child(card)
	var row:=HBoxContainer.new();card.add_child(row)
	var texture:=_icon_texture(icon_slot)
	if texture!=null:
		var icon:=TextureRect.new();icon.texture=texture;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(72,64)*NauticalTheme.density_scale();row.add_child(icon)
	var col:=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col)
	var t:=Label.new();t.text=title;t.add_theme_color_override("font_color",NauticalHud.GOLD);t.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(t)
	var d:=Label.new();d.text=detail;d.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(d)
	if not badge_slot.is_empty():
		var badge_tex:=_icon_texture(badge_slot)
		if badge_tex!=null:
			var badge:=TextureRect.new();badge.texture=badge_tex;badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;badge.custom_minimum_size=Vector2(56,56)*NauticalTheme.density_scale();row.add_child(badge)

func _cannon_summary_card(cannon:Dictionary,tier:Dictionary)->void:
	var id:=str(cannon.get("id","naval_cannon"));var role:=CombatCatalog.cannon_role_profile(cannon);var tier_id:=int(tier.get("tier",1))
	_presentation_card(M205CannonPresentationCatalog.cannon_icon_slot(id),"AKTIV · %s"%str(cannon.get("name",id)),"Rolle: %s · Qualitätsstufe %d %s\nStärke: %s · Trade-off: %s"%[str(cannon.get("role","balanced")).to_upper(),tier_id,str(tier.get("label","")),str(role.get("strength","flexible")),str(role.get("tradeoff","none"))],M205CannonPresentationCatalog.quality_tier_icon_slot(tier_id))

func _cannon_family_card(cannon:Dictionary,active:bool)->void:
	var id:=str(cannon.get("id","naval_cannon"));var role:=CombatCatalog.cannon_role_profile(cannon)
	_presentation_card(M205CannonPresentationCatalog.cannon_icon_slot(id),("● " if active else "")+str(cannon.get("name",id)),"%s · Freischaltung PL %d · %s"%[str(cannon.get("role","balanced")).to_upper(),int(cannon.get("unlock_level",1)),str(role.get("strength","flexible"))])

func _cannon_track_card(track:Dictionary,level:int,max_level:int)->void:
	var id:=str(track.get("id","barrel"))
	_presentation_card(M205CannonPresentationCatalog.track_icon_slot(id,level),"%s · %d/%d"%[str(track.get("label",id)),level,max_level],"%s · %s"%[str(track.get("effect","")),M205CannonPresentationCatalog.track_stage_label(level)])

func _requirement_action(action_label:String,state:Dictionary,cb:Callable)->void:
	var ok:=bool(state.get("ok",false));var status:=str(state.get("label","Nicht verfügbar"))
	var suffix:=" · "+status
	var b:=Button.new();b.text=action_label+suffix;b.disabled=not ok
	var min_touch:=56.0
	var m167:=get_tree().get_first_node_in_group("m167_ux_content_catalog") as M167UxContentCatalog
	if m167!=null:
		var prof:=m167.mobile_profile(get_viewport_rect().size,float(DisplayServer.screen_get_dpi()));min_touch=maxf(56.0,float(prof.get("touch_target",56.0)))
	b.custom_minimum_size.y=min_touch*NauticalTheme.density_scale();b.pressed.connect(cb);body.add_child(b)
func _label(text:String)->void:_label_to(body,text,false)
func _label_to(parent:Control,text:String,expand:bool=false)->void:
	var l:=Label.new()
	l.text=text
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if expand:
		l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(l)
func _button(parent:Control,text:String,cb:Callable)->void:
	var b:=Button.new();b.text=text
	var min_touch:=56.0
	var m167:=get_tree().get_first_node_in_group("m167_ux_content_catalog") as M167UxContentCatalog
	if m167!=null:
		var prof:=m167.mobile_profile(get_viewport_rect().size,float(DisplayServer.screen_get_dpi()))
		min_touch=maxf(56.0,float(prof.get("touch_target",56.0)))
	b.custom_minimum_size.y=min_touch*NauticalTheme.density_scale();b.pressed.connect(cb);parent.add_child(b)
func _result(ok:bool)->void:
	if hud!=null:hud.note("Erfolgreich" if ok else "Voraussetzungen, Hafen, Ressourcen oder Freischaltung prüfen")
	_rebuild()

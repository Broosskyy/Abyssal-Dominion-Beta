extends Control
## Update gate → welcome/auth → captain harbor → chart loading → actual sea.
const SIM=preload("res://simulation.gd")
const WORLD_CHART=preload("res://world_chart.gd")
const PARCHMENT=preload("res://assets/ui/painted/chart_parchment.jpg")
const NETWORK=preload("res://network_client.gd")
const SKIN=preload("res://ui_skin.gd")
const SAVE="user://captain_m3052.json"
const CONFIG="user://connection.json"
const ART=preload("res://assets/world_v2/frontier_splash.png")
const NEWS_HARBOR=preload("res://assets/ui/painted/loading_harbor.jpg")
const NEWS_KESSEL=preload("res://assets/ui/painted/kessel_scene.jpg")
const NEWS_CHART=preload("res://assets/ui/painted/chart_parchment.jpg")
const DAILY_CHEST=preload("res://assets/ui/painted/reward_chest.png")
const NEWS_FRAMES=[
	{"title":"DIE SCHATTENGEWÄSSER RUFEN","tag":"WELT & ABENTEUER","description":"Erkunde 40 Seekarten, kämpfe gegen Seeungeheuer und entdecke die befahrbaren Inselhäfen.","art":0,"action":"Seekarten","button":"WELTKARTE ÖFFNEN"},
	{"title":"WERFT & MARKTPLATZ","tag":"DEIN SCHIFF","description":"Rüste Geschütze aus, entdecke Schiffsdesigns und bereite dich auf die nächste große Seeschlacht vor.","art":1,"action":"Werft","button":"ZUR WERFT"},
	{"title":"GEZEITENKESSEL & BONUSKARTEN","tag":"BELOHNUNGEN","description":"Sammle Bonuskartenfragmente, stelle Schriftrollen zusammen und kämpfe dich durch fünf Wellen.","art":2,"action":"Bonuskarten","button":"BONUSKARTEN ÖFFNEN"},
	{"title":"ERKUNDE DEINE WELTKARTE","tag":"SEEKARTEN","description":"Von den Küsten bis zu den Schattengewässern: Deine Route bestimmst du selbst.","art":3,"action":"start","button":"JETZT IN SEE STECHEN"}
]
const FRIEND_SHARE_URL="https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases"
var sea_time := 0.0
var backdrop: TextureRect
var sim=SIM.new()
var network: Node
var panel: Panel
var scroll: ScrollContainer
var body: VBoxContainer
var page := "welcome"
var registration := false
var status_text := ""
var email: LineEdit
var password: LineEdit
var username: LineEdit
var server_field: LineEdit
var chart_chapter := 0
var chart_pick := 0
var featured_index := 0
var home_landscape := false
var featured_seconds := 0.0
var featured_image: TextureRect
var featured_title: Label
var featured_tag: Label
var featured_detail: Label
var featured_position: Label
var featured_action: Button
var home_section := "ABENTEUER"
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop=TextureRect.new();backdrop.name="LivingHarbor"
	backdrop.texture=ART;backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;backdrop.show_behind_parent=true
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sea=ShaderMaterial.new();sea.shader=preload("res://harbor_backdrop.gdshader");backdrop.material=sea
	add_child(backdrop)
	if FileAccess.file_exists(SAVE):
		var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		if value is Dictionary:sim.restore_save(value)
	_save() # Commit offline accrual before any button can claim it.
	chart_chapter=maxi(0,sim.CONTENT.SEA_MAP_IDS.find(sim.map_id))/10;chart_pick=sim.map_id
	network=NETWORK.new();add_child(network)
	network.auth_completed.connect(_authenticated)
	if FileAccess.file_exists(CONFIG):
		var config: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if config is Dictionary:network.server_url=str(config.get("server_url",""))
	# A plain Panel does NOT derive its minimum size from the long dashboard.
	# PanelContainer did and could overflow 480px portrait screens by 2x.
	panel=Panel.new();panel.name="CaptainPanel";add_child(panel)
	panel.add_theme_stylebox_override("panel",SKIN.card())
	# A PanelContainer must size to the viewport, NOT to the combined
	# minimum size of a long dashboard. A neutral Control wrapper absorbs
	# the ScrollContainer content minimum on rotated/portrait phones.
	var scroll_view=Control.new()
	scroll_view.name="CaptainScrollViewport"
	scroll_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll_view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll_view.clip_contents=true
	panel.add_child(scroll_view)
	scroll_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_view.offset_left=10
	scroll_view.offset_top=10
	scroll_view.offset_right=-10
	scroll_view.offset_bottom=-10
	scroll=preload("res://touch_scroll.gd").new()
	scroll.name="CaptainContentScroll"
	scroll_view.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	get_viewport().size_changed.connect(_layout)
	page="home" if get_tree().get_meta("abyssal_entered",false) else "welcome"
	_show(page);_layout()
	var boot=get_tree().root.get_node_or_null("DataBoot")
	if boot!=null:boot.mark_healthy()
func _process(delta: float) -> void:
	sea_time+=delta
	if backdrop!=null:backdrop.material.set_shader_parameter("sea_time",sea_time)
	if page=="home" and is_instance_valid(featured_image):
		featured_seconds+=delta
		if featured_seconds>=9.0:
			featured_seconds=0.0
			_featured_shift(1)

func _layout() -> void:
	if panel==null:return
	var viewport_size: Vector2=get_viewport_rect().size
	var ui_scale: float=clampf(minf(viewport_size.x,viewport_size.y)/600.0,1.0,1.8)
	panel.scale=Vector2.ONE*ui_scale
	var dimensions: Vector2=viewport_size/ui_scale
	var wide: bool=dimensions.x>dimensions.y*1.35
	# Rebuild the feature from side-by-side landscape to stacked portrait.
	# Keeping the old HBox on rotation forces the 370px artwork and copy
	# to expand the whole panel past the screen's safe area.
	if page=="home" and is_instance_valid(featured_image) and home_landscape!=wide:
		_show("home")
		return
	var dashboard: bool=page in ["home","rewards","friends","maps","guild","profile"]
	if dashboard:
		panel.size=Vector2(minf(1180.0,dimensions.x-28.0),minf(780.0,dimensions.y-36.0) if wide else minf(950.0,dimensions.y-40.0))
		panel.position=((dimensions-panel.size)*.5)*ui_scale
	else:
		panel.size=Vector2(minf(520.0,dimensions.x-32.0),minf(maxf(180.0,body.get_combined_minimum_size().y+24.0),minf(760.0,dimensions.y-48.0)))
		var local_position: Vector2=Vector2(dimensions.x-panel.size.x-32.0,(dimensions.y-panel.size.y)*.5) if wide and dimensions.x>920 else (dimensions-panel.size)*.5
		panel.position=local_position*ui_scale
	queue_redraw()
func _draw() -> void:
	var dimensions: Vector2=get_viewport_rect().size

	if dimensions.x>920 and dimensions.x>dimensions.y*1.35:
		var font: Font=ThemeDB.fallback_font
		var fs: int=clampi(roundi(dimensions.x*.028),26,52)
		draw_string_outline(font,Vector2(36,dimensions.y*.17),"ABYSSAL",HORIZONTAL_ALIGNMENT_LEFT,-1,fs,6,Color("07111e"))
		draw_string(font,Vector2(36,dimensions.y*.17),"ABYSSAL",HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("f2d69c"))
		draw_string(font,Vector2(38,dimensions.y*.17+fs*.8),"D O M I N I O N",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(fs*.55),Color("f2d69c"))
func _label(text: String,heading: bool=false) -> Label:
	var label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",24 if heading else 16)
	label.add_theme_color_override("font_color",Color("f0d496") if heading else Color("c3d5dd"));body.add_child(label)
	return label
func _button(text: String,callback: Callable,primary: bool=false) -> Button:
	var button=Button.new();button.text=text;button.custom_minimum_size.y=48;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	SKIN.dress(button,"primary" if primary else "normal",16);body.add_child(button);button.pressed.connect(callback)
	return button
# Shared dashboard components. All touch surfaces are at least 48 px high
# in logical coordinates, with automatic 2-column portrait layouts.
func _hint(parent: Node,message: String,size: int=14,color: Color=Color("c3d5dd")) -> Label:
	var label=Label.new()
	label.text=message
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _dashboard_grid(wide_columns: int=4) -> GridContainer:
	var grid=GridContainer.new()
	var size: Vector2=get_viewport_rect().size
	# Large art/cards use only one column on small logical phone widths.
	# Stat chips deliberately use their own compact two-column grid.
	grid.columns=wide_columns if size.x>size.y*1.3 else (1 if size.x<620.0 and wide_columns>=3 else 2)
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	return grid

func _dashboard_button(parent: Node,label: String,callback: Callable,primary: bool=false) -> Button:
	var button=Button.new()
	button.text=label
	button.custom_minimum_size=Vector2(0,52)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size",14)
	SKIN.dress(button,"primary" if primary else "normal",9.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _dashboard_card(parent: Node,heading: String,detail: String,callback: Callable,image: Texture2D=null) -> PanelContainer:
	var panel_card=PanelContainer.new()
	panel_card.name="HomeActionCard_"+heading.replace(" ","_").replace("&","UND")
	panel_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel_card.add_theme_stylebox_override("panel",SKIN.card(Color("a88c59")))
	parent.add_child(panel_card)
	var stack=VBoxContainer.new()
	stack.add_theme_constant_override("separation",7)
	panel_card.add_child(stack)
	if image!=null:
		var preview=TextureRect.new()
		preview.texture=image
		preview.name="HomeActionArt"
		preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.custom_minimum_size=Vector2(0,76)
		preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(preview)
	var caption=_hint(stack,heading,16,Color("f5db9a"))
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var copy=_hint(stack,detail,12)
	copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_dashboard_button(stack,"ÖFFNEN",callback)
	return panel_card

func _featured_shift(direction: int) -> void:
	featured_index=posmod(featured_index+direction,NEWS_FRAMES.size())
	featured_seconds=0.0
	if not is_instance_valid(featured_image):return
	var spec: Dictionary=NEWS_FRAMES[featured_index]
	featured_image.texture=[ART,NEWS_HARBOR,NEWS_KESSEL,NEWS_CHART][int(spec.art)]
	featured_title.text=str(spec.title)
	featured_tag.text=str(spec.tag)
	featured_detail.text=str(spec.description)
	featured_position.text="%d / %d" % [featured_index+1,NEWS_FRAMES.size()]
	if is_instance_valid(featured_action):
		featured_action.text=str(spec.button)

func _invite_text() -> String:
	# Share a real, reachable download page; do not invent referral rewards
	# or expose private account identifiers without a server-backed opt-in.
	return "Komm mit mir auf See bei Abyssal Dominion! Teste die Beta und werde Piratenkapitän: "+FRIEND_SHARE_URL

func _copy_invite() -> void:
	DisplayServer.clipboard_set(_invite_text())
	status_text="Spielelink in die Zwischenablage kopiert. Du kannst ihn in WhatsApp, Discord oder anderen Apps teilen."
	_show("friends")

# An original illustrated news-first home inspired by classic sea MMO
# information hubs. Promotions are only links to real existing game areas;
# no fake payment offers, server events or referral rewards are displayed.
func _home_nav() -> void:
	# Ordinary Control wrapper prevents the 6-button HBox minimum width
	# propagating into the modal PanelContainer on portrait phones.
	var viewport=Control.new()
	viewport.name="HomeNavViewport"
	viewport.custom_minimum_size.y=60
	viewport.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	viewport.clip_contents=true
	body.add_child(viewport)
	var swipe=ScrollContainer.new()
	swipe.name="HomeNavigationScroller"
	swipe.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	swipe.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	swipe.follow_focus=true
	swipe.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	viewport.add_child(swipe)
	swipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var items=HBoxContainer.new()
	items.add_theme_constant_override("separation",8)
	swipe.add_child(items)
	for option in [["STARTSEITE","home"],["BELOHNUNGEN","rewards"],["FREUNDE","friends"],["LOGBUCH","logbook"],["WELTKARTE","maps"],["PROFIL","profile"]]:
		var destination: String=str(option[1])
		var action=_dashboard_button(items,str(option[0]),func():_show(destination),destination=="home")
		action.name="HubTab_"+destination
		action.custom_minimum_size.x=138

func _activate_featured() -> void:
	var destination: String=str(NEWS_FRAMES[featured_index].get("action","start"))
	if destination=="start":_sail()
	else:_sail_menu(destination)

func _switch_home_section(section: String) -> void:
	if not section in ["ABENTEUER","SCHIFF & HANDEL","KAPITÄN & BONUS"]:return
	home_section=section
	_show("home")

func _show_home() -> void:
	_label("ABYSSAL DOMINION · KAPITÄNSHAFEN",true)
	var summary=_hint(body,"%s  ·  LV. %d  ·  SEEKARTE %s  ·  %s" % [sim.captain_name,sim.level,sim.CONTENT.MAPS[sim.map_id].code,"ONLINE" if not network.account.is_empty() else "LOKALE BETA"],14)
	summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_home_nav()
	_label("AKTUELL AUF DEN MEEREN",true)
	var hero=PanelContainer.new()
	hero.name="FeaturedNews"
	hero.add_theme_stylebox_override("panel",SKIN.card(Color("d9b16c")))
	hero.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(hero)
	var wide: bool=get_viewport_rect().size.x>get_viewport_rect().size.y*1.35
	home_landscape=wide
	var content: BoxContainer=HBoxContainer.new() if wide else VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	hero.add_child(content)
	featured_image=TextureRect.new()
	featured_image.name="FeaturedArtwork"
	featured_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	featured_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	featured_image.custom_minimum_size=Vector2(370,214) if wide else Vector2(0,180)
	featured_image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	featured_image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(featured_image)
	var copy=VBoxContainer.new()
	copy.add_theme_constant_override("separation",8)
	copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_child(copy)
	featured_tag=_hint(copy,"",12,Color("a7d5cb"))
	featured_title=_hint(copy,"",21,Color("f4d595"))
	featured_detail=_hint(copy,"",14)
	featured_action=_dashboard_button(copy,"",_activate_featured,true)
	featured_action.name="FeaturedAction"
	var nav=HBoxContainer.new()
	nav.add_theme_constant_override("separation",8)
	copy.add_child(nav)
	_dashboard_button(nav,"‹",func():_featured_shift(-1))
	featured_position=_hint(nav,"1 / 4",13,Color("e1c38a"))
	featured_position.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	featured_position.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_dashboard_button(nav,"›",func():_featured_shift(1))
	_featured_shift(0)
	var start_action=_button("JETZT SPIELEN · ZUR SEEKARTE",_sail,true)
	start_action.name="SailButton"
	start_action.custom_minimum_size.y=56
	# Compact teaser row, the equivalent of the three small news cards in
	# the reference. All actions open real features from the current game.
	_label("ENTDECKEN & VORBEREITEN",true)
	var teasers=_dashboard_grid(3)
	_dashboard_card(teasers,"NEUE SCHIFFSDESIGNS","Schiffe & Kanonen",func():_sail_menu("Werft"),NEWS_HARBOR)
	_dashboard_card(teasers,"GEZEITENKESSEL","Fragmente & Belohnungen",func():_sail_menu("Kessel"),NEWS_KESSEL)
	_dashboard_card(teasers,"SAISONPASS","Kostenlose Stufen",func():_sail_menu("Battle Pass"),DAILY_CHEST)
	# Daily rewards are existing ledger-backed systems, not a new wallet.
	var daily_pending: bool=sim.rewards.daily_available()
	var daily=PanelContainer.new()
	daily.name="DailyStatusBanner"
	daily.add_theme_stylebox_override("panel",SKIN.card(Color("77bda1") if daily_pending else Color("778591")))
	body.add_child(daily)
	var daily_row=HBoxContainer.new()
	daily_row.add_theme_constant_override("separation",10)
	daily.add_child(daily_row)
	var daily_info=VBoxContainer.new()
	daily_info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	daily_row.add_child(daily_info)
	_hint(daily_info,"TAGESBONUS BEREIT" if daily_pending else "TAGESBONUS ABGEHOLT",16,Color("f1d7a0"))
	_hint(daily_info,"7-Tage-Serie · AFK-Beute · " + ("Heute abholbar" if daily_pending else "Nächste Abholung ab 00:00 UTC"),12)
	var daily_open=_dashboard_button(daily_row,"ABHOLEN" if daily_pending else "ANSEHEN",func():_show("rewards"),daily_pending)
	daily_open.name="HomeDailyButton"
	daily_open.custom_minimum_size.x=118
	# Separate, swipeable groups avoid forcing every menu into an enormous
	# lobby wall. The shared menu content remains available via the sea HUD.
	_label("DEINE SPIELBEREICHE",true)
	var section_view=Control.new()
	section_view.name="HomeSectionsViewport"
	section_view.custom_minimum_size.y=58
	section_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	section_view.clip_contents=true
	body.add_child(section_view)
	var section_scroll=ScrollContainer.new()
	section_scroll.name="HomeSectionScroller"
	section_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	section_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	section_scroll.follow_focus=true
	section_view.add_child(section_scroll)
	section_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sections=HBoxContainer.new()
	sections.name="HomeSections"
	sections.add_theme_constant_override("separation",6)
	section_scroll.add_child(sections)
	for section in ["ABENTEUER","SCHIFF & HANDEL","KAPITÄN & BONUS"]:
		var choice: String=section
		var tab=_dashboard_button(sections,section,func():_switch_home_section(choice),home_section==section)
		tab.name="HomeSection_"+section.replace(" ","_").replace("&","UND")
		tab.custom_minimum_size=Vector2(152,52)
	var tiles=_dashboard_grid(3)
	match home_section:
		"ABENTEUER":
			_dashboard_card(tiles,"SEEKARTEN","40 Karten & Portale",func():_show("maps"),NEWS_CHART)
			_dashboard_card(tiles,"MONSTERJAGD","Seeungeheuer & Harpunen",func():_sail_menu("Monster"),ART)
			_dashboard_card(tiles,"BONUSKARTEN","Fragmente & fünf Wellen",func():_sail_menu("Bonuskarten"),NEWS_CHART)
			_dashboard_card(tiles,"GILDE & INSEL","Heimatbasis & Belagerungen",func():_show("guild"),NEWS_HARBOR)
			_dashboard_card(tiles,"LOGBUCH","Aufträge & Fortschritt",func():_show("logbook"),NEWS_CHART)
			_dashboard_card(tiles,"EVENTS","Saisoninhalte ansehen",func():_sail_menu("Events"),NEWS_KESSEL)
		"SCHIFF & HANDEL":
			_dashboard_card(tiles,"SCHIFFSWERFT","Designs & Kanonenmontage",func():_sail_menu("Werft"),NEWS_HARBOR)
			_dashboard_card(tiles,"MARKTPLATZ","Munition & Items",func():_sail_menu("Markt"),NEWS_CHART)
			_dashboard_card(tiles,"DECKS & LAGER","Gold-, Elite- & Sonderdecks",func():_sail_menu("Decks"),DAILY_CHEST)
			_dashboard_card(tiles,"KASTELLE & TALENTE","Schiffsausbau & Punkte",func():_sail_menu("Kastelle"),ART)
			_dashboard_card(tiles,"ARSENAL","Geschütze & Montage",func():_sail_menu("Bewaffnung"),NEWS_HARBOR)
			_dashboard_card(tiles,"GEZEITENKESSEL","Essenz & Glück",func():_sail_menu("Kessel"),NEWS_KESSEL)
		_:
			_dashboard_card(tiles,"TAGESBONUS & AFK","Echte lokale Belohnungen",func():_show("rewards"),DAILY_CHEST)
			_dashboard_card(tiles,"FREUNDE EINLADEN","Teilbarer Beta-Link",func():_show("friends"),NEWS_CHART)
			_dashboard_card(tiles,"SAISONPASS","Kostenlose Belohnungsstufen",func():_sail_menu("Battle Pass"),DAILY_CHEST)
			_dashboard_card(tiles,"SPIELERPROFIL","Name, Rang & Battle Points",func():_show("profile"),ART)
			_dashboard_card(tiles,"KRONEN-SHOP","Echtgeldkäufe noch gesperrt",func():_sail_menu("Premium-Shop"),NEWS_HARBOR)
			_dashboard_card(tiles,"EINSTELLUNGEN","Server, Konto & Updater",func():_show("settings"),NEWS_KESSEL)
	var stats=_dashboard_grid(4)
	if get_viewport_rect().size.x<620.0:stats.columns=2
	for entry in [["GOLD",_coins(int(sim.player.gold))],["ESSENZ",str(sim.essence)],["STUFE",str(sim.level)],["BATTLE POINTS",str(sim.battle_points)]]:
		var stat_card=PanelContainer.new()
		stat_card.add_theme_stylebox_override("panel",SKIN.card(Color("b7985e")))
		stat_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		stats.add_child(stat_card)
		var stack=VBoxContainer.new()
		stat_card.add_child(stack)
		var stat_name=_hint(stack,str(entry[0]),11,Color("a8bec1"))
		stat_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var value=_hint(stack,str(entry[1]),16,Color("f5dcab"))
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _coins(value: int) -> String:
	var digits: String=str(maxi(0,value))
	var out: String=""
	while digits.length()>3:
		out="."+digits.right(3)+out
		digits=digits.left(digits.length()-3)
	return digits+out

func _show_daily_rewards() -> void:
	_label("TÄGLICHE BELOHNUNGEN",true)
	_hint(body,"Sieben Tage in Folge abholen. Wechsel täglich um 00:00 UTC. Die Beträge werden aus der vorhandenen lokalen Belohnungsverwaltung vergeben.",14)
	var available: bool=sim.rewards.daily_available()
	var today: int=floori(float(Time.get_unix_time_from_system())/86400.0)
	var next_day: int=(sim.rewards.streak%7)+1 if sim.rewards.last_claim_day==today-1 else 1
	if not available:next_day=sim.rewards.streak
	# All seven days stay in one swipeable reward strip on phones instead
	# of producing four tall stacked rows that hide the claim button.
	var calendar_view=Control.new()
	calendar_view.name="DailyCalendarViewport"
	calendar_view.custom_minimum_size.y=214
	calendar_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	calendar_view.clip_contents=true
	body.add_child(calendar_view)
	var calendar=ScrollContainer.new()
	calendar.name="DailyCalendarScroller"
	calendar.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	calendar.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	calendar.follow_focus=true
	calendar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	calendar_view.add_child(calendar)
	calendar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board=HBoxContainer.new()
	board.add_theme_constant_override("separation",8)
	calendar.add_child(board)
	for day in 7:
		var position: int=day+1
		var accent: Color=Color("e8be6d") if position==next_day else Color("65838b")
		var tile=PanelContainer.new()
		tile.name="DailyDay"+str(position)
		tile.custom_minimum_size=Vector2(136,200)
		tile.add_theme_stylebox_override("panel",SKIN.card(accent))
		board.add_child(tile)
		var stack=VBoxContainer.new()
		stack.add_theme_constant_override("separation",5)
		tile.add_child(stack)
		var name=_hint(stack,"TAG %d" % position,15,Color("f5d89c"))
		name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var gold=_hint(stack,"%d GOLD" % (100+position*50),13)
		gold.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var icon=TextureRect.new()
		icon.texture=DAILY_CHEST
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size=Vector2(0,70)
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(icon)
		_hint(stack,"+%d ESSENZ" % (2 if position==7 else 1),12,Color("a8d9cb")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var marker=_hint(stack,"BEREIT" if available and position==next_day else ("HEUTE GEHOLT" if position==next_day else "SERIENBONUS"),11,accent)
		marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var daily=_button("TAGESBONUS ABHOLEN · TAG %d" % next_day if available else "HEUTE BEREITS ABGEHOLT",func():
		if sim.rewards.claim_daily(sim):
			_save()
		_show("rewards"),true)
	daily.name="DailyClaim"
	daily.custom_minimum_size.y=58
	daily.disabled=not available
	_label("AFK-BEUTE",true)
	_hint(body,"Bis zu 8 Stunden gesammelt · %s Gold verfügbar. Beim Abholen erhältst du auch Vollkugeln." % _coins(sim.rewards.afk_gold()),14)
	var afk=_button("AFK-BEUTE ABHOLEN",func():
		if sim.rewards.claim_afk(sim):
			_save()
		_show("rewards"),true)
	afk.name="AfkClaim"
	afk.disabled=sim.rewards.afk_gold()<=0
	_hint(body,"Diese Beta-Belohnungen werden lokal gespeichert und sind noch kein übertragbarer Online-Kontostand.",12)
	_back()

func _show_friends() -> void:
	_label("FREUNDE & EINLADUNGEN",true)
	_hint(body,"Lade Freunde zur Abyssal-Dominion-Beta ein und erkundet später dieselben Seekarten im Crossplay. Der Einladungslink funktioniert schon jetzt.",15)
	var image=TextureRect.new()
	image.texture=NEWS_HARBOR
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size=Vector2(0,160)
	image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(image)
	_label("BETA MIT FREUNDEN TEILEN",true)
	_hint(body,FRIEND_SHARE_URL,13,Color("aadbd7"))
	_button("EINLADUNG KOPIEREN",_copy_invite,true).name="InviteCopy"
	if not status_text.is_empty() and status_text.contains("Spielelink"):
		_hint(body,status_text,13,Color("a6dfbd"))
	_label("FREUNDESLISTE & EMPFEHLUNGEN",true)
	_hint(body,"Freundesliste, Freundschaftsanfragen, Gruppen und echte Einladungsbelohnungen erfordern registrierte Konten und einen gemeinsamen Server. In der lokalen Beta werden keine Freunde oder Referral-Boni vorgetäuscht.",13)
	var locked=_button("FREUNDESLISTE · ONLINE FOLGT",func():pass)
	locked.disabled=true
	_back()

func _field(hint: String,secret: bool=false) -> LineEdit:
	var input=LineEdit.new();input.placeholder_text=hint;input.secret=secret;input.custom_minimum_size.y=48;input.max_length=128 if secret else 80;body.add_child(input)
	return input
func _show(next: String) -> void:
	page=next
	for child in body.get_children():body.remove_child(child);child.queue_free()
	scroll.scroll_vertical=0
	match page:
		"welcome":
			_label("ABYSSAL DOMINION",true)
			_label("Dein Schiff. Deine Gilde. Dein Meer.")
			_button("ANMELDEN",func():registration=false;_show("auth"),true)
			_button("KONTO ERSTELLEN",func():registration=true;_show("auth"))
			_button("ALS GAST WEITERSPIELEN",_enter_home)
			_button("VERBINDUNG & EINSTELLUNGEN",func():_show("settings"))
		"auth":
			_label("KONTO ERSTELLEN" if registration else "WILLKOMMEN ZURÜCK",true)
			if registration:username=_field("Spielername · 3 bis 24 Zeichen")
			email=_field("E-Mail");password=_field("Passwort · mindestens 10 Zeichen",true)
			var notice=_label(status_text if not status_text.is_empty() else ("Beta-Server verbunden" if not network.server_url.is_empty() else "Beta-Server noch nicht verbunden · Gastspiel verfügbar"))
			notice.name="AuthStatus"
			_button("REGISTRIEREN" if registration else "ANMELDEN",func():
				notice.text="Anmeldung wird geprüft …"
				network.authenticate(email.text,password.text,username.text if registration else "",registration),true)
			_button("ZURÜCK",func():_show("welcome"))
		"home":
			_show_home()
		"rewards":
			_show_daily_rewards()
		"friends":
			_show_friends()
		"logbook":
			_label("KAPITÄNSLOGBUCH",true)
			_hint(body,"Deine bisherige Fahrt, Siege und Belohnungen. Detaillierte Aufträge und tägliche Missionen findest du auf der Seekarte.",14)
			var ledger=_dashboard_grid(2)
			for detail in [["VERSENKTE SCHIFFE",str(sim.kills)],["SEEUNGEHEUER",str(sim.monster_kills)],["BONUSKARTEN",str(sim.bonus_runs)],["BATTLE POINTS",str(sim.battle_points)]]:
				var card=PanelContainer.new();card.add_theme_stylebox_override("panel",SKIN.card(Color("a78d5c")));ledger.add_child(card)
				var info=VBoxContainer.new();card.add_child(info)
				_hint(info,str(detail[0]),12,Color("aabcbc"))
				_hint(info,str(detail[1]),22,Color("f7db9d"))
			_button("ZUR SEE & ZU DEN MISSIONEN",_sail,true)
			_back()
		"profile":
			_label("SPIELERPROFIL",true)
			_label("[%s] %s\nID %s\nPiratenrang %d · Battle Points %d" % [sim.guild.get("tag","–"),sim.captain_name,sim.captain_id,clampi(floori((sim.level-1)/4.0)+1,1,5),sim.battle_points])
			var field=_field("Spielername");field.max_length=24;field.text=sim.captain_name
			_button("NAMEN SPEICHERN",func():
				if field.text.strip_edges().length()>=2:sim.captain_name=field.text.strip_edges();_save();_show("profile"))
			_back()
		"maps":
			_label("SEEKARTEN · 1/1 BIS 20/2",true)
			_label("Jedes Gebiet hat Hafen, Gegner und Portale. Kartenwahl und Portalkurs auch direkt auf See unter Karten.")
			var leaves=GridContainer.new();leaves.columns=4;body.add_child(leaves)
			for leaf in 4:
				var pick: int=leaf
				var button=Button.new();button.text="%d–%d" % [leaf*5+1,leaf*5+5];button.custom_minimum_size.y=44;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				button.pressed.connect(func():chart_chapter=pick;chart_pick=sim.CONTENT.SEA_MAP_IDS[pick*10];_show("maps"));leaves.add_child(button)
			var chart=WORLD_CHART.new();chart.name="WorldChart";chart.sim=sim;chart.parchment=PARCHMENT;chart.chapter=chart_chapter;chart.selected=chart_pick
			chart.custom_minimum_size=Vector2(0,390);chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			chart.picked.connect(func(index: int):chart_pick=index;_show("maps"));body.add_child(chart)
			if chart_pick==WORLD_CHART.FORTRESS_NODE:_label("GILDENINSEL · 3/1 · 12 ausbaubare Türme")
			else:
				var map: Dictionary=sim.CONTENT.MAPS[chart_pick]
				_label("%s · %s · Stufe %d%s" % [map.code,map.name,map.level," · HIER" if chart_pick==sim.map_id else ""])
			_back()
		"guild":
			_label("GILDE & GILDENINSEL",true)
			_label("[%s] %s" % [sim.guild.get("tag","–"),sim.guild.get("name","Noch keine Gilde")])
			_label("Die Korsarenfestung auf 3/1 ist eroberbar: zwölf Türme zerstören und mit deiner Gilde halten. Deine permanente Heimatbasis bleibt unabhängig vom Besitz der Weltinsel. Die Verwaltung findest du auf See unter Gilde.")
			_back()
		"settings":
			_label("EINSTELLUNGEN & KONTO",true)
			_label("Grafik, HUD, Effekte und Steuerung bleiben auf See direkt unter Einstellungen erreichbar.")
			_label("Beta-Server · HTTPS-Adresse")
			server_field=_field("Server noch nicht verbunden");server_field.text=network.server_url
			_button("VERBINDUNG SPEICHERN",func():
				var value: String=server_field.text.strip_edges().trim_suffix("/")
				if value.is_empty() or network.valid_server(value):
					network.sign_out();network.server_url=value
					var file=FileAccess.open(CONFIG,FileAccess.WRITE)
					if file!=null:file.store_string(JSON.stringify({"server_url":value}))
					status_text="Verbindung gespeichert";_show("settings"))
			_button("UPDATER ÖFFNEN",func():_save();get_tree().set_meta("abyssal_manual_update",true);get_tree().change_scene_to_file("res://updater/launcher.tscn"))
			_button("ABMELDEN / STARTSEITE",func():network.sign_out();get_tree().set_meta("abyssal_entered",false);_show("welcome"))
			_back()
	_layout()
	_layout.call_deferred()
func _back() -> void:_button("ZURÜCK ZUM HAUPTMENÜ",func():_show("home") if get_tree().get_meta("abyssal_entered",false) else _show("welcome"))
func _authenticated(ok: bool,message: String) -> void:
	status_text=message
	if password!=null and is_instance_valid(password):password.text=""
	if ok:_enter_home()
	else:
		var notice=body.get_node_or_null("AuthStatus")
		if notice!=null:notice.text=message
func _enter_home() -> void:
	get_tree().set_meta("abyssal_entered",true);_show("home")
func _sail() -> void:
	_save();get_tree().change_scene_to_file("res://sea_map.tscn")

func _sail_menu(kind: String) -> void:
	# Consume once in sea_map._ready(); avoids parallel lobby market
	# systems that could desynchronize the captain's gold or inventory.
	get_tree().set_meta("abyssal_start_modal",kind)
	_sail()
func _save() -> void:
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(sim.export_save()))
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST]:_save()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_show("home" if page not in ["home","welcome","auth"] and get_tree().get_meta("abyssal_entered",false) else "welcome")
		get_viewport().set_input_as_handled()

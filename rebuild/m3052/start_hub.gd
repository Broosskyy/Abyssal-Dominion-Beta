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
const HARBOR_ART=preload("res://assets/ui/painted/loading_harbor.jpg")
const MARKET_ART=preload("res://assets/ui/painted/nav_harbor.png")
const SHIP_ART=preload("res://assets/ui/painted/nav_shipyard.png")
const GUILD_ART=preload("res://assets/ui/painted/nav_guild.png")
const CHART_ART=preload("res://assets/ui/painted/nav_charts.png")
const REWARD_ART=preload("res://assets/ui/painted/reward_chest.png")
const QUEST_ART=preload("res://assets/ui/painted/nav_quests.png")
const SKULL_ART=preload("res://assets/ui/painted/nav_ranking.png")
const SOCIAL=preload("res://social_invite.gd")
var sea_time := 0.0
var backdrop: TextureRect
var sim=SIM.new()
var network: Node
var panel: PanelContainer
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
	panel=PanelContainer.new();panel.name="CaptainPanel";add_child(panel)
	panel.add_theme_stylebox_override("panel",SKIN.card())
	scroll=preload("res://touch_scroll.gd").new();panel.add_child(scroll)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
	get_viewport().size_changed.connect(_layout)
	page="home" if get_tree().get_meta("abyssal_entered",false) else "welcome"
	_show(page);_layout()
	var boot=get_tree().root.get_node_or_null("DataBoot")
	if boot!=null:boot.mark_healthy()
func _process(delta: float) -> void:
	sea_time+=delta
	if backdrop!=null:backdrop.material.set_shader_parameter("sea_time",sea_time)

func _layout() -> void:
	var viewport_size: Vector2=get_viewport_rect().size
	var ui_scale: float=clampf(minf(viewport_size.x,viewport_size.y)/600.0,1.0,1.8)
	panel.scale=Vector2.ONE*ui_scale
	var dimensions: Vector2=viewport_size/ui_scale
	var wide: bool=dimensions.x>dimensions.y*1.35
	# Reference-inspired lobby: a generous content board on the right in
	# landscape, near-width in portrait, but never edge-to-edge fullscreen.
	panel.size=Vector2(minf(760.0,dimensions.x-36.0),minf(860.0,dimensions.y-44.0))
	var local_position: Vector2=Vector2(dimensions.x-panel.size.x-24.0,(dimensions.y-panel.size.y)*.5) if wide and dimensions.x>920 else (dimensions-panel.size)*.5
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
# Shared nautical dashboard components. Avoid tiny, repeated text buttons.
func _section(title: String) -> void:
	var label=_label(title.to_upper(),true)
	label.add_theme_font_size_override("font_size",20)

func _stat_chip(parent: Node,title: String,value: String) -> void:
	var box=PanelContainer.new()
	box.add_theme_stylebox_override("panel",SKIN.card())
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",2)
	box.add_child(column)
	var header=Label.new()
	header.text=title
	header.add_theme_font_size_override("font_size",12)
	header.add_theme_color_override("font_color",Color("9eabb8"))
	column.add_child(header)
	var number=Label.new()
	number.text=value
	number.add_theme_font_size_override("font_size",17)
	number.add_theme_color_override("font_color",Color("f8d995"))
	column.add_child(number)

func _lobby_card(parent: Node,icon: Texture2D,title: String,description: String,action: String,callback: Callable) -> void:
	var shell=PanelContainer.new()
	shell.add_theme_stylebox_override("panel",SKIN.card())
	shell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	shell.custom_minimum_size.y=160
	parent.add_child(shell)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",6)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	shell.add_child(content)
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	content.add_child(row)
	var picture=TextureRect.new()
	picture.texture=icon
	picture.custom_minimum_size=Vector2(66,66)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var texts=VBoxContainer.new()
	texts.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation",3)
	row.add_child(texts)
	var heading=Label.new()
	heading.text=title
	heading.add_theme_font_size_override("font_size",17)
	heading.add_theme_color_override("font_color",Color("f1d38f"))
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(heading)
	var details=Label.new()
	details.text=description
	details.add_theme_font_size_override("font_size",13)
	details.add_theme_color_override("font_color",Color("bccbd0"))
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(details)
	var button=Button.new()
	button.text=action
	button.custom_minimum_size.y=52
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	SKIN.dress(button,"normal",15)
	button.pressed.connect(callback)
	content.add_child(button)

func _home_dashboard() -> void:
	_label("KAPITÄNSHAFEN · ABYSSAL DOMINION",true)
	_label("WILLKOMMEN ZURÜCK · "+sim.captain_name.to_upper())
	var resources=GridContainer.new()
	resources.columns=3 if get_viewport_rect().size.x>=860 else 2
	resources.add_theme_constant_override("h_separation",8)
	resources.add_theme_constant_override("v_separation",8)
	body.add_child(resources)
	_stat_chip(resources,"GOLD",_thousands(int(sim.player.gold)))
	_stat_chip(resources,"KAPITÄNSSTUFE",str(sim.level))
	_stat_chip(resources,"KARTE",str(sim.CONTENT.MAPS[sim.map_id].code))
	var preview=PanelContainer.new()
	preview.add_theme_stylebox_override("panel",SKIN.card())
	body.add_child(preview)
	var hero=VBoxContainer.new()
	hero.add_theme_constant_override("separation",8)
	preview.add_child(hero)
	var image=TextureRect.new()
	image.name="LobbyHero"
	image.texture=HARBOR_ART
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size.y=205
	image.clip_contents=true
	image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hero.add_child(image)
	var heading=Label.new()
	heading.text="DEIN ABENTEUER WARTET"
	heading.add_theme_font_size_override("font_size",23)
	heading.add_theme_color_override("font_color",Color("f5dba2"))
	hero.add_child(heading)
	var info=Label.new()
	info.text="Erkunde die Seekarten, rüste dein Schiff aus und stelle dich den Monstern der Tiefe."
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size",15)
	info.add_theme_color_override("font_color",Color("b9d4d5"))
	hero.add_child(info)
	var sail=Button.new()
	sail.name="SailButton"
	sail.text="JETZT ZUR SEE · SPIELEN"
	sail.custom_minimum_size.y=60
	SKIN.dress(sail,"primary",18)
	hero.add_child(sail)
	sail.pressed.connect(_sail)
	# Existing signed daily/AFK ledger, not a second reward source.
	var next_reward: String="TAGESBONUS VERFÜGBAR" if sim.rewards.daily_available() else "TAGESBONUS HEUTE ABGEHOLT"
	_section("TÄGLICHE BELOHNUNGEN")
	var rewards=GridContainer.new()
	rewards.columns=2 if get_viewport_rect().size.x>=600 else 1
	rewards.add_theme_constant_override("h_separation",8)
	body.add_child(rewards)
	_lobby_card(rewards,REWARD_ART,next_reward,"7-Tage-Serie: %d/7" % sim.rewards.streak,"BELONUNGEN ANSEHEN",func():_show("rewards"))
	_lobby_card(rewards,REWARD_ART,"AFK-BEUTE","%d Gold zum Abholen" % sim.rewards.afk_gold(),"AFK-BEUTE ANSEHEN",func():_show("rewards"))
	_section("DEIN KAPITÄNSMENÜ")
	var shortcuts=GridContainer.new()
	shortcuts.columns=2 if get_viewport_rect().size.x>=600 else 1
	shortcuts.add_theme_constant_override("h_separation",8)
	shortcuts.add_theme_constant_override("v_separation",8)
	body.add_child(shortcuts)
	for item in [
		["LOGBUCH","Aufträge, Quests und Fortschritt","ÖFFNEN",QUEST_ART,"Logbuch"],
		["WERFT & DECKS","Kanonen, Designs und Decks","ZUR WERFT",SHIP_ART,"Werft"],
		["MARKTPLATZ","Gold, Munition und Items","ZUM MARKT",MARKET_ART,"Markt"],
		["SEEKARTEN","Routen und Kartenübersicht","WELTKARTE",CHART_ART,"Seekarten"],
		["FREUNDE","Einladungscode teilen","EINLADEN",GUILD_ART,"friends"],
		["NEUIGKEITEN","Was in der Beta entsteht","ANSEHEN",SKULL_ART,"news"]
	]:
		var target: String=str(item[4])
		_lobby_card(shortcuts,item[3],str(item[0]),str(item[1]),str(item[2]),func():
			if target=="friends" or target=="news":_show(target)
			else:_sail_to(target))
	_section("WEITERE BEREICHE")
	var extra=GridContainer.new()
	extra.columns=2
	extra.add_theme_constant_override("h_separation",8)
	body.add_child(extra)
	for target in [["Battle Pass","SAISONPASS"],["Kastelle","TALENTE & KASTELLE"],["Gilde","GILDE"],["Profil","SPIELERPROFIL"]]:
		var name: String=str(target[0])
		var button=Button.new()
		button.text=str(target[1])
		button.custom_minimum_size.y=52
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		SKIN.dress(button,"normal",14)
		button.pressed.connect(func():_sail_to(name))
		extra.add_child(button)
	_button("EINSTELLUNGEN & KONTO",func():_show("settings"))
	_label("Lokale Beta · "+("Konto angemeldet" if not network.account.is_empty() else "Gastfortschritt auf diesem Gerät"))

func _thousands(value: int) -> String:
	var digits: String=str(absi(value))
	var formatted: String=""
	while digits.length()>3:
		formatted="."+digits.right(3)+formatted
		digits=digits.left(digits.length()-3)
	return digits+formatted

func _rewards_dashboard() -> void:
	_label("TAGESBONUS · 7-TAGE-SERIE",true)
	_label("Tägliche Belohnungen mit echten, bereits vorhandenen Spielwerten. Tageswechsel 00:00 UTC.")
	var today: int=floori(float(Time.get_unix_time_from_system())/86400.0)
	var last_claim: int=sim.rewards.last_claim_day
	var next_day: int=(sim.rewards.streak%7)+1 if last_claim>=today-1 else 1
	var cards=GridContainer.new()
	cards.columns=3 if get_viewport_rect().size.x>=640 else 2
	cards.add_theme_constant_override("h_separation",8)
	cards.add_theme_constant_override("v_separation",8)
	body.add_child(cards)
	for day in 7:
		var index: int=day+1
		var completed: bool=index<=sim.rewards.streak and last_claim==today
		var title: String="TAG %d%s" % [index," · ✓" if completed else (" · NÄCHSTER" if index==next_day else "")]
		var essence: int=2 if index==7 else 1
		_lobby_card(cards,REWARD_ART,title,"%d Gold · %d Essenz · 1 Reparatur" % [100+index*50,essence],"ABGEHOLT" if completed else "VORSCHAU",func():pass)
	# The only payout actions remain the existing reward ledger methods.
	var reward=_button("TAGESBONUS ABHOLEN" if sim.rewards.daily_available() else "HEUTE BEREITS ABGEHOLT",func():
		if sim.rewards.claim_daily(sim):_save()
		_show("rewards"),true)
	reward.name="DailyClaimButton"
	reward.disabled=not sim.rewards.daily_available()
	_section("AFK-BEUTE")
	_label("Aktuell %d Gold · 3 Gold pro Minute, maximal 8 Stunden. Zusätzlich 10 Vollkugeln je 5 Minuten." % sim.rewards.afk_gold())
	var afk=_button("AFK-BEUTE ABHOLEN",func():
		if sim.rewards.claim_afk(sim):_save()
		_show("rewards"),true)
	afk.disabled=sim.rewards.afk_gold()<=0
	_label("Beta-Hinweis: Diese Belohnungen werden lokal gespeichert; später muss ein Spielserver die Zeit und Ansprüche prüfen.")
	_back()

func _friends_dashboard() -> void:
	_label("FREUNDE & EINLADUNGEN",true)
	_label("Zeig Freunden das Spiel und teile deinen Beta-Code. Online-Freundeslisten und Einladungsbelohnungen sind noch nicht freigeschaltet.")
	var code: String=SOCIAL.invite_code(sim.captain_id)
	var hero=GridContainer.new()
	hero.columns=1
	body.add_child(hero)
	_lobby_card(hero,GUILD_ART,"DEIN EINLADUNGSCODE",code if not code.is_empty() else "Noch kein gültiger Spielercode","CODE ÜBERNEHMEN",func():_copy_invite())
	var copy=_button("EINLADUNGSTEXT KOPIEREN",_copy_invite,true)
	copy.name="CopyInviteButton"
	copy.disabled=code.is_empty()
	_label("Enthalten sind dein Code und die GitHub-Beta-Release-Seite. Die Weitergabe ist freiwillig; der Code vergibt derzeit kein Gold und keine Premiumwährung.")
	_section("EINGEHENDE EINLADUNG")
	var input=_field("Einladungscode eines Freundes · ADM-...")
	input.name="InviteCodeInput"
	var feedback=_label("Noch keine Online-Freundesverknüpfung möglich.")
	_button("CODEFORMAT PRÜFEN",func():
		feedback.text="Format gültig · Verknüpfung erst nach Serverstart möglich." if SOCIAL.is_invite_code(input.text) else "Bitte einen gültigen ADM-Einladungscode eingeben.")
	_section("FREUNDESLISTE & GRUPPEN")
	_label("Freundesliste, Online-Status, gemeinsame Gruppen und Einladungsprämien folgen mit dem Multiplayer-Server. Es werden keine nicht vorhandenen Freunde angezeigt.")
	_back()

func _copy_invite() -> void:
	var message: String=SOCIAL.invite_text(sim.captain_name,sim.captain_id)
	if message.is_empty():
		status_text="Einladungscode noch nicht verfügbar."
	else:
		DisplayServer.clipboard_set(message)
		status_text="Einladung mit Beta-Code in die Zwischenablage kopiert."
	_show("friends")
	_label(status_text)

func _news_dashboard() -> void:
	_label("NEUIGKEITEN & ENTWICKLUNG",true)
	_label("ABYSSAL DOMINION · BETA-ÜBERSICHT")
	var updates=GridContainer.new()
	updates.columns=1
	body.add_child(updates)
	_lobby_card(updates,SHIP_ART,"WERFT & SCHIFFSAUSRÜSTUNG","Kanonenmontage, Decks und Schiffdesigns im eigenen Marineblau-Gold-Look.","WERFT ÖFFNEN",func():_sail_to("Werft"))
	_lobby_card(updates,REWARD_ART,"TAGESBELOHNUNGEN","Sammle deine täglichen Vorräte und bereits verdiente AFK-Beute.","BELONUNGEN ÖFFNEN",func():_show("rewards"))
	_lobby_card(updates,GUILD_ART,"CROSSPLAY · IN ARBEIT","Login ist vorbereitet; verbindliche Freundeslisten und echte MMO-Welten brauchen einen erreichbaren Server.","FREUNDE",func():_show("friends"))
	_label("Dies sind Beta-Projektinformationen, keine live vom Server gelieferten Neuigkeiten.")
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
		"home":_home_dashboard()
		"rewards":_rewards_dashboard()
		"friends":_friends_dashboard()
		"news":_news_dashboard()
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
			_label("Die Korsarenfestung auf 3/1 ist eroberbar: alle zwölf Türme zerstören, mit deiner Gilde halten und jeden Turm bis Stufe 5 ausbauen. Verwaltung und Inselkampf findest du auf See unter Gilde.")
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
func _sail_to(menu: String) -> void:
	get_tree().set_meta("abyssal_start_modal",menu)
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

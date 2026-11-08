extends Control
## Update gate → welcome/auth → captain harbor → chart loading → actual sea.
const SIM=preload("res://simulation.gd")
const NETWORK=preload("res://network_client.gd")
const SKIN=preload("res://ui_skin.gd")
const SAVE="user://captain_m3052.json"
const CONFIG="user://connection.json"
const ART=preload("res://assets/world_v2/frontier_splash.png")
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
	panel.size=Vector2(minf(520,dimensions.x-32),minf(maxf(180,body.get_combined_minimum_size().y+24),minf(760,dimensions.y-48)))
	var local_position: Vector2=Vector2(dimensions.x-panel.size.x-32,(dimensions.y-panel.size.y)*.5) if wide and dimensions.x>920 else (dimensions-panel.size)*.5
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
			_label("KAPITÄNSHAFEN",true)
			_label("%s · Stufe %d\n%s Gold · Karte %s" % [sim.captain_name,sim.level,sim.player.gold,sim.CONTENT.MAPS[sim.map_id].code])
			_label("Lokale Beta · "+("Konto angemeldet; Weltserver-Vorschau vorbereitet" if not network.account.is_empty() else "Gastfortschritt auf diesem Gerät"))
			_button("ZUR SEE · KARTE STARTEN",_sail,true).name="SailButton"
			_button("TAGESBONUS & AFK-BEUTE",func():_show("rewards"))
			_button("SPIELERPROFIL",func():_show("profile"))
			_button("SEEKARTEN · 40 GEBIETE",func():_show("maps"))
			_button("GILDE & INSEL",func():_show("guild"))
			_button("EINSTELLUNGEN & KONTO",func():_show("settings"))
		"rewards":
			_label("TAGESBONUS & AFK-BEUTE",true)
			_label("Serie %d/7 · Tagwechsel 00:00 UTC" % sim.rewards.streak)
			_button("TAGESBONUS ABHOLEN" if sim.rewards.daily_available() else "HEUTE BEREITS ABGEHOLT",func():sim.rewards.claim_daily(sim);_save();_show("rewards"),true).disabled=not sim.rewards.daily_available()
			_label("AFK-Beute: %d Gold · maximal 8 Stunden" % sim.rewards.afk_gold())
			_button("AFK-BEUTE ABHOLEN",func():sim.rewards.claim_afk(sim);_save();_show("rewards"),true).disabled=sim.rewards.afk_gold()<=0
			_label("Tagesbonus: 150–450 Gold, Essenz, Notreparatur. AFK: 3 Gold/Minute und Vollkugeln. Lokale Beta-Belohnungen werden nicht als Online-Fortschritt übertragen.")
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
			for index: int in sim.CONTENT.SEA_MAP_IDS:
				var map: Dictionary=sim.CONTENT.MAPS[index]
				_label("%s · %s · Stufe %d%s" % [map.code,map.name,map.level," · HIER" if index==sim.map_id else ""])
			_back()
		"guild":
			_label("GILDE & GILDENINSEL",true)
			_label("[%s] %s" % [sim.guild.get("tag","–"),sim.guild.get("name","Noch keine Gilde")])
			_label("Die Korsarenfestung auf 3/1 ist eroberbar: alle zehn Türme zerstören, mit deiner Gilde halten und jeden Turm bis Stufe 5 ausbauen. Verwaltung und Inselkampf findest du auf See unter Gilde.")
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
func _save() -> void:
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(sim.export_save()))
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST]:_save()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_show("home" if page not in ["home","welcome","auth"] and get_tree().get_meta("abyssal_entered",false) else "welcome")
		get_viewport().set_input_as_handled()

extends Control
const DATA=preload("res://updater/data_controller.gd")
const CONTROLLER=preload("res://updater/update_controller.gd")
var autostart=true
var updater: Node
var content: Node
var content_started=false
var version_label: Label
var status: Label
var bar: ProgressBar
var action: Button
var play: Button
var panel: Panel
var box: Control
var countdown=false

func _ready() -> void:
	var manual=bool(get_tree().get_meta("abyssal_manual_update",false))
	if manual:get_tree().remove_meta("abyssal_manual_update");autostart=false
	var bg=TextureRect.new();bg.texture=load("res://assets/world_v2/frontier_splash.png");bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	panel=Panel.new();add_child(panel)
	var skin=StyleBoxFlat.new();skin.bg_color=Color(.025,.07,.10,.95);skin.border_color=Color("b89755")
	skin.set_border_width_all(1);skin.set_corner_radius_all(16)
	skin.content_margin_left=28;skin.content_margin_right=28;skin.content_margin_top=24;skin.content_margin_bottom=24
	panel.add_theme_stylebox_override("panel",skin)
	box=Control.new();panel.add_child(box)
	var title=Label.new();title.text="ABYSSAL DOMINION";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",25);title.add_theme_color_override("font_color",Color("e1c68b"));box.add_child(title)
	version_label=Label.new();version_label.text="Version "+str(ProjectSettings.get_setting("application/config/version",""));version_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(version_label)
	status=Label.new();status.text="Spieldaten werden geprüft …";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.y=48;status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(status)
	bar=ProgressBar.new();bar.custom_minimum_size.y=16;bar.show_percentage=false;bar.max_value=1;box.add_child(bar)
	action=Button.new();action.text="Updates prüfen";action.custom_minimum_size.y=48;action.pressed.connect(_action);box.add_child(action)
	play=Button.new();play.text="ZUR STARTSEITE";play.custom_minimum_size.y=48;play.pressed.connect(_play);box.add_child(play)
	var hint=Label.new();hint.text="Spieldaten ohne Installation · Android-Updates mit Bestätigung.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",13);box.add_child(hint)
	updater=CONTROLLER.new();add_child(updater);updater.changed.connect(_refresh)
	content=DATA.new();add_child(content);content.changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout);_layout()
	if manual:updater.check()
	elif autostart:
		if OS.get_name()=="Android":updater.check()
		else:await get_tree().create_timer(0.15).timeout;_play()

func _layout() -> void:
	var s=get_viewport_rect().size
	var width=minf(540,s.x-32)
	panel.size=Vector2(width,minf(434,s.y-24))
	panel.position=(s-panel.size)*0.5
	box.position=Vector2(24,(panel.size.y-342)/2)
	box.size=Vector2(panel.size.x-48,342)
	# Fixed slots avoid Container minimum-height feedback from wrapped labels.
	var slots=[Vector2(0,32),Vector2(36,24),Vector2(70,76),Vector2(156,16),Vector2(188,48),Vector2(246,48),Vector2(306,36)]
	for i in box.get_child_count():
		var widget=box.get_child(i) as Control
		widget.position=Vector2(0,slots[i].x)
		widget.size=Vector2(box.size.x,slots[i].y)

func _refresh() -> void:
	var boot=get_tree().root.get_node_or_null("DataBoot")
	if boot!=null:version_label.text="App "+str(ProjectSettings.get_setting("application/config/version",""))+" · Daten "+str(boot.active_revision)
	if boot!=null and int(content.spec.get("revision",0))>boot.active_revision:version_label.text+=" → "+str(content.spec.revision)
	if not content_started and updater.state in ["current","offline"]:
		content_started=true;content.check();return
	var current=content if content_started else updater
	status.text=current.message;bar.value=current.progress
	var state=str(current.state)
	bar.indeterminate=state in ["checking","verifying"]
	action.visible=state not in ["checking","downloading","paused","verifying"]
	action.disabled=state=="installing"
	action.text="Installation fortsetzen" if state in ["ready","permission"] else ("Update herunterladen" if state=="available" else ("Erneut herunterladen" if state=="error" and not current.spec.is_empty() else "Updates prüfen"))
	if state=="restart":action.text="App schließen"
	play.text="STARTSEITE · Download läuft weiter" if state in ["downloading","paused"] else "ZUR STARTSEITE"
	var direct_active: bool=bool(current.foreground_transfer) and state in ["downloading","verifying"]
	play.disabled=direct_active
	if direct_active:play.text="DOWNLOAD LÄUFT · APP OFFEN LASSEN"
	if autostart and state in ["current","offline","unsupported"] and content_started and not countdown:
		countdown=true
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and current.state==state:_play()

func _action() -> void:
	if content_started:
		if content.state=="restart":get_tree().quit()
		elif content.state=="error" and not content.spec.is_empty():content.download()
		else:content.check()
	elif updater.state in ["ready","permission"]:updater.install()
	elif updater.state=="available" or (updater.state=="error" and not updater.spec.is_empty()):updater.download()
	else:updater.check()

func _play() -> void:
	var boot=get_tree().root.get_node_or_null("DataBoot")
	if boot!=null:boot.prepare_game()
	get_tree().change_scene_to_file("res://start_hub.tscn")

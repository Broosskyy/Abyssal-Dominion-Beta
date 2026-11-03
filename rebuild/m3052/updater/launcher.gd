extends Control
const CONTROLLER=preload("res://updater/update_controller.gd")
var autostart=true
var updater: Node
var status: Label
var bar: ProgressBar
var action: Button
var play: Button
var panel: PanelContainer
var countdown=false

func _ready() -> void:
	var manual=bool(get_tree().get_meta("abyssal_manual_update",false))
	if manual:get_tree().remove_meta("abyssal_manual_update");autostart=false
	var bg=ColorRect.new();bg.color=Color("061b28");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	panel=PanelContainer.new();add_child(panel)
	var skin=StyleBoxFlat.new();skin.bg_color=Color("0b2736");skin.border_color=Color("b89755")
	skin.set_border_width_all(1);skin.set_corner_radius_all(16)
	skin.content_margin_left=28;skin.content_margin_right=28;skin.content_margin_top=24;skin.content_margin_bottom=24
	panel.add_theme_stylebox_override("panel",skin)
	var box=VBoxContainer.new();box.add_theme_constant_override("separation",14);panel.add_child(box)
	var title=Label.new();title.text="ABYSSAL DOMINION";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",25);title.add_theme_color_override("font_color",Color("e1c68b"));box.add_child(title)
	var version=Label.new();version.text="Version "+str(ProjectSettings.get_setting("application/config/version",""));version.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(version)
	status=Label.new();status.text="Seekarte wird vorbereitet …";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.custom_minimum_size.y=48;status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(status)
	bar=ProgressBar.new();bar.custom_minimum_size.y=16;bar.show_percentage=false;bar.max_value=1;box.add_child(bar)
	action=Button.new();action.text="Updates prüfen";action.custom_minimum_size.y=48;action.pressed.connect(_action);box.add_child(action)
	play=Button.new();play.text="Spielen";play.custom_minimum_size.y=48;play.pressed.connect(_play);box.add_child(play)
	var hint=Label.new();hint.text="Android kann den Download beim App-Wechsel fortsetzen.";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",13);box.add_child(hint)
	updater=CONTROLLER.new();add_child(updater);updater.changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout);_layout()
	if manual:updater.check()
	elif autostart:
		if OS.get_name()=="Android":updater.check()
		else:await get_tree().create_timer(0.15).timeout;_play()

func _layout() -> void:
	var s=get_viewport_rect().size
	var width=minf(540,s.x-32)
	panel.size=Vector2(width,minf(410,s.y-24))
	panel.position=(s-panel.size)*0.5

func _refresh() -> void:
	status.text=updater.message;bar.value=updater.progress
	var state=str(updater.state)
	bar.indeterminate=state in ["checking","verifying"]
	action.visible=state not in ["checking","downloading","paused","verifying"]
	action.disabled=state=="installing"
	action.text="Installation fortsetzen" if state in ["ready","permission"] else ("Update herunterladen" if state=="available" else ("Erneut herunterladen" if state=="error" and not updater.spec.is_empty() else "Updates prüfen"))
	play.text="Spielen · Download läuft weiter" if state in ["downloading","paused"] else "Spielen"
	if autostart and state in ["current","offline"] and not countdown:
		countdown=true
		await get_tree().create_timer(1.2).timeout
		if is_inside_tree() and updater.state==state:_play()

func _action() -> void:
	if updater.state in ["ready","permission"]:updater.install()
	elif updater.state=="available" or (updater.state=="error" and not updater.spec.is_empty()):updater.download()
	else:updater.check()

func _play() -> void:
	get_tree().change_scene_to_file("res://sea_map.tscn")

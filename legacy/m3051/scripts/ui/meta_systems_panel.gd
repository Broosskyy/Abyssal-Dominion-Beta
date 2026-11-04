class_name MetaSystemsPanel
extends Control

var panel:PanelContainer
var shade:ColorRect
var toggle:Button
var companion_label:Label
var artifact_label:Label
var afk_label:Label
var last_preview:Dictionary={}
var preview_sequence:=0

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;theme=NauticalTheme.create();add_to_group("meta_systems_panel");set_meta("router_persistent",true)
	shade=ColorRect.new();shade.color=Color(0.005,0.018,0.028,0.86);shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT);shade.mouse_filter=MOUSE_FILTER_STOP;add_child(shade)
	toggle=Button.new();toggle.text="META";toggle.custom_minimum_size=Vector2(96,52)*NauticalTheme.density_scale();toggle.mouse_filter=MOUSE_FILTER_STOP;toggle.pressed.connect(_toggle);add_child(toggle)
	panel=PanelContainer.new();panel.mouse_filter=MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",NauticalHud.box_style());add_child(panel)
	var margin:=MarginContainer.new();for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14);panel.add_child(margin)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	var title:=Label.new();title.text="BEGLEITER · ARTEFAKTE · AFK · V3.8";body.add_child(title)
	var note:=Label.new();note.text="DEV-VORSCHAU · Ownership, Progression und Claims bleiben serverautoritativ";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(note)
	companion_label=Label.new();companion_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(companion_label)
	_button(body,"Begleiter-Visual testen · DEV",_cycle_companion)
	artifact_label=Label.new();artifact_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(artifact_label)
	_button(body,"Artefakt-Visualisierung testen · DEV",_cycle_artifacts)
	var afk_icon:=TextureRect.new();afk_icon.texture=load("res://assets/production/ui/m152/afk_harbor_operations.svg");afk_icon.custom_minimum_size=Vector2(72,72);afk_icon.expand_mode=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL;afk_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;body.add_child(afk_icon)
	afk_label=Label.new();afk_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(afk_label)
	_button(body,"AFK-Profilvorschau · DEV",_preview_afk)
	_button(body,"Serverstatus anzeigen",_show_server_state)
	_button(body,"Schließen",_toggle)
	shade.hide();panel.hide();get_viewport().size_changed.connect(_layout);_layout();_refresh()

func _button(parent:Node,text_value:String,callback:Callable)->void:
	var button:=Button.new();button.text=text_value;button.custom_minimum_size.y=56*NauticalTheme.density_scale();button.pressed.connect(callback,CONNECT_DEFERRED);parent.add_child(button)

func _toggle()->void:
	if panel.visible:close()
	else:open()
func open()->void:
	panel.show();shade.show();toggle.hide();mouse_filter=MOUSE_FILTER_STOP
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if player!=null:
		player.set_meta("meta_panel_open",true);(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation();player.stop_ship()
	_refresh()
	panel.modulate.a=0.0
	panel.position.x+=18.0*NauticalTheme.density_scale()
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(panel,"modulate:a",1.0,0.14)
	tween.tween_property(panel,"position:x",panel.position.x-18.0*NauticalTheme.density_scale(),0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func close()->void:
	panel.hide();shade.hide();mouse_filter=MOUSE_FILTER_IGNORE
	toggle.visible=not InputDeviceProfile.touch_like(_safe_rect().size)
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if player!=null:player.set_meta("meta_panel_open",false)
	var hud:=get_tree().get_first_node_in_group("hud") as GameHud
	if hud!=null:hud.complete_routed_panel(self)
func _input(event:InputEvent)->void:
	if panel.visible and event.is_action_pressed("ui_cancel"):
		close();get_viewport().set_input_as_handled()
func _cycle_companion()->void:
	var runtime:=get_tree().get_first_node_in_group("companion_runtime") as CompanionRuntime
	if runtime!=null:runtime.cycle()
	_refresh()
func _cycle_artifacts()->void:
	var loadout:=get_tree().get_first_node_in_group("artifact_loadout") as ArtifactLoadout
	if loadout==null:return
	var sets:Array[Array]=[["ARTIFACT-STAR-COMPASS","ARTIFACT-TIDE-BULWARK"],["ARTIFACT-WAR-CAPSTAN","ARTIFACT-LEVIATHAN-TOOTH"],["ARTIFACT-FORTUNE-IDOL","ARTIFACT-ABYSS-HEART"]]
	var current:=sets.find(loadout.equipped);loadout.equip(sets[(current+1)%sets.size()]);_refresh()
func _preview_afk()->void:
	var service:=get_tree().get_first_node_in_group("afk_reward_service") as AfkRewardService
	if service!=null:last_preview=service.preview("AFK-PROFILE-HARBOR-OPS",7200)
	_refresh()
func _show_server_state()->void:
	# M251: no normal local AFK reward claim button; legacy _claim_afk flow is intentionally retired.
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	var runtime: M251MetaProgressionRuntime = null
	if player!=null: runtime=player.get_node_or_null("MetaProgression") as M251MetaProgressionRuntime
	if runtime==null or str(runtime.snapshot().get("source",""))!="SERVER":
		afk_label.text="SERVERSTATUS · nicht verbunden\nKeine lokale Offlinezeit, Rewards oder Claim-Receipts werden erzeugt."
	else:
		var state:=runtime.afk_state()
		afk_label.text="SERVERSTATUS · %s\n%s"%[str(state.get("claim_state","UNBEKANNT")).to_upper(),str(state.get("profile_name",state.get("profile_id","Captain Expedition")))]

func _refresh()->void:
	var companion:=get_tree().get_first_node_in_group("companion_runtime") as CompanionRuntime
	var definition:=CompanionCatalog.by_id(companion.equipped_id) if companion!=null else {}
	companion_label.text="BEGLEITER · DEV-VISUAL\n%s · %s · 1 aktiver Preview-Slot\nBesitz/Level/Traits: SERVER"%[str(definition.get("name","nicht geladen")),str(definition.get("role",""))]
	var loadout:=get_tree().get_first_node_in_group("artifact_loadout") as ArtifactLoadout
	artifact_label.text="ARTEFAKTE · DEV-VISUAL\n%s\nOwnership/Mastery/Resonanz: SERVER"%[", ".join(loadout.equipped) if loadout!=null else "nicht geladen"]
	if last_preview.is_empty():afk_label.text="AFK-REWARDS\nBegrenzter Pool · aktiver SERVER-Claim · kein Hintergrundkampf"
	else:afk_label.text="AFK-PREVIEW · %dh · Gold %d · XP %d · Items %d\nKein Ranked/Event/Boss/Endgame-Loot"%[int(last_preview.get("seconds",0))/3600,int(last_preview.get("gold",0)),int(last_preview.get("world_xp",0)),(last_preview.get("items",[]) as Array).size()]

func _safe_rect()->Rect2:
	var visible:=get_viewport_rect()
	if OS.has_feature("android") or OS.has_feature("ios"):
		var usable:=DisplayServer.get_display_safe_area();var screen:=DisplayServer.screen_get_size()
		if usable.size.x>0 and screen.x>0 and screen.y>0:
			var factor:=visible.size/Vector2(screen);return Rect2(Vector2(usable.position)*factor,Vector2(usable.size)*factor)
	return visible
func _layout()->void:
	var safe:=_safe_rect();var compact:=safe.size.x<720.0;var sx:=NauticalTheme.density_scale()
	var toggle_size:=Vector2(96,52)*sx
	toggle.position=Vector2(safe.end.x-toggle_size.x-8*sx,safe.position.y+132*sx);toggle.size=toggle_size;toggle.visible=not InputDeviceProfile.touch_like(safe.size) and not panel.visible
	panel.size=Vector2(minf(390.0*sx,safe.size.x-16.0*sx),minf(610.0*sx,safe.size.y-24.0*sx));panel.position=Vector2(safe.end.x-panel.size.x-8.0*sx,safe.position.y+12.0*sx)

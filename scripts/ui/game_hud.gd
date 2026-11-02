class_name GameHud
extends Control
## M198 HUD regression lock: No persistent bottom command/map-selection bar.
## M198 HUD regression lock: no centered primary attack button.
## M198 HUD regression lock: lower-right combat anchor.

const PANEL := Color(0.025, 0.05, 0.075, 0.86)
const TEXT := Color(0.92, 0.95, 0.97)
const HEALTH_GREEN := Color(0.18, 0.78, 0.42)
const ENEMY_RED := Color(0.9, 0.22, 0.16)
const RELOAD_ORANGE := Color(0.93, 0.64, 0.18)

var font: Font
var global_map_open := false
var full_chart_view := "sector" # M223: current named sea map first; region overview remains secondary
var full_chart_filter := "all"
var full_chart_selected: Node3D = null
var _m223_chart_hits: Array[Dictionary] = []
var full_chart_zoom := 1.0 # M224: presentation-only zoom of rectangular full sea chart
var full_chart_pan := Vector2.ZERO # M224: normalized chart-space pan; never changes world/navigation state
var _m224_chart_dragging := false
var _m224_chart_drag_origin := Vector2.ZERO
var _m224_chart_pan_origin := Vector2.ZERO
var _nameplate_rects: Array[Rect2] = []
var recent_log: Array[String] = ["Lokaler Test · Kein Online-Chat"]
var log_open := false
var _last_compact := false
var notice_until := 0
var active_notice := ""
var notice_priority := 0
var notice_family := ""
var menu_open := false
var menu_page := ""
var command_deck: CommandDeck
var routed_panel: Control
var routed_return_page := ""
var combat_picker := "" # "ammo" / "items"; responsive combat selector
var combat_detail_id := "" # M43 long-press detail card
var guild_island_panel := ""
var guild_island_panel_until := 0
var guild_island_focus_index := 0
var _m226_harbor_service_hits: Array[Dictionary] = []
# M231 presentation-only encounter territory feedback state.
var _m231_zone_key := ""
var _m231_zone_read := ""
var _m231_zone_label := ""
var _m231_zone_hint := ""
var _m231_zone_feedback_until := 0.0
var _m231_last_change := -999.0
# M232 presentation-only active world-event awareness state.
var _m232_event_zone_key := ""
var _m232_event_inside := false
var _m232_event_phase := -1
var _m232_event_label := ""
var _m232_event_hint := ""
var _m232_event_feedback_until := 0.0
var _m232_event_last_change := -999.0
# M233 event lifecycle continuity; presentation only.
var _m233_event_state := "inactive"
var _m233_event_title := ""
var _m233_event_label := ""
var _m233_event_hint := ""
var _m233_event_feedback_until := 0.0
var _m234_event_objective_snapshot: Dictionary = {}
var _m234_event_label := ""
var _m234_event_hint := ""
var _m234_event_feedback_until := 0.0
# M235 server-replicated event contribution/ranking/eligibility presentation.
var _m235_contribution_snapshot: Dictionary = {}
var _m235_contribution_label := ""
var _m235_contribution_hint := ""
var _m235_contribution_feedback_until := 0.0
var _m232_last_boss_key := ""
var _m232_last_boss_announce := -999.0
# M280 presentation-only server-confirmed reward visual view model.
var m280_reward_visual_state: Dictionary = {}
var _m280_last_visual_revision := -1
# M281 presentation-only server-confirmed combat HUD convergence view model.
var m281_combat_hud_state: Dictionary = {}
var _m281_last_visual_revision := -1
# M282 presentation-only server-confirmed combat event/coalescing view model.
var m282_combat_feedback_state: Dictionary = {}
# M283 presentation-only projectile/salvo/harpoon/audio-haptics view model.
var m283_projectile_presentation_state: Dictionary = {}
# M284 presentation-only cannon/ammo/harpoon/material/audio identity view model.
var m284_naval_combat_identity_state: Dictionary = {}
# M285 server-confirmed ship hit/damage-state/defeat presentation view model.
var m285_ship_damage_defeat_state: Dictionary = {}
# M286 server-confirmed single-model damage-overlay presentation view model.
var m286_ship_damage_escalation_state: Dictionary = {}
# M287 server-confirmed ship-motion/wake/sail presentation view model.
var m287_ship_motion_identity_state: Dictionary = {}
# M288 server-confirmed naval-contact/target/threat presentation view model.
var m288_naval_contact_readability_state: Dictionary = {}
# M289 first-session vertical-slice source/native-QA readiness view model.
var m289_playable_vertical_slice_state: Dictionary = {}
# M290 first-sortie event-binding and visible-guidance view model.
var m290_first_sortie_state: Dictionary = {}
var _m282_last_feedback_revision := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("hud")
	font = ThemeDB.fallback_font
	_apply_saved_hud_layout.call_deferred()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		(player.get_node("Missions") as MissionSystem).mission_completed.connect(_mission_completed)
		var roster := player.get_node("ShipRoster") as PlayerShipRoster
		roster.ship_mastery_leveled.connect(_ship_mastery_leveled)
	_last_compact = bool(layout().compact)
	log_open = false
	command_deck = CommandDeck.new()
	command_deck.hud = self
	add_child(command_deck)
	queue_redraw()



func _m280_sync_reward_visual_state() -> void:
	var runtime := get_tree().get_first_node_in_group("reward_visual_integration_readiness") as M280RewardVisualIntegrationRuntime
	if runtime == null:
		m280_reward_visual_state.clear()
		return
	var view := runtime.presentation_view(layout())
	var revision := int(view.get("visual_revision", -1)) if not view.is_empty() else -1
	if revision != _m280_last_visual_revision:
		_m280_last_visual_revision = revision
		m280_reward_visual_state = view.duplicate(true)
		queue_redraw()
	elif revision >= 0:
		m280_reward_visual_state = view.duplicate(true)


func _m281_sync_combat_hud_state() -> void:
	var runtime := get_tree().get_first_node_in_group("combat_hud_convergence_readiness") as M281CombatHudConvergenceRuntime
	if runtime == null:
		m281_combat_hud_state.clear()
		return
	if int(runtime.snapshot().get("visual_revision", -1)) < 0:
		var combat := get_tree().get_first_node_in_group("authoritative_combat_readiness") as M269AuthoritativeCombatRuntime
		var state := get_tree().get_first_node_in_group("authoritative_combat_state_readiness") as M270AuthoritativeCombatStateRuntime
		var targeting := get_tree().get_first_node_in_group("targeting_relationship_authority_readiness") as M271TargetingRelationshipAuthorityRuntime
		runtime.bind_authority_layers(combat, state, targeting)
	var view := runtime.presentation_view(layout())
	var revision := int(view.get("visual_revision", -1)) if not view.is_empty() else -1
	if revision != _m281_last_visual_revision:
		_m281_last_visual_revision = revision
		m281_combat_hud_state = view.duplicate(true)
		queue_redraw()
	elif revision >= 0:
		m281_combat_hud_state = view.duplicate(true)



func _m282_sync_combat_feedback_state() -> void:
	var runtime := get_tree().get_first_node_in_group("combat_event_feedback_readiness") as M282CombatEventFeedbackRuntime
	if runtime == null:
		m282_combat_feedback_state.clear()
		return
	if int(runtime.snapshot().get("feedback_revision", -1)) < 0:
		var combat := get_tree().get_first_node_in_group("authoritative_combat_readiness") as M269AuthoritativeCombatRuntime
		var state := get_tree().get_first_node_in_group("authoritative_combat_state_readiness") as M270AuthoritativeCombatStateRuntime
		var hud_runtime := get_tree().get_first_node_in_group("combat_hud_convergence_readiness") as M281CombatHudConvergenceRuntime
		runtime.bind_authority_layers(combat, state, hud_runtime)
	# Prototype bridge only copies an already server-verified M269 verdict; it never turns local fire feedback into truth.
	runtime.sync_latest_server_outcome()
	var view := runtime.presentation_view(layout())
	var revision := int(view.get("feedback_revision", -1)) if not view.is_empty() else -1
	if revision != _m282_last_feedback_revision:
		_m282_last_feedback_revision = revision
		m282_combat_feedback_state = view.duplicate(true)
		queue_redraw()
	elif revision >= 0:
		m282_combat_feedback_state = view.duplicate(true)

func _apply_saved_hud_layout()->void:
	var store:=HudLayoutStore.current(get_tree())
	if store==null:return
	var base:=NauticalLayout.calculate(_safe_rect())
	var profile:=str(base.get("hud_profile","desktop_wide"))
	NauticalLayout.set_player_offsets(profile,store.layouts.get(profile,{}))
	store.changed.connect(func():
		NauticalLayout.set_player_offsets(profile,store.layouts.get(profile,{}))
		queue_redraw())

func open_hud_layout_editor()->void:
	if get_node_or_null("HudLayoutEditor")!=null:return
	combat_picker=""
	global_map_open=false
	if menu_open:close_menu()
	var editor:=HudLayoutEditor.new()
	editor.name="HudLayoutEditor"
	add_child(editor)
	editor.closed.connect(func(): queue_redraw())



func _ship_mastery_leveled(ship_id: String, level: int) -> void:
	var profile := ShipCatalog.profile_by_id(ship_id)
	note("%s · SCHIFFSLEVEL %d" % [str(profile.get("display_name", ship_id)).to_upper(), level])
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player != null:
		player.set_meta("last_mastery_hook", MasteryRewardHooks.event_payload(ship_id, level))
		CombatVfx.action(get_tree(), "mastery_level_up", player.global_position)
	queue_redraw()


func _input(event: InputEvent) -> void:
	# M223: the full chart owns pointer input while open so taps never sail the ship behind the overlay.
	if global_map_open:
		# M224: wheel/pinch-equivalent controls affect only the visual full-chart transform.
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			full_chart_zoom = clampf(full_chart_zoom + (0.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.15), M224SeaChartPresentationCatalog.MIN_ZOOM, M224SeaChartPresentationCatalog.MAX_ZOOM)
			queue_redraw(); get_viewport().set_input_as_handled(); return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_m224_chart_dragging = true; _m224_chart_drag_origin = event.position; _m224_chart_pan_origin = full_chart_pan
			else:
				_m224_chart_dragging = false
		if event is InputEventMouseMotion and _m224_chart_dragging and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var delta: Vector2 = (event as InputEventMouseMotion).position - _m224_chart_drag_origin
			if delta.length() > 8.0:
				full_chart_pan = M224SeaChartPresentationCatalog.clamp_pan(_m224_chart_pan_origin + delta / maxf(220.0, 220.0 * full_chart_zoom), full_chart_zoom)
				queue_redraw(); get_viewport().set_input_as_handled(); return
		var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
		if pressed:
			var point: Vector2 = (event as InputEventMouseButton).position if event is InputEventMouseButton else (event as InputEventScreenTouch).position
			if _m223_activate_chart_at(point):
				get_viewport().set_input_as_handled()
				return
	var m226_pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed)
	if m226_pressed and _m226_activate_harbor_service_at(event.position):
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if not combat_detail_id.is_empty():
		close_combat_detail()
	elif not combat_picker.is_empty():
		close_combat_picker()
	elif global_map_open:
		global_map_open = false
		queue_redraw()
	elif menu_open:
		close_menu()
	else:
		return
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_m280_sync_reward_visual_state()
	_m281_sync_combat_hud_state()
	_m282_sync_combat_feedback_state()
	_m283_sync_projectile_presentation_state()
	_m284_sync_naval_combat_identity_state()
	_m285_sync_ship_damage_defeat_state()
	_m286_sync_ship_damage_escalation_state()
	_m287_sync_ship_motion_identity_state()
	_m288_sync_naval_contact_readability_state()
	_m289_sync_playable_vertical_slice_state()
	_m290_sync_first_sortie_state()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.get_meta("settings_open", false): return
	if _last_compact != bool(layout().compact):
		_last_compact = bool(layout().compact)
		log_open = false
	if Input.is_action_just_pressed("map_toggle"):
		if menu_open:
			close_menu()
		else:
			toggle_global_map()
	_m231_update_encounter_zone_feedback(player as ShipMotor)
	_m232_update_world_event_awareness(player as ShipMotor)
	_m233_update_world_event_lifecycle(player as ShipMotor)
	_m234_update_world_event_objectives(player as ShipMotor)
	_m235_update_world_event_contribution(player as ShipMotor)
	queue_redraw()


func _m231_update_encounter_zone_feedback(player:ShipMotor)->void:
	# M231: presentation-only crossing read. No aggro/combat/navigation authority is changed here.
	if player==null:return
	var now:=Time.get_ticks_msec()/1000.0
	var nearest:=M231EncounterZoneFeedbackCatalog.nearest_relevant(player,get_tree().get_nodes_in_group("enemies"))
	var active_key:=""
	var active_read:=""
	var active_node:Node3D=null
	if not nearest.is_empty():
		active_node=nearest.get("node") as Node3D
		var distance:=float(nearest.get("distance",INF))
		var radius:=float(nearest.get("radius",0.0))
		var candidate_key:=str(nearest.get("key",""))
		var inside:=distance<=radius
		if candidate_key==_m231_zone_key and not _m231_zone_key.is_empty():
			inside=distance<=radius+M231EncounterZoneFeedbackCatalog.EXIT_HYSTERESIS
		if inside:
			active_key=candidate_key
			active_read=str(nearest.get("read",""))
	if active_key==_m231_zone_key:return
	if now-_m231_last_change<M231EncounterZoneFeedbackCatalog.CHANGE_COOLDOWN:return
	if not _m231_zone_key.is_empty() and active_key.is_empty():
		_m231_zone_label=M231EncounterZoneFeedbackCatalog.leave_label(_m231_zone_read)
		_m231_zone_hint=""
		_m231_zone_feedback_until=now+M231EncounterZoneFeedbackCatalog.MESSAGE_SECONDS
	elif not active_key.is_empty():
		_m231_zone_label=M231EncounterZoneFeedbackCatalog.enter_label(active_node)
		_m231_zone_hint=M231EncounterZoneFeedbackCatalog.regional_hint(active_node)
		_m231_zone_feedback_until=now+M231EncounterZoneFeedbackCatalog.MESSAGE_SECONDS
	_m231_zone_key=active_key
	_m231_zone_read=active_read
	_m231_last_change=now
	player.set_meta("m231_zone_feedback",_m231_zone_label)

func _m231_draw_encounter_zone_feedback(safe:Rect2,scale_value:float)->void:
	if _m231_zone_label.is_empty() or Time.get_ticks_msec()/1000.0>=_m231_zone_feedback_until:return
	# Compact upper-world read; no permanent center banner.
	var width:=minf(360.0*scale_value,safe.size.x*0.72)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+132.0*scale_value),Vector2(width,42.0*scale_value))
	draw_rect(rect,Color(0.035,0.055,0.07,0.78),true)
	_draw_centered(_m231_zone_label,rect.position+Vector2(rect.size.x*0.5,16.0*scale_value),int(12.0*scale_value),Color("ffd27a"))
	if not _m231_zone_hint.is_empty():
		_draw_centered(_m231_zone_hint,rect.position+Vector2(rect.size.x*0.5,31.0*scale_value),int(8.0*scale_value),TEXT.darkened(0.12))

func _m232_update_world_event_awareness(player:ShipMotor)->void:
	# M232: reads EventRuntime + existing event-owned world nodes only. No event/gameplay authority.
	if player==null:return
	var runtime:=M232WorldEventAwarenessCatalog.event_runtime(get_tree())
	var state:=M232WorldEventAwarenessCatalog.event_state(runtime)
	if state.is_empty():
		_m232_event_inside=false; _m232_event_zone_key=""; _m232_event_phase=-1
		return
	var now:=Time.get_ticks_msec()/1000.0
	var phase_now:=int(state.get("phase",-1))
	if _m232_event_phase>=0 and phase_now!=_m232_event_phase:
		_m232_event_label=M232WorldEventAwarenessCatalog.phase_label(runtime)
		_m232_event_hint="WORLD-EVENT · %.0f%%"%(float(state.get("meter",0.0))*100.0)
		_m232_event_feedback_until=now+M232WorldEventAwarenessCatalog.PHASE_FEEDBACK_SECONDS
	_m232_event_phase=phase_now
	var nearest:=M232WorldEventAwarenessCatalog.nearest_anchor(player,get_tree(),str(state.get("id","")))
	var inside_now:=false
	var next_key:=""
	if not nearest.is_empty():
		var distance:=float(nearest.get("distance",INF))
		var radius:=M232WorldEventAwarenessCatalog.EVENT_ENTER_RADIUS
		if _m232_event_inside:radius+=M232WorldEventAwarenessCatalog.EVENT_EXIT_HYSTERESIS
		inside_now=distance<=radius
		if inside_now:next_key=str(nearest.get("key",""))
	if inside_now!=_m232_event_inside and now-_m232_event_last_change>=1.0:
		_m232_event_label=M232WorldEventAwarenessCatalog.enter_label(runtime) if inside_now else M232WorldEventAwarenessCatalog.leave_label(runtime)
		_m232_event_hint="%s · %.0f%%"%[runtime.phase_label().to_upper(),runtime.meter_ratio()*100.0]
		_m232_event_feedback_until=now+M232WorldEventAwarenessCatalog.FEEDBACK_SECONDS
		_m232_event_inside=inside_now; _m232_event_zone_key=next_key; _m232_event_last_change=now
		player.set_meta("m232_event_feedback",_m232_event_label)
	if not nearest.is_empty():
		var node:=nearest.get("node") as Node3D
		var boss_key:=str(nearest.get("key",""))
		if node!=null and M232WorldEventAwarenessCatalog.boss_presence(node) and float(nearest.get("distance",INF))<=M232WorldEventAwarenessCatalog.BOSS_ANNOUNCE_RADIUS:
			if boss_key!=_m232_last_boss_key or now-_m232_last_boss_announce>=M232WorldEventAwarenessCatalog.BOSS_COOLDOWN:
				_m232_event_label=M232WorldEventAwarenessCatalog.boss_label(node)
				_m232_event_hint="%s · %s"%[runtime.title().to_upper(),runtime.phase_label().to_upper()]
				_m232_event_feedback_until=now+M232WorldEventAwarenessCatalog.FEEDBACK_SECONDS
				_m232_last_boss_key=boss_key; _m232_last_boss_announce=now

func _m232_draw_world_event_awareness(safe:Rect2,scale_value:float)->void:
	if _m232_event_label.is_empty() or Time.get_ticks_msec()/1000.0>=_m232_event_feedback_until:return
	# Short-lived upper safe-area read; never a permanent center overlay.
	var width:=minf(430.0*scale_value,safe.size.x*0.78)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+180.0*scale_value),Vector2(width,44.0*scale_value))
	draw_rect(rect,Color(0.03,0.045,0.075,0.82),true)
	draw_rect(rect,Color(0.42,0.67,0.85,0.68),false,1.4*scale_value)
	_draw_centered(_m232_event_label,rect.position+Vector2(rect.size.x*0.5,17.0*scale_value),int(11.0*scale_value),Color("9fe6ff"))
	if not _m232_event_hint.is_empty():
		_draw_centered(_m232_event_hint,rect.position+Vector2(rect.size.x*0.5,33.0*scale_value),int(8.0*scale_value),TEXT.darkened(0.1))

func _m233_update_world_event_lifecycle(player:ShipMotor)->void:
	# M233 observes EventRuntime/client-replicated lifecycle only. Never schedules or advances an event.
	if player==null:return
	var runtime_value:=M233WorldEventLifecycleCatalog.runtime(get_tree())
	var snapshot:=M233WorldEventLifecycleCatalog.lifecycle(runtime_value)
	var next_state:=str(snapshot.get("state","inactive"))
	var title:=runtime_value.title() if runtime_value!=null and runtime_value.is_active() else _m233_event_title
	if runtime_value!=null and runtime_value.is_active():_m233_event_title=runtime_value.title()
	var transition:=M233WorldEventLifecycleCatalog.transition_label(_m233_event_state,next_state,title)
	if not transition.is_empty():
		_m233_event_label=transition
		_m233_event_hint=M233WorldEventLifecycleCatalog.timing_hint(snapshot)
		_m233_event_feedback_until=Time.get_ticks_msec()/1000.0+(M233WorldEventLifecycleCatalog.WARNING_SECONDS if next_state=="warning" else M233WorldEventLifecycleCatalog.FEEDBACK_SECONDS)
		player.set_meta("m233_event_lifecycle_feedback",_m233_event_label)
	_m233_event_state=next_state
	if runtime_value!=null and runtime_value.is_active():M233WorldEventLifecycleCatalog.stamp_objectives(get_tree(),runtime_value,next_state)

func _m233_draw_world_event_lifecycle(safe:Rect2,scale_value:float)->void:
	if _m233_event_label.is_empty() or Time.get_ticks_msec()/1000.0>=_m233_event_feedback_until:return
	var width:=minf(450.0*scale_value,safe.size.x*0.80)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+228.0*scale_value),Vector2(width,44.0*scale_value))
	draw_rect(rect,Color(0.035,0.035,0.07,0.84),true)
	draw_rect(rect,Color(0.72,0.58,0.94,0.72),false,1.4*scale_value)
	_draw_centered(_m233_event_label,rect.position+Vector2(rect.size.x*0.5,17.0*scale_value),int(11.0*scale_value),Color("d9bcff"))
	if not _m233_event_hint.is_empty():_draw_centered(_m233_event_hint,rect.position+Vector2(rect.size.x*0.5,33.0*scale_value),int(8.0*scale_value),TEXT.darkened(0.08))

func _m234_update_world_event_objectives(player:ShipMotor)->void:
	# M234 reads replicated/runtime objective state only; never advances phases or publishes/grants rewards.
	if player==null:return
	var runtime_value:=M234WorldEventObjectiveChainCatalog.runtime(get_tree())
	if runtime_value==null or not runtime_value.is_active():
		_m234_event_objective_snapshot={}
		return
	var next_snapshot:=M234WorldEventObjectiveChainCatalog.objective_snapshot(runtime_value)
	var transition:=M234WorldEventObjectiveChainCatalog.transition_label(_m234_event_objective_snapshot,next_snapshot,runtime_value.title())
	if not transition.is_empty():
		_m234_event_label=transition
		_m234_event_hint=M234WorldEventObjectiveChainCatalog.progress_label(runtime_value)
		_m234_event_feedback_until=Time.get_ticks_msec()/1000.0+M234WorldEventObjectiveChainCatalog.FEEDBACK_SECONDS
		player.set_meta("m234_event_objective_feedback",_m234_event_label)
	_m234_event_objective_snapshot=next_snapshot.duplicate(true)
	M234WorldEventObjectiveChainCatalog.stamp_world_objectives(get_tree(),runtime_value)

func _m234_draw_world_event_objectives(safe:Rect2,scale_value:float)->void:
	if _m234_event_label.is_empty() or Time.get_ticks_msec()/1000.0>=_m234_event_feedback_until:return
	var width:=minf(470.0*scale_value,safe.size.x*0.82)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+276.0*scale_value),Vector2(width,44.0*scale_value))
	draw_rect(rect,Color(0.04,0.03,0.065,0.84),true)
	draw_rect(rect,Color(0.82,0.66,0.30,0.75),false,1.4*scale_value)
	_draw_centered(_m234_event_label,rect.position+Vector2(rect.size.x*0.5,17.0*scale_value),int(11.0*scale_value),Color("ffd98a"))
	if not _m234_event_hint.is_empty():_draw_centered(_m234_event_hint,rect.position+Vector2(rect.size.x*0.5,33.0*scale_value),int(8.0*scale_value),TEXT.darkened(0.08))

func _m235_update_world_event_contribution(player:ShipMotor)->void:
	# M235 is read-only presentation of a server contribution/rank/eligibility replica.
	if player==null:return
	var runtime_value:=M235WorldEventContributionCatalog.runtime(get_tree())
	if runtime_value==null or not runtime_value.is_active():
		_m235_contribution_snapshot={}
		return
	var next_snapshot:=M235WorldEventContributionCatalog.snapshot(runtime_value)
	var transition:=M235WorldEventContributionCatalog.transition_label(_m235_contribution_snapshot,next_snapshot)
	if not transition.is_empty():
		_m235_contribution_label=transition
		_m235_contribution_hint=M235WorldEventContributionCatalog.compact_label(next_snapshot)
		_m235_contribution_feedback_until=Time.get_ticks_msec()/1000.0+M235WorldEventContributionCatalog.FEEDBACK_SECONDS
		player.set_meta("m235_event_contribution_feedback",_m235_contribution_label)
	_m235_contribution_snapshot=next_snapshot.duplicate(true)

func _m235_draw_world_event_contribution(safe:Rect2,scale_value:float)->void:
	if _m235_contribution_label.is_empty() or Time.get_ticks_msec()/1000.0>=_m235_contribution_feedback_until:return
	var width:=minf(470.0*scale_value,safe.size.x*0.82)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+324.0*scale_value),Vector2(width,44.0*scale_value))
	draw_rect(rect,Color(0.025,0.045,0.06,0.84),true)
	draw_rect(rect,Color(0.35,0.78,0.66,0.75),false,1.4*scale_value)
	_draw_centered(_m235_contribution_label,rect.position+Vector2(rect.size.x*0.5,17.0*scale_value),int(11.0*scale_value),Color("9fffdc"))
	if not _m235_contribution_hint.is_empty():_draw_centered(_m235_contribution_hint,rect.position+Vector2(rect.size.x*0.5,33.0*scale_value),int(8.0*scale_value),TEXT.darkened(0.08))

func active_boss_telegraph()->Dictionary:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if player==null:return {}
	var nearest:ShipMotor=null
	var nearest_distance:=99999.0
	for node in get_tree().get_nodes_in_group("enemy"):
		var ship:=node as ShipMotor
		if ship==null:continue
		var kind:=str(ship.get_meta("danger_telegraph",""))
		if kind.is_empty():continue
		var distance:=player.global_position.distance_to(ship.global_position)
		if distance<nearest_distance:
			nearest=ship;nearest_distance=distance
	if nearest==null:return {}
	var kind:=str(nearest.get_meta("danger_telegraph",""))
	var fallback_label:="RELIC BARRIER" if kind=="relic_barrier" else ("PRESSURE PULSE" if kind=="pressure_pulse" else kind.replace("_"," ").to_upper())
	var until:=float(nearest.get_meta("danger_telegraph_until",Time.get_ticks_msec()/1000.0))
	return {"kind":kind,"label":str(nearest.get_meta("boss_mechanic_label",fallback_label)).to_upper(),"distance":nearest_distance,"remaining":maxf(0.0,until-Time.get_ticks_msec()/1000.0),"duration":maxf(0.01,float(nearest.get_meta("danger_telegraph_duration",1.0))),"color":Color(str(nearest.get_meta("danger_telegraph_color","#B46CFF")))}


func toggle_combat_picker(kind: String) -> void:
	if kind not in ["ammo", "items"]:
		return
	combat_detail_id = ""
	combat_picker = "" if combat_picker == kind else kind
	if not combat_picker.is_empty():
		global_map_open = false
		close_menu()
	queue_redraw()


func close_combat_picker() -> void:
	combat_picker = ""
	combat_detail_id = ""
	queue_redraw()

func show_combat_detail(id: String) -> void:
	if combat_picker.is_empty() or id in ["", "close", "dismiss"]:
		return
	combat_detail_id = id
	queue_redraw()

func close_combat_detail() -> void:
	combat_detail_id = ""
	queue_redraw()


func combat_picker_layout() -> Dictionary:
	var geometry := layout()
	var safe: Rect2 = geometry.safe
	var sx: float = float(geometry.get("ui_scale", 1.0))
	var landscape_grid := safe.size.x / maxf(1.0, safe.size.y) > 1.35 and safe.size.x >= 700.0
	var columns := 2 if landscape_grid else 1
	var ids: Array[String] = []
	if combat_picker == "ammo":
		ids = CombatCatalog.ammo_ids()
		for row in SupportPayloadCatalog.harpoon_payloads(): ids.append(str(row.get("id", "")))
		for row in SupportPayloadCatalog.support_ammo(): ids.append(str(row.get("id", "")))
	else:
		# M171: action-item selector is catalog-driven. New content records appear without editing this UI.
		ids = ActionItemCatalog.item_ids()
		for supply_id in ["powder", "plates", "harpoon"]:
			if supply_id not in ids: ids.append(supply_id)
	var desired_card_h := (78.0 if landscape_grid else 68.0) * sx
	var available_h := maxf(260.0 * sx, safe.size.y - 42.0 * sx)
	var card_h := minf(desired_card_h, maxf(52.0 * sx, (available_h - 58.0 * sx) / ceili(float(ids.size()) / float(columns))))
	var title_h := 58.0 * sx
	var rows_count := ceili(float(ids.size()) / float(columns))
	var width := minf((760.0 if landscape_grid else 540.0) * sx, safe.size.x - 28.0 * sx)
	var max_panel_h := maxf(180.0 * sx, safe.size.y - 24.0 * sx)
	var height := minf(title_h + card_h * rows_count + 16.0 * sx, max_panel_h)
	if rows_count > 0:
		card_h = minf(card_h, maxf(44.0 * sx, (height - title_h - 16.0 * sx) / float(rows_count)))
	var x := safe.get_center().x - width * 0.5
	var y_min := safe.position.y + 12.0 * sx
	var y_max := maxf(y_min, safe.end.y - height - 12.0 * sx)
	var y := clampf(safe.get_center().y - height * 0.5, y_min, y_max)
	var panel := Rect2(Vector2(x, y), Vector2(width, height))
	var rows := {}
	var gap := 8.0 * sx
	var inner_w := panel.size.x - 20.0 * sx
	var card_w := (inner_w - gap * float(columns - 1)) / float(columns)
	for i in ids.size():
		var col := i % columns
		var row_index := i / columns
		rows[ids[i]] = Rect2(panel.position + Vector2(10.0 * sx + col * (card_w + gap), title_h + row_index * card_h), Vector2(card_w, card_h - 7.0 * sx))
	var close_rect := Rect2(Vector2(panel.end.x - 48.0 * sx, panel.position.y + 8.0 * sx), Vector2(40, 40) * sx)
	return {"panel": panel, "rows": rows, "close": close_rect, "ui_scale": sx, "columns": columns, "landscape_grid": landscape_grid}


func combat_picker_action_at(point: Vector2) -> String:
	if combat_picker.is_empty():
		return ""
	var data := combat_picker_layout()
	if not combat_detail_id.is_empty():
		var panel: Rect2 = data.panel
		var sx: float = float(data.ui_scale)
		var detail_rect := Rect2(panel.position + Vector2(18, 58) * sx, panel.size - Vector2(36, 76) * sx)
		var detail_close := Rect2(detail_rect.end - Vector2(48, detail_rect.size.y - 8) * sx, Vector2(40, 40) * sx)
		if detail_close.has_point(point) or not detail_rect.has_point(point): return "detail_close"
		var bind_gap := 6.0 * sx
		var bind_available := maxf(120.0 * sx, detail_rect.size.x - 36.0 * sx)
		var bind_w := maxf(46.0 * sx, (bind_available - bind_gap * 3.0) / 4.0)
		var bind_size := Vector2(bind_w, 38.0 * sx)
		var bind_y := detail_rect.end.y - 50.0 * sx
		var bind_start_x := detail_rect.position.x + 18.0 * sx
		for i in 4:
			var bind_rect := Rect2(Vector2(bind_start_x + i * (bind_size.x + bind_gap), bind_y), bind_size)
			if bind_rect.has_point(point): return "bind_%d" % i
		return ""
	if (data.close as Rect2).has_point(point):
		return "close"
	for id in data.rows:
		if (data.rows[id] as Rect2).has_point(point):
			return str(id)
	return "dismiss" if not (data.panel as Rect2).has_point(point) else ""


func activate_combat_picker_action(action: String) -> void:
	if action == "detail_close":
		close_combat_detail()
		return
	if action.begins_with("bind_"):
		var bind_player := get_tree().get_first_node_in_group("player") as ShipMotor
		if bind_player == null or combat_detail_id.is_empty():
			return
		var inventory := bind_player.get_node("Inventory") as PlayerInventory
		var slot := int(action.trim_prefix("bind_"))
		var kind := inventory.quick_binding_kind(combat_detail_id)
		if inventory.assign_quickslot(slot, combat_detail_id, kind):
			note("Quickslot %d: %s" % [slot + 1, combat_detail_id])
		queue_redraw()
		return
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null:
		close_combat_picker()
		return
	var weapons := player.get_node("Weapons") as ShipWeapons
	var inventory := player.get_node("Inventory") as PlayerInventory
	var input := player.get_node("PlayerInput") as PlayerShipInput
	var runtime_ammo_index:=CombatCatalog.ammo_index_by_id(action)
	if runtime_ammo_index>=0:
		weapons.select_mode("cannon")
		weapons.ammo_index=runtime_ammo_index
		weapons.loadout_changed.emit()
		note("Munition: "+weapons.ammo_name())
		close_combat_picker()
		return
	# M171: resolve payload/support families by their runtime catalogs before generic action items.
	for row in SupportPayloadCatalog.harpoon_payloads():
		if str(row.get("id", "")) == action:
			weapons.select_harpoon_payload(action)
			note("Harpunen-Payload: " + weapons.ammo_name())
			close_combat_picker(); return
	for row in SupportPayloadCatalog.support_ammo():
		if str(row.get("id", "")) == action:
			weapons.select_support_ammo(action)
			note("Support-Munition: " + weapons.ammo_name())
			close_combat_picker(); return
	match action:
		"harpoon":
			weapons.select_mode("harpoon")
			MonsterTeachingState.mark_harpoon_selected(player)
			note("Jagdharpune gewählt")
		"powder", "plates":
			inventory.toggle_supply(action)
			note(("Schwarzpulver" if action == "powder" else "Panzerplatten") + (" aktiv" if (inventory.powder_enabled if action == "powder" else inventory.plates_enabled) else " aus"))
		"close", "dismiss": pass
		_:
			var definition := ActionItemCatalog.item(action)
			if definition.is_empty(): return
			var used := input.use_action_item(action)
			note(str(definition.get("name", action)) + (" aktiviert" if used else " nicht verfügbar / Ziel / Cooldown prüfen"))
	close_combat_picker()





func halloween_event_prompt()->Dictionary:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	return HalloweenEventInteraction.prompt(player)

func halloween_event_interaction_layout()->Dictionary:
	var prompt:=halloween_event_prompt()
	if prompt.is_empty():return {}
	var geometry:=layout()
	var safe:Rect2=geometry.safe
	var sx:=float(geometry.get("ui_scale",1.0))
	var width:=minf(330.0*sx,safe.size.x-20.0*sx)
	var button:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.end.y-88.0*sx),Vector2(width,54.0*sx))
	return {"button":button,"prompt":prompt,"ui_scale":sx}

func halloween_event_action_at(point:Vector2)->bool:
	var data:=halloween_event_interaction_layout()
	return not data.is_empty() and (data.button as Rect2).has_point(point)

func activate_halloween_event_interaction()->bool:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	var result:=HalloweenEventInteraction.activate(player)
	if not bool(result.get("ok",false)):return false
	note(str(result.get("message","Eventinteraktion")))
	queue_redraw()
	return true

func guild_island_prompt()->Dictionary:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	return GuildIslandInteraction.prompt(player)

func guild_island_interaction_layout()->Dictionary:
	var prompt:=guild_island_prompt()
	if prompt.is_empty():return {}
	var geometry:=layout()
	var safe:Rect2=geometry.safe
	var sx:=float(geometry.get("ui_scale",1.0))
	var compact:=bool(geometry.get("compact",false))
	var actions:Array=prompt.get("actions",[])
	var narrow:=safe.size.y<620.0 or safe.size.x<900.0
	var width:=minf((390.0 if narrow else (420.0 if compact else 520.0))*sx,safe.size.x-20.0*sx)
	var row_h:=(42.0 if narrow else (48.0 if compact else 54.0))*sx
	var header_h:=(40.0 if narrow else 48.0)*sx
	var height:=header_h+(row_h*actions.size())
	var bottom_margin:=(10.0 if narrow else 18.0)*sx
	var bottom_candidate:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.end.y-height-bottom_margin),Vector2(width,height))
	var top_candidate:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+58.0*sx),Vector2(width,height))
	var reserved:=NauticalLayout.reserved(geometry,log_visible())
	var bottom_hits:=0
	var top_hits:=0
	for r in reserved:
		if bottom_candidate.intersects(r):bottom_hits+=1
		if top_candidate.intersects(r):top_hits+=1
	var panel:=bottom_candidate if bottom_hits<=top_hits else top_candidate
	panel.position.y=clampf(panel.position.y,safe.position.y+6.0*sx,maxf(safe.position.y+6.0*sx,safe.end.y-panel.size.y-6.0*sx))
	var rows:Dictionary={}
	for i in actions.size():
		rows[str(actions[i].get("id",""))]=Rect2(panel.position+Vector2(7.0*sx,header_h+i*row_h),Vector2(panel.size.x-14.0*sx,row_h-4.0*sx))
	return {"panel":panel,"rows":rows,"ui_scale":sx,"prompt":prompt,"narrow":narrow}

func guild_island_action_icon(id:String)->String:
	return {
		"dock":"m99_guild_dock",
		"inspect_guild":"m99_guild_hall",
		"inspect_defense":"m99_guild_defense",
		"inspect_facilities":"m99_guild_facilities",
		"inspect_harbor":"m99_guild_dock",
		"range_preview":"m99_guild_range"
	}.get(id,"m99_guild_focus")

func guild_island_detail_layout()->Dictionary:
	var data:=guild_island_interaction_layout()
	var panel_data:=guild_island_panel_data()
	if data.is_empty() or panel_data.is_empty():return {}
	var rows:Array=panel_data.get("rows",[])
	if rows.is_empty():return {}
	var panel:Rect2=data.panel
	var sx:=float(data.ui_scale)
	var row_h:=31.0*sx
	var height:=minf((42.0+mini(rows.size(),4)*31.0)*sx,190.0*sx)
	var safe:Rect2=(layout().safe as Rect2)
	var above:=Rect2(Vector2(panel.position.x,panel.position.y-height-8.0*sx),Vector2(panel.size.x,height))
	var below:=Rect2(Vector2(panel.position.x,panel.end.y+8.0*sx),Vector2(panel.size.x,height))
	var rect:=above if safe.encloses(above) else below
	if not safe.encloses(rect):
		rect.position.y=clampf(rect.position.y,safe.position.y+6.0*sx,maxf(safe.position.y+6.0*sx,safe.end.y-rect.size.y-6.0*sx))
	var visible_count:=mini(rows.size(),4)
	guild_island_focus_index=clampi(guild_island_focus_index,0,maxi(0,rows.size()-1))
	var first_index:=clampi(guild_island_focus_index-floori(visible_count*0.5),0,maxi(0,rows.size()-visible_count))
	var row_rects:Array[Rect2]=[]
	var row_indices:Array[int]=[]
	for i in visible_count:
		row_rects.append(Rect2(rect.position+Vector2(8,29+i*31)*sx,Vector2(rect.size.x-16*sx,row_h)))
		row_indices.append(first_index+i)
	return {"panel":rect,"rows":row_rects,"row_indices":row_indices,"first_index":first_index,"ui_scale":sx,"data":panel_data}

func guild_island_detail_row_at(point:Vector2)->int:
	var detail:=guild_island_detail_layout()
	if detail.is_empty():return -1
	var rows:Array=detail.rows
	var indices:Array=detail.get("row_indices",[])
	for i in rows.size():
		if (rows[i] as Rect2).has_point(point):return int(indices[i]) if i<indices.size() else i
	return -1

func guild_island_set_focus(index:int)->void:
	var data:=guild_island_panel_data()
	var rows:Array=data.get("rows",[])
	if rows.is_empty():return
	guild_island_focus_index=clampi(index,0,rows.size()-1)
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	var island:=GuildIslandInteraction.nearest(player)
	if island==null:return
	var row:Dictionary=rows[guild_island_focus_index]
	var kind:=str(data.get("focus_kind",""))
	var id:=str(row.get("role","")) if kind=="tower" else str(row.get("id",""))
	GuildIslandVisualState.set_focus(island,kind,id)
	guild_island_panel_until=Time.get_ticks_msec()+5200
	queue_redraw()

func guild_island_action_at(point:Vector2)->String:
	var data:=guild_island_interaction_layout()
	if data.is_empty():return ""
	for id in data.rows:
		if (data.rows[id] as Rect2).has_point(point):return str(id)
	return ""

func guild_island_focus(delta:int)->void:
	var data:=guild_island_panel_data()
	var rows:Array=data.get("rows",[])
	if rows.is_empty():return
	guild_island_set_focus(posmod(guild_island_focus_index+delta,rows.size()))

func guild_island_selected_row()->Dictionary:
	var data:=guild_island_panel_data()
	var rows:Array=data.get("rows",[])
	if rows.is_empty():return {}
	guild_island_focus_index=clampi(guild_island_focus_index,0,rows.size()-1)
	return rows[guild_island_focus_index]

func activate_guild_island_action(id:String)->void:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	var result:=GuildIslandInteraction.activate(player,id)
	if not bool(result.get("ok",false)):return
	guild_island_panel=id
	guild_island_panel_until=Time.get_ticks_msec()+5200
	guild_island_focus_index=0
	var rows:Array=result.get("rows",[])
	var island:=GuildIslandInteraction.nearest(player)
	if island!=null and not rows.is_empty():
		var kind:=str(result.get("focus_kind",""))
		var first:Dictionary=rows[0]
		var focus_id:=str(first.get("role","")) if kind=="tower" else str(first.get("id",""))
		GuildIslandVisualState.set_focus(island,kind,focus_id)
	var title:=str(result.get("label",id))
	note("%s · %s"%[title,"SERVER NÖTIG" if str(result.get("authority",""))=="presentation_only" else "VORSCHAU"])
	queue_redraw()

func guild_island_panel_data()->Dictionary:
	if guild_island_panel.is_empty() or Time.get_ticks_msec()>guild_island_panel_until:return {}
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	return GuildIslandInteraction.activate(player,guild_island_panel)

func activate_quickslot(index: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null:
		return
	var inventory := player.get_node("Inventory") as PlayerInventory
	var weapons := player.get_node("Weapons") as ShipWeapons
	var input := player.get_node("PlayerInput") as PlayerShipInput
	var binding := inventory.quickslot(index)
	var id := str(binding.get("id", ""))
	var kind := str(binding.get("kind", ""))
	if id.is_empty():
		return
	match kind:
		"ammo":
			weapons.select_mode("cannon")
			weapons.ammo_index = CombatCatalog.ammo_index_by_id(id)
			weapons.loadout_changed.emit()
			note("Quick %d · Munition: %s" % [index + 1, weapons.ammo_name()])
		"mode":
			weapons.select_mode("harpoon")
			note("Quick %d · Jagdharpune" % [index + 1])
		"supply":
			inventory.toggle_supply(id)
			note("Quick %d · %s" % [index + 1, id])
		"item":
			var used := input.use_action_item(id)
			var definition := ActionItemCatalog.item(id)
			note("Quick %d · %s%s" % [index + 1, str(definition.get("name", id)), "" if used else " nicht verfügbar"])
		_: return
	queue_redraw()


func toggle_global_map() -> void:
	combat_picker = ""
	if menu_open:
		close_menu()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and (player.get_meta("inventory_open", false) or player.get_meta("journal_open", false)):
		return
	global_map_open = not global_map_open
	if global_map_open:
		full_chart_view = "sector"
		full_chart_filter = "all"
		full_chart_selected = null
	if global_map_open and player != null:
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()


func poi_context_prompt()->String:
	var captain:=get_tree().get_first_node_in_group("player") as ShipMotor
	return DynamicPoiInteraction.prompt(get_tree(),captain) if captain!=null else ""

func _draw_poi_context_prompt()->void:
	var prompt:=poi_context_prompt()
	if prompt.is_empty() or menu_open or global_map_open:return
	var safe:=_safe_rect();var compact:=safe.size.x<720.0
	var width:=minf(330.0,safe.size.x-24.0);var height:=52.0 if compact else 46.0
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.end.y-height-96.0),Vector2(width,height))
	draw_style_box(NauticalHud.panel(Color(0.02,0.08,0.11,0.94),Color(0.27,0.78,0.82,0.9),12.0),rect)
	draw_string(font,rect.position+Vector2(14.0,30.0),prompt,HORIZONTAL_ALIGNMENT_CENTER,width-28.0,14 if compact else 15,Color.WHITE)

func _draw() -> void:
	var danger:=active_boss_telegraph()
	if not danger.is_empty():
		var geometry:=layout()
		var safe:Rect2=geometry.safe
		var width:=minf(360.0,safe.size.x-28.0)
		var warning_y:float=(geometry.top as Rect2).end.y+8.0
		if (geometry.objective_strip as Rect2).has_area():warning_y=maxf(warning_y,(geometry.objective_strip as Rect2).end.y+6.0)
		var accent:Color=danger.color
		var rect:=Rect2(Vector2(safe.position.x+(safe.size.x-width)*0.5,warning_y),Vector2(width,46.0))
		draw_style_box(NauticalHud.panel(Color(accent.r*0.22,accent.g*0.12,accent.b*0.24,0.94),Color(accent.r,accent.g,accent.b,0.92),12.0),rect)
		var seconds:="%.1fs"%float(danger.remaining)
		draw_string(font,rect.position+Vector2(14,27),"⚠ "+str(danger.label),HORIZONTAL_ALIGNMENT_LEFT,width-82,16,Color.WHITE)
		draw_string(font,rect.position+Vector2(width-67,27),seconds,HORIZONTAL_ALIGNMENT_RIGHT,53,14,Color.WHITE)
		var progress:=clampf(float(danger.remaining)/float(danger.duration),0.0,1.0)
		draw_rect(Rect2(rect.position+Vector2(10,38),Vector2(width-20,4)),Color(0.01,0.04,0.06,0.78))
		draw_rect(Rect2(rect.position+Vector2(10,38),Vector2((width-20)*progress,4)),accent)
	NauticalHud.paint(self)
	_draw_m216_defeat_respawn_overlay()
	_draw_poi_context_prompt()



func _draw_m216_defeat_respawn_overlay() -> void:
	# M216 explicit defeat/respawn state: this is presentation only and intentionally sits above normal HUD paint.
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var health := player.get_node_or_null("Health") as ShipHealth
	if health == null or not health.is_sunk: return
	var safe := _safe_rect()
	var width := minf(460.0, safe.size.x - 30.0)
	var rect := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - 58.0), Vector2(width, 116.0))
	draw_style_box(NauticalHud.panel(Color(0.10,0.025,0.025,0.95), Color(0.93,0.28,0.22,0.94), 14.0), rect)
	_draw_centered("SCHIFF VERSENKT", rect.position + Vector2(rect.size.x * 0.5, 37.0), 23, Color("ffd7cc"))
	var respawn_at := int(player.get_meta("respawn_at_msec", Time.get_ticks_msec()))
	var remaining := maxf(0.0, float(respawn_at - Time.get_ticks_msec()) / 1000.0)
	_draw_centered("Rückkehr zum Hafen · %.1f s" % remaining, rect.position + Vector2(rect.size.x * 0.5, 70.0), 15, Color.WHITE)
	_draw_centered("Gegnerbeschuss endet bis zum Respawn; danach gilt Schutzzeit.", rect.position + Vector2(rect.size.x * 0.5, 96.0), 12, Color("d9c7bf"))

func layout() -> Dictionary:
	return NauticalLayout.calculate(_safe_rect())


func log_visible() -> bool:
	return log_open and not global_map_open and not menu_open


func open_menu(page: String) -> void:
	var owner_ship := get_tree().get_first_node_in_group("player")
	if owner_ship != null and (owner_ship.get_meta("inventory_open", false) or owner_ship.get_meta("journal_open", false) or owner_ship.get_meta("settings_open", false) or owner_ship.get_meta("external_panel_open", false)): return
	if owner_ship != null: owner_ship.set_meta("command_open", true)
	menu_page = page
	menu_open = true
	global_map_open = false
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player != null:
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()
	note(_menu_title(page) + " geöffnet")
	command_deck.page_history.clear()
	command_deck.open_page(page)


func close_menu() -> void:
	if is_instance_valid(command_deck): command_deck.hide()
	var player := get_tree().get_first_node_in_group("player")
	if player != null: player.set_meta("command_open", false)
	menu_open = false
	menu_page = ""


func route_panel(panel: Control, return_page := "home") -> void:
	if panel == null: return
	combat_picker = ""
	combat_detail_id = ""
	global_map_open = false
	if menu_open: close_menu()
	if is_instance_valid(routed_panel) and routed_panel != panel:
		routed_panel.set_meta("router_replaced", true)
		routed_panel.hide()
		if not bool(routed_panel.get_meta("router_persistent", false)):
			routed_panel.queue_free()
	routed_panel = panel
	routed_return_page = return_page
	panel.set_meta("command_return_page", return_page)
	panel.set_meta("router_replaced", false)
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player != null:
		player.set_meta("external_panel_open", true)
		(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
		player.stop_ship()


func complete_routed_panel(panel: Control) -> void:
	if panel == null or panel != routed_panel: return
	var return_page := str(panel.get_meta("command_return_page", routed_return_page))
	var replaced := bool(panel.get_meta("router_replaced", false))
	routed_panel = null
	routed_return_page = ""
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player != null:
		player.set_meta("external_panel_open", false)
		player.set_meta("ui_action_guard_until", Time.get_ticks_msec() + 150)
	if not replaced and not return_page.is_empty():
		call_deferred("open_menu", return_page)


func routed_return(fallback := "home") -> String:
	return routed_return_page if not routed_return_page.is_empty() else fallback


func _menu_title(page: String) -> String:
	return {
		"events": "Events", "quests": "Aufträge", "shop": "Markt", "bazaar": "Basar", "guild": "Gilde",
		"chat": "Chat", "achievements": "Erfolge", "rankings": "Ranglisten", "meta": "Begleiter & Artefakte",
		"bonus": "Bonus", "bonusmaps": "Bonusmaps", "group": "Gruppe", "home": "Kapitänsmenü",
		"systems": "Online & Systemstatus", "help": "Hilfe & System", "admin": "Admin", "log": "Logbuch", "progress": "Karten & Fortschritt", "equipment": "Schiff & Ausrüstung", "harbor": "Hafen"
	}.get(page, page.capitalize())


func note(message: String) -> void:
	note_prioritized(message, 1, "default", 2600)


func note_tiered(message: String, duration_ms: int) -> void:
	note_prioritized(message, 4 if duration_ms >= 3000 else 2, "reward", duration_ms)


func note_prioritized(message: String, priority: int, family: String, duration_ms: int) -> void:
	var now := Time.get_ticks_msec()
	var can_replace := now >= notice_until or priority >= notice_priority or active_notice == message
	if can_replace:
		active_notice = message
		notice_priority = priority
		notice_family = family
		notice_until = now + clampi(duration_ms, 1200, 6000)
	recent_log.push_front(message)
	if recent_log.size() > 3:
		recent_log.resize(3)


func present_event(id: String, fallback: String, values: Dictionary = {}) -> void:
	var catalog := M176RuntimeFeedbackCatalog.current(get_tree())
	var profile: Dictionary = {}
	if catalog != null:
		profile = catalog.notification_profile(id)
	var message := str(profile.get("text", fallback))
	if message == "{message}":
		message = fallback
	for key in values:
		message = message.replace("{%s}" % str(key), str(values[key]))
	note_prioritized(message, int(profile.get("priority", 1)), id, int(profile.get("duration_ms", 2600)))


func _mission_completed(result: Dictionary) -> void:
	note("Auftrag abgeschlossen: +%d Gold · +%d EXP" % [result.coins, result.xp])


func _draw_legacy() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as ShipMotor
	var health := player.get_node("Health") as ShipHealth
	var weapons := player.get_node("Weapons") as ShipWeapons
	var progression := player.get_node("Progression") as PlayerProgression
	var missions := player.get_node("Missions") as MissionSystem
	var world := _world_map()
	var scale_value: float = clamp(size.y / 720.0, 0.85, 1.7)
	var safe := _safe_rect()
	var panel_width: float = min(390.0 * scale_value, safe.size.x - 36.0)
	var panel := Rect2(safe.position + Vector2(18.0, 18.0), Vector2(panel_width, 250.0 * scale_value))
	draw_rect(panel, PANEL, true)
	draw_string(font, panel.position + Vector2(16.0, 31.0 * scale_value), "SEE FIGHT 3D · M168", HORIZONTAL_ALIGNMENT_LEFT, panel_width - 32.0, int(18.0 * scale_value), Color.WHITE)
	draw_string(font, panel.position + Vector2(16.0, 58.0 * scale_value), "Hull %.0f/%.0f    Speed %.1f" % [health.current_health, health.max_health, player.current_speed], HORIZONTAL_ALIGNMENT_LEFT, -1, int(14.0 * scale_value), TEXT)
	_draw_bar(Rect2(panel.position + Vector2(16.0, 70.0 * scale_value), Vector2(panel_width - 32.0, 13.0 * scale_value)), health.normalized(), HEALTH_GREEN)
	_draw_bar(Rect2(panel.position + Vector2(16.0, 91.0 * scale_value), Vector2(panel_width - 32.0, 8.0 * scale_value)), weapons.reload_progress(), RELOAD_ORANGE)
	if world != null:
		var coordinates := world.display_coordinates()
		draw_string(font, panel.position + Vector2(16.0, 124.0 * scale_value), "%s  •  X %03d / Y %03d" % [world.current_map_name(), int(round(coordinates.x)), int(round(coordinates.y))], HORIZONTAL_ALIGNMENT_LEFT, -1, int(13.0 * scale_value), TEXT)
	var input_node := player.get_node("PlayerInput") as PlayerShipInput
	var inventory := player.get_node("Inventory") as PlayerInventory
	var loadout_text := "%s • %s (%d)" % [weapons.cannon_name(), weapons.ammo_name(), inventory.count(weapons.ammo_id())]
	draw_string(font, panel.position + Vector2(16.0, 148.0 * scale_value), loadout_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 * scale_value), Color("ffd47a"))
	var economy_text := "Repair %d  •  Boost %.0f%%  •  Coins %d" % [
		input_node.repair_charges,
		input_node.ability_progress() * 100.0,
		progression.coins,
	]
	draw_string(font, panel.position + Vector2(16.0, 168.0 * scale_value), economy_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 * scale_value), TEXT)
	var level_text := "Level %d  •  XP %d/%d" % [progression.level, progression.xp, progression.xp_to_next_level()]
	draw_string(font, panel.position + Vector2(16.0, 190.0 * scale_value), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 * scale_value), Color("8fd6e5"))
	_draw_bar(Rect2(panel.position + Vector2(16.0, 198.0 * scale_value), Vector2(panel_width - 32.0, 7.0 * scale_value)), progression.xp_progress(), Color("35bce4"))
	draw_string(font, panel.position + Vector2(16.0, 219.0 * scale_value), "Mission: %s" % missions.description(), HORIZONTAL_ALIGNMENT_LEFT, panel_width - 32.0, int(11.0 * scale_value), TEXT)
	if world != null and world.encounters != null:
		draw_string(font, panel.position + Vector2(16.0, 241.0 * scale_value), world.encounters.status_text(), HORIZONTAL_ALIGNMENT_LEFT, panel_width - 32.0, int(11.0 * scale_value), Color("ffd267"))
		if world.encounters.notice_time > 0.0:
			_draw_centered(world.encounters.notice, Vector2(safe.get_center().x, safe.end.y - 165.0 * scale_value), int(15.0 * scale_value), Color("ffd267"))

	var mobile_platform := bool(get_tree().root.get_meta("touch_ui", false))
	var hint := "LINKS: STEUERN  •  RECHTS: AKTIONEN  •  MAP: OBEN RECHTS" if mobile_platform else "WASD • SPACE FEUER • T ZIEL • C/X WAFFE • Q REPARATUR • E BOOST • F HAFEN"
	if progression.shop_open:
		hint = "SHIPYARD: SCHIFF WÄHLEN ODER UPGRADEN" if mobile_platform else "[ / ] SCHIFF • ENTER KAUFEN/AUSRÜSTEN • 1/2/3 UPGRADES • G SCHLIESSEN"
	_draw_centered(hint, Vector2(safe.get_center().x, safe.end.y - 24.0), int(14.0 * scale_value), TEXT)
	_draw_world_labels(scale_value)
	_draw_poi_markers(scale_value)
	_draw_navigation_course(safe, scale_value, player)
	_draw_minimap(safe, scale_value, world)
	_draw_transition_banner(safe, scale_value, world)
	_m231_draw_encounter_zone_feedback(safe, scale_value)
	_m232_draw_world_event_awareness(safe, scale_value)
	_m233_draw_world_event_lifecycle(safe, scale_value)
	_m234_draw_world_event_objectives(safe, scale_value)
	_m235_draw_world_event_contribution(safe, scale_value)
	_draw_combat_feedback(safe, scale_value, player, panel)
	if player.get_meta("in_safe_zone", false):
		_draw_centered("SAFE ZONE — %s" % player.get_meta("safe_zone_name", "HARBOR"), Vector2(safe.get_center().x, safe.position.y + 52.0 * scale_value), int(18.0 * scale_value), Color("54efad"))
	if player.has_meta("nearby_port"):
		var m225_docked := bool(player.get_meta("m225_docked", false))
		var dock_hint := ("ABLEGEN ANTIPPEN" if m225_docked else "ANLEGEN ANTIPPEN") if mobile_platform else ("F DRÜCKEN: ABLEGEN" if m225_docked else "F DRÜCKEN: ANLEGEN")
		_draw_centered(dock_hint, Vector2(safe.get_center().x, safe.position.y + 76.0 * scale_value), int(14.0 * scale_value), Color("54efad") if m225_docked else Color("ffd267"))
		if m225_docked:
			_m225_draw_docked_harbor_strip(safe, scale_value, player)
	var message_until := float(player.get_meta("dock_message_until", 0.0))
	if Time.get_ticks_msec() / 1000.0 < message_until:
		_draw_centered(str(player.get_meta("dock_message", "DOCKED")), Vector2(safe.get_center().x, safe.position.y + 102.0 * scale_value), int(16.0 * scale_value), Color("54efad"))
	if Time.get_ticks_msec()/1000.0 < float(player.get_meta("m226_repair_feedback_until",0.0)):
		_draw_centered("REPARATUR ABGESCHLOSSEN",Vector2(safe.get_center().x,safe.position.y+198.0*scale_value),int(13.0*scale_value),Color("54efad"))
	elif Time.get_ticks_msec()/1000.0 < float(player.get_meta("m226_undock_visual_until",0.0)):
		_draw_centered("LEINEN LOS",Vector2(safe.get_center().x,safe.position.y+122.0*scale_value),int(13.0*scale_value),Color("ffd267"))
	if global_map_open:
		_draw_global_map(safe, scale_value, world)
	else:
		if progression.shop_open:
			_draw_shop(safe, scale_value, progression)
		else:
			_draw_target_panel(safe, scale_value, player)
		if mobile_platform:
			_draw_mobile_actions(safe, scale_value)
	_draw_touch_joystick()
	if bool(get_tree().root.get_meta("app_suspended", false)):
		draw_rect(get_viewport_rect(), Color(0.0, 0.0, 0.0, 0.72), true)
		_draw_centered("PAUSED", get_viewport_rect().get_center(), int(26.0 * scale_value), Color.WHITE)


func _m225_draw_docked_harbor_strip(safe:Rect2, scale_value:float, player:ShipMotor)->void:
	# M226 supersedes the M225 text strip with real service hit targets while keeping the world visible.
	_m226_harbor_service_hits.clear()
	var width:=minf(610.0*scale_value, safe.size.x-32.0*scale_value)
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5, safe.position.y+108.0*scale_value),Vector2(width,78.0*scale_value))
	draw_rect(rect,Color(0.025,0.06,0.075,0.94),true)
	draw_rect(rect,Color("d2ad58"),false,1.5*scale_value)
	_draw_centered("%s · ANGELEGT" % str(player.get_meta("m225_docked_port", player.get_meta("nearby_port_name","HAFEN"))),rect.position+Vector2(rect.size.x*0.5,17.0*scale_value),int(11.0*scale_value),Color("ffe19a"))
	var ids:=M226HarborServiceCatalog.SERVICES
	var gap:=5.0*scale_value
	var inner_width:=rect.size.x-20.0*scale_value
	var button_w:=(inner_width-gap*float(ids.size()-1))/float(ids.size())
	for i in ids.size():
		var id:=str(ids[i])
		var br:=Rect2(rect.position+Vector2(10.0*scale_value+i*(button_w+gap),30.0*scale_value),Vector2(button_w,36.0*scale_value))
		draw_rect(br,Color(0.045,0.11,0.14,0.98) if id!="undock" else Color(0.16,0.09,0.045,0.98),true)
		draw_rect(br,Color("61bdd1") if id!="undock" else Color("d2ad58"),false,1.0*scale_value)
		var label:=M226HarborServiceCatalog.repair_label(player) if id=="repair" else M226HarborServiceCatalog.label(id)
		_draw_centered(label,br.position+Vector2(br.size.x*0.5,22.0*scale_value),int(8.0*scale_value),TEXT)
		_m226_harbor_service_hits.append({"id":id,"rect":br})

func _m226_activate_harbor_service_at(point:Vector2)->bool:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if not M226HarborServiceCatalog.can_use(player): return false
	var service_id:=""
	for hit in _m226_harbor_service_hits:
		if (hit.get("rect",Rect2()) as Rect2).has_point(point): service_id=str(hit.get("id","")); break
	if service_id.is_empty(): return false
	match service_id:
		"shipyard":
			var roster:=player.get_node_or_null("ShipRoster") as PlayerShipRoster
			var screen:=ShipyardPanel.new(); get_tree().root.add_child(screen); route_panel(screen,"home")
			screen.open(self,roster.selected_ship_id if roster!=null else "")
		"repair":
			var inventory:=player.get_node_or_null("Inventory") as PlayerInventory
			if inventory==null: return true
			var quote:=inventory.harbor_repair_quote()
			if quote==0: note("RUMPF BEREITS VOLLSTÄNDIG REPARIERT")
			elif inventory.purchase_harbor_repair():
				player.set_meta("m226_repair_feedback_until",Time.get_ticks_msec()/1000.0+1.4)
				note("RUMPF REPARIERT · -%d GOLD" % quote)
			else: note("REPARATUR NICHT MÖGLICH · %d GOLD BENÖTIGT" % quote)
		"market": open_menu("shop")
		"arsenal":
			var arsenal:=get_tree().get_first_node_in_group("arsenal_ui") as ArsenalPanel
			if arsenal!=null: arsenal.toggle()
		"undock":
			var port:=player.get_meta("nearby_port",null) as PortInteraction
			if port!=null and port.activate(player):
				player.set_meta("m226_undock_visual_until",Time.get_ticks_msec()/1000.0+1.5)
				note("ABLEGEN · ZURÜCK AUF SEE")
	queue_redraw(); return true


func _draw_target_panel(safe: Rect2, scale_value: float, player: ShipMotor) -> void:
	var targeting := player.get_node_or_null("Targeting") as TargetingSystem
	if targeting == null or targeting.target == null or not is_instance_valid(targeting.target):
		return
	var target_health := targeting.target.get_node_or_null("Health") as ShipHealth
	if target_health == null or target_health.is_sunk:
		return
	var panel := Rect2(Vector2(safe.get_center().x - 145.0 * scale_value, safe.position.y + 18.0), Vector2(290.0, 62.0) * scale_value)
	var target_kind := str(targeting.target.get_meta("encounter_kind", "ship"))
	var target_rank := str(targeting.target.get_meta("rarity", "common"))
	var relation := EncounterRelation.status(targeting.target)
	var neutral := relation == EncounterRelation.NEUTRAL
	draw_rect(panel, Color(0.02, 0.09, 0.09, 0.90) if neutral else Color(0.08, 0.025, 0.025, 0.88), true)
	var boss_phase := int(targeting.target.get_meta("boss_phase", 1))
	var rank_text := "BOSS P%d" % boss_phase if target_rank == "boss" else target_rank.to_upper()
	var kind_icon := "MONSTER" if target_kind == "monster" else "SHIP"
	var relation_color := Color("71d7c4") if neutral else (Color("ffd267") if target_rank == "boss" else Color("ffb86b"))
	_draw_centered("TARGET: %s  •  %.0fm" % [targeting.target.name, player.global_position.distance_to(targeting.target.global_position)], panel.position + Vector2(panel.size.x * 0.5, 20.0 * scale_value), int(13.0 * scale_value), Color.WHITE)
	var m217_threat := Time.get_ticks_msec() < int(targeting.target.get_meta("m217_broadside_threat_until", 0))
	var relation_line := "%s  •  %s  •  %s" % [kind_icon, rank_text, EncounterRelation.label(targeting.target)]
	if m217_threat:
		relation_line += "  •  SALVE"
	_draw_centered(relation_line, panel.position + Vector2(panel.size.x * 0.5, 36.0 * scale_value), int(10.0 * scale_value), Color("ffd267") if m217_threat else relation_color)
	_draw_bar(Rect2(panel.position + Vector2(14.0, 44.0 * scale_value), Vector2(panel.size.x - 28.0, 10.0 * scale_value)), target_health.normalized(), Color("50bca9") if neutral else ENEMY_RED)


func _draw_shop(safe: Rect2, scale_value: float, progression: PlayerProgression) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var roster := players[0].get_node("ShipRoster") as PlayerShipRoster
	var profile := roster.preview_ship()
	var shop_size := Vector2(min(760.0 * scale_value, safe.size.x - 54.0), min(470.0 * scale_value, safe.size.y - 110.0))
	var panel := Rect2(safe.get_center() - shop_size * 0.5, shop_size)
	draw_rect(panel, Color(0.018, 0.04, 0.058, 0.97), true)
	draw_rect(panel, Color(0.76, 0.57, 0.24, 0.9), false, 2.0)
	_draw_centered("SCHIFFSWERFT", panel.position + Vector2(panel.size.x * 0.5, 38.0 * scale_value), int(21.0 * scale_value), Color("ffe19a"))
	_draw_centered("Coins: %d  •  Owned: %d/%d" % [progression.coins, roster.owned_ship_ids.size(), ShipCatalog.SHIPS.size()], panel.position + Vector2(panel.size.x * 0.5, 66.0 * scale_value), int(14.0 * scale_value), Color.WHITE)
	var ship_card := Rect2(panel.position + Vector2(18.0 * scale_value, 82.0 * scale_value), Vector2(panel.size.x - 36.0 * scale_value, 116.0 * scale_value))
	draw_rect(ship_card, Color(0.035, 0.105, 0.145, 0.98), true)
	draw_rect(ship_card, Color(0.32, 0.76, 0.92, 0.65), false, 1.5)
	_draw_centered("‹   %s   ›" % str(profile.display_name).to_upper(), ship_card.position + Vector2(ship_card.size.x * 0.5, 29.0 * scale_value), int(17.0 * scale_value), Color.WHITE)
	_draw_centered(str(profile.role), ship_card.position + Vector2(ship_card.size.x * 0.5, 53.0 * scale_value), int(11.0 * scale_value), Color("a9dceb"))
	var stats := "Hull %.0f  •  Speed %.1f  •  Turn %.0f°  •  Damage %.0f" % [float(profile.hull), float(profile.speed), float(profile.turn_speed), float(profile.damage)]
	_draw_centered(stats, ship_card.position + Vector2(ship_card.size.x * 0.5, 77.0 * scale_value), int(11.0 * scale_value), TEXT)
	_draw_centered(roster.preview_status(), ship_card.position + Vector2(ship_card.size.x * 0.5, 101.0 * scale_value), int(13.0 * scale_value), Color("ffd267"))
	var upgrade_data := [
		["HULL", "hull", "+12% hull"],
		["CANNONS", "cannon", "+10% damage"],
		["SAILS", "sails", "+4.5% speed"],
	]
	var card_width := (panel.size.x - 48.0 * scale_value) / 3.0
	for index in upgrade_data.size():
		var data: Array = upgrade_data[index]
		var card := Rect2(panel.position + Vector2(12.0 * scale_value + index * card_width, 216.0 * scale_value), Vector2(card_width - 8.0 * scale_value, 150.0 * scale_value))
		draw_rect(card, Color(0.045, 0.095, 0.13, 0.96), true)
		draw_rect(card, Color(0.3, 0.68, 0.8, 0.45), false, 1.5)
		var kind := str(data[1])
		_draw_centered(str(data[0]), card.position + Vector2(card.size.x * 0.5, 30.0 * scale_value), int(14.0 * scale_value), Color.WHITE)
		_draw_centered("Level %d/10" % int(progression.upgrades[kind]), card.position + Vector2(card.size.x * 0.5, 61.0 * scale_value), int(12.0 * scale_value), TEXT)
		_draw_centered(str(data[2]), card.position + Vector2(card.size.x * 0.5, 88.0 * scale_value), int(11.0 * scale_value), Color("8fd6e5"))
		_draw_centered("%d coins" % progression.upgrade_cost(kind), card.position + Vector2(card.size.x * 0.5, 121.0 * scale_value), int(12.0 * scale_value), Color("ffd267"))
	_draw_centered("Werft ist global erreichbar · lokale Hafendienste bleiben getrennt", panel.position + Vector2(panel.size.x * 0.5, panel.size.y - 25.0 * scale_value), int(11.0 * scale_value), TEXT)


func _draw_mobile_actions(safe: Rect2, scale_value: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	var progression := players[0].get_node_or_null("Progression") as PlayerProgression if not players.is_empty() else null
	var first_label := "DOCK" if not players.is_empty() and players[0].has_meta("nearby_port") else "TARGET"
	var labels := ["HULL", "CANNON", "SAILS", "CLOSE"] if progression != null and progression.shop_open else [first_label, "REPAIR", "BOOST", "FIRE"]
	var total_width: float = min(safe.size.x * 0.45, 520.0 * scale_value)
	var button_width: float = total_width / labels.size()
	var origin := Vector2(safe.end.x - total_width, safe.end.y - 130.0 * scale_value)
	for index in labels.size():
		var rect := Rect2(origin + Vector2(index * button_width, 0.0), Vector2(button_width - 5.0, 64.0 * scale_value))
		draw_rect(rect, Color(0.035, 0.08, 0.11, 0.82), true)
		draw_rect(rect, Color(0.35, 0.78, 0.94, 0.62), false, 2.0)
		_draw_centered(labels[index], rect.get_center() + Vector2(0.0, 5.0 * scale_value), int(11.0 * scale_value), Color.WHITE)
	if progression != null and progression.shop_open:
		var roster_labels := ["SHIP ‹", "AUSRÜSTEN", "SHIP ›", "CLOSE"]
		var roster_origin := origin - Vector2(0.0, 72.0 * scale_value)
		for index in roster_labels.size():
			var roster_rect := Rect2(roster_origin + Vector2(index * button_width, 0.0), Vector2(button_width - 5.0, 64.0 * scale_value))
			draw_rect(roster_rect, Color(0.07, 0.14, 0.18, 0.92), true)
			draw_rect(roster_rect, Color(0.92, 0.68, 0.25, 0.72), false, 2.0)
			_draw_centered(roster_labels[index], roster_rect.get_center() + Vector2(0.0, 5.0 * scale_value), int(10.0 * scale_value), Color.WHITE)


func _draw_world_labels(scale_value: float) -> void:
	_nameplate_rects.clear()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var occupied := NauticalLayout.reserved(layout(), log_visible())
	var settings := ClientSettings.current(get_tree())
	var names: bool = settings == null or settings.values.show_names
	var bars: bool = settings == null or settings.values.show_health
	if not names and not bars: return
	var player_ship:=get_tree().get_first_node_in_group("player") as ShipMotor
	var selected_target:Node3D=null
	if player_ship!=null:
		var player_weapons:=player_ship.get_node_or_null("Weapons") as ShipWeapons
		if player_weapons!=null:selected_target=player_weapons.selected_target()
	var nameplate_limit:=MobileLodController.nameplate_distance(get_tree())
	for ship: ShipMotor in get_tree().get_nodes_in_group("ships"):
		var health: ShipHealth = ship.get_node("Health")
		var distance_to_player:=0.0 if player_ship==null else player_ship.global_position.distance_to(ship.global_position)
		var keep_readable:=ship.is_in_group("player") or ship==selected_target or str(ship.get_meta("rarity",""))=="boss"
		if not keep_readable and distance_to_player>nameplate_limit:
			continue
		if health.is_sunk or camera.is_position_behind(ship.global_position):
			continue
		var bounds: AABB = ship.get_meta("hud_visual_bounds", AABB(Vector3(-2, 0, -3), Vector3(4, 4, 6)))
		var screen_bounds := Rect2()
		for index in 8:
			var point := camera.unproject_position(ship.global_transform * bounds.get_endpoint(index))
			screen_bounds = Rect2(point, Vector2.ZERO) if index == 0 else screen_bounds.expand(point)
		var own := ship.is_in_group("player")
		var base_label := str(ship.get_meta("captain_name", ship.name)) if own else str(ship.name)
		var combat_level := int(ship.get_meta("combat_level", 1))
		var rarity := str(ship.get_meta("rarity", "player" if own else "common"))
		var encounter_kind := str(ship.get_meta("encounter_kind", "ship"))
		var prefix := "☠ " if rarity == "boss" and encounter_kind == "monster" else ("★ " if rarity == "boss" else ("◆ " if rarity == "elite" else ""))
		var relation := EncounterRelation.status(ship)
		var presentation_label:=EncounterPresentationCatalog.label(ship)
		var relation_suffix := "  · %s" % presentation_label if presentation_label in ["NEUTRAL","ALARM"] else ""
		var label := "%s%s  Lv.%d%s" % [prefix, base_label, combat_level, relation_suffix]
		var selected_read:=ship==selected_target
		# M230: M229 rank/formation semantics become visible without increasing nameplate density.
		var m230_badge:=M230EncounterWorldReadCatalog.rank_badge(ship)
		if m230_badge!="" and (selected_read or int(ship.get_meta("m229_world_read_priority",1))>=3):
			label="%s  · %s %s" % [label,m230_badge,M230EncounterWorldReadCatalog.formation_glyph(ship)]
		var boss_read:=rarity=="boss" or bool(ship.get_meta("is_admiral",false))
		var m219_rank:=M219WorldReadabilityCatalog.nameplate_rank(ship,selected_read,own)
		ship.set_meta("m219_nameplate_rank",m219_rank)
		var m219_extent:=M219WorldReadabilityCatalog.compact_nameplate_width(selected_read,boss_read)
		var extent := Vector2(clampf(font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 20, 146 if selected_read else 126, m219_extent.x), m219_extent.y)
		var box := NauticalLayout.nameplate_box(screen_bounds, extent, _safe_rect().grow(-6), occupied, own)
		if not box.has_area():
			continue
		_nameplate_rects.append(box)
		occupied.append(box)
		var plate_slot := WorldNameplateVisualCatalog.slot(ship, relation, own)
		var plate_texture := VisualAssetCatalog.texture(plate_slot)
		if plate_texture != null:
			draw_texture_rect(plate_texture, box.grow(2.0 * scale_value), false)
		if selected_read:
			draw_arc(box.get_center(), maxf(box.size.x, box.size.y) * 0.54, 0, TAU, 28, NauticalHud.GOLD, 1.6 * scale_value, true)
		if names:
			draw_string_outline(font, box.position + Vector2(4, 14), label, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 8, 13, 3, Color("041720"))
			var label_color := NauticalHud.LIGHT if own else (Color("71d7c4") if relation == EncounterRelation.NEUTRAL else (Color("ffd267") if rarity == "boss" else (Color("ffb86b") if rarity == "elite" else Color.WHITE)))
			draw_string(font, box.position + Vector2(4, 14), label, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 8, 13, label_color)
		if bars:
			var bar_color := NauticalHud.GREEN if own else (Color("50bca9") if relation == EncounterRelation.NEUTRAL else NauticalHud.RED)
			NauticalHud.bar(self, Rect2(box.position + Vector2(3, 21), Vector2(box.size.x - 6, 9 if selected_read else 7)), health.normalized(), bar_color)
		if own and bars:
			NauticalHud.bar(self, Rect2(box.position + Vector2(3, 32), Vector2(box.size.x - 6, 6)), (ship.get_node("Weapons") as ShipWeapons).reload_progress(), NauticalHud.BLUE)
		if selected_read and player_ship != null:
			var selected_weapons := player_ship.get_node_or_null("Weapons") as ShipWeapons
			if selected_weapons != null:
				var state := (player_ship.get_node("Targeting") as TargetingSystem).target_range_state(selected_weapons.effective_range())
				draw_string(font, box.position + Vector2(4, box.size.y - 3), "%s · %.0fm" % [state, distance_to_player], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 8, 9, NauticalHud.GOLD)
		_draw_ship_status_icons(ship, box, scale_value)





func _draw_navigation_course(safe:Rect2, scale_value:float, player:ShipMotor)->void:
	# M220: a restrained, presentation-only course read. The final captain-selected
	# destination remains authoritative; the bend only exposes existing M192 island avoidance.
	var input:=player.get_node_or_null("PlayerInput") as PlayerShipInput
	var camera:=get_viewport().get_camera_3d()
	if input==null or camera==null:return
	var course:=input.navigation_presentation()
	if not bool(course.get("active",false)):return
	var final_world:Vector3=course.get("final_target",Vector3.ZERO)
	var steering_world:Vector3=course.get("steering_target",final_world)
	var detouring:=bool(course.get("detouring_land",false))
	var intent:=str(course.get("intent","water"))
	var distance:=float(course.get("remaining",0.0))
	var alpha:=M220NavigationPresentationCatalog.course_alpha(distance)
	var player_point:=camera.unproject_position(player.global_position+Vector3.UP*0.35)
	var final_behind:=camera.is_position_behind(final_world)
	var final_point:=camera.unproject_position(final_world)
	var steering_behind:=camera.is_position_behind(steering_world)
	var steering_point:=camera.unproject_position(steering_world)
	var readable:=safe.grow(-36.0)
	# Do not paint long lines through permanent HUD. Only show the local leg when both
	# endpoints are in the readable sea-chart area.
	if readable.has_point(player_point):
		if detouring and not steering_behind and readable.has_point(steering_point):
			draw_dashed_line(player_point,steering_point,Color(0.36,0.84,1.0,alpha),2.0*scale_value,7.0*scale_value,true)
			if not final_behind and readable.has_point(final_point):
				draw_dashed_line(steering_point,final_point,Color(0.86,0.76,0.46,alpha*0.82),1.5*scale_value,8.0*scale_value,true)
		elif not final_behind and readable.has_point(final_point):
			draw_dashed_line(player_point,final_point,Color(0.36,0.84,1.0,alpha),1.8*scale_value,8.0*scale_value,true)
	if not final_behind and readable.has_point(final_point):
		draw_arc(final_point,13.0*scale_value,0,TAU,24,NauticalHud.BLUE,2.0*scale_value,true)
		draw_circle(final_point,3.0*scale_value,NauticalHud.GOLD)
		_draw_centered(M220NavigationPresentationCatalog.edge_label(intent,distance,detouring),final_point+Vector2(0,24.0*scale_value),9,NauticalHud.LIGHT)
		return
	# Off-screen course: one prioritized edge cue, clamped clear of the HUD.
	var center:=safe.get_center()
	var direction:=Vector2(0,-1) if final_behind else (final_point-center).normalized()
	var edge:=center+direction*minf(safe.size.x*0.42,safe.size.y*0.38)
	edge.x=clampf(edge.x,safe.position.x+42.0,safe.end.x-42.0)
	edge.y=clampf(edge.y,safe.position.y+42.0,safe.end.y-42.0)
	var occupied:=NauticalLayout.reserved(layout(),log_visible())
	var cue:=Rect2(edge-Vector2(34,20)*scale_value,Vector2(68,40)*scale_value)
	for rect in occupied:
		if cue.intersects(rect):
			edge=center+direction.rotated(0.22)*minf(safe.size.x*0.39,safe.size.y*0.35)
			break
	draw_arc(edge,14.0*scale_value,-PI*0.78,PI*0.78,16,NauticalHud.BLUE,2.0*scale_value,true)
	var arrow:=direction.normalized()
	draw_line(edge-arrow*7.0*scale_value,edge+arrow*8.0*scale_value,NauticalHud.GOLD,2.0*scale_value,true)
	_draw_centered(M220NavigationPresentationCatalog.edge_label(intent,distance,detouring),edge+Vector2(0,25.0*scale_value),9,NauticalHud.LIGHT)


func _draw_poi_markers(scale_value: float) -> void:
	# M182 compatibility token: "loot"] and distance<=34.0; M219 supersedes display gating via priority catalog.
	var camera:=get_viewport().get_camera_3d()
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if camera==null or player==null:return
	var safe:=_safe_rect().grow(-8)
	var rows:Array=[]
	var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	var tracked_target: Node3D = tracking.resolve_target() if tracking != null else null
	for node in get_tree().get_nodes_in_group("world_poi_markers"):
		var poi:=node as Node3D
		if poi==null or poi==tracked_target or camera.is_position_behind(poi.global_position):continue
		var distance:=player.global_position.distance_to(poi.global_position)
		if distance>64.0:continue
		var kind:=str(poi.get_meta("poi_kind",""))
		var priority:=int(poi.get_meta("marker_priority",WorldMarkerPriorityCatalog.priority(kind)))
		rows.append({"node":poi,"distance":distance,"priority":priority})
	WorldMarkerPriorityCatalog.sort_rows(rows)
	var poi_limit:=MobilePresentationBudget.int_value(get_viewport_rect().size,float(DisplayServer.screen_get_dpi()),"world_poi",6)
	var occupied:=NauticalLayout.reserved(layout(),log_visible())
	occupied.append_array(_nameplate_rects)
	var drawn:=0
	for row in rows:
		if drawn>=poi_limit:break
		var poi:Node3D=row.node
		var distance:=float(row.distance)
		var point:=camera.unproject_position(poi.global_position+Vector3.UP*1.7)
		if not safe.has_point(point):continue
		var alpha:=1.0-clampf((distance-42.0)/22.0,0.0,1.0)*0.72
		var marker_base:=MobilePresentationBudget.float_value(get_viewport_rect().size,float(DisplayServer.screen_get_dpi()),"world_marker_size",30.0)
		var marker_priority:=int(row.priority)
		var priority_scale:=1.16 if marker_priority>=82 else (1.08 if marker_priority>=72 else 1.0)
		var size:=clampf(marker_base*scale_value*priority_scale,24.0,46.0)
		var rect:=Rect2(point-Vector2.ONE*size*0.5,Vector2.ONE*size)
		var blocked:=false
		for other in occupied:
			if rect.grow(4.0).intersects(other):
				blocked=true
				break
		if blocked:continue
		var texture:=VisualAssetCatalog.texture(str(poi.get_meta("marker_slot","world_interact")))
		if texture!=null:
			var tint:=Color(1,1,1,alpha)
			if str(poi.get_meta("poi_kind",""))=="guild_island":
				var rc:=GuildIslandVisualState.relation_color(poi)
				tint=Color(rc.r,rc.g,rc.b,alpha)
			draw_texture_rect(texture,rect,false,tint)
			var kind:=str(poi.get_meta("poi_kind",""))
			if M219WorldReadabilityCatalog.marker_label_visible(kind,distance,marker_priority):
				var label:=str(poi.get_meta("poi_label",kind.replace("_"," ").to_upper()))
				if kind=="loot" or marker_priority>=82:label="%s · %.0fm"%[label,distance]
				var label_rect:=Rect2(Vector2(rect.get_center().x-70.0,rect.end.y+3.0),Vector2(140.0,18.0))
				if safe.encloses(label_rect):
					_draw_centered(label,label_rect.get_center()+Vector2(0,4),9,Color(0.92,0.88,0.68,alpha))
			occupied.append(rect)
			drawn+=1
	_draw_tracked_objective_marker(camera, player, safe, scale_value)

func _draw_tracked_objective_marker(camera: Camera3D, player: ShipMotor, safe: Rect2, scale_value: float) -> void:
	var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	if tracking == null: return
	var target := tracking.resolve_target()
	if target == null: return
	var texture := VisualAssetCatalog.texture("m72_poi_objective_frame")
	var point := camera.unproject_position(target.global_position + Vector3.UP * 2.1)
	var behind := camera.is_position_behind(target.global_position)
	var on_screen := not behind and safe.grow(-34.0).has_point(point)
	var marker_position := point
	if not on_screen:
		var center := safe.get_center()
		var direction := Vector2(0, -1) if behind else (point - center).normalized()
		marker_position = center + direction * minf(safe.size.x * 0.43, safe.size.y * 0.39)
		marker_position.x = clampf(marker_position.x, safe.position.x + 34.0, safe.end.x - 34.0)
		marker_position.y = clampf(marker_position.y, safe.position.y + 34.0, safe.end.y - 34.0)
	var size := 42.0 * scale_value
	# M189: the tracked objective is the highest-priority world cue, but it may not
	# cover permanent HUD controls. Pick a nearby edge candidate outside reserved UI.
	var marker_rect := Rect2(marker_position - Vector2.ONE * size * 0.5, Vector2.ONE * size)
	var reserved := NauticalLayout.reserved(layout(), log_visible())
	if not on_screen:
		var center := safe.get_center()
		var base_direction := (marker_position - center).normalized()
		var candidates := [marker_position]
		for angle in [0.18, -0.18, 0.34, -0.34, 0.52, -0.52]:
			var direction := base_direction.rotated(angle)
			var candidate := center + direction * minf(safe.size.x * 0.41, safe.size.y * 0.37)
			candidate.x = clampf(candidate.x, safe.position.x + 40.0, safe.end.x - 40.0)
			candidate.y = clampf(candidate.y, safe.position.y + 40.0, safe.end.y - 40.0)
			candidates.append(candidate)
		for candidate in candidates:
			var candidate_rect := Rect2(candidate - Vector2.ONE * size * 0.5, Vector2.ONE * size).grow(5.0)
			var blocked := false
			for hud_rect in reserved:
				if candidate_rect.intersects(hud_rect):
					blocked = true
					break
			if not blocked:
				marker_position = candidate
				marker_rect = Rect2(marker_position - Vector2.ONE * size * 0.5, Vector2.ONE * size)
				break
	if texture != null: draw_texture_rect(texture, marker_rect, false, Color(1.0, 0.86, 0.38, 0.96))
	draw_arc(marker_position, size * 0.62, 0, TAU, 24, NauticalHud.GOLD, 2.0, true)
	var distance := roundi(player.global_position.distance_to(target.global_position))
	_draw_centered("ZIEL · %dm" % distance, marker_position + Vector2(0, size * 0.72), 10, NauticalHud.GOLD)

func _draw_first_session_guide(player:ShipMotor,layout:Dictionary)->void:
	var state:=FirstSessionGuide.state(player)
	if state.is_empty():return
	var guide:=str(state.get("guide",""))
	var target:Node3D=null
	if guide=="harbor":target=FirstSessionGuide.nearest_port(player)
	elif guide=="loot":target=FirstSessionGuide.nearest_loot(player)
	if target==null:return
	var camera:=get_viewport().get_camera_3d()
	if camera==null:return
	var safe:Rect2=layout.safe
	var point:=camera.unproject_position(target.global_position+Vector3.UP*2.0)
	var visible_on_screen:=not camera.is_position_behind(target.global_position) and safe.grow(-36).has_point(point)
	var icon_slot:=str(state.get("icon","m72_poi_objective_frame"))
	var texture:=VisualAssetCatalog.texture(icon_slot)
	if visible_on_screen:
		if texture!=null:
			draw_texture_rect(texture,Rect2(point-Vector2.ONE*17.0,Vector2.ONE*34.0),false,Color(1,1,1,0.88))
		return
	# Edge cue: one icon only, clamped inside safe area. No waypoint trail/spam.
	var center:=safe.get_center()
	var direction:Vector2
	if camera.is_position_behind(target.global_position):
		direction=Vector2(0,-1)
	else:
		direction=(point-center).normalized()
	var edge:=center+direction*minf(safe.size.x*0.42,safe.size.y*0.38)
	edge.x=clampf(edge.x,safe.position.x+34.0,safe.end.x-34.0)
	edge.y=clampf(edge.y,safe.position.y+34.0,safe.end.y-34.0)
	if texture!=null:
		draw_texture_rect(texture,Rect2(edge-Vector2.ONE*18.0,Vector2.ONE*36.0),false,Color(1,1,1,0.92))
	var distance:=roundi(player.global_position.distance_to(target.global_position))
	_draw_centered("%dm"%distance,edge+Vector2(0,28),10,Color("d7c49a"))

func _draw_ship_status_icons(ship: ShipMotor, box: Rect2, scale_value: float) -> void:
	var states := StatusVisualCatalog.active(ship)
	if states.is_empty():
		return
	var rules: Dictionary = StatusVisualCatalog.data().get("rules", {})
	var max_icons := mini(int(rules.get("max_world_icons", 4)), states.size())
	var size := clampf(float(rules.get("world_icon_size_px", 18)) * scale_value, 16.0, 28.0)
	var gap := 3.0 * scale_value
	var total := max_icons * size + maxf(0, max_icons - 1) * gap
	var start := Vector2(box.get_center().x - total * 0.5, box.position.y - size - 5.0 * scale_value)
	for i in max_icons:
		var state: Dictionary = states[i]
		var rect := Rect2(start + Vector2(i * (size + gap), 0), Vector2.ONE * size)
		var texture := VisualAssetCatalog.texture(str(state.get("icon_slot", "")))
		draw_circle(rect.get_center(), size * 0.54, Color(0.01, 0.04, 0.06, 0.88))
		if texture != null:
			draw_texture_rect(texture, rect, false)
		var remaining := float(state.get("remaining", 0.0))
		if bool(rules.get("show_remaining_seconds", true)) and remaining < 9999.0:
			var sec := str(maxi(1, ceili(remaining)))
			draw_string_outline(font, rect.end + Vector2(-3, -1), sec, HORIZONTAL_ALIGNMENT_RIGHT, size, maxi(8, int(8 * scale_value)), 2, Color("041720"))
			draw_string(font, rect.end + Vector2(-3, -1), sec, HORIZONTAL_ALIGNMENT_RIGHT, size, maxi(8, int(8 * scale_value)), Color.WHITE)

func _draw_world_labels_legacy(scale_value: float) -> void:
	_nameplate_rects.clear()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for ship_node in get_tree().get_nodes_in_group("ships"):
		var ship := ship_node as ShipMotor
		var health := ship.get_node("Health") as ShipHealth
		var anchor := ship.get_node_or_null("Anchors/Nameplate") as Marker3D
		var anchor_position := anchor.global_position if anchor != null else ship.global_position + Vector3.UP * 3.6
		if health.is_sunk or camera.is_position_behind(anchor_position):
			continue
		var screen := camera.unproject_position(anchor_position)
		var safe := _safe_rect().grow(-46.0 * scale_value)
		if not ship.is_in_group("player") and not safe.has_point(screen):
			continue
		screen = screen.clamp(safe.position, safe.end)
		var width := 116.0 * scale_value
		var label_name := str(ship.get_meta("captain_name", ship.name)) if ship.is_in_group("player") else str(ship.name)
		var text_width := font.get_string_size(label_name, HORIZONTAL_ALIGNMENT_LEFT, -1, int(13.0 * scale_value)).x
		var plate_width := maxf(width, text_width)
		_nameplate_rects.append(Rect2(screen + Vector2(-plate_width * 0.5, -32.0 * scale_value), Vector2(plate_width, 44.0 * scale_value)))
		_draw_centered(label_name, screen - Vector2(0.0, 14.0 * scale_value), int(13.0 * scale_value), Color.WHITE)
		_draw_bar(Rect2(screen + Vector2(-width * 0.5, 2.0 * scale_value), Vector2(width, 7.0 * scale_value)), health.normalized(), HEALTH_GREEN if ship.is_in_group("player") else ENEMY_RED)


func _draw_combat_feedback(safe: Rect2, scale_value: float, player: ShipMotor, stats_panel: Rect2) -> void:
	if global_map_open or bool(player.get_meta("inventory_open", false)) or (player.get_node("Progression") as PlayerProgression).shop_open:
		return
	var feedback := GameScope.owner_of(self).get_node_or_null("CombatFeedback") as CombatFeedback
	var camera := get_viewport().get_camera_3d()
	if feedback == null or camera == null:
		return
	var occupied := NauticalLayout.reserved(layout(), log_visible())
	occupied.append_array(_nameplate_rects)
	for entry in feedback.display_entries():
		var font_size := int(17.0 * scale_value * float(entry.get("scale", 1.0)))
		var position: Vector3 = entry.position
		if camera.is_position_behind(position):
			continue
		var anchor := camera.unproject_position(position) - Vector2(0, float(entry.age) * 22.0)
		var text_size := font.get_string_size(str(entry.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var box := CombatFeedback.place_label(anchor, Vector2(text_size.x + 12.0, font_size + 10.0), safe.grow(-8), occupied)
		if not box.has_area():
			continue
		occupied.append(box)
		var color := Color("ff9c88") if entry.incoming else Color("ffe395")
		if entry.critical:
			color = Color("ffd35d")
		match str(entry.get("kind", "damage")):
			"heal", "repair": color = Color("65e6a6")
			"shield": color = Color("62cfff")
			"block": color = Color("d8f1ff")
			"armor": color = Color("d7b878")
		color.a = float(entry.alpha)
		var baseline := box.get_center() + Vector2(-text_size.x * 0.5, font_size * 0.35)
		draw_string_outline(font, baseline, str(entry.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.02, 0.05, 0.07, color.a))
		draw_string(font, baseline, str(entry.text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_touch_joystick() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var input_node := players[0].get_node_or_null("PlayerInput") as PlayerShipInput
	if input_node == null or not input_node.joystick_visible:
		return
	draw_circle(input_node.steering_start, 54.0, Color(1.0, 1.0, 1.0, 0.16))
	var knob := input_node.steering_current - input_node.steering_start
	knob = knob.limit_length(48.0)
	draw_circle(input_node.steering_start + knob, 22.0, Color(1.0, 1.0, 1.0, 0.42))


func _draw_minimap(safe: Rect2, scale_value: float, world: WorldMapSystem) -> void:
	if world == null or global_map_open:
		return
	var map_size := Vector2(225.0, 166.0) * scale_value
	var map_rect := Rect2(Vector2(safe.end.x - map_size.x - 18.0, safe.position.y + 18.0), map_size)
	draw_rect(map_rect, Color(0.018, 0.038, 0.055, 0.9), true)
	draw_rect(map_rect, Color(0.3, 0.72, 0.88, 0.7), false, 2.0)
	draw_string(font, map_rect.position + Vector2(10.0, 21.0 * scale_value), "%s  [MAP]" % world.current_map_name(), HORIZONTAL_ALIGNMENT_LEFT, map_rect.size.x - 20.0, int(12.0 * scale_value), Color.WHITE)
	var content_rect := Rect2(map_rect.position + Vector2(8.0, 30.0 * scale_value), map_rect.size - Vector2(16.0, 38.0 * scale_value))
	for step in range(1, 4):
		var x := content_rect.position.x + content_rect.size.x * step / 4.0
		var y := content_rect.position.y + content_rect.size.y * step / 4.0
		draw_line(Vector2(x, content_rect.position.y), Vector2(x, content_rect.end.y), Color(1.0, 1.0, 1.0, 0.08), 1.0)
		draw_line(Vector2(content_rect.position.x, y), Vector2(content_rect.end.x, y), Color(1.0, 1.0, 1.0, 0.08), 1.0)
	for island in get_tree().get_nodes_in_group("islands"):
		draw_circle(_to_minimap(island.position, content_rect, world.sector_half_size()), 3.8 * scale_value, Color("6d9b52"))
	for port in get_tree().get_nodes_in_group("ports"):
		draw_circle(_to_minimap(port.position, content_rect, world.sector_half_size()), 5.0 * scale_value, Color("f1c75b"))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_health := enemy.get_node_or_null("Health") as ShipHealth
		if enemy_health != null and enemy_health.is_sunk:
			continue
		var admiral: bool = bool(enemy.get_meta("is_admiral", false))
		draw_circle(_to_minimap(enemy.position, content_rect, world.sector_half_size()), (6.0 if admiral else 3.6) * scale_value, Color("ffd267") if admiral else ENEMY_RED)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		draw_circle(_to_minimap(players[0].position, content_rect, world.sector_half_size()), 5.2 * scale_value, Color("35cfff"))



func _draw_global_map(safe: Rect2, scale_value: float, world: WorldMapSystem) -> void:
	# M223 rectangular/full-screen sea chart. Current-sector detail is primary; the legacy region graph stays available.
	if full_chart_view == "regions":
		_draw_global_map_regions(safe, scale_value, world)
		return
	_draw_m223_sector_chart(safe, scale_value, world)


func _draw_m223_sector_chart(safe: Rect2, scale_value: float, world: WorldMapSystem) -> void:
	if world == null: return
	_m223_chart_hits.clear()
	draw_rect(safe, Color(0.005, 0.012, 0.02, 0.88), true)
	var overlay := safe.grow(-18.0 * scale_value)
	draw_rect(overlay, Color(0.025,0.055,0.078,0.985), true)
	draw_rect(overlay, Color(0.28,0.7,0.88,0.72), false, 2.0)
	_draw_centered("SEEKARTE · %s" % world.current_map_name().to_upper(), Vector2(overlay.get_center().x, overlay.position.y + 30.0*scale_value), int(19.0*scale_value), Color.WHITE)
	var region_rect := Rect2(overlay.position + Vector2(16,12)*scale_value, Vector2(96,36)*scale_value)
	draw_rect(region_rect, Color(0.04,0.14,0.19,0.96), true); draw_string(font, region_rect.position+Vector2(10,24)*scale_value, "REGIONEN", HORIZONTAL_ALIGNMENT_CENTER, region_rect.size.x-20*scale_value, int(10*scale_value), TEXT)
	_m223_chart_hits.append({"rect":region_rect,"action":"view_regions"})
	var close_rect := Rect2(Vector2(overlay.end.x-52*scale_value,overlay.position.y+10*scale_value),Vector2(40,40)*scale_value)
	draw_rect(close_rect,Color(0.12,0.06,0.06,0.92),true); _draw_centered("×",close_rect.get_center()+Vector2(0,6*scale_value),int(20*scale_value),Color.WHITE); _m223_chart_hits.append({"rect":close_rect,"action":"close"})
	var filter_x := overlay.position.x + 18*scale_value
	for filter_id in M223FullSeaChartCatalog.FILTERS:
		var w := (78.0 if filter_id != "all" else 64.0)*scale_value
		var r := Rect2(Vector2(filter_x, overlay.position.y+52*scale_value),Vector2(w,34*scale_value))
		draw_rect(r, Color(0.08,0.34,0.48,0.95) if full_chart_filter==filter_id else Color(0.035,0.10,0.14,0.92), true)
		draw_string(font,r.position+Vector2(7,22)*scale_value,M223FullSeaChartCatalog.filter_label(filter_id),HORIZONTAL_ALIGNMENT_CENTER,r.size.x-14*scale_value,int(9*scale_value),Color.WHITE)
		_m223_chart_hits.append({"rect":r,"action":"filter","filter":filter_id}); filter_x += w + 6*scale_value
	var card_w := minf(250.0*scale_value, overlay.size.x*0.31)
	var chart := Rect2(overlay.position+Vector2(18,96)*scale_value, Vector2(overlay.size.x-card_w-54*scale_value,overlay.size.y-116*scale_value))
	draw_rect(chart,Color(0.02,0.11,0.15,0.96),true); draw_rect(chart,Color(0.3,0.72,0.88,0.35),false,1.0)
	for step in range(1,4):
		var x=chart.position.x+chart.size.x*step/4.0; var y=chart.position.y+chart.size.y*step/4.0
		draw_line(Vector2(x,chart.position.y),Vector2(x,chart.end.y),Color(1,1,1,0.06),1); draw_line(Vector2(chart.position.x,y),Vector2(chart.end.x,y),Color(1,1,1,0.06),1)
	var targets:Array[Dictionary]=[]
	for group_kind in [["ports","harbor"],["enemies","enemy"],["event_interactables","event"],["loot","loot"],["world_poi_markers","poi"]]:
		for node in get_tree().get_nodes_in_group(group_kind[0]):
			var n:=node as Node3D; if n==null or not is_instance_valid(n): continue
			var kind:=M223FullSeaChartCatalog.kind_for(n)
			if not M223FullSeaChartCatalog.visible_for_filter(kind,full_chart_filter): continue
			targets.append({"node":n,"kind":kind})
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	var tracking:=player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime if player!=null else null
	if tracking!=null:
		var objective_target:=tracking.resolve_target()
		if objective_target!=null and M223FullSeaChartCatalog.visible_for_filter("tracked_objective",full_chart_filter): targets.append({"node":objective_target,"kind":"tracked_objective"})
	for item in targets:
		var n:Node3D=item.node; var kind:=str(item.kind); var pos:=_m224_world_to_chart(n.global_position,chart,world.sector_half_size())
		if not chart.has_point(pos): continue
		_m224_draw_chart_marker(pos,kind,n,scale_value)
		_m223_chart_hits.append({"rect":Rect2(pos-Vector2.ONE*16*scale_value,Vector2.ONE*32*scale_value),"action":"select","target":n,"kind":kind})
	if player!=null: _m224_draw_player_marker(_m224_world_to_chart(player.global_position,chart,world.sector_half_size()),scale_value)
	_m224_draw_chart_legend(chart,scale_value)
	_m224_draw_zoom_controls(chart,scale_value)
	var card:=Rect2(Vector2(chart.end.x+16*scale_value,chart.position.y),Vector2(card_w,chart.size.y))
	draw_rect(card,Color(0.025,0.075,0.10,0.98),true)
	if full_chart_selected==null or not is_instance_valid(full_chart_selected):
		draw_string(font,card.position+Vector2(14,30)*scale_value,"ZIEL AUSWÄHLEN",HORIZONTAL_ALIGNMENT_LEFT,card.size.x-28*scale_value,int(13*scale_value),Color.WHITE)
		draw_string(font,card.position+Vector2(14,58)*scale_value,"Tippe einen vorhandenen Marker an.",HORIZONTAL_ALIGNMENT_LEFT,card.size.x-28*scale_value,int(10*scale_value),TEXT)
	else:
		var kind:=str(full_chart_selected.get_meta("m223_chart_kind",M223FullSeaChartCatalog.kind_for(full_chart_selected)))
		draw_string(font,card.position+Vector2(14,30)*scale_value,str(full_chart_selected.name).replace("_"," ").to_upper(),HORIZONTAL_ALIGNMENT_LEFT,card.size.x-28*scale_value,int(12*scale_value),Color.WHITE)
		var event_runtime:=M234WorldEventObjectiveChainCatalog.runtime(get_tree())
		var m234_status:=M234WorldEventObjectiveChainCatalog.chart_status(full_chart_selected,event_runtime)
		var m233_status:=M233WorldEventLifecycleCatalog.marker_status(full_chart_selected,event_runtime)
		var status_text:=m234_status if not m234_status.is_empty() else (m233_status if not m233_status.is_empty() else M224SeaChartPresentationCatalog.status_label(full_chart_selected,kind))
		draw_string(font,card.position+Vector2(14,53)*scale_value,"%s  ·  %s" % [M224SeaChartPresentationCatalog.kind_label(kind), status_text],HORIZONTAL_ALIGNMENT_LEFT,card.size.x-28*scale_value,int(9*scale_value),TEXT)
		if player!=null:
			var distance := Vector2(player.global_position.x-full_chart_selected.global_position.x,player.global_position.z-full_chart_selected.global_position.z).length()
			draw_string(font,card.position+Vector2(14,69)*scale_value,"DISTANZ  %.0f m" % distance,HORIZONTAL_ALIGNMENT_LEFT,card.size.x-28*scale_value,int(9*scale_value),Color(0.64,0.84,0.92))
		var labels:=M223FullSeaChartCatalog.action_labels(kind,kind=="tracked_objective")
		var by:=card.position.y+94*scale_value
		for i in labels.size():
			var br:=Rect2(Vector2(card.position.x+12*scale_value,by+i*46*scale_value),Vector2(card.size.x-24*scale_value,38*scale_value))
			draw_rect(br,Color(0.08,0.34,0.48,0.95),true); draw_string(font,br.position+Vector2(8,25)*scale_value,labels[i],HORIZONTAL_ALIGNMENT_CENTER,br.size.x-16*scale_value,int(10*scale_value),Color.WHITE)
			_m223_chart_hits.append({"rect":br,"action":"context","index":i,"kind":kind,"target":full_chart_selected})


func _m224_world_to_chart(world_pos:Vector3, chart:Rect2, half_size:float)->Vector2:
	var normalized := Vector2(world_pos.x, world_pos.z) / maxf(1.0, half_size)
	normalized = (normalized + full_chart_pan) * full_chart_zoom
	return chart.get_center() + Vector2(normalized.x, normalized.y) * chart.size * 0.5

func _m224_draw_chart_marker(pos:Vector2,kind:String,node:Node3D,scale_value:float)->void:
	var color:=M224SeaChartPresentationCatalog.marker_color(kind)
	var radius:=M224SeaChartPresentationCatalog.marker_radius(kind)*scale_value
	match M224SeaChartPresentationCatalog.marker_shape(kind):
		"diamond":
			var d:=radius*1.2; draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-d),pos+Vector2(d,0),pos+Vector2(0,d),pos+Vector2(-d,0)]),color)
		"square": draw_rect(Rect2(pos-Vector2.ONE*radius,Vector2.ONE*radius*2.0),color,true)
		"ring": draw_circle(pos,radius,color,false,2.2*scale_value); draw_circle(pos,radius*0.35,color,true)
		_: draw_circle(pos,radius,color,true)
	if kind in ["tracked_objective","boss"] or node==full_chart_selected:
		draw_circle(pos,radius+5.0*scale_value,color,false,1.5*scale_value)

func _m224_draw_player_marker(pos:Vector2,scale_value:float)->void:
	var r:=7.0*scale_value; var c:=Color("35cfff")
	draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-r*1.4),pos+Vector2(r, r),pos,pos+Vector2(-r,r)]),c)

func _m224_draw_chart_legend(chart:Rect2,scale_value:float)->void:
	var legend:=Rect2(chart.position+Vector2(10,10)*scale_value,Vector2(188,30)*scale_value)
	draw_rect(legend,Color(0.01,0.04,0.06,0.82),true)
	var x:=legend.position.x+9*scale_value
	for kind in M224SeaChartPresentationCatalog.LEGEND_KINDS:
		draw_circle(Vector2(x,legend.get_center().y),3.2*scale_value,M224SeaChartPresentationCatalog.marker_color(kind),true)
		draw_string(font,Vector2(x+7*scale_value,legend.position.y+19*scale_value),M224SeaChartPresentationCatalog.kind_label(kind),HORIZONTAL_ALIGNMENT_LEFT,-1,int(7*scale_value),TEXT)
		x += 36*scale_value

func _m224_draw_zoom_controls(chart:Rect2,scale_value:float)->void:
	var base:=Vector2(chart.end.x-38*scale_value,chart.position.y+14*scale_value)
	for pair in [["+",1],["−",-1],["1:1",0]]:
		var r:=Rect2(base,Vector2(28,28)*scale_value); draw_rect(r,Color(0.035,0.12,0.17,0.94),true); draw_string(font,r.position+Vector2(4,19)*scale_value,str(pair[0]),HORIZONTAL_ALIGNMENT_CENTER,r.size.x-8*scale_value,int(10*scale_value),Color.WHITE)
		_m223_chart_hits.append({"rect":r,"action":"zoom","step":int(pair[1])}); base.y += 32*scale_value



func _m223_activate_chart_at(point:Vector2)->bool:
	for hit in _m223_chart_hits:
		if not (hit.rect as Rect2).has_point(point): continue
		match str(hit.action):
			"close": global_map_open=false
			"view_regions": full_chart_view="regions"
			"filter": full_chart_filter=str(hit.filter); full_chart_selected=null
			"select":
				full_chart_selected=hit.target as Node3D; if full_chart_selected!=null: full_chart_selected.set_meta("m223_chart_kind",str(hit.kind))
			"zoom":
				if int(hit.step)==0: full_chart_zoom=1.0; full_chart_pan=Vector2.ZERO
				else: full_chart_zoom=clampf(full_chart_zoom+0.2*int(hit.step),M224SeaChartPresentationCatalog.MIN_ZOOM,M224SeaChartPresentationCatalog.MAX_ZOOM); full_chart_pan=M224SeaChartPresentationCatalog.clamp_pan(full_chart_pan,full_chart_zoom)
			"context": _m223_execute_context(str(hit.kind),hit.target as Node3D,int(hit.index))
		queue_redraw(); return true
	if full_chart_view=="regions": full_chart_view="sector"; queue_redraw(); return true
	return true


func _m223_execute_context(kind:String,target:Node3D,index:int)->void:
	var player:=get_tree().get_first_node_in_group("player") as ShipMotor
	if player==null or not M222SeaChartInteractionCatalog.can_navigate(target): return
	if kind=="tracked_objective" and index==0:
		var tracking:=player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
		if tracking!=null: tracking.untrack(); full_chart_selected=null; note("MISSIONSZIEL NICHT MEHR VERFOLGT")
		return
	if kind in ["enemy","boss"] and index==0:
		var targeting:=player.get_node_or_null("Targeting") as TargetingSystem
		if targeting!=null: targeting.set_target(target as ShipMotor); note("ZIEL AUSGEWÄHLT")
		return
	var input:=player.get_node_or_null("PlayerInput") as PlayerShipInput
	if input!=null:
		input.set_navigation_world_target(target.global_position,M222SeaChartInteractionCatalog.navigation_intent(kind)); global_map_open=false; note("KURS GESETZT")

func _draw_global_map_regions(safe: Rect2, scale_value: float, world: WorldMapSystem) -> void:
	if world == null:
		return
	draw_rect(safe, Color(0.005, 0.012, 0.02, 0.82), true)
	var overlay_size := Vector2(min(760.0 * scale_value, safe.size.x - 50.0), min(470.0 * scale_value, safe.size.y - 70.0))
	var overlay := Rect2(safe.get_center() - overlay_size * 0.5, overlay_size)
	draw_rect(overlay, Color(0.025, 0.055, 0.078, 0.98), true)
	draw_rect(overlay, Color(0.28, 0.7, 0.88, 0.72), false, 2.0)
	_draw_centered("GLOBAL SEA MAP — M / MAP TO CLOSE", Vector2(overlay.get_center().x, overlay.position.y + 34.0 * scale_value), int(20.0 * scale_value), Color.WHITE)
	var grid:=Rect2(overlay.position+Vector2(24.0,58.0*scale_value),overlay.size-Vector2(48.0,82.0*scale_value))
	var bounds:=WorldSectorRegistry.map_bounds()
	var rows:=WorldSectorRegistry.effective_all()
	var cell_size:=Vector2(maxf(46.0*scale_value,grid.size.x/maxf(1.0,bounds.size.x+1.0)),maxf(38.0*scale_value,grid.size.y/maxf(1.0,bounds.size.y+1.0)))
	cell_size.x=minf(cell_size.x,110.0*scale_value);cell_size.y=minf(cell_size.y,78.0*scale_value)
	for row in rows:
		var map_pos:=WorldSectorRegistry.map_position_for_id(str(row.get("id","")))
		var normalized:=Vector2((map_pos.x-bounds.position.x)/maxf(1.0,bounds.size.x),(map_pos.y-bounds.position.y)/maxf(1.0,bounds.size.y))
		var center:=grid.position+Vector2(normalized.x*maxf(0.0,grid.size.x-cell_size.x),normalized.y*maxf(0.0,grid.size.y-cell_size.y))
		var cell:=Rect2(center,cell_size).grow(-3.0)
		var selected:=str(row.get("id",""))==world.current_stable_sector_id()
		draw_rect(cell,Color(0.08,0.34,0.48,0.95) if selected else Color(0.04,0.12,0.17,0.95),true)
		draw_rect(cell,Color("55d5ff") if selected else Color(1.0,1.0,1.0,0.18),false,2.0 if selected else 1.0)
		var map_name:=str(row.get("display_name",""))
		var port:=str(row.get("port",""))
		var map_level:=int(row.get("pirate_level",1))
		draw_string(font,cell.position+Vector2(9.0,24.0*scale_value),map_name,HORIZONTAL_ALIGNMENT_LEFT,cell.size.x-18.0,int(11.0*scale_value),Color.WHITE)
		if not port.is_empty():draw_string(font,cell.position+Vector2(9.0,45.0*scale_value),"⚓ %s"%port,HORIZONTAL_ALIGNMENT_LEFT,cell.size.x-18.0,int(10.0*scale_value),Color("f1c75b"))
		if map_level>=2:draw_string(font,cell.position+Vector2(cell.size.x-64.0*scale_value,45.0*scale_value),"GUILD ◈",HORIZONTAL_ALIGNMENT_LEFT,58.0*scale_value,int(8.0*scale_value),Color("d7a94f"))
		draw_string(font,cell.position+Vector2(9.0,cell.size.y-10.0),"Lv. %d"%map_level,HORIZONTAL_ALIGNMENT_LEFT,cell.size.x-18.0,int(9.0*scale_value),TEXT)


func _draw_transition_banner(safe: Rect2, scale_value: float, world: WorldMapSystem) -> void:
	if world == null or world.transition_message_time <= 0.0:
		return
	# Keep world-edge warnings even when cosmetic map-change banners are disabled.
	if world.transition_message != "WORLD EDGE" and not ClientSettings.show_map_transition(get_tree()):
		return
	var alpha: float = clamp(world.transition_message_time, 0.0, 1.0)
	var banner := Rect2(Vector2(safe.get_center().x - 190.0 * scale_value, safe.position.y + 86.0 * scale_value), Vector2(380.0, 54.0) * scale_value)
	draw_rect(banner, Color(0.015, 0.035, 0.05, 0.82 * alpha), true)
	_draw_centered(world.transition_message, banner.get_center() + Vector2(0.0, 7.0 * scale_value), int(19.0 * scale_value), Color(1.0, 1.0, 1.0, alpha))


func _to_minimap(world_position: Vector3, rect: Rect2, half_size: float) -> Vector2:
	var normalized := Vector2(clamp(world_position.x / half_size, -1.0, 1.0), clamp(world_position.z / half_size, -1.0, 1.0))
	return rect.get_center() + normalized * rect.size * 0.48


func _world_map() -> WorldMapSystem:
	var nodes := get_tree().get_nodes_in_group("world_map")
	return nodes[0] as WorldMapSystem if not nodes.is_empty() else null


func _draw_bar(rect: Rect2, value: float, color: Color) -> void:
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.56), true)
	var inner := Rect2(rect.position + Vector2(2.0, 2.0), Vector2(max(0.0, rect.size.x - 4.0) * clamp(value, 0.0, 1.0), max(1.0, rect.size.y - 4.0)))
	draw_rect(inner, color, true)


func _draw_centered(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center - Vector2(text_size.x * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _safe_rect() -> Rect2:
	var viewport_rect := get_viewport_rect()
	var platform_safe := DisplayServer.get_display_safe_area()
	if platform_safe.size.x <= 0 or platform_safe.size.y <= 0:
		return viewport_rect
	var screen_size := DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return viewport_rect
	var ratio := viewport_rect.size / Vector2(screen_size)
	return Rect2(Vector2(platform_safe.position) * ratio, Vector2(platform_safe.size) * ratio)


func _m283_sync_projectile_presentation_state() -> void:
	var runtime := get_tree().get_first_node_in_group("projectile_salvo_presentation_readiness") as M283ProjectileSalvoPresentationRuntime
	if runtime == null:
		m283_projectile_presentation_state.clear()
		return
	var view := runtime.presentation_view(layout())
	if view.is_empty():
		m283_projectile_presentation_state.clear()
	else:
		m283_projectile_presentation_state = view.duplicate(true)


func _m284_sync_naval_combat_identity_state() -> void:
	var runtime := get_tree().get_first_node_in_group("naval_combat_identity_readiness") as M284NavalCombatIdentityRuntime
	if runtime == null:
		m284_naval_combat_identity_state.clear()
		return
	if int(runtime.snapshot().get("profile_revision", -1)) < 0:
		var projectile := get_tree().get_first_node_in_group("projectile_salvo_presentation_readiness") as M283ProjectileSalvoPresentationRuntime
		runtime.bind_projectile_presentation(projectile)
	var view := runtime.presentation_view(layout())
	m284_naval_combat_identity_state = view.duplicate(true) if not view.is_empty() else {}


func _m285_sync_ship_damage_defeat_state() -> void:
	var runtime := get_tree().get_first_node_in_group("ship_damage_defeat_presentation_readiness") as M285ShipDamageDefeatPresentationRuntime
	if runtime == null:
		m285_ship_damage_defeat_state.clear()
		return
	if int(runtime.snapshot().get("state_revision", -1)) < 0:
		var combat_state := get_tree().get_first_node_in_group("authoritative_combat_state_readiness") as M270AuthoritativeCombatStateRuntime
		var feedback := get_tree().get_first_node_in_group("combat_event_feedback_readiness") as M282CombatEventFeedbackRuntime
		var projectiles := get_tree().get_first_node_in_group("projectile_salvo_presentation_readiness") as M283ProjectileSalvoPresentationRuntime
		var identity := get_tree().get_first_node_in_group("naval_combat_identity_readiness") as M284NavalCombatIdentityRuntime
		runtime.bind_authority_layers(combat_state, feedback, projectiles, identity)
	var view := runtime.presentation_view(layout())
	m285_ship_damage_defeat_state = view.duplicate(true) if not view.is_empty() else {}


func _m286_sync_ship_damage_escalation_state() -> void:
	var runtime := get_tree().get_first_node_in_group("ship_damage_escalation_readiness") as M286ShipDamageEscalationRuntime
	if runtime == null:
		m286_ship_damage_escalation_state.clear()
		return
	if int(runtime.snapshot().get("escalation_revision", -1)) < 0:
		var damage_presentation := get_tree().get_first_node_in_group("ship_damage_defeat_presentation_readiness") as M285ShipDamageDefeatPresentationRuntime
		runtime.bind_ship_damage_presentation(damage_presentation)
	var view := runtime.presentation_view(layout())
	m286_ship_damage_escalation_state = view.duplicate(true) if not view.is_empty() else {}


func _m287_sync_ship_motion_identity_state() -> void:
	var runtime := get_tree().get_first_node_in_group("ship_motion_identity_readiness") as M287ShipMotionIdentityRuntime
	if runtime == null:
		m287_ship_motion_identity_state.clear()
		return
	if int(runtime.snapshot().get("motion_revision", -1)) < 0:
		var movement := get_tree().get_first_node_in_group("authoritative_movement_readiness") as M268AuthoritativeMovementRuntime
		runtime.bind_authoritative_movement(movement)
	var view := runtime.presentation_view(layout())
	m287_ship_motion_identity_state = view.duplicate(true) if not view.is_empty() else {}


func _m288_sync_naval_contact_readability_state() -> void:
	var runtime := get_tree().get_first_node_in_group("naval_contact_readability_readiness") as M288NavalContactReadabilityRuntime
	if runtime == null:
		m288_naval_contact_readability_state.clear()
		return
	if int(runtime.snapshot().get("contact_revision", -1)) < 0:
		var targeting := get_tree().get_first_node_in_group("targeting_relationship_authority_readiness") as M271TargetingRelationshipAuthorityRuntime
		runtime.bind_targeting_authority(targeting)
	var view := runtime.presentation_view(layout())
	m288_naval_contact_readability_state = view.duplicate(true) if not view.is_empty() else {}


func _m289_sync_playable_vertical_slice_state() -> void:
	var runtime := get_tree().get_first_node_in_group("playable_vertical_slice_readiness") as M289PlayableVerticalSliceRuntime
	if runtime == null:
		m289_playable_vertical_slice_state.clear()
		return
	m289_playable_vertical_slice_state = runtime.readiness_view().duplicate(true)


func _m290_sync_first_sortie_state() -> void:
	var runtime := get_tree().get_first_node_in_group("first_sortie_integration") as M290FirstSortieIntegrationRuntime
	if runtime == null:
		m290_first_sortie_state.clear()
		return
	m290_first_sortie_state = runtime.presentation_view(layout()).duplicate(true)


func _draw_m290_first_sortie_guidance(layout_value: Dictionary) -> void:
	if m290_first_sortie_state.is_empty(): return
	var mission: Rect2 = layout_value.get("mission", Rect2())
	if not mission.has_area(): return
	var observed := int(m290_first_sortie_state.get("observed", 0))
	var total := maxi(1, int(m290_first_sortie_state.get("total", 12)))
	# Tracked-quest title occupies the left side. On narrow layouts, skip the
	# secondary badge altogether; the Command Deck retains the full evidence.
	if mission.size.x < 192.0: return
	var label := "%d/%d" % [observed, total]
	var width := minf(48.0, mission.size.x * 0.22)
	var text_rect := Rect2(mission.end.x - width - 8.0, mission.position.y + 7.0, width, 16.0)
	draw_string(font, text_rect.position + Vector2(0, 11), label, HORIZONTAL_ALIGNMENT_RIGHT, text_rect.size.x, 10, NauticalHud.LIGHT)
	var progress_rect := Rect2(text_rect.position + Vector2(0, 15), Vector2(text_rect.size.x, 3))
	draw_rect(progress_rect, Color(0.01, 0.04, 0.06, 0.8))
	draw_rect(Rect2(progress_rect.position, Vector2(progress_rect.size.x * clampf(float(observed) / float(total), 0.0, 1.0), progress_rect.size.y)), NauticalHud.GOLD)

class_name AdminOverlay
extends Control
## Touch/desktop local admin panel. All commands are local development actions.

var runtime:AdminModeRuntime
var shade:ColorRect
var panel:PanelContainer
var toggle:Button
var status:Label
var asset_filter:LineEdit
var asset_list:VBoxContainer
var asset_category:OptionButton
var module_picker:OptionButton
var content_type_picker:OptionButton
var content_summary:Label
var draft_picker:OptionButton
var draft_editor:TextEdit
var draft_feedback:Label
var selected_draft_id:=""
var transport_status_label:Label
var p0_asset_status_label:Label
var production_wave_status_label:Label
var meta_status_label:Label

func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_IGNORE;process_mode=Node.PROCESS_MODE_ALWAYS;theme=NauticalTheme.create()
	runtime=get_tree().get_first_node_in_group("admin_runtime") as AdminModeRuntime
	shade=ColorRect.new();shade.color=Color(0.005,0.018,0.028,0.86);shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT);shade.mouse_filter=MOUSE_FILTER_STOP;add_child(shade)
	toggle=Button.new();toggle.text="ADMIN";toggle.mouse_filter=MOUSE_FILTER_STOP;toggle.custom_minimum_size=Vector2(96,52)*NauticalTheme.density_scale();toggle.pressed.connect(_toggle);add_child(toggle)
	panel=PanelContainer.new();panel.mouse_filter=MOUSE_FILTER_STOP;panel.custom_minimum_size=Vector2(330,420);panel.add_theme_stylebox_override("panel",NauticalHud.box_style());add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
	panel.add_child(margin)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=SIZE_EXPAND_FILL;scroll.add_child(body)
	var title:=Label.new();title.text="M163 ADMIN · GAMEPLAY AUTHORING + COMMERCE + COMMANDS";body.add_child(title)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(status)
	var role_status:=Label.new();role_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;role_status.text=runtime.verified_admin_summary();body.add_child(role_status)
	_build_module_browser(body)
	var transport_title:=Label.new();transport_title.text="ADMIN SERVICE TRANSPORT";body.add_child(transport_title)
	transport_status_label=Label.new();transport_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(transport_status_label)
	_btn(body,"Snapshot TEST anfragen",_request_test_snapshot)
	_btn(body,"Request-Queue erneut versuchen",_flush_admin_queue)
	var asset_wave_title:=Label.new();asset_wave_title.text="P0 ASSET PRODUCTION · M146";body.add_child(asset_wave_title)
	p0_asset_status_label=Label.new();p0_asset_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(p0_asset_status_label)
	var future_wave_title:=Label.new();future_wave_title.text="REGIONAL VISUALS + W5 GLB/LOD + CLASS 51–100 + PRESTIGE · M163";body.add_child(future_wave_title)
	production_wave_status_label=Label.new();production_wave_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(production_wave_status_label)
	var meta_title:=Label.new();meta_title.text="V3.8 · BEGLEITER / ARTEFAKTE / AFK-REWARDS";body.add_child(meta_title)
	meta_status_label=Label.new();meta_status_label.name="M152MetaStatus";meta_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(meta_status_label)
	_btn(body,"Schließen",_toggle)
	_btn(body,"Halloween AN/AUS",func():runtime.toggle_halloween();_refresh())
	_btn(body,"Eventphase weiter",func():runtime.cycle_event_phase();_refresh())
	_btn(body,"+100 Eventwährung",func():runtime.add_event_currency();_refresh())
	_btn(body,"+25 Eventscore",func():runtime.event().admin_add_score(25);_refresh())
	_btn(body,"Test-Kit + 25.000 Gold",func():runtime.grant_test_kit();_refresh())
	_btn(body,"Voll reparieren",func():runtime.heal_full();_refresh())
	_btn(body,"Unverwundbarkeit AN/AUS",func():runtime.toggle_invulnerability();_refresh())
	for level in [1,2,3,4,5,6,10,15]:
		_btn(body,"Teleport Kartenlevel %d"%level,func(v=level):runtime.teleport_level(v);_refresh())
	_btn(body,"Halloween Sloop spawnen",func():runtime.spawn_event_preview("event_halloween_npc_sloop_01"))
	_btn(body,"Halloween Raider spawnen",func():runtime.spawn_event_preview("event_halloween_npc_raider_01"))
	_btn(body,"Halloween Admiral spawnen",func():runtime.spawn_event_preview("event_halloween_admiral_01"))
	_btn(body,"Halloween Monster spawnen",func():runtime.spawn_event_preview("event_halloween_monster_01"))
	_btn(body,"Halloween Boss spawnen",func():runtime.spawn_event_preview("event_halloween_boss_01"))
	_btn(body,"Gildeninsel Relation wechseln",func():runtime.cycle_guild_relation();_refresh())
	_btn(body,"Gildenturm-Zustand wechseln",func():runtime.cycle_guild_tower_state();_refresh())
	_btn(body,"Turmreichweiten AN/AUS",func():runtime.toggle_guild_range_preview();_refresh())
	_btn(body,"Seekarte neu aufbauen",func():runtime.rebuild_sector();_refresh())
	var asset_title:=Label.new();asset_title.text="ASSET / EVENT SPAWN BROWSER";body.add_child(asset_title)
	asset_category=OptionButton.new()
	for label in ["ALLE","HALLOWEEN WORLD","HALLOWEEN COMBAT","HALLOWEEN GUILD","HALLOWEEN REWARD"]:asset_category.add_item(label)
	asset_category.item_selected.connect(func(_index):_rebuild_asset_list(asset_filter.text if asset_filter!=null else ""))
	body.add_child(asset_category)
	asset_filter=LineEdit.new();asset_filter.placeholder_text="Asset-ID filtern …";asset_filter.text_changed.connect(_rebuild_asset_list);body.add_child(asset_filter)
	asset_list=VBoxContainer.new();body.add_child(asset_list)
	var content_title:=Label.new();content_title.text="CONTENT STUDIO · LOCAL DRAFT PREVIEW";body.add_child(content_title)
	var registry:=runtime.content_registry()
	if registry!=null:
		content_summary=Label.new();content_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(content_summary)
		content_type_picker=OptionButton.new();content_type_picker.custom_minimum_size.y=52*NauticalTheme.density_scale()
		for type_id in registry.supported_types():content_type_picker.add_item(type_id)
		body.add_child(content_type_picker)
		_btn(body,"Test-Item Draft anlegen",func():runtime.create_content_draft("item","ITEM-LOCAL-%d"%Time.get_ticks_msec(),"Local Test Item");_refresh())
		_btn(body,"Test-Schiff Draft anlegen",func():runtime.create_content_draft("ship","SHIP-LOCAL-%d"%Time.get_ticks_msec(),"Local Test Ship");_refresh())
		_btn(body,"Test-Event Draft anlegen",func():runtime.create_content_draft("event","EVENT-LOCAL-%d"%Time.get_ticks_msec(),"Local Test Event");_refresh())
		_btn(body,"Gewählten Typ als Draft",func():_create_selected_type())
		var draft_title:=Label.new();draft_title.text="PERSISTENTE DRAFTS · JSON EDITOR";body.add_child(draft_title)
		draft_picker=OptionButton.new();draft_picker.custom_minimum_size.y=52*NauticalTheme.density_scale();draft_picker.item_selected.connect(_select_draft);body.add_child(draft_picker)
		draft_editor=TextEdit.new();draft_editor.custom_minimum_size=Vector2(360,220)*NauticalTheme.density_scale();draft_editor.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;body.add_child(draft_editor)
		draft_feedback=Label.new();draft_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(draft_feedback)
		_btn(body,"Änderungen lokal speichern",_save_selected_draft)
		_btn(body,"Draft validieren",_validate_selected_draft)
		_btn(body,"Review lokal markieren",func():_set_selected_status("review"))
		_btn(body,"Publish-Request für TEST vormerken",_queue_publish_request)
		registry.drafts_changed.connect(_on_drafts_changed)
		_rebuild_draft_picker()
	var publish_note:=Label.new();publish_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;publish_note.text="Produktiv-Publish: server-verifizierte Rolle + Einzelpermission + ggf. Freigabe erforderlich";body.add_child(publish_note)
	_btn(body,"Admin-Spawns entfernen",func():runtime.clear_admin_spawns();_refresh())
	_rebuild_asset_list("")
	shade.hide();panel.hide();runtime.changed.connect(_refresh);get_viewport().size_changed.connect(_layout);_layout();_refresh()

func _asset_ids()->Array[String]:
	var data:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m95_admin_asset_browser.json"))
	var result:Array[String]=[]
	if not data is Dictionary:return result
	var category_keys:=["","halloween_world","halloween_combat","halloween_guild","halloween_reward"]
	var selected:=asset_category.selected if asset_category!=null else 0
	var key: String = category_keys[clampi(selected,0,category_keys.size()-1)]
	for category in data.get("categories",{}):
		if not key.is_empty() and str(category)!=key:continue
		for id in data.categories[category]:
			if str(id) not in result:result.append(str(id))
	result.sort()
	return result

func _rebuild_asset_list(filter_text:String)->void:
	if asset_list==null:return
	for child in asset_list.get_children():child.queue_free()
	var query:=filter_text.strip_edges().to_lower()
	var shown:=0
	for id in _asset_ids():
		if not query.is_empty() and not id.to_lower().contains(query):continue
		if shown>=12:break
		var b:=Button.new();b.text=id;b.custom_minimum_size.y=48*NauticalTheme.density_scale()
		b.pressed.connect(func(asset_id=id):runtime.spawn_event_preview(asset_id))
		asset_list.add_child(b);shown+=1
	if shown==0:
		var l:=Label.new();l.text="Keine passenden Assets.";asset_list.add_child(l)

func _btn(parent:Node,text:String,call:Callable)->void:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=52*NauticalTheme.density_scale();b.pressed.connect(call,CONNECT_DEFERRED);parent.add_child(b)

func _build_module_browser(parent:VBoxContainer)->void:
	var heading:=Label.new();heading.text="MODULE · Rechte werden serverseitig geprüft";parent.add_child(heading)
	module_picker=OptionButton.new();module_picker.custom_minimum_size.y=52*NauticalTheme.density_scale()
	var modules:=get_tree().get_first_node_in_group("admin_module_registry") as AdminModuleRegistry
	if modules!=null:
		for module in modules.visible_modules(runtime.authorization(),true):
			module_picker.add_item("%s · %s"%[str(module.get("label","")),str(module.get("permission",""))])
	parent.add_child(module_picker)

func _create_selected_type()->void:
	if content_type_picker==null or content_type_picker.item_count==0:return
	var type_id:=content_type_picker.get_item_text(content_type_picker.selected)
	var schema:=runtime.content_registry().type_schema(type_id)
	var prefix:=str(schema.get("id_prefix",type_id.to_upper()+"-"))
	runtime.create_content_draft(type_id,prefix+"LOCAL-"+str(Time.get_ticks_msec()),"Local "+type_id.capitalize())
	_refresh()

func _record(id:String)->Dictionary:
	var registry:=runtime.content_registry() if runtime!=null else null
	if registry==null:return {}
	for row in registry.records():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}

func _rebuild_draft_picker()->void:
	if draft_picker==null:return
	var keep:=selected_draft_id
	draft_picker.clear()
	var registry:=runtime.content_registry() if runtime!=null else null
	if registry==null:return
	var selected_index:=-1
	for row in registry.records():
		if not row is Dictionary:continue
		var id:=str(row.get("id",""))
		draft_picker.add_item("%s · %s"%[id,str(row.get("status","draft"))])
		draft_picker.set_item_metadata(draft_picker.item_count-1,id)
		if id==keep:selected_index=draft_picker.item_count-1
	if draft_picker.item_count==0:
		selected_draft_id=""
		if draft_editor!=null:draft_editor.text=""
		return
	draft_picker.select(selected_index if selected_index>=0 else 0)
	_select_draft(draft_picker.selected)

func _select_draft(index:int)->void:
	if draft_picker==null or index<0 or index>=draft_picker.item_count:return
	selected_draft_id=str(draft_picker.get_item_metadata(index))
	var row:=_record(selected_draft_id)
	if draft_editor!=null:draft_editor.text=JSON.stringify(row,"\t")
	if draft_feedback!=null:draft_feedback.text="LOKAL · Revision %d · keine Live-Authority"%int(row.get("revision",0))

func _save_selected_draft()->void:
	if selected_draft_id.is_empty() or draft_editor==null:return
	var parsed:Variant=JSON.parse_string(draft_editor.text)
	if not parsed is Dictionary:
		draft_feedback.text="FEHLER · JSON ist ungültig";return
	var changes:Dictionary=(parsed as Dictionary).duplicate(true)
	changes.erase("id");changes.erase("type")
	if runtime.content_registry().patch_draft(selected_draft_id,changes):
		draft_feedback.text="GESPEICHERT · nur lokale Vorschau"
	else:draft_feedback.text="FEHLER · Draft nicht gefunden"

func _validate_selected_draft()->void:
	var row:=_record(selected_draft_id)
	if row.is_empty():return
	var errors:=runtime.content_registry().validate_record(row)
	if errors.is_empty():
		runtime.content_registry().set_local_status(str(row.get("id","")),"validated");draft_feedback.text="VALIDIERT · bereit für lokalen Review"
	else:draft_feedback.text="VALIDIERUNG · "+", ".join(errors)

func _set_selected_status(value:String)->void:
	if selected_draft_id.is_empty():return
	if runtime.content_registry().set_local_status(selected_draft_id,value):draft_feedback.text="STATUS · "+value.to_upper()
	else:draft_feedback.text="STATUS BLOCKIERT · erst validieren oder lokal zurücksetzen"

func _queue_publish_request()->void:
	var row:=_record(selected_draft_id)
	if row.is_empty():return
	if str(row.get("status",""))!="review":draft_feedback.text="REQUEST BLOCKIERT · Draft zuerst validieren und Review markieren";return
	var gateway:=get_tree().get_first_node_in_group("content_admin_gateway") as ContentAdminGateway
	if gateway==null:draft_feedback.text="GATEWAY · nicht verfügbar";return
	var envelope:=gateway.build_request("publish",{"id":selected_draft_id,"revision":int(row.get("revision",0))},"TEST","ingame_admin")
	draft_feedback.text="TEST REQUEST · sicher vorgemerkt, Produktion unverändert\n"+str(envelope.get("request_id",""))
	_refresh()

func _request_test_snapshot()->void:
	var transport:=get_tree().get_first_node_in_group("admin_http_transport") as AdminHttpTransport
	if transport!=null:transport.request_snapshot("TEST")
	_refresh()

func _flush_admin_queue()->void:
	var transport:=get_tree().get_first_node_in_group("admin_http_transport") as AdminHttpTransport
	if transport!=null:transport.flush()
	_refresh()

func _on_drafts_changed()->void:
	_rebuild_draft_picker()
	_refresh()

func _toggle()->void:
	if runtime==null:return
	runtime.toggle_overlay()

func _input(event:InputEvent)->void:
	if runtime!=null and runtime.overlay_open and event.is_action_pressed("ui_cancel"):
		runtime.toggle_overlay();get_viewport().set_input_as_handled()

func _refresh()->void:
	if runtime==null:return
	var ev:=runtime.event();var p:=runtime.player()
	status.text="LOKAL · keine Live-Authority\nEvent: %s · Phase %d · %s\nInvulnerable: %s"%[
		("AUS" if ev==null or not ev.is_active() else ev.title()),(0 if ev==null or not ev.is_active() else ev.phase),
		("" if ev==null or not ev.is_active() else ev.phase_label()),str(bool(p.get_meta("admin_invulnerable",false))) if p!=null else "false"]
	if content_summary!=null and runtime.content_registry()!=null:
		var summary:=runtime.content_registry().local_summary()
		content_summary.text="%d Typen · %d lokale Datensätze · Draft/Validate/Review lokal · Publish nur Server"%[int(summary.get("types",0)),int(summary.get("records",0))]
	if transport_status_label!=null:
		var gateway:=get_tree().get_first_node_in_group("content_admin_gateway") as ContentAdminGateway
		var transport_status:=gateway.transport_status() if gateway!=null else {}
		var queue_status:=transport_status.get("queue",{}) as Dictionary
		var snapshots:=get_tree().get_first_node_in_group("content_snapshot_service") as ContentSnapshotService
		transport_status_label.text="%s · HTTPS-Profile %d · Queue %d · GLOBAL GESPERRT\nSnapshot: %s · server-verifiziert: %s"%[
			str(transport_status.get("last_event","OFFLINE")),(transport_status.get("online_profiles",[]) as Array).size(),int(queue_status.get("count",0)),
			(snapshots.content_version if snapshots!=null else "unbekannt"),str(snapshots.server_verified if snapshots!=null else false)]
	if p0_asset_status_label!=null:
		var swap:=get_tree().get_first_node_in_group("p0_asset_swap_service") as P0AssetSwapService
		var asset_status:=swap.summary() if swap!=null else {}
		p0_asset_status_label.text="%d/%d eigene GLB-Swap-Slots gültig · Austausch ohne Code: %s\nNächste Welle: %s"%[
			int(asset_status.get("valid",0)),int(asset_status.get("total",0)),str(bool(asset_status.get("replace_without_code",false))),str(asset_status.get("next_wave","P1 nach P0-Abnahme"))]
	if production_wave_status_label!=null:
		var waves:=get_tree().get_first_node_in_group("production_wave_catalog") as ProductionWaveCatalog
		var wave_status:=waves.summary() if waves!=null else {}
		var regional:=get_tree().get_first_node_in_group("p1_regional_asset_catalog") as P1RegionalAssetCatalog
		var regional_status:=regional.summary() if regional!=null else {}
		var visual_acceptance:=get_tree().get_first_node_in_group("p1_regional_visual_acceptance_catalog") as P1RegionalVisualAcceptanceCatalog
		var visual_status:=visual_acceptance.summary() if visual_acceptance!=null else {}
		var late_fleet:=get_tree().get_first_node_in_group("ship_production_architecture") as ShipProductionArchitecture
		var late_status:=late_fleet.summary() if late_fleet!=null else {}
		var w5:=W5ProductionBatch.summary()
		production_wave_status_label.text="P1 Schiffe %d/%d · Regionalbatch %d/%d · P2 %d reserviert · P3 %d · P4 %d\nM150 Visuals: %d Materialprofile · gültig %s\nM153 W5: %d/10 LOD-Sets · %d/30 GLBs · %d Sockets\nFlotte: %d Klassen-Slots · %d Prestige · finale GLB %d · ehrliche Placeholder %d · Fallback %d\nGLOBAL gesperrt %s · Live-Aktivierung: %s"%[
			int(wave_status.get("p1_glb_ready",0)),int(wave_status.get("p1_glb_total",0)),int(regional_status.get("valid_glb",0)),int(regional_status.get("total",0)),int(wave_status.get("p2_reserved",0)),
			int(wave_status.get("p3_reserved",0)),int(wave_status.get("p4_reserved",0)),int(visual_status.get("materials",0)),str(bool(visual_status.get("valid",false))),int(w5.get("complete_lod_sets",0)),int(w5.get("lod_files",0)),int(w5.get("socket_count",0)),int(late_status.get("regular_slots",0)),int(late_status.get("prestige_slots",0)),int(late_status.get("final_glb_ready",0)),int(late_status.get("production_glb_placeholders",0)),int(late_status.get("runtime_fallbacks",0)),str(bool(late_status.get("global_locked",true))),str(bool(late_status.get("live_activation",false)))]
	if meta_status_label!=null:
		var companions:=CompanionCatalog.summary()
		var artifacts:=ArtifactCatalog.summary()
		var afk:=AfkRewardCatalog.summary()
		var commerce:=get_tree().get_first_node_in_group("commerce_catalog") as M161CommerceCatalog
		var commerce_summary:=commerce.summary() if commerce!=null else {}
		var commands:=get_tree().get_first_node_in_group("admin_command_registry") as M161AdminCommandRegistry
		var command_summary:=commands.summary() if commands!=null else {}
		var no_code:=get_tree().get_first_node_in_group("no_code_capability_catalog") as M161NoCodeCapabilityCatalog
		var no_code_summary:=no_code.summary() if no_code!=null else {}
		meta_status_label.text="Begleiter %d · Artefakte %d · AFK-Profile %d · Cap %dh\nM163 No-Code: %d Familien · %d Contenttypen · Commerce %d Shops/%d Angebote · Staff Commands %d\nPayment/Entitlements/Commands: SERVER AUTHORITY · RBAC + Audit + Approval\nGLOBAL: Serverzeit + Idempotenz + Audit erforderlich"%[
			int(companions.get("definitions",0)),int(artifacts.get("definitions",0)),int(afk.get("profiles",0)),int(int(afk.get("cap_seconds",0))/3600),
			int(no_code_summary.get("families",0)),int(no_code_summary.get("authorable_types",0)),int(commerce_summary.get("shops",0)),int(commerce_summary.get("offers",0)),int(command_summary.get("commands",0))]
	var open:=runtime.overlay_open
	panel.visible=open;shade.visible=open;mouse_filter=MOUSE_FILTER_STOP if open else MOUSE_FILTER_IGNORE
	toggle.visible=not InputDeviceProfile.touch_like(get_viewport_rect().size) and not open
	var player_ship:=runtime.player()
	if player_ship!=null:
		player_ship.set_meta("admin_panel_open",open)
		if open:
			(player_ship.get_node("PlayerInput") as PlayerShipInput).cancel_navigation();player_ship.stop_ship()

func _layout()->void:
	var safe:=get_viewport_rect()
	var screen_safe:=DisplayServer.get_display_safe_area()
	var screen_size:=DisplayServer.screen_get_size()
	if screen_safe.size.x>0 and screen_safe.size.y>0 and screen_size.x>0 and screen_size.y>0:
		var ratio:=safe.size/Vector2(screen_size)
		safe=Rect2(Vector2(screen_safe.position)*ratio,Vector2(screen_safe.size)*ratio)
	var sx:=NauticalTheme.density_scale();var touch:=InputDeviceProfile.touch_like(safe.size)
	var toggle_size:=Vector2(96,52)*sx
	toggle.size=toggle_size;toggle.position=Vector2(safe.end.x-toggle_size.x-12*sx,safe.position.y+112*sx);toggle.visible=not touch and not runtime.overlay_open
	panel.size=Vector2(minf(760*sx,safe.size.x-28*sx),safe.size.y-28*sx)
	panel.position=safe.get_center()-panel.size*0.5

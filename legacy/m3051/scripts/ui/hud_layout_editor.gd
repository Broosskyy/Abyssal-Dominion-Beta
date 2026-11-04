class_name HudLayoutEditor
extends Control
## M86 fullscreen HUD editor with touch/mouse editing and non-invasive device QA preview.
## Drag, scale, visibility, presets, snapping and overlap warnings.

signal closed
const LABELS={
	"profile_status":"Kapitän / Status","mission":"Mission","objective":"Ziel",
	"minimap":"Minimap","movement":"Navigation","combat":"Kampf",
	"quickbar":"Schnellleiste","target":"Zielinfo","currency":"Währungen"
}
const GROUP_IDS={
	"profile_status":["top"],"mission":["mission"],"objective":["objective_strip"],
	"minimap":["minimap","world","group"],"movement":["wheel","zoom_in","zoom_out","recenter","auto_fire"],
	"combat":["fire","repair","boost","target","ammo_menu","items_menu"],
	"quickbar":["quick_0","quick_1","quick_2","quick_3"],"target":["target_info"],"currency":["currency"]
}
var store:HudLayoutStore
var profile:=""
var dragging:=""
var selected:=""
var drag_start:=Vector2.ZERO
var base_offset:=Vector2.ZERO
var buttons:Dictionary={}
var overlaps:Array[String]=[]
var snap_x:float=INF
var snap_y:float=INF
var qa_index:=0
var qa_enabled:=false

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	process_mode=Node.PROCESS_MODE_ALWAYS
	store=HudLayoutStore.current(get_tree())
	_refresh()

func _safe()->Rect2:
	var hud:=get_tree().get_first_node_in_group("hud") as GameHud
	return hud._safe_rect() if hud!=null else get_viewport_rect()

func _profile()->String:
	return str(InputDeviceProfile.detect(_safe().size).get("hud_profile","desktop_wide"))

func _refresh()->void:
	profile=_profile()
	if store!=null:NauticalLayout.set_player_offsets(profile,store.layouts.get(profile,{}))
	buttons.clear()
	var current:=NauticalLayout.calculate(_safe())
	for group_id in LABELS:
		var r:=_group_bounds(current,group_id)
		if r.has_area():buttons[group_id]=r.grow(6.0)
		else:
			# hidden groups retain a small editor chip instead of vanishing forever
			var index:=HudLayoutStore.GROUPS.find(group_id)
			buttons[group_id]=Rect2(Vector2(24+float(index%3)*132,82+float(index/3)*42),Vector2(124,34))
	_update_overlap_warnings()
	queue_redraw()

func _group_bounds(layout:Dictionary,group_id:String)->Rect2:
	var result:=Rect2()
	var first:=true
	for id in GROUP_IDS[group_id]:
		var r:Rect2=layout.actions.get(id,layout.get(id,Rect2()))
		if not r.has_area():continue
		result=r if first else result.merge(r)
		first=false
	return result

func _control_rect(id:String)->Rect2:
	var narrow:=size.x<1180.0
	var y:=size.y-(118.0 if narrow else 70.0)
	if narrow:
		match id:
			"qa":return Rect2(12,68,150,40)
			"reset":return Rect2(12,y,92,42)
			"reset_all":return Rect2(110,y,104,42)
			"standard":return Rect2(220,y,92,42)
			"combat":return Rect2(318,y,92,42)
			"minimal":return Rect2(416,y,92,42)
			"scale_down":return Rect2(12,y+48,76,42)
			"scale_up":return Rect2(94,y+48,76,42)
			"visibility":return Rect2(176,y+48,82,42)
			"lock":return Rect2(264,y+48,82,42)
			"done":return Rect2(352,y+48,106,42)
	else:
		match id:
			"qa":return Rect2(12,68,150,40)
			"reset":return Rect2(12,y,92,46)
			"reset_all":return Rect2(110,y,104,46)
			"standard":return Rect2(220,y,92,46)
			"combat":return Rect2(318,y,92,46)
			"minimal":return Rect2(416,y,92,46)
			"scale_down":return Rect2(size.x-458,y,76,46)
			"scale_up":return Rect2(size.x-376,y,76,46)
			"visibility":return Rect2(size.x-294,y,82,46)
			"lock":return Rect2(size.x-206,y,82,46)
			"done":return Rect2(size.x-118,y,106,46)
	return Rect2()

func _gui_input(event:InputEvent)->void:
	var point:=Vector2.ZERO
	var pressed:=false
	var released:=false
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		point=event.position;pressed=event.pressed;released=not event.pressed
	elif event is InputEventScreenTouch:
		point=event.position;pressed=event.pressed;released=not event.pressed
	elif event is InputEventMouseMotion and not dragging.is_empty():
		_drag(event.position);accept_event();return
	elif event is InputEventScreenDrag and not dragging.is_empty():
		_drag(event.position);accept_event();return
	else:return
	if pressed:
		if _handle_toolbar(point):
			accept_event();return
		for id in buttons:
			if (buttons[id] as Rect2).has_point(point):
				selected=id
				var selected_row:=store.row(profile,id)
				if not bool(selected_row.locked) and (bool(selected_row.visible) or id not in HudLayoutStore.HIDEABLE):
					dragging=id;drag_start=point;base_offset=store.offset(profile,id,_safe())
				_refresh()
				accept_event();return
	if released and not dragging.is_empty():
		_drag(point);dragging="";snap_x=INF;snap_y=INF;_refresh();accept_event()

func _handle_toolbar(point:Vector2)->bool:
	if _control_rect("qa").has_point(point):
		qa_enabled=true
		qa_index+=1
		_refresh()
		return true
	if _control_rect("reset").has_point(point):
		store.reset_profile(profile);NauticalLayout.clear_player_offsets();selected="";_refresh();return true
	if _control_rect("reset_all").has_point(point):
		store.reset_all();NauticalLayout.clear_player_offsets();selected="";_refresh();return true
	for preset in ["standard","combat","minimal"]:
		if _control_rect(preset).has_point(point):
			store.apply_preset(profile,preset);selected="";_refresh();return true
	if _control_rect("done").has_point(point):
		closed.emit();queue_free();return true
	if selected.is_empty():return false
	if _control_rect("lock").has_point(point):
		store.toggle_lock(profile,selected);dragging="";_refresh();return true
	var selected_row:=store.row(profile,selected)
	if bool(selected_row.locked):return false
	if _control_rect("scale_down").has_point(point):
		var row:=store.row(profile,selected);store.set_scale(profile,selected,float(row.scale)-0.05);_refresh();return true
	if _control_rect("scale_up").has_point(point):
		var row:=store.row(profile,selected);store.set_scale(profile,selected,float(row.scale)+0.05);_refresh();return true
	if _control_rect("visibility").has_point(point):
		store.toggle_visible(profile,selected);_refresh();return true
	return false

func _drag(point:Vector2)->void:
	if store==null or dragging.is_empty():return
	var desired:=base_offset+(point-drag_start)
	var safe:=_safe()
	var snap:=_snap_delta(dragging,desired,safe)
	store.set_offset(profile,dragging,snap,safe)
	_refresh()

func _snap_delta(group_id:String,desired:Vector2,safe:Rect2)->Vector2:
	var threshold:=14.0
	var base_layout:=NauticalLayout.calculate(safe)
	var current:=_group_bounds(base_layout,group_id)
	if not current.has_area():return desired
	# reverse currently stored offset so we can reason from default center
	var existing:=store.offset(profile,group_id,safe)
	var default_center:=current.get_center()-existing
	var proposed:=default_center+desired
	var xs:=[safe.position.x+safe.size.x*0.25,safe.get_center().x,safe.position.x+safe.size.x*0.75]
	var ys:=[safe.position.y+safe.size.y*0.25,safe.get_center().y,safe.position.y+safe.size.y*0.75]
	snap_x=INF;snap_y=INF
	for x in xs:
		if abs(proposed.x-float(x))<=threshold:
			desired.x+=float(x)-proposed.x;snap_x=float(x);break
	for y in ys:
		if abs(proposed.y-float(y))<=threshold:
			desired.y+=float(y)-proposed.y;snap_y=float(y);break
	return desired

func _update_overlap_warnings()->void:
	overlaps.clear()
	var ids:=buttons.keys()
	for i in range(ids.size()):
		for j in range(i+1,ids.size()):
			var a:=str(ids[i]);var b:=str(ids[j])
			if (buttons[a] as Rect2).intersects(buttons[b] as Rect2):
				overlaps.append("%s ↔ %s"%[LABELS[a],LABELS[b]])

func _draw()->void:
	draw_rect(get_rect(),Color(0.01,0.025,0.035,0.76))
	var font:=ThemeDB.fallback_font
	var live_safe:=_safe()
	draw_rect(live_safe,Color(0.12,0.30,0.32,0.06),true)
	draw_rect(live_safe,Color(0.45,0.90,0.95,0.55),false,1.5)
	var qa_button:=_control_rect("qa")
	draw_rect(qa_button,Color(0.05,0.12,0.15,0.95),true)
	draw_rect(qa_button,Color("d7a94f"),false,2)
	draw_string(font,qa_button.position+Vector2(6,25),"DEVICE PREVIEW",HORIZONTAL_ALIGNMENT_CENTER,qa_button.size.x-12,11,Color("ffd98a"))
	draw_string(font,Vector2(20,30),"HUD / UI ANPASSEN",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("ffd98a"))
	draw_string(font,Vector2(20,52),"Ziehen · auswählen · Größe/Sichtbarkeit unten · Profil: %s"%profile,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e9e8da"))
	_draw_device_preview(font)
	if snap_x<INF:draw_line(Vector2(snap_x,0),Vector2(snap_x,size.y),Color(0.45,0.9,0.95,0.55),1)
	if snap_y<INF:draw_line(Vector2(0,snap_y),Vector2(size.x,snap_y),Color(0.45,0.9,0.95,0.55),1)
	for id in buttons:
		var r:Rect2=buttons[id]
		var row:=store.row(profile,id) if store!=null else {"scale":1.0,"visible":true}
		var overlap:=false
		for pair in overlaps:
			if str(pair).contains(str(LABELS[id])):overlap=true;break
		var fill:=Color(0.16,0.07,0.06,0.80) if overlap else Color(0.05,0.16,0.2,0.72)
		if id==selected:fill=Color(0.12,0.24,0.22,0.90)
		draw_rect(r,fill,true)
		draw_rect(r,Color("ff9b75") if overlap else Color("d7a94f"),false,2)
		var state:="AUS" if not bool(row.visible) else "%d%%"%roundi(float(row.scale)*100.0)
		if bool(row.locked):state+=" · LOCK"
		draw_string(font,r.position+Vector2(7,20),"%s · %s"%[LABELS[id],state],HORIZONTAL_ALIGNMENT_LEFT,r.size.x-14,12,Color("ffd98a"))
	if not overlaps.is_empty():
		draw_string(font,Vector2(20,size.y-(136 if size.x<1180.0 else 88)),"ÜBERLAPPUNG: "+str(overlaps[0]),HORIZONTAL_ALIGNMENT_LEFT,minf(size.x-40,560),13,Color("ffb08e"))
	var live_layout:=NauticalLayout.calculate(_safe())
	if HudGestureSafety.near_edge(live_layout,"movement") or HudGestureSafety.near_edge(live_layout,"combat"):
		draw_string(font,Vector2(20,size.y-(152 if size.x<1180.0 else 104)),"SAFE AREA: kritische Touch-Steuerung nahe System-/Gestenrand",HORIZONTAL_ALIGNMENT_LEFT,minf(size.x-40,620),12,Color("ffcf7a"))
	for id in ["reset","reset_all","standard","combat","minimal","scale_down","scale_up","visibility","lock","done"]:
		var r:=_control_rect(id)
		var selected_locked:=not selected.is_empty() and bool(store.row(profile,selected).locked)
		var enabled:bool=id in ["reset","reset_all","standard","combat","minimal","done"] or (not selected.is_empty() and (id=="lock" or not selected_locked))
		draw_rect(r,Color(0.05,0.12,0.15,0.95) if enabled else Color(0.03,0.05,0.06,0.75),true)
		draw_rect(r,Color("d7a94f"),false,2)
		var labels={"reset":"RESET","reset_all":"RESET ALLE","standard":"STANDARD","combat":"COMBAT","minimal":"MINIMAL",
			"scale_down":"− GR.","scale_up":"+ GR.","visibility":"AN/AUS","lock":"LOCK","done":"FERTIG"}
		draw_string(font,r.position+Vector2(6,28),labels[id],HORIZONTAL_ALIGNMENT_CENTER,r.size.x-12,12,Color("ffd98a") if enabled else Color("75694f"))


func _draw_device_preview(font:Font)->void:
	if not qa_enabled:return
	var row:=HudLayoutQaProfiles.profile(qa_index)
	if row.is_empty():return
	var size_data:Array=row.get("size",[1280,720])
	var safe_data:Array=row.get("safe",[0,0,1280,720])
	var source_size:=Vector2(float(size_data[0]),float(size_data[1]))
	var preview_w:=minf(310.0,size.x*0.30)
	var preview_h:=preview_w*source_size.y/maxf(1.0,source_size.x)
	var outer:=Rect2(Vector2(size.x-preview_w-18,18),Vector2(preview_w,preview_h))
	draw_rect(outer,Color(0.01,0.05,0.07,0.94),true)
	draw_rect(outer,Color("d7a94f"),false,2)
	var scale:=preview_w/source_size.x
	var safe:=Rect2(
		outer.position+Vector2(float(safe_data[0]),float(safe_data[1]))*scale,
		Vector2(float(safe_data[2]),float(safe_data[3]))*scale)
	draw_rect(safe,Color(0.15,0.40,0.42,0.15),true)
	draw_rect(safe,Color(0.45,0.90,0.95,0.70),false,1)
	# notch/unsafe region remains visibly outside the cyan safe rectangle
	draw_string(font,outer.position+Vector2(8,16),str(row.get("label","Device")),HORIZONTAL_ALIGNMENT_LEFT,outer.size.x-16,11,Color("ffd98a"))
	var simulated:=NauticalLayout.calculate(Rect2(Vector2.ZERO,Vector2(float(safe_data[2]),float(safe_data[3]))))
	var critical={
		"movement":["wheel","zoom_in","zoom_out","recenter","auto_fire"],
		"combat":["fire","repair","boost","target","ammo_menu","items_menu"],
		"minimap":["minimap","world","group"]
	}
	var colors={"movement":Color(0.35,0.75,0.95,0.55),"combat":Color(0.95,0.40,0.25,0.55),"minimap":Color(0.85,0.70,0.25,0.55)}
	for group_id in critical:
		for id in critical[group_id]:
			var r:Rect2=simulated.actions.get(id,simulated.get(id,Rect2()))
			if not r.has_area():continue
			var rr:=Rect2(safe.position+r.position*scale,r.size*scale)
			draw_rect(rr,colors[group_id],false,1)

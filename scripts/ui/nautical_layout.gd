class_name NauticalLayout
extends RefCounted
## M198 visual-master HUD lock: world-first edge HUD + shared hit testing.
## No persistent bottom command/map-selection bar and no centered primary attack button.
## Mobile/Desktop share the same HUD hierarchy; only responsive size/spacing/safe-area presentation changes.

static func calculate(safe: Rect2) -> Dictionary:
	var w := safe.size.x
	var h := safe.size.y
	var portrait := w < 600
	var dpi := float(DisplayServer.screen_get_dpi())
	var device_profile:=InputDeviceProfile.detect(Vector2(w,h),dpi)
	var touch_density := bool(device_profile.get("touch_like",false))
	var compact := bool(device_profile.get("compact",false)) or touch_density
	var hud_profile:=str(device_profile.get("hud_profile","desktop_wide"))
	# M34: 720p-fixed geometry was physically too small on modern 1080p+ phones.
	var ui_scale := clampf(minf(w / 1280.0, h / 720.0), 1.0, 1.55)
	if not touch_density and w >= 1800.0 and h >= 1000.0:
		ui_scale=maxf(ui_scale,clampf(minf(w/1920.0,h/1080.0)*1.12,1.12,1.45))
	# M38: physical-density pass. High-resolution phones must not render a desktop-sized
	# 720p HUD at tiny physical dimensions. Desktop monitors normally report ~96-140 DPI,
	# while Android/iOS devices report a much higher density.
	if touch_density:
		ui_scale = maxf(ui_scale, clampf(dpi / 210.0, 1.15, 1.70))
	if portrait:
		ui_scale = maxf(ui_scale, clampf(h / 720.0, 1.0, 1.45))
	var sx := ui_scale
	var top := (116.0 if portrait else (88.0 if compact else 96.0)) * sx
	var p := safe.position
	var actions := {}
	# M180: physical mobile width, not raw high-DPI pixels, decides navigation density.
	# Secondary destinations remain available through MENU instead of crowding the top bar.
	var mobile_nav := ["nav_map", "shipyard", "nav_log", "arsenal", "home"] if w / sx >= 1000.0 else ["shipyard", "arsenal", "home"]
	var nav := mobile_nav if touch_density or w / sx < 1450.0 else ["shipyard", "arsenal", "events", "quests", "shop", "home"]
	var nw := (62.0 if compact else 66.0) * sx
	for index in nav.size():
		actions[nav[index]] = Rect2(p + Vector2(w - 10.0 * sx - (nav.size() - index) * (nw + 6.0 * sx), 8.0 * sx), Vector2(nw, (70.0 if compact else 76.0) * sx))
	var map_radius := (54.0 if compact else 76.0) * sx
	# M221: master-reference minimap is a stronger upper-right world-navigation anchor.
	actions["minimap"] = Rect2(p + Vector2(w - map_radius * 2.0 - 14.0 * sx, top + 15.0 * sx), Vector2.ONE * map_radius * 2.0)
	var utility_radius := (25.0 if compact else 30.0) * sx
	for item in [["world", Vector2(-map_radius * 2.0 - utility_radius * 2.0 - 24.0 * sx, top + 18.0 * sx)], ["group", Vector2(-map_radius * 2.0 - utility_radius * 2.0 - 24.0 * sx, top + 18.0 * sx + utility_radius * 2.0 + 10.0 * sx)]]:
		var point: Vector2 = p + Vector2(w, 0) + item[1] + Vector2.ONE * utility_radius
		actions[item[0]] = Rect2(point - Vector2.ONE * utility_radius, Vector2.ONE * utility_radius * 2.0)
	# M198: primary attack remains a large lower-right combat anchor on every platform.
	var fire_radius := (50.0 if compact else 68.0) * sx
	var center := p + Vector2(w - fire_radius - 18.0 * sx, h - fire_radius - 22.0 * sx)
	actions["fire"] = Rect2(center - Vector2.ONE * fire_radius, Vector2.ONE * fire_radius * 2.0)
	# M38 combat comfort: large current-ammo and item selectors. These open full pickers;
	# the three legacy quick-ammo circles remain available as optional shortcuts.
	var picker_radius := (36.0 if compact else 45.0) * sx
	var ammo_picker_center := center + Vector2(-fire_radius - picker_radius - 22.0 * sx, 4.0 * sx)
	var items_picker_center := ammo_picker_center + Vector2(-picker_radius * 2.0 - 14.0 * sx, 0)
	actions["ammo_menu"] = Rect2(ammo_picker_center - Vector2.ONE * picker_radius, Vector2.ONE * picker_radius * 2.0)
	actions["items_menu"] = Rect2(items_picker_center - Vector2.ONE * picker_radius, Vector2.ONE * picker_radius * 2.0)
	# M44: four large, actionable per-ship quickslots. Assignment is done from
	# the long-press/right-click detail view; the slots only execute saved bindings.
	var quick_size := (43.0 if compact else 48.0) * sx
	var quick_gap := 8.0 * sx
	var quick_total := quick_size * 4.0 + quick_gap * 3.0
	var quick_x := items_picker_center.x - picker_radius - quick_total - 12.0 * sx if compact else center.x - quick_total - fire_radius - 26.0 * sx
	quick_x = clampf(quick_x, p.x + 310.0 * sx, p.x + w - quick_total - 230.0 * sx)
	var quick_y := p.y + h - quick_size - 18.0 * sx
	for i in 4:
		actions["quick_%d" % i] = Rect2(Vector2(quick_x + i * (quick_size + quick_gap), quick_y), Vector2.ONE * quick_size)
	var small := (28.0 if compact else 39.0) * sx
	if compact:
		var upper_gap := 12.0 * sx
		var repair_center := ammo_picker_center + Vector2(0, -picker_radius - small - upper_gap)
		var boost_center := items_picker_center + Vector2(0, -picker_radius - small - upper_gap)
		var target_center := center + Vector2(0, -fire_radius - small - upper_gap)
		for item in [["repair", repair_center], ["boost", boost_center], ["target", target_center]]:
			actions[item[0]] = Rect2(item[1] - Vector2.ONE * small, Vector2.ONE * small * 2.0)
	else:
		for item in [["repair", Vector2(-fire_radius - small - 16.0 * sx, -6.0 * sx)], ["boost", Vector2(-small * 2.0 - 16.0 * sx, -fire_radius - small - 16.0 * sx)], ["target", Vector2(0, -fire_radius - small - 16.0 * sx)]]:
			var point: Vector2 = center + item[1]
			actions[item[0]] = Rect2(point - Vector2.ONE * small, Vector2.ONE * small * 2.0)
	var ammo_radius := (27.0 if compact else 33.0) * sx
	var ammo_y := h - (320.0 * sx if portrait else ammo_radius + 20.0 * sx)
	for i in 3:
		if touch_density:
			actions["ammo_%d" % i] = Rect2()
		else:
			var point := p + Vector2(w * 0.5 + (i - 1) * (ammo_radius * 2.0 + 14.0 * sx), ammo_y)
			actions["ammo_%d" % i] = Rect2(point - Vector2.ONE * ammo_radius, Vector2.ONE * ammo_radius * 2.0)
	var mission := Rect2(p + Vector2(10.0 * sx, top + 56.0 * sx), Vector2(minf(250.0 * sx, w * 0.53), (68.0 if compact else 110.0) * sx))
	# M75: reserve a dedicated center-top lane for temporary beginner objectives.
	var objective_width:=minf((300.0 if compact else 390.0)*sx,w*0.52)
	var objective_strip:=Rect2(Vector2(p.x+w*0.5-objective_width*0.5,p.y+top+(8.0 if compact else 14.0)*sx),
		Vector2(objective_width,(48.0 if compact else 62.0)*sx))
	if objective_strip.intersects(mission):
		objective_strip.position.y=mission.end.y+6.0*sx
	var zoom_y := p.y + h - 60.0 * sx
	for i in 2:
		actions["zoom_in" if i == 0 else "zoom_out"] = Rect2(Vector2(p.x + (128.0 + i * 54.0) * sx, zoom_y), Vector2(48, 48) * sx)
	actions["recenter"] = Rect2(p + Vector2(236.0 * sx, h - 60.0 * sx), Vector2(58, 48) * sx)
	actions["auto_fire"] = Rect2(p + Vector2(18.0 * sx, h - 166.0 * sx), Vector2(72, 48) * sx)
	var target_info := Rect2(p + Vector2(w * 0.5 - 114.0 * sx, top + 8.0 * sx), Vector2(228, 42) * sx)
	var wheel := Rect2(p + Vector2(18.0 * sx, h - 108.0 * sx), Vector2.ONE * 96.0 * sx)
	if portrait:
		actions.zoom_in = Rect2(p + Vector2(12.0 * sx, h - 228.0 * sx), Vector2(48, 48) * sx)
		actions.zoom_out = Rect2(p + Vector2(66.0 * sx, h - 228.0 * sx), Vector2(48, 48) * sx)
		actions.recenter = Rect2(p + Vector2(18.0 * sx, h - 288.0 * sx), Vector2(96, 48) * sx)
		target_info = Rect2(p + Vector2(10.0 * sx, top + 132.0 * sx), Vector2(w - 20.0 * sx, 34.0 * sx))
	var log := Rect2(p + Vector2(10.0 * sx, h - (132.0 if compact else 178.0) * sx), Vector2(minf(396.0 * sx, w * 0.37), (120.0 if compact else 164.0) * sx))
	if portrait:
		log = Rect2(p + Vector2(12.0 * sx, top + 126.0 * sx), Vector2(minf(340.0 * sx, w - 24.0 * sx), 112.0 * sx))
	# M70 mobile closure: interactive touch targets never fall below the physical comfort floor.
	# Visuals can remain smaller inside these hit boxes; only interaction geometry expands.
	if touch_density:
		var min_touch := 56.0 * maxf(1.0, minf(sx, 1.35))
		for action_id in actions.keys():
			var rect: Rect2 = actions[action_id]
			if not rect.has_area(): continue
			var target_size := Vector2(maxf(rect.size.x, min_touch), maxf(rect.size.y, min_touch))
			actions[action_id] = Rect2(rect.get_center() - target_size * 0.5, target_size)
	var result:={"safe": safe, "compact": compact, "portrait": portrait, "touch_density": touch_density, "ui_scale": ui_scale,
		"hud_profile":hud_profile,"input_mode":str(device_profile.get("input_mode","mouse_keyboard")),
		"top": Rect2(p, Vector2(w, top)), "actions": actions,
		"mission": mission, "objective_strip": objective_strip, "wheel": wheel, "log": log, "target_info": target_info,
		"currency": Rect2(p + Vector2(10.0 * sx, top + 7.0 * sx), Vector2(minf(396.0 * sx, w * 0.58), 42.0 * sx))}
	var defaults:=result.duplicate(true)
	var customized:=apply_player_layout(result)
	customized=enforce_custom_safety(customized,defaults)
	customized=enforce_runtime_non_overlap(customized,defaults)
	return HudGestureSafety.clamp_critical(customized)

static var player_offsets:Dictionary={}
static var player_profile:=""

static func set_player_offsets(profile:String,offsets:Dictionary)->void:
	player_profile=profile
	player_offsets=offsets.duplicate(true)

static func clear_player_offsets()->void:
	player_profile=""
	player_offsets.clear()

static func _transform_rect(rect:Rect2,delta:Vector2,scale_value:float,visible:bool,safe:Rect2)->Rect2:
	if not rect.has_area() or not visible:return Rect2()
	var size:=rect.size*clampf(scale_value,0.80,1.35)
	var shifted:=Rect2(rect.get_center()+delta-size*0.5,size)
	var margin:=8.0
	shifted.position.x=clampf(shifted.position.x,safe.position.x+margin,maxf(safe.position.x+margin,safe.end.x-shifted.size.x-margin))
	shifted.position.y=clampf(shifted.position.y,safe.position.y+margin,maxf(safe.position.y+margin,safe.end.y-shifted.size.y-margin))
	return shifted

static func apply_player_layout(layout:Dictionary)->Dictionary:
	var profile:=str(layout.get("hud_profile","desktop_wide"))
	if player_profile!=profile or player_offsets.is_empty():return layout
	var safe:Rect2=layout.safe
	var groups={
		"profile_status":["top"],"mission":["mission"],"objective":["objective_strip"],
		"minimap":["minimap","world","group"],"movement":["wheel","zoom_in","zoom_out","recenter","auto_fire"],
		"combat":["fire","repair","boost","target","ammo_menu","items_menu"],
		"quickbar":["quick_0","quick_1","quick_2","quick_3"],"target":["target_info"],"currency":["currency"]
	}
	for group_id in groups:
		var row:Variant=player_offsets.get(group_id,{})
		if not row is Dictionary:continue
		var delta:=Vector2(float(row.get("x",0.0))*safe.size.x,float(row.get("y",0.0))*safe.size.y)
		var group_scale:=clampf(float(row.get("scale",1.0)),0.80,1.35)
		var visible:=bool(row.get("visible",true))
		if group_id not in ["mission","objective","minimap","quickbar","target","currency"]:
			visible=true
		for id in groups[group_id]:
			if layout.actions.has(id):
				layout.actions[id]=_transform_rect(layout.actions[id],delta,group_scale,visible,safe)
			elif layout.has(id):
				layout[id]=_transform_rect(layout[id],delta,group_scale,visible,safe)
	return layout

static func _group_bounds(layout:Dictionary,ids:Array[String])->Rect2:
	var result:=Rect2()
	var first:=true
	for id in ids:
		var r:Rect2=layout.actions.get(id,layout.get(id,Rect2()))
		if not r.has_area():continue
		result=r if first else result.merge(r)
		first=false
	return result

static func _restore_group(layout:Dictionary,defaults:Dictionary,ids:Array[String])->void:
	for id in ids:
		if layout.actions.has(id) and defaults.actions.has(id):
			layout.actions[id]=defaults.actions[id]
		elif layout.has(id) and defaults.has(id):
			layout[id]=defaults[id]

static func enforce_custom_safety(layout:Dictionary,defaults:Dictionary)->Dictionary:
	if not bool(layout.get("compact",false)):return layout
	var movement:Array[String]=["wheel","zoom_in","zoom_out","recenter","auto_fire"]
	var combat:Array[String]=["fire","repair","boost","target","ammo_menu","items_menu"]
	var move_box:=_group_bounds(layout,movement)
	var combat_box:=_group_bounds(layout,combat)
	# Critical input groups are never allowed to collapse into one another on compact touch layouts.
	if move_box.has_area() and combat_box.has_area() and move_box.grow(6.0).intersects(combat_box.grow(6.0)):
		_restore_group(layout,defaults,movement)
		move_box=_group_bounds(layout,movement)
		if move_box.grow(6.0).intersects(combat_box.grow(6.0)):
			_restore_group(layout,defaults,combat)
	# Critical touch actions keep their physical minimum even after custom scaling.
	if bool(layout.get("touch_density",false)):
		var sx:=float(layout.get("ui_scale",1.0))
		var min_touch:=56.0*maxf(1.0,minf(sx,1.35))
		for id in combat+["zoom_in","zoom_out","recenter","auto_fire"]:
			if not layout.actions.has(id):continue
			var r:Rect2=layout.actions[id]
			if not r.has_area():continue
			if r.size.x<min_touch or r.size.y<min_touch:
				var size:=Vector2(maxf(r.size.x,min_touch),maxf(r.size.y,min_touch))
				layout.actions[id]=_transform_rect(Rect2(r.get_center()-size*0.5,size),Vector2.ZERO,1.0,true,layout.safe)
	return layout

static func enforce_runtime_non_overlap(layout:Dictionary,defaults:Dictionary)->Dictionary:
	if not bool(layout.get("compact",false)):return layout
	var ids:Array[String]=["fire","ammo_menu","items_menu","repair","boost","target","quick_0","quick_1","quick_2","quick_3"]
	for i in ids.size():
		var a:Rect2=layout.actions.get(ids[i],Rect2())
		if not a.has_area():continue
		for j in range(i+1,ids.size()):
			var b:Rect2=layout.actions.get(ids[j],Rect2())
			if b.has_area() and a.grow(3.0).intersects(b.grow(3.0)):
				_restore_group(layout,defaults,ids)
				return layout
	return layout

static func circular(id: String) -> bool:
	return id in ["fire", "repair", "boost", "target", "minimap", "world", "group", "ammo_menu", "items_menu"] or id.begins_with("ammo_")

static func action_at(point: Vector2, layout: Dictionary) -> String:
	for id in layout.actions:
		var box: Rect2 = layout.actions[id]
		if circular(id):
			if point.distance_to(box.get_center()) <= box.size.x * 0.5: return id
		elif box.has_point(point): return id
	return ""

static func blocks_world(point: Vector2, layout: Dictionary, log_visible := false) -> bool:
	for id in ["top", "mission", "objective_strip", "currency", "wheel", "target_info"]:
		if (layout[id] as Rect2).has_point(point): return true
	return not action_at(point, layout).is_empty() or (log_visible and (layout.log as Rect2).has_point(point))

static func reserved(layout: Dictionary, log_visible := false) -> Array[Rect2]:
	var result:Array[Rect2]=[]
	for rect:Rect2 in [layout.top,layout.mission,layout.objective_strip,layout.currency,layout.wheel,layout.target_info]:
		if rect.has_area():result.append(rect)
	for rect: Rect2 in layout.actions.values():
		if rect.has_area():result.append(rect)
	if log_visible and (layout.log as Rect2).has_area():result.append(layout.log)
	return result

static func nameplate_box(bounds: Rect2, extent: Vector2, safe: Rect2, occupied: Array[Rect2], player: bool) -> Rect2:
	var above := Vector2(bounds.get_center().x - extent.x * 0.5, bounds.position.y - extent.y - 10)
	var below := Vector2(bounds.get_center().x - extent.x * 0.5, bounds.end.y + 10)
	var side_y := bounds.get_center().y - extent.y * 0.5
	var candidates := [below, above] if player else [above, below]
	candidates.append(Vector2(bounds.position.x - extent.x - 10, side_y)); candidates.append(Vector2(bounds.end.x + 10, side_y))
	for point in candidates:
		var box := Rect2(point, extent)
		if not safe.encloses(box): continue
		var blocked := false
		for other in occupied:
			if box.grow(2).intersects(other): blocked = true; break
		if not blocked: return box
	return Rect2()

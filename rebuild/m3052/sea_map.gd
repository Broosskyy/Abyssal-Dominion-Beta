extends Node2D
const SIM = preload("res://simulation.gd")
const MINI = preload("res://minimap.gd")
const HUD=preload("res://nautical_button.gd")
const HUD_PANEL=preload("res://nautical_panel.gd")
const CAMERA_PAD=preload("res://camera_pad.gd")
const RULER=preload("res://grid_ruler.gd")
const LOADING=preload("res://loading_screen.gd")
const CONTENT = preload("res://content.gd")
const VISUALS = preload("res://ship_visuals.gd")
const USER_ROOT := "res://assets/user/"
const SAVE := "user://captain_m3052.json"
const HUD_SAVE := "user://display_m3052.json"
const GOLD := Color("dcc18a")
const CYAN := Color("80e3dc")
const ROMAN := ["","I","II","III","IV","V","VI","VII","VIII","IX","X"]
var sim := SIM.new()
var camera: Camera2D
var water: ColorRect
var ocean: ShaderMaterial
var ui: Control
var chart_mini: Control
var desired_zoom := 0.96
var pan := Vector2.ZERO
var camera_anchor := Vector2.ZERO
var camera_locked := true
var accumulator := 0.0
var refresh_clock := 0.0
var save_clock := 0.0
var elapsed := 0.0
var skins: Array[Dictionary] = []
var ship_textures: Array[Texture2D] = []
var skin_previews: Array[Texture2D] = []
var atlas_textures: Array[Texture2D] = []
var island_textures: Dictionary = {}
var icons: Dictionary = {}
var beast: Texture2D
var font: Font = ThemeDB.fallback_font
var chrome: Panel
var gold_label: Label
var kills_label: Label
var wallet_icons: Array[TextureRect]=[]
var meter_tags: Array[Label]=[]
var xp_numbers: Label
var player_hp: ProgressBar
var player_numbers: Label
var target_panel: Panel
var target_name: Label
var target_hp: ProgressBar
var target_numbers: Label
var status: Label
var attack: Button
var repair: Button
var center_button: Button
var zoom_in: Button
var zoom_out: Button
var ammo_buttons: Array[Button] = []
var nav_buttons: Array[Button] = []
var quest_panel: Panel
var quest_text: Label
var quest_claim: Button
var modal: Panel
var modal_title: Label
var modal_close: Button
var modal_scroll: ScrollContainer
var modal_body: VBoxContainer
var modal_kind := ""
var drag_start := Vector2.ZERO
var dragging := false
var last_mouse := Vector2.ZERO
var touch_points: Dictionary = {}
var hud_touches: Dictionary = {}
var pinch_distance := 0.0
var suppress_tap_until := 0
var drawn_shots := 0
var last_touch_ms := -10000
var interact: Button
var player_xp: ProgressBar
var extra_icons: Dictionary = {}
var modal_backdrop: ColorRect
var modal_skin: StyleBoxTexture
var modal_compact_skin: StyleBoxFlat
var ship_frames: Dictionary = {}
var starter_texture: Texture2D
var starter_damaged_texture: Texture2D
var facing_cache: Dictionary = {}
var direction_cache: Dictionary = {}
var gallery_page := -1
var loadout_button: Button
var target_portrait: TextureRect
var portrait_target := -1
var target_health_skin: StyleBoxFlat
var hud_icons: Dictionary={}
var painted: Dictionary={}
var ammo_selector: Button
var settings_button: Button
var quest_open: Button
var quest_icon: TextureRect
var ruler: Control
var loading: Control
var loading_left := 0.0
var loading_total := 1.0
var message_history: Array[String]=[]
var player_shield: ProgressBar
var shield_numbers: Label
var supply_buttons: Dictionary={}
var page_button: Button
var quick_page := 0
var buff_bar: Control
var kessel_log: Array[String]=[]
var guild_name_input: LineEdit
var guild_tag_input: LineEdit
var previous_region := -1
var hud_size := 1 # 0 compact, 1 comfortable, 2 large
var journal_visible := true
var hud_scale := 1.0
var camera_pad: Control
var target_cycle: Button
var camera_pad_visible := true

func _ready() -> void:
	_load_assets()
	_load_progress()
	_load_display()
	previous_region=sim.map_id
	camera = Camera2D.new()
	camera.position = sim.player.pos
	camera.zoom = Vector2.ONE*desired_zoom
	add_child(camera)
	var backdrop = CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	water = ColorRect.new()
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(water)
	ocean = ShaderMaterial.new()
	ocean.shader = preload("res://ocean.gdshader")
	ocean.set_shader_parameter("wave_noise",load("res://assets/reference/ocean/wave_noise.png"))
	ocean.set_shader_parameter("sea_tile",load("res://assets/ui/painted/sea_tile.png"))
	water.material = ocean
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_ui()
	# Test harnesses attach the scene before claiming it; only a real scene change shows the boot curtain.
	if get_tree().current_scene==self:_begin_loading(1.4)
	var data_boot=get_tree().root.get_node_or_null("DataBoot")
	if data_boot!=null:data_boot.mark_healthy()

func _load_assets() -> void:
	for name in ["anchor","ship","book","compass","chest","gear","plus","minus","focus","arrow","target_cycle"]:hud_icons[name]=load("res://assets/ui/icons/"+name+".svg")
	extra_icons.port_watchtower=load("res://assets/reference/landmarks/port_watchtower.png")
	ship_frames=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visuals/ship_frames.json")).entries
	var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(USER_ROOT+"pack.json"))
	for item: Dictionary in pack.ship_catalog:
		skins.append(item)
		ship_textures.append(load(USER_ROOT+str(item.path)))
		skin_previews.append(_ship_preview(ship_textures.back(),0))
	for name in ["redkorsar","elite2","elite3","elite4","elite5","elite6","elite7","elite9","elite10","boneship","burningdutchman1","blackbeardspirates"]:
		atlas_textures.append(load("res://assets/fleet/"+str(name)+".png"))
	for name in ["elite8","warship","pinnace","flyingdutchman"]:
		atlas_textures.append(load("res://assets/reference/ships/"+str(name)+".png"))
	var hull_names = ["Roter Korsar","Jadebrigg","Kupfersegler","Küstenfregatte","Goldene Armada","Eisfregatte","Schattensegler","Admiralswache","Elite-Galeone","Knochenschiff","Brennender Holländer","Schwarzbart","Königsgaleone","Kriegsschiff","Schmuggler","Fliegender Holländer"]
	for i in atlas_textures.size():
		skins.append({"name":hull_names[i],"directional":true,"atlas":i})
		skin_previews.append(_ship_preview(atlas_textures[i],0))
	starter_texture=load("res://assets/generated/ships/starter_small_8_intact.png")
	starter_damaged_texture=load("res://assets/generated/ships/starter_small_8_damaged.png")
	skins.append({"name":"Küstenschaluppe","asset_id":"SHIP-STARTER-001","views":8})
	skin_previews.append(_ship_preview(starter_texture,5))
	for name in ["tropical","rock","snow","snow2"]:
		island_textures[name] = load("res://assets/reference/islands/"+name+".png")
	for name in ["cannonball","harpoon","chain","repair_chest","portal"]:
		icons[name] = load(USER_ROOT+"ui/"+name+".png")
	beast = load("res://assets/reference/monsters/tiamat.png")
	for name in ["cannon_0","cannon_1","cannon_2","harpoon_0","harpoon_1","harpoon_2","loot_0","loot_1","loot_2","loot_3","upgrade_cannon","upgrade_harpoon","upgrade_hull","upgrade_sails","quest_book","world_chart"]:
		extra_icons[name] = load("res://assets/expanded/"+name+".png")
	extra_icons.cannon_action=load("res://assets/ui/cannon_action.png")
	for name in ["nav_ship","nav_shipyard","nav_harbor","nav_quests","nav_charts","nav_supplies","nav_ranking","nav_menu","gold_coins","kills_skull","spyglass","helm_wheel",
			"nav_bonus","nav_kessel","nav_guild","nav_castles","supply_powder","supply_plates","supply_repair","supply_shield","essence_flask","scroll_fragment",
			"crystal_blessing","tide_deck","castle_crew","castle_war","boss_wave","reward_chest","tower_cannon","tower_mortar","tower_chain","tower_guardian"]:
		painted[name]=load("res://assets/ui/painted/"+name+".png")
	painted.loading=load("res://assets/ui/painted/loading_harbor.jpg")
	painted.kessel_scene=load("res://assets/ui/painted/kessel_scene.jpg")

func _art(name: String) -> Texture2D:
	return extra_icons[name] if extra_icons.has(name) else painted.get(name)

func _process(delta: float) -> void:
	if modal_backdrop!=null:modal_backdrop.visible=modal.visible
	if gallery_page>=0:
		queue_redraw()
		return
	elapsed += delta
	accumulator = minf(accumulator+delta,0.2)
	while accumulator >= 1.0/30.0:
		sim.step(1.0/30.0)
		accumulator -= 1.0/30.0
	if previous_region!=sim.map_id:_sync_region()
	if loading_left>0:_advance_loading(delta)
	if camera_pad.visible and not modal.visible:_pan_camera(camera_pad.value,delta)
	var goal: Vector2 = sim.player.pos if camera_locked else camera_anchor
	pan=goal-sim.player.pos
	camera.position = camera.position.lerp(goal,1.0-exp(-delta*5.0))
	camera.zoom = camera.zoom.lerp(Vector2.ONE*desired_zoom,1.0-exp(-delta*8.0))
	ocean.set_shader_parameter("camera_world",camera.position)
	ocean.set_shader_parameter("map_zoom",camera.zoom.x)
	ocean.set_shader_parameter("viewport_size",get_viewport_rect().size)
	ocean.set_shader_parameter("region_tint",CONTENT.MAPS[sim.map_id].tint)
	chart_mini.camera_world = camera.position
	chart_mini.view_world = get_viewport_rect().size/camera.zoom
	chart_mini.queue_redraw()
	_sync_ruler()
	refresh_clock += delta
	if refresh_clock > 0.12:
		refresh_clock = 0
		_refresh_ui()
	save_clock += delta
	if save_clock > 8.0:
		save_clock = 0
		_save_progress()
	queue_redraw()

func _draw() -> void:
	if camera == null: return
	if gallery_page>=0:
		_draw_ship_gallery()
		return
	var view = Rect2(camera.position-get_viewport_rect().size/camera.zoom*0.5,get_viewport_rect().size/camera.zoom).grow(350)
	# Projected art is drawn on the same 2D chart as movement and collision.
	for island in sim.islands:
		if not view.has_point(island.pos): continue
		var tex: Texture2D = island_textures[island.art]
		var width: float = island.width
		var dimensions = tex.get_size()*width/tex.get_width()
		var point: Vector2 = island.pos
		draw_texture_rect(tex,Rect2(point-dimensions*Vector2(0.5,0.65),dimensions),false)
		if island.pos==sim.islands[0].pos:
			var tower: Texture2D=extra_icons.port_watchtower
			var tower_size=tower.get_size()*42.0/tower.get_width()
			var foundation: Vector2=island.bounds.get_center()+Vector2(10,24)
			draw_texture_rect(tower,Rect2(foundation-tower_size*Vector2(0.5,0.96),tower_size),false)
		_label(Vector2(point.x,island.bounds.end.y+26),island.name,16,GOLD)
	# Planned route and tap marker remain visible without obscuring the sea.
	# Docks and portals occupy water cells and are also marked on the minimap.
	# Compact anchor replaces the oversized dock circle and upgrade-arrow placeholder.
	if sim.has_harbor() and _landmark_label_visible(sim.harbor):
		var anchor=sim.harbor
		draw_circle(anchor-Vector2(0,23),6,GOLD,false,2.0,true)
		draw_line(anchor-Vector2(0,17),anchor+Vector2(0,17),GOLD,2.5,true)
		draw_line(anchor-Vector2(13,7),anchor+Vector2(13,-7),GOLD,2.0,true)
		draw_arc(anchor+Vector2(0,1),23,0,PI,24,GOLD,2.5,true)
		_label(sim.harbor+Vector2(0,100),"HAFEN · ANDOCKEN",13,GOLD)
	for sparkle in sim.sparkles:
		if float(sparkle.respawn)>0 or not view.has_point(sparkle.pos):continue
		_draw_sparkle(sparkle.pos,float(sparkle.id))
	for portal in sim.portals:
		if not view.has_point(portal.pos): continue
		var pp: Vector2 = portal.pos
		var region: Dictionary = CONTENT.MAPS[int(portal.destination)]
		_draw_portal_marker(pp,int(region.level)>sim.level)
		if _landmark_label_visible(pp):
			var locked=int(region.level)>sim.level
			_label(pp+Vector2(0,100),"%s · AB LV. %d" % [region.name,region.level] if locked else str(region.name)+" · PORTAL",14,GOLD if locked else CYAN)
			if not locked:_label(pp+Vector2(0,119),"Antippen: automatische Überfahrt",11,CYAN)
	if not sim.player.path.is_empty():
		var before: Vector2 = sim.player.pos
		for point: Vector2 in sim.player.path:
			draw_dashed_line(before,point,Color(0.50,0.83,0.80,0.35),1.4,10.0)
			before = point
		var goal: Vector2 = sim.player.path.back()
		draw_arc(goal,16+sin(elapsed*3)*2,0,TAU,32,Color(0.54,0.92,0.85,0.7),1.7,true)
		draw_line(goal-Vector2(22,0),goal+Vector2(22,0),Color(0.5,0.9,0.84,0.5),1.0)
		draw_line(goal-Vector2(0,16),goal+Vector2(0,16),Color(0.5,0.9,0.84,0.5),1.0)
	for drop in sim.drops:
		if not view.has_point(drop.pos): continue
		var p: Vector2 = drop.pos+Vector2(0,sin(elapsed*2+drop.id)*3)
		_ellipse(p,Vector2(31,13),Color(0.95,0.7,0.2,0.1))
		var tex: Texture2D = extra_icons["loot_%d" % int(drop.get("art",0))]
		var dims = tex.get_size()*49.0/maxf(tex.get_width(),tex.get_height())
		draw_texture_rect(tex,Rect2(p-dims*0.5,dims),false)
		_label(p+Vector2(0,31),"BEUTE",10,GOLD)
	var fleet: Array[Dictionary] = []
	fleet.append(sim.player)
	for npc in sim.npcs:
		if view.has_point(npc.pos): fleet.append(npc)
	fleet.sort_custom(func(a,b):return a.pos.y < b.pos.y)
	for actor: Dictionary in fleet:
		if int(actor.hp)>0: _draw_actor(actor)
	for actor: Dictionary in fleet:
		if int(actor.hp)>0 and actor.get("kind","")=="tower":_nameplate(actor,actor.pos+Vector2(0,-96.0*_plate_scale() if sim.target==int(actor.id) else 16.0))
	drawn_shots = 0
	for shot in sim.shots:
		if float(shot.age)<0: continue
		drawn_shots += 1
		var progress = clampf(float(shot.traveled)/float(shot.distance),0,1)
		var mortar=shot.weapon=="mortar"
		var p: Vector2 = shot.pos-Vector2(0,sin(progress*PI)*(110.0 if mortar else 28.0))
		var victim = sim.actor(int(shot.target))
		if victim.is_empty(): continue
		var direction: Vector2=(victim.pos-shot.pos).normalized()
		var color = Color("ffe0a2") if int(shot.source)==0 else Color("ff8c56")
		if mortar:_ellipse(shot.pos,Vector2(7,3),Color(0,0,0,.28))
		draw_line(p-direction*18,p,color,2.4,true)
		draw_circle(p,(7.0 if mortar else 4.2),Color(0,0,0,0.5))
		draw_circle(p,(5.0 if mortar else 2.7),color)
		if shot.weapon=="chain": draw_arc(p,6,0,TAU,12,color,1.2,true)
		if shot.weapon=="harpoon": draw_line(p-direction*30,p,color,1.4,true)
	for event in sim.events:
		var age: float = sim.clock-float(event.time)
		if age>1.2: continue
		var p: Vector2 = event.pos
		if event.type=="impact":
			var fade = maxf(0,1-age/0.6)
			_ellipse_line(p,Vector2(12+age*45,8+age*22),Color(0.95,0.84,0.60,fade),2.3)
		elif event.type=="muzzle" and age<0.35:
			draw_circle(p,8+age*18,Color(1,0.73,0.3,(1-age/0.35)*0.65))
		elif event.type=="sunk":
			_ellipse(p,Vector2(70*age+5,36*age+5),Color(0.38,0.55,0.56,(1-age/1.2)*0.4))
		elif event.type=="loot":
			_label(p+Vector2(0,-30-age*45),"+%d GOLD"%int(event.value),19,Color(0.95,0.81,0.4,1-age/1.2))
		elif event.type=="level":
			_ellipse_line(p,Vector2(50+age*80,22+age*35),Color(0.5,0.9,1,1-age/1.2),2.2)
			_label(p+Vector2(0,-100-age*25),"KAPITÄNSSTUFE %d" % int(event.value),22,CYAN)
		elif event.type=="essence":
			_label(p+Vector2(0,-48-age*40),"+%d ESSENZ"%int(event.value),17,Color(0.45,1,0.92,1-age/1.2))
		elif event.type in ["blessing","tide_deck","supply"]:
			var tint=Color("c69bff") if event.type=="blessing" else (Color("5fe0d2") if event.type=="tide_deck" else Color("8fd0ff"))
			_ellipse_line(p,Vector2(40+age*90,16+age*36),Color(tint,1-age/1.2),2.6)
		elif event.type=="conquest":
			_label(p+Vector2(0,-120-age*20),"FESTUNG EROBERT",24,Color(1,0.85,0.45,1-age/1.2))

	for group: Dictionary in VISUALS.impact_labels(sim.events,sim.clock):
		var age=sim.clock-float(group.time)
		_label(group.pos+Vector2(0,-65-age*33-float(group.lane)*26),"−%d"%int(group.value),19,Color(1,0.65,0.33,1-age/1.2))

func _landmark_label_visible(point: Vector2) -> bool:
	var bodies: Array=[sim.player]
	bodies.append_array(sim.npcs)
	return VISUALS.landmark_label_visible(point,bodies)

func _draw_portal_marker(point: Vector2,locked: bool) -> void:
	# Transparent chart gate, not a repair chest or an opaque inventory tile.
	var color=Color("a79c78") if locked else Color("66cddd")
	_ellipse(point,Vector2(76,31),Color(color,0.07))
	for i in 3:
		var phase=fmod(elapsed*0.35+float(i)/3.0,1.0)
		_ellipse_line(point,Vector2(42+phase*42,17+phase*17),Color(color,(1-phase)*0.6),2.0)
	for i in 4:
		var angle=float(i)*PI*0.5
		var tip=point+Vector2(cos(angle)*85,sin(angle)*35)
		var inner=point+Vector2(cos(angle)*70,sin(angle)*28)
		draw_line(inner,tip,color,2.2,true)

func _starter_texture(hp: float,max_hp: float) -> Texture2D:
	return starter_damaged_texture if VISUALS.damage_state(hp,max_hp)==1 else starter_texture

func _actor_visual_length(actor: Dictionary) -> float:
	if int(actor.id)==0:
		var skin=int(sim.player.skin)
		if skin==26:return 132.0
		if skin>=10:return float(CONTENT.SHIP_LENGTHS[skin-10])
		return 156.0
	if actor.kind=="ship":return float(CONTENT.SHIP_LENGTHS[posmod(int(actor.art),CONTENT.SHIP_LENGTHS.size())])
	return 150.0

func _draw_actor(actor: Dictionary) -> void:
	if float(actor.hp)<=0:return
	if actor.get("kind","")=="tower":
		_draw_tower(actor)
		return
	var is_player = int(actor.id)==0
	var point: Vector2=actor.pos
	var heading: Vector2=actor.heading
	var length=_actor_visual_length(actor)
	if not actor.path.is_empty():
		var side=Vector2(-heading.y,heading.x)
		for j in 4:
			var tail=point-heading*(24+float(j)*12)
			var spread=8+float(j)*2
			var foam=Color(0.62,0.86,0.87,(1.0-float(j)/4.0)*0.13)
			draw_line(tail+side*spread,tail-heading*9+side*(spread+1.5),foam,1.1,true)
			draw_line(tail-side*spread,tail-heading*9-side*(spread+1.5),foam,1.1,true)
	_ellipse(point+Vector2(0,3),Vector2(length*0.32,length*0.085),Color(0.005,0.03,0.045,0.17))
	if sim.target==int(actor.id):
		_ellipse_line(point,Vector2(length*0.44,length*0.16),Color("ed9d67"),2.0)
	if is_player:
		_ellipse_line(point,Vector2(length*0.44,length*0.16),Color(0.37,0.84,0.83,0.4),1.1)
	var monster = not is_player and actor.kind=="monster"
	if monster:
		var col = posmod(roundi((heading.angle()+PI*0.25)/TAU*4),4)
		var row = int(elapsed*6)%CONTENT.MONSTER_ROWS
		_draw_atlas(beast,point,210.0,col,row,CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS)
	elif is_player and int(sim.player.skin)==26:
		var col=VISUALS.heading_eight(heading,int(direction_cache.get(int(actor.id),-1)))
		direction_cache[int(actor.id)]=col
		_draw_ship_frame(_starter_texture(float(actor.hp),float(actor.max_hp)),point,length,col,false,sin(elapsed*1.7+actor.id)*1.2)
	elif is_player and int(sim.player.skin)<10:
		var tex=ship_textures[int(sim.player.skin)]
		var flipped=VISUALS.facing_right(heading,bool(facing_cache.get(int(actor.id),false)))
		facing_cache[int(actor.id)]=flipped
		_draw_ship_frame(tex,point,length,0,flipped,sin(elapsed*1.7+actor.id)*1.2)
	else:
		var tex = atlas_textures[int(sim.player.skin)-10] if is_player else atlas_textures[posmod(int(actor.art),atlas_textures.size())]
		var col=VISUALS.heading_column(heading,int(direction_cache.get(int(actor.id),-1)))
		direction_cache[int(actor.id)]=col
		_draw_ship_frame(tex,point,length,col,false,sin(elapsed*1.7+actor.id)*1.2)
	if is_player or sim.target==int(actor.id):
		var nose=point+heading*length*0.38
		var side=Vector2(-heading.y,heading.x)*4
		draw_line(nose-heading*8+side,nose,CYAN,1.4,true)
		draw_line(nose-heading*8-side,nose,CYAN,1.4,true)
	var name_offset=68.0 if is_player and int(sim.player.skin)==26 else 47.0
	_nameplate(actor,point+Vector2(0,name_offset))

func _plate_scale() -> float:
	return 1.0 if gallery_page>=0 or camera==null else clampf(1.0/camera.zoom.x,1.0,1.6)

## Nameplates keep a constant on-screen size: captain medallion, guild tag, hull and shield capsules, status icons.
func _nameplate(actor: Dictionary,anchor: Vector2) -> void:
	var is_player=int(actor.id)==0
	var tower=actor.get("kind","")=="tower"
	var monster=actor.get("kind","")=="monster"
	var elite=bool(actor.get("elite",false))
	var hostile=not is_player and (bool(actor.get("aggressive",false)) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) or (tower and not sim.tower_friendly()))
	var hull_ratio=float(actor.hp)/maxf(1.0,float(actor.max_hp))
	var max_shield=float(actor.get("max_shield",0))
	var shield_ratio=float(actor.get("shield",0))/maxf(1.0,max_shield)
	draw_set_transform(anchor,0,Vector2.ONE*_plate_scale())
	if is_player:
		var parts: Array=[]
		if not sim.guild.is_empty():parts.append(["[%s] " % sim.guild.tag,Color("ffd27a")])
		parts.append([str(skins[int(sim.player.skin)].name),CYAN])
		_label_parts(Vector2(11,0),parts,15)
		_medallion(Vector2(-62,19),clampi(floori((sim.level-1)/4.0)+1,1,ROMAN.size()-1))
		_plate_bar(Rect2(-46,6,114,14),hull_ratio,Color("4fbf5e"),"%s / %s" % [_thousands(int(actor.hp)),_thousands(int(actor.max_hp))],10)
		_plate_bar(Rect2(-46,23,114,10),shield_ratio,Color("3d8fe0"),_thousands(int(actor.shield)),9)
		var states: Array[Texture2D]=[]
		if sim.powder_on:states.append(painted.supply_powder)
		if sim.plates_on:states.append(painted.supply_plates)
		if sim.has_blessing():states.append(painted.crystal_blessing)
		if float(sim.buffs.tide_deck)>0:states.append(painted.tide_deck)
		if sim.guild_island_held():states.append(painted.nav_guild)
		if float(actor.slow)>0:states.append(icons.chain)
		for i in states.size():
			var center=Vector2(11+(float(i)-(states.size()-1)*.5)*19,46)
			draw_circle(center,8.5,Color(0.02,0.06,0.08,.85))
			draw_circle(center,8.5,Color("c7a15a"),false,1.0,true)
			draw_texture_rect(states[i],Rect2(center-Vector2(7,7),Vector2(14,14)),false)
	else:
		var color=Color("e4b6ee") if monster else (Color("ff9d8a") if hostile else (Color("ffd98a") if elite else Color("f1e6cc")))
		var health=Color("e0604c") if hostile else (Color("5fc46e") if tower else Color("e1c062"))
		# Clustered fortress towers only name the one under the spyglass; the rest keep compact bars.
		var named=not tower or sim.target==int(actor.id)
		var half=46.0 if named else 28.0
		var top=0.0
		if named:
			var parts: Array=[]
			if tower:parts.append(["[%s] " % sim.tower_tag(),Color("9fe7a8") if sim.tower_friendly() else Color("ffb37a")])
			parts.append([str(actor.name),color])
			_label_parts(Vector2.ZERO,parts,14 if tower else 15)
			top=6.0
		_plate_bar(Rect2(-half,top,half*2,7),hull_ratio,health)
		var below=top+14
		if max_shield>0:
			_plate_bar(Rect2(-half,top+9,half*2,4),shield_ratio,Color("3d8fe0"))
			below=top+19
		if not tower:
			var tier=4 if monster else (3 if elite else 1)+mini(sim.map_id,CONTENT.REGION_COUNT-1)
			if bool(actor.get("boss",false)):tier=5
			var emblem=Color("d9a0ff") if monster else (Color("ffd27a") if elite else Color("8fbcf0"))
			_rank_emblem(Vector2(0,below+8),clampi(tier,1,5),emblem)
			below+=24
		if float(actor.slow)>0:_label(Vector2(0,below+10),"VERLANGSAMT",11,Color("9fdbf4"))
	draw_set_transform(Vector2.ZERO)

func _label_parts(point: Vector2,parts: Array,fontsize: int) -> void:
	var total=0.0
	for part: Array in parts:total+=font.get_string_size(str(part[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	var x=point.x-total*.5
	for part: Array in parts:
		var text=str(part[0])
		var color: Color=part[1]
		draw_string_outline(font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,3,Color(0.01,0.035,0.05,color.a))
		draw_string(font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)
		x+=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x

func _capsule(rect: Rect2,color: Color) -> void:
	if rect.size.x<=0.5 or rect.size.y<=0.5:return
	if rect.size.x<rect.size.y:
		draw_rect(rect,color)
		return
	var r=rect.size.y*.5
	var points=PackedVector2Array()
	for i in 9:points.append(Vector2(rect.end.x-r,rect.position.y+r)+Vector2.from_angle(-PI*.5+PI*float(i)/8.0)*r)
	for i in 9:points.append(Vector2(rect.position.x+r,rect.position.y+r)+Vector2.from_angle(PI*.5+PI*float(i)/8.0)*r)
	draw_colored_polygon(points,color)

func _plate_bar(rect: Rect2,ratio: float,color: Color,text: String="",fontsize: int=9) -> void:
	_capsule(rect.grow(1.5),Color(0,0,0,.78))
	_capsule(rect,Color("0b1a20"))
	var filled=Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0,1),rect.size.y))
	_capsule(filled,color)
	_capsule(Rect2(filled.position+Vector2(2,1),Vector2(filled.size.x-4,filled.size.y*.38)),Color(1,1,1,.24))
	if not text.is_empty():_label(Vector2(rect.get_center().x,rect.get_center().y+fontsize*.36),text,fontsize,Color.WHITE,2)

func _medallion(center: Vector2,tier: int) -> void:
	draw_circle(center+Vector2(0,1.5),14,Color(0,0,0,.6))
	draw_circle(center,13,Color("17303c"))
	draw_circle(center,13,Color("d8b46a"),false,2.0,true)
	draw_circle(center,9.5,Color("7fd8ff"),false,1.0,true)
	_label(center+Vector2(0,4),ROMAN[tier],11 if tier<4 else 9,Color("ffe6a8"))

func _draw_tower(actor: Dictionary) -> void:
	var point: Vector2=actor.pos
	var guardian=str(actor.tower)=="guardian"
	if guardian:
		var phase=fmod(elapsed*.45,1.0)
		_ellipse_line(point,Vector2(44+phase*26,17+phase*9),Color(0.55,0.86,1,(1-phase)*.5),2.0)
	if sim.target==int(actor.id):
		draw_arc(point,float(actor.range),0,TAU,96,Color(1,.55,.35,.2) if not sim.tower_friendly() else Color(.5,1,.6,.2),1.6,true)
	_ellipse(point+Vector2(0,4),Vector2(30,10),Color(0,0,0,.3))
	if sim.target==int(actor.id):_ellipse_line(point+Vector2(0,3),Vector2(38,14),Color("ed9d67"),2.0)
	var tex: Texture2D=painted.get("tower_"+str(actor.tower))
	if tex!=null:
		var dims=tex.get_size()*76.0/maxf(tex.get_width(),tex.get_height())
		draw_texture_rect(tex,Rect2(point-dims*Vector2(0.5,0.9),dims),false)
	if float(actor.reload)>float(actor.rate)-.25 and str(actor.get("state",""))=="attack":
		draw_circle(point-Vector2(0,56),6,Color(1,.75,.35,.6))

func _draw_sparkle(point: Vector2,seed: float) -> void:
	var pulse=0.5+0.5*sin(elapsed*3.2+seed)
	_ellipse(point+Vector2(0,8),Vector2(30,10),Color(0.3,0.95,0.88,0.07+pulse*0.06))
	_ellipse_line(point+Vector2(0,8),Vector2(20+pulse*9,7+pulse*3),Color(0.5,1,0.92,0.32),1.4)
	var lift=point-Vector2(0,8+sin(elapsed*2.0+seed)*3)
	var star=PackedVector2Array()
	for i in 8:
		var angle=float(i)*PI*.25+elapsed*.5+seed
		star.append(lift+Vector2.from_angle(angle)*((10.0+pulse*3.0) if i%2==0 else 3.4))
	draw_colored_polygon(star,Color(0.72,1,0.95,0.92))
	draw_circle(lift,2.6,Color.WHITE)

func _rank_emblem(center: Vector2,tier: int,tint: Color) -> void:
	var dark=Color(0,0,0,.6)
	var k=1.4
	for side in [-1.0,1.0]:
		for feather in 3:
			var root=center+Vector2(side*6,-1+feather*2.6)*k
			var tip=center+Vector2(side*(21-feather*4.5),-5+feather*2.2)*k
			draw_line(root+Vector2(0,1.2),tip+Vector2(0,1.2),dark,(3.2-feather*.5)*k,true)
			draw_line(root,tip,Color(tint,1.0-feather*.22),(2.4-feather*.45)*k,true)
	for chevron in tier:
		var y=-3.5+chevron*3.2
		var arms=PackedVector2Array([center+Vector2(-4.5,y-2.5)*k,center+Vector2(0,y+.8)*k,center+Vector2(4.5,y-2.5)*k])
		draw_polyline(arms,dark,3.0*k,true)
		draw_polyline(arms,tint.lightened(.35),1.6*k,true)
	draw_circle(center+Vector2(0,-6.5)*k,2.6*k,dark)
	draw_circle(center+Vector2(0,-6.5)*k,1.9*k,tint.lightened(.5))

func _draw_atlas(tex: Texture2D,point: Vector2,width: float,col: int,row: int,columns: int,rows: int) -> void:
	var cell = tex.get_size()/Vector2(columns,rows)
	var dims = cell*width/cell.x
	draw_texture_rect_region(tex,Rect2(point-dims*Vector2(0.5,0.68),dims),Rect2(Vector2(col,row)*cell,cell))

func _ship_preview(texture: Texture2D,column: int) -> AtlasTexture:
	var frame: Dictionary=ship_frames[texture.resource_path.trim_prefix("res://")].frames[column]
	var r: Array=frame.rect
	var preview=AtlasTexture.new()
	preview.atlas=texture
	preview.region=Rect2(r[0],r[1],r[2],r[3])
	return preview

func _draw_ship_frame(texture: Texture2D,point: Vector2,length: float,column: int,flipped: bool,bob: float) -> void:
	var frame: Dictionary=ship_frames[texture.resource_path.trim_prefix("res://")].frames[column]
	var geometry: Dictionary=VISUALS.geometry(frame,length)
	# Positive source/destination rectangles; reflection is around the measured hull anchor.
	draw_set_transform(point+Vector2(0,bob),0,Vector2(-1,1) if flipped else Vector2.ONE)
	draw_texture_rect_region(texture,geometry.destination,geometry.source)
	draw_set_transform(Vector2.ZERO)

func _draw_ship_gallery() -> void:
	if gallery_page in [3,4]:
		_draw_starter_gallery(gallery_page==4)
		return
	var first=0 if gallery_page==0 else 10+(gallery_page-1)*8
	var last=10 if gallery_page==0 else mini(first+8,skins.size())
	var before=sim.player.duplicate(true)
	var directions=[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]
	_label(Vector2(640,26),"M3056 · ORIGINAL RUNTIME RENDERER · WATERLINE ANCHORS",20,GOLD)
	for c in 4:_label(Vector2(320+c*240,59),["NORDOST","NORDWEST","SÜDWEST","SÜDOST"][c],14,CYAN)
	for skin in range(first,last):
		var y=216.0+float(skin-first)*200.0
		_label(Vector2(100,y-18),str(skins[skin].name),13,GOLD)
		_label(Vector2(100,y+5),"Einzelbild / Spiegelung" if skin<10 else "4 echte Atlasansichten",10,CYAN)
		draw_line(Vector2(14,y+78),Vector2(1266,y+78),Color(0.3,0.5,0.6,0.2))
		for c in 4:
			var ground=Vector2(320+c*240,y)
			sim.player.skin=skin
			sim.player.pos=ground
			sim.player.heading=directions[c].normalized()
			sim.player.path=[]
			_draw_actor(sim.player)
			draw_line(ground-Vector2(4,0),ground+Vector2(4,0),Color("ffae66"),1)
			draw_line(ground-Vector2(0,4),ground+Vector2(0,4),Color("ffae66"),1)
	sim.player=before

func _draw_starter_gallery(damaged: bool=false) -> void:
	var before=sim.player.duplicate(true)
	var headings=[Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
	var labels=["NORD","NORDOST","OST","SÜDOST","SÜD","SÜDWEST","WEST","NORDWEST"]
	_label(Vector2(640,38),"M3056 · SMALL STARTER · "+("8 BESCHÄDIGTE ANSICHTEN" if damaged else "8 INTAKTE ANSICHTEN"),21,GOLD)
	_label(Vector2(640,70),"Laufzeit-Renderer · feste Vergrößerung · orange = Wasserlinienanker",13,CYAN)
	for i in 8:
		var ground=Vector2(200+(i%4)*290,300+int(i/4)*370)
		_label(ground-Vector2(0,180),labels[i],16,CYAN)
		sim.player.skin=26
		sim.player.hp=float(sim.player.max_hp)*(0.25 if damaged else 1.0)
		sim.player.pos=ground
		sim.player.heading=headings[i].normalized()
		sim.player.path=[]
		direction_cache.erase(0)
		_draw_actor(sim.player)
		draw_line(ground-Vector2(6,0),ground+Vector2(6,0),Color("ffae66"),1)
		draw_line(ground-Vector2(0,6),ground+Vector2(0,6),Color("ffae66"),1)
	sim.player=before
	direction_cache.erase(0)

func _ellipse(point: Vector2,radii: Vector2,color: Color) -> void:
	var vertices = PackedVector2Array()
	for i in 32: vertices.append(point+Vector2(cos(float(i)*TAU/32),sin(float(i)*TAU/32))*radii)
	draw_colored_polygon(vertices,color)

func _ellipse_line(point: Vector2,radii: Vector2,color: Color,width: float) -> void:
	var vertices = PackedVector2Array()
	for i in 33: vertices.append(point+Vector2(cos(float(i)*TAU/32),sin(float(i)*TAU/32))*radii)
	draw_polyline(vertices,color,width,true)

func _label(point: Vector2,text: String,fontsize: int,color: Color,outline: int=3) -> void:
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	var p = point-Vector2(width*0.5,0)
	draw_string_outline(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,outline,Color(0.01,0.035,0.05,color.a))
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)

func _panel(parent: Node) -> Panel:
	var p =HUD_PANEL.new()
	var style =StyleBoxFlat.new()
	style.bg_color=Color(0.025,0.07,0.09,0.94)
	style.border_color=Color("93764b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color=Color(0,0,0,0.25)
	style.shadow_size=5
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p

func _text(parent: Node,text: String,fontsize: int=14,color: Color=GOLD) -> Label:
	var l =Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",fontsize)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Node,text: String,callback: Callable) -> Button:
	var b =Button.new()
	b.text=text
	b.clip_text=true
	b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",14)
	b.add_theme_color_override("font_color",GOLD)
	for state in ["normal","hover","pressed","disabled"]:
		var style =StyleBoxFlat.new()
		style.bg_color={"normal":Color("122832"),"hover":Color("29404a"),"pressed":Color("365760"),"disabled":Color("0d1d25")}[state]
		style.border_color=GOLD if state in ["pressed","hover"] else Color("67583f")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(6)
		b.add_theme_stylebox_override(state,style)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _portrait(parent: Control) -> TextureRect:
	var p=TextureRect.new()
	p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _bar(parent: Node) -> ProgressBar:
	var b =ProgressBar.new()
	b.show_percentage=false
	b.max_value=sim.PLAYER_HP
	var bg =StyleBoxFlat.new();bg.bg_color=Color("061018");bg.set_corner_radius_all(3);bg.border_color=Color("6d5634");bg.set_border_width_all(1)
	var fill =StyleBoxFlat.new();fill.bg_color=Color("3fa65a");fill.set_corner_radius_all(2)
	b.add_theme_stylebox_override("background",bg)
	b.add_theme_stylebox_override("fill",fill)
	parent.add_child(b)
	return b

func _orb(parent: Node,semantic: String,texture: Texture2D,callback: Callable,caption: String="",nav: bool=false) -> Button:
	var button=HUD.new()
	button.text=semantic;button.art=texture;button.caption=caption;button.nav_mode=nav
	button.tooltip_text=semantic
	button.pressed.connect(callback);parent.add_child(button)
	return button

func _set_orb(button: Button,texture: Texture2D,amount: String="",active: bool=false,caption: String="") -> void:
	button.set("art",texture);button.set("quantity",amount);button.set("latched",active);button.set("caption",caption);button.queue_redraw()

func _build_ui() -> void:
	var layer =CanvasLayer.new()
	add_child(layer)
	ui=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	ruler=RULER.new();ruler.world_size=sim.WORLD;ui.add_child(ruler)
	chrome=_panel(ui)
	for name in ["gold_coins","kills_skull"]:
		var icon=_portrait(chrome);icon.texture=painted[name];wallet_icons.append(icon)
	gold_label=_text(chrome,"",15,Color("ffe2a0"))
	kills_label=_text(chrome,"",12,Color("eadfc6"))
	for label in [gold_label,kills_label]:label.clip_text=true;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var nav_items=[["Schiff","nav_ship","Schiff"],["Werft","nav_shipyard","Werft"],["Hafen","nav_harbor","Hafen"],["Logbuch","nav_quests","Logbuch"],["Bonus","nav_bonus","Bonuskarten"],["Kessel","nav_kessel","Kessel"],["Gilde","nav_guild","Gilde"],["Rang","nav_ranking","Rangliste"],["Menü","nav_menu","Spielinfo"]]
	for item in nav_items:
		var kind: String=item[2]
		var button=_orb(chrome,str(item[0]),painted[item[1]],func():_open_modal(kind),str(item[0]),true)
		button.tooltip_text=kind
		button.set_meta("modal",kind);nav_buttons.append(button)
	for tag in ["EXP","HP","SCHILD"]:
		var label=_text(chrome,tag,9,Color("ecd29a"));label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;meter_tags.append(label)
	player_xp=_bar(chrome)
	var xp_style: StyleBoxFlat=player_xp.get_theme_stylebox("fill").duplicate();xp_style.bg_color=Color("c79a3f");player_xp.add_theme_stylebox_override("fill",xp_style)
	player_hp=_bar(chrome)
	player_shield=_bar(chrome)
	var shield_style: StyleBoxFlat=player_shield.get_theme_stylebox("fill").duplicate();shield_style.bg_color=Color("2f7fd0");player_shield.add_theme_stylebox_override("fill",shield_style)
	xp_numbers=_text(player_xp,"",9,Color.WHITE)
	player_numbers=_text(player_hp,"",9,Color.WHITE)
	shield_numbers=_text(player_shield,"",9,Color.WHITE)
	for readout: Label in [xp_numbers,player_numbers,shield_numbers]:
		readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;readout.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;readout.clip_text=true
		readout.add_theme_color_override("font_outline_color",Color("06121a"));readout.add_theme_constant_override("outline_size",3)
	target_panel=_panel(ui)
	target_portrait=_portrait(target_panel)
	target_panel.clip_contents=true
	target_name=_text(target_panel,"",13);target_name.clip_text=true
	target_hp=_bar(target_panel)
	target_health_skin=target_hp.get_theme_stylebox("fill").duplicate();target_hp.add_theme_stylebox_override("fill",target_health_skin)
	target_numbers=_text(target_panel,"",10)
	target_numbers.clip_text=true
	target_numbers.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quest_panel=_panel(ui)
	quest_icon=_portrait(quest_panel);quest_icon.texture=painted.nav_quests
	quest_text=_text(quest_panel,"",11);quest_text.clip_text=true;quest_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	quest_open=Button.new();quest_open.focus_mode=Control.FOCUS_NONE;quest_open.tooltip_text="Logbuch öffnen"
	for state in ["normal","hover","pressed","hover_pressed","focus"]:quest_open.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	quest_open.pressed.connect(func():_open_modal("Logbuch"));quest_panel.add_child(quest_open)
	quest_claim=_button(quest_panel,"ABHOLEN",func():sim.claim_quest();_save_progress();_refresh_ui());quest_claim.add_theme_font_size_override("font_size",10)
	chart_mini=MINI.new();chart_mini.simulation=sim
	chart_mini.course_requested.connect(func(point):_chart_course(point))
	ui.add_child(chart_mini)
	zoom_out=_orb(ui,"Weiter zoomen",hud_icons.minus,func():_zoom(1.0/1.15))
	zoom_in=_orb(ui,"Näher zoomen",hud_icons.plus,func():_zoom(1.15))
	center_button=_orb(ui,"Kamera zum Schiff",hud_icons.focus,_recenter_camera)
	settings_button=_orb(ui,"Anzeige & Steuerung",hud_icons.gear,func():_open_modal("Anzeige"));settings_button.name="SettingsButton"
	attack=_orb(ui,"Feuer ein/aus",extra_icons.cannon_action,_toggle_fire,"FEUER");attack.name="FireButton"
	attack.set("hero",true)
	repair=_orb(ui,"Schiff reparieren",extra_icons.upgrade_hull,func():sim.toggle_repair();_refresh_ui(),"REP");repair.name="RepairButton"
	for i in 3:
		var index=i
		var button=_orb(ui,"",icons[["cannonball","chain","harpoon"][i]],func():sim.set_ammo(index);_refresh_ui())
		button.name="Ammo%d" % i;button.toggle_mode=true;ammo_buttons.append(button)
	for key: String in CONTENT.SUPPLY_KEYS:
		var supply=key
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var button=_orb(ui,"%s · %s" % [config.name,config.effect],painted[config.icon],func():_use_supply(supply),str(config.short))
		button.name="Supply_"+key;supply_buttons[key]=button
	page_button=_orb(ui,"Schnellleiste umschalten · Q",null,_flip_page,"1/2");page_button.name="PageButton"
	page_button.set("pager",true)
	target_cycle=_orb(ui,"Nächstes sichtbares Ziel · Tab",painted.spyglass,_cycle_target,"ZIEL")
	ammo_selector=_orb(ui,"Munition & Gegenstände",painted.nav_supplies,func():_open_modal("Munition"),"VORRAT")
	loadout_button=_orb(ui,"Bewaffnung",extra_icons.cannon_0,func():_open_modal("Bewaffnung"),"WAFFEN")
	camera_pad=CAMERA_PAD.new();ui.add_child(camera_pad)
	interact=_button(ui,"",_interact);interact.name="InteractButton"
	buff_bar=Control.new();buff_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;buff_bar.name="BuffBar"
	buff_bar.draw.connect(_draw_buffs);ui.add_child(buff_bar)
	status=_text(ui,"",12,Color("e2ecee"));status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	status.clip_text=true
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var toast=StyleBoxFlat.new();toast.bg_color=Color(.01,.04,.06,.64);toast.set_corner_radius_all(11);toast.border_color=Color(.79,.64,.37,.35);toast.set_border_width_all(1)
	toast.content_margin_left=12;toast.content_margin_right=12
	status.add_theme_stylebox_override("normal",toast)
	modal_backdrop=ColorRect.new()
	modal_backdrop.color=Color(0.002,0.009,0.018,0.77)
	modal_backdrop.z_index=19
	modal_backdrop.visible=false
	modal_backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
	ui.add_child(modal_backdrop)
	modal=_panel(ui)
	# Scroll clipping must remain in unscaled viewport space. HUD orbs scale separately.
	modal.set_as_top_level(true)
	modal_skin=StyleBoxTexture.new()
	modal_skin.texture=load("res://assets/expanded/panel_frame.png")
	modal_skin.texture_margin_left=58
	modal_skin.texture_margin_right=42
	modal_skin.texture_margin_top=65
	modal_skin.texture_margin_bottom=38
	modal_compact_skin=StyleBoxFlat.new()
	modal_compact_skin.bg_color=Color("081d28")
	modal_compact_skin.border_color=GOLD
	modal_compact_skin.set_border_width_all(2)
	modal_compact_skin.set_corner_radius_all(7)
	modal.z_index=20
	modal.visible=false
	modal_title=_text(modal,"",22)
	modal_close=_button(modal,"SCHLIESSEN",func():modal.hide();_save_progress())
	modal_scroll=ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	modal.add_child(modal_scroll)
	modal_body=VBoxContainer.new()
	modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",10)
	modal_scroll.add_child(modal_body)
	loading=LOADING.new();loading.art=painted.loading;loading.wheel=painted.helm_wheel
	loading.set_as_top_level(true);loading.z_index=40;loading.visible=false
	ui.add_child(loading)

func _place(c: Control,x: float,y: float,w: float,h: float) -> void:
	c.position=Vector2(x,y)
	c.size=Vector2(maxf(w,1),maxf(h,1))

func _layout() -> void:
	if ui==null:return
	var viewport_size=get_viewport_rect().size
	# Scale only the HUD. Ocean, camera, world input and simulation keep viewport coordinates.
	var base=clampf(viewport_size.y/600.0,1.0,1.35)
	var requested=base*[0.86,1.0,1.14][hud_size]
	hud_scale=clampf(requested,0.86,minf(viewport_size.x/720.0,viewport_size.y/390.0))
	ui.scale=Vector2.ONE*hud_scale
	var s=viewport_size/hud_scale
	ui.size=s
	var compact=viewport_size.y<560 or viewport_size.x<1000
	if compact and elapsed<0.1:
		desired_zoom=0.78
		camera.zoom=Vector2.ONE*desired_zoom
	water.size=viewport_size
	_place(ruler,0,0,s.x,s.y)
	# Top bar: wallet left, full-width navigation, captain meters right.
	var header=48.0 if compact else 54.0
	_place(chrome,0,0,s.x,header)
	var wallet=104.0 if compact else 138.0
	var row=(header-6)*.5
	for i in 2:_place(wallet_icons[i],6,4+i*row,row-2,row-2)
	_place(gold_label,row+8,3,wallet-row-10,row)
	_place(kills_label,row+8,3+row,wallet-row-10,row)
	var meters=140.0 if compact else 204.0
	var meter_x=s.x-meters-8
	var meter_row=(header-6)/3.0
	var bars: Array[ProgressBar]=[player_xp,player_hp,player_shield]
	var readouts: Array[Label]=[xp_numbers,player_numbers,shield_numbers]
	for i in 3:
		_place(meter_tags[i],meter_x,3+i*meter_row,34,meter_row)
		_place(bars[i],meter_x+34,4+i*meter_row,meters-34,meter_row-2)
		_place(readouts[i],0,0,bars[i].size.x,bars[i].size.y)
	var nav_left=wallet+8
	var nav_span=meter_x-10-nav_left
	var nw=minf(nav_span/nav_buttons.size(),98.0)
	var nav_x=nav_left+(nav_span-nw*nav_buttons.size())*.5
	for i in nav_buttons.size():_place(nav_buttons[i],nav_x+i*nw+1,2,nw-3,header-4)
	# Left column sits inside the row-letter ruler.
	var left=22.0
	var top=header+18
	var column=212.0 if compact else 240.0
	var quest_h=40.0 if compact else 44.0
	_place(quest_panel,left,top,column,quest_h)
	quest_panel.visible=journal_visible
	_place(quest_icon,5,4,quest_h-8,quest_h-8)
	_place(quest_text,quest_h+2,2,column-quest_h-8,quest_h-4)
	_place(quest_open,0,0,column,quest_h)
	_place(quest_claim,column-78,(quest_h-26)*.5,72,26)
	var target_y=top+(quest_h+6 if journal_visible else 0)
	var card_h=60.0 if compact else 66.0
	_place(target_panel,left,target_y,column,card_h)
	_place(target_portrait,6,6,card_h-12,card_h-12)
	var tx=card_h
	_place(target_name,tx,3,column-tx-6,18);_place(target_hp,tx,22,column-tx-10,8);_place(target_numbers,tx,31,column-tx-6,card_h-33)
	_place(interact,left,target_y+card_h+6,column,34)
	_place(buff_bar,left,target_y+card_h+46,column,30)
	# Chart with corner controls, as on classic sea-chart clients.
	var mw=136.0 if compact else 190.0
	var mh=118.0 if compact else 160.0
	var mx=s.x-mw-20
	var my=header+22
	_place(chart_mini,mx,my,mw,mh)
	var z=32.0 if compact else 36.0
	_place(zoom_out,mx-z*.3,my-z*.3,z,z)
	_place(zoom_in,mx+mw-z*.7,my-z*.3,z,z)
	_place(center_button,mx-z*.3,my+mh-z*.7,z,z)
	_place(settings_button,mx+mw-z*.7,my+mh-z*.7,z,z)
	var pad=92.0 if compact else 104.0
	_place(camera_pad,12,s.y-pad-12,pad,pad)
	camera_pad.visible=camera_pad_visible
	ruler.top=header
	ruler.left_bottom=(s.y-pad-20) if camera_pad_visible else s.y-12
	# Combat corner: cannon bottom-right, quick slots in an L around it, utilities continue the bottom row.
	var fire=112.0 if compact else 140.0
	var orb=50.0 if compact else 60.0
	var gap=8.0
	var fx=s.x-fire-10
	var fy=s.y-fire-10
	_place(attack,fx,fy,fire,fire)
	_place(ammo_buttons[0],fx-orb-gap,s.y-orb-10,orb,orb)
	_place(ammo_buttons[1],fx-orb-gap,s.y-orb*2-10-gap,orb,orb)
	_place(ammo_buttons[2],fx+fire*.5-orb-gap*.5,fy-orb-gap,orb,orb)
	_place(repair,fx+fire*.5+gap*.5,fy-orb-gap,orb,orb)
	# Page two swaps the three ammunition slots for items; powder keeps its own slot above the chain shot.
	_place(supply_buttons.powder,fx-orb-gap,ammo_buttons[1].position.y-orb-gap,orb,orb)
	for i in 3:
		var item: Button=supply_buttons[["repair_kit","shield_charge","plates"][i]]
		_place(item,ammo_buttons[i].position.x,ammo_buttons[i].position.y,orb,orb)
	var hot: Array[Button]=[target_cycle,ammo_selector,loadout_button,page_button]
	var row_x=fx-orb-gap
	for i in hot.size():_place(hot[hot.size()-1-i],row_x-(i+1)*(orb+gap),s.y-orb-10,orb,orb)
	_apply_page()
	var toast_w=minf(380.0,2.0*(ammo_buttons[1].position.x-s.x*.5)-16.0)
	_place(status,(s.x-toast_w)*.5,s.y-orb-40,toast_w,24)
	status.set_meta("room",toast_w)
	var menu_size=viewport_size
	var width=minf(720,menu_size.x-32)
	var height=minf(620,menu_size.y-24)
	_place(modal_backdrop,0,0,s.x,s.y)
	if modal_kind=="Munition":
		width=minf(480,menu_size.x-32);height=minf(420,menu_size.y-108)
		_place(modal,menu_size.x-width-16,maxf(12,menu_size.y-height-104),width,height)
	else:_place(modal,(menu_size.x-width)*.5,(menu_size.y-height)*.5,width,height)
	modal.add_theme_stylebox_override("panel",modal_compact_skin)
	_place(modal_title,18,12,width-160,30);_place(modal_close,width-136,12,118,32)
	_place(modal_scroll,18,56,width-36,height-74)
	modal_body.size.x=modal_scroll.size.x
	modal_body.queue_sort()
	_place(loading,0,0,viewport_size.x,viewport_size.y)

func _sync_ruler() -> void:
	ruler.world_to_screen=get_canvas_transform()
	ruler.hud_scale=hud_scale
	ruler.queue_redraw()

func _thousands(value: int) -> String:
	var digits=str(absi(value))
	var grouped=""
	while digits.length()>3:
		grouped="."+digits.right(3)+grouped
		digits=digits.left(digits.length()-3)
	return ("-" if value<0 else "")+digits+grouped

func _refresh_ui() -> void:
	if gold_label==null:return
	var today=Time.get_date_string_from_system()
	var quest_ready=not sim.current_quest().is_empty() and sim.quest_progress()>=int(sim.current_quest().goal)
	for nav: Button in nav_buttons:
		var kind=str(nav.get_meta("modal"))
		var badge=""
		var alert=false
		match kind:
			"Logbuch":
				badge="!" if quest_ready else "";alert=quest_ready
			"Bonuskarten":
				var stock=0
				for amount in sim.scrolls:stock+=int(amount)
				badge="!" if not sim.bonus.is_empty() else (str(stock) if stock>0 else "")
				alert=not sim.bonus.is_empty() or sim.fragments>=int(CONTENT.BONUS_TIERS[0].fragments)
				if alert and badge.is_empty():badge="+"
			"Kessel":
				badge=str(sim.essence);alert=sim.free_flask_ready(today)
			"Gilde":
				badge="%d'" % ceili(sim.fortress_hold/60.0) if sim.guild_island_held() else ""
		nav.set("quantity",badge);nav.set("badge_alert",alert)
		nav.set("latched",modal.visible and modal_kind==kind);nav.queue_redraw()
	gold_label.text=_thousands(int(sim.player.gold))
	kills_label.text="%s versenkt" % _thousands(sim.kills)
	player_hp.max_value=sim.player.max_hp
	player_hp.value=sim.player.hp
	player_numbers.text="%s / %s" % [_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))]
	player_shield.max_value=maxf(1.0,float(sim.player.max_shield))
	player_shield.value=sim.player.shield
	shield_numbers.text="%s / %s" % [_thousands(int(sim.player.shield)),_thousands(int(sim.player.max_shield))]
	buff_bar.queue_redraw()
	player_xp.max_value=maxi(1,sim.xp_required())
	player_xp.value=sim.xp
	xp_numbers.text="LV. %d · %s / %s" % [sim.level,_thousands(sim.xp),_thousands(sim.xp_required())]
	player_xp.tooltip_text="Erfahrung %d / %d" % [sim.xp,sim.xp_required()]
	var selected =sim.actor(sim.target)
	target_panel.visible=not selected.is_empty() and sim.target>0 and int(selected.hp)>0
	if target_panel.visible:
		if portrait_target!=int(selected.id):
			portrait_target=int(selected.id)
			if selected.kind=="monster":
				var preview=AtlasTexture.new();preview.atlas=beast
				preview.region=Rect2(Vector2.ZERO,beast.get_size()/Vector2(CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS))
				target_portrait.texture=preview
			elif selected.kind=="tower":target_portrait.texture=painted["tower_"+str(selected.tower)]
			else:target_portrait.texture=_ship_preview(atlas_textures[int(selected.art)],0)
		target_name.text=("[%s] " % sim.tower_tag() if selected.kind=="tower" else "")+str(selected.name)
		target_hp.max_value=selected.max_hp
		target_hp.value=selected.hp
		var disposition="IM KAMPF" if sim.npc_engages(selected) else ("FEINDLICH" if CONTENT.MAPS[sim.map_id].npc_hostile else "NEUTRAL")
		if selected.kind=="tower" and sim.tower_friendly():disposition="GILDENTURM"
		target_health_skin.bg_color=Color("c9573f") if bool(selected.aggressive) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) else Color("cfae55")
		var shield_text=" · Schild %s" % _thousands(int(selected.shield)) if float(selected.get("max_shield",0))>0 else ""
		target_numbers.text="%s / %s HP%s\n%s · %d m"%[_thousands(int(selected.hp)),_thousands(int(selected.max_hp)),shield_text,disposition,roundi(sim.player.pos.distance_to(selected.pos))]
	attack.text="STOPP" if sim.firing else "FEUER"
	attack.disabled=not target_panel.visible or int(sim.player.hp)<=0 or sim.docked
	_set_orb(attack,extra_icons.cannon_action,"",sim.firing,attack.text)
	attack.set("cooldown",float(sim.player.reload)/sim.reload_time())
	attack.set("state_label",_combat_state())
	repair.disabled=sim.docked
	repair.text="STOPP" if sim.repairing else "REPARATUR"
	_set_orb(repair,extra_icons.upgrade_hull,"",sim.repairing,"STOPP" if sim.repairing else "REP")
	for i in 3:
		ammo_buttons[i].text=["Vollkugeln","Kettenkugeln","Harpunen"][i]+"\n"+("✓ " if sim.ammo_mode==i else "")+str(sim.player.ammo[i])
		ammo_buttons[i].set_pressed_no_signal(sim.ammo_mode==i)
		_set_orb(ammo_buttons[i],icons[["cannonball","chain","harpoon"][i]],_thousands(int(sim.player.ammo[i])),sim.ammo_mode==i)
		ammo_buttons[i].tooltip_text=["Vollkugeln: gegen Schiffe","Kettenkugeln: verlangsamen Schiffe","Harpunen: gegen Monster"][i]
	for key: String in CONTENT.SUPPLY_KEYS:
		var item: Button=supply_buttons[key]
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var stock=int(sim.supplies[key])
		var active=(sim.powder_on if key=="powder" else sim.plates_on) if bool(config.toggle) else false
		var wait=float(sim.cooldowns.get(key,0.0))
		_set_orb(item,painted[config.icon],_thousands(stock),active,str(config.short))
		item.set("cooldown",wait/float(config.get("cooldown",1.0)))
		item.set("state_label","%d s" % ceili(wait) if wait>0 else ("AN" if active else ""))
		item.disabled=sim.docked or int(sim.player.hp)<=0 or (stock<=0 and not active)
	_set_orb(page_button,null,"",quick_page==1,"%d/2" % (quick_page+1))
	page_button.set("state_label","SCHUTZ" if quick_page==1 else "MUNITION")
	_set_orb(ammo_selector,painted.nav_supplies,"",modal.visible and modal_kind=="Munition","VORRAT")
	_set_orb(target_cycle,painted.spyglass,"",false,"ZIEL")
	_set_orb(loadout_button,extra_icons.cannon_0,"",modal.visible and modal_kind=="Bewaffnung","WAFFEN")
	if message_history.is_empty() or message_history.back()!=sim.message:
		message_history.append(sim.message)
		if message_history.size()>6:message_history.pop_front()
	status.text="IM HAFEN · ABLEGEN zum Weiterfahren" if sim.docked else sim.message
	status.visible=not status.text.is_empty()
	var toast_room: float=status.get_meta("room",status.size.x)
	var toast_w=minf(toast_room,font.get_string_size(status.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+40)
	status.position.x=ui.size.x*.5-toast_w*.5;status.size.x=toast_w
	var quest = sim.current_quest()
	var claimable=not quest.is_empty() and sim.quest_progress()>=int(quest.goal)
	var raid=sim.in_bonus_map() and not sim.bonus.is_empty()
	if raid:
		claimable=false
		quest_icon.texture=painted.boss_wave
		var tier: Dictionary=CONTENT.BONUS_TIERS[int(sim.bonus.tier)]
		var wave=mini(int(sim.bonus.wave),CONTENT.BONUS_WAVES.size()-1)
		var title="%s · WELLE %d/%d" % [str(tier.name).to_upper(),wave+1,CONTENT.BONUS_WAVES.size()]
		match str(sim.bonus.state):
			"break":quest_text.text="%s\n%s formiert sich · %d s" % [title,CONTENT.BONUS_WAVES[wave].label,ceili(float(sim.bonus.timer))]
			"fight":quest_text.text="%s\n%s · noch %d Gegner" % [title,CONTENT.BONUS_WAVES[wave].label,sim.bonus_wave_alive()]
			_:quest_text.text="%s GESCHAFFT\nTruhe geborgen · Karte verlassen" % str(tier.name).to_upper()
	else:
		quest_icon.texture=painted.nav_quests
		quest_text.text="ALLE AUFTRÄGE ERLEDIGT\nDas Logbuch bleibt offen" if quest.is_empty() else "%s · %d/%d\n%d Gold · %d EP" % [str(quest.name).to_upper(),mini(sim.quest_progress(),int(quest.goal)),quest.goal,quest.gold,quest.xp]
	quest_claim.visible=claimable
	quest_claim.disabled=not claimable
	quest_text.size.x=quest_panel.size.x-quest_panel.size.y-(86 if claimable else 8)
	interact.visible=sim.in_bonus_map() or sim.docked or sim.near_portal()>=0 or sim.can_dock() or sim.pending_portal>=0
	interact.disabled=false
	if sim.in_bonus_map():
		interact.text="BONUSKARTE VERLASSEN"
	elif sim.docked:
		interact.text="ABLEGEN"
	elif sim.near_portal()>=0:
		var region: Dictionary=CONTENT.MAPS[sim.near_portal()]
		interact.text=("AB LV. %d · %s" % [region.level,region.name]) if sim.level<int(region.level) else "PORTAL · "+str(region.name)
	elif sim.pending_portal>=0:
		interact.text="PORTALKURS ABBRECHEN"
	elif sim.can_dock():
		interact.text="IM HAFEN ANDOCKEN"
	else:
		interact.text="KURS ZUM PORTAL" if sim.pending_portal>=0 else "KURS ZUM HAFEN"

func _begin_loading(duration: float) -> void:
	var region: Dictionary=CONTENT.MAPS[sim.map_id]
	loading_total=maxf(duration,.1);loading_left=loading_total
	loading.region="%s %s" % [region.name,region.code]
	loading.tip=LOADING.TIPS[(sim.map_id+sim.kills+sim.quest_index)%LOADING.TIPS.size()]
	loading.progress=0.0;loading.fade=1.0;loading.visible=true
	loading.queue_redraw()

func _advance_loading(delta: float) -> void:
	loading_left=maxf(0.0,loading_left-delta)
	loading.progress=ease(clampf((1.0-loading_left/loading_total)/0.8,0,1),0.6)
	loading.fade=clampf(loading_left/0.3,0,1)
	loading.spin+=delta*2.6
	loading.visible=loading_left>0
	loading.queue_redraw()

func _combat_state() -> String:
	if int(sim.player.hp)<=0:return "VERSENKT"
	if sim.docked:return "IM HAFEN"
	var victim=sim.actor(sim.target)
	if victim.is_empty() or float(victim.hp)<=0:return "ZIEL WÄHLEN"
	if victim.kind=="tower" and sim.tower_friendly():return "GILDENTURM"
	if (victim.kind=="monster")!=(sim.ammo_mode==2):return "WAFFE WECHSELN"
	if int(sim.player.ammo[sim.ammo_mode])<(1 if sim.ammo_mode==2 else 3):return "MUNITION LEER"
	if sim.player.pos.distance_to(victim.pos)>530:return "ZU WEIT"
	if victim.kind!="tower" and not sim.segment_free(sim.player.pos,victim.pos):return "INSEL IM WEG"
	if float(sim.player.reload)>0:return ("LÄDT %.1f s" % float(sim.player.reload)).replace(".",",")
	return "BEREIT"

func _toggle_fire() -> void:
	if sim.target<1:return
	sim.firing=not sim.firing
	sim.repairing=false
	_refresh_ui()

func _use_supply(key: String) -> void:
	if bool(CONTENT.SUPPLIES[key].toggle):sim.toggle_supply(key)
	else:sim.use_supply(key)
	_refresh_ui()

func _flip_page() -> void:
	quick_page=1-quick_page
	_apply_page()
	_refresh_ui()

func _apply_page() -> void:
	for i in 3:
		ammo_buttons[i].visible=quick_page==0
		supply_buttons[["repair_kit","shield_charge","plates"][i]].visible=quick_page==1

## Active effects with remaining sea time; emergency cooldowns live on their own orbs.
func _draw_buffs() -> void:
	var entries: Array=[]
	if sim.has_blessing():entries.append([painted.crystal_blessing,_clock_text(float(sim.buffs.blessing)),Color("c69bff")])
	if float(sim.buffs.tide_deck)>0:entries.append([painted.tide_deck,_clock_text(float(sim.buffs.tide_deck)),Color("5fe0d2")])
	if sim.guild_island_held():entries.append([painted.nav_guild,_clock_text(sim.fortress_hold),Color("9fe7a8")])
	var x=0.0
	var h=buff_bar.size.y
	for entry: Array in entries:
		var text: String=entry[1]
		var w=h+6+font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+10
		var skin=StyleBoxFlat.new();skin.bg_color=Color(0.02,0.06,0.08,.82);skin.set_corner_radius_all(int(h*.5))
		skin.border_color=entry[2];skin.set_border_width_all(1)
		buff_bar.draw_style_box(skin,Rect2(x,0,w,h))
		buff_bar.draw_texture_rect(entry[0],Rect2(x+3,3,h-6,h-6),false)
		buff_bar.draw_string_outline(font,Vector2(x+h+3,h*.5+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("06121a"))
		buff_bar.draw_string(font,Vector2(x+h+3,h*.5+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3e0b6"))
		x+=w+6
		if x>buff_bar.size.x-40:break

func _clock_text(seconds: float) -> String:
	var total=ceili(seconds)
	var hours=floori(total/3600.0)
	var minutes=floori((total%3600)/60.0)
	return "%d:%02d:%02d" % [hours,minutes,total%60] if hours>0 else "%d:%02d" % [minutes,total%60]

func _open_modal(kind: String) -> void:
	camera_pad.release()
	var scroll_position=modal_scroll.scroll_vertical if modal.visible and modal_kind==kind else 0
	modal_kind=kind
	modal_title.text=kind
	modal_body.add_theme_constant_override("separation",6 if kind=="Munition" else 10)
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	_layout()
	if kind=="Schiff":
		_info(("[%s] " % sim.guild.tag if not sim.guild.is_empty() else "")+str(skins[int(sim.player.skin)].name).to_upper(),CYAN)
		_picture(modal_body,skin_previews[int(sim.player.skin)],120)
		_info("Kapitän Lv. %d · Erfahrung %d / %d\nRumpf %s / %s · Schild %s / %s\nFahrt %d · Nachladen %s s" % [sim.level,sim.xp,sim.xp_required(),_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp)),_thousands(int(sim.player.shield)),_thousands(int(sim.player.max_shield)),sim.player.speed,("%.2f" % sim.reload_time()).replace(".",",")])
		_info("KANONEN · %d an Bord · %d Plätze · %d feuern je Salve" % [sim.player.cannons,sim.cannon_slots(),sim.equipped_cannons()],CYAN)
		var mounted: Array[String]=[]
		for slot in 2:
			var index=int(sim.deck_slots[slot])
			mounted.append("Platz %d: %s" % [slot+1,_deck_title(sim.decks[index]) if index>=0 else "frei"])
		if float(sim.buffs.tide_deck)>0:mounted.append("Gezeitendeck aktiv · %s" % _clock_text(float(sim.buffs.tide_deck)))
		_info("DECKS\n"+"\n".join(mounted))
		_info("VORRÄTE · Pulver %d · Platten %d · Notreparatur %d · Schildladung %d" % [sim.supplies.powder,sim.supplies.plates,sim.supplies.repair_kit,sim.supplies.shield_charge])
		_action("DECKS VERWALTEN",func():_open_modal("Decks"))
		_action("KASTELLE",func():_open_modal("Kastelle"))
		_action("SCHIFFSDESIGN WÄHLEN",func():_open_modal("Werft"))
		_action("BEWAFFNUNG",func():_open_modal("Bewaffnung"))
	elif kind=="Munition":
		modal_title.text="Munition & Gegenstände"
		_text(modal_body,"KANONENKUGEL-AUSWAHL",13,CYAN)
		for i in 3:
			var index=i
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);modal_body.add_child(row)
			_picture(row,icons[["cannonball","chain","harpoon"][i]],52)
			var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
			column.add_theme_constant_override("separation",2)
			var boost=" · ×1,4 mit Pulver" if i<2 else ""
			var label=_text(column,"%s · %d\n%d Schaden%s · %s" % [["Vollkugeln","Kettenkugeln","Harpunen"][i],sim.player.ammo[i],sim.weapon_damage(i),boost,["Gegen Schiffe und Türme","Verlangsamt Schiffe","Gegen Seeungeheuer"][i]],12,CYAN)
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var choose=_button(column,"GELADEN" if sim.ammo_mode==i else "LADEN",func():sim.set_ammo(index);modal.hide();_refresh_ui())
			choose.custom_minimum_size.y=28;choose.add_theme_font_size_override("font_size",11);choose.disabled=sim.ammo_mode==i or int(sim.player.ammo[i])<=0
		_text(modal_body,"GEGENSTÄNDE",13,CYAN)
		for key: String in CONTENT.SUPPLY_KEYS:
			var supply=key
			var config: Dictionary=CONTENT.SUPPLIES[key]
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);modal_body.add_child(row)
			_picture(row,painted[config.icon],52)
			var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
			column.add_theme_constant_override("separation",2)
			var label=_text(column,"%s · %d\n%s" % [config.name,sim.supplies[key],config.effect],12,CYAN)
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var active=(sim.powder_on if key=="powder" else sim.plates_on) if bool(config.toggle) else false
			var wait=float(sim.cooldowns.get(key,0.0))
			var text=("AUSSCHALTEN" if active else "EINSCHALTEN") if bool(config.toggle) else ("LÄDT %d s" % ceili(wait) if wait>0 else "EINSETZEN")
			var use=_button(column,text,func():_use_supply(supply);_open_modal("Munition"))
			use.custom_minimum_size.y=28;use.add_theme_font_size_override("font_size",11)
			use.disabled=sim.docked or wait>0 or (int(sim.supplies[key])<=0 and not active)
	elif kind=="Werft":
		_info("SCHIFFSDESIGNS · %d Karten, nach Namen sortiert." % skins.size(),CYAN)
		var order: Array[int]=[]
		for i in skins.size():order.append(i)
		order.sort_custom(func(a,b): return str(skins[a].name).naturalnocasecmp_to(str(skins[b].name))<0)
		var grid=GridContainer.new()
		grid.columns=2
		grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation",8)
		grid.add_theme_constant_override("v_separation",8)
		modal_body.add_child(grid)
		for raw in order:
			var index: int=raw
			var card=VBoxContainer.new()
			card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			card.add_theme_constant_override("separation",4)
			grid.add_child(card)
			var frame=Panel.new()
			frame.custom_minimum_size=Vector2(0,108)
			frame.clip_contents=true
			var frame_style=StyleBoxFlat.new()
			frame_style.bg_color=Color("071820")
			frame_style.border_color=CYAN if int(sim.player.skin)==index else Color("67583f")
			frame_style.set_border_width_all(1)
			frame_style.set_corner_radius_all(4)
			frame.add_theme_stylebox_override("panel",frame_style)
			card.add_child(frame)
			var preview=_portrait(frame)
			preview.texture=skin_previews[index]
			preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var equipped=int(sim.player.skin)==index
			var choose=_button(card,str(skins[index].name)+("\nAKTIV" if equipped else "\nAUSRÜSTEN"),func():_equip(index))
			choose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			choose.custom_minimum_size.y=46
			choose.add_theme_font_size_override("font_size",12)
			choose.disabled=equipped
		_text(modal_body,"MUNITIONSNACHSCHUB · Je 30 Gold",14,CYAN)
		for i in 3:
			var index =i
			var b =_button(modal_body,["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_refresh_ui())
			b.custom_minimum_size.y=48
	elif kind=="Bewaffnung":
		_info("BEWAFFNUNG · KANONEN & HARPUNEN",CYAN)
		_info("Bugkastell Stufe %d · Jagdkastell Stufe %d\n%d von %d Kanonen feuern · Breitseite: 3 Geschosse · Nachladen: %s Sekunden" % [sim.upgrades.cannon,sim.upgrades.harpoon,sim.equipped_cannons(),sim.player.cannons,("%.2f" % sim.reload_time()).replace(".",",")])
		for i in 3:
			var index=i
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);modal_body.add_child(row)
			_picture(row,icons[["cannonball","chain","harpoon"][i]],44)
			var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
			var label=_text(column,"%s · %d im Lager\n%d Schaden je Geschoss" % [["Vollkugeln","Kettenkugeln","Harpunen"][i],sim.player.ammo[i],sim.weapon_damage(i)],14,CYAN)
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var choose=_button(column,"GELADEN" if sim.ammo_mode==i else "LADEN",func():sim.set_ammo(index);_refresh_ui();_open_modal("Bewaffnung"))
			choose.custom_minimum_size.y=44;choose.disabled=sim.ammo_mode==i
		_info("Vollkugeln gegen Schiffe · Kettenkugeln bremsen Schiffe · Harpunen gegen Seeungeheuer")
		_action("AUSRÜSTUNG & NACHSCHUB IM HAFEN",func():_open_modal("Hafen"))
	elif kind=="Hafen":
		_info("PORT AZUR · AUSRÜSTUNG & VERSORGUNG" if sim.map_id==0 else "HAFEN · AUSRÜSTUNG & VERSORGUNG",CYAN)
		if not sim.has_harbor():
			_info("Bonuskarten haben keinen Hafen. Über BONUSKARTE VERLASSEN kehrst du zurück; die aktuelle Welle bleibt gespeichert.")
		elif not sim.docked:
			_info("Fahre zum goldenen Hafensymbol und docke an. Dein Schiff liegt dort geschützt; die Patrouillen fahren weiter. Distanz: %d m." % roundi(sim.player.pos.distance_to(sim.harbor)))
			_action("KURS ZUM HAFEN",func():sim.course(sim.harbor);modal.hide())
			var dock_button = _action("ANDOCKEN",func():
				if sim.dock():_save_progress();_open_modal("Hafen")
				_refresh_ui())
			dock_button.disabled=not sim.can_dock()
		else:
			_info("Kapitänsstufe %d · %s Gold · Rumpf %s / %s" % [sim.level,_thousands(int(sim.player.gold)),_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))])
			var repair_cost = sim.harbor_repair_cost()
			var repair_button = _action("TROCKENDOCK · %d Gold" % repair_cost,func():sim.harbor_repair();_save_progress();_open_modal("Hafen");_refresh_ui())
			repair_button.disabled=repair_cost<=0 or int(sim.player.gold)<repair_cost
			var built=0
			for key in CONTENT.UPGRADE_KEYS:built+=int(sim.upgrades[key])
			_action("KASTELLE · %d / %d STUFEN" % [built,CONTENT.UPGRADE_KEYS.size()*CONTENT.CASTLE_MAX],func():_open_modal("Kastelle"))
			_info("VORRÄTE",CYAN)
			for key: String in CONTENT.SUPPLY_KEYS:
				var supply=key
				var config: Dictionary=CONTENT.SUPPLIES[key]
				var buy=_action("%d× %s · %d Gold" % [config.pack,config.name,config.price],func():sim.buy_supply(supply);_save_progress();_open_modal("Hafen");_refresh_ui())
				buy.disabled=int(sim.player.gold)<int(config.price)
			_info("KANONEN · %d an Bord · %d Plätze" % [sim.player.cannons,sim.cannon_slots()],CYAN)
			var cannons=_action("2 KANONEN · %d Gold" % sim.cannon_price() if int(sim.player.cannons)<sim.MAX_CANNONS else "KANONENDECK VOLL",func():sim.buy_cannons();_save_progress();_open_modal("Hafen");_refresh_ui())
			cannons.disabled=int(sim.player.cannons)>=sim.MAX_CANNONS or int(sim.player.gold)<sim.cannon_price()
			_info("MUNITIONSNACHSCHUB",CYAN)
			for i in 3:
				var index = i
				var buy = _action(["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_open_modal("Hafen");_refresh_ui())
				buy.disabled=int(sim.player.gold)<30
			_action("DECKS & DECKWERFT",func():_open_modal("Decks"))
			_action("GEZEITENKESSEL",func():_open_modal("Kessel"))
			_action("SCHIFFSDESIGN WÄHLEN · %d DESIGNS" % skins.size(),func():_open_modal("Werft"))
			_action("ABLEGEN",func():sim.depart();modal.hide();_save_progress();_refresh_ui())
		if not sim.docked:_action("KASTELLE ANSEHEN",func():_open_modal("Kastelle"))
		_action("SEEKARTEN",func():_open_modal("Seekarten"))
		_action("UPDATES PRÜFEN",func():
			_save_progress()
			get_tree().set_meta("abyssal_manual_update",true)
			get_tree().change_scene_to_file("res://updater/launcher.tscn"))
	elif kind=="Logbuch":
		_info("KAPITÄNSLOGBUCH · AUFTRÄGE & FORTSCHRITT",CYAN)
		_info("Lv. %d · Erfahrung %d / %d · %d geborgene Kisten · %d besiegte Seeungeheuer" % [sim.level,sim.xp,sim.xp_required(),sim.loot_collected,sim.monster_kills])
		for i in CONTENT.QUESTS.size():
			var q: Dictionary = CONTENT.QUESTS[i]
			if i < sim.quest_index:
				_info("✓ "+str(q.name)+" · abgeschlossen",CYAN)
			elif i==sim.quest_index:
				_info("AKTIV · %s\n%s · %d/%d\nBelohnung: %d Gold und %d EP" % [q.name,q.description,mini(sim.quest_progress(),int(q.goal)),q.goal,q.gold,q.xp])
				var claim = _action("BELOHNUNG ABHOLEN",func():sim.claim_quest();_save_progress();_open_modal("Logbuch");_refresh_ui())
				claim.disabled=sim.quest_progress()<int(q.goal)
			else:
				_info("%d · %s\n%s" % [i+1,q.name,q.description],Color("84999c"))
		_info("LETZTE MELDUNGEN",CYAN)
		var recent=message_history.duplicate();recent.reverse()
		_info("\n".join(recent) if not recent.is_empty() else "Noch keine Meldungen",Color("bac7c7"))
	elif kind=="Rangliste":
		var ranks=["Schiffsjunge","Matrose","Bootsmann","Steuermann","Leutnant","Kapitän","Kommodore","Admiral"]
		_info("KAPITÄNSRANG · %s" % ranks[clampi(floori((sim.level-1)/2.5),0,ranks.size()-1)].to_upper(),CYAN)
		_info("Kapitänsstufe %d · Erfahrung %s / %s\nGold %s\nVersenkte Schiffe %d · davon Elite %d\nSeeungeheuer %d · Beutekisten %d\nAufträge %d / %d · Seegebiete %d / %d" % [sim.level,_thousands(sim.xp),_thousands(sim.xp_required()),_thousands(int(sim.player.gold)),sim.kills,sim.elite_kills,sim.monster_kills,sim.loot_collected,mini(sim.quest_index,CONTENT.QUESTS.size()),CONTENT.QUESTS.size(),sim.visited.count(true),CONTENT.REGION_COUNT])
		_info("Bonuskarten geschafft %d · Kesselwürfe %d\nZerstörte Türme %d · Festungseroberungen %d\nGilde %s" % [sim.bonus_runs,sim.kessel_throws,sim.tower_kills,sim.fortress_conquests,"[%s] %s" % [sim.guild.tag,sim.guild.name] if not sim.guild.is_empty() else "keine"])
		_info("Diese Rangliste zählt deinen Fortschritt auf diesem Gerät. Ranglisten gegen andere Kapitäne und Gilden kommen mit dem Online-Server.",Color("84999c"))
	elif kind=="Decks":
		_open_decks()
	elif kind=="Kastelle":
		_info("KASTELLE · DAUERHAFTE HAFENAUSBAUTEN",CYAN)
		_info("Sechs Kastelle mit je %d Stufen. Stufe 1 bis 3 sind sofort offen, danach kommt alle drei Kapitänsstufen eine weitere hinzu. Aktuell offen: bis Stufe %d." % [CONTENT.CASTLE_MAX,sim.castle_cap()])
		if not sim.docked:_info("Ausbauen kannst du nur angedockt im Hafen.",Color("edc68c"))
		for key in CONTENT.UPGRADE_KEYS:_upgrade_row(str(key))
	elif kind=="Kessel":
		_open_kessel()
	elif kind=="Bonuskarten":
		_open_bonus()
	elif kind=="Gilde":
		_open_guild()
	elif kind=="Seekarten":
		_info("DREI SEEGEBIETE · PORTALE VERBINDEN DIE SEEKARTEN",CYAN)
		for i in CONTENT.REGION_COUNT:
			var region: Dictionary = CONTENT.MAPS[i]
			var index = i
			var locked = sim.level<int(region.level)
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation",12)
			modal_body.add_child(row)
			_picture(row,extra_icons.world_chart,64)
			var column = VBoxContainer.new()
			column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			row.add_child(column)
			var label = _text(column,"%s · %s\nAb Lv. %d · %s" % [region.code,region.name,region.level,"Feindliche Patrouillen" if region.npc_hostile else "Neutrale Patrouillen · Gegenwehr bei Angriff"],14,CYAN)
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var text = "DU BIST HIER" if i==sim.map_id else ("GESPERRT · LV. %d" % region.level if locked else ("PORTAL BETRETEN" if sim.near_portal()==i else "KURS ZUM PORTAL"))
			var travel_button = _button(column,text,func():_navigate_region(index))
			travel_button.custom_minimum_size.y=44
			travel_button.disabled=i==sim.map_id or locked or sim.docked or sim.in_bonus_map()
		_info("Tippe auf ein Portal oder auf KURS ZUM PORTAL. Dein Schiff fährt hin und wechselt beim Erreichen automatisch. Levelgrenzen bleiben gültig; nach einem Treffer wartet das Portal 6 Sekunden. Im Hafen zuerst ablegen.")
		_info("BONUSKARTEN · Bronzeriff B-1, Silberbucht B-2 und Goldene Lagune B-3 öffnest du mit Schriftrollen.",CYAN)
		_action("BONUSKARTEN",func():_open_modal("Bonuskarten"))
		_action("STEUERUNG & SPIELINFO",func():_open_modal("Spielinfo"))
	elif kind=="Anzeige":
		_info("DEINE SEEKARTE · DEINE OBERFLÄCHE",CYAN)
		_info("Wähle die Größe für Anzeigen, Karte und Kampfbuttons. Die Spielwelt behält ihre eigene Zoomstufe. Deine Auswahl bleibt auf diesem Gerät gespeichert.")
		for i in 3:
			var index=i
			var choice=_action((["KOMPAKT · mehr freie Seekarte","KOMFORT · größere Anzeigen","GROSS · beste Lesbarkeit"][i])+("   ✓" if hud_size==i else ""),func():_set_display(index,journal_visible))
			choice.disabled=hud_size==i
		_action("AUFTRAGSLEISTE: "+("EIN" if journal_visible else "AUS"),func():_set_display(hud_size,not journal_visible))
		_action("JOYSTICK: "+("EIN" if camera_pad_visible else "AUS"),func():camera_pad_visible=not camera_pad_visible;_set_display(hud_size,journal_visible))
		_info("Die Auftragsleiste oben links öffnet das Logbuch. Der Joystick bewegt nur die Kamera: Seekarte erkunden, das Schiff hält seinen Kurs. Gefahren wird per Antippen. Fadenkreuz an der Karte: zurück zum Schiff. Fernrohr: nächstes sichtbares Ziel.")
		_action("STANDARD WIEDERHERSTELLEN",func():camera_pad_visible=true;_set_display(1,true))
	else:
		_action("SEEKARTEN",func():_open_modal("Seekarten"))
		_action("KASTELLE",func():_open_modal("Kastelle"))
		_action("ANZEIGE & HUD ANPASSEN",func():_open_modal("Anzeige"))
		_action("UPDATES PRÜFEN",func():_save_progress();get_tree().set_meta("abyssal_manual_update",true);get_tree().change_scene_to_file("res://updater/launcher.tscn"))
		var info =_text(modal_body,"ABYSSAL DOMINION · STEUERUNG\n\nTippe auf freies Wasser zum Fahren.\nTippe auf ein Schiff und anschließend FEUER.\nVoll- und Kettenkugeln wirken gegen Schiffe und Türme, Harpunen gegen Seeungeheuer.\nFahre über Beute, um Gold einzusammeln, und durch glitzernde Strömungen für Gezeitenessenz.\n\nRUMPF & SCHILD: Der Schild fängt Treffer zuerst ab und lädt sich 8 Sekunden nach dem letzten Treffer wieder auf. REP repariert den Rumpf ohne Gegenstand.\nSCHNELLLEISTE: Pulver schaltet +40 % Salvenschaden ein und verbraucht nur bei einer gültigen Salve. Der Pfeilknopf wechselt zu Notreparatur, Schildladung und Panzerplatten.\n\nHAFEN: Trockendock, Vorräte, Kanonen, Decks und Kastelle.\nKESSEL: Gezeitenessenz einwerfen, offene Preistabelle, Meilensteine bei 10, 25, 50 und 100.\nBONUSKARTEN: Fragmente zu Schriftrollen zusammensetzen, fünf Wellen mit Checkpoint.\nGILDE: Kürzel vor dem Schiffsnamen, Korsarenfestung mit vier Türmen in den Schattengewässern.\n\nZwei Finger / Mausrad / Plus und Minus an der Karte: Zoom. Joystick links unten oder Ziehen / rechte Maustaste: Kamera. Fernrohr / Tab: nächstes Ziel. Tasten 1 bis 3 Munition, 4 bis 7 Gegenstände, Q Schnellleiste.\n\nGastfortschritt wird auf diesem Gerät gespeichert. Lokales Spiel; noch kein öffentlicher MMO-Server.",15)
		info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size.y=300
	modal_body.size.x=modal_scroll.size.x
	modal_body.queue_sort()
	modal.show()
	modal_backdrop.show()
	modal_scroll.set_deferred("scroll_vertical",scroll_position)

func _info(text: String,color: Color=GOLD) -> Label:
	var label = _text(modal_body,text,16,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _action(text: String,callback: Callable) -> Button:
	var button = _button(modal_body,text,callback)
	button.custom_minimum_size.y=50
	button.add_theme_font_size_override("font_size",16)
	return button

func _picture(parent: Node,texture: Texture2D,width: float) -> void:
	var picture = TextureRect.new()
	picture.texture=texture
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=Vector2(width,width)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)

func _upgrade_row(key: String) -> void:
	var config: Dictionary=CONTENT.UPGRADES[key]
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	modal_body.add_child(row)
	var art_key = key+"_%d" % mini(2,int(sim.upgrades[key])) if key in ["cannon","harpoon"] else str(config.icon)
	_picture(row,_art(art_key),80)
	var column = VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var stage=int(sim.upgrades[key])
	var label = _text(column,"%s · %s · Stufe %d/%d\n%s" % [config.name,config.role,stage,CONTENT.CASTLE_MAX,config.effect],14,CYAN)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var cost: int=sim.upgrade_cost(key)
	var gated=cost>=0 and stage>=sim.castle_cap()
	var text="MAXIMALE STUFE" if cost<0 else ("AB KAPITÄNSSTUFE %d" % ((stage-2)*3) if gated else "VERBESSERN · %d Gold" % cost)
	var button = _button(column,text,func():sim.buy_upgrade(key);_save_progress();_open_modal("Kastelle");_refresh_ui())
	button.custom_minimum_size.y=44
	button.disabled=cost<0 or gated or not sim.docked or int(sim.player.gold)<cost

func _deck_title(deck: Dictionary) -> String:
	return "%s %s" % [CONTENT.DECKS[str(deck.type)].name,CONTENT.DECK_TIERS[int(deck.tier)]]

func _deck_effect(deck: Dictionary) -> String:
	var config: Dictionary=CONTENT.DECKS[str(deck.type)]
	return str(config.effect) % int(config.values[int(deck.tier)])

func _banner(texture: Texture2D,height: float) -> void:
	var frame=TextureRect.new()
	frame.texture=texture
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.custom_minimum_size=Vector2(0,height)
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.clip_contents=true
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal_body.add_child(frame)

func _row(texture: Texture2D,text: String,size: float=64.0) -> VBoxContainer:
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);modal_body.add_child(row)
	if texture!=null:_picture(row,texture,size)
	var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
	column.add_theme_constant_override("separation",4)
	var label=_text(column,text,14,CYAN);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return column

func _row_button(parent: Node,text: String,callback: Callable,disabled: bool=false) -> Button:
	var button=_button(parent,text,callback)
	button.custom_minimum_size.y=40
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.disabled=disabled
	return button

const DECK_ART := {"cannon":"cannon_1","armor":"upgrade_hull","hunter":"harpoon_1","navigation":"upgrade_sails","logistics":"castle_crew"}

func _open_decks() -> void:
	_info("DECKS · ZWEI DECKPLÄTZE · JEDER TYP NUR EINMAL",CYAN)
	for slot in 2:
		var place=slot
		var index=int(sim.deck_slots[slot])
		if index<0:
			_info("Platz %d · frei" % (slot+1),Color("bac7c7"))
			continue
		var column=_row(_art(DECK_ART[str(sim.decks[index].type)]),"Platz %d · %s\n%s" % [slot+1,_deck_title(sim.decks[index]),_deck_effect(sim.decks[index])],52)
		_row_button(column,"ABBAUEN",func():sim.unequip_deck(place);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked)
	var tide=float(sim.buffs.tide_deck)
	_row(painted.tide_deck,"GEZEITENDECK · "+("aktiv %s · +10 Kanonenplätze" % _clock_text(tide) if tide>0 else "nicht aktiv · aus Gezeitenkessel und Meilensteinen"),52)
	if not sim.docked:_info("Decks werden angedockt im Hafen umgebaut.",Color("edc68c"))
	_info("DECKLAGER · %d DECKS" % sim.decks.size(),CYAN)
	if sim.decks.is_empty():_info("Noch keine Decks. Stufe I gibt es in der Deckwerft, höhere Stufen aus Bonuskarten und dem Kessel.",Color("bac7c7"))
	for i in sim.decks.size():
		var index=i
		var deck: Dictionary=sim.decks[i]
		var column=_row(_art(DECK_ART[str(deck.type)]),"%s\n%s" % [_deck_title(deck),_deck_effect(deck)],52)
		var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",6);column.add_child(buttons)
		for slot in 2:
			var place=slot
			var here=int(sim.deck_slots[slot])==i
			_row_button(buttons,("MONTIERT %d" if here else "PLATZ %d") % (slot+1),func():sim.equip_deck(index,place);_save_progress();_open_modal("Decks");_refresh_ui(),here or not sim.docked)
	if sim.docked:
		_info("DECKWERFT · STUFE I",CYAN)
		for key: String in CONTENT.DECK_KEYS:
			var type=key
			var config: Dictionary=CONTENT.DECKS[key]
			var owned=sim.owns_deck(key,0)
			var buy=_action(("%s I · VORHANDEN" if owned else "%s I · %d Gold") % ([config.name] if owned else [config.name,config.price]),func():sim.buy_deck(type);_save_progress();_open_modal("Decks");_refresh_ui())
			buy.disabled=owned or int(sim.player.gold)<int(config.price)
	_info("Doppelte Decks werden automatisch in %d Gezeitenessenz umgewandelt." % CONTENT.DUPLICATE_DECK_ESSENCE,Color("bac7c7"))

func _open_kessel() -> void:
	modal_title.text="Gezeitenkessel"
	_banner(painted.kessel_scene,150)
	_info("GEZEITENESSENZ · %d" % sim.essence,CYAN)
	var today=Time.get_date_string_from_system()
	if not sim.docked:
		_info("Der Kessel steht im Hafen. Essenz sammelst du auf See: glitzernde Strömungen, versenkte Gegner, Aufträge, Bonuskarten und die Korsarenfestung.",Color("edc68c"))
	var flask=_action("TAGESFLASCHE · KOSTENLOS" if sim.free_flask_ready(today) else "TAGESFLASCHE · MORGEN WIEDER",func():_kessel_results(sim.claim_free_flask(today)))
	flask.disabled=not sim.docked or not sim.free_flask_ready(today)
	var throws=HBoxContainer.new();throws.add_theme_constant_override("separation",6);modal_body.add_child(throws)
	for amount: int in CONTENT.KESSEL_THROWS:
		var count=amount
		var button=_row_button(throws,"×%d" % amount,func():_kessel_results(sim.throw_kessel(count,today)),not sim.docked or sim.essence<amount)
		button.custom_minimum_size.y=46
		button.add_theme_font_size_override("font_size",16)
	var meter=_bar(modal_body)
	meter.max_value=CONTENT.KESSEL_CYCLE;meter.value=sim.kessel_meter;meter.custom_minimum_size.y=16
	var meter_style: StyleBoxFlat=meter.get_theme_stylebox("fill").duplicate();meter_style.bg_color=Color("3fc7b8");meter.add_theme_stylebox_override("fill",meter_style)
	var steps: Array[String]=[]
	for milestone: Dictionary in CONTENT.KESSEL_MILESTONES:
		steps.append("%s %d: %s" % ["✓" if sim.kessel_meter>=int(milestone.at) else "·",milestone.at,milestone.name])
	_info("KESSELMETER · %d / %d\n%s" % [sim.kessel_meter,CONTENT.KESSEL_CYCLE,"\n".join(steps)])
	if not kessel_log.is_empty():
		_info("LETZTE WÜRFE",CYAN)
		var recent=kessel_log.duplicate();recent.reverse()
		_info("\n".join(PackedStringArray(recent.slice(0,8))),Color("e2ecee"))
	_info("PREISTABELLE · offen einsehbar",CYAN)
	var table: Array[String]=[]
	for entry: Dictionary in CONTENT.KESSEL_POOL:
		var pack=" ×%d" % int(entry.amount) if int(entry.amount)>1 and str(entry.id)!="tide_deck" else ""
		table.append("%d %% · %s%s · %s" % [entry.weight,entry.name,pack,CONTENT.RARITIES[int(entry.rarity)]])
	_info("\n".join(table),Color("bac7c7"))
	_info("Doppelte Decks werden in %d Essenz umgewandelt. Essenz gibt es nur im Spiel, nicht gegen Echtgeld." % CONTENT.DUPLICATE_DECK_ESSENCE,Color("84999c"))

func _kessel_results(results: Array) -> void:
	for result: Dictionary in results:
		kessel_log.append("%s%s · %s" % ["★ " if bool(result.get("milestone",false)) else "",result.text,CONTENT.RARITIES[clampi(int(result.rarity),0,3)]])
	while kessel_log.size()>24:kessel_log.pop_front()
	_save_progress()
	_open_modal("Kessel")
	_refresh_ui()

func _open_bonus() -> void:
	_info("BONUSKARTEN · FÜNF WELLEN · CHECKPOINT NACH JEDER WELLE",CYAN)
	_info("Schriftrollenfragmente %d · Schriftrollen: Bronze %d · Silber %d · Gold %d\nAbgeschlossene Bonuskarten %d" % [sim.fragments,sim.scrolls[0],sim.scrolls[1],sim.scrolls[2],sim.bonus_runs])
	if not sim.bonus.is_empty():
		var tier: Dictionary=CONTENT.BONUS_TIERS[int(sim.bonus.tier)]
		var done=str(sim.bonus.state)=="done"
		var text="%s-BONUSKARTE · %s" % [str(tier.name).to_upper(),"GESCHAFFT" if done else "WELLE %d/%d" % [mini(int(sim.bonus.wave)+1,CONTENT.BONUS_WAVES.size()),CONTENT.BONUS_WAVES.size()]]
		if done and sim.bonus.has("chest"):text+="\nTruhe: "+str(sim.bonus.chest)
		var column=_row(painted.reward_chest if done else painted.boss_wave,text,64)
		if sim.in_bonus_map():_row_button(column,"BONUSKARTE VERLASSEN",func():modal.hide();_interact())
	for i in CONTENT.BONUS_TIERS.size():
		var index=i
		var tier: Dictionary=CONTENT.BONUS_TIERS[i]
		var region: Dictionary=CONTENT.MAPS[int(tier.map)]
		var running=not sim.bonus.is_empty() and int(sim.bonus.tier)==i
		var column=_row(painted.scroll_fragment,"%s-SCHRIFTROLLE · %s %s\nAb Lv. %d · Gegnerstärke ×%s · %d Fragmente" % [str(tier.name).to_upper(),region.name,region.code,tier.level,str(region.enemy_scale).replace(".",","),tier.fragments],64)
		var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",6);column.add_child(buttons)
		_row_button(buttons,"ZUSAMMENSETZEN",func():sim.craft_scroll(index);_save_progress();_open_modal("Bonuskarten");_refresh_ui(),sim.fragments<int(tier.fragments))
		var blocked=sim.in_bonus_map() or sim.level<int(tier.level) or (not running and (int(sim.scrolls[i])<=0 or not sim.bonus.is_empty()))
		_row_button(buttons,"FORTSETZEN" if running else ("AB LV. %d" % tier.level if sim.level<int(tier.level) else "STARTEN"),func():_start_bonus(index),blocked)
	_info("WELLEN · 1 Eröffnung · 2 Druck · 3 Elite · 4 Admiral · 5 Leviathan",CYAN)
	_info("Jede Welle zahlt Gold und 1 Gezeitenessenz. Die Truhe am Ende enthält Pulver, Platten, eine Notreparatur, einen Kristallsegen und ein Deck der Kartenstufe.\nKein Lebenssystem: Wirst du versenkt, geht es nach 8 Sekunden an derselben Welle weiter. Verlassen speichert die aktuelle Welle.")
	_info("Fragmente gibt es aus dem Kessel und der Korsarenfestung.",Color("84999c"))

func _start_bonus(tier: int) -> void:
	if sim.docked:sim.depart()
	sim.start_bonus(tier)
	if previous_region!=sim.map_id:_sync_region()
	else:_open_modal("Bonuskarten")
	_refresh_ui()

func _line_edit(placeholder: String,limit: int) -> LineEdit:
	var field=LineEdit.new()
	field.placeholder_text=placeholder
	field.max_length=limit
	field.custom_minimum_size.y=44
	field.add_theme_font_size_override("font_size",16)
	field.add_theme_color_override("font_color",Color("f3e0b6"))
	var skin=StyleBoxFlat.new();skin.bg_color=Color("0b1d26");skin.border_color=Color("67583f");skin.set_border_width_all(1);skin.set_corner_radius_all(4);skin.set_content_margin_all(8)
	field.add_theme_stylebox_override("normal",skin)
	var focus=skin.duplicate();focus.border_color=GOLD
	field.add_theme_stylebox_override("focus",focus)
	modal_body.add_child(field)
	return field

func _open_guild() -> void:
	_info("GILDE · LOKALE VORSCHAU",CYAN)
	_info("Gilden laufen in dieser Version lokal auf deinem Gerät. Mitglieder, Gildenchat und Gildenkriege kommen mit dem Online-Server.",Color("84999c"))
	if sim.guild.is_empty():
		_info("Gründe deine Gilde für %d Gold. Das Kürzel steht vor deinem Schiffsnamen und auf gehaltenen Türmen." % CONTENT.GUILD_COST)
		guild_name_input=_line_edit("Gildenname · 3 bis 24 Zeichen",24)
		guild_tag_input=_line_edit("Kürzel · 2 bis 4 Buchstaben oder Ziffern",4)
		var found=_action("GILDE GRÜNDEN · %d Gold" % CONTENT.GUILD_COST,func():
			sim.found_guild(guild_name_input.text,guild_tag_input.text)
			_save_progress();_open_modal("Gilde");_refresh_ui())
		found.disabled=int(sim.player.gold)<CONTENT.GUILD_COST
	else:
		_info("[%s] %s · Anführer: du (lokal)" % [sim.guild.tag,sim.guild.name],Color("ffd27a"))
	_info("GILDENINSEL · KORSARENFESTUNG",CYAN)
	var towers=HBoxContainer.new();towers.add_theme_constant_override("separation",6);modal_body.add_child(towers)
	for config: Dictionary in CONTENT.TOWERS:_picture(towers,painted["tower_"+str(config.kind)],64)
	var state=""
	if sim.guild_island_held():state="[%s] hält die Insel noch %s · +10 %% Beutegold · die Türme feuern nicht auf dich" % [sim.guild.tag,_clock_text(sim.fortress_hold)]
	elif sim.map_id==CONTENT.FORTRESS_MAP:state="Gehalten von [%s] · %d von %d Türmen stehen" % [CONTENT.FORTRESS_TAG,sim.towers_alive(),CONTENT.TOWERS.size()]
	else:state="Schattengewässer %s · ab Lv. %d · gehalten von [%s]" % [CONTENT.MAPS[CONTENT.FORTRESS_MAP].code,CONTENT.MAPS[CONTENT.FORTRESS_MAP].level,CONTENT.FORTRESS_TAG]
	_info(state)
	_info("Kanonenturm: Doppelschuss · Mörserturm: weite Bögen · Kettenturm: bremst · Wächterturm: lädt die Schilde der anderen Türme. Zerstöre alle vier für +900 Gold, +3 Essenz und +2 Fragmente. Mit Gilde hältst du die Insel 30 Minuten.",Color("bac7c7"))
	_info("Eroberungen %d · zerstörte Türme %d" % [sim.fortress_conquests,sim.tower_kills])
	if sim.map_id==CONTENT.FORTRESS_MAP:
		var course=_action("KURS ZUR FESTUNG",func():
			var island: Dictionary=sim.fortress_island()
			sim.course(Vector2(island.bounds.get_center().x,island.bounds.end.y+140))
			modal.hide();_refresh_ui())
		course.disabled=sim.docked
	else:
		var travel=_action("KURS SCHATTENGEWÄSSER",func():_navigate_region(CONTENT.FORTRESS_MAP))
		travel.disabled=sim.docked or sim.in_bonus_map() or sim.level<int(CONTENT.MAPS[CONTENT.FORTRESS_MAP].level)
	if not sim.guild.is_empty():_action("GILDE AUFLÖSEN",func():sim.leave_guild();_save_progress();_open_modal("Gilde");_refresh_ui())

func _sync_region() -> void:
	previous_region=sim.map_id
	modal.hide()
	_recenter_camera();camera.position=sim.player.pos
	_save_progress();_refresh_ui()
	_begin_loading(1.1)

func _navigate_region(destination: int) -> void:
	sim.request_portal(destination)
	if previous_region!=sim.map_id:_sync_region()
	modal.hide();_refresh_ui()

func _chart_course(point: Vector2) -> void:
	for portal in sim.portals:
		if point.distance_to(portal.pos)<120:
			_navigate_region(int(portal.destination));return
	sim.course(point);_refresh_ui()

func _interact() -> void:
	if sim.in_bonus_map():
		sim.leave_bonus()
		if previous_region!=sim.map_id:_sync_region()
	elif sim.docked:
		sim.depart()
		modal.hide()
	elif sim.near_portal()>=0:
		_navigate_region(sim.near_portal())
	elif sim.pending_portal>=0:
		sim.pending_portal=-1;sim.player.path=[];sim.message="Portalkurs abgebrochen"
	elif sim.can_dock():
		if sim.dock():_open_modal("Hafen")
	else:
		sim.course(sim.harbor)
	_save_progress()
	_refresh_ui()

func _equip(index: int) -> void:
	sim.player.skin=index
	sim.message="Schiffsdesign ausgerüstet: "+str(skins[index].name)
	_save_progress()
	_open_modal("Werft")
	_refresh_ui()

func _zoom(factor: float) -> void:
	desired_zoom=clampf(desired_zoom*factor,0.5,1.4)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch_ms=Time.get_ticks_msec()
		if event.pressed:
			if _hud_contains(event.position):hud_touches[event.index]=true;return
			touch_points[event.index]=event.position
			if touch_points.size()==1:drag_start=event.position;dragging=false
			if touch_points.size()>1:suppress_tap_until=Time.get_ticks_msec()+400
		else:
			if hud_touches.has(event.index):hud_touches.erase(event.index);return
			if touch_points.size()==1 and not dragging and Time.get_ticks_msec()>suppress_tap_until and not _hud_contains(event.position):
				_tap(event.position)
			touch_points.erase(event.index)
			pinch_distance=0
			suppress_tap_until=Time.get_ticks_msec()+180
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if hud_touches.has(event.index):return
		touch_points[event.index]=event.position
		if touch_points.size()>=2:
			var values =touch_points.values()
			var distance: float=values[0].distance_to(values[1])
			if pinch_distance>0:_zoom(distance/pinch_distance)
			pinch_distance=distance
			dragging=true
		elif event.position.distance_to(drag_start)>20:
			dragging=true
			_shift_camera(-event.relative/camera.zoom)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:_zoom(1.10)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:_zoom(1/1.10)
		elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Time.get_ticks_msec()-last_touch_ms>350:
			_tap(event.position)
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			dragging=event.pressed
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_shift_camera(-event.relative/camera.zoom)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_TAB:_cycle_target();get_viewport().set_input_as_handled()
		if event.keycode==KEY_SPACE:_toggle_fire()
		if event.keycode==KEY_ESCAPE:modal.hide()
		if event.keycode==KEY_R:sim.toggle_repair()
		if event.keycode==KEY_1:sim.set_ammo(0)
		if event.keycode==KEY_2:sim.set_ammo(1)
		if event.keycode==KEY_3:sim.set_ammo(2)
		var hotkeys=[KEY_4,KEY_5,KEY_6,KEY_7]
		if event.keycode in hotkeys:_use_supply(CONTENT.SUPPLY_KEYS[hotkeys.find(event.keycode)])
		if event.keycode==KEY_Q:_flip_page()

func _hud_contains(screen: Vector2) -> bool:
	if modal.visible:return true
	var controls: Array[Control]=[chrome,target_panel,chart_mini,quest_panel,attack,repair,ammo_selector,loadout_button,center_button,settings_button,target_cycle,camera_pad,zoom_in,zoom_out,interact,page_button]
	controls.append_array(ammo_buttons)
	for item: Button in supply_buttons.values():controls.append(item)
	for control: Control in controls:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen):return true
	return false

func _tap(screen: Vector2) -> void:
	if modal.visible or loading_left>0:return
	var point: Vector2=get_canvas_transform().affine_inverse()*screen
	for portal in sim.portals:
		if point.distance_to(portal.pos)<=maxf(85,45/camera.zoom.x):
			_navigate_region(int(portal.destination));return
	var nearest =-1
	var distance =82.0/camera.zoom.x
	for npc in sim.npcs:
		if int(npc.hp)<=0:continue
		var d: float=point.distance_to(npc.pos-Vector2(0,25))
		if d<distance:distance=d;nearest=int(npc.id)
	if nearest>0:
		sim.select(nearest)
	else:
		sim.course(point)
	_refresh_ui()

func _save_progress() -> void:
	var data: Dictionary=sim.export_save()
	var file =FileAccess.open(SAVE,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(data));file.close()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE):return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:sim.restore_save(data)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_WM_CLOSE_REQUEST]:
		if camera_pad!=null:camera_pad.release()
		if camera!=null:_save_progress()

func _load_display() -> void:
	if not FileAccess.file_exists(HUD_SAVE):return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(HUD_SAVE))
	if not data is Dictionary:return
	hud_size=clampi(int(data.get("hud_size",1)),0,2)
	journal_visible=bool(data.get("journal_visible",true))
	camera_pad_visible=bool(data.get("camera_pad_visible",true))

func _set_display(size_index: int,show_journal: bool) -> void:
	hud_size=clampi(size_index,0,2)
	journal_visible=show_journal
	var file=FileAccess.open(HUD_SAVE,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"hud_size":hud_size,"journal_visible":journal_visible,"camera_pad_visible":camera_pad_visible}))
		file.close()
	_layout()
	_open_modal("Anzeige")
	_refresh_ui()

func _pan_camera(direction: Vector2,delta: float) -> void:
	if direction==Vector2.ZERO:return
	_shift_camera(direction*620.0*maxf(delta,0.0)/camera.zoom)

func _shift_camera(offset: Vector2) -> void:
	if camera_locked:camera_anchor=sim.player.pos+pan
	camera_locked=false
	camera_anchor=(camera_anchor+offset).clamp(Vector2.ZERO,sim.WORLD)
	pan=camera_anchor-sim.player.pos

func _recenter_camera() -> void:
	pan=Vector2.ZERO;camera_locked=true;camera_anchor=sim.player.pos
	if camera_pad!=null:camera_pad.release()

func _cycle_target() -> void:
	if modal.visible:return
	var candidates: Array[int]=[]
	var viewport=get_viewport_rect().grow(-8)
	for npc: Dictionary in sim.npcs:
		if float(npc.hp)<=0:continue
		var screen: Vector2=get_canvas_transform()*npc.pos
		if viewport.has_point(screen) and not _hud_contains(screen):candidates.append(int(npc.id))
	candidates.sort()
	if candidates.is_empty():
		sim.message="Kein Ziel im sichtbaren Bereich"
	else:
		var index=candidates.find(sim.target)
		sim.firing=false
		sim.select(candidates[(index+1)%candidates.size()])
	_refresh_ui()

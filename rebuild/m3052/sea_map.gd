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
const SKIN = preload("res://ui_skin.gd")
const TOUCH_SCROLL = preload("res://touch_scroll.gd")
const ORNATE = preload("res://ornate_frame.gd")
const SEA_MARKS = preload("res://sea_marks.gd")
const KESSEL_FX = preload("res://kessel_fx.gd")
const WORLD_CHART = preload("res://world_chart.gd")
const CHART_GUIDE = preload("res://chart_guide.gd")
const AMMO_CHOICE=preload("res://ammo_choice.gd")
const CAPTAIN_PLATE_OFFSET := 62.0
const OTHER_PLATE_OFFSET := 48.0
const CAPTAIN_HULL_CLEARANCE := 34.0
const NPC_HULL_CLEARANCE := 24.0
const PLATE_ID_BASELINE := 13.0
const PLATE_HP_Y := 24.0
const PLATE_SHIELD_Y := 35.0
const PLATE_DECK_Y := 65.0
const SHOT_COLORS := {"flare":Color("ffe27a"),"pumpkin":Color("ff8a2a"),"snow":Color("f4fbff"),"ice":Color("7fd4ff"),"chain":Color("d7e4ea"),"harpoon":Color("9fd0c8")}
const USER_ROOT := "res://assets/user/"
const SAVE := "user://captain_m3052.json"
const HUD_SAVE := "user://display_m3052.json"
const STAFF_SAVE := "user://staff_m3052.json"
const RARITY_INK := [Color("d6e2e4"),Color("4fc3ff"),Color("c69bff"),Color("ffc04d")]
const GOLD := Color("dcc18a")
const CYAN := Color("80e3dc")
const ROMAN := ["","I","II","III","IV","V","VI","VII","VIII","IX","X"]
var sim := SIM.new()
var camera: Camera2D
var water: ColorRect
var ocean: ShaderMaterial
var ui: Control
var chart_mini: Control
var desired_zoom := 1.08
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
var ammo_rows: Array[Button] = []
const AMMO_UI := [
	{"name":"Vollkugeln","use":"Gegen Schiffe und Türme","icon":"cannonball"},
	{"name":"Kettenkugeln","use":"Verlangsamt Schiffe","icon":"chain"},
	{"name":"Harpunen","use":"Gegen Seeungeheuer","icon":"harpoon"},
	{"name":"Leuchtkugeln","use":"Markiert das Ziel · Folgetreffer +15 %","icon":"ammo_flare"},
	{"name":"Kürbismunition","use":"Splitter im Umkreis","icon":"ammo_pumpkin"},
	{"name":"Schneemunition","use":"Starke Verlangsamung","icon":"ammo_snow"},
	{"name":"Eismunition","use":"Friert das Ziel kurz ein","icon":"ammo_ice"}
]
var nav_buttons: Array[Button] = []
var quest_panel: Panel
var quest_text: Label
var quest_claim: Button
var modal: ORNATE
var modal_title: Label
var modal_close: Button
var modal_scroll: TOUCH_SCROLL
var modal_body: VBoxContainer
var modal_tabs: HBoxContainer
var modal_tab := {}
var scroll_hint: Control
var modal_scroll_box := Rect2()
var modal_kind := ""
var kessel_throw: Dictionary = {}
var staff_pill: Button
var staff_code_input: LineEdit
var chart_pick := -1
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
var plate_rects: Dictionary = {}
var status_age := 0.0
var ammo_previews: Dictionary = {}

func _ready() -> void:
	# The edge HUD is scaled on high-DPI phones. MSDF prevents magnifying
	# small raster glyphs along with it; world labels share the same crisp font.
	if font is FontFile:
		font.multichannel_signed_distance_field=true
		font.msdf_pixel_range=16
		font.msdf_size=48
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_use_uhd()
	_load_assets()
	_load_progress()
	_load_staff()
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

## One screen pixel is one drawn pixel. Desktop opens at 3840×2160. Phones use the
## device resolution instead of stretching a 1280×720 picture. Tests that clear the
## content scale keep the size they chose.
func _use_uhd() -> void:
	if OS.has_feature("web"):return
	var window := get_window()
	if window == null or window.content_scale_size == Vector2i.ZERO:return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.content_scale_size = Vector2i.ZERO
	if OS.has_feature("mobile"):return
	var uhd := Vector2i(3840, 2160)
	window.size = uhd
	var screen := DisplayServer.screen_get_size()
	if screen.x >= uhd.x and screen.y >= uhd.y:
		window.position = (screen - uhd) / 2

func _sharp_zoom() -> float:
	return desired_zoom * clampf(get_viewport_rect().size.y / 720.0, 1.0, 1.7)

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
			"crystal_blessing","tide_deck","castle_crew","castle_war","boss_wave","reward_chest","tower_cannon","tower_mortar","tower_chain","tower_guardian",
			"staff_seal","staff_teleport","staff_dummy","staff_ledger","ammo_flare","ammo_pumpkin","ammo_snow","ammo_ice"]:
		painted[name]=load("res://assets/ui/painted/"+name+".png")
	painted.loading=load("res://assets/ui/painted/loading_harbor.jpg")
	painted.kessel_scene=load("res://assets/ui/painted/kessel_scene.jpg")
	painted.chart_parchment=load("res://assets/ui/painted/chart_parchment.jpg")

func _art(name: String) -> Texture2D:
	return extra_icons[name] if extra_icons.has(name) else painted.get(name)

func _process(delta: float) -> void:
	status_age += delta
	if modal_backdrop!=null:modal_backdrop.visible=modal.visible
	if modal.visible:scroll_hint.queue_redraw()
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
	camera.zoom = camera.zoom.lerp(Vector2.ONE*_sharp_zoom(),1.0-exp(-delta*8.0))
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
		_map_island_label(Vector2(point.x,island.bounds.end.y+19),str(island.name))
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
	_draw_nameplates(fleet)
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
		if int(shot.source)==0:
			color = SHOT_COLORS.get(str(shot.weapon), color)
		if mortar:_ellipse(shot.pos,Vector2(7,3),Color(0,0,0,.28))
		draw_line(p-direction*18,p,color,2.4,true)
		draw_circle(p,(7.0 if mortar else 4.2),Color(0,0,0,0.5))
		draw_circle(p,(5.0 if mortar else 2.7),color)
		if str(shot.weapon) in ["chain","snow","ice","flare","pumpkin"]: draw_arc(p,6,0,TAU,12,color,1.4,true)
		if shot.weapon=="harpoon": draw_line(p-direction*30,p,color,1.4,true)
		if shot.weapon=="flare": draw_circle(p,9,Color(1,.9,.4,.35))
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
		elif event.type=="teleport":
			var fade=maxf(0.0,1.0-age/0.9)
			var tint=sim.staff.color() if sim.staff.active() else Color("d0a0ff")
			_ellipse_line(p,Vector2(18+age*90,8+age*34),Color(tint,fade),2.4)
			draw_arc(p,10+age*46,-elapsed*6,PI-elapsed*6,16,Color(tint,fade),1.6,true)

	for group: Dictionary in VISUALS.impact_labels(sim.events,sim.clock):
		var age=sim.clock-float(group.time)
		_label(group.pos+Vector2(0,-65-age*33-float(group.lane)*26),"−%d"%int(group.value),19,Color(1,0.65,0.33,1-age/1.2))

## Island labels stay subordinate to the ships and do not balloon with camera zoom.
func _map_island_label(point: Vector2,label_text: String) -> void:
	draw_set_transform(point,0,Vector2.ONE*_plate_scale()*.83)
	_label(Vector2.ZERO,label_text,13,Color(GOLD,.79),2)
	draw_set_transform(Vector2.ZERO)

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
	_ellipse(point+Vector2(0,4),Vector2(length*0.34,length*0.09),Color(0.0,0.02,0.04,0.34))
	if is_player and sim.has_blessing():
		var blessing_pulse=.5+.5*sin(elapsed*3.2)
		_ellipse(point+Vector2(0,2),Vector2(length*0.62,length*0.24),Color(0.62,0.38,1.0,.08+blessing_pulse*.06))
		_ellipse_line(point+Vector2(0,2),Vector2(length*0.5,length*0.18),Color(0.86,0.72,1.0,.4),1.8)
	if sim.target==int(actor.id):
		_ellipse_line(point,Vector2(length*0.44,length*0.16),Color("ed9d67"),2.0)
	if is_player:
		_ellipse_line(point,Vector2(length*0.44,length*0.16),Color(0.37,0.84,0.83,0.4),1.1)
	var hull_alpha=0.45 if is_player and sim.staff.hidden() else 1.0
	var monster = not is_player and actor.kind=="monster"
	if monster:
		var col = posmod(roundi((heading.angle()+PI*0.25)/TAU*4),4)
		var row = int(elapsed*6)%CONTENT.MONSTER_ROWS
		_draw_atlas(beast,point,210.0,col,row,CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS)
	elif is_player and int(sim.player.skin)==26:
		var col=VISUALS.heading_eight(heading,int(direction_cache.get(int(actor.id),-1)))
		direction_cache[int(actor.id)]=col
		_draw_ship_frame(_starter_texture(float(actor.hp),float(actor.max_hp)),point,length,col,false,sin(elapsed*1.7+actor.id)*1.2,hull_alpha)
	elif is_player and int(sim.player.skin)<10:
		var tex=ship_textures[int(sim.player.skin)]
		var flipped=VISUALS.facing_right(heading,bool(facing_cache.get(int(actor.id),false)))
		facing_cache[int(actor.id)]=flipped
		_draw_ship_frame(tex,point,length,0,flipped,sin(elapsed*1.7+actor.id)*1.2,hull_alpha)
	else:
		var tex = atlas_textures[int(sim.player.skin)-10] if is_player else atlas_textures[posmod(int(actor.art),atlas_textures.size())]
		var col=VISUALS.heading_column(heading,int(direction_cache.get(int(actor.id),-1)))
		direction_cache[int(actor.id)]=col
		_draw_ship_frame(tex,point,length,col,false,sin(elapsed*1.7+actor.id)*1.2,hull_alpha)
	if is_player and sim.staff.shows_badge():
		var pulse=.5+.5*sin(elapsed*4.0)
		_ellipse_line(point,Vector2(length*0.52,length*0.2),Color(sim.staff.color(),.28+pulse*.35),2.4)
	if bool(actor.get("frozen",false)) or float(actor.get("ice",0.0))>0.0:
		_ellipse_line(point,Vector2(length*0.5,length*0.19),Color("b7e7ff",.85),2.2)
		draw_arc(point,length*0.28,0,TAU,28,Color("e8f7ff",.7),1.6,true)
	if float(actor.get("spotted",0.0))>sim.clock:
		draw_circle(point-Vector2(0,length*0.35),8,Color("ffe27a",.85))
	if is_player or sim.target==int(actor.id):
		var nose=point+heading*length*0.38
		var side=Vector2(-heading.y,heading.x)*4
		draw_line(nose-heading*8+side,nose,CYAN,1.4,true)
		draw_line(nose-heading*8-side,nose,CYAN,1.4,true)
	if gallery_page>=0:_nameplate(actor,point+Vector2(0,28))

func _plate_pixels() -> float:
	return clampf(get_viewport_rect().size.y/720.0,1.0,1.45)

func _plate_scale() -> float:
	if gallery_page>=0 or camera==null:return 1.0
	return _plate_pixels()/maxf(camera.zoom.x,0.05)

## Use the same effective font pixels as _label(), including high-DPI zoom.
## Otherwise the rank emblem can overlap the measured player name.
func _plate_text_width(value: String,size: int) -> float:
	var grow=1.0 if gallery_page>=0 or camera==null else clampf(get_viewport_rect().size.y/720.0,1.0,1.7)
	var actual=maxi(size,roundi(float(size)*grow))
	return font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x

func _plate_identity(actor: Dictionary) -> String:
	if int(actor.id)==0:return "ID: "+sim.captain_id
	var uid:=str(actor.get("player_uid","")).strip_edges()
	return "ID: "+uid.left(20) if not uid.is_empty() else ""

func _plate_title(actor: Dictionary) -> String:
	var title=str(skins[int(sim.player.skin)].name) if int(actor.id)==0 else str(actor.name)
	var title_size=16 if int(actor.id)==0 else 14
	if int(actor.id)==0:
		if not sim.guild.is_empty():title="[%s] " % sim.guild.tag+title
		if sim.staff.shows_badge():title="[%s] " % sim.staff.badge()+title
	elif actor.get("kind","")=="tower":title="[%s] " % sim.tower_tag()+title
	# Keep the title inside its reserved rectangle, including guild and staff prefixes.
	var shortened=false
	while _plate_text_width(title+("…" if shortened else ""),title_size)>210 and title.length()>1:
		title=title.left(title.length()-1);shortened=true
	return title+"…" if shortened else title

func _plate_has_rank(actor: Dictionary) -> bool:
	# An NPC rank/elite tier is NOT a player's pirate rank.
	return int(actor.id)==0 or bool(actor.get("is_player",false))

func _actor_screen_bounds(actor: Dictionary) -> Rect2:
	var length=_actor_visual_length(actor)
	var point: Vector2=actor.pos
	var transform=get_canvas_transform()
	if actor.get("kind","")=="tower":return transform*Rect2(point-Vector2(38,76),Vector2(76,82))
	if actor.get("kind","")=="monster":return transform*Rect2(point-Vector2(80,85),Vector2(160,105))
	var player=int(actor.id)==0
	var texture: Texture2D
	var column=0
	var flipped=false
	if player and int(sim.player.skin)==26:
		texture=_starter_texture(float(actor.hp),float(actor.max_hp))
		column=int(direction_cache.get(0,0))
	elif player and int(sim.player.skin)<10:
		texture=ship_textures[int(sim.player.skin)];flipped=bool(facing_cache.get(0,false))
	else:
		texture=atlas_textures[int(sim.player.skin)-10] if player else atlas_textures[posmod(int(actor.art),atlas_textures.size())]
		column=int(direction_cache.get(int(actor.id),0))
	var frame: Dictionary=ship_frames[texture.resource_path.trim_prefix("res://")].frames[column]
	return transform*VISUALS.world_rect(frame,point,length,flipped)

## Place a caption below the *visible* sprite, not below its center. The
## measured atlas frame follows the current heading and its real pivot.
func _plate_screen_anchor(actor: Dictionary) -> Vector2:
	var pixels=_plate_pixels()
	var point: Vector2=get_canvas_transform()*actor.pos
	var player=int(actor.id)==0
	var hull: Rect2=_actor_screen_bounds(actor)
	var minimum=point.y+(CAPTAIN_PLATE_OFFSET if player else OTHER_PLATE_OFFSET)*pixels
	var clearance=(CAPTAIN_HULL_CLEARANCE if player else NPC_HULL_CLEARANCE)*pixels
	return Vector2(point.x,maxf(minimum,hull.end.y+clearance))

## No NPC caption is hidden. The captain is never moved by nearby ships.
## Target and other NPC captions choose a deterministic nearby free position.
func _nameplate_layout(fleet: Array[Dictionary]) -> Dictionary:
	var placed: Dictionary={}
	var pending: Array[Dictionary]=[]
	var pixels=_plate_pixels()
	for actor: Dictionary in fleet:
		if int(actor.hp)<=0:continue
		var point: Vector2=get_canvas_transform()*actor.pos
		if not get_viewport_rect().grow(180*pixels).has_point(point):continue
		var player=int(actor.id)==0
		var width=maxf(188.0 if player else 154.0,_plate_text_width(_plate_title(actor),16 if player else 14)+58.0)*pixels
		var baseline=_plate_screen_anchor(actor)
		var rect=Rect2(baseline-Vector2(width*.5,17*pixels),Vector2(width,(116 if player else 56)*pixels))
		if player:placed[0]=rect
		else:pending.append({"actor":actor,"rect":rect})
	pending.sort_custom(func(a,b):
		var a_id=int(a.actor.id)
		var b_id=int(b.actor.id)
		return (0 if a_id==sim.target else a_id+100) < (0 if b_id==sim.target else b_id+100)
	)
	var occupied: Array[Rect2]=[]
	if placed.has(0):occupied.append(placed[0])
	var view_size=get_viewport_rect().size
	for entry: Dictionary in pending:
		var base: Rect2=entry.rect
		var dx=base.size.x+14*pixels
		var dy=base.size.y+12*pixels
		var offsets: Array[Vector2]=[
			Vector2.ZERO,Vector2(-dx,0),Vector2(dx,0),
			Vector2(-dx*.55,dy),Vector2(dx*.55,dy),Vector2(0,dy),
			Vector2(-dx,dy),Vector2(dx,dy),Vector2(0,dy*2.0),
			Vector2(-dx*1.5,dy),Vector2(dx*1.5,dy)]
		var best=base
		var score=INF
		for offset: Vector2 in offsets:
			var candidate=Rect2(base.position+offset,base.size)
			var penalty=offset.length()*.025
			for other: Rect2 in occupied:
				if candidate.intersects(other.grow(6*pixels)):
					var overlap=candidate.intersection(other.grow(6*pixels))
					penalty+=10000.0+overlap.size.x*overlap.size.y
			if candidate.position.x<8 or candidate.end.x>view_size.x-8:penalty+=15000
			if candidate.position.y<68 or candidate.end.y>view_size.y-20:penalty+=15000
			if penalty<score:score=penalty;best=candidate
			if score<1.0:break
		placed[int(entry.actor.id)]=best
		occupied.append(best)
	return placed

func _draw_nameplates(fleet: Array[Dictionary]) -> void:
	plate_rects=_nameplate_layout(fleet)
	var inverse=get_canvas_transform().affine_inverse()
	var pixels=_plate_pixels()
	var ordered=fleet.duplicate()
	ordered.sort_custom(func(a,b):return (2 if int(a.id)==0 else (1 if int(a.id)==sim.target else 0))<(2 if int(b.id)==0 else (1 if int(b.id)==sim.target else 0)))
	for actor: Dictionary in ordered:
		if not plate_rects.has(int(actor.id)):continue
		var rect: Rect2=plate_rects[int(actor.id)]
		_nameplate(actor,inverse*(rect.position+Vector2(rect.size.x*.5,17*pixels)))

## Readable, anchored name/HP/shield block; ten deck slots follow directly below.
func _nameplate(actor: Dictionary,anchor: Vector2) -> void:
	var player=int(actor.id)==0
	var tower=actor.get("kind","")=="tower"
	var monster=actor.get("kind","")=="monster"
	var elite=bool(actor.get("elite",false))
	var hostile=not player and (bool(actor.get("aggressive",false)) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) or (tower and not sim.tower_friendly()))
	var color=Color("e8d0a1") if elite else Color("dce8e4")
	if player:color=sim.staff.color() if sim.staff.shows_badge() else Color("d9f0e5")
	elif hostile:color=Color("eab8a7")
	elif monster:color=Color("c6b9d6")
	var title=_plate_title(actor)
	var title_size=16 if player else 14
	var text_width=_plate_text_width(title,title_size)
	draw_set_transform(anchor,0,Vector2.ONE*_plate_scale())
	_label(Vector2(0,0),title,title_size,color,2)
	if _plate_has_rank(actor):
		var tier=clampi(floori((sim.level-1)/4.0)+1,1,5) if player else clampi(int(actor.get("pirate_rank",1)),1,5)
		# Only real players receive a pirate rank; the emblem clears the full title.
		_rank_emblem(Vector2(-text_width*.5-23,-6),tier,Color("d5b77a"))
	var width=132.0 if player else (96.0 if int(actor.id)==sim.target else 84.0)
	var hull_color=Color("d97660") if hostile else Color("61b967")
	var identity=_plate_identity(actor)
	if not identity.is_empty():_label(Vector2(0,PLATE_ID_BASELINE),identity,8,Color(.72,.86,.88,.49),1)
	var hit_age=sim.clock-float(actor.get("last_hit",-100.0))
	var hit_flash=clampf(1.0-hit_age/.42,0.0,1.0)
	if player:
		# Only the HUD displays numeric HP. The ship gets clean gauges.
		_status_bar(Rect2(-width*.5,PLATE_HP_Y,width,7),float(actor.hp)/maxf(1,float(actor.max_hp)),Color("49df24"),hit_flash)
	else:_plate_bar(Rect2(-width*.5,12,width,5),float(actor.hp)/maxf(1,float(actor.max_hp)),hull_color)
	var shield=float(actor.get("max_shield",0))
	if shield>0:
		if player:_status_bar(Rect2(-width*.5,PLATE_SHIELD_Y,width,5),float(actor.get("shield",0))/shield,Color("409fdf"),hit_flash)
		else:_plate_bar(Rect2(-width*.5,22,width,3),float(actor.get("shield",0))/shield,Color("4d95be"))
	if player:SEA_MARKS.deck_badge(self,Vector2(0,PLATE_DECK_Y),6.0,sim,elapsed)
	if float(actor.get("slow",0))>0:draw_circle(Vector2(width*.5+6,14),2.5,Color("9fdbf4"))
	if player and sim.staff.hidden():_label(Vector2(0,-20),"GEIST" if sim.staff.presence=="ghost" else "ZUSCHAUER",10,sim.staff.color(),2)
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

## Straight combat gauges match the rectangular deck fittings below them.
func _status_bar(rect: Rect2,ratio: float,color: Color,flash: float=0.0) -> void:
	draw_rect(rect.grow(1.0+flash*.7),Color("030b12").lerp(color,flash*.3))
	draw_rect(rect,Color("0a1620"))
	var fill=Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0,1),rect.size.y))
	if fill.size.x<=0:return
	draw_rect(fill,color.lightened(.20*flash))
	draw_line(fill.position+Vector2(0,1),Vector2(fill.end.x,fill.position.y+1),color.lightened(.3+.3*flash),1,true)
	if flash>0:draw_rect(rect.grow(2),Color(color,.19*flash),false,1.4,true)

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
	var k=.6
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

func _draw_ship_frame(texture: Texture2D,point: Vector2,length: float,column: int,flipped: bool,bob: float,alpha: float=1.0) -> void:
	var frame: Dictionary=ship_frames[texture.resource_path.trim_prefix("res://")].frames[column]
	var geometry: Dictionary=VISUALS.geometry(frame,length)
	# Positive source/destination rectangles; reflection is around the measured hull anchor.
	draw_set_transform(point+Vector2(0,bob),0,Vector2(-1,1) if flipped else Vector2.ONE)
	draw_texture_rect_region(texture,geometry.destination,geometry.source,Color(1,1,1,alpha))
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
	var grow=1.0 if gallery_page>=0 or camera==null else clampf(get_viewport_rect().size.y/720.0,1.0,1.7)
	var fs=maxi(fontsize,roundi(float(fontsize)*grow))
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var p = point-Vector2(width*0.5,0)
	draw_string_outline(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,outline,Color(0.01,0.035,0.05,color.a))
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

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

func _button(parent: Node,text: String,callback: Callable,variant: String="normal") -> Button:
	var b =Button.new()
	b.text=text
	b.clip_text=true
	b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",14)
	SKIN.dress(b,variant,20.0 if variant=="close" else 6.0)
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
	ui.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
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
	for key: String in CONTENT.SUPPLY_KEYS:
		var supply=key
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var button=_orb(ui,"%s · %s" % [config.name,config.effect],painted[config.icon],func():_use_supply(supply),str(config.short))
		button.name="Supply_"+key;supply_buttons[key]=button
	target_cycle=_orb(ui,"Nächstes sichtbares Ziel · Tab",painted.spyglass,_cycle_target,"ZIEL")
	ammo_selector=_orb(ui,"Munition auswählen",_ammo_texture(sim.ammo_mode),_toggle_ammo,"MUNITION");ammo_selector.name="AmmoSelector"
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
	modal_backdrop.gui_input.connect(func(event):
		if modal_kind!="Munition":return
		if (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_close_ammo();modal_backdrop.accept_event())
	staff_pill=_button(ui,"",func():_open_modal("Staff"),"staff")
	staff_pill.name="StaffPill";staff_pill.visible=false;staff_pill.add_theme_font_size_override("font_size",11)
	staff_pill.tooltip_text="Staff-Werkzeuge"
	modal=ORNATE.new()
	ui.add_child(modal)
	# Scroll clipping must remain in unscaled viewport space. HUD orbs scale separately.
	modal.set_as_top_level(true)
	modal.z_index=20
	modal.visible=false
	modal_title=_text(modal,"",21,Color("fff0c8"))
	modal_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;modal_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	modal_title.clip_text=true;modal_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	modal_title.add_theme_color_override("font_outline_color",Color("2a0c06"));modal_title.add_theme_constant_override("outline_size",5)
	modal_close=_button(modal,"×",func():modal.hide();_save_progress(),"close")
	modal_close.add_theme_font_size_override("font_size",26);modal_close.tooltip_text="Schließen";modal_close.clip_text=false
	modal_tabs=HBoxContainer.new();modal_tabs.add_theme_constant_override("separation",5);modal_tabs.visible=false
	modal.add_child(modal_tabs)
	modal_scroll=TOUCH_SCROLL.new()
	modal.add_child(modal_scroll)
	modal_scroll.minimum_size_changed.connect(_fit_modal_scroll)
	modal_body=VBoxContainer.new()
	modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",10)
	modal_scroll.add_child(modal_body)
	scroll_hint=Control.new();scroll_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scroll_hint.draw.connect(_draw_scroll_hint);modal.add_child(scroll_hint)
	loading=LOADING.new();loading.art=painted.loading;loading.wheel=painted.helm_wheel
	loading.set_as_top_level(true);loading.z_index=40;loading.visible=false
	ui.add_child(loading)

func _fit_modal_scroll() -> void:
	if modal_scroll==null or modal_scroll_box.size.x<2:return
	if modal_scroll.get_combined_minimum_size().x>modal_scroll_box.size.x+1.0:return
	if modal_scroll.position==modal_scroll_box.position and modal_scroll.size==modal_scroll_box.size:return
	modal_scroll.position=modal_scroll_box.position
	modal_scroll.size=modal_scroll_box.size

func _place(c: Control,x: float,y: float,w: float,h: float) -> void:
	c.position=Vector2(x,y)
	c.size=Vector2(maxf(w,1),maxf(h,1))

func _layout() -> void:
	if ui==null:return
	var viewport_size=get_viewport_rect().size
	# Scale only the HUD. Ocean, camera, world input and simulation keep viewport coordinates.
	var base=maxf(viewport_size.y/600.0,1.0)
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
	var pill_w=minf(220.0,s.x*.3)
	_place(staff_pill,(s.x-pill_w)*.5,header+4,pill_w,22)
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
	_place(buff_bar,left,target_y+card_h+46,column,26)
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
	_place(ammo_selector,fx-orb-gap,s.y-orb-10,orb,orb)
	_place(repair,fx+fire*.5+gap*.5,fy-orb-gap,orb,orb)
	# Supplies retain their own functions; every ammunition type uses one selector.
	var supply_order=["powder","repair_kit","shield_charge","plates"]
	for i in supply_order.size():
		_place(supply_buttons[supply_order[i]],fx-2*(orb+gap)+(i%2)*(orb+gap),fy-(orb+gap)+floori(i/2.0)*(orb+gap),orb,orb)
	var hot: Array[Button]=[target_cycle,loadout_button]
	for i in hot.size():_place(hot[hot.size()-1-i],ammo_selector.position.x-(i+1)*(orb+gap),s.y-orb-10,orb,orb)
	var toast_w=maxf(60.0,minf(380.0,s.x-2.0*(left+column+12)))
	_place(status,(s.x-toast_w)*.5,header+3+(26.0 if staff_pill.visible else 0.0),toast_w,20 if compact else 24)
	status.set_meta("room",toast_w)
	var menu_size=viewport_size
	var grow=clampf(viewport_size.y/720.0,1.0,1.7)
	modal.scale=Vector2.ONE*grow
	var visual_w=minf(720.0*grow,menu_size.x-32.0)
	var visual_h=minf(620.0*grow,menu_size.y-24.0)
	var width=visual_w/grow
	var height=visual_h/grow
	_place(modal_backdrop,0,0,s.x,s.y)
	if modal_kind=="Munition":
		var button_rect=ammo_selector.get_global_rect()
		visual_w=minf(400.0*grow,menu_size.x-24.0)
		var bottom=button_rect.position.y-10.0
		var top_limit=chrome.get_global_rect().end.y+10.0
		visual_h=minf(566.0*grow,maxf(160.0,bottom-top_limit))
		width=visual_w/grow;height=visual_h/grow
		_place(modal,clampf(button_rect.end.x-visual_w,12.0,menu_size.x-visual_w-12.0),bottom-visual_h,width,height)
	else:_place(modal,(menu_size.x-visual_w)*.5,(menu_size.y-visual_h)*.5,width,height)
	var head=34.0 if modal_kind=="Munition" else (46.0 if height<420 else 52.0)
	modal.header=head
	var title_w=width-62 if modal_kind=="Munition" else clampf(font.get_string_size(modal_title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+70,200,width-170)
	modal.ribbon=Rect2(10,3,title_w,head-6) if modal_kind=="Munition" else Rect2((width-title_w)*.5,8,title_w,head-14)
	_place(modal_title,modal.ribbon.position.x+8,modal.ribbon.position.y,title_w-16,modal.ribbon.size.y)
	var close=head-12
	_place(modal_close,width-close-12,6,close,close)
	var inner_top=head+8
	if modal_tabs.visible:
		_place(modal_tabs,18,inner_top,width-36,34)
		inner_top+=42
	modal_scroll_box=Rect2(18,inner_top,width-36,height-inner_top-18)
	_fit_modal_scroll()
	_fit_modal_scroll.call_deferred()
	_place(scroll_hint,18,inner_top,width-36,height-inner_top-18)
	modal.queue_redraw()
	# The scroll container sizes its child. Forcing the body to the full width
	# includes the scrollbar and the container then grows past the frame.
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
	buff_bar.visible=sim.has_blessing() or float(sim.buffs.tide_deck)>0 or float(sim.buffs.storm_deck)>0 or float(sim.buffs.salvage_deck)>0 or sim.guild_island_held()
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
	ammo_selector.text="%s · %d" % [AMMO_UI[sim.ammo_mode].name,sim.player.ammo[sim.ammo_mode]]
	ammo_selector.tooltip_text="%s · %s · antippen zum Wechseln" % [AMMO_UI[sim.ammo_mode].name,AMMO_UI[sim.ammo_mode].use]
	_set_orb(ammo_selector,_ammo_texture(sim.ammo_mode),_thousands(int(sim.player.ammo[sim.ammo_mode])),modal.visible and modal_kind=="Munition","MUNITION")
	ammo_selector.set("state_label","MUNITION")
	_set_orb(target_cycle,painted.spyglass,"",false,"ZIEL")
	_set_orb(loadout_button,extra_icons.cannon_0,"",modal.visible and modal_kind=="Bewaffnung","WAFFEN")
	var staff=sim.staff
	staff_pill.visible=staff.active()
	if staff_pill.visible:
		var presence="" if staff.presence=="official" else " · "+str(CONTENT.STAFF_PRESENCE[staff.presence].name)
		staff_pill.text="%s%s · %s" % [staff.badge(),presence,CONTENT.STAFF_ENVIRONMENT]
	if message_history.is_empty() or message_history.back()!=sim.message:
		message_history.append(sim.message)
		status_age=0.0
		if message_history.size()>6:message_history.pop_front()
	status.text="IM HAFEN · ABLEGEN zum Weiterfahren" if sim.docked else sim.message
	status.visible=not status.text.is_empty() and (status_age<4.0 or sim.docked)
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
	if int(sim.player.ammo[sim.ammo_mode])<(1 if sim.ammo_mode>=2 else 3):return "MUNITION LEER"
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

func _toggle_ammo() -> void:
	if modal.visible and modal_kind=="Munition":_close_ammo()
	else:_open_modal("Munition")

func _close_ammo() -> void:
	modal.hide();modal_backdrop.hide()
	suppress_tap_until=Time.get_ticks_msec()+250
	_refresh_ui()

func _choose_ammo(index: int) -> void:
	sim.set_ammo(index)
	_save_progress()
	_close_ammo()

## Active effects with remaining sea time; emergency cooldowns live on their own orbs.
func _draw_buffs() -> void:
	var entries: Array=[]
	if sim.has_blessing():entries.append([painted.crystal_blessing,_clock_text(float(sim.buffs.blessing)),Color("c69bff")])
	if float(sim.buffs.tide_deck)>0:entries.append([painted.tide_deck,_clock_text(float(sim.buffs.tide_deck)),Color("5fe0d2")])
	for key: String in CONTENT.SPECIAL_DECKS:
		if float(sim.buffs[key])>0:entries.append([painted[CONTENT.SPECIAL_DECKS[key].icon],_clock_text(float(sim.buffs[key])),CONTENT.SPECIAL_DECKS[key].color])
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

const MODAL_TABS := {"Seekarten":["WELTKARTE","ANLEITUNG"],"Staff":["ÜBERSICHT","TELEPORT","SCHIFF","WELT","GEWÄHREN","ZIEL","PROTOKOLL"]}
const MODAL_TITLES := {"Munition":"Munitionsauswahl","Kessel":"Gezeitenkessel","Staff":"Staff-Werkzeuge","Anzeige":"Anzeige & Steuerung","Rangliste":"Rangliste","Bonuskarten":"Bonuskarten"}

func _open_modal(kind: String) -> void:
	camera_pad.release()
	var scroll_position=modal_scroll.scroll_vertical if modal.visible and modal_kind==kind else 0
	modal_kind=kind
	modal.plain=kind=="Munition"
	modal_backdrop.color=Color(0,0,0,0) if kind=="Munition" else Color(0.002,0.009,0.018,0.77)
	modal_title.add_theme_font_size_override("font_size",15 if kind=="Munition" else 21)
	modal_title.add_theme_constant_override("outline_size",2 if kind=="Munition" else 5)
	modal_close.add_theme_font_size_override("font_size",20 if kind=="Munition" else 26)
	if kind=="Munition":
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var style=StyleBoxFlat.new();style.bg_color=Color("222d33");style.border_color=Color("8a7553");style.set_border_width_all(1)
			modal_close.add_theme_stylebox_override(state,style)
	else:SKIN.dress(modal_close,"close",20.0)
	modal_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if kind=="Munition" else HORIZONTAL_ALIGNMENT_CENTER
	modal_title.text=str(MODAL_TITLES.get(kind,kind)).to_upper()
	modal_body.add_theme_constant_override("separation",3 if kind=="Munition" else 10)
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	_build_tabs(kind)
	_layout()
	match kind:
		"Schiff":_open_ship()
		"Munition":_open_ammo()
		"Werft":_open_shipyard()
		"Bewaffnung":_open_weapons()
		"Hafen":_open_harbor()
		"Logbuch":_open_logbook()
		"Rangliste":_open_ranking()
		"Decks":_open_decks()
		"Kastelle":
			_banner_card(painted.nav_castles,"KASTELLE · DAUERHAFTE HAFENAUSBAUTEN","Sechs Kastelle mit je %d Stufen. Stufe 1 bis 3 sind sofort offen, danach kommt alle drei Kapitänsstufen eine weitere hinzu. Aktuell offen: bis Stufe %d." % [CONTENT.CASTLE_MAX,sim.castle_cap()])
			if not sim.docked:_note("Ausbauen kannst du nur angedockt im Hafen.",Color("edc68c"))
			for key in CONTENT.UPGRADE_KEYS:_upgrade_row(str(key))
		"Kessel":_open_kessel()
		"Bonuskarten":_open_bonus()
		"Gilde":_open_guild()
		"Seekarten":_open_charts()
		"Anzeige":_open_display()
		"Staff":_open_staff()
		_:_open_info()
	modal_body.queue_sort()
	modal.show()
	modal_backdrop.show()
	modal_scroll.restore(sim.ammo_mode*77 if kind=="Munition" else scroll_position)

func _build_tabs(kind: String) -> void:
	for child in modal_tabs.get_children():
		modal_tabs.remove_child(child)
		child.queue_free()
	var names: Array=MODAL_TABS.get(kind,[])
	if kind=="Staff" and not sim.staff.active():names=[]
	modal_tabs.visible=not names.is_empty()
	if names.is_empty():return
	var current=str(modal_tab.get(kind,names[0]))
	if not current in names:current=str(names[0])
	modal_tab[kind]=current
	for name in names:
		var tab=str(name)
		var button=_button(modal_tabs,tab,func():_switch_tab(kind,tab),"tab_on" if tab==current else "tab")
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",12 if names.size()>4 else 14)

func _switch_tab(kind: String,tab: String) -> void:
	modal_tab[kind]=tab
	modal_scroll.scroll_vertical=0
	_open_modal(kind)

func _tab(kind: String) -> String:
	return str(modal_tab.get(kind,""))

# --- Menu building blocks ------------------------------------------------------------

func _info(text: String,color: Color=GOLD) -> Label:
	var label = _text(modal_body,text,15,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _note(text: String,color: Color=Color("bac7c7"),parent: Node=null) -> Label:
	var label=_text(parent if parent!=null else modal_body,text,14,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_stylebox_override("normal",SKIN.note())
	return label

## Gold heading with carved rules left and right, as on the classic client's menu sections.
func _section(text: String,parent: Node=null) -> Label:
	var label=_text(parent if parent!=null else modal_body,text,15,Color("f5d78d"))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y=30
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_outline_color",Color("061016"));label.add_theme_constant_override("outline_size",4)
	label.draw.connect(func():_draw_section(label))
	return label

func _draw_section(label: Label) -> void:
	var tw=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
	var mid=label.size*.5
	var gap=tw*.5+14.0
	for side in [-1.0,1.0]:
		var inner=Vector2(mid.x+side*gap,mid.y)
		var outer=Vector2(8.0 if side<0 else label.size.x-8.0,mid.y)
		if (outer.x-inner.x)*side<12:continue
		label.draw_line(inner+Vector2(0,1.5),outer+Vector2(0,1.5),Color(0,0,0,.6),2.0)
		label.draw_line(inner,outer,Color("c9a35e"),1.4,true)
		label.draw_line(inner+Vector2(side*6,-3.5),outer+Vector2(-side*30,-3.5),Color("c9a35e",.35),1.0)
		var d=PackedVector2Array([inner+Vector2(0,-4),inner+Vector2(side*5,0),inner+Vector2(0,4),inner+Vector2(-side*5,0)])
		label.draw_colored_polygon(d,Color("f5d78d"))

func _action(text: String,callback: Callable,variant: String="normal",parent: Node=null) -> Button:
	var button = _button(parent if parent!=null else modal_body,text,callback,variant)
	button.custom_minimum_size.y=48
	button.add_theme_font_size_override("font_size",16)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return button

func _primary(text: String,callback: Callable,parent: Node=null) -> Button:
	return _action(text,callback,"primary",parent)

func _with_icon(button: Button,texture: Texture2D) -> Button:
	button.icon=texture
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",26)
	button.add_theme_constant_override("h_separation",8)
	return button

func _grid(columns: int=2,parent: Node=null) -> GridContainer:
	var grid=GridContainer.new()
	grid.columns=columns if modal_scroll.size.x>=420 else 1
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8)
	(parent if parent!=null else modal_body).add_child(grid)
	return grid

func _card(accent: Color=Color(0,0,0,0),parent: Node=null) -> PanelContainer:
	var card=PanelContainer.new()
	card.add_theme_stylebox_override("panel",SKIN.card(accent))
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	(parent if parent!=null else modal_body).add_child(card)
	return card

func _picture(parent: Node,texture: Texture2D,width: float,framed: bool=true) -> TextureRect:
	var holder: Node=parent
	if framed:
		var frame=PanelContainer.new();frame.add_theme_stylebox_override("panel",SKIN.icon_frame())
		frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		parent.add_child(frame);holder=frame
	var picture = TextureRect.new()
	picture.texture=texture
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=Vector2(width,width)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	holder.add_child(picture)
	return picture

## Item card: framed picture left, text and buttons right. Returns the right column.
func _row(texture: Texture2D,text: String,size: float=64.0,accent: Color=Color(0,0,0,0),parent: Node=null) -> VBoxContainer:
	var card=_card(accent,parent)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	if texture!=null:_picture(row,texture,size)
	var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
	column.add_theme_constant_override("separation",5);column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var label=_text(column,text,14,Color("e8f4f2"));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("title",true)
	return column

func _row_button(parent: Node,text: String,callback: Callable,disabled: bool=false,variant: String="normal") -> Button:
	var button=_button(parent,text,callback,variant)
	button.custom_minimum_size.y=40
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.disabled=disabled
	return button

func _banner_card(texture: Texture2D,title: String,text: String,accent: Color=Color("c9a35e")) -> VBoxContainer:
	var column=_row(texture,title,72,accent)
	var label: Label=column.get_child(0);label.add_theme_color_override("font_color",Color("f5d78d"));label.add_theme_font_size_override("font_size",15)
	var body=_text(column,text,13,Color("bac7c7"));body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return column

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

func _meter(title: String,value: float,maximum: float,color: Color,readout: String) -> void:
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",10);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;modal_body.add_child(line)
	var tag=_text(line,title,13,Color("ecd29a"));tag.custom_minimum_size.x=110;tag.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var bar=_bar(line);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.custom_minimum_size.y=20
	bar.max_value=maxf(1.0,maximum);bar.value=value
	var fill: StyleBoxFlat=bar.get_theme_stylebox("fill").duplicate();fill.bg_color=color;bar.add_theme_stylebox_override("fill",fill)
	var numbers=_text(bar,readout,11,Color.WHITE);numbers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	numbers.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;numbers.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	numbers.add_theme_color_override("font_outline_color",Color("06121a"));numbers.add_theme_constant_override("outline_size",3)

func _stat(parent: Node,title: String,value: String,texture: Texture2D=null) -> void:
	var card=_card(Color(0,0,0,0),parent)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	if texture!=null:_picture(row,texture,30,false)
	var column=VBoxContainer.new();column.add_theme_constant_override("separation",0);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
	_text(column,title,11,Color("9fb4b4"))
	var number=_text(column,value,16,Color("fff0c8"));number.clip_text=true

func _canvas_text(canvas: CanvasItem,center: Vector2,text: String,fs: int,color: Color) -> void:
	var w=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	canvas.draw_string_outline(font,center-Vector2(w*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color("041016"))
	canvas.draw_string(font,center-Vector2(w*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func _draw_scroll_hint() -> void:
	if modal_scroll==null or not modal.visible:return
	var w=scroll_hint.size.x-16
	var h=scroll_hint.size.y
	var limit=modal_scroll.max_scroll()
	var shade=Color(0.02,0.07,0.09,.94)
	var clear=Color(shade,0)
	var bob=sin(Time.get_ticks_msec()/220.0)*2.0
	if modal_scroll.scroll_vertical<limit-4:
		scroll_hint.draw_polygon(PackedVector2Array([Vector2(0,h-30),Vector2(w,h-30),Vector2(w,h),Vector2(0,h)]),PackedColorArray([clear,clear,shade,shade]))
		var c=Vector2(w*.5,h-12+bob)
		for k in 2:
			var arm=PackedVector2Array([c+Vector2(-9,-5+k*5),c+Vector2(0,1+k*5),c+Vector2(9,-5+k*5)])
			scroll_hint.draw_polyline(arm,Color(0,0,0,.7),4.0,true)
			scroll_hint.draw_polyline(arm,Color("f5d78d",1.0-k*.4),2.0,true)
	if modal_scroll.scroll_vertical>4:
		scroll_hint.draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(w,0),Vector2(w,18),Vector2(0,18)]),PackedColorArray([shade,shade,clear,clear]))

# --- Ship, ammunition, shipyard and weapons ----------------------------------------------

func _open_ship() -> void:
	var stage=Control.new()
	stage.name="ShipStage"
	stage.custom_minimum_size=Vector2(0,250)
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.name="ShipStage"
	stage.draw.connect(func():_draw_ship_stage(stage))
	modal_body.add_child(stage)
	_meter("RUMPF",float(sim.player.hp),float(sim.player.max_hp),Color("4fbf5e"),"%s / %s" % [_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))])
	_meter("SCHILD",float(sim.player.shield),float(sim.player.max_shield),Color("3d8fe0"),"%s / %s" % [_thousands(int(sim.player.shield)),_thousands(int(sim.player.max_shield))])
	_meter("LV. %d · EP" % sim.level,float(sim.xp),float(sim.xp_required()),Color("c79a3f"),"%s / %s" % [_thousands(sim.xp),_thousands(sim.xp_required())])
	var stats=_grid(2)
	_stat(stats,"FAHRT","%d Knoten" % roundi(float(sim.player.speed)),painted.helm_wheel)
	_stat(stats,"NACHLADEN","%s s" % ("%.2f" % sim.reload_time()).replace(".",","),painted.spyglass)
	_stat(stats,"KANONEN","%d feuern · %d an Bord · %d Plätze" % [sim.equipped_cannons(),sim.player.cannons,sim.cannon_slots()],extra_icons.cannon_0)
	_stat(stats,"BREITSEITE","%d Schaden je Kugel" % sim.weapon_damage(0),icons.cannonball)
	_section("DECKS")
	for slot in CONTENT.DECK_SLOT_COUNT:
		var index=int(sim.deck_slots[slot])
		if index>=0:
			var deck: Dictionary=sim.decks[index]
			_row(_art(DECK_ART[str(deck.type)]),"PLATZ %d · %s\n%s" % [slot+1,_deck_title(deck).to_upper(),_deck_effect(deck)],44,CONTENT.DECK_TIER_COLORS[int(deck.tier)])
		else:_row(null,"PLATZ %d · FREI\nDecks montierst du angedockt im Hafen." % (slot+1),44,Color("4a4234"))
	var tide=float(sim.buffs.tide_deck)
	_row(painted.tide_deck,"GEZEITENDECK · "+("aktiv %s · +10 Kanonenplätze" % _clock_text(tide) if tide>0 else "nicht aktiv"),44,SEA_MARKS.DECK_COLORS.tide if tide>0 else Color("4a4234"))
	_section("VORRÄTE")
	var stock=_grid(2)
	for key: String in CONTENT.SUPPLY_KEYS:_stat(stock,str(CONTENT.SUPPLIES[key].name).to_upper(),"%d an Bord" % int(sim.supplies[key]),painted[CONTENT.SUPPLIES[key].icon])
	var links=_grid(2)
	_action("DECKS VERWALTEN",func():_open_modal("Decks"),"normal",links)
	_action("KASTELLE",func():_open_modal("Kastelle"),"normal",links)
	_action("SCHIFFSDESIGN WÄHLEN",func():_open_modal("Werft"),"normal",links)
	_action("BEWAFFNUNG",func():_open_modal("Bewaffnung"),"normal",links)

## The ship window retains the detailed deck gems; the sea uses a compact edge strip.
func _draw_ship_stage(stage: Control) -> void:
	var w=stage.size.x;var h=stage.size.y
	stage.draw_style_box(SKIN.card(),Rect2(Vector2.ZERO,stage.size))
	var sea=Rect2(5,5,w-10,h-10)
	stage.draw_polygon(PackedVector2Array([sea.position,Vector2(sea.end.x,sea.position.y),sea.end,Vector2(sea.position.x,sea.end.y)]),PackedColorArray([Color("0c2f3c"),Color("0c2f3c"),Color("06161d"),Color("06161d")]))
	var center=Vector2(w*.5,h*.47)
	for i in 4:
		var radii=Vector2(w*(.16+.05*i),h*(.05+.018*i))
		var ring=PackedVector2Array()
		for j in 33:ring.append(center+Vector2(0,h*.15)+Vector2(cos(j*TAU/32),sin(j*TAU/32))*radii)
		stage.draw_polyline(ring,Color(.45,.9,.88,.16-.03*i),1.4,true)
	var tex: Texture2D=skin_previews[int(sim.player.skin)]
	var box=Vector2(minf(w*.6,380.0),h*.52)
	var k=minf(box.x/maxf(tex.get_width(),1),box.y/maxf(tex.get_height(),1))
	var dims=tex.get_size()*k
	stage.draw_texture_rect(tex,Rect2(center-dims*Vector2(.5,.62),dims),false)
	var staff=sim.staff
	var name=str(skins[int(sim.player.skin)].name).to_upper()
	var tag="[%s] " % sim.guild.tag if not sim.guild.is_empty() else ""
	var title=tag+name
	var tw=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	var badge=SEA_MARKS.badge_width(staff.badge(),font,12)+8 if staff.shows_badge() else 0.0
	var left=w*.5-(tw+badge)*.5
	if staff.shows_badge():SEA_MARKS.staff_badge(stage,Vector2(left,22),staff.badge(),staff.color(),font,12)
	_canvas_text(stage,Vector2(left+badge+tw*.5,28),title,17,staff.color() if staff.shows_badge() else CYAN)
	var tier=clampi(floori((sim.level-1)/4.0)+1,1,ROMAN.size()-1)
	stage.draw_circle(Vector2(34,34),18,Color("17303c"));stage.draw_arc(Vector2(34,34),18,0,TAU,28,Color("d8b46a"),2.0,true)
	_canvas_text(stage,Vector2(34,39),ROMAN[tier],13,Color("ffe6a8"))
	_canvas_text(stage,Vector2(34,66),"LV. %d" % sim.level,11,Color("ecd29a"))
	SEA_MARKS.deck_badge(stage,Vector2(w*.5,h-55),10,sim)
	var mounted=0
	for index in sim.deck_slots:
		if int(index)>=0:mounted+=1
	_canvas_text(stage,Vector2(w*.5,h-12),"%d / 10 DECKS · GEZEITENDECK %s" % [mounted,_clock_text(float(sim.buffs.tide_deck)) if float(sim.buffs.tide_deck)>0 else "AUS"],12,Color("e2ecee"))

func _ammo_texture(index: int) -> Texture2D:
	var key=str(AMMO_UI[index].icon)
	if icons.has(key):return icons[key]
	if not ammo_previews.has(key):
		# These four source images have a baked checkerboard outside the projectile.
		# Sample only its opaque center; the HUD's circular UV mask supplies the rim.
		var preview=AtlasTexture.new()
		preview.atlas=painted[key]
		preview.region=Rect2(Vector2(160,160),Vector2(192,192))
		ammo_previews[key]=preview
	return ammo_previews[key]

func _open_ammo() -> void:
	ammo_rows.clear()
	for i in AMMO_UI.size():
		var index=i
		var row=AMMO_CHOICE.new()
		row.title=str(AMMO_UI[i].name)
		row.detail="%d Schaden · %s" % [sim.weapon_damage(i),AMMO_UI[i].use]
		row.stock=_thousands(int(sim.player.ammo[i]))
		row.loaded=sim.ammo_mode==i
		row.art=_ammo_texture(i)
		row.text="%s · Vorrat %d · %s" % [AMMO_UI[i].name,sim.player.ammo[i],AMMO_UI[i].use]
		row.tooltip_text=row.text
		row.set_meta("ammo_index",i);row.name="AmmoChoice%d" % i
		row.custom_minimum_size=Vector2(0,74);row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.pressed.connect(func():_choose_ammo(index))
		modal_body.add_child(row);ammo_rows.append(row)

func _open_shipyard() -> void:
	_banner_card(painted.nav_shipyard,"SCHIFFSDESIGNS · %d KARTEN" % skins.size(),"Nach Namen sortiert. Das Design ändert nur das Aussehen; Rumpf, Kanonen und Decks bleiben.")
	var order: Array[int]=[]
	for i in skins.size():order.append(i)
	order.sort_custom(func(a,b): return str(skins[a].name).naturalnocasecmp_to(str(skins[b].name))<0)
	var grid=_grid(2)
	for raw in order:
		var index: int=raw
		var equipped=int(sim.player.skin)==index
		var card=_card(CYAN if equipped else Color(0,0,0,0),grid)
		var column=VBoxContainer.new();column.add_theme_constant_override("separation",6);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(column)
		var frame=Panel.new()
		frame.custom_minimum_size=Vector2(0,104)
		frame.clip_contents=true
		frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var frame_style=SKIN.icon_frame(CYAN if equipped else Color("6b5634"))
		frame.add_theme_stylebox_override("panel",frame_style)
		column.add_child(frame)
		var preview=_portrait(frame)
		preview.texture=skin_previews[index]
		preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.offset_left=6;preview.offset_top=6;preview.offset_right=-6;preview.offset_bottom=-6
		var choose=_button(column,str(skins[index].name)+("\nAKTIV" if equipped else "\nAUSRÜSTEN"),func():_equip(index),"normal" if equipped else "primary")
		choose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		choose.custom_minimum_size.y=46
		choose.add_theme_font_size_override("font_size",12)
		choose.disabled=equipped
	_section("MUNITIONSNACHSCHUB · JE 30 GOLD")
	var stock=_grid(3)
	for i in 3:
		var index =i
		var b =_action(["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_refresh_ui(),"normal",stock)
		_with_icon(b,icons[["cannonball","chain","harpoon"][i]])

func _open_weapons() -> void:
	_banner_card(extra_icons.cannon_0,"BEWAFFNUNG · KANONEN & HARPUNEN","Bugkastell Stufe %d · Jagdkastell Stufe %d\n%d von %d Kanonen feuern · Breitseite: 3 Geschosse · Nachladen: %s Sekunden" % [sim.upgrades.cannon,sim.upgrades.harpoon,sim.equipped_cannons(),sim.player.cannons,("%.2f" % sim.reload_time()).replace(".",",")])
	for i in AMMO_UI.size():
		var index=i
		var entry: Dictionary=AMMO_UI[i]
		var column=_row(_ammo_texture(i),"%s · %d im Lager\n%d Schaden je Geschoss · %s" % [entry.name,sim.player.ammo[i],sim.weapon_damage(i),entry.use],48,CYAN if sim.ammo_mode==i else Color(0,0,0,0))
		_row_button(column,"GELADEN" if sim.ammo_mode==i else "LADEN",func():sim.set_ammo(index);_refresh_ui();_open_modal("Bewaffnung"),sim.ammo_mode==i,"normal" if sim.ammo_mode==i else "primary")
	_note("Vollkugeln, Ketten, Leucht, Kürbis, Schnee und Eis gegen Schiffe. Harpunen gegen Seeungeheuer. Leuchtkugeln markieren, Kürbisse splittern, Schnee bremst, Eis friert ein.")
	_action("AUSRÜSTUNG & NACHSCHUB IM HAFEN",func():_open_modal("Hafen"))

# --- Harbor, logbook and ranking -----------------------------------------------------------

func _open_harbor() -> void:
	var name="PORT AZUR" if sim.map_id==0 else "HAFEN"
	if not sim.has_harbor():
		_banner_card(painted.nav_harbor,"KEIN HAFEN AUF BONUSKARTEN","Über BONUSKARTE VERLASSEN kehrst du zurück; die aktuelle Welle bleibt gespeichert.")
	elif not sim.docked:
		_banner_card(painted.nav_harbor,"%s · AUSRÜSTUNG & VERSORGUNG" % name,"Fahre zum goldenen Hafensymbol und docke an. Dein Schiff liegt dort geschützt; die Patrouillen fahren weiter. Distanz: %d m." % roundi(sim.player.pos.distance_to(sim.harbor)))
		var go=_grid(2)
		_primary("KURS ZUM HAFEN",func():sim.course(sim.harbor);modal.hide(),go)
		var dock_button = _action("ANDOCKEN",func():
			if sim.dock():_save_progress();_open_modal("Hafen")
			_refresh_ui(),"normal",go)
		dock_button.disabled=not sim.can_dock()
	else:
		_banner_card(painted.nav_harbor,"%s · AUSRÜSTUNG & VERSORGUNG" % name,"Kapitänsstufe %d · %s Gold · Rumpf %s / %s" % [sim.level,_thousands(int(sim.player.gold)),_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))])
		_section("TROCKENDOCK & KASTELLE")
		var yard=_grid(2)
		var repair_cost = sim.harbor_repair_cost()
		var repair_button = _with_icon(_action("TROCKENDOCK · %d Gold" % repair_cost,func():sim.harbor_repair();_save_progress();_open_modal("Hafen");_refresh_ui(),"normal",yard),painted.gold_coins)
		repair_button.disabled=repair_cost<=0 or int(sim.player.gold)<repair_cost
		var built=0
		for key in CONTENT.UPGRADE_KEYS:built+=int(sim.upgrades[key])
		_with_icon(_action("KASTELLE · %d / %d STUFEN" % [built,CONTENT.UPGRADE_KEYS.size()*CONTENT.CASTLE_MAX],func():_open_modal("Kastelle"),"normal",yard),painted.nav_castles)
		_section("VORRÄTE")
		var supplies=_grid(2)
		for key: String in CONTENT.SUPPLY_KEYS:
			var supply=key
			var config: Dictionary=CONTENT.SUPPLIES[key]
			var buy=_with_icon(_action("%d× %s · %d Gold" % [config.pack,config.name,config.price],func():sim.buy_supply(supply);_save_progress();_open_modal("Hafen");_refresh_ui(),"normal",supplies),painted[config.icon])
			buy.disabled=int(sim.player.gold)<int(config.price)
		_section("KANONEN · %d AN BORD · %d PLÄTZE" % [sim.player.cannons,sim.cannon_slots()])
		var cannons=_with_icon(_action("2 KANONEN · %d Gold" % sim.cannon_price() if int(sim.player.cannons)<sim.MAX_CANNONS else "KANONENDECK VOLL",func():sim.buy_cannons();_save_progress();_open_modal("Hafen");_refresh_ui()),extra_icons.cannon_1)
		cannons.disabled=int(sim.player.cannons)>=sim.MAX_CANNONS or int(sim.player.gold)<sim.cannon_price()
		_section("MUNITIONSNACHSCHUB")
		var ammo=_grid(3)
		for i in 3:
			var index = i
			var buy = _with_icon(_action(["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_open_modal("Hafen");_refresh_ui(),"normal",ammo),icons[["cannonball","chain","harpoon"][i]])
			buy.disabled=int(sim.player.gold)<30
		_section("SONDERMUNITION · JE 12 FÜR 80 GOLD")
		var special_stock=_grid(2)
		for i in range(3,AMMO_UI.size()):
			var index=i
			var buy=_action("12 %s · 80 GOLD" % AMMO_UI[i].name,func():sim.buy_ammo(index);_save_progress();_open_modal("Hafen");_refresh_ui(),"normal",special_stock)
			buy.disabled=int(sim.player.gold)<80
			_with_icon(buy,_ammo_texture(i))
		_section("HAFENDIENSTE")
		var services=_grid(2)
		_with_icon(_action("DECKS & DECKWERFT",func():_open_modal("Decks"),"normal",services),painted.tide_deck)
		_with_icon(_action("GEZEITENKESSEL",func():_open_modal("Kessel"),"normal",services),painted.nav_kessel)
		_with_icon(_action("SCHIFFSDESIGN WÄHLEN · %d DESIGNS" % skins.size(),func():_open_modal("Werft"),"normal",services),painted.nav_shipyard)
		_with_icon(_action("SEEKARTEN",func():_open_modal("Seekarten"),"normal",services),painted.nav_charts)
		_primary("ABLEGEN",func():sim.depart();modal.hide();_save_progress();_refresh_ui())
	if not sim.docked:
		var more=_grid(2)
		_action("KASTELLE ANSEHEN",func():_open_modal("Kastelle"),"normal",more)
		_action("SEEKARTEN",func():_open_modal("Seekarten"),"normal",more)
	_action("UPDATES PRÜFEN",func():
		_save_progress()
		get_tree().set_meta("abyssal_manual_update",true)
		get_tree().change_scene_to_file("res://updater/launcher.tscn"))

func _open_logbook() -> void:
	_banner_card(painted.nav_quests,"KAPITÄNSLOGBUCH · AUFTRÄGE & FORTSCHRITT","Lv. %d · Erfahrung %d / %d · %d geborgene Kisten · %d besiegte Seeungeheuer" % [sim.level,sim.xp,sim.xp_required(),sim.loot_collected,sim.monster_kills])
	for i in CONTENT.QUESTS.size():
		var q: Dictionary = CONTENT.QUESTS[i]
		if i < sim.quest_index:
			_row(null,"ERLEDIGT · %s\n%s" % [q.name,q.description],48,Color("6fd37a"))
		elif i==sim.quest_index:
			var column=_row(painted.reward_chest,"AKTIV · %s\n%s · %d/%d\nBelohnung: %d Gold und %d EP" % [q.name,q.description,mini(sim.quest_progress(),int(q.goal)),q.goal,q.gold,q.xp],56,Color("ffd27a"))
			var claim = _row_button(column,"BELOHNUNG ABHOLEN",func():sim.claim_quest();_save_progress();_open_modal("Logbuch");_refresh_ui(),sim.quest_progress()<int(q.goal),"primary")
			claim.custom_minimum_size.y=44
		else:
			var label: Label=_row(null,"%d · %s\n%s" % [i+1,q.name,q.description],48).get_child(0)
			label.add_theme_color_override("font_color",Color("84999c"))
	_section("LETZTE MELDUNGEN")
	var recent=message_history.duplicate();recent.reverse()
	_note("\n".join(recent) if not recent.is_empty() else "Noch keine Meldungen",Color("d6e2e4"))

func _open_ranking() -> void:
	var ranks=["Schiffsjunge","Matrose","Bootsmann","Steuermann","Leutnant","Kapitän","Kommodore","Admiral"]
	_banner_card(painted.nav_ranking,"KAPITÄNSRANG · %s" % ranks[clampi(floori((sim.level-1)/2.5),0,ranks.size()-1)].to_upper(),"Kapitänsstufe %d · Erfahrung %s / %s\nGold %s\nVersenkte Schiffe %d · davon Elite %d\nSeeungeheuer %d · Beutekisten %d\nAufträge %d / %d · Seegebiete %d / %d" % [sim.level,_thousands(sim.xp),_thousands(sim.xp_required()),_thousands(int(sim.player.gold)),sim.kills,sim.elite_kills,sim.monster_kills,sim.loot_collected,mini(sim.quest_index,CONTENT.QUESTS.size()),CONTENT.QUESTS.size(),sim.visited.count(true),CONTENT.REGION_COUNT])
	var grid=_grid(2)
	_stat(grid,"BONUSKARTEN GESCHAFFT",str(sim.bonus_runs),painted.nav_bonus)
	_stat(grid,"KESSELWÜRFE",str(sim.kessel_throws),painted.nav_kessel)
	_stat(grid,"ZERSTÖRTE TÜRME",str(sim.tower_kills),painted.tower_cannon)
	_stat(grid,"FESTUNGSEROBERUNGEN",str(sim.fortress_conquests),painted.nav_guild)
	_note("Gilde %s" % ("[%s] %s" % [sim.guild.tag,sim.guild.name] if not sim.guild.is_empty() else "keine"),Color("ffd27a"))
	if sim.staff_marked or sim.staff.touched:
		_note("Dieser Spielstand wurde mit Staff-Werkzeugen verändert und zählt später nicht für öffentliche Ranglisten.",Color("e7957a"))
	_note("Diese Rangliste zählt deinen Fortschritt auf diesem Gerät. Ranglisten gegen andere Kapitäne und Gilden kommen mit dem Online-Server.",Color("84999c"))

# --- Castles, decks, cauldron, bonus maps and guild -------------------------------------------

func _upgrade_row(key: String) -> void:
	var config: Dictionary=CONTENT.UPGRADES[key]
	var art_key = key+"_%d" % mini(2,int(sim.upgrades[key])) if key in ["cannon","harpoon"] else str(config.icon)
	var stage=int(sim.upgrades[key])
	var column=_row(_art(art_key),"%s · %s · Stufe %d/%d\n%s" % [config.name,config.role,stage,CONTENT.CASTLE_MAX,config.effect],68,Color("c9a35e") if stage>0 else Color(0,0,0,0))
	var pips=Control.new();pips.custom_minimum_size=Vector2(0,12);pips.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(pips)
	pips.draw.connect(func():
		for i in CONTENT.CASTLE_MAX:
			var c=Vector2(8+i*16,6)
			SEA_MARKS.gem(pips,c,5.5,Color("f2c14e"),-1,i<stage))
	var cost: int=sim.upgrade_cost(key)
	var gated=cost>=0 and stage>=sim.castle_cap()
	var text="MAXIMALE STUFE" if cost<0 else ("AB KAPITÄNSSTUFE %d" % ((stage-2)*3) if gated else "VERBESSERN · %d Gold" % cost)
	var button = _row_button(column,text,func():sim.buy_upgrade(key);_save_progress();_open_modal("Kastelle");_refresh_ui(),cost<0 or gated or not sim.docked or int(sim.player.gold)<cost,"primary")
	button.custom_minimum_size.y=42
	if cost>=0 and not gated:_with_icon(button,painted.gold_coins)

func _deck_title(deck: Dictionary) -> String:
	return "%s %s" % [CONTENT.DECKS[str(deck.type)].name,CONTENT.DECK_TIERS[int(deck.tier)]]

func _deck_effect(deck: Dictionary) -> String:
	var config: Dictionary=CONTENT.DECKS[str(deck.type)]
	return str(config.effect) % int(config.values[int(deck.tier)])

const DECK_ART := {"cannon":"cannon_1","armor":"upgrade_hull","hunter":"harpoon_1","navigation":"upgrade_sails","logistics":"castle_crew"}

func _open_decks() -> void:
	var stage=Control.new();stage.custom_minimum_size=Vector2(0,118);stage.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.draw.connect(func():
		stage.draw_style_box(SKIN.card(),Rect2(Vector2.ZERO,stage.size))
		SEA_MARKS.deck_badge(stage,Vector2(stage.size.x*.5,43),11,sim)
		_canvas_text(stage,Vector2(stage.size.x*.5,94),"10 DECKPLÄTZE · ZWEI REIHEN MIT JE FÜNF",12,Color("ecd29a"))
		_canvas_text(stage,Vector2(stage.size.x*.5,111),"GOLD · ORANGE/GELB     ELITE · BLAU     KRISTALL · LILA",11,Color("c4d5db")))
	modal_body.add_child(stage)
	_section("MONTIERTE DECKS")
	for slot in CONTENT.DECK_SLOT_COUNT:
		var place=slot
		var index=int(sim.deck_slots[slot])
		if index<0:
			_row(null,"PLATZ %d · FREI" % (slot+1),34,Color("4a4234"));continue
		var deck: Dictionary=sim.decks[index]
		var column=_row(_art(DECK_ART[str(deck.type)]),"PLATZ %d · %s\n%s" % [slot+1,_deck_title(deck),_deck_effect(deck)],48,CONTENT.DECK_TIER_COLORS[int(deck.tier)])
		_row_button(column,"ABBAUEN",func():sim.unequip_deck(place);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked)
	_section("SONDERDECKS & SEGEN")
	var tide=float(sim.buffs.tide_deck)
	_row(painted.tide_deck,"GEZEITENDECK · "+("aktiv %s · +10 Kanonenplätze" % _clock_text(tide) if tide>0 else "aus Gezeitenkessel und Meilensteinen"),48,SEA_MARKS.DECK_COLORS.tide)
	for key: String in CONTENT.SPECIAL_DECKS:
		var special_key=key
		var config: Dictionary=CONTENT.SPECIAL_DECKS[key]
		var left=float(sim.buffs[key])
		var special=_row(painted[config.icon],"%s · %s\n%s" % [str(config.name).to_upper(),_clock_text(left) if left>0 else "INAKTIV",config.effect],48,config.color)
		var caption="30 MIN · %d GOLD" % config.price if sim.level>=int(config.level) else "AB KAPITÄNSSTUFE %d" % config.level
		_row_button(special,caption,func():sim.buy_special_deck(special_key);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked or sim.level<int(config.level) or int(sim.player.gold)<int(config.price))
	_row(painted.crystal_blessing,"KRISTALLSEGEN · "+(_clock_text(float(sim.buffs.blessing)) if sim.has_blessing() else "nicht aktiv · aus dem Gezeitenkessel"),48,Color("bd78f2"))
	if not sim.docked:_note("Decks werden angedockt im Hafen umgebaut.",Color("edc68c"))
	_section("DECKLAGER · %d / %d" % [sim.decks.size(),CONTENT.DECK_INVENTORY_MAX])
	if sim.decks.is_empty():_note("Golddecks kaufst du in der Deckwerft. Im Hafen verbesserst du sie später zu Elite und Kristall.")
	for i in sim.decks.size():
		var index=i
		var deck: Dictionary=sim.decks[i]
		var column=_row(_art(DECK_ART[str(deck.type)]),"%s\n%s" % [_deck_title(deck),_deck_effect(deck)],48,CONTENT.DECK_TIER_COLORS[int(deck.tier)])
		var controls=HBoxContainer.new();controls.add_theme_constant_override("separation",6);column.add_child(controls)
		var picker=OptionButton.new();picker.custom_minimum_size=Vector2(118,40);picker.add_theme_font_size_override("font_size",13)
		for slot in CONTENT.DECK_SLOT_COUNT:picker.add_item("Platz %d" % (slot+1))
		var mounted=sim.deck_slots.find(i)
		picker.select(mounted if mounted>=0 else maxi(0,sim.deck_slots.find(-1)))
		controls.add_child(picker)
		_row_button(controls,"MONTIEREN",func():sim.equip_deck(index,picker.selected);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked)
		var tier=int(deck.tier)
		if tier<CONTENT.DECK_TIERS.size()-1:
			var level=int(CONTENT.DECK_UPGRADE_LEVEL[tier]);var gold=int(CONTENT.DECK_UPGRADE_GOLD[tier]);var essence=int(CONTENT.DECK_UPGRADE_ESSENCE[tier])
			var text="ZU %s · %d GOLD%s" % [str(CONTENT.DECK_TIERS[tier+1]).to_upper(),gold," · %d ESSENZ" % essence if essence>0 else ""]
			if sim.level<level:text="%s AB KAPITÄNSSTUFE %d" % [str(CONTENT.DECK_TIERS[tier+1]).to_upper(),level]
			_row_button(column,text,func():sim.upgrade_deck(index);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked or sim.level<level or int(sim.player.gold)<gold or sim.essence<essence,"primary")
	if sim.docked:
		_section("DECKWERFT · GOLDDECKS")
		var yard=_grid(2)
		for key: String in CONTENT.DECK_KEYS:
			var type=key
			var config: Dictionary=CONTENT.DECKS[key]
			var buy=_with_icon(_action("%s · %d GOLD" % [config.name,config.price],func():sim.buy_deck(type);_save_progress();_open_modal("Decks");_refresh_ui(),"normal",yard),_art(DECK_ART[key]))
			buy.disabled=sim.decks.size()>=CONTENT.DECK_INVENTORY_MAX or int(sim.player.gold)<int(config.price)
	_note("Gekaufte Decks sind einzelne Exemplare. Gleiche Funktionen dürfen auf mehreren Plätzen sitzen. Doppelte Kesselbelohnungen werden weiterhin in %d Gezeitenessenz umgewandelt." % CONTENT.DUPLICATE_DECK_ESSENCE)

func _open_kessel() -> void:
	var stage=KESSEL_FX.new()
	stage.name="KesselStage"
	stage.art=painted.kessel_scene;stage.flask=painted.essence_flask;stage.font=font
	stage.throw=kessel_throw
	stage.custom_minimum_size=Vector2(0,clampf(modal_scroll.size.x*.42,170.0,250.0))
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_child(stage)
	var today=Time.get_date_string_from_system()
	var purse=_row(painted.essence_flask,"GEZEITENESSENZ · %d" % sim.essence,44,Color("3fe8cf"))
	var hint=_text(purse,"Glitzernde Strömungen, versenkte Gegner, Aufträge, Bonuskarten und die Korsarenfestung bringen Essenz." if sim.docked else "Der Kessel steht im Hafen. Zum Werfen zuerst andocken.",12,Color("bac7c7") if sim.docked else Color("edc68c"))
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var flask=_with_icon(_primary("TAGESFLASCHE · KOSTENLOS" if sim.free_flask_ready(today) else "TAGESFLASCHE · MORGEN WIEDER",func():_kessel_results(sim.claim_free_flask(today))),painted.essence_flask)
	flask.disabled=not sim.docked or not sim.free_flask_ready(today)
	var throws=HBoxContainer.new();throws.add_theme_constant_override("separation",6);modal_body.add_child(throws)
	for amount: int in CONTENT.KESSEL_THROWS:
		var count=amount
		var button=_row_button(throws,"×%d" % amount,func():_kessel_results(sim.throw_kessel(count,today)),not sim.docked or sim.essence<amount,"primary")
		button.custom_minimum_size.y=46
		button.add_theme_font_size_override("font_size",17)
	_section("KESSELMETER · %d / %d" % [sim.kessel_meter,CONTENT.KESSEL_CYCLE])
	var meter=_bar(modal_body)
	meter.max_value=CONTENT.KESSEL_CYCLE;meter.value=sim.kessel_meter;meter.custom_minimum_size.y=16
	var meter_style: StyleBoxFlat=meter.get_theme_stylebox("fill").duplicate();meter_style.bg_color=Color("3fc7b8");meter.add_theme_stylebox_override("fill",meter_style)
	var steps=_grid(4)
	for milestone: Dictionary in CONTENT.KESSEL_MILESTONES:
		var reached=sim.kessel_meter>=int(milestone.at)
		var card=_card(Color("ffc04d") if reached else Color(0,0,0,0),steps)
		var label=_text(card,"%d · %s\n%s" % [milestone.at,"ERREICHT" if reached else "OFFEN",milestone.name],12,Color("fff0c8") if reached else Color("bac7c7"))
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var age=(Time.get_ticks_msec()-int(kessel_throw.get("start",-1000000)))/1000.0
	if not kessel_throw.is_empty() and age<60.0:
		var shown: Array=kessel_throw.results
		_section("AUSBEUTE · %d %s" % [shown.size(),"FUND" if shown.size()==1 else "FUNDE"])
		var loot=_grid(2)
		for i in mini(shown.size(),12):
			var entry: Dictionary=shown[i]
			var rarity=clampi(int(entry.rarity),0,3)
			var card=_row(entry.icon,"%s%s\n%s" % ["MEILENSTEIN · " if bool(entry.get("milestone",false)) else "",entry.text,CONTENT.RARITIES[rarity]],34,RARITY_INK[rarity],loot).get_parent().get_parent()
			var delay=KESSEL_FX.FLY+KESSEL_FX.FLASH+.08*i-age
			if delay>0:
				card.modulate.a=0.0
				var fade=card.create_tween()
				fade.tween_interval(delay)
				fade.tween_property(card,"modulate:a",1.0,.28)
		if shown.size()>12:_note("… und %d weitere Funde im Wurfprotokoll" % (shown.size()-12))
	if not kessel_log.is_empty():
		_section("LETZTE WÜRFE")
		var recent=kessel_log.duplicate();recent.reverse()
		_note("\n".join(PackedStringArray(recent.slice(0,8))),Color("e2ecee"))
	_section("PREISTABELLE · OFFEN EINSEHBAR")
	var table=_grid(2)
	for entry: Dictionary in CONTENT.KESSEL_POOL:
		var pack=" ×%d" % int(entry.amount) if int(entry.amount)>1 and str(entry.id)!="tide_deck" else ""
		var label=_note("%d %% · %s%s · %s" % [entry.weight,entry.name,pack,CONTENT.RARITIES[int(entry.rarity)]],RARITY_INK[int(entry.rarity)],table)
		label.add_theme_font_size_override("font_size",13)
	_note("Doppelte Decks werden in %d Essenz umgewandelt. Essenz gibt es nur im Spiel, nicht gegen Echtgeld." % CONTENT.DUPLICATE_DECK_ESSENCE,Color("84999c"))

func _result_icon(id: String) -> Texture2D:
	if id=="fragment" or id.begins_with("scroll"):return painted.scroll_fragment
	if id.begins_with("deck_"):return _art(DECK_ART.get(id.split("_")[1],"cannon_1"))
	match id:
		"ammo0":return icons.cannonball
		"ammo1":return icons.chain
		"ammo2":return icons.harpoon
		"powder":return painted.supply_powder
		"plates":return painted.supply_plates
		"gold":return painted.gold_coins
		"repair_kit":return painted.supply_repair
		"shield_charge":return painted.supply_shield
		"essence":return painted.essence_flask
		"tide_deck":return painted.tide_deck
		"blessing":return painted.crystal_blessing
	return painted.reward_chest

func _kessel_results(results: Array) -> void:
	var shown: Array=[]
	for result: Dictionary in results:
		var milestone=bool(result.get("milestone",false))
		kessel_log.append("%s%s · %s" % ["MEILENSTEIN · " if milestone else "",result.text,CONTENT.RARITIES[clampi(int(result.rarity),0,3)]])
		shown.append({"icon":_result_icon(str(result.id)),"rarity":int(result.rarity),"milestone":milestone,"text":str(result.text)})
	while kessel_log.size()>24:kessel_log.pop_front()
	if not shown.is_empty():kessel_throw={"start":Time.get_ticks_msec(),"results":shown}
	_save_progress()
	_open_modal("Kessel")
	_refresh_ui()

func _open_bonus() -> void:
	_banner_card(painted.nav_bonus,"BONUSKARTEN · FÜNF WELLEN · CHECKPOINT","Schriftrollenfragmente %d · Schriftrollen: Bronze %d · Silber %d · Gold %d\nAbgeschlossene Bonuskarten %d" % [sim.fragments,sim.scrolls[0],sim.scrolls[1],sim.scrolls[2],sim.bonus_runs])
	if not sim.bonus.is_empty():
		var tier: Dictionary=CONTENT.BONUS_TIERS[int(sim.bonus.tier)]
		var done=str(sim.bonus.state)=="done"
		var text="%s-BONUSKARTE · %s" % [str(tier.name).to_upper(),"GESCHAFFT" if done else "WELLE %d/%d" % [mini(int(sim.bonus.wave)+1,CONTENT.BONUS_WAVES.size()),CONTENT.BONUS_WAVES.size()]]
		if bool(sim.bonus.get("staff",false)):text+=" · STAFF-TESTLAUF"
		if done and sim.bonus.has("chest"):text+="\nTruhe: "+str(sim.bonus.chest)
		var column=_row(painted.reward_chest if done else painted.boss_wave,text,64,Color("ffc04d"))
		if sim.in_bonus_map():_row_button(column,"BONUSKARTE VERLASSEN",func():modal.hide();_interact(),false,"danger")
	var tints=[Color("cd8a4c"),Color("c9d2d6"),Color("ffd27a")]
	for i in CONTENT.BONUS_TIERS.size():
		var index=i
		var tier: Dictionary=CONTENT.BONUS_TIERS[i]
		var region: Dictionary=CONTENT.MAPS[int(tier.map)]
		var running=not sim.bonus.is_empty() and int(sim.bonus.tier)==i
		var column=_row(painted.scroll_fragment,"%s-SCHRIFTROLLE · %s %s\nAb Lv. %d · Gegnerstärke ×%s · %d Fragmente · %d im Lager" % [str(tier.name).to_upper(),region.name,region.code,tier.level,str(region.enemy_scale).replace(".",","),tier.fragments,sim.scrolls[i]],64,tints[i])
		var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",6);column.add_child(buttons)
		_row_button(buttons,"ZUSAMMENSETZEN",func():sim.craft_scroll(index);_save_progress();_open_modal("Bonuskarten");_refresh_ui(),sim.fragments<int(tier.fragments))
		var blocked=sim.in_bonus_map() or sim.level<int(tier.level) or (not running and (int(sim.scrolls[i])<=0 or not sim.bonus.is_empty()))
		_row_button(buttons,"FORTSETZEN" if running else ("AB LV. %d" % tier.level if sim.level<int(tier.level) else "STARTEN"),func():_start_bonus(index),blocked,"primary")
	_section("WELLEN")
	var waves=_grid(5)
	for i in CONTENT.BONUS_WAVES.size():
		var wave: Dictionary=CONTENT.BONUS_WAVES[i]
		var card=_card(Color("ff6a4d") if not str(wave.boss).is_empty() else Color(0,0,0,0),waves)
		_text(card,"%d · %s" % [i+1,wave.label],13,Color("fff0c8"))
	_note("Jede Welle zahlt Gold und 1 Gezeitenessenz. Die Truhe am Ende enthält Pulver, Platten, eine Notreparatur, einen Kristallsegen und ein Deck der Kartenstufe.\nKein Lebenssystem: Wirst du versenkt, geht es nach 8 Sekunden an derselben Welle weiter. Verlassen speichert die aktuelle Welle.")
	_note("Fragmente gibt es aus dem Kessel und der Korsarenfestung.",Color("84999c"))

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
	field.add_theme_color_override("font_placeholder_color",Color("7d8a86"))
	var skin=SKIN.bevel(Color("06141a"),Color("0b1d26"),Color("6b5634"),6.0,10.0)
	skin.sheen=0.0;skin.shadow=.2;skin.inner=Color(0,0,0,.6)
	field.add_theme_stylebox_override("normal",skin)
	var focus=SKIN.bevel(Color("06141a"),Color("0b1d26"),GOLD,6.0,10.0)
	focus.sheen=0.0;focus.glow=Color("f5d78d",.5)
	field.add_theme_stylebox_override("focus",focus)
	modal_body.add_child(field)
	return field

func _open_guild() -> void:
	_banner_card(painted.nav_guild,"GILDE · LOKALE VORSCHAU","Gilden laufen in dieser Version lokal auf deinem Gerät. Mitglieder, Gildenchat und Gildenkriege kommen mit dem Online-Server.")
	if sim.guild.is_empty():
		_section("GILDE GRÜNDEN")
		_note("Gründe deine Gilde für %d Gold. Das Kürzel steht vor deinem Schiffsnamen und auf gehaltenen Türmen. Kürzel wie ADM, GM oder MOD sind dem Spielteam vorbehalten." % CONTENT.GUILD_COST)
		guild_name_input=_line_edit("Gildenname · 3 bis 24 Zeichen",24)
		guild_tag_input=_line_edit("Kürzel · 2 bis 4 Buchstaben oder Ziffern",4)
		var found=_with_icon(_primary("GILDE GRÜNDEN · %d Gold" % CONTENT.GUILD_COST,func():
			sim.found_guild(guild_name_input.text,guild_tag_input.text)
			_save_progress();_open_modal("Gilde");_refresh_ui()),painted.gold_coins)
		found.disabled=int(sim.player.gold)<CONTENT.GUILD_COST
	else:
		_row(painted.nav_guild,"[%s] %s\nAnführer: du (lokal)" % [sim.guild.tag,sim.guild.name],48,Color("ffd27a"))
	_section("GILDENINSEL · KORSARENFESTUNG")
	var towers=_grid(4)
	for config: Dictionary in CONTENT.TOWERS:
		var card=_card(Color(0,0,0,0),towers)
		var column=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(column)
		_picture(column,painted["tower_"+str(config.kind)],56,false)
		var label=_text(column,str(config.name),12,Color("fff0c8"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.clip_text=true
	var state=""
	if sim.guild_island_held():state="[%s] hält die Insel noch %s · +10 %% Beutegold · die Türme feuern nicht auf dich" % [sim.guild.tag,_clock_text(sim.fortress_hold)]
	elif sim.map_id==CONTENT.FORTRESS_MAP:state="Gehalten von [%s] · %d von %d Türmen stehen" % [CONTENT.FORTRESS_TAG,sim.towers_alive(),CONTENT.TOWERS.size()]
	else:state="Schattengewässer %s · ab Lv. %d · gehalten von [%s]" % [CONTENT.MAPS[CONTENT.FORTRESS_MAP].code,CONTENT.MAPS[CONTENT.FORTRESS_MAP].level,CONTENT.FORTRESS_TAG]
	_info(state)
	_note("Kanonenturm: Doppelschuss · Mörserturm: weite Bögen · Kettenturm: bremst · Wächterturm: lädt die Schilde der anderen Türme. Zerstöre alle vier für +900 Gold, +3 Essenz und +2 Fragmente. Mit Gilde hältst du die Insel 30 Minuten.")
	_note("Eroberungen %d · zerstörte Türme %d" % [sim.fortress_conquests,sim.tower_kills],Color("ffd27a"))
	if sim.map_id==CONTENT.FORTRESS_MAP:
		var course=_primary("KURS ZUR FESTUNG",func():
			var island: Dictionary=sim.fortress_island()
			sim.course(Vector2(island.bounds.get_center().x,island.bounds.end.y+140))
			modal.hide();_refresh_ui())
		course.disabled=sim.docked
	else:
		var travel=_primary("KURS SCHATTENGEWÄSSER",func():_navigate_region(CONTENT.FORTRESS_MAP))
		travel.disabled=sim.docked or sim.in_bonus_map() or sim.level<int(CONTENT.MAPS[CONTENT.FORTRESS_MAP].level)
	if not sim.guild.is_empty():_action("GILDE AUFLÖSEN",func():sim.leave_guild();_save_progress();_open_modal("Gilde");_refresh_ui(),"danger")

# --- Sea charts and the chart guide -----------------------------------------------------------

func _open_charts() -> void:
	if _tab("Seekarten")=="ANLEITUNG":
		_open_chart_guide()
		return
	var chart=WORLD_CHART.new()
	chart.name="WorldChart"
	chart.sim=sim;chart.parchment=painted.chart_parchment;chart.font=font
	chart.selected=chart_pick if chart_pick>=0 else sim.map_id
	chart.custom_minimum_size=Vector2(0,clampf(modal_scroll.size.x*.56,230.0,380.0))
	chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chart.picked.connect(func(index: int):chart_pick=index;_open_modal("Seekarten"))
	modal_body.add_child(chart)
	_note("Tippe auf ein Seegebiet der Karte für Details. Die Karten-Anleitung erklärt Koordinaten, Portale und die Minikarte.",Color("84999c"))
	_chart_details(chart.selected)

func _chart_details(index: int) -> void:
	var staff=sim.staff
	if index==WORLD_CHART.FORTRESS_NODE:
		var column=_row(painted.tower_guardian,"KORSARENFESTUNG · IN %s %s\nGehalten von [%s] · %d Türme · ab Lv. %d" % [CONTENT.MAPS[CONTENT.FORTRESS_MAP].code,CONTENT.MAPS[CONTENT.FORTRESS_MAP].name,sim.tower_tag(),CONTENT.TOWERS.size(),CONTENT.MAPS[CONTENT.FORTRESS_MAP].level],64,Color("ff6a4d"))
		var line=HBoxContainer.new();line.add_theme_constant_override("separation",6);column.add_child(line)
		_row_button(line,"GILDE & FESTUNG",func():_open_modal("Gilde"))
		if staff.active():_row_button(line,"STAFF-TELEPORT",func():_staff(func():sim.staff_teleport(CONTENT.FORTRESS_MAP,"fortress"),true),not staff.can("map" if sim.map_id!=CONTENT.FORTRESS_MAP else "teleport"),"staff")
		return
	var region: Dictionary=CONTENT.MAPS[index]
	var bonus=bool(region.get("bonus",false))
	var locked=sim.level<int(region.level)
	var hostile=bool(region.npc_hostile)
	var lines: Array[String]=["%s · %s" % [region.code,str(region.name).to_upper()]]
	lines.append("Ab Kapitänsstufe %d%s · %s" % [region.level," · GESPERRT" if locked else "","feindliche Gewässer" if hostile else "neutrale Patrouillen"])
	if bonus:
		var tier=index-CONTENT.REGION_COUNT
		lines.append("Nur mit %s-Schriftrolle · 5 Wellen bis zum Leviathan · Gegnerstärke ×%s" % [CONTENT.BONUS_TIERS[tier].name,str(region.enemy_scale).replace(".",",")])
		lines.append("Kein Hafen, keine Portale · Ausgang über BONUSKARTE VERLASSEN")
	else:
		lines.append("Hafen: ja · Portale: Ost → %s · West → %s" % [CONTENT.MAPS[(index+1)%CONTENT.REGION_COUNT].code,CONTENT.MAPS[(index+2)%CONTENT.REGION_COUNT].code])
		lines.append("16 Patrouillen, davon Elite-Schiffe · Seeungeheuer Tiamat · Gegnerstärke ×%s" % str(region.enemy_scale).replace(".",","))
		if index==CONTENT.FORTRESS_MAP:lines.append("Korsarenfestung mit vier Türmen · Gildeninsel")
	var column=_row(extra_icons.world_chart,"\n".join(lines),64,Color("a02818") if hostile else Color("2f6b3a"))
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",6);column.add_child(line)
	if bonus:
		_row_button(line,"BONUSKARTEN",func():_open_modal("Bonuskarten"))
	elif index==sim.map_id:
		_row_button(line,"DU BIST HIER",func():pass,true)
	else:
		var text="GESPERRT · LV. %d" % region.level if locked else ("PORTAL BETRETEN" if sim.near_portal()==index else "KURS ZUM PORTAL")
		_row_button(line,text,func():_navigate_region(index),locked or sim.docked or sim.in_bonus_map(),"primary")
	if staff.active():
		_row_button(line,"STAFF-TELEPORT",func():_staff(func():sim.staff_teleport(index,"start"),true),not staff.can("map" if index!=sim.map_id else "teleport") or index==sim.map_id,"staff")

func _open_chart_guide() -> void:
	_section("KOORDINATEN & PLANQUADRATE")
	_note("Die Seekarte ist in Planquadrate geteilt. Spalten tragen Zahlen, Zeilen Buchstaben. Die Minikarte zeigt oben Kartencode und dein Planquadrat; die Lineale am Bildrand zeigen dieselben Namen für den sichtbaren Ausschnitt.")
	_guide("grid")
	_section("KARTENCODES")
	var codes: Array[String]=[]
	for map: Dictionary in CONTENT.MAPS:
		codes.append("%s %s · ab Lv. %d · %s" % [map.code,map.name,map.level,"Bonuskarte, nur mit Schriftrolle" if bool(map.get("bonus",false)) else ("feindlich" if map.npc_hostile else "neutral")])
	_note("\n".join(codes),Color("e2ecee"))
	_section("PORTALE")
	_note("Jede Seekarte hat ein Portal im Osten und eines im Westen; zusammen bilden sie einen Ring 1-1 → 2-1 → 3-1. Portal antippen setzt Kurs, beim Erreichen wechselt das Schiff automatisch. Nach einem Treffer wartet das Portal 6 Sekunden. Gesperrte Portale zeigen AB LV. und lassen dich erst mit der Kapitänsstufe hinüber.")
	_section("HAFEN & ANDOCKEN")
	_note("Das goldene Anker-Symbol ist der Hafen. Innerhalb von 160 m und 6 Sekunden ohne Treffer kannst du andocken: Trockendock, Vorräte, Kanonen, Decks, Kastelle und der Gezeitenkessel. Angedockt bist du geschützt; ABLEGEN bringt dich zurück auf See.")
	_section("NEUTRAL ODER FEINDLICH")
	_note("In neutralen Gewässern greifen Patrouillen erst an, wenn du sie beschießt. In feindlichen Gewässern eröffnen sie in der Nähe von selbst das Feuer. Die Farbe des Namens verrät es:")
	_guide("colors")
	_section("BONUSKARTEN & FESTUNG")
	_note("Bonuskarten B-1 bis B-3 erreichst du nur mit einer Schriftrolle aus Fragmenten. Fünf Wellen, Checkpoint nach jeder Welle, Truhe am Ende. Die Korsarenfestung liegt in den Schattengewässern 3-1: vier Türme, und mit Gilde hältst du die Insel 30 Minuten.")
	_section("MINIKARTE · LEGENDE")
	_guide("legend")
	_section("STEUERUNG AUF DER KARTE")
	_note("Freies Wasser antippen: Kurs setzen. Schiff antippen: Ziel wählen, dann FEUER. Minikarte antippen: Kurs dorthin. Joystick links unten bewegt nur die Kamera, das Fadenkreuz holt sie zurück. Zwei Finger oder Mausrad: Zoom.")

func _guide(mode: String) -> void:
	var diagram=CHART_GUIDE.new()
	diagram.mode=mode;diagram.font=font
	diagram.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_child(diagram)

# --- Display settings and game info -------------------------------------------------------

func _open_display() -> void:
	_banner_card(hud_icons.gear,"DEINE SEEKARTE · DEINE OBERFLÄCHE","Wähle die Größe für Anzeigen, Karte und Kampfbuttons. Die Spielwelt behält ihre eigene Zoomstufe. Deine Auswahl bleibt auf diesem Gerät gespeichert.")
	_section("HUD-GRÖSSE")
	for i in 3:
		var index=i
		var choice=_action((["KOMPAKT · mehr freie Seekarte","KOMFORT · größere Anzeigen","GROSS · beste Lesbarkeit"][i])+(" · AKTIV" if hud_size==i else ""),func():_set_display(index,journal_visible),"tab_on" if hud_size==i else "normal")
		choice.disabled=hud_size==i
	_section("LEISTEN")
	var toggles=_grid(2)
	_action("AUFTRAGSLEISTE: "+("EIN" if journal_visible else "AUS"),func():_set_display(hud_size,not journal_visible),"normal",toggles)
	_action("JOYSTICK: "+("EIN" if camera_pad_visible else "AUS"),func():camera_pad_visible=not camera_pad_visible;_set_display(hud_size,journal_visible),"normal",toggles)
	_note("Die Auftragsleiste oben links öffnet das Logbuch. Der Joystick bewegt nur die Kamera: Seekarte erkunden, das Schiff hält seinen Kurs. Gefahren wird per Antippen. Fadenkreuz an der Karte: zurück zum Schiff. Fernrohr: nächstes sichtbares Ziel.")
	_action("STANDARD WIEDERHERSTELLEN",func():camera_pad_visible=true;_set_display(1,true))

func _open_info() -> void:
	var links=_grid(2)
	_with_icon(_action("SEEKARTEN",func():_open_modal("Seekarten"),"normal",links),painted.nav_charts)
	_with_icon(_action("KARTEN-ANLEITUNG",func():modal_tab["Seekarten"]="ANLEITUNG";_open_modal("Seekarten"),"normal",links),extra_icons.world_chart)
	_with_icon(_action("KASTELLE",func():_open_modal("Kastelle"),"normal",links),painted.nav_castles)
	_with_icon(_action("ANZEIGE & HUD ANPASSEN",func():_open_modal("Anzeige"),"normal",links),hud_icons.gear)
	_with_icon(_action("STAFF-ZUGANG",func():_open_modal("Staff"),"staff",links),painted.staff_seal)
	_action("UPDATES PRÜFEN",func():_save_progress();get_tree().set_meta("abyssal_manual_update",true);get_tree().change_scene_to_file("res://updater/launcher.tscn"),"normal",links)
	_section("ABYSSAL DOMINION · STEUERUNG")
	_note("Tippe auf freies Wasser zum Fahren. Tippe auf ein Schiff und anschließend FEUER.\nVoll- und Kettenkugeln wirken gegen Schiffe und Türme, Harpunen gegen Seeungeheuer.\nFahre über Beute, um Gold einzusammeln, und durch glitzernde Strömungen für Gezeitenessenz.",Color("e2ecee"))
	_section("RUMPF, SCHILD & SCHNELLLEISTE")
	_note("Der Schild fängt Treffer zuerst ab und lädt sich 8 Sekunden nach dem letzten Treffer wieder auf. REP repariert den Rumpf ohne Gegenstand.\nPulver schaltet +40 % Salvenschaden ein und verbraucht nur bei einer gültigen Salve. Der Pfeilknopf wechselt zu Notreparatur, Schildladung und Panzerplatten.",Color("e2ecee"))
	_section("HAFEN, KESSEL, BONUSKARTEN, GILDE")
	_note("HAFEN: Trockendock, Vorräte, Kanonen, Decks und Kastelle.\nKESSEL: Gezeitenessenz einwerfen, offene Preistabelle, Meilensteine bei 10, 25, 50 und 100.\nBONUSKARTEN: Fragmente zu Schriftrollen zusammensetzen, fünf Wellen mit Checkpoint.\nGILDE: Kürzel vor dem Schiffsnamen, Korsarenfestung mit vier Türmen in den Schattengewässern.",Color("e2ecee"))
	_section("TASTEN & GESTEN")
	_note("Zwei Finger / Mausrad / Plus und Minus an der Karte: Zoom. Joystick links unten oder Ziehen / rechte Maustaste: Kamera. Fernrohr / Tab: nächstes Ziel. Tasten 1 bis 3 Munition, 8 Leucht, 9 Kürbis, 0 Schnee, Minus Eis, 4 bis 7 Gegenstände, Q Schnellleiste.\n\nGastfortschritt wird auf diesem Gerät gespeichert. Lokales Spiel; noch kein öffentlicher MMO-Server.",Color("bac7c7"))

# --- Staff tools ----------------------------------------------------------------------

func _staff(action: Callable,leave: bool=false) -> void:
	action.call()
	_save_staff();_save_progress()
	if previous_region!=sim.map_id:
		_sync_region()
	elif leave:
		modal.hide();_recenter_camera();camera.position=sim.player.pos
	else:
		_open_modal("Staff")
	_refresh_ui()

func _staff_button(parent: Node,text: String,permission: String,action: Callable,leave: bool=false,variant: String="normal",disabled: bool=false) -> Button:
	var button=_action(text,func():_staff(action,leave),variant,parent)
	button.custom_minimum_size.y=42;button.add_theme_font_size_override("font_size",14)
	button.disabled=disabled or not sim.staff.can(permission)
	return button

func _badge_plate(parent: Node,tag: String,color: Color) -> void:
	var plate=Control.new();plate.custom_minimum_size=Vector2(SEA_MARKS.badge_width(tag,font,14)+8,30);plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plate.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	plate.draw.connect(func():SEA_MARKS.staff_badge(plate,Vector2(2,15),tag,color,font,14))
	parent.add_child(plate)

func _open_staff() -> void:
	var staff=sim.staff
	if not staff.active():
		_banner_card(painted.staff_seal,"STAFF-ZUGANG · %s" % CONTENT.STAFF_ENVIRONMENT,"Anmeldung für das Spielteam. In dieser Testversion schalten lokale Zugangscodes die Rollen frei. Im Online-Spiel vergibt und prüft der Server die Rechte; dann gibt es hier keine Codes mehr.",Color("d0a0ff"))
		staff_code_input=_line_edit("Zugangscode",24)
		staff_code_input.secret=true
		staff_code_input.text_submitted.connect(func(_text: String):_staff_sign_in())
		_with_icon(_action("ANMELDEN",_staff_sign_in,"staff"),painted.staff_seal)
		if not staff.audit.is_empty() and not bool(staff.audit.back().allowed):_note("Letzter Versuch abgelehnt · %s" % staff.audit.back().detail,Color("e7957a"))
		_section("ROLLEN & RECHTE")
		for key in CONTENT.STAFF_ROLE_ORDER:
			var role: Dictionary=CONTENT.STAFF_ROLES[key]
			var card=_card(role.color)
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
			_badge_plate(row,str(role.badge),role.color)
			var names: Array[String]=[]
			for permission in role.permissions:names.append(str(CONTENT.STAFF_PERMISSIONS[permission]))
			var label=_text(row,"%s\n%s" % [str(role.name).to_upper(),", ".join(names)],13,Color("e2ecee"));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_note("Jede Staff-Aktion wird protokolliert, auch verweigerte. Abschüsse, Wellen und Bonuskarten zählen während einer Staff-Sitzung nicht für Ranglisten oder Belohnungen. Beim Abmelden lässt sich der Spielstand vor der Anmeldung wiederherstellen.",Color("84999c"))
		return
	match _tab("Staff"):
		"TELEPORT":_staff_teleport_tab()
		"SCHIFF":_staff_ship_tab()
		"WELT":_staff_world_tab()
		"GEWÄHREN":_staff_grant_tab()
		"ZIEL":_staff_target_tab()
		"PROTOKOLL":_staff_audit_tab()
		_:_staff_overview_tab()

func _staff_sign_in() -> void:
	var code=staff_code_input.text if staff_code_input!=null else ""
	sim.staff_sign_in(code)
	modal_tab["Staff"]="ÜBERSICHT"
	_save_staff()
	_open_modal("Staff")
	_refresh_ui()

func _staff_overview_tab() -> void:
	var staff=sim.staff
	var card=_card(staff.color())
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
	_picture(row,painted.staff_seal,56)
	_badge_plate(row,staff.badge(),staff.color())
	var minutes=maxi(0,int(Time.get_unix_time_from_system())-staff.started)/60
	var label=_text(row,"%s · %s\nAngemeldet seit %d min · Staff-Abschüsse %d (zählen nicht)\n%s" % [staff.title().to_upper(),CONTENT.STAFF_ENVIRONMENT,minutes,sim.staff_kills,"Spielstand verändert" if staff.touched else "Noch keine Änderungen am Spielstand"],13,Color("e2ecee"))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_section("SICHTBARKEIT AUF DER KARTE")
	var presence=_grid(2)
	for mode in CONTENT.STAFF_PRESENCE_ORDER:
		var key=str(mode)
		_staff_button(presence,str(CONTENT.STAFF_PRESENCE[key].name),"presence",func():sim.staff_set_presence(key),false,"tab_on" if staff.presence==key else "normal",staff.presence==key)
	_note(str(CONTENT.STAFF_PRESENCE[staff.presence].effect),Color("d0a0ff"))
	_section("SCHNELLZUGRIFF")
	var quick=_grid(2)
	for key in ["god","no_aggro","speed"]:
		var flag=str(key)
		_staff_button(quick,"%s · %s" % [str(CONTENT.STAFF_FLAGS[flag]).to_upper(),"AN" if staff.flag(flag) else "AUS"],"ship",func():sim.staff_toggle(flag),false,"tab_on" if staff.flag(flag) else "normal")
	_staff_button(quick,"TIPP-TELEPORT · %s" % ("AN" if staff.tap_teleport else "AUS"),"teleport",func():sim.staff_set_tap_teleport(not staff.tap_teleport),false,"tab_on" if staff.tap_teleport else "normal")
	_section("ABMELDEN")
	var out=_grid(2)
	_action("ABMELDEN · ZURÜCKSETZEN",func():modal_tab["Staff"]="ÜBERSICHT";_staff(func():sim.staff_sign_out(true)),"danger",out)
	_action("ABMELDEN · BEHALTEN",func():modal_tab["Staff"]="ÜBERSICHT";_staff(func():sim.staff_sign_out(false)),"normal",out)
	_note("ZURÜCKSETZEN stellt Gold, Fortschritt und Position wie vor der Anmeldung wieder her. BEHALTEN übernimmt die Änderungen und markiert den Spielstand als Staff-verändert.",Color("84999c"))

func _staff_teleport_tab() -> void:
	var region: Dictionary=CONTENT.MAPS[sim.map_id]
	_section("SPRUNGZIELE · %s %s" % [region.code,str(region.name).to_upper()])
	var here=_grid(2)
	var places=[["harbor","HAFEN"],["start","STARTPUNKT"],["portal_east","PORTAL OST"],["portal_west","PORTAL WEST"]]
	if sim.map_id==CONTENT.FORTRESS_MAP:places.append(["fortress","KORSARENFESTUNG"])
	for entry in places:
		var place=str(entry[0])
		var blocked=sim.in_bonus_map() and place!="start"
		_with_icon(_staff_button(here,str(entry[1]),"teleport",func():sim.staff_teleport(sim.map_id,place),true,"normal",blocked),painted.staff_teleport)
	_staff_button(modal_body,"TIPP-TELEPORT · %s" % ("AN" if sim.staff.tap_teleport else "AUS"),"teleport",func():sim.staff_set_tap_teleport(not sim.staff.tap_teleport),false,"tab_on" if sim.staff.tap_teleport else "normal")
	_note("Mit Tipp-Teleport springt dein Schiff beim Antippen von freiem Wasser sofort dorthin. Ein Schiff antippen wählt weiterhin ein Ziel. Levelgrenzen und die 6-Sekunden-Regel gelten für Staff nicht.",Color("84999c"))
	_section("SEEKARTE WECHSELN")
	var maps=_grid(2)
	for i in CONTENT.MAPS.size():
		var index=i
		var map: Dictionary=CONTENT.MAPS[i]
		_staff_button(maps,"%s · %s%s" % [map.code,str(map.name).to_upper()," · HIER" if i==sim.map_id else ""],"map",func():sim.staff_teleport(index,"start"),true,"tab_on" if i==sim.map_id else "normal",i==sim.map_id)
	_note("Bonuskarten öffnen per Teleport einen Staff-Testlauf ohne Schriftrolle. Er zählt nicht und wird nicht gespeichert.",Color("84999c"))
	_section("ZIEL")
	var target=_grid(2)
	var none=sim.actor(sim.target).is_empty() or sim.target<=0
	_staff_button(target,"ZUM ZIEL SPRINGEN","teleport",func():sim.staff_teleport_target(),true,"normal",none)
	_staff_button(target,"ZIEL HERBEIRUFEN","summon",func():sim.staff_summon_target(),false,"normal",none)

func _staff_ship_tab() -> void:
	_section("STAFF-SCHIFFSWERTE")
	var flags=_grid(2)
	for key in CONTENT.STAFF_FLAG_ORDER:
		var flag=str(key)
		var on=sim.staff.flag(flag)
		_staff_button(flags,"%s · %s" % [str(CONTENT.STAFF_FLAGS[flag]).to_upper(),"AN" if on else "AUS"],"ship",func():sim.staff_toggle(flag),false,"tab_on" if on else "normal")
	_section("SOFORTHILFE")
	var help=_grid(3)
	_staff_button(help,"VOLL REPARIEREN","ship",func():sim.staff_ship("repair"))
	_staff_button(help,"EFFEKTE LÖSCHEN","ship",func():sim.staff_ship("cleanse"))
	_staff_button(help,"ABKLINGZEITEN 0","ship",func():sim.staff_ship("cooldowns"))
	_note("Staff-Schiffswerte gelten nur während der Sitzung und enden beim Abmelden.",Color("84999c"))

func _staff_world_tab() -> void:
	_section("ERZEUGEN · %d / %d STAFF-ZIELE" % [sim.staff_spawn_count(),sim.STAFF_SPAWN_CAP])
	var spawns=_grid(2)
	for key in CONTENT.STAFF_SPAWN_ORDER:
		var kind=str(key)
		var button=_staff_button(spawns,str(CONTENT.STAFF_SPAWNS[kind].name).to_upper(),"spawn",func():sim.staff_spawn(kind))
		_with_icon(button,painted.staff_dummy if kind=="dummy" else (painted.boss_wave if kind in ["admiral","monster"] else painted.spyglass))
	_staff_button(modal_body,"STAFF-ZIELE ENTFERNEN","spawn",func():sim.staff_clear_spawns(),false,"danger")
	_note("Staff-Ziele erscheinen vor dem Bug, werden sofort angewählt und tauchen nach dem Versenken nicht wieder auf. Sie geben weder Gold noch Erfahrung. Das Übungsziel bleibt eingefroren und schießt nicht.",Color("84999c"))
	_section("WELT-WERKZEUGE")
	var world=_grid(2)
	_staff_button(world,"GEGNER ZURÜCKSETZEN","world",func():sim.staff_world("reset_npcs"))
	_staff_button(world,"FESTUNG ERNEUERN","world",func():sim.staff_world("reset_fortress"),false,"normal",sim.map_id!=CONTENT.FORTRESS_MAP)
	_staff_button(world,"WELLE ÜBERSPRINGEN","world",func():sim.staff_world("skip_wave"),false,"normal",not sim.in_bonus_map() or sim.bonus.is_empty())
	_staff_button(world,"BEUTEKISTE ABWERFEN","world",func():sim.staff_world("loot"))

func _staff_grant_tab() -> void:
	if not sim.staff.can("grant"):_note("Nur Administratoren gewähren Gegenstände.",Color("e7957a"))
	_section("GEWÄHREN")
	var grants=_grid(2)
	for key in CONTENT.STAFF_GRANT_ORDER:
		var kind=str(key)
		_staff_button(grants,str(CONTENT.STAFF_GRANTS[kind]).to_upper(),"grant",func():sim.staff_grant(kind),false,"normal",kind=="level" and sim.level>=20)
	_note("Gewährte Gegenstände markieren den Spielstand als Staff-verändert, außer du meldest dich mit ZURÜCKSETZEN ab.",Color("84999c"))

func _staff_target_tab() -> void:
	var info=sim.staff_inspect()
	_section("ZIEL INSPIZIEREN")
	if info.is_empty():
		_note("Kein Ziel gewählt. Tippe auf der Seekarte ein Schiff an oder erzeuge unter WELT ein Übungsziel." if sim.staff.can("inspect") else "Deine Rolle darf keine Ziele inspizieren.")
	else:
		var kind={"ship":"Schiff","monster":"Seeungeheuer","tower":"Festungsturm"}.get(info.kind,info.kind)
		var lines="%s\n%s%s · Rumpf %s / %s · Schild %s / %s\nZustand %s%s%s · Belohnung %d Gold · %d m entfernt\nPlanquadrat X %s · Y %s" % [str(info.name).to_upper(),kind," · Elite" if info.elite else "",_thousands(info.hp),_thousands(info.max_hp),_thousands(info.shield),_thousands(info.max_shield),info.state," · aggressiv" if info.aggressive else ""," · eingefroren" if info.frozen else "",info.reward,info.distance,MINI.column_name(info.pos.x),MINI.row_name(info.pos.y)]
		_row(painted.spyglass,lines,52,Color("ff6a4d") if info.aggressive else CYAN)
		var tools=_grid(2)
		_staff_button(tools,"AUFTAUEN" if info.frozen else "EINFRIEREN","world",func():sim.staff_target("freeze"))
		_staff_button(tools,"HEILEN","world",func():sim.staff_target("heal"))
		_staff_button(tools,"BERUHIGEN","world",func():sim.staff_target("calm"))
		_staff_button(tools,"VERSENKEN","world",func():sim.staff_target("sink"),false,"danger")
		_staff_button(tools,"ZUM ZIEL SPRINGEN","teleport",func():sim.staff_teleport_target(),true)
		_staff_button(tools,"HERBEIRUFEN","summon",func():sim.staff_summon_target(),false,"normal",info.kind=="tower")
	_section("MODERATION · KAPITÄNE")
	_note("Andere Kapitäne gibt es erst mit dem Online-Server. Dann folgen Verwarnen, Stummschalten, Kick und Sperre, jeweils mit Grund und Protokolleintrag.",Color("84999c"))
	var moderation=_grid(2)
	for text in ["VERWARNEN","STUMMSCHALTEN","KICK","SPERRE"]:
		var button=_action(text+" · KOMMT MIT DEM SERVER",func():pass,"normal",moderation)
		button.disabled=true;button.custom_minimum_size.y=40;button.add_theme_font_size_override("font_size",12)

func _staff_audit_tab() -> void:
	var staff=sim.staff
	if not staff.can("audit"):
		_note("Deine Rolle darf das Protokoll nicht einsehen.",Color("e7957a"))
		return
	_section("PROTOKOLL · %d EINTRÄGE" % staff.audit.size())
	var bias=int(Time.get_time_zone_from_system().get("bias",0))*60
	var entries=staff.audit.duplicate();entries.reverse()
	for entry: Dictionary in entries.slice(0,60):
		var stamp=Time.get_time_string_from_unix_time(int(entry.time)+bias)
		var line="%s · %s · %s%s" % [stamp,entry.role,entry.action," · "+str(entry.detail) if not str(entry.detail).is_empty() else ""]
		var label=_note(line,Color("e2ecee") if bool(entry.allowed) else Color("ff9d8a"))
		label.add_theme_font_size_override("font_size",13)
	if staff.audit.is_empty():_note("Noch keine Einträge.")

func _save_staff() -> void:
	var file=FileAccess.open(STAFF_SAVE,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(sim.staff.export_state()));file.close()

func _load_staff() -> void:
	if not FileAccess.file_exists(STAFF_SAVE):return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(STAFF_SAVE))
	if data is Dictionary:sim.staff.restore_state(data)

func _sync_region() -> void:
	previous_region=sim.map_id
	chart_pick=-1
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
		if event.keycode==KEY_8:sim.set_ammo(3)
		if event.keycode==KEY_9:sim.set_ammo(4)
		if event.keycode==KEY_0:sim.set_ammo(5)
		if event.keycode==KEY_MINUS:sim.set_ammo(6)
		var hotkeys=[KEY_4,KEY_5,KEY_6,KEY_7]
		if event.keycode in hotkeys:_use_supply(CONTENT.SUPPLY_KEYS[hotkeys.find(event.keycode)])

func _hud_contains(screen: Vector2) -> bool:
	if modal.visible:return true
	var controls: Array[Control]=[chrome,target_panel,chart_mini,quest_panel,attack,repair,ammo_selector,loadout_button,center_button,settings_button,target_cycle,camera_pad,zoom_in,zoom_out,interact,staff_pill]
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
	elif sim.staff.tap_teleport and sim.staff.can("teleport"):
		sim.staff_teleport(sim.map_id,"",point)
		_save_staff()
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

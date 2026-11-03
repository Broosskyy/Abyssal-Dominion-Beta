extends Node2D
const SIM = preload("res://simulation.gd")
const MINI = preload("res://minimap.gd")
const HUD=preload("res://nautical_button.gd")
const CONTENT = preload("res://content.gd")
const VISUALS = preload("res://ship_visuals.gd")
const USER_ROOT := "res://assets/user/"
const SAVE := "user://captain_m3052.json"
const GOLD := Color("dcc18a")
const CYAN := Color("80e3dc")
var sim := SIM.new()
var camera: Camera2D
var water: ColorRect
var ocean: ShaderMaterial
var ui: Control
var chart_mini: Control
var desired_zoom := 0.96
var pan := Vector2.ZERO
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
var title: Label
var resources: Label
var player_panel: Panel
var player_name: Label
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
var combat_dock: Panel
var combat_readout: Label
var loadout_button: Button
var player_portrait: TextureRect
var target_portrait: TextureRect
var portrait_skin := -1
var portrait_target := -1
var target_health_skin: StyleBoxFlat
var hud_icons: Dictionary={}
var ammo_selector: Button
var deck_hp: ProgressBar
var deck_xp: ProgressBar
var deck_numbers: Label
var system_tab: Button
var quest_tab: Button
var system_label: Label
var system_view=false
var message_history: Array[String]=[]
var previous_region := -1

func _ready() -> void:
	_load_assets()
	_load_progress()
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
	water.material = ocean
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_ui()
	var data_boot=get_tree().root.get_node_or_null("DataBoot")
	if data_boot!=null:data_boot.mark_healthy()

func _load_assets() -> void:
	for name in ["anchor","ship","book","compass","chest","gear","plus","minus","focus","arrow"]:hud_icons[name]=load("res://assets/ui/icons/"+name+".svg")
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
	var goal: Vector2 = sim.player.pos+pan
	camera.position = camera.position.lerp(goal,1.0-exp(-delta*5.0))
	camera.zoom = camera.zoom.lerp(Vector2.ONE*desired_zoom,1.0-exp(-delta*8.0))
	ocean.set_shader_parameter("camera_world",camera.position)
	ocean.set_shader_parameter("map_zoom",camera.zoom.x)
	ocean.set_shader_parameter("viewport_size",get_viewport_rect().size)
	ocean.set_shader_parameter("region_tint",CONTENT.MAPS[sim.map_id].tint)
	chart_mini.camera_world = camera.position
	chart_mini.view_world = get_viewport_rect().size/camera.zoom
	chart_mini.queue_redraw()
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
	if _landmark_label_visible(sim.harbor):
		var anchor=sim.harbor
		draw_circle(anchor-Vector2(0,23),6,GOLD,false,2.0,true)
		draw_line(anchor-Vector2(0,17),anchor+Vector2(0,17),GOLD,2.5,true)
		draw_line(anchor-Vector2(13,7),anchor+Vector2(13,-7),GOLD,2.0,true)
		draw_arc(anchor+Vector2(0,1),23,0,PI,24,GOLD,2.5,true)
	if _landmark_label_visible(sim.harbor):_label(sim.harbor+Vector2(0,100),"HAFEN · ANDOCKEN",13,GOLD)
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
	drawn_shots = 0
	for shot in sim.shots:
		if float(shot.age)<0: continue
		drawn_shots += 1
		var progress = clampf(float(shot.traveled)/float(shot.distance),0,1)
		var p: Vector2 = shot.pos-Vector2(0,sin(progress*PI)*28)
		var victim = sim.actor(int(shot.target))
		if victim.is_empty(): continue
		var direction: Vector2=(victim.pos-shot.pos).normalized()
		var color = Color("ffe0a2") if int(shot.source)==0 else Color("ff8c56")
		draw_line(p-direction*18,p,color,2.4,true)
		draw_circle(p,4.2,Color(0,0,0,0.5))
		draw_circle(p,2.7,color)
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
	var name: String = str(skins[int(sim.player.skin)].name) if is_player else str(actor.name)
	var color = CYAN if is_player else (Color("e4b6ee") if monster else Color("e4c596"))
	var name_offset=68.0 if is_player and int(sim.player.skin)==26 else 47.0
	var baseline = point+Vector2(0,name_offset)
	_label(baseline,("✦ "+name) if is_player else name,14 if is_player else 13,color)
	var bar = Rect2(point+Vector2(-43,name_offset+8),Vector2(86,4))
	draw_rect(bar,Color("071820"))
	var health_color=Color("60b682") if is_player else (Color("b36452") if bool(actor.get("aggressive",false)) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) else Color("baa165"))
	draw_rect(Rect2(bar.position,Vector2(bar.size.x*float(actor.hp)/float(actor.max_hp),4)),health_color)
	if float(actor.slow)>0: _label(point+Vector2(0,name_offset+33),"VERLANGSAMT",10,Color("9fdbf4"))

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

func _label(point: Vector2,text: String,fontsize: int,color: Color) -> void:
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	var p = point-Vector2(width*0.5,0)
	draw_string_outline(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,3,Color(0.01,0.035,0.05,color.a))
	draw_string(font,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)

func _panel(parent: Node) -> Panel:
	var p =Panel.new()
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
	var bg =StyleBoxFlat.new();bg.bg_color=Color("07161f");bg.set_corner_radius_all(2)
	var fill =StyleBoxFlat.new();fill.bg_color=Color("4fa788");fill.set_corner_radius_all(2)
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
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	chrome=_panel(ui)
	title=_text(chrome,"ABYSSAL DOMINION",12)
	resources=_text(chrome,"",11,GOLD)
	var nav_items=[["Schiff","ship","Schiff"],["Werft","anchor","Hafen"],["Aufträge","book","Logbuch"],["Karten","compass","Seekarten"],["Vorräte","chest","Munition"],["Menü","gear","Spielinfo"]]
	for item in nav_items:
		var kind: String=item[2]
		var button=_orb(chrome,str(item[0]),hud_icons[item[1]],func():_open_modal(kind),str(item[0]),true)
		button.set_meta("modal",kind);nav_buttons.append(button)
	player_panel=_panel(ui)
	player_portrait=_portrait(player_panel)
	player_name=_text(player_panel,"",12,GOLD)
	player_hp=_bar(player_panel)
	player_numbers=_text(player_panel,"",11)
	player_name.clip_text=true
	player_xp=_bar(player_panel)
	var xp_style: StyleBoxFlat=player_xp.get_theme_stylebox("fill").duplicate();xp_style.bg_color=Color("348cb6");player_xp.add_theme_stylebox_override("fill",xp_style)
	target_panel=_panel(ui)
	target_portrait=_portrait(target_panel)
	target_name=_text(target_panel,"",12);target_name.clip_text=true
	target_hp=_bar(target_panel)
	target_health_skin=target_hp.get_theme_stylebox("fill").duplicate();target_hp.add_theme_stylebox_override("fill",target_health_skin)
	target_numbers=_text(target_panel,"",11)
	chart_mini=MINI.new();chart_mini.simulation=sim
	chart_mini.course_requested.connect(func(point):_chart_course(point))
	ui.add_child(chart_mini)
	combat_dock=_panel(ui);combat_dock.mouse_filter=Control.MOUSE_FILTER_IGNORE
	combat_readout=_text(combat_dock,"",10,GOLD);combat_readout.clip_text=true
	deck_hp=_bar(combat_dock);deck_xp=_bar(combat_dock);deck_xp.add_theme_stylebox_override("fill",xp_style)
	deck_numbers=_text(combat_dock,"",9,Color.WHITE);deck_numbers.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	loadout_button=_orb(ui,"Bewaffnung",extra_icons.cannon_0,func():_open_modal("Bewaffnung"),"WAFFEN")
	attack=_orb(ui,"Feuer ein/aus",extra_icons.cannon_2,_toggle_fire,"FEUER");attack.name="FireButton"
	repair=_orb(ui,"Schiff reparieren",extra_icons.upgrade_hull,func():sim.toggle_repair();_refresh_ui(),"REP");repair.name="RepairButton"
	ammo_selector=_orb(ui,"Munitionsauswahl",icons.cannonball,func():_open_modal("Munition"),"KUGELN")
	for i in 3:
		var index=i
		var button=_orb(ui,"",icons[["cannonball","chain","harpoon"][i]],func():sim.set_ammo(index);_refresh_ui())
		button.name="Ammo%d" % i;button.toggle_mode=true;ammo_buttons.append(button)
	center_button=_orb(ui,"Kamera zum Schiff",hud_icons.focus,func():pan=Vector2.ZERO;camera_locked=true)
	zoom_in=_orb(ui,"Näher zoomen",hud_icons.plus,func():_zoom(1.15))
	zoom_out=_orb(ui,"Weiter zoomen",hud_icons.minus,func():_zoom(1.0/1.15))
	interact=_button(ui,"",_interact);interact.name="InteractButton"
	status=_text(ui,"",11,Color("b3ccd0"));status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quest_panel=_panel(ui)
	quest_tab=_button(quest_panel,"AUFTRAG",func():system_view=false;_refresh_ui())
	system_tab=_button(quest_panel,"SYSTEM",func():system_view=true;_refresh_ui())
	for tab in [quest_tab,system_tab]:tab.add_theme_font_size_override("font_size",10)
	quest_text=_text(quest_panel,"",11);quest_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	system_label=_text(quest_panel,"",11,Color("bac7c7"));system_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;system_label.clip_text=true
	quest_claim=_button(quest_panel,"BELOHNUNG ABHOLEN",func():sim.claim_quest();_save_progress();_refresh_ui());quest_claim.add_theme_font_size_override("font_size",10)
	modal_backdrop=ColorRect.new()
	modal_backdrop.color=Color(0.002,0.009,0.018,0.77)
	modal_backdrop.z_index=19
	modal_backdrop.visible=false
	modal_backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
	ui.add_child(modal_backdrop)
	modal=_panel(ui)
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
	modal_title=_text(modal,"",20)
	modal_close=_button(modal,"SCHLIESSEN",func():modal.hide();_save_progress())
	modal_scroll=ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(modal_scroll)
	modal_body=VBoxContainer.new()
	modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",10)
	modal_scroll.add_child(modal_body)

func _place(c: Control,x: float,y: float,w: float,h: float) -> void:
	c.position=Vector2(x,y)
	c.size=Vector2(maxf(w,1),maxf(h,1))

func _layout() -> void:
	if ui==null:return
	var s =get_viewport_rect().size
	var compact =s.y<560 or s.x<1000
	if compact and elapsed<0.1:
		desired_zoom=0.78
		camera.zoom=Vector2.ONE*desired_zoom
	water.size=s
	var header=54.0 if compact else 62.0
	_place(chrome,0,0,s.x,header)
	title.visible=not compact;_place(title,12,4,210,18)
	_place(resources,12,5 if compact else 24,154 if compact else 250,44 if compact else 32)
	resources.visible=true
	var nw=62.0 if compact else 80.0
	var nav_x=(s.x-nw*nav_buttons.size())*.5
	for i in nav_buttons.size():_place(nav_buttons[i],nav_x+i*nw,2,nw-3,header-4)
	var top=header+8
	_place(player_panel,12,top,208 if compact else 236,66)
	_place(player_portrait,7,6,48,49);_place(player_name,62,3,player_panel.size.x-70,22)
	_place(player_hp,62,27,player_panel.size.x-72,9);_place(player_numbers,62,38,player_panel.size.x-70,20)
	_place(player_xp,8,60,player_panel.size.x-16,3)
	var tw=player_panel.size.x
	_place(target_panel,12,top+72,tw,72)
	_place(target_portrait,7,5,48,51);_place(target_name,62,3,tw-70,22);_place(target_hp,62,27,tw-72,8);_place(target_numbers,62,36,tw-70,32)
	var mw=128.0 if compact else 180.0
	var mh=108.0 if compact else 154.0
	_place(chart_mini,s.x-mw-12,top,mw,mh)
	var z=36.0 if compact else 38.0
	_place(zoom_out,s.x-2*z-18,top+mh+6,z,z);_place(zoom_in,s.x-z-12,top+mh+6,z,z)
	_place(center_button,s.x-z-12,top+mh+z+10,z,z)
	var q=44.0 if compact else 52.0
	var group=4*q+24
	var left=(s.x-group)*.5
	var dh=104.0 if compact else 116.0
	var dy=s.y-dh-6
	_place(combat_dock,left-8,dy,group+16,dh)
	_place(combat_readout,8,3,group,14)
	_place(deck_hp,8,19,group,10);_place(deck_xp,8,31,group,7);_place(deck_numbers,8,18,group,12)
	for i in 3:_place(ammo_buttons[i],left+i*(q+8),dy+42,q,q+12)
	_place(loadout_button,left+3*(q+8),dy+42,q,q)
	var fire=92.0 if compact else 118.0
	_place(attack,s.x-fire-12,s.y-fire-12,fire,fire)
	var small=52.0 if compact else 60.0
	var side_x=s.x-fire-small-28
	_place(repair,side_x,s.y-small-12,small,small)
	_place(ammo_selector,side_x-2,s.y-small*2-42,small+4,small+16)
	var status_x=maxf(236 if compact else 294,s.x*.5-220)
	_place(status,status_x,dy-26,minf(440,side_x-status_x-12),20)
	_place(interact,12,top+152,player_panel.size.x,36)
	_place(quest_panel,12,s.y-(116 if compact else 150)-10,208 if compact else 270,116 if compact else 150)
	quest_panel.visible=true
	_place(quest_tab,5,4,quest_panel.size.x*.5-7,23);_place(system_tab,quest_panel.size.x*.5+2,4,quest_panel.size.x*.5-7,23)
	_place(quest_text,10,33,quest_panel.size.x-20,quest_panel.size.y-72)
	_place(system_label,10,33,quest_panel.size.x-20,quest_panel.size.y-42)
	_place(quest_claim,8,quest_panel.size.y-32,quest_panel.size.x-16,25)
	var width=minf(640,s.x-32)
	var height=minf(560,s.y-24)
	_place(modal_backdrop,0,0,s.x,s.y)
	if modal_kind=="Munition":
		width=minf(430,s.x-32);height=minf(380,s.y-108)
		_place(modal,s.x-width-16,maxf(12,s.y-height-104),width,height)
	else:_place(modal,(s.x-width)*.5,(s.y-height)*.5,width,height)
	modal.add_theme_stylebox_override("panel",modal_compact_skin)
	_place(modal_title,18,12,width-160,30);_place(modal_close,width-136,12,118,32)
	_place(modal_scroll,18,56,width-36,height-74)

func _refresh_ui() -> void:
	if player_name==null:return
	for nav: Button in nav_buttons:
		nav.set("latched",modal.visible and modal_kind==str(nav.get_meta("modal")));nav.queue_redraw()
	player_name.text="Lv. %d · %s" % [sim.level,skins[int(sim.player.skin)].name]
	if portrait_skin!=int(sim.player.skin):
		portrait_skin=int(sim.player.skin)
		player_portrait.texture=skin_previews[portrait_skin]
	player_hp.max_value=sim.player.max_hp
	player_hp.value=sim.player.hp
	player_numbers.text="%d / %d HP" % [int(sim.player.hp),int(sim.player.max_hp)]
	player_xp.tooltip_text="Erfahrung %d / %d" % [sim.xp,sim.xp_required()]
	player_xp.max_value=sim.xp_required()
	player_xp.value=sim.xp
	resources.text="GOLD  %s\nLV. %d · %d VERSENKT" % [str(sim.player.gold),sim.level,sim.kills]
	var selected =sim.actor(sim.target)
	target_panel.visible=not selected.is_empty() and sim.target>0 and int(selected.hp)>0
	if target_panel.visible:
		if portrait_target!=int(selected.id):
			portrait_target=int(selected.id)
			if selected.kind=="monster":
				var preview=AtlasTexture.new();preview.atlas=beast
				preview.region=Rect2(Vector2.ZERO,beast.get_size()/Vector2(CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS))
				target_portrait.texture=preview
			else:target_portrait.texture=_ship_preview(atlas_textures[int(selected.art)],0)
		target_name.text=str(selected.name)
		target_hp.max_value=selected.max_hp
		target_hp.value=selected.hp
		var disposition="IM KAMPF" if sim.npc_engages(selected) else ("FEINDLICH" if CONTENT.MAPS[sim.map_id].npc_hostile else "NEUTRAL")
		target_health_skin.bg_color=Color("b36452") if bool(selected.aggressive) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) else Color("baa165")
		target_numbers.text="%d / %d HP\n%s · %d m"%[int(selected.hp),int(selected.max_hp),disposition,roundi(sim.player.pos.distance_to(selected.pos))]
	attack.text="STOPP" if sim.firing else "FEUER"
	attack.disabled=not target_panel.visible or int(sim.player.hp)<=0 or sim.docked
	_set_orb(attack,extra_icons["cannon_%d" % mini(2,int(sim.upgrades.cannon))],"",sim.firing,attack.text)
	attack.set("cooldown",float(sim.player.reload)/1.65)
	repair.disabled=sim.docked
	repair.text="STOPP" if sim.repairing else "REPARATUR"
	_set_orb(repair,extra_icons.upgrade_hull,"",sim.repairing,"STOPP" if sim.repairing else "REP")
	for i in 3:
		ammo_buttons[i].text=["Vollkugeln","Kettenkugeln","Harpunen"][i]+"\n"+("✓ " if sim.ammo_mode==i else "")+str(sim.player.ammo[i])
		ammo_buttons[i].set_pressed_no_signal(sim.ammo_mode==i)
		_set_orb(ammo_buttons[i],icons[["cannonball","chain","harpoon"][i]],str(sim.player.ammo[i]),sim.ammo_mode==i)
		ammo_buttons[i].tooltip_text=["Vollkugeln: gegen Schiffe","Kettenkugeln: verlangsamen Schiffe","Harpunen: gegen Monster"][i]
	_set_orb(ammo_selector,icons[["cannonball","chain","harpoon"][sim.ammo_mode]],str(sim.player.ammo[sim.ammo_mode]),false,["KUGELN","KETTE","HARP."][sim.ammo_mode])
	deck_hp.max_value=sim.player.max_hp;deck_hp.value=sim.player.hp;deck_xp.max_value=sim.xp_required();deck_xp.value=sim.xp
	deck_numbers.text="%d / %d HP" % [sim.player.hp,sim.player.max_hp]
	var reload_text="IM HAFEN" if sim.docked else ("BEREIT" if float(sim.player.reload)<=0 else "LÄDT %.1f s" % float(sim.player.reload))
	combat_readout.text="%s · %d×%d · %s" % [["Vollkugeln","Kettenkugeln","Harpunen"][sim.ammo_mode],sim.weapon_damage(sim.ammo_mode),1 if sim.ammo_mode==2 else 3,reload_text]
	if message_history.is_empty() or message_history.back()!=sim.message:
		message_history.append(sim.message)
		if message_history.size()>3:message_history.pop_front()
	var recent=message_history.duplicate();recent.reverse()
	system_label.text="\n".join(recent)
	system_label.visible=system_view;quest_text.visible=not system_view;quest_claim.visible=not system_view
	status.text="IM HAFEN · ABLEGEN zum Weiterfahren" if sim.docked else sim.message
	var quest = sim.current_quest()
	quest_claim.disabled=quest.is_empty() or sim.quest_progress()<int(quest.goal)
	quest_text.text="ALLE AUFTRÄGE ERLEDIGT" if quest.is_empty() else "%s · %d/%d\n%d Gold · %d EP" % [str(quest.name).to_upper(),mini(sim.quest_progress(),int(quest.goal)),quest.goal,quest.gold,quest.xp]
	quest_claim.text="ABGESCHLOSSEN" if quest.is_empty() else "BELOHNUNG ABHOLEN"
	interact.visible=sim.docked or sim.near_portal()>=0 or sim.can_dock() or sim.pending_portal>=0
	interact.disabled=false
	if sim.docked:
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

func _toggle_fire() -> void:
	if sim.target<1:return
	sim.firing=not sim.firing
	sim.repairing=false
	_refresh_ui()

func _open_modal(kind: String) -> void:
	var scroll_position=modal_scroll.scroll_vertical if modal.visible and modal_kind==kind else 0
	modal_kind=kind
	modal_title.text=kind
	modal_body.add_theme_constant_override("separation",6 if kind=="Munition" else 10)
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	_layout()
	if kind=="Schiff":
		_info(str(skins[int(sim.player.skin)].name).to_upper(),CYAN)
		_picture(modal_body,skin_previews[int(sim.player.skin)],120)
		_info("Kapitän Lv. %d · Erfahrung %d / %d\nRumpf %d / %d · Fahrt %d\nKanonen St. %d · Harpunen St. %d" % [sim.level,sim.xp,sim.xp_required(),sim.player.hp,sim.player.max_hp,sim.player.speed,sim.upgrades.cannon,sim.upgrades.harpoon])
		_action("SCHIFFSDESIGN WÄHLEN",func():_open_modal("Werft"))
		_action("BEWAFFNUNG",func():_open_modal("Bewaffnung"))
	elif kind=="Munition":
		modal_title.text="Munitionsauswahl"
		for i in 3:
			var index=i
			var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);modal_body.add_child(row)
			_picture(row,icons[["cannonball","chain","harpoon"][i]],58)
			var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
			column.add_theme_constant_override("separation",2)
			var label=_text(column,"%s · %d\n%d Schaden · %s" % [["Vollkugeln","Kettenkugeln","Harpunen"][i],sim.player.ammo[i],sim.weapon_damage(i),["Gegen Schiffe","Verlangsamt Schiffe","Gegen Seeungeheuer"][i]],12,CYAN)
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var choose=_button(column,"GELADEN" if sim.ammo_mode==i else "LADEN",func():sim.set_ammo(index);modal.hide();_refresh_ui())
			choose.custom_minimum_size.y=28;choose.add_theme_font_size_override("font_size",11);choose.disabled=sim.ammo_mode==i or int(sim.player.ammo[i])<=0
	elif kind=="Werft":
		_info("SCHIFFSDESIGNS · Wähle deinen Look für die nächste Ausfahrt.",CYAN)
		for i in skins.size():
			var index =i
			var b =_button(modal_body,str(skins[i].name)+("   ✓" if int(sim.player.skin)==i else "   AUSRÜSTEN"),func():_equip(index))
			b.custom_minimum_size.y=64
			b.icon=skin_previews[i]
			b.expand_icon=true
			b.add_theme_constant_override("icon_max_width",72)
		_text(modal_body,"MUNITIONSNACHSCHUB · Je 30 Gold",14,CYAN)
		for i in 3:
			var index =i
			var b =_button(modal_body,["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_refresh_ui())
			b.custom_minimum_size.y=48
	elif kind=="Bewaffnung":
		_info("BEWAFFNUNG · KANONEN & HARPUNEN",CYAN)
		_info("Kanonen Stufe %d · Harpunen Stufe %d\nBreitseite: 3 Geschosse · Nachladen: 1,65 Sekunden" % [sim.upgrades.cannon,sim.upgrades.harpoon])
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
		if not sim.docked:
			_info("Fahre zum goldenen Hafensymbol und docke an. Dein Schiff liegt dort geschützt; die Patrouillen fahren weiter. Distanz: %d m." % roundi(sim.player.pos.distance_to(sim.harbor)))
			_action("KURS ZUM HAFEN",func():sim.course(sim.harbor);modal.hide())
			var dock_button = _action("ANDOCKEN",func():
				if sim.dock():_save_progress();_open_modal("Hafen")
				_refresh_ui())
			dock_button.disabled=not sim.can_dock()
		else:
			_info("Kapitänsstufe %d · %d Gold · %d / %d Rumpfpunkte" % [sim.level,sim.player.gold,sim.player.hp,sim.player.max_hp])
			var repair_cost = sim.harbor_repair_cost()
			var repair_button = _action("TROCKENDOCK · %d Gold" % repair_cost,func():sim.harbor_repair();_save_progress();_open_modal("Hafen");_refresh_ui())
			repair_button.disabled=repair_cost<=0 or int(sim.player.gold)<repair_cost
			for key in CONTENT.UPGRADE_KEYS:
				_upgrade_row(str(key))
			_info("MUNITIONSNACHSCHUB",CYAN)
			for i in 3:
				var index = i
				var buy = _action(["150 Vollkugeln","60 Kettenkugeln","40 Harpunen"][i]+" · 30 Gold",func():sim.buy_ammo(index);_save_progress();_open_modal("Hafen");_refresh_ui())
				buy.disabled=int(sim.player.gold)<30
			_action("SCHIFFSDESIGN WÄHLEN · %d DESIGNS" % skins.size(),func():_open_modal("Werft"))
			_action("ABLEGEN",func():sim.depart();modal.hide();_save_progress();_refresh_ui())
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
	elif kind=="Seekarten":
		_info("DREI SEEGEBIETE · PORTALE VERBINDEN DIE SEEKARTEN",CYAN)
		for i in CONTENT.MAPS.size():
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
			travel_button.disabled=i==sim.map_id or locked or sim.docked
		_info("Tippe auf ein Portal oder auf KURS ZUM PORTAL. Dein Schiff fährt hin und wechselt beim Erreichen automatisch. Levelgrenzen bleiben gültig; nach einem Treffer wartet das Portal 6 Sekunden. Im Hafen zuerst ablegen.")
		_action("STEUERUNG & SPIELINFO",func():_open_modal("Spielinfo"))
	else:
		_action("UPDATES PRÜFEN",func():_save_progress();get_tree().set_meta("abyssal_manual_update",true);get_tree().change_scene_to_file("res://updater/launcher.tscn"))
		var info =_text(modal_body,"ABYSSAL DOMINION · STEUERUNG\n\nTippe auf freies Wasser zum Fahren.\nTippe auf ein Schiff und anschließend FEUER.\nVoll- und Kettenkugeln wirken gegen Schiffe, Harpunen gegen Tiamat.\nFahre über Beute, um Gold einzusammeln.\n\nHAFEN: Andocken, Rumpf reparieren und Kanonen, Harpunen, Rumpf oder Segel verbessern.\nLOGBUCH: Sieben aufeinanderfolgende Aufträge.\nKARTEN: Portale zur Karibischen See, zum Nordmeer und zu den Schattengewässern.\n\nZwei Finger / Mausrad: Zoom. Ziehen / rechte Maustaste: Kamera.\nDas Fadenkreuz zentriert die Kamera. Portale antippen: hinfahren und automatisch wechseln.\n\nGastfortschritt wird auf diesem Gerät gespeichert. Lokales Spiel; noch kein öffentlicher MMO-Server.",15)
		info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size.y=300
	modal.show()
	modal_backdrop.show()
	modal_scroll.set_deferred("scroll_vertical",scroll_position)

func _info(text: String,color: Color=GOLD) -> Label:
	var label = _text(modal_body,text,14,color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return label

func _action(text: String,callback: Callable) -> Button:
	var button = _button(modal_body,text,callback)
	button.custom_minimum_size.y=46
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
	_picture(row,extra_icons[art_key],88)
	var column = VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var label = _text(column,"%s · Stufe %d/3\n%s" % [config.name,sim.upgrades[key],config.effect],14,CYAN)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var cost: int=sim.upgrade_cost(key)
	var button = _button(column,"MAXIMALE STUFE" if cost<0 else "VERBESSERN · %d Gold" % cost,func():sim.buy_upgrade(key);_save_progress();_open_modal("Hafen");_refresh_ui())
	button.custom_minimum_size.y=44
	button.disabled=cost<0 or int(sim.player.gold)<cost

func _sync_region() -> void:
	previous_region=sim.map_id
	modal.hide()
	pan=Vector2.ZERO;camera.position=sim.player.pos
	_save_progress();_refresh_ui()

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
	if sim.docked:
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
			pan-=event.relative/camera.zoom
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:_zoom(1.10)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:_zoom(1/1.10)
		elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Time.get_ticks_msec()-last_touch_ms>350:
			_tap(event.position)
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			dragging=event.pressed
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pan-=event.relative/camera.zoom
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:_toggle_fire()
		if event.keycode==KEY_ESCAPE:modal.hide()
		if event.keycode==KEY_R:sim.toggle_repair()
		if event.keycode==KEY_1:sim.set_ammo(0)
		if event.keycode==KEY_2:sim.set_ammo(1)
		if event.keycode==KEY_3:sim.set_ammo(2)

func _hud_contains(screen: Vector2) -> bool:
	if modal.visible:return true
	for control: Control in [chrome,player_panel,target_panel,chart_mini,quest_panel,combat_dock,attack,repair,ammo_selector,center_button,zoom_in,zoom_out,interact]:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen):return true
	return false

func _tap(screen: Vector2) -> void:
	if modal.visible:return
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
	if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()

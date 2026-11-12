extends Node2D
const SIM = preload("res://simulation.gd")
const MONSTER_MOTION=preload("res://monster_motion.gd")
const MINI = preload("res://minimap.gd")
const HUD=preload("res://nautical_button.gd")
const HUD_PANEL=preload("res://nautical_panel.gd")
const CAMERA_PAD=preload("res://camera_pad.gd")
const RULER=preload("res://grid_ruler.gd")
const LOADING=preload("res://loading_screen.gd")
const CONTENT = preload("res://content.gd")
const VISUALS = preload("res://ship_visuals.gd")
const SKIN = preload("res://ui_skin.gd")
const SHARE = preload("res://share_links.gd")
const TOUCH_SCROLL = preload("res://touch_scroll.gd")
const ORNATE = preload("res://ornate_frame.gd")
const SEA_MARKS = preload("res://sea_marks.gd")
const PLATE_OVERLAY = preload("res://ship_plate_overlay.gd")
# Load real GLB ships only on native. The browser Classic client must not
# even import the GLB rendering script or instantiate a 3D SubViewport.
const MESH_SHIPS_PATH := "res://ship_mesh_layer.gd"
const CLASSIC_SLOOP: Texture2D=preload("res://assets/classic/classic_sloop.svg")
const CLASSIC_BRIG: Texture2D=preload("res://assets/classic/classic_brig.svg")
const CLASSIC_GALLEON: Texture2D=preload("res://assets/classic/classic_galleon.svg")
const CLASSIC_ATLAS_ROOT := "res://assets/classic_baked/"
const CLASSIC_ATLAS_COLUMNS := 8
# The still images are baked in CI from the exact authored 3D GLB meshes.
# 8 images share one atlas per hull/paint: no 3D work at browser runtime.
const CLASSIC_MODEL_KEYS := [
	"schattenkriegsschiff_shaded","black_crown_corsair_elite_test",
	"old_harbor_trader","merchant_brig_3002","merchant_brig_2921",
	"merchant_brig_2912","weathered_voyager","weathered_junk",
	"emerald_voyager","midnight_mariner","crimson_tide_galley"
]
const KESSEL_FX = preload("res://kessel_fx.gd")
const WORLD_CHART = preload("res://world_chart.gd")
const CHART_GUIDE = preload("res://chart_guide.gd")
const AMMO_CHOICE=preload("res://ammo_choice.gd")
const NETWORK=preload("res://network_client.gd")
const COMBAT_FX=preload("res://combat_fx.gd")
const SPRITE_FX=preload("res://sprite_fx.gd")
const USER_AMMO_ATLAS: Texture2D=preload("res://assets/ui/ammo/user_ammo_atlas.webp")
# Original reusable 2.5D island harbor with a transparent background;
# the dock itself stays on navigable water on each normal region.
const TOWER_TEXTURES := {
	"cannon":preload("res://assets/world_v2/tower_cannon.png"),
	"mortar":preload("res://assets/world_v2/tower_mortar.png"),
	"chain":preload("res://assets/world_v2/tower_chain.png"),
	"guardian":preload("res://assets/world_v2/tower_guardian.png")}
const HARBOR_ISLAND: Texture2D=preload("res://assets/world_v2/island_harbor.png")
const GUILD_FORTRESS_ART: Texture2D=preload("res://assets/world_v3/guild_fortress_base.svg")
const HARBOR_DRAW_SIZE := SIM.HARBOR_SIZE
const HARBOR_DOCK_OFFSET := SIM.HARBOR_OFFSET
const CAPTAIN_PLATE_OFFSET := 62.0
const OTHER_PLATE_OFFSET := 48.0
const CAPTAIN_HULL_CLEARANCE := 34.0
const NPC_HULL_CLEARANCE := 24.0
const PLATE_ID_BASELINE := 13.0
const PLATE_HP_Y := 24.0
const PLATE_SHIELD_Y := 35.0
const PLATE_DECK_Y := 65.0
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
## Render interpolation only: ship simulation remains server/logic-authoritative at 30 Hz.
const SIMULATION_TICK := 1.0 / 30.0
var visual_before: Dictionary = {}
var visual_after: Dictionary = {}
# Local visual-only water animation state; never written to saves or simulation.
# Each entry stores recent interpolated positions and sampled movement speed.
var wake_tracks: Dictionary = {}
const WAKE_LIFETIME := 1.35
const WAKE_SAMPLE_INTERVAL := 0.11

var refresh_clock := 0.0
var save_clock := 0.0
var elapsed := 0.0
var skins: Array[Dictionary] = []
var skin_previews: Array[Texture2D] = []
# Keep every option accessible, but let touch users browse just their type.
var shipyard_filter := "all"
var island_textures: Dictionary = {}
var icons: Dictionary = {}
var beast: Texture2D
var font: Font = ThemeDB.fallback_font
var currency_wallet: Control
var currency_titles: Array[Label]=[]
var pearl_label: Label
var crystal_label: Label
var pearl_icon: TextureRect
var crystal_icon: TextureRect
var profile_button: Button
var profile_avatar: TextureRect
var profile_name: Label
var profile_level: Label
var captain_meters: Control
var player_bp: ProgressBar
var bp_numbers: Label
var chrome: Panel
var gold_label: Label
var kills_label: Label
var wallet_icons: Array[TextureRect]=[]
var meter_tags: Array[Label]=[]
var xp_numbers: Label
var player_hp: ProgressBar
var player_numbers: Label
var target_panel: Panel
var target_clear: Button
var target_name: Label
var target_hp: ProgressBar
var target_shield: ProgressBar
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
	{"name":"Eismunition","use":"Friert das Ziel kurz ein","icon":"ammo_ice"},
	{"name":"Feuerkugeln","use":"Glut und Flammen · Grafik-Beta","icon":"fire"},
	{"name":"Giftkugeln","use":"Giftnebel und Tropfen · Grafik-Beta","icon":"poison"},
	{"name":"Schrapnellkugeln","use":"Metallsplitter · Grafik-Beta","icon":"shrapnel"},
	{"name":"Blitzkugeln","use":"Elektrische Entladung · Grafik-Beta","icon":"lightning"},
	{"name":"Heilige Kugeln","use":"Goldene Lichtstrahlen · Grafik-Beta","icon":"holy"},
	{"name":"Schattenkugeln","use":"Violetter Schattensog · Grafik-Beta","icon":"shadow"},
	{"name":"Wirbelkugeln","use":"Sturmwirbel · Grafik-Beta","icon":"wind"},
	{"name":"Erdkugeln","use":"Steinsplitter und Staub · Grafik-Beta","icon":"earth"},
	{"name":"Wasserkugeln","use":"Wasserfontänen · Grafik-Beta","icon":"water"},
	{"name":"Fluchkugeln","use":"Fluchrunen · Grafik-Beta","icon":"cursed"},
	{"name":"Blutkugeln","use":"Rote Energiesplitter · Grafik-Beta","icon":"bleed"},
	{"name":"Nekrokugeln","use":"Nekrotische Geister · Grafik-Beta","icon":"necro"},
	{"name":"Goldkugeln","use":"Goldene Lichtfunken · Grafik-Beta","icon":"gold"},
	{"name":"Kristallkugeln","use":"Kristallsplitter · Grafik-Beta","icon":"crystal"},
	{"name":"Explosivkugeln","use":"Explosion und Rauch · Grafik-Beta","icon":"explosive"},
	{"name":"Arkankugeln","use":"Magischer Wirbel · Grafik-Beta","icon":"arcane"},
	{"name":"Geisterkugeln","use":"Türkise Geisterflammen · Grafik-Beta","icon":"spectral"},
	{"name":"Lavakugeln","use":"Lava und Glut · Grafik-Beta","icon":"lava"},
	{"name":"Lichtkugeln","use":"Lichtstrahlen · Grafik-Beta","icon":"light"},
	{"name":"Panzerbrecher","use":"Metallspitzen · Grafik-Beta","icon":"armor_piercing"},
	{"name":"Gaskugeln","use":"Gaswolken · Grafik-Beta","icon":"gas"}
]
var nav_buttons: Array[Button] = []
var nav_scroll: ScrollContainer
var nav_strip: HBoxContainer
var online_client: Node
var online_players: Array[Dictionary]=[]
var online_population: int=0
var online_connected: bool=false
var online_actor_ids: Dictionary={}
var online_next_actor_id: int=-1000
var online_profile_age: float=0.0
var online_own_target: Vector2
var online_own_heading: Vector2=Vector2.LEFT
var online_has_position: bool=false
var quest_panel: Panel
var quest_text: Label
var quest_claim: Button
var modal: ORNATE
var modal_title: Label
var modal_close: Button
var modal_back: Button
var menu_history: Array[String]=[]
# Navigation state belongs to a page and category, only for this open menu session.
var menu_scroll_positions: Dictionary={}
var menu_page_key := ""
var quick_bar: Control
var quick_page := 0
var quick_edit_slot := 0
var quick_pages: Array=preload("res://sea_expansion.gd").QUICK_DEFAULT.duplicate(true)
var feedback_overlay: Control
var expansion_art: Dictionary={}
var modal_scroll: TOUCH_SCROLL
var modal_body: VBoxContainer
var modal_tabs: HBoxContainer
var modal_tabs_scroll: ScrollContainer
var modal_tab := {}
var scroll_hint: Control
var modal_scroll_box := Rect2()
var modal_kind := ""
var kessel_throw: Dictionary = {}
var staff_pill: Button
var staff_code_input: LineEdit
var chart_pick := -1
var chart_chapter := -1
var drag_start := Vector2.ZERO
var dragging := false
var last_mouse := Vector2.ZERO
var touch_points: Dictionary = {}
# Every touch tracks its own original position and drag/multitouch state.
# Do not share a global "dragging" flag across unrelated fingers.
var touch_starts: Dictionary = {}
var touch_invalid: Dictionary = {}
var hud_touches: Dictionary = {}
var pinch_distance := 0.0
var suppress_tap_until := 0
var drawn_shots := 0
var last_touch_ms := -10000
var interact: Button
var player_xp: ProgressBar
var extra_icons: Dictionary = {}
var modal_backdrop: ColorRect
var gallery_page := -1
var loadout_button: Button
var target_portrait: TextureRect
var portrait_target := -1
var target_health_skin: StyleBoxFlat
var hud_icons: Dictionary={}
var painted: Dictionary={}
var deck_icons: Dictionary={}
var focused_deck_index: int=-1 # Selected physical deck in the mobile deckyard
var ammo_selector: Button
var settings_button: Button
var render_toggle: Button
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
var supply_selector: Button
var buff_bar: Control
var kessel_log: Array[String]=[]
var guild_name_input: LineEdit
var guild_tag_input: LineEdit
var previous_region := -1
var hud_size := 1 # 0 compact, 1 comfortable, 2 large
var projectile_visual_count := 3 # purely cosmetic per actual hit: 1, 3, 5 or 8
# M3107: user-local presentation switches. Gameplay always runs unchanged.
const VFX_DEFAULT_FLAGS := {"enabled":true,"flight":true,"muzzle":true,"impact":true,"particles":true,"water":true,"flashes":true}
var vfx_flags: Dictionary = VFX_DEFAULT_FLAGS.duplicate(true)
var vfx_intensity := 1.35
# Classic is mandatory on Web and selectable on native. It uses no 3D stage.
var browser_classic := OS.has_feature("web")
var classic_atlases: Dictionary={}
var classic_geometry: Dictionary={}
var classic_monster_bottoms: Dictionary={}
var classic_heading_cache: Dictionary={}
var web_fast_mode := OS.has_feature("web")
# Browser quality controller samples actual presented frames only once per
# 2.5 seconds. Deliberate hysteresis prevents constant GPU buffer resizes.
var web_fps_clock: float=0.0
var web_fps_frames: int=0
var web_fps_warmup: float=0.0
var web_fps_last: float=0.0
var web_quality_good_windows: int=0
var web_minimap_clock: float=0.0
# Independent from combat VFX: mobile users can disable mesh rocking and wakes.
var ambient_motion_enabled := true
var wallet_previous: Array[int]=[]
var wallet_tweens: Dictionary={}
var ship_animations_enabled := true
var wake_effects_enabled := true
# Centered, device-proportional menu frames; legacy fullscreen choice is ignored.
var menu_layout := "balanced"
var double_tap_attack_enabled := false
const DOUBLE_TAP_MIN_MS := 70
const DOUBLE_TAP_ATTACK_MS := 360
const DOUBLE_TAP_ATTACK_RADIUS := 82.0
var last_enemy_tap_id := -1
var last_enemy_tap_ms := -10000
var last_enemy_tap_screen := Vector2.ZERO
var ship_switch_pulse_at := -100.0
var journal_visible := true
var hud_scale := 1.0
var camera_pad: Control
var target_cycle: Button
var camera_pad_visible := true
var plate_rects: Dictionary = {}
# The same names and font sizes are measured every frame at sea; cache widths
# for mobile CPU savings. Invalidate by actual font pixel size in the key.
var plate_text_width_cache: Dictionary = {}
# Pure cosmetic target reacquisition pulse, never a new gameplay target.
var ring_last_target := -1
var ring_target_acquired_at := -100.0
var plate_overlay: Control
var mesh_layer
var render_mode := "hybrid"
# 1 shaded starter, 1 untouched Corsair test, ten variants of one shared Corsair GLB.
const ELITE_V2_NAMES := ["Obsidian","Bordeaux","Tiefblau","Waldgrün","Violett","Petrol","Elfenbein","Stahlblau","Karmesin","Knochen"]
const ELITE_V2_ACCENTS := [Color("caa668"),Color("ce7b8f"),Color("669dd7"),Color("6bb28a"),Color("b392dc"),Color("5fc3b0"),Color("e1cda0"),Color("87aeda"),Color("e06f70"),Color("d5c9b5")]
const FINAL_SHIP_PREVIEW: Texture2D=preload("res://assets/player/schattenkriegsschiff_preview.png")
const ELITE_ONE_SHIP_PREVIEW: Texture2D=preload("res://assets/player/black_crown_elite_1_preview.png")
const SHIPYARD_SEA_TILE: Texture2D=preload("res://assets/ui/painted/sea_tile.png")
const SHIPYARD_STUDIO_KEY: Shader=preload("res://shipyard_preview_key.gdshader")
const FINAL_SHIP_LENGTH := 158.0
const NPC_VISUAL_SCALE := 0.90
# Only the Classic 2D presentation scales down the enormous player/NPC
# sprites seen at 2340x1080. The world body, hitbox, NPC speed, waypoints and
# native 2.5D/3D mesh sizes stay exactly as before.
const CLASSIC_HULL_SCALE := 0.62
const CLASSIC_VIEWPORT_ZOOM_BOOST_MAX := 1.15
const CLASSIC_LABEL_CLEARANCE_PX := 11.0
var plate_fleet: Array[Dictionary] = []
## Keep the maximum artwork extent stable across all rendered headings.
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
	# Browser is always Classic. Android/desktop use the saved graphics mode.
	# Steering must be configured before any sea-chart route is created.
	sim.set_classic_steering(browser_classic)
	if browser_classic:_load_classic_atlases()
	get_tree().set_meta("abyssal_ui_motion",ambient_motion_enabled)
	previous_region=sim.map_id
	camera = Camera2D.new()
	# Camera and ship-nameplate sampling must share the idle/render clock.
	camera.process_callback=Camera2D.CAMERA2D_PROCESS_IDLE
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
	ocean.set_shader_parameter("web_classic",browser_classic)
	_build_ui()
	_apply_ambient_motion()
	_apply_web_performance()
	_start_online_presence()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_ui()
	if get_tree().has_meta("abyssal_start_modal"):
		var requested: String=str(get_tree().get_meta("abyssal_start_modal"))
		get_tree().remove_meta("abyssal_start_modal")
		if requested in ["Werft","Markt","Decks","Kastelle","Bonuskarten","Battle Pass","Logbuch","Seekarten","Monster","Events","Bewaffnung","Kessel","Premium-Shop","Belohnungen","Freunde","Gilde","Hafen","Profil"]:
			_open_modal(requested)
	# Test harnesses attach the scene before claiming it; only a real scene change shows the boot curtain.
	if get_tree().current_scene==self:_begin_loading(1.4)
	var data_boot=get_tree().root.get_node_or_null("DataBoot")
	if data_boot!=null:data_boot.mark_healthy()
	if browser_classic:print("BROWSER_READY:sea")

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

## Test-only online presence. Account and room transport are real, but the
## economy, enemy AI, PvP and ship damage remain local to each client.
## Never treat server presence snapshots as player or inventory authority.
func _start_online_presence() -> void:
	if not get_tree().has_meta("abyssal_session"):return
	online_client=NETWORK.new()
	online_client.name="OnlinePresencePreview"
	add_child(online_client)
	online_client.snapshot_received.connect(_online_snapshot)
	online_client.connection_changed.connect(_online_connection_changed)
	_join_online_room()

func _join_online_room() -> void:
	if online_client==null or not is_instance_valid(online_client):return
	if str(online_client.token).is_empty() or sim.in_bonus_map():return
	var result: Error=online_client.connect_world(sim.map_id)
	if result!=OK:online_connected=false

func _online_connection_changed(connected: bool) -> void:
	online_connected=connected
	sim.player["network_motion"]=connected
	if not connected:
		online_players.clear()
		online_population=0
		online_has_position=false
		sim.player.path.clear()

func _online_snapshot(packet: Dictionary) -> void:
	if str(packet.get("type",""))=="welcome" and packet.get("player") is Dictionary:
		var spawn: Dictionary=packet.player
		sim.player.pos=Vector2(float(spawn.x),float(spawn.y))
		sim.player.heading=Vector2.from_angle(float(spawn.heading))
		sim.player.skin=clampi(int(spawn.skin),0,13)
		sim.player.path.clear()
		online_own_target=sim.player.pos
		online_own_heading=sim.player.heading
		online_has_position=true
		sim.captain_name=str(online_client.account.get("username",sim.captain_name))
		sim.captain_id=str(online_client.account.get("id",sim.captain_id))
		return
	if str(packet.get("type",""))!="snapshot" or int(packet.get("map_id",-1))!=sim.map_id:return
	var entries: Variant=packet.get("players",[])
	if not entries is Array:return
	var all_players: Array=entries
	online_population=mini(all_players.size(),32)
	var others: Array[Dictionary]=[]
	var my_id: String=str(online_client.account.get("id","")) if online_client!=null else ""
	for candidate in all_players.slice(0,32):
		if not candidate is Dictionary:continue
		var x: float=float(candidate.get("x",-1))
		var y: float=float(candidate.get("y",-1))
		if not Vector2(x,y).is_finite() or x<0 or x>sim.WORLD.x or y<0 or y>sim.WORLD.y:continue
		var heading: Vector2=Vector2.from_angle(float(candidate.get("heading",PI)))
		if str(candidate.get("id",""))==my_id:
			online_own_target=Vector2(x,y)
			online_own_heading=heading
			if not bool(candidate.get("moving",true)):sim.player.path.clear()
			continue
		var uid: String=str(candidate.get("id",""))
		if uid.is_empty():continue
		if not online_actor_ids.has(uid):
			online_actor_ids[uid]=online_next_actor_id
			online_next_actor_id-=1
		var point: Vector2=Vector2(x,y)
		for previous: Dictionary in online_players:
			if str(previous.player_uid)==uid:point=previous.pos;break
		others.append({"id":int(online_actor_ids[uid]),"player_uid":uid,"is_player":true,"remote_player":true,
			"name":str(candidate.get("username","Kapitän")).left(24),"kind":"ship",
			"pos":point,"network_target":Vector2(x,y),"heading":heading,"skin":clampi(int(candidate.get("skin",0)),0,13),
			"hp":clampi(int(candidate.get("hp",2400)),0,10000000),"max_hp":clampi(int(candidate.get("max_hp",2400)),1,10000000),
			"shield":0,"max_shield":0,"speed":165.0,"slow":0.0,"path":[],"elite":false})
	online_players=others
	# Drop identities of departed players to bound caches during long sessions.
	var active: Dictionary={}
	for other: Dictionary in others:active[str(other.player_uid)]=true
	for uid: String in online_actor_ids.keys():
		if not active.has(uid):
			classic_heading_cache.erase(int(online_actor_ids[uid]))
				online_actor_ids.erase(uid)

func _send_online_course(point: Vector2) -> void:
	if online_client!=null and is_instance_valid(online_client) and online_connected:
		online_client.send_course(point,sim.player.path)

func _update_online_ships(delta: float) -> void:
	if not online_connected:return
	var blend: float=1.0-exp(-delta*18.0)
	if online_has_position:
		sim.player.pos=sim.player.pos.lerp(online_own_target,blend)
		sim.player.heading=online_own_heading
	for other: Dictionary in online_players:
		other.pos=Vector2(other.pos).lerp(Vector2(other.network_target),blend)
	online_profile_age+=delta
	if online_profile_age>=.5:
		online_profile_age=0.0
		online_client.send_appearance(int(sim.player.skin),int(sim.player.hp),int(sim.player.max_hp))

func _sharp_zoom() -> float:
	var max_boost: float=CLASSIC_VIEWPORT_ZOOM_BOOST_MAX if browser_classic else 1.7
	return desired_zoom * clampf(get_viewport_rect().size.y / 720.0, 1.0, max_boost)

func _load_classic_atlases() -> void:
	if browser_classic:
		var metadata_path: String=CLASSIC_ATLAS_ROOT+"manifest.json"
		var metadata: Variant=null
		if FileAccess.file_exists(metadata_path):metadata=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		else:
			# Signed native exports include this index already; JSON sidecars
			# need not alter the installed updater/bootstrap export settings.
			var provenance: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://assets/provenance.json"))
			if provenance is Dictionary:metadata=provenance.get("classic_fleet")
		if metadata is Dictionary:
			for entry: Dictionary in metadata.get("atlases",[]):classic_geometry[str(entry.name)]=entry
			classic_monster_bottoms=metadata.get("monster_bottoms",{})
		var baked_keys: Array[String]=[]
		for model_key: String in CLASSIC_MODEL_KEYS:baked_keys.append(model_key)
		for index in range(1,11):baked_keys.append("elite_%02d" % index)
		baked_keys.append_array(["event_halloween","event_columbus"])
		for key: String in baked_keys:
			var file: String=CLASSIC_ATLAS_ROOT+key+".png"
			if ResourceLoader.exists(file):
				classic_atlases[key]=load(file) as Texture2D
			else:
				if not key.begins_with("elite_") and not key.begins_with("event_"):
					push_error("Missing original-GLB browser sprite atlas: "+file)

func _load_assets() -> void:
	if browser_classic:_load_classic_atlases()
	for key in ["kraken","serpent","crab","glitter","pumpkin"]:expansion_art[key]=load("res://assets/expansion/"+key+".webp")
	for name in ["anchor","ship","book","compass","chest","gear","plus","minus","focus","arrow","target_cycle"]:hud_icons[name]=load("res://assets/ui/icons/"+name+".svg")
	for key in ["cannon","armor","hunter","navigation","logistics","tide","storm","salvage","blessing"]:
		deck_icons[key]=load("res://assets/ui/abyssal/"+key+".svg")
	# The decorative watchtower on the first island was removed; harbors have their own real asset.
	# Explicit selection: current production ship plus the original full-geometry Elite 1 test.
	skins.append({"name":"Schattenkriegsschiff","mesh_key":"schattenkriegsschiff_shaded","views":0})
	skin_previews.append(FINAL_SHIP_PREVIEW)
	skins.append({"name":"Black Crown Corsair · Testmodell","mesh_key":"black_crown_corsair_elite_test","views":0,"texture_level":0})
	skin_previews.append(ELITE_ONE_SHIP_PREVIEW)
	for index in ELITE_V2_NAMES.size():
		skins.append({"name":"Elite-Schiff %02d · %s" % [index+1,ELITE_V2_NAMES[index]],"mesh_key":"black_crown_corsair_elite_test","texture_level":index+1,"views":0})
		skin_previews.append(_ship_preview("res://assets/elite_v2/previews/elite_%02d.png" % (index+1)))
	for event in ["Halloween · Nachtkrone","Columbus · Entdeckerkrone"]:
		skins.append({"name":event,"mesh_key":"black_crown_corsair_elite_test","texture_level":skins.size()-1,"views":0})
		skin_previews.append(_ship_preview("res://assets/expansion/preview_"+("halloween" if skins.size()==13 else "columbus")+".webp"))
	for name in ["tropical","rock","snow","snow2"]:
		island_textures[name] = load("res://assets/reference/islands/"+name+".png")
	for name in ["cannonball","harpoon","chain","repair_chest"]:
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

func _ship_preview(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else FINAL_SHIP_PREVIEW

func _refresh_ship_catalog() -> void:
	_load_classic_atlases()
	for index in range(2,12):skin_previews[index]=_ship_preview("res://assets/elite_v2/previews/elite_%02d.png" % (index-1))
	skin_previews[12]=_ship_preview("res://assets/expansion/preview_halloween.webp")
	skin_previews[13]=_ship_preview("res://assets/expansion/preview_columbus.webp")

func _art(name: String) -> Texture2D:
	return extra_icons[name] if extra_icons.has(name) else painted.get(name)

## Capture just before/after each movement tick, then draw between both states
## on every render frame. This avoids 30 Hz hull/plate jumps on 60/120 Hz phones.
func _visual_snapshot() -> Dictionary:
	var positions: Dictionary={0:sim.player.pos}
	for actor: Dictionary in sim.npcs:positions[int(actor.id)]=actor.pos
	return positions

func _visual_actor_pos(actor: Dictionary) -> Vector2:
	var id=int(actor.id)
	var current: Vector2=actor.pos
	if not visual_before.has(id) or not visual_after.has(id):return current
	var previous: Vector2=visual_before[id]
	var latest: Vector2=visual_after[id]
	# Don't interpolate teleports, respawns, or externally changed positions.
	if current.distance_squared_to(latest)>.01 or previous.distance_to(latest)>200.0:return current
	return previous.lerp(latest,clampf(accumulator/SIMULATION_TICK,0.0,1.0))

# Ships must leave trails only while actually moving; using 'path' alone
# painted foam even when a hull was blocked by islands or sitting in port.
func wake_motion_strength(measured: float,cruising: float) -> float:
	return clampf(measured/maxf(cruising,1.0),0.0,1.0)

func _wake_speed_for(actor: Dictionary) -> float:
	return float(wake_tracks.get(int(actor.get("id",-1)),{}).get("speed",0.0))

func _wake_intensity_for(actor: Dictionary) -> float:
	return wake_motion_strength(_wake_speed_for(actor),float(actor.get("speed",1.0)))

func _update_wake_tracks(delta: float) -> void:
	var alive: Dictionary={}
	var boats: Array[Dictionary]=[sim.player]
	for npc: Dictionary in sim.npcs:
		if int(npc.hp)>0 and str(npc.get("kind","ship"))=="ship":boats.append(npc)
	boats.append_array(online_players)
	for actor: Dictionary in boats:
		if int(actor.hp)<=0:continue
		var id: int=int(actor.id)
		alive[id]=true
		var point: Vector2=_visual_actor_pos(actor)
		if not wake_tracks.has(id):
			wake_tracks[id]={"last":point,"speed":0.0,"points":[],"sample_time":elapsed}
			continue
		var state: Dictionary=wake_tracks[id]
		var previous: Vector2=state.get("last",point)
		var dist: float=point.distance_to(previous)
		if dist>190.0:
			# Teleport, map crossing and respawn must not create a giant wake.
			wake_tracks[id]={"last":point,"speed":0.0,"points":[],"sample_time":elapsed}
			continue
		var nominal: float=maxf(float(actor.get("speed",40.0)),1.0)
		var measured: float=minf(dist/maxf(delta,0.0001),nominal*1.6)
		state["speed"]=lerpf(float(state.get("speed",0.0)),measured,clampf(delta*7.0,0.0,1.0))
		state["last"]=point
		var history: Array=state.get("points",[])
		while not history.is_empty() and elapsed-float(history[0].time)>WAKE_LIFETIME:
			history.pop_front()
		if elapsed-float(state.get("sample_time",0.0))>=WAKE_SAMPLE_INTERVAL:
			state["sample_time"]=elapsed
			if not history.is_empty():
				var displacement: Vector2=point-Vector2(history.back().pos)
				if displacement.length()>2.0:
					history.append({"pos":point,"time":elapsed,"course":displacement.normalized(),"strength":wake_motion_strength(float(state.speed),nominal)})
			elif measured>2.5:
				var course: Vector2=Vector2(actor.get("heading",Vector2.RIGHT)).normalized()
				history.append({"pos":point,"time":elapsed,"course":course,"strength":wake_motion_strength(float(state.speed),nominal)})
		while history.size()>16:history.pop_front()
		state["points"]=history
		wake_tracks[id]=state
	for key in wake_tracks.keys():
		if not alive.has(key):wake_tracks.erase(key)

func _draw_wake(actor: Dictionary) -> void:
	if not wake_effects_enabled or str(actor.get("kind","ship"))!="ship":return
	var state: Dictionary=wake_tracks.get(int(actor.id),{})
	if state.is_empty():return
	var history: Array=state.get("points",[])
	if history.is_empty():return
	var length: float=_actor_visual_length(actor)
	for sample in history:
		var age: float=elapsed-float(sample.time)
		if age<0.06 or age>WAKE_LIFETIME:continue
		var fade: float=VISUALS.wake_sample_strength(sample,elapsed,WAKE_LIFETIME)
		if fade<0.014:continue
		var direction: Vector2=Vector2(sample.course).normalized()
		if direction.length_squared()<0.1:continue
		var cross: Vector2=Vector2(-direction.y,direction.x)
		var back: Vector2=Vector2(sample.pos)-direction*length*.34
		var spread: float=length*(.075+age*.10)
		var ripple_clock: float=elapsed if ambient_motion_enabled else 0.0
		var scatter: float=sin(ripple_clock*3.0+age*7.0+float(actor.id))*(.8+age*1.0)
		for sign_value in [-1.0,1.0]:
			var shore: Vector2=back+cross*(spread+scatter)*sign_value
			var trailing: Vector2=shore-direction*(8.0+age*6.5)
			draw_line(shore,trailing,Color(.73,.93,.96,.40*fade),1.65,true)
			draw_circle(shore,1.2+age*.55,Color(.78,.97,1.0,.20*fade))

# M3094: wave contact reaches the actual dark hull's outer edge, not
# the hidden narrow centerline under the 3D scene. No thick platform.
func _draw_ship_waterline(actor: Dictionary,point: Vector2,heading: Vector2,length: float) -> void:
	if heading.length_squared()<0.5:return
	var moving: float=_wake_intensity_for(actor) if wake_effects_enabled else 0.0
	var alpha: float=(0.11 if browser_classic else 0.17)+moving*0.22
	var ripple_clock: float=elapsed if ambient_motion_enabled else 0.0
	var half_width: float=length*(.175 if (int(actor.get("id",-1))==0 or bool(actor.get("remote_player",false))) and int(actor.get("skin",0))>=1 and int(actor.get("skin",0))<=13 else .137)
	draw_set_transform(point+Vector2(0,3),heading.angle(),Vector2.ONE)
	for side in [-1.0,1.0]:
		var side_sign: float=side
		var waterline: PackedVector2Array=PackedVector2Array()
		for segment in 10:
			var progress: float=float(segment)/9.0
			var longitudinal: float=length*(-.36+.72*progress)
			var taper: float=pow(maxf(0.0,1.0-pow(absf(progress*2.0-1.0),2.2)),.7)
			var moving_foam: float=sin(ripple_clock*5.1-progress*15.0+side_sign)*moving*1.7
			var swell: float=sin(ripple_clock*1.7-progress*7.0+side_sign+float(actor.id)*.37)*.35*taper
			moving_foam+=swell
			waterline.append(Vector2(longitudinal,side_sign*(half_width*taper+moving_foam)))
		draw_polyline(waterline,Color(.68,.87,.93,alpha),1.45,true)
		if moving>.2:
			var bow: Vector2=Vector2(length*.29,side_sign*half_width*.67)
			var spread: Vector2=Vector2(length*.16,-side_sign*length*.10)
			draw_line(bow,bow+spread,Color(.78,.96,1.0,moving*.27),1.35,true)
	draw_set_transform(Vector2.ZERO)

func _draw_bow_spray(actor: Dictionary,point: Vector2,heading: Vector2,length: float) -> void:
	if not wake_effects_enabled:return
	var intensity: float=_wake_intensity_for(actor)
	if intensity<0.12 or heading.length_squared()<0.5:return
	var forward: Vector2=heading.normalized()
	var cross: Vector2=Vector2(-forward.y,forward.x)
	var nose: Vector2=point+forward*(length*.38)
	for side_value in [-1.0,1.0]:
		var crest: Vector2=nose+cross*side_value*(length*.055)
		var out: Vector2=crest-forward*length*.085+cross*side_value*length*.070
		draw_line(crest,out,Color(.77,.97,1.0,.38*intensity),1.45,true)
		draw_circle(out,1.8,Color(.83,.98,1.0,.28*intensity))

func _process(delta: float) -> void:
	_update_web_auto_quality(delta)
	status_age += delta
	if modal_backdrop!=null:modal_backdrop.visible=modal.visible
	if modal.visible:scroll_hint.queue_redraw()
	elapsed += delta
	accumulator = minf(accumulator+delta,0.2)
	while accumulator >= SIMULATION_TICK:
		visual_before=_visual_snapshot()
		sim.step(SIMULATION_TICK)
		visual_after=_visual_snapshot()
		accumulator -= SIMULATION_TICK
	if ring_last_target!=int(sim.target):
		ring_last_target=int(sim.target)
		ring_target_acquired_at=elapsed if ring_last_target>0 else -100.0
	if previous_region!=sim.map_id:
		wake_tracks.clear()
		_sync_region()
	_update_online_ships(delta)
	_update_wake_tracks(delta)
	if loading_left>0:_advance_loading(delta)
	if camera_pad.visible and not modal.visible:_pan_camera(camera_pad.value,delta)
	_classic_keyboard_pan(delta)
	var render_player: Vector2=_visual_actor_pos(sim.player)
	var goal: Vector2=render_player if camera_locked else camera_anchor
	pan=goal-render_player
	# With follow-lock active, frame-interpolated ship and camera stay together.
	# A one-pixel change in the captain plate is then *real* screen movement,
	# not a 30 Hz simulation/camera mismatch amplified by high zoom.
	if camera_locked:camera.position=goal
	else:camera.position=camera.position.lerp(goal,1.0-exp(-delta*5.0))
	camera.zoom = camera.zoom.lerp(Vector2.ONE*_sharp_zoom(),1.0-exp(-delta*8.0))
	# Commit this frame's camera transform before projecting screen-space labels.
	# Calculating readouts later inside _draw() creates a one-frame delay.
	camera.force_update_scroll()
	_sync_plate_overlay()
	ocean.set_shader_parameter("camera_world",camera.position)
	ocean.set_shader_parameter("map_zoom",camera.zoom.x)
	ocean.set_shader_parameter("viewport_size",get_viewport_rect().size)
	ocean.set_shader_parameter("region_tint",CONTENT.MAPS[sim.map_id].tint)
	chart_mini.camera_world = camera.position
	chart_mini.view_world = get_viewport_rect().size/camera.zoom
	# Minimap icons (not the chart or ship labels) need only ~10 updates/s.
	# Avoid redrawing this entire secondary canvas every display frame on WebGL.
	web_minimap_clock+=delta
	if not (OS.has_feature("web") and web_fast_mode) or web_minimap_clock>=0.10:
		web_minimap_clock=0.0
		chart_mini.queue_redraw()
	_sync_ruler()
	refresh_clock += delta
	if refresh_clock > (0.20 if OS.has_feature("web") and web_fast_mode else 0.12):
		refresh_clock = 0
		_refresh_ui()
	save_clock += delta
	if save_clock > 8.0:
		save_clock = 0
		_save_progress()
	queue_redraw()

func _draw() -> void:
	if camera == null: return
	var view = Rect2(camera.position-get_viewport_rect().size/camera.zoom*0.5,get_viewport_rect().size/camera.zoom).grow(350)
	# Projected art is drawn on the same 2D chart as movement and collision.
	for island in sim.islands:
		if not view.has_point(island.pos): continue
		var guild_island: bool=bool(island.get("guild_fortress",false))
		var tex: Texture2D=GUILD_FORTRESS_ART if guild_island else island_textures[island.art]
		var width: float=island.width
		var dimensions: Vector2=Vector2(width,width*CONTENT.GUILD_FORTRESS_ASPECT) if guild_island else tex.get_size()*width/tex.get_width()
		var point: Vector2=island.pos
		draw_texture_rect(tex,Rect2(point-dimensions*Vector2(0.5,0.65),dimensions),false)
		_draw_coastal_surf(island)
		if guild_island:
			# Dynamic owner crest; the texture never hardcodes any guild's name.
			var owned: bool=sim.tower_friendly()
			var tag: String=sim.tower_tag()
			var keep: Vector2=point+Vector2(0,-dimensions.y*.31)
			var plate: Rect2=Rect2(keep-Vector2(69,19),Vector2(138,26))
			draw_rect(plate,Color("173c32" if owned else "4a2525",.88))
			draw_rect(plate,Color("e2b768"),false,2.0)
			draw_string(font,plate.position+Vector2(11,18),"FESTUNG [%s]" % tag,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffe0a3"))
		# Only geometry: no island nameplates (internal navigation names remain
		# available for testing and staff tools).
		# The former fake watchtower on island 0 is deliberately gone.
	# Planned route and tap marker remain visible without obscuring the sea.
	# All normal regions display a dedicated compact island harbor.
	# Transparent art is placed so the berth at (802,442) matches the
	# exact navigable world coordinate used by can_dock() and staff tools.
	# No decorative island collision is added across the ship's approach.
	if sim.has_harbor() and view.has_point(sim.harbor):
		_draw_island_harbor()
	for sparkle in sim.sparkles:
		if float(sparkle.respawn)>0 or not view.has_point(sparkle.pos):continue
		_draw_sparkle(sparkle.pos,float(sparkle.id))
	_draw_sea_edges(view)
	if not sim.player.path.is_empty():
		var goal: Vector2=sim.player.path.back()
		var before: Vector2=sim.player.pos
		# Classic's real 45-degree steps are purposely short and numerous.
		# Do not paint a busy dotted zigzag over the entire sea chart.
		# The destination marker stays clear; native modes keep their route.
		if not browser_classic:
			for point: Vector2 in sim.player.path:
				draw_dashed_line(before,point,Color(0.50,0.83,0.80,0.35),1.4,10.0)
				before=point
		draw_arc(goal,16+sin(elapsed*3)*2,0,TAU,32,Color(0.54,0.92,0.85,0.7),1.7,true)
		draw_line(goal-Vector2(22,0),goal+Vector2(22,0),Color(0.5,0.9,0.84,0.5),1.0)
		draw_line(goal-Vector2(0,16),goal+Vector2(0,16),Color(0.5,0.9,0.84,0.5),1.0)
	for drop in sim.drops:
		if not view.has_point(drop.pos): continue
		var p: Vector2 = drop.pos+Vector2(0,sin(elapsed*2+drop.id)*3)
		_ellipse(p,Vector2(31,13),Color(0.95,0.7,0.2,0.1))
		var tex: Texture2D = expansion_art.glitter
		var dims = tex.get_size()*66.0/maxf(tex.get_width(),tex.get_height())
		draw_texture_rect(tex,Rect2(p-dims*0.5,dims),false)
		_label(p+Vector2(0,31),"BEUTE",10,GOLD)
	for pickup: Dictionary in sim.event_pickups:
		if float(pickup.respawn)>0 or not view.has_point(pickup.pos):continue
		var tex: Texture2D=expansion_art.pumpkin if pickup.event=="halloween" else expansion_art.glitter
		var dims: Vector2=tex.get_size()*75.0/maxf(tex.get_width(),tex.get_height())
		draw_texture_rect(tex,Rect2(pickup.pos-dims*.5+Vector2(0,sin(elapsed*1.6+pickup.id)*3),dims),false)
		_ellipse_line(pickup.pos,Vector2(29,12),Color("f9ad55",.55),1.4)
	var fleet: Array[Dictionary] = []
	fleet.append(sim.player)
	for npc in sim.npcs:
		if view.has_point(npc.pos): fleet.append(npc)
	for other: Dictionary in online_players:
		if view.has_point(other.pos):fleet.append(other)
	fleet.sort_custom(func(a,b):return a.pos.y < b.pos.y)
	# Foam is rendered below each real GLB and sprite: 2D map still owns water.
	for actor: Dictionary in fleet:
		if int(actor.hp)>0:_draw_wake(actor)
	for actor: Dictionary in fleet:
		if int(actor.hp)>0: _draw_actor(actor)
	# Name/HP/shield/decks are rendered in a screen-space CanvasLayer,
	# already synced during _process(), never sourced from an old draw pass.
	# Original M3100 missile silhouettes, contrails, sparks and shadow arcs.
	# Both approved GLB modes share the same chart-space combat VFX layer.
	drawn_shots=0
	# Keep real projectiles and impacts, but skip purely decorative fragment
	# particles, water flashes and high overdraw in mobile-browser fast mode.
	var fast_fx: bool=OS.has_feature("web") and web_fast_mode
	var fx_strength: float=minf(vfx_intensity,0.85) if fast_fx else vfx_intensity
	var fx_particles: bool=bool(vfx_flags.particles) and not fast_fx
	var fx_splashes: bool=bool(vfx_flags.water) and not fast_fx
	var fx_flashes: bool=bool(vfx_flags.flashes) and not fast_fx
	# One compact flying Kugelhaufen per salvo. A three-hit broadside does
	# NOT produce three separate rows or three duplicate bundles.
	var rendered_salvos: Dictionary={}
	for shot: Dictionary in sim.shots:
		if float(shot.get("age",-1.0))<0.0:continue
		var salvo_key: int=int(shot.get("salvo_group",shot.get("id",-1)))
		if rendered_salvos.has(salvo_key):continue
		rendered_salvos[salvo_key]=true
		drawn_shots+=1
		COMBAT_FX.draw_projectile(self,shot,sim.clock,projectile_visual_count,bool(vfx_flags.enabled) and bool(vfx_flags.flight),fx_strength,fx_particles)
	for event in sim.events:
		var age: float = sim.clock-float(event.time)
		if age>(1.8 if str(event.type)=="impact" else 1.2):continue
		var p: Vector2 = event.pos
		if event.type=="impact":
			if bool(vfx_flags.enabled) and bool(vfx_flags.impact):
				SPRITE_FX.draw_impact(self,event,age,fx_strength,fx_particles,fx_splashes,fx_flashes)
		elif event.type=="muzzle":
			if bool(event.get("powder",false)):
				_ellipse_line(p-Vector2(0,20),Vector2(22+age*32,10+age*15),Color("ffb155",maxf(0,.8-age)),3.0)
			if bool(vfx_flags.enabled) and bool(vfx_flags.muzzle):
				SPRITE_FX.draw_muzzle(self,event,age,fx_strength,fx_particles,fx_flashes)
		elif event.type=="sunk":
			COMBAT_FX.draw_sinking(self,event,age)
		elif event.type=="loot":pass
		elif event.type=="level":
			_ellipse_line(p,Vector2(50+age*80,22+age*35),Color(0.5,0.9,1,1-age/1.2),2.2)
			_label(p+Vector2(0,-100-age*25),"KAPITÄNSSTUFE %d" % int(event.value),22,CYAN)
		elif event.type=="essence":pass
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
# Small, readable and tap-friendly harbor rather than a random anchor in sea.
# Surface effects follow the authored coast; land and collision never oscillate.
func _draw_coastal_surf(island: Dictionary) -> void:
	if not wake_effects_enabled:return
	var outline: PackedVector2Array=island.outline
	var center: Vector2=island.bounds.get_center()
	var water_edge: float=island.bounds.position.y+island.bounds.size.y*.66
	for i in range(0,outline.size(),3):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+3)%outline.size()]
		if minf(a.y,b.y)<water_edge:continue
		var phase: float=fposmod(elapsed*.32+float(i)*.071,1.0)
		var offset: Vector2=((a+b)*.5-center).normalized()*(3.0+phase*12.0)
		draw_line(a+offset,b+offset,Color(.68,.88,.88,sin(phase*PI)*.24),1.4,true)

func _draw_island_harbor() -> void:
	var berth: Vector2=sim.harbor
	var pulse: float=.5+.5*sin(elapsed*1.9)
	if CONTENT.has_guild_island(sim.map_id):
		# The guild berth belongs to the inner water basin: NO independent
		# harbor island texture or shore collider can obstruct its entrance.
		var ink: Color=Color("80e0d0") if sim.tower_friendly() else Color("ebbc75")
		draw_circle(berth,25.0,Color(ink,.055+.04*pulse))
		draw_arc(berth,29.0+2.0*pulse,0,TAU,40,Color(ink,.30+.24*pulse),1.7,true)
		draw_line(berth+Vector2(0,-15),berth+Vector2(0,13),Color(ink,.68),1.7,true)
		draw_arc(berth+Vector2(0,5),8.0,0,PI,20,Color(ink,.70),2.0,true)
		# Only the small docking UI is drawn here. The entire approach,
		# including the entrance mouth, remains unobstructed water.
		if sim.player.pos.distance_to(berth)<410.0 and not sim.docked and _landmark_label_visible(berth+Vector2(0,62)):
			_label(berth+Vector2(0,62),"GILDENHAFEN · ANDOCKEN",12,Color(ink,.92))
		return
	draw_texture_rect(HARBOR_ISLAND,Rect2(berth-HARBOR_DOCK_OFFSET,HARBOR_DRAW_SIZE),false)
	# Directly centered on the docking coordinate, not the graphical islet.
	draw_arc(berth,36.0,0,TAU,40,Color(GOLD,.30+.23*pulse),1.6,true)
	if sim.player.pos.distance_to(berth)<410.0 and not sim.docked and _landmark_label_visible(berth+Vector2(0,78)):
		_label(berth+Vector2(0,78),"HAFEN · ANDOCKEN",12,Color(GOLD,.90))


func _landmark_label_visible(point: Vector2) -> bool:
	var bodies: Array=[sim.player]
	bodies.append_array(sim.npcs)
	return VISUALS.landmark_label_visible(point,bodies)

func _draw_sea_edges(view: Rect2) -> void:
	if sim.in_bonus_map():return
	for edge: String in ["east","west","north","south"]:
		var vertical: bool=edge in ["east","west"]
		var fixed: float=64.0 if edge in ["west","north"] else (sim.WORLD.x-64.0 if vertical else sim.WORLD.y-64.0)
		if vertical and (fixed<view.position.x-100 or fixed>view.end.x+100):continue
		if not vertical and (fixed<view.position.y-100 or fixed>view.end.y+100):continue
		var low: float=maxf(64.0,view.position.y if vertical else view.position.x)
		var high: float=minf((sim.WORLD.y if vertical else sim.WORLD.x)-64.0,view.end.y if vertical else view.end.x)
		if high<low:continue
		var destination: int=CONTENT.sea_edge_neighbor(sim.map_id,edge)
		var locked: bool=destination>=0 and sim.level<int(CONTENT.MAPS[destination].level)
		var color: Color=Color("6ad7d2") if destination>=0 else Color("7e8991")
		if locked:color=Color("d9ab62")
		var first: Vector2=Vector2(fixed,low) if vertical else Vector2(low,fixed)
		var last: Vector2=Vector2(fixed,high) if vertical else Vector2(high,fixed)
		draw_line(first,last,Color(color,.08),24.0,true)
		draw_line(first,last,Color(color,.75),2.0,true)
		var inward: Vector2={"east":Vector2.LEFT,"west":Vector2.RIGHT,"north":Vector2.DOWN,"south":Vector2.UP}[edge]
		var tangent: Vector2=Vector2.DOWN if vertical else Vector2.RIGHT
		for tick in range(ceili(low/160.0),floori(high/160.0)+1):
			var at: Vector2=Vector2(fixed,tick*160.0) if vertical else Vector2(tick*160.0,fixed)
			draw_line(at,at+inward*14.0,Color(color,.65),1.6,true)
			if tick%2==0 and destination>=0:
				var tip: Vector2=at+inward*24
				draw_polyline(PackedVector2Array([tip+inward*10-tangent*7,tip,tip+inward*10+tangent*7]),color,2.0,true)
		# Keep a single destination caption in the middle of the visible edge,
		# rather than hiding the only repeated caption under the combat buttons.
		var middle: float=(low+high)*.5
		var at: Vector2=Vector2(fixed,middle) if vertical else Vector2(middle,fixed)
		var label: String="WELTGRENZE"
		if destination>=0:
			var region: Dictionary=CONTENT.MAPS[destination]
			label="%s · %s" % [region.code,region.name]
			if locked:label+=" · AB LV. %d" % region.level
		_label(at+inward*140+Vector2(0,5),label,13,color)

func _npc_ship_texture(_actor: Dictionary) -> Texture2D:
	# NPCs are 3D-only; a nautical UI icon replaces obsolete sprite portraits.
	return painted.nav_ship

func _actor_visual_length(actor: Dictionary) -> float:
	var length: float=150.0
	if int(actor.id)==0 or bool(actor.get("remote_player",false)):
		length=180.0 if int(actor.get("skin",0))>=1 and int(actor.get("skin",0))<=13 else FINAL_SHIP_LENGTH
	elif str(actor.get("visual_key",""))=="black_crown_corsair_elite_test":
		length=180.0
	elif str(actor.get("kind",""))=="ship":
		length=float(CONTENT.SHIP_LENGTHS[posmod(int(actor.art),CONTENT.SHIP_LENGTHS.size())])*NPC_VISUAL_SCALE
	# The renderer uses the same smaller size for shadows, wake/waterline,
	# selection ring, actual atlas draw and visual hit rectangle. Only ships
	# shrink; sea monsters, shore defenses and physical navigation do not.
	if browser_classic and str(actor.get("kind","ship"))=="ship":
		length*=CLASSIC_HULL_SCALE
	return length

# M3095: classic sea-combat selection circles are flat chart overlays.
# They stay centered on the WATER footprint while the GLB rotates freely.
# No opaque selection platform and no duplicate 3D mesh.
func _selection_ring_visible(actor: Dictionary) -> bool:
	if int(actor.get("hp",0))<=0:return false
	var id: int=int(actor.get("id",-1))
	return id==0 or (id>0 and id==int(sim.target))

func _selection_ring_radii(actor: Dictionary) -> Vector2:
	if str(actor.get("kind",""))=="tower":return Vector2(48.0,20.0)
	var length: float=_actor_visual_length(actor)
	# M3098: water contact should hug the two large test hulls instead of
	# forming the wide neon oval seen in the Android M3097 comparison.
	# Both test models use the same visual length and therefore the same ring.
	if int(actor.get("id",-1))==0:
		return Vector2(maxf(36.0,length*0.44),maxf(16.0,length*0.185))
	return Vector2(maxf(36.0,length*0.58),maxf(16.0,length*0.245))

func _ship_design_accent(skin_id: int) -> Color:
	if skin_id==12:return Color("f59949")
	if skin_id==13:return Color("e6d2a6")
	if skin_id==0:return Color("62cce4")
	if skin_id==1:return Color("efbf69") # Original untouched Corsair test.
	if skin_id>=2 and skin_id<=11:return ELITE_V2_ACCENTS[skin_id-2]
	return Color("62cce4")

func _selection_ring_tint(actor: Dictionary) -> Color:
	if int(actor.id)==0:return _ship_design_accent(int(actor.get("skin",0)))
	if str(actor.get("kind",""))=="tower":
		return Color("d8b06d") if sim.tower_friendly() else Color("f47d62")
	if str(actor.get("event_key",""))=="halloween":return Color("eca655")
	if str(actor.get("event_key",""))=="columbus":return Color("6dd0c6")
	var hostile: bool=bool(actor.get("aggressive",false)) or bool(CONTENT.MAPS[sim.map_id].npc_hostile)
	return Color("f47d62") if hostile else Color("e6b869")

# Consistent on-screen line thickness across zoom 0.4x–2x, not the old
# world-space strokes that disappeared at low zoom and bloated up close.
func _ring_stroke_for_zoom(screen_pixels: float,zoom: float) -> float:
	return clampf(screen_pixels/maxf(zoom,.1),.55,8.0)

func _selection_ring_stroke(screen_pixels: float) -> float:
	var zoom: float=camera.zoom.x if camera!=null else 1.0
	return _ring_stroke_for_zoom(screen_pixels,zoom)

func _target_ring_pulse(at_seconds: float=0.0) -> float:
	var age: float=at_seconds-ring_target_acquired_at
	if ring_last_target<=0 or age<0.0 or age>=.85:return 0.0
	return pow(1.0-age/.85,1.35)

func _selection_ring_arc(center: Vector2,radii: Vector2,start: float,span: float,tint: Color,width: float) -> void:
	var points := PackedVector2Array()
	for segment in 13:
		var a: float=start+span*float(segment)/12.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_polyline(points,tint,width,true)

func _draw_ship_selection_ring(actor: Dictionary,point: Vector2) -> void:
	if not _selection_ring_visible(actor):return
	var enemy_selected: bool=int(actor.id)>0
	var radii: Vector2=_selection_ring_radii(actor)
	var tint: Color=_selection_ring_tint(actor)
	var pulse: float=0.5+0.5*sin(elapsed*(3.1 if enemy_selected else 1.5))
	var center: Vector2=point
	# Only the visible 3D captain ring shifts toward the hull's water contact.
	# The course, tap target and collision center remain exactly where they were.
	if not enemy_selected and mesh_layer!=null and mesh_layer.can_render_actor(actor):
		center.y+=_actor_visual_length(actor)*0.035
	# Short water-borne pulse after choosing a ship; no combat or collision effect.
	if not enemy_selected and elapsed-ship_switch_pulse_at>=0.0 and elapsed-ship_switch_pulse_at<1.15:
		var phase: float=clampf((elapsed-ship_switch_pulse_at)/1.15,0.0,1.0)
		_ellipse_line(center,radii*(1.05+phase*.8),Color(tint,(1.0-phase)*.58),_selection_ring_stroke(2.5-phase*.7))
	_ellipse_line(center,radii*1.055,Color(tint,0.09+0.06*pulse),_selection_ring_stroke(3.0))
	_ellipse_line(center,radii,Color(tint,0.64+0.14*pulse),_selection_ring_stroke(2.0 if enemy_selected else 1.8))
	_ellipse_line(center,radii*0.92,Color(tint,0.16+0.04*pulse),_selection_ring_stroke(.9))
	for quarter in 4:
		var start: float=float(quarter)*TAU/4.0+elapsed*(0.37 if enemy_selected else 0.10)
		_selection_ring_arc(center,radii,start,0.24,Color(tint,0.83),_selection_ring_stroke(2.6 if enemy_selected else 2.15))
	if enemy_selected:
		# Distinct focus ticks for the currently targeted vessel. They are
		# chart overlays, never a platform or a collision-size change.
		var acquired: float=_target_ring_pulse(elapsed)
		if acquired>0.0:
			var focus_radii: Vector2=radii*(1.08+.37*(1.0-acquired))
			_ellipse_line(center,focus_radii,Color(tint,.45*acquired),_selection_ring_stroke(2.2))
		for quadrant in 4:
			var a: float=float(quadrant)*PI*.5+PI*.25
			var direction := Vector2(cos(a)*radii.x,sin(a)*radii.y)
			draw_line(center+direction*1.08,center+direction*1.19,Color(tint,0.60+0.14*pulse),_selection_ring_stroke(1.8),true)

# Destroyed emplacements leave visible rubble rather than vanishing into an
# intact backdrop. No extra art or collision is added to the sea entrance.
func _draw_ruined_tower(actor: Dictionary) -> void:
	var point: Vector2=Vector2(actor.pos)
	var seed: float=float(int(actor.id))
	_ellipse(point+Vector2(0,3),Vector2(32,13),Color("100e0d"))
	for piece in 9:
		var angle: float=float(piece)*TAU/9.0+seed*.031
		var distance: float=10.0+float(piece%4)*4.8
		var origin: Vector2=point+Vector2(cos(angle)*distance,sin(angle)*distance*.44)
		var height: float=5.0+float((piece*3)%5)*1.8
		var chips:=PackedVector2Array([origin+Vector2(-5,2),origin+Vector2(-2,-height),origin+Vector2(3,-height*.68),origin+Vector2(6,2)])
		draw_colored_polygon(chips,Color("77736a") if piece%3==0 else Color("514c44"))
		draw_line(origin+Vector2(-2,-height),origin+Vector2(3,-height*.68),Color("a89d89",.65),1.0,true)
	if ship_animations_enabled and (float(actor.get("respawn",0.0))>0.0 or (not sim.guild.is_empty() and not sim.tower_friendly())):
		for plume in 3:
			var life: float=fmod(elapsed*.45+float(plume)*.33+seed*.015,1.0)
			var drift: Vector2=Vector2(sin(elapsed+float(plume)*2.3)*7.0-life*4.0,-15.0-life*35.0)
			draw_circle(point+drift,3.0+life*7.0,Color("6d655e",.14*(1.0-life)))

func _draw_actor(actor: Dictionary) -> void:
	if float(actor.hp)<=0:
		if str(actor.get("kind",""))=="tower":_draw_ruined_tower(actor)
		return
	if actor.get("kind","")=="tower":
		_draw_tower(actor)
		return
	var is_player = int(actor.id)==0
	var point: Vector2=_visual_actor_pos(actor)
	var heading: Vector2=actor.heading
	var length=_actor_visual_length(actor)
	# Both renderers use cheap line/circle foam at the same water footprint.
	_draw_bow_spray(actor,point,heading,length)
	# Mesh ships are lit in their own SubViewport. Do not add the previous
	# oversized opaque 2D oval beneath their hulls.
	var mesh_ship=mesh_layer!=null and mesh_layer.can_render_actor(actor)
	if mesh_ship:
		# M3095: immerse the keel in a broad but very transparent 2D contact
		# shadow and let wave crests sit at the outside of its actual hull.
		draw_set_transform(point+Vector2(0,3),heading.angle(),Vector2.ONE)
		_ellipse(Vector2.ZERO,Vector2(length*.34,length*.09),Color(.002,.018,.03,.25))
		draw_set_transform(Vector2.ZERO)
		_draw_ship_waterline(actor,point,heading,length)
	else:
		_ellipse(point+Vector2(0,4),Vector2(length*0.32,length*0.085),Color(0.0,0.02,0.04,0.25))
		if browser_classic and str(actor.get("kind",""))=="ship":_draw_ship_waterline(actor,point,heading,length)
	_draw_ship_selection_ring(actor,point)
	if is_player and sim.plates_on:
		_ellipse_line(point,Vector2(length*.48,length*.22),Color("90c9ee",.45+.15*sin(elapsed*2)),2.5)
	if is_player and sim.has_blessing():
		var blessing_pulse=.5+.5*sin(elapsed*3.2)
		if mesh_ship:
			# A subtle directional aura replaces the oversized hovering disk.
			draw_set_transform(point,heading.angle(),Vector2.ONE)
			_ellipse(Vector2.ZERO,Vector2(length*.40,length*.115),Color(.58,.34,1.0,.035+blessing_pulse*.025))
			_ellipse_line(Vector2.ZERO,Vector2(length*.42,length*.12),Color(.83,.69,1.0,.15),1.1)
			draw_set_transform(Vector2.ZERO)
		else:
			_ellipse(point+Vector2(0,2),Vector2(length*0.62,length*0.24),Color(0.62,0.38,1.0,.08+blessing_pulse*.06))
			_ellipse_line(point+Vector2(0,2),Vector2(length*0.5,length*0.18),Color(0.86,0.72,1.0,.4),1.8)
	# Selection markers were previously near-invisible, direction-dependent
	# strokes. M3095 draws a single stable circle underneath any ship instead.
	var hull_alpha=0.45 if is_player and sim.staff.hidden() else 1.0
	var monster = not is_player and actor.kind=="monster"
	if monster:
		var key: String=str(actor.get("monster_key",""))
		if expansion_art.has(key):
			var tex: Texture2D=expansion_art[key]
			var dims: Vector2=tex.get_size()*225.0/maxf(tex.get_width(),tex.get_height())
			if ship_animations_enabled:
				# Soft surface rings connect the moving limbs to the sea.
				for ring in 2:
					var phase: float=fposmod(elapsed*.42+float(actor.id)*.19+ring*.5,1.0)
					_ellipse_line(point+Vector2(0,dims.y*.22),Vector2(55+phase*60,12+phase*16),Color(.57,.85,.88,(1.0-phase)*.12),1.2)
			var mesh: ArrayMesh=MONSTER_MOTION.frame(key,elapsed,int(actor.id),ship_animations_enabled)
			draw_mesh(mesh,tex,Transform2D(0.0,dims,0.0,point))
		else:
			var col = posmod(roundi((heading.angle()+PI*0.25)/TAU*4),4)
			var row = int(elapsed*6)%CONTENT.MONSTER_ROWS if ship_animations_enabled else 0
			_draw_atlas(beast,point,210.0,col,row,CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS)
	elif browser_classic and not monster:
		_draw_classic_ship(actor,point,heading,length)
	elif not mesh_ship:
		# Never replace a broken native GLB with a fake sprite.
		pass
	if is_player and sim.staff.shows_badge():
		var pulse=.5+.5*sin(elapsed*4.0)
		if mesh_ship:
			draw_set_transform(point,heading.angle(),Vector2.ONE)
			_ellipse_line(Vector2.ZERO,Vector2(length*.41,length*.115),Color(sim.staff.color(),.15+pulse*.16),1.3)
			draw_set_transform(Vector2.ZERO)
		else:_ellipse_line(point,Vector2(length*.52,length*.2),Color(sim.staff.color(),.28+pulse*.35),2.4)
	# Persisting but subtle status VFX: flares mark targets, frozen hulls get
	# crystalline water contact, and slowed vessels show snow or chain wisps.
	COMBAT_FX.draw_status(self,actor,point,sim.clock,length)
	if is_player or sim.target==int(actor.id):
		var nose=point+heading*length*0.38
		var side=Vector2(-heading.y,heading.x)*4
		var course_tint: Color=_selection_ring_tint(actor)
		draw_line(nose-heading*8+side,nose,course_tint,1.4,true)
		draw_line(nose-heading*8-side,nose,course_tint,1.4,true)
	if gallery_page>=0:_nameplate(actor,point+Vector2(0,28))

## Original Abyssal sprites for the 2010–2016-style browser sea chart.
## One rotated 2D texture draw per vessel: no 3D GLB, lighting, shadows
## or per-frame mesh transforms. World coordinates and combat are unchanged.
func _classic_ship_texture(actor: Dictionary) -> Texture2D:
	if int(actor.get("id",0))==0:
		return CLASSIC_SLOOP if int(actor.get("skin",0))==0 else CLASSIC_GALLEON
	var key: String=str(actor.get("visual_key",""))
	var choice: int=posmod(int(actor.get("id",0)),3)
	if key.contains("brig") or key.contains("trader"):choice=1
	elif key.contains("galley") or key.contains("mariner"):choice=2
	return CLASSIC_SLOOP if choice==0 else CLASSIC_BRIG if choice==1 else CLASSIC_GALLEON

func _classic_atlas_key(actor: Dictionary) -> String:
	if int(actor.get("id",-1))==0 or bool(actor.get("remote_player",false)):
		var skin: int=int(actor.get("skin",0))
		if skin==0:return "schattenkriegsschiff_shaded"
		if skin==1:return "black_crown_corsair_elite_test"
		if skin>=2 and skin<=11:return "elite_%02d" % (skin-1)
		if skin==12:return "event_halloween"
		if skin==13:return "event_columbus"
		return "schattenkriegsschiff_shaded"
	return str(actor.get("visual_key",""))

func _classic_frame_for_actor(actor: Dictionary) -> int:
	var id: int=int(actor.get("id",-1))
	var heading: Vector2=actor.get("heading",Vector2.RIGHT)
	# The simulation now sails in real NE/SE/SW/NW mini-legs.
	# Never add an independent visual animation or fake side sway:
	# hull and actual travelled heading must match in every frame.
	var frame: int=VISUALS.heading_four(heading,int(classic_heading_cache.get(id,-1)))
	classic_heading_cache[id]=frame
	return frame

func _draw_classic_ship(actor: Dictionary,point: Vector2,heading: Vector2,length: float) -> void:
	var key: String=_classic_atlas_key(actor)
	var atlas: Texture2D=classic_atlases.get(key) as Texture2D
	if atlas!=null:
		var entry: Dictionary=classic_geometry.get(key,{})
		if not entry.is_empty():
			var frame: Dictionary=entry.frames[_classic_frame_for_actor(actor)]
			var spec: Dictionary=VISUALS.geometry(frame,length)
			var target: Rect2=spec.destination
			target.position+=point
			draw_texture_rect_region(atlas,target,spec.source)
			return
		# The eight baked frames stay available for future styles. Classic
		# selects only NE/NW/SW/SE; actual ship position follows its direct
		# simulated course, independently of how the hull is drawn.
		# Camera perspective is ALREADY baked for each heading:
		# never rotate 2D atlas frames or the sails become inaccurate.
		var heading_index: int=_classic_frame_for_actor(actor)
		var frame_width: float=float(atlas.get_width())/float(CLASSIC_ATLAS_COLUMNS)
		var frame_height: float=float(atlas.get_height())
		var side: float=length*1.38
		var target: Rect2=Rect2(point-Vector2(side,side)*.5,Vector2(side,side))
		var source: Rect2=Rect2(float(heading_index)*frame_width,0.0,frame_width,frame_height)
		draw_texture_rect_region(atlas,target,source)
		return
	# Editor/offline fallback only. Production browser CI rejects any missing
	# baked atlas; it never substitutes hand-drawn hulls for the actual GLBs.
	var art: Texture2D=_classic_ship_texture(actor)
	if art==null:return
	var h: float=length*.667
	var classic_angle: float=float({1:-PI*.25,7:-PI*.75,5:PI*.75,3:PI*.25}.get(_classic_frame_for_actor(actor),heading.angle()))
	draw_set_transform(point,classic_angle,Vector2.ONE)
	draw_texture_rect(art,Rect2(Vector2(-length*.5,-h*.5),Vector2(length,h)),false)
	draw_set_transform(Vector2.ZERO)

func _plate_pixels() -> float:
	var minimum: float=1.15 if browser_classic else 1.0
	return clampf(get_viewport_rect().size.y/720.0,minimum,1.45)

func _plate_scale() -> float:
	if gallery_page>=0 or camera==null:return 1.0
	return _plate_pixels()/maxf(camera.zoom.x,0.05)

## Use the same effective font pixels as _label(), including high-DPI zoom.
## Otherwise the rank emblem can overlap the measured player name.
func _plate_text_width(value: String,size: int) -> float:
	# The native plate overlay actually renders at _plate_pixels(), which is
	# capped at 1.45. Using the old 1.7 factor for layout made captions and
	# rank emblems drift apart at high resolution.
	var grow: float=1.0 if gallery_page>=0 or camera==null else _plate_pixels()
	var actual: int=maxi(size,roundi(float(size)*grow))
	var cache_key: String="%d|%s" % [actual,value]
	if plate_text_width_cache.has(cache_key):return float(plate_text_width_cache[cache_key])
	var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x
	if plate_text_width_cache.size()>255:plate_text_width_cache.clear()
	plate_text_width_cache[cache_key]=width
	return width

func _plate_identity(actor: Dictionary) -> String:
	if int(actor.id)==0:return "ID: "+sim.captain_id
	var uid:=str(actor.get("player_uid","")).strip_edges()
	return "ID: "+uid.left(20) if not uid.is_empty() else ""

func _plate_title(actor: Dictionary) -> String:
	var title=str(sim.captain_name) if int(actor.id)==0 else str(actor.name)
	var title_size=16 if int(actor.id)==0 else 14
	if int(actor.id)==0:
		if not sim.guild.is_empty():title="[%s] " % sim.guild.tag+title
		if sim.staff.shows_badge():title="[%s] " % sim.staff.badge()+title
	elif actor.get("kind","")=="tower":title="[%s] " % sim.tower_tag()+title
	# The captain's full ship design is important: never abbreviate it to
	# TEST 2 · G… or TEST · Sc… even when guild/staff badges are present.
	# NPC names still observe their compact, separate label budget.
	if int(actor.id)==0:return title
	var shortened=false
	while _plate_text_width(title+("…" if shortened else ""),title_size)>210*_plate_pixels() and title.length()>1:
		title=title.left(title.length()-1);shortened=true
	return title+"…" if shortened else title

func _plate_title_size(actor: Dictionary) -> int:
	if int(actor.id)!=0:return 14
	var result:=16
	var title: String=_plate_title(actor)
	# Full name has priority, but long guild/staff prefixes should not
	# dominate the combat view on narrow phone screens.
	var limit: float=minf(430.0*_plate_pixels(),get_viewport_rect().size.x*0.84)
	while result>12 and _plate_text_width(title,result)>limit:
		result-=1
	return result

func _plate_has_rank(actor: Dictionary) -> bool:
	# An NPC rank/elite tier is NOT a player's pirate rank.
	return int(actor.id)==0 or bool(actor.get("is_player",false))

func _actor_screen_bounds(actor: Dictionary) -> Rect2:
	var length: float=_actor_visual_length(actor)
	var point: Vector2=_visual_actor_pos(actor)
	var transform=get_canvas_transform()
	if actor.get("kind","")=="tower":return transform*Rect2(point-Vector2(38,76),Vector2(76,82))
	if actor.get("kind","")=="monster":return transform*Rect2(point-Vector2(80,85),Vector2(160,105))
	return transform*Rect2(point-Vector2(length*0.42,length*0.36),Vector2(length*0.84,length*0.72))

func _plate_stable_hull_drop(actor: Dictionary) -> float:
	if str(actor.get("kind",""))=="tower":return 6.0
	if str(actor.get("kind",""))=="monster":return 72.0
	return _actor_visual_length(actor)*0.34

## The screen offset is constant for each design, independent of heading and
## camera motion. Nearby ships never influence the captain's position.
func _plate_screen_anchor(actor: Dictionary) -> Vector2:
	var pixels=_plate_pixels()
	var point: Vector2=get_canvas_transform()*_visual_actor_pos(actor)
	var player=int(actor.id)==0
	if browser_classic:
		var zoom: float=absf(get_canvas_transform().y.y)
		var entry: Dictionary=classic_geometry.get(_classic_atlas_key(actor),{})
		if not entry.is_empty() and str(actor.get("kind","ship"))=="ship":
			var bottom: float=float(entry.stable_bottom)*_actor_visual_length(actor)/float(entry.reference_extent)
			return Vector2(point.x,point.y+bottom*zoom+CLASSIC_LABEL_CLEARANCE_PX*pixels)
		if str(actor.get("kind",""))=="monster":
			# The monster atlas is drawn around a 68% waterline pivot, not
			# the old 72-world-unit 3D hull envelope used for every monster.
			var key: String=str(actor.get("monster_key",""))
			var bottom: float=210.0*beast.get_height()/float(CONTENT.MONSTER_ROWS)/(beast.get_width()/float(CONTENT.MONSTER_COLUMNS))*.32
			if expansion_art.has(key):
				var tex: Texture2D=expansion_art[key]
				bottom=tex.get_height()*227.5/maxf(tex.get_width(),tex.get_height())*.5+2.0
			bottom=float(classic_monster_bottoms.get(key if expansion_art.has(key) else "tiamat",bottom))
			return Vector2(point.x,point.y+bottom*zoom+21.0*pixels)
	# The player 3D plate follows a constant hull envelope. Its position
	# is independent of yaw while still tracking camera zoom every frame.
	if (player or bool(actor.get("remote_player",false))) and mesh_layer!=null and mesh_layer.can_render_actor(actor):
		var drop: float=mesh_layer.stable_player_plate_drop(actor,camera.zoom.y,pixels)
		return Vector2(point.x,point.y+drop)
	var minimum=point.y+(CAPTAIN_PLATE_OFFSET if player else OTHER_PLATE_OFFSET)*pixels
	var clearance=(CAPTAIN_HULL_CLEARANCE if player else NPC_HULL_CLEARANCE)*pixels
	var stable_bottom=point.y+_plate_stable_hull_drop(actor)*absf(get_canvas_transform().y.y)
	return Vector2(point.x,maxf(minimum,stable_bottom+clearance))

## Every caption is centered on its OWN sprite. Never move a nameplate to
## another screen position to avoid neighboring names: the old candidate
## rectangles moved entire NPC labels 100–300 pixels from their ships.
## In tight packs names may touch; target/captain draw last and remain legible.
func _nameplate_layout(fleet: Array[Dictionary]) -> Dictionary:
	var placed: Dictionary={}
	var pixels=_plate_pixels()
	for actor: Dictionary in fleet:
		if int(actor.hp)<=0:continue
		var point: Vector2=get_canvas_transform()*_visual_actor_pos(actor)
		if not get_viewport_rect().grow(180*pixels).has_point(point):continue
		var player=int(actor.id)==0
		var width=maxf((188.0 if player else 154.0)*pixels,
			_plate_text_width(_plate_title(actor),_plate_title_size(actor))+58.0*pixels)
		var anchor=_plate_screen_anchor(actor)
		placed[int(actor.id)]=Rect2(anchor-Vector2(width*.5,17*pixels),Vector2(width,(116 if player else 56)*pixels))
	return placed

## One layout snapshot per *process frame* directly after Camera2D is scrolled.
## Never publish it asynchronously from the map's CanvasItem._draw() callback.
func _sync_plate_overlay() -> void:
	if plate_overlay==null or camera==null or gallery_page>=0:return
	var screen=get_viewport_rect().size
	var view=Rect2(camera.position-screen/camera.zoom*.5,screen/camera.zoom).grow(350)
	var fleet: Array[Dictionary]=[sim.player]
	for npc: Dictionary in sim.npcs:
		if int(npc.hp)>0 and view.has_point(_visual_actor_pos(npc)):fleet.append(npc)
	for other: Dictionary in online_players:
		if view.has_point(other.pos):fleet.append(other)
	plate_fleet=fleet
	# Projection must use THIS frame's ship transforms before laying out labels.
	if mesh_layer!=null:mesh_layer.sync_fleet(fleet,camera,get_viewport_rect().size)
	plate_rects=_nameplate_layout(fleet)
	plate_overlay.queue_redraw()

## Kept as a simple explicit regression hook, not called from the map draw.
func _draw_nameplates(fleet: Array[Dictionary]) -> void:
	plate_fleet=fleet.duplicate()
	plate_rects=_nameplate_layout(fleet)
	if plate_overlay!=null:plate_overlay.queue_redraw()

## Readable, anchored name/HP/shield block; ten deck slots follow directly below.
func _nameplate(actor: Dictionary,anchor: Vector2) -> void:
	var player=int(actor.id)==0
	var tower=actor.get("kind","")=="tower"
	var monster=actor.get("kind","")=="monster"
	var elite=bool(actor.get("elite",false))
	var hostile=not player and (bool(actor.get("aggressive",false)) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) or (tower and not sim.tower_friendly()))
	if tower:hostile=not sim.tower_friendly()
	var color=Color("e8d0a1") if elite else Color("dce8e4")
	if player:color=sim.staff.color() if sim.staff.shows_badge() else (Color("d9f0e5") if int(actor.get("skin",0))==0 else _ship_design_accent(int(actor.get("skin",0))).lightened(.17))
	elif hostile:color=Color("eab8a7")
	elif monster:color=Color("c6b9d6")
	var title=_plate_title(actor)
	var title_size=_plate_title_size(actor)
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
	if sim.target==int(actor.id):_draw_ship_selection_ring(actor,point+Vector2(0,3))
	var tex: Texture2D=TOWER_TEXTURES.get(str(actor.tower))
	if tex!=null:
		var dims=tex.get_size()*(88.0+float(actor.get("tower_level",1))*7.0)/maxf(tex.get_width(),tex.get_height())
		draw_texture_rect(tex,Rect2(point-dims*Vector2(0.5,0.9),dims),false)
	# Reuse the tower art as a rigid base, with independent wind and gun VFX.
	if ship_animations_enabled:
		var top: Vector2=point+Vector2(-19,-70-float(actor.get("tower_level",1))*3)
		var tint: Color=Color("d7ae57") if sim.tower_friendly() else Color("9f3931")
		draw_line(top,top+Vector2(0,-21),Color("66554a"),1.6,true)
		var flutter: float=sin(elapsed*4.0+float(actor.id)*.8)*2.4
		draw_colored_polygon(PackedVector2Array([top+Vector2(0,-21),top+Vector2(17,-19+flutter),top+Vector2(14,-11+flutter*.5),top+Vector2(0,-12)]),tint)
		var glow: float=.65+.25*sin(elapsed*6.2+float(actor.id))
		draw_circle(point+Vector2(-10,-21),2.0,Color(1,.67,.23,glow))
	var shot_age: float=float(actor.rate)-float(actor.reload)
	if str(actor.get("state",""))=="attack" and shot_age>=0.0 and shot_age<.85 and bool(vfx_flags.get("muzzle",true)) and bool(vfx_flags.get("enabled",true)):
		var mouth: Vector2=point-Vector2(0,56)
		if shot_age<.16:draw_circle(mouth,8.0*(1.0-shot_age/.16),Color(1,.79,.37,.8))
		for puff in 3:
			var drift: Vector2=Vector2(shot_age*17+float(puff)*4,-shot_age*26-float(puff)*3)
			draw_circle(mouth+drift,3.0+shot_age*8,Color(.54,.57,.57,(1.0-shot_age/.85)*.24))

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

# Legacy direction atlases and multi-design galleries were deleted.

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
	var b: ProgressBar=preload("res://living_meter.gd").new()
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

func _ensure_mesh_layer(layer: CanvasLayer=null) -> void:
	if mesh_layer!=null:return
	if layer==null:layer=ui.get_parent() as CanvasLayer
	mesh_layer=load(MESH_SHIPS_PATH).new()
	mesh_layer.name="Real3DNpcFleet";mesh_layer.host=self
	layer.add_child(mesh_layer);layer.move_child(mesh_layer,0)
	mesh_layer.set_render_mode(render_mode)
	render_mode=mesh_layer.mode

func _classic_fleet_ready() -> bool:
	return classic_atlases.size()==23 and classic_geometry.size()==23

func _build_ui() -> void:
	var layer =CanvasLayer.new()
	add_child(layer)
	if browser_classic:render_mode="classic"
	else:_ensure_mesh_layer(layer)
	# Screen-space captain/NPC readouts, independent of all Camera2D zoom/pan.
	plate_overlay=PLATE_OVERLAY.new()
	plate_overlay.host=self
	plate_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plate_overlay.name="ShipPlateScreenSpace"
	layer.add_child(plate_overlay)
	ui=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	layer.add_child(ui)
	feedback_overlay=preload("res://feedback_overlay.gd").new();feedback_overlay.host=self;layer.add_child(feedback_overlay)
	ruler=RULER.new();ruler.world_size=sim.WORLD;ui.add_child(ruler)
	chrome=_panel(ui)
	for name in ["gold_coins","kills_skull"]:
		var icon=_portrait(chrome);icon.texture=painted[name];wallet_icons.append(icon)
	currency_wallet=Control.new();currency_wallet.name="ThreeCurrencyWallet";chrome.add_child(currency_wallet)
	wallet_icons[0].reparent(currency_wallet)
	gold_label=_text(currency_wallet,"",12,Color("ffe2a0"))
	pearl_label=_text(currency_wallet,"",12,Color("e9edf5"))
	crystal_label=_text(currency_wallet,"",12,Color("cfb6ff"))
	pearl_icon=_portrait(currency_wallet);pearl_icon.texture=preload("res://assets/ui/icons/pearl.svg")
	crystal_icon=_portrait(currency_wallet);crystal_icon.texture=preload("res://assets/ui/icons/crystal.svg")
	for title: String in ["GOLD","PERLEN","KRISTALLE"]:currency_titles.append(_text(currency_wallet,title,8,Color("c4b893")))
	for amount: Label in [gold_label,pearl_label,crystal_label]:amount.clip_text=true
	profile_button=_button(chrome,"",func():_open_modal("Profil"))
	profile_button.name="PirateProfileButton";profile_button.clip_contents=true
	profile_avatar=_portrait(profile_button);profile_avatar.texture=preload("res://assets/ui/icons/pirate_profile.svg")
	profile_name=_text(profile_button,"",12,Color("f4dfb5"));profile_name.clip_text=true
	profile_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	profile_level=_text(profile_button,"",8,Color("9fc5ce"));profile_level.clip_text=true
	kills_label=_text(chrome,"",12,Color("eadfc6"))
	for label in [gold_label,kills_label]:label.clip_text=true;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	# Sea HUD is a combat overlay, not a second inventory dashboard.
	# Kill count lives in the profile/logbook; only gold stays in the header.
	kills_label.hide()
	wallet_icons[1].hide()
	var nav_items=[["Schiff","nav_ship","Schiff"],["Markt","gold_coins","Markt"],["Decks","tide_deck","Decks"],["Karten","nav_charts","Seekarten"],["Menü","nav_menu","Menü"]]
	# Five primary actions only. Everything else lives in a real grouped
	# menu instead of eleven scrolling buttons covering the top of the sea.
	nav_scroll=ScrollContainer.new()
	nav_scroll.name="SeaHeaderNavigation"
	nav_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	nav_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	nav_scroll.scroll_deadzone=12
	nav_scroll.follow_focus=true
	chrome.add_child(nav_scroll)
	nav_strip=HBoxContainer.new()
	nav_strip.name="SeaHeaderNavigationItems"
	nav_strip.add_theme_constant_override("separation",3)
	nav_scroll.add_child(nav_strip)
	for item in nav_items:
		var kind: String=item[2]
		var button=_orb(nav_strip,str(item[0]),painted[item[1]],func():_open_modal(kind),str(item[0]),true)
		button.tooltip_text=kind
		button.set_meta("modal",kind);nav_buttons.append(button)
	for tag in ["EXP","HP","SCHILD"]:
		var label=_text(chrome,tag,9,Color("ecd29a"));label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;meter_tags.append(label)
	captain_meters=Control.new();captain_meters.name="CenteredCaptainMeters"
	captain_meters.mouse_filter=Control.MOUSE_FILTER_IGNORE;chrome.add_child(captain_meters)
	player_xp=_bar(captain_meters)
	player_xp.set("damage_feedback",false)
	var xp_style: StyleBoxFlat=player_xp.get_theme_stylebox("fill").duplicate();xp_style.bg_color=Color("c79a3f");player_xp.add_theme_stylebox_override("fill",xp_style)
	player_hp=_bar(captain_meters)
	player_shield=_bar(captain_meters)
	var shield_style: StyleBoxFlat=player_shield.get_theme_stylebox("fill").duplicate();shield_style.bg_color=Color("2f7fd0");player_shield.add_theme_stylebox_override("fill",shield_style)
	player_bp=_bar(captain_meters)
	player_bp.set("damage_feedback",false)
	var bp_style: StyleBoxFlat=player_bp.get_theme_stylebox("fill").duplicate();bp_style.bg_color=Color("a470d8");player_bp.add_theme_stylebox_override("fill",bp_style)
	var bp_background: StyleBoxFlat=player_bp.get_theme_stylebox("background").duplicate();bp_background.border_color=Color("765296");player_bp.add_theme_stylebox_override("background",bp_background)
	bp_numbers=_text(player_bp,"",10,Color.WHITE)
	xp_numbers=_text(player_xp,"",10,Color.WHITE)
	player_numbers=_text(player_hp,"",10,Color.WHITE)
	shield_numbers=_text(player_shield,"",10,Color.WHITE)
	for readout: Label in [xp_numbers,player_numbers,shield_numbers,bp_numbers]:
		readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;readout.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;readout.clip_text=true
		readout.add_theme_color_override("font_outline_color",Color("06121a"));readout.add_theme_constant_override("outline_size",3)
	target_panel=_panel(ui)
	target_clear=_button(target_panel,"×",_cancel_target,"danger")
	target_clear.name="TargetClearButton"
	target_clear.tooltip_text="Anvisieren abbrechen · × oder ESC"
	target_clear.focus_mode=Control.FOCUS_NONE
	target_clear.add_theme_font_size_override("font_size",18)
	target_portrait=_portrait(target_panel)
	target_panel.clip_contents=false
	target_name=_text(target_panel,"",14,Color("ffdf9d"));target_name.clip_text=true
	target_hp=_bar(target_panel)
	target_health_skin=target_hp.get_theme_stylebox("fill").duplicate();target_hp.add_theme_stylebox_override("fill",target_health_skin)
	target_shield=_bar(target_panel)
	target_shield.name="TargetShield"
	var target_shield_skin: StyleBoxFlat=target_shield.get_theme_stylebox("fill").duplicate()
	target_shield_skin.bg_color=Color("358fd0")
	target_shield.add_theme_stylebox_override("fill",target_shield_skin)
	target_shield.hide()
	target_numbers=_text(target_panel,"",10)
	target_numbers.clip_text=true
	target_numbers.add_theme_constant_override("line_spacing",0)
	target_numbers.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	# Topmost and touch-owning: never let portraits, text or bars cover cancel.
	target_clear.move_to_front()
	target_clear.z_index=3
	target_clear.mouse_filter=Control.MOUSE_FILTER_STOP
	quest_panel=_panel(ui)
	quest_icon=_portrait(quest_panel);quest_icon.texture=painted.nav_quests
	quest_text=_text(quest_panel,"",11);quest_text.clip_text=true;quest_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	quest_open=Button.new();quest_open.focus_mode=Control.FOCUS_NONE;quest_open.tooltip_text="Logbuch öffnen"
	for state in ["normal","hover","pressed","hover_pressed","focus"]:quest_open.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	quest_open.pressed.connect(func():_switch_tab("Logbuch","VERTRÄGE") if sim.current_quest().is_empty() else _open_modal("Logbuch"));quest_panel.add_child(quest_open)
	quest_claim=_button(quest_panel,"ABHOLEN",func():sim.claim_quest();_save_progress();_refresh_ui());quest_claim.add_theme_font_size_override("font_size",10)
	chart_mini=MINI.new();chart_mini.simulation=sim
	chart_mini.course_requested.connect(func(point):_chart_course(point))
	ui.add_child(chart_mini)
	zoom_out=_orb(ui,"Weiter zoomen",hud_icons.minus,func():_zoom(1.0/1.15))
	zoom_in=_orb(ui,"Näher zoomen",hud_icons.plus,func():_zoom(1.15))
	center_button=_orb(ui,"Kamera zum Schiff",hud_icons.focus,_recenter_camera)
	settings_button=_orb(ui,"Anzeige & Steuerung",hud_icons.gear,func():_open_modal("Anzeige"));settings_button.name="SettingsButton"
	# Directly reachable beside the minimap: no hidden submenu or scrolling.
	render_toggle=_button(ui,"GRAFIK: 2,5D / 3D",_cycle_render_mode,"normal")
	render_toggle.name="GraphicsModeToggle"
	render_toggle.tooltip_text="Browser: klassisches 2D ohne 3D; App: echtes 2,5D/3D"
	render_toggle.add_theme_font_size_override("font_size",10)
	if OS.has_feature("web"):render_toggle.hide()
	attack=_orb(ui,"Feuer ein/aus",extra_icons.cannon_action,_toggle_fire,"FEUER");attack.name="FireButton"
	attack.set("hero",true)
	repair=_orb(ui,"Schiff reparieren",extra_icons.upgrade_hull,func():sim.toggle_repair();_refresh_ui(),"REP");repair.name="RepairButton"
	for key: String in CONTENT.SUPPLY_KEYS:
		var supply=key
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var button=_orb(ui,"%s · %s" % [config.name,config.effect],_supply_icon(key),func():_use_supply(supply),str(config.short))
		button.name="Supply_"+key;supply_buttons[key]=button;button.hide()
	supply_selector=_orb(ui,"Verbrauchsgegenstände",painted.supply_repair,func():
		if modal.visible and modal_kind=="Verbrauch":_close_ammo()
		else:_open_modal("Verbrauch"),"ITEMS");supply_selector.name="SupplySelector"
	target_cycle=_orb(ui,"Nächstes sichtbares Ziel · Tab",painted.spyglass,_cycle_target,"ZIEL")
	ammo_selector=_orb(ui,"Munition auswählen",_ammo_texture(sim.ammo_mode),_toggle_ammo,"MUNITION");ammo_selector.name="AmmoSelector"
	loadout_button=_orb(ui,"Bewaffnung",extra_icons.cannon_0,func():_open_modal("Bewaffnung"),"WAFFEN")
	camera_pad=CAMERA_PAD.new();ui.add_child(camera_pad)
	interact=_button(ui,"",_interact);interact.name="InteractButton"
	quick_bar=preload("res://quick_bar.gd").new();quick_bar.host=self;quick_bar.name="QuickBar"
	quick_bar.used.connect(func(slot: int):_use_supply(str(quick_pages[quick_page][slot])))
	quick_bar.page_picked.connect(func(page: int):quick_page=page;_persist_display_preferences();quick_bar.refresh())
	quick_bar.configure.connect(func():_open_modal("Schnellzugriff"));ui.add_child(quick_bar)
	buff_bar=Control.new();buff_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;buff_bar.name="BuffBar"
	buff_bar.draw.connect(_draw_buffs);ui.add_child(buff_bar)
	status=_text(ui,"",13,Color("e2ecee"));status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	status.clip_text=true
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var toast=StyleBoxFlat.new();toast.bg_color=Color(.01,.04,.06,.64);toast.set_corner_radius_all(11);toast.border_color=Color(.79,.64,.37,.35);toast.set_border_width_all(1)
	toast.content_margin_left=12;toast.content_margin_right=12
	status.add_theme_stylebox_override("normal",toast)
	modal_backdrop=ColorRect.new()
	modal_backdrop.color=Color(0.002,0.009,0.018,0.56)
	modal_backdrop.z_index=19
	modal_backdrop.visible=false
	modal_backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
	ui.add_child(modal_backdrop)
	modal_backdrop.gui_input.connect(func(event):
		if not modal_kind in ["Munition","Verbrauch"]:return
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
	modal_close=_button(modal,"×",_close_modal,"close")
	modal_close.name="ModalCloseButton"
	modal_close.add_theme_font_size_override("font_size",26);modal_close.tooltip_text="Schließen";modal_close.clip_text=false
	modal_back=_button(modal,"‹ ZURÜCK",_back_modal);modal_back.name="BackButton";modal_back.add_theme_font_size_override("font_size",12)
	# Scrolling category tabs avoid tiny/unreadable buttons on portrait phones.
	modal_tabs_scroll=ScrollContainer.new()
	modal_tabs_scroll.name="ModalCategoryScroller"
	modal_tabs_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	modal_tabs_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	modal_tabs_scroll.follow_focus=true
	SKIN.scrollbar(modal_tabs_scroll.get_h_scroll_bar())
	modal_tabs_scroll.visible=false
	modal.add_child(modal_tabs_scroll)
	modal_tabs=HBoxContainer.new()
	modal_tabs.add_theme_constant_override("separation",6)
	modal_tabs.visible=false
	modal_tabs_scroll.add_child(modal_tabs)
	modal_scroll=TOUCH_SCROLL.new()
	modal.add_child(modal_scroll)
	modal_scroll.minimum_size_changed.connect(_fit_modal_scroll)
	modal_body=VBoxContainer.new()
	modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation",10)
	modal_scroll.add_child(modal_body)
	scroll_hint=Control.new();scroll_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scroll_hint.draw.connect(_draw_scroll_hint);modal.add_child(scroll_hint)
	loading=LOADING.new();loading.art=preload("res://assets/world_v2/frontier_splash.png");loading.wheel=painted.helm_wheel
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

# Reusable measurement helper; the ammunition picker is separately anchored.
# A separate touch-first layout is selected by input hardware or a narrow
# viewport. Desktop gets a mouse/keyboard rail, not an enlarged mobile HUD.
func _is_mobile_hud(viewport: Vector2,touch_available: bool=false) -> bool:
	return touch_available or viewport.x<1024.0

func _menu_layout_fractions(viewport: Vector2,layout: String) -> Vector2:
	var portrait: bool=viewport.y>viewport.x*1.13
	match layout:
		"compact":return Vector2(.88,.68) if portrait else Vector2(.72,.74)
		"large":return Vector2(.97,.89) if portrait else Vector2(.90,.91)
		_:return Vector2(.94,.80) if portrait else Vector2(.82,.84)

func _layout() -> void:
	if ui==null:return
	var viewport_size=get_viewport_rect().size
	# This overlay deliberately does not inherit the HUD's ui.scale or Camera2D.
	if mesh_layer!=null:mesh_layer.resize_view(viewport_size)
	if plate_overlay!=null:
		plate_overlay.position=Vector2.ZERO
		plate_overlay.scale=Vector2.ONE
		plate_overlay.size=viewport_size
	# Scale only the HUD. Ocean, camera, world input and simulation keep viewport coordinates.
	var base=maxf(viewport_size.y/600.0,1.0)
	var requested=base*[0.86,1.0,1.14][hud_size]
	if browser_classic:requested*=1.15
	hud_scale=clampf(requested,0.86,minf(viewport_size.x/720.0,viewport_size.y/390.0))
	ui.scale=Vector2.ONE*hud_scale
	var s=viewport_size/hud_scale
	ui.size=s
	var mobile_hud: bool=_is_mobile_hud(viewport_size,OS.has_feature("mobile") or DisplayServer.is_touchscreen_available())
	var compact=viewport_size.y<560 or viewport_size.x<1000
	if compact and elapsed<0.1:
		desired_zoom=0.78
		camera.zoom=Vector2.ONE*desired_zoom
	water.size=viewport_size
	_place(ruler,0,0,s.x,s.y)
	# One compact row: profile | health | centered menus | progress | wallet.
	var header: float=54.0 if compact else 60.0
	_place(chrome,0,0,s.x,header)
	var nav_y: float=4.0
	var nav_h: float=header-8.0
	var gap: float=6.0
	var utility_w: float=clampf(s.x*.13,100.0,132.0)
	var nav_span: float=clampf(s.x*.33,252.0,400.0)
	var meter_w: float=minf(208.0,(s.x-nav_span-2.0*utility_w-4.0*gap-16.0)*.5)
	var group_w: float=nav_span+2.0*(meter_w+gap)
	var group_x: float=(s.x-group_w)*.5
	_place(captain_meters,group_x,nav_y,group_w,nav_h)
	_place(profile_button,group_x-gap-utility_w,nav_y,utility_w,nav_h)
	_place(profile_avatar,3,(nav_h-32.0)*.5,32,32)
	_place(profile_name,40,(nav_h-32.0)*.5,utility_w-45,19)
	_place(profile_level,40,(nav_h-32.0)*.5+19,utility_w-45,13)
	profile_name.add_theme_font_size_override("font_size",11)
	_place(currency_wallet,group_x+group_w+gap,nav_y,utility_w,nav_h)
	var amounts: Array[Label]=[gold_label,pearl_label,crystal_label]
	var money_icons: Array[TextureRect]=[wallet_icons[0],pearl_icon,crystal_icon]
	var money_h: float=nav_h/3.0
	for i in 3:
		_place(money_icons[i],0,float(i)*money_h,16,money_h)
		_place(amounts[i],22,float(i)*money_h,utility_w-24,money_h)
		amounts[i].add_theme_font_size_override("font_size",11)
		currency_titles[i].hide()
		money_icons[i].tooltip_text=["Gold","Perlen","Kristalle"][i]
	_place(wallet_icons[1],0,0,0,0)
	_place(kills_label,0,0,0,0)
	var meter_h: float=(nav_h-3.0)*.5
	var bars: Array[ProgressBar]=[player_hp,player_shield,player_xp,player_bp]
	var readouts: Array[Label]=[player_numbers,shield_numbers,xp_numbers,bp_numbers]
	for i in bars.size():
		bars[i].show();readouts[i].show()
		var x: float=0.0 if i<2 else meter_w+nav_span+2.0*gap
		_place(bars[i],x,float(i%2)*(meter_h+3.0),meter_w,meter_h)
		_place(readouts[i],0,0,meter_w,meter_h)
		readouts[i].add_theme_font_size_override("font_size",10 if meter_w<160.0 else 11)
	for tag: Label in meter_tags:tag.hide()
	var pill_w: float=minf(220.0,s.x*.3)
	_place(staff_pill,(s.x-pill_w)*.5,header+4,pill_w,22)
	_place(nav_scroll,(s.x-nav_span)*.5,nav_y,nav_span,nav_h)
	var nav_button_w: float=maxf(48.0,(nav_span-12.0)/float(nav_buttons.size()))
	for nav: Button in nav_buttons:
		nav.custom_minimum_size=Vector2(nav_button_w,nav_h-2.0)
		nav.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
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
	var card_h=72.0 if compact else 78.0
	# Enemy HP/shield and the close button need their own readable space.
	# Do not expand the quest panel or cover the central sea/action corner.
	var target_w: float=minf(256.0 if compact else 308.0,s.x*.42)
	_place(target_panel,left,target_y,target_w,card_h)
	_place(target_portrait,6,6,card_h-12,card_h-12)
	var tx=card_h
	_place(target_clear,target_w-46,4,40,32)
	_place(target_name,tx,3,target_w-tx-52,18)
	_place(target_hp,tx,22,target_w-tx-51,8)
	_place(target_shield,tx,32,target_w-tx-51,6)
	var target_stats_y: float=41.0 if target_shield.visible else 31.0
	_place(target_numbers,tx,target_stats_y,target_w-tx-51,card_h-target_stats_y-2)
	_place(interact,left,target_y+card_h+6,column,34)
	_place(buff_bar,left,target_y+card_h+46,column,26)
	# Chart with corner controls, as on classic sea-chart clients.
	var mw=136.0 if compact else 190.0
	var map_bottom: float=(46.0 if compact else 50.0)+22.0+(118.0 if compact else 160.0)
	var map_top: float=header+12.0
	var mh: float=maxf(94.0,map_bottom-map_top)
	var mx=s.x-mw-20
	var my=map_top
	_place(chart_mini,mx,my,mw,mh)
	var z=32.0 if compact else 36.0
	_place(zoom_out,mx-z*.3,my-z*.3,z,z)
	_place(zoom_in,mx+mw-z*.7,my-z*.3,z,z)
	_place(center_button,mx-z*.3,my+mh-z*.7,z,z)
	_place(settings_button,mx+mw-z*.7,my+mh-z*.7,z,z)
	_place(render_toggle,mx-122.0,my+mh-32.0,100.0,30.0)
	var pad=92.0 if compact else 104.0
	_place(camera_pad,12,s.y-pad-12,pad,pad)
	camera_pad.visible=camera_pad_visible
	ruler.top=header
	ruler.left_bottom=(s.y-pad-20) if camera_pad_visible else s.y-12
	# Combat corner: cannon bottom-right, quick slots in an L around it, utilities continue the bottom row.
	var fire=112.0 if compact else 140.0
	var orb=50.0 if compact else 60.0
	gap=8.0
	var fx=s.x-fire-10
	var fy=s.y-fire-10
	_place(attack,fx,fy,fire,fire)
	_place(ammo_selector,fx-orb-gap,s.y-orb-10,orb,orb)
	_place(repair,fx+fire*.5+gap*.5,fy-orb-gap,orb,orb)
	# Supplies retain their own functions; every ammunition type uses one selector.
	_place(supply_selector,fx-orb-gap,fy-orb-gap,orb,orb)
	for item: Button in supply_buttons.values():item.hide()
	# One shared, persistent set of three configurable bars, two layouts.
	# On touch devices the slots remain beside the cannon, with 44px tabs.
	# On desktop they form a separate mouse/keyboard rail along bottom-left.
	quick_bar.mobile_first=mobile_hud
	# Keep all three page tabs at least 44px wide as well as tall in
	# compact landscape; grow the rail to the left, away from combat orbs.
	var touch_extra: float=20.0 if mobile_hud else 0.0
	var quick_w: float=orb*3.0+gap*2.0+touch_extra
	var quick_h: float=orb+quick_bar.tab_height()+4.0
	var quick_x: float=fx-4.0*(orb+gap)-touch_extra if mobile_hud else left+column-20.0
	var quick_y: float=s.y-orb-10.0-quick_h-8.0 if mobile_hud else s.y-quick_h-10.0
	_place(quick_bar,quick_x,quick_y,quick_w,quick_h)
	quick_bar._layout()
	var hot: Array[Button]=[target_cycle,loadout_button]
	for i in hot.size():_place(hot[hot.size()-1-i],ammo_selector.position.x-(i+1)*(orb+gap),s.y-orb-10,orb,orb)
	var toast_w=maxf(60.0,minf(380.0,s.x-2.0*(left+column+12)))
	_place(status,(s.x-toast_w)*.5,header+3+(26.0 if staff_pill.visible else 0.0),toast_w,20 if compact else 24)
	status.set_meta("room",toast_w)
	var menu_size=viewport_size
	var grow=clampf(viewport_size.y/720.0,1.0,1.7)
	modal.scale=Vector2.ONE*grow
	# Leave a visible border of sea around the menu. Relative dimensions keep
	# 720p phones, 1080p landscape and portrait devices proportionate.
	var menu_ratios: Vector2=_menu_layout_fractions(menu_size,menu_layout)
	var visual_w: float=minf(menu_size.x-24.0,menu_size.x*menu_ratios.x)
	var visual_h: float=minf(menu_size.y-22.0,menu_size.y*menu_ratios.y)
	var width=visual_w/grow
	var height=visual_h/grow
	_place(modal_backdrop,0,0,s.x,s.y)
	if modal_kind in ["Munition","Verbrauch"]:
		var button_rect=ammo_selector.get_global_rect()
		# M3107: 30% wider picker for 96px atlas artwork and large touch rows.
		# Always remain above the combat orb and below the top HUD on small phones.
		visual_w=minf(520.0*grow,menu_size.x-24.0)
		var bottom=button_rect.position.y-10.0
		var top_limit=chrome.get_global_rect().end.y+10.0
		visual_h=minf(650.0*grow,maxf(160.0,bottom-top_limit))
		width=visual_w/grow;height=visual_h/grow
		_place(modal,clampf(button_rect.end.x-visual_w,12.0,menu_size.x-visual_w-12.0),bottom-visual_h,width,height)
	else:_place(modal,(menu_size.x-visual_w)*.5,(menu_size.y-visual_h)*.5,width,height)
	var head=42.0 if modal_kind in ["Munition","Verbrauch"] else (46.0 if height<420 else 52.0)
	modal.header=head
	var title_w=width-150 if modal_kind in ["Munition","Verbrauch"] else clampf(font.get_string_size(modal_title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x+70,minf(150,width-170),width-170)
	modal.ribbon=Rect2(94,3,title_w,head-6) if modal_kind in ["Munition","Verbrauch"] else Rect2((width-title_w)*.5,8,title_w,head-14)
	_place(modal_title,modal.ribbon.position.x+8,modal.ribbon.position.y,title_w-16,modal.ribbon.size.y)
	var title_font: int=18 if modal_kind in ["Munition","Verbrauch"] else 21
	while title_font>13 and font.get_string_size(modal_title.text,HORIZONTAL_ALIGNMENT_LEFT,-1,title_font).x>title_w-16:title_font-=1
	modal_title.add_theme_font_size_override("font_size",title_font)
	var close=head-12
	_place(modal_close,width-close-12,6,close,close)
	_place(modal_back,10,8,82,30)
	var inner_top=head+8
	if modal_tabs.visible:
		_place(modal_tabs_scroll,18,inner_top,width-36,62)
		inner_top+=70
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
	if render_toggle!=null:
		render_toggle.text="GRAFIK CLASSIC 2D" if browser_classic else {"hybrid":"GRAFIK 2,5D","3d":"GRAFIK 3D"}.get(render_mode,"GRAFIK 2,5D")
		render_toggle.disabled=false
		render_toggle.visible=not OS.has_feature("web")
	var today=Time.get_date_string_from_system()
	var contracts_ready: bool=sim.sea_contracts.ready_count(sim)>0
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
			"Menü":
				alert=quest_ready or contracts_ready or sim.free_flask_ready(today) or sim.rewards.daily_available() or sim.rewards.afk_gold()>0
				badge="!" if alert else ""
		nav.set("quantity",badge);nav.set("badge_alert",alert)
		nav.set("latched",modal.visible and modal_kind==kind);nav.queue_redraw()
	_wallet_feedback([int(sim.player.gold),sim.pearls,sim.crystals])
	gold_label.text=_wallet_amount(int(sim.player.gold))
	pearl_label.text=_wallet_amount(sim.pearls)
	crystal_label.text=_wallet_amount(sim.crystals)
	currency_wallet.tooltip_text="Gold: %s · Perlen: %s · Kristalle: %s" % [_thousands(int(sim.player.gold)),_thousands(sim.pearls),_thousands(sim.crystals)]
	profile_name.text=sim.captain_name
	profile_level.text="LV. %d · PROFIL" % sim.level
	profile_button.tooltip_text="Piratenprofil öffnen · %s · ID %s" % [sim.captain_name,sim.captain_id]
	kills_label.text="%s versenkt" % _thousands(sim.kills)
	player_hp.max_value=sim.player.max_hp
	player_hp.value=sim.player.hp
	player_numbers.text="HP  %s / %s" % [_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))]
	player_shield.max_value=maxf(1.0,float(sim.player.max_shield))
	player_shield.value=sim.player.shield
	shield_numbers.text="SCHILD  %s / %s" % [_thousands(int(sim.player.shield)),_thousands(int(sim.player.max_shield))]
	quick_bar.refresh()
	buff_bar.visible=sim.powder_on or sim.plates_on or sim.has_blessing() or float(sim.buffs.tide_deck)>0 or float(sim.buffs.storm_deck)>0 or float(sim.buffs.salvage_deck)>0 or sim.guild_island_held()
	buff_bar.queue_redraw()
	player_xp.max_value=maxi(1,sim.xp_required())
	player_xp.value=player_xp.max_value if sim.level>=20 else sim.xp
	xp_numbers.text="EXP  %s / %s" % [_thousands(sim.xp),_thousands(sim.xp_required())]
	player_xp.tooltip_text="Erfahrung %d / %d" % [sim.xp,sim.xp_required()]
	if sim.level>=20:
		player_xp.value=player_xp.max_value
		xp_numbers.text="EXP  MAX"
		player_xp.tooltip_text="Maximale Kapitänsstufe dieser Beta erreicht"
	var bp: Dictionary=sim.battle_point_progress()
	player_bp.min_value=bp.total-bp.current
	player_bp.max_value=bp.next
	player_bp.value=bp.total
	bp_numbers.text="BP  %s / %s" % [_thousands(bp.total),_thousands(bp.next)]
	player_bp.tooltip_text="Battle Points: %s · nächste Fortschrittsstufe bei %s BP. Nur PvP; NPCs vergeben keine Battle Points." % [_thousands(bp.total),_thousands(bp.next)]

	var selected =sim.actor(sim.target)
	target_panel.visible=not selected.is_empty() and sim.target>0 and int(selected.hp)>0
	if target_panel.visible:
		if portrait_target!=int(selected.id):
			portrait_target=int(selected.id)
			if selected.kind=="monster":
				var preview=AtlasTexture.new();preview.atlas=beast
				preview.region=Rect2(Vector2.ZERO,beast.get_size()/Vector2(CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS))
				target_portrait.texture=expansion_art.get(str(selected.get("monster_key","")),preview)
			elif selected.kind=="tower":target_portrait.texture=painted["tower_"+str(selected.tower)]
			else:target_portrait.texture=_npc_ship_texture(selected)
		target_name.text=("[%s] " % sim.tower_tag() if selected.kind=="tower" else "")+str(selected.name)
		target_hp.max_value=selected.max_hp
		target_hp.value=selected.hp
		var shield_present: bool=float(selected.get("max_shield",0))>0
		if target_shield.visible!=shield_present:
			target_shield.visible=shield_present
			_layout()
		target_shield.max_value=maxf(1.0,float(selected.get("max_shield",0)))
		target_shield.value=float(selected.get("shield",0))
		target_shield.tooltip_text="Schutzschild: %s / %s" % [_thousands(int(selected.get("shield",0))),_thousands(int(selected.get("max_shield",0)))]
		var disposition="IM KAMPF" if sim.npc_engages(selected) else ("FEINDLICH" if CONTENT.MAPS[sim.map_id].npc_hostile else "NEUTRAL")
		if selected.kind=="tower" and sim.tower_friendly():disposition="GILDENTURM"
		target_health_skin.bg_color=Color("c9573f") if bool(selected.aggressive) or bool(CONTENT.MAPS[sim.map_id].npc_hostile) else Color("cfae55")
		if selected.kind=="tower" and sim.tower_friendly():target_health_skin.bg_color=Color("61b967")
		var shield_text=" · S%s" % _thousands(int(selected.shield)) if float(selected.get("max_shield",0))>0 else ""
		var enemy_distance: int=roundi(sim.player.pos.distance_to(Vector2(selected.pos)))
		# Exact values remain available on the card; shorten repeated labels on
		# compact Android screens so the X and the health text never collide.
		if ui.size.x<1100.0:
			target_numbers.text="%s/%s%s\n%s · %d m" % [_thousands(int(selected.hp)),_thousands(int(selected.max_hp)),shield_text,disposition,enemy_distance]
		else:
			target_numbers.text="%s / %s HP%s\n%s · %d m" % [_thousands(int(selected.hp)),_thousands(int(selected.max_hp)),shield_text,disposition,enemy_distance]
		target_numbers.tooltip_text="Rumpf: %s / %s · Schutzschild: %s / %s · Distanz: %d m" % [_thousands(int(selected.hp)),_thousands(int(selected.max_hp)),_thousands(int(selected.shield)),_thousands(int(selected.get("max_shield",0))),enemy_distance]
	attack.text="STOPP" if sim.firing else "FEUER"
	attack.disabled=not target_panel.visible or int(sim.player.hp)<=0 or sim.docked
	_set_orb(attack,extra_icons.cannon_action,"",sim.firing,attack.text)
	attack.set("cooldown",float(sim.player.reload)/sim.reload_time())
	var combat_state: String=_combat_state()
	attack.set("state_label",combat_state)
	attack.set("state_color",_combat_state_color(combat_state))
	attack.tooltip_text=combat_state+" · FEUER startet, STOPP beendet den Angriff. Keine automatische Verfolgung."
	repair.disabled=sim.docked
	repair.text="STOPP" if sim.repairing else "REPARATUR"
	_set_orb(repair,extra_icons.upgrade_hull,"",sim.repairing,"STOPP" if sim.repairing else "REP")
	for key: String in CONTENT.SUPPLY_KEYS:
		var item: Button=supply_buttons[key]
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var stock=int(sim.supplies[key])
		var active=(sim.powder_on if key=="powder" else sim.plates_on) if bool(config.toggle) else false
		var wait=float(sim.cooldowns.get(key,0.0))
		_set_orb(item,_supply_icon(key),_thousands(stock),active,str(config.short))
		item.set("cooldown",wait/float(config.get("cooldown",1.0)))
		item.set("state_label","%d s" % ceili(wait) if wait>0 else ("AN" if active else ""))
		item.disabled=sim.docked or int(sim.player.hp)<=0 or (stock<=0 and not active)
	if modal.visible and modal_kind=="Verbrauch":
		for button: Button in modal_body.find_children("Use_*","Button",true,false):
			var key: String=str(button.get_meta("supply_key",""))
			var active: bool=sim.powder_on if key=="powder" else (sim.plates_on if key=="plates" else false)
			var wait: float=float(sim.cooldowns.get(key,0))
			button.text="AUSSCHALTEN" if active else ("%d s" % ceili(wait) if wait>0 else "AKTIVIEREN")
			button.disabled=sim.docked or int(sim.player.hp)<=0 or wait>0 or (int(sim.supplies.get(key,0))<=0 and not active)
	_set_orb(supply_selector,painted.supply_repair,"",modal.visible and modal_kind=="Verbrauch","ITEMS")
	ammo_selector.text="%s · %d" % [AMMO_UI[sim.ammo_mode].name,sim.player.ammo[sim.ammo_mode]]
	ammo_selector.tooltip_text="%s · %s · antippen zum Wechseln" % [AMMO_UI[sim.ammo_mode].name,AMMO_UI[sim.ammo_mode].use]
	_set_orb(ammo_selector,_ammo_texture(sim.ammo_mode),_thousands(int(sim.player.ammo[sim.ammo_mode])),modal.visible and modal_kind=="Munition","MUNITION")
	ammo_selector.set("ammo_marker",true)
	ammo_selector.set("ammo_color",COMBAT_FX.weapon_color(str(sim.AMMO_NAMES[sim.ammo_mode])))
	ammo_selector.set("state_label",["VOLL","KETTE","HARPUNE","LEUCHT","KÜRBIS","SCHNEE","EIS"][sim.ammo_mode] if sim.ammo_mode<7 else "SPEZIAL")
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
		quest_text.text=("SEEVERTRÄGE BEREIT\nIm Logbuch abholen" if contracts_ready else "KAMPAGNE ERLEDIGT\nSeeverträge im Logbuch") if quest.is_empty() else "%s · %d/%d\n%d Gold · %d EP" % [str(quest.name).to_upper(),mini(sim.quest_progress(),int(quest.goal)),quest.goal,quest.gold,quest.xp]
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
		interact.text=("AB LV. %d · %s" % [region.level,region.name]) if sim.level<int(region.level) else "ÜBERFAHRT · "+str(region.name)
	elif sim.pending_portal>=0:
		interact.text="ÜBERFAHRT ABBRECHEN"
	elif sim.can_dock():
		interact.text="IM HAFEN ANDOCKEN"
	else:
		interact.text="KURS ZUM KARTENRAND" if sim.pending_portal>=0 else "KURS ZUM HAFEN"
	if modal.visible and modal_kind=="Logbuch" and _tab("Logbuch")=="VERTRÄGE":_refresh_contract_rows()
	if modal.visible and modal_kind=="Events":_refresh_event_controls()
	if modal.visible and modal_kind=="Monster":_refresh_monster_controls()

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

func _combat_state_color(state: String) -> Color:
	if state=="BEREIT":return Color("80e3dc")
	if state.begins_with("LÄDT"):return Color("e8c980")
	if state in ["WAFFE WECHSELN","MUNITION LEER","ZU WEIT","INSEL IM WEG","VERSENKT"]:return Color("ff9b81")
	return Color("c5d3d6")

func _toggle_fire() -> void:
	if sim.target<1:return
	sim.firing=not sim.firing
	sim.repairing=false
	_refresh_ui()

func _use_supply(key: String) -> void:
	if bool(CONTENT.SUPPLIES[key].toggle):sim.toggle_supply(key)
	else:sim.use_supply(key)
	_save_progress()
	if modal.visible and modal_kind=="Verbrauch":_open_modal("Verbrauch")
	_refresh_ui()

func _toggle_ammo() -> void:
	if modal.visible and modal_kind=="Munition":_close_ammo()
	else:_open_modal("Munition")

func _close_ammo() -> void:
	_close_modal()
	_refresh_ui()

func _choose_ammo(index: int) -> void:
	sim.set_ammo(index)
	_save_progress()
	_close_ammo()

## Active effects with remaining sea time; emergency cooldowns live on their own orbs.
func _draw_buffs() -> void:
	var entries: Array=[]
	if sim.powder_on:entries.append([_supply_icon("powder"),"PULVER +40%",Color("ffb85e")])
	if sim.plates_on:entries.append([_supply_icon("plates"),"PLATTEN −35%",Color("83cfff")])
	if sim.has_blessing():entries.append([deck_icons.blessing,_clock_text(float(sim.buffs.blessing)),Color("c69bff")])
	if float(sim.buffs.tide_deck)>0:entries.append([deck_icons.tide,_clock_text(float(sim.buffs.tide_deck)),Color("5fe0d2")])
	for key: String in CONTENT.SPECIAL_DECKS:
		if float(sim.buffs[key])>0:entries.append([deck_icons[key.trim_suffix("_deck")],_clock_text(float(sim.buffs[key])),CONTENT.SPECIAL_DECKS[key].color])
	if sim.guild_island_held():entries.append([painted.nav_guild,_clock_text(sim.fortress_hold),Color("9fe7a8")])
	var x=0.0
	var h=buff_bar.size.y
	for entry: Array in entries:
		var text: String=entry[1]
		var w=h+6+font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+10
		var ink: Color=entry[2]
		var pulse=.5+.5*sin(elapsed*1.9+float(x)*.04)
		var skin=StyleBoxFlat.new();skin.bg_color=Color(0.02,0.06,0.08,.87);skin.set_corner_radius_all(int(h*.5))
		skin.border_color=ink.lightened(.13*pulse);skin.set_border_width_all(1)
		buff_bar.draw_style_box(skin,Rect2(x,0,w,h))
		buff_bar.draw_circle(Vector2(x+h*.5,h*.5),h*.38,Color(ink,.07+.06*pulse))
		buff_bar.draw_texture_rect(entry[0],Rect2(x+3,3,h-6,h-6),false)
		buff_bar.draw_line(Vector2(x+h*.95,2),Vector2(x+w-8,2),Color(ink,.12+.12*pulse),1.0,true)
		buff_bar.draw_string_outline(font,Vector2(x+h+3,h*.5+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("06121a"))
		buff_bar.draw_string(font,Vector2(x+h+3,h*.5+4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3e0b6"))
		x+=w+6
		if x>buff_bar.size.x-40:break

func _clock_text(seconds: float) -> String:
	var total=ceili(seconds)
	var hours=floori(total/3600.0)
	var minutes=floori((total%3600)/60.0)
	return "%d:%02d:%02d" % [hours,minutes,total%60] if hours>0 else "%d:%02d" % [minutes,total%60]

const MODAL_TABS := {"Logbuch":["AKTUELL","VERTRÄGE","VERLAUF"],"Spielinfo":["KAPITÄN","SCHIFF","WELT","SYSTEM"],"Decks":["SCHIFF","LAGER","SPEZIAL","KAUFEN"],"Werft":["SCHIFFE","KANONEN"],"Hafen":["DOCK","DIENSTE"],"Markt":["AUSRÜSTUNG","MUNITION","ITEMS","AUKTION"],"Kastelle":["KASTELLE","TALENTE"],"Gilde":["HEIMATBASIS","WELTINSEL"],"Anzeige":["GRAFIK","STEUERUNG","HUD","EFFEKTE"],"Seekarten":["WELTKARTE","ANLEITUNG"],"Staff":["ÜBERSICHT","TELEPORT","SCHIFF","WELT","GEWÄHREN","ZIEL","PROTOKOLL"]}
const MODAL_TITLES := {"Spielinfo":"Kapitänsmenü","Menü":"Spielmenü","Events":"Events","Monster":"Seeungeheuer","Schnellzugriff":"Schnellleisten","Hilfe":"Spielanleitung","Verbrauch":"Verbrauchsgegenstände","Profil":"Spielerprofil","Freunde":"Freunde & Einladungen","Belohnungen":"Tagesbonus & AFK-Beute","Munition":"Munitionsauswahl","Markt":"Markt & Handel","Premium-Shop":"Kronen-Shop · Vorschau","Battle Pass":"Saisonpass","Kessel":"Gezeitenkessel","Staff":"Staff-Werkzeuge","Anzeige":"Anzeige & Steuerung","Rangliste":"Rangliste","Bonuskarten":"Bonuskarten"}

func _open_modal(kind: String,remember: bool=true) -> void:
	if browser_classic and kind in ["Werft","Events"]:
		var delivery=get_tree().root.get_node_or_null("BrowserContent")
		if delivery!=null and not delivery.available("ship_designs"):
			sim.message="Schiffskatalog wird geladen …"
			_refresh_ui()
			if not await delivery.ensure("ship_designs"):
				sim.message="Schiffskatalog nicht geladen. Bitte erneut öffnen."
				_refresh_ui()
				return
			_refresh_ship_catalog()
	if modal.visible and not menu_page_key.is_empty():
		menu_scroll_positions[menu_page_key]=modal_scroll.scroll_vertical
	elif not modal.visible:
		menu_scroll_positions.clear()
	if modal.visible and modal_kind!=kind and remember:
		menu_history.append(modal_kind)
		if menu_history.size()>16:menu_history.pop_front()
	elif not modal.visible and remember:menu_history.clear()
	_reset_enemy_tap()
	camera_pad.release()
	modal_kind=kind
	modal.plain=kind in ["Munition","Verbrauch"]
	modal_backdrop.color=Color(0,0,0,0) if kind in ["Munition","Verbrauch"] else Color(0.002,0.009,0.018,0.56)
	modal_title.add_theme_font_size_override("font_size",18 if kind in ["Munition","Verbrauch"] else 21)
	modal_title.add_theme_constant_override("outline_size",2 if kind in ["Munition","Verbrauch"] else 5)
	modal_close.add_theme_font_size_override("font_size",20 if kind in ["Munition","Verbrauch"] else 26)
	if kind in ["Munition","Verbrauch"]:
		for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var style=StyleBoxFlat.new();style.bg_color=Color("222d33");style.border_color=Color("8a7553");style.set_border_width_all(1)
			modal_close.add_theme_stylebox_override(state,style)
	else:SKIN.dress(modal_close,"close",20.0)
	modal_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if kind in ["Munition","Verbrauch"] else HORIZONTAL_ALIGNMENT_CENTER
	modal_title.text=str(MODAL_TITLES.get(kind,kind)).to_upper()
	modal_body.add_theme_constant_override("separation",5 if kind in ["Munition","Verbrauch"] else 10)
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	_build_tabs(kind)
	menu_page_key=kind+"/"+_tab(kind)
	var scroll_position: int=int(menu_scroll_positions.get(menu_page_key,0))
	_layout()
	match kind:
		"Schiff":_open_ship()
		"Menü":_open_menu_hub()
		"Munition":_open_ammo()
		"Verbrauch":_open_consumables()
		"Events":_open_events()
		"Monster":_open_monsters()
		"Schnellzugriff":_open_quick_config()
		"Hilfe":_open_help()
		"Profil":_open_profile()
		"Belohnungen":_open_rewards()
		"Freunde":_open_friends()
		"Werft":_open_shipyard()
		"Markt":_open_market()
		"Premium-Shop":_open_premium_shop()
		"Battle Pass":_open_battle_pass()
		"Bewaffnung":_open_weapons()
		"Hafen":_open_harbor()
		"Logbuch":_open_logbook()
		"Rangliste":_open_ranking()
		"Decks":_open_decks()
		"Kastelle":_open_castles()
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
	modal_scroll.restore(sim.ammo_mode*99 if kind=="Munition" else scroll_position)

func _close_modal() -> void:
	# Close BOTH surfaces. Leaving the backdrop active after X made the
	# sea appear frozen because it still intercepted every touch.
	_reset_enemy_tap()
	modal.hide()
	modal_backdrop.hide()
	menu_history.clear()
	menu_scroll_positions.clear()
	menu_page_key=""
	suppress_tap_until=Time.get_ticks_msec()+250
	_save_progress()

func _back_modal() -> void:
	_reset_enemy_tap()
	if menu_history.is_empty():
		_close_modal()
	else:
		var destination: String=menu_history.pop_back()
		_open_modal(destination,false)

func _build_tabs(kind: String) -> void:
	for child in modal_tabs.get_children():
		modal_tabs.remove_child(child)
		child.queue_free()
	var names: Array=MODAL_TABS.get(kind,[])
	if kind=="Staff" and not sim.staff.active():names=[]
	modal_tabs.visible=not names.is_empty()
	modal_tabs_scroll.visible=not names.is_empty()
	if names.is_empty():return
	var current=str(modal_tab.get(kind,names[0]))
	if not current in names:current=str(names[0])
	modal_tab[kind]=current
	for name in names:
		var tab: String=str(name)
		var caption: String="KANONEN" if kind=="Markt" and tab=="AUSRÜSTUNG" and get_viewport_rect().size.x<920.0 else tab
		var button=_button(modal_tabs,caption,func():_switch_tab(kind,tab),"tab_on" if tab==current else "tab")
		button.set_meta("menu_tab",tab)
		button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size=Vector2(154 if names.size()>=4 else 174,58)
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size",14)
		var tab_art: Texture2D=_menu_tab_art(kind,tab)
		if tab_art!=null:
			_with_icon(button,tab_art)
			button.add_theme_constant_override("icon_max_width",38)
		if tab==current:_reveal_menu_tab.call_deferred(button)

# Wait until the rebuilt category row has its final container measurements.
func _reveal_menu_tab(button: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(button) and button.is_inside_tree() and button.get_parent()==modal_tabs:
		modal_tabs_scroll.ensure_control_visible(button)

# Genuine game artwork, not text-only placeholder icons: each category
# provides a directly recognizable pictogram beside its active pill.
func _menu_tab_art(kind: String,tab: String) -> Texture2D:
	match kind:
		"Logbuch":return painted.nav_ship if tab=="VERTRÄGE" else (painted.spyglass if tab=="VERLAUF" else painted.nav_quests)
		"Markt":
			match tab:
				"AUSRÜSTUNG":return extra_icons.cannon_1
				"MUNITION":return icons.cannonball
				"ITEMS":return painted.supply_repair
				"AUKTION":return painted.reward_chest
		"Decks":
			match tab:
				"SCHIFF":return painted.nav_ship
				"LAGER":return painted.reward_chest
				"SPEZIAL":return painted.tide_deck
				"KAUFEN":return painted.gold_coins
		"Kastelle":
			return painted.nav_castles
		"Werft":
			return extra_icons.cannon_0 if tab=="KANONEN" else painted.nav_shipyard
		"Hafen":
			return painted.nav_harbor
		"Gilde":
			return painted.nav_guild
		"Anzeige":
			return hud_icons.gear
		"Seekarten":
			return painted.nav_bonus
	return null

func _switch_tab(kind: String,tab: String) -> void:
	modal_tab[kind]=tab
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
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y=34
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
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
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
	button.custom_minimum_size.y=48
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.disabled=disabled
	return button

# Shared mobile-first catalog used by Market, Decks, Castles, and Talents.
# At phone widths a tile spans the panel; landscape gets two or three
# columns. A price and a touch-sized action always stay BELOW its artwork.
func _catalog_grid(max_columns: int=3,parent: Node=null) -> GridContainer:
	var width: float=modal_scroll.size.x
	# Keep each illustrated product at least ~280px wide; never put two
	# tall image cards side by side in the narrow portrait modal.
	var columns: int=1 if width<690.0 else (3 if width>=1220.0 else 2)
	var gallery=_grid(mini(max_columns,columns),parent)
	gallery.set_meta("catalog_grid",true)
	return gallery

func _catalog_tile(parent: Node,texture: Texture2D,title: String,details: String,footer: String,accent: Color=Color("ab8852")) -> VBoxContainer:
	var panel: PanelContainer=_card(accent,parent)
	panel.set_meta("catalog_tile",true)
	# On phones the portrait and product information sit side by side with
	# the action BELOW them: big enough to see, but no 350px-tall card wall.
	# Wider panels retain the classic illustrated shop-grid presentation.
	var compact: bool=modal_scroll.size.x<690.0
	var side_by_side: bool=compact and modal_scroll.size.x>=420.0
	panel.custom_minimum_size=Vector2(0,224 if compact else 326)
	panel.set_meta("catalog_compact",compact)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	var lead: Node=content
	var copy: Node=content
	if side_by_side:
		var product_row=HBoxContainer.new()
		product_row.name="CatalogProductRow"
		product_row.add_theme_constant_override("separation",12)
		product_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		content.add_child(product_row)
		lead=product_row
		var info=VBoxContainer.new()
		info.name="CatalogInfo"
		info.add_theme_constant_override("separation",6)
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		info.mouse_filter=Control.MOUSE_FILTER_IGNORE
		copy=info
		# Art must precede copy in the row.
	var art_stage=PanelContainer.new()
	art_stage.name="CatalogArtStage"
	art_stage.add_theme_stylebox_override("panel",SKIN.catalog_art(accent))
	art_stage.custom_minimum_size=Vector2(132,140) if side_by_side else Vector2(0,140 if compact else 172)
	art_stage.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN if side_by_side else Control.SIZE_EXPAND_FILL
	art_stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lead.add_child(art_stage)
	var frame=CenterContainer.new()
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art_stage.add_child(frame)
	if texture!=null:
		var image_size: float=116.0 if compact else 148.0
		var art=_picture(frame,texture,image_size,false)
		art.name="CatalogArtwork"
		art.custom_minimum_size=Vector2(image_size,image_size)
	if side_by_side:lead.add_child(copy)
	var heading=_text(copy,title,17,Color("ffe4ad"))
	heading.name="CatalogTitle"
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if side_by_side else HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.y=28
	var description=_text(copy,details,14,Color("d6e5e6"))
	description.name="CatalogDescription"
	description.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if side_by_side else HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y=38
	var price=_text(copy,footer,15,Color("b8eacf"))
	price.name="CatalogStatus"
	price.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if side_by_side else HORIZONTAL_ALIGNMENT_CENTER
	price.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	price.custom_minimum_size.y=30
	price.add_theme_stylebox_override("normal",SKIN.note())
	return content

func _catalog_action(parent: Node,text: String,handler: Callable,disabled: bool=false) -> Button:
	var action=_row_button(parent,text,handler,disabled,"primary")
	action.custom_minimum_size.y=60
	action.add_theme_font_size_override("font_size",15)
	action.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return action

func _banner_card(texture: Texture2D,title: String,text: String,accent: Color=Color("c9a35e")) -> VBoxContainer:
	# Full-width illustrated hero: all major systems now open with a large
	# readable image, carved navy/brass title and concise explanatory copy.
	var banner=PanelContainer.new()
	banner.name="FeaturedMenuBanner"
	banner.add_theme_stylebox_override("panel",SKIN.feature_banner(accent))
	banner.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal_body.add_child(banner)
	var row=HBoxContainer.new()
	row.name="FeaturedMenuContent"
	row.add_theme_constant_override("separation",14)
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	banner.add_child(content)
	content.add_child(row)
	var narrow: bool=modal_scroll.size.x<420.0
	var short_panel: bool=modal_scroll.size.y<280.0
	var compact: bool=modal_scroll.size.x<510.0 or short_panel
	if texture!=null:
		var art_stage=PanelContainer.new()
		art_stage.name="FeaturedMenuArtStage"
		art_stage.add_theme_stylebox_override("panel",SKIN.catalog_art(accent))
		art_stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art_stage.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(art_stage)
		var image_size: float=88.0 if compact else 132.0
		var art=_picture(art_stage,texture,image_size,false)
		art.name="FeaturedMenuArtwork"
		art.custom_minimum_size=Vector2(image_size,image_size)
	var column=VBoxContainer.new()
	column.name="FeaturedMenuCopy"
	column.add_theme_constant_override("separation",8)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var eyebrow=_text(column,"ABYSSAL DOMINION  /  KAPITÄNSMENÜ",10,Color("9fd0cf"))
	eyebrow.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	eyebrow.visible=not narrow and not short_panel
	var label=_text(column,title,14 if narrow else (18 if compact else 22),Color("ffe2a0"))
	label.name="FeaturedMenuTitle"
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_outline_color",Color("081a20"))
	label.add_theme_constant_override("outline_size",3)
	# Portrait copy uses the full panel width instead of a thin column beside the art.
	var body=_text(content if narrow else column,text,13 if compact else 14,Color("d5e4e4"))
	body.name="FeaturedMenuDescription"
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
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

func _start_deck_motion(stage: Control) -> void:
	# Modest 15 FPS ornament animation, scoped to its modal; no permanent UI timers.
	var timer=Timer.new()
	timer.name="DeckArtPulse"
	timer.wait_time=1.0/15.0
	timer.autostart=true
	timer.timeout.connect(func():if is_instance_valid(stage) and stage.is_visible_in_tree():stage.queue_redraw())
	stage.add_child(timer)

func _open_ship() -> void:
	var stage=Control.new()
	stage.name="ShipStage"
	stage.custom_minimum_size=Vector2(0,250)
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.name="ShipStage"
	stage.draw.connect(func():_draw_ship_stage(stage))
	modal_body.add_child(stage)
	_start_deck_motion(stage)
	_meter("RUMPF",float(sim.player.hp),float(sim.player.max_hp),Color("4fbf5e"),"%s / %s" % [_thousands(int(sim.player.hp)),_thousands(int(sim.player.max_hp))])
	_meter("SCHILD",float(sim.player.shield),float(sim.player.max_shield),Color("3d8fe0"),"%s / %s" % [_thousands(int(sim.player.shield)),_thousands(int(sim.player.max_shield))])
	_meter("LV. %d · EP" % sim.level,float(sim.xp),float(sim.xp_required()),Color("c79a3f"),"%s / %s" % [_thousands(sim.xp),_thousands(sim.xp_required())])
	var stats=_grid(2)
	_stat(stats,"FAHRT","%d Knoten" % roundi(float(sim.player.speed)),painted.helm_wheel)
	_stat(stats,"NACHLADEN","%s s" % ("%.2f" % sim.reload_time()).replace(".",","),painted.spyglass)
	_stat(stats,"KANONEN","%d feuern · %d montiert · %d im Lager" % [sim.equipped_cannons(),sim.mounted_cannons,sim.cannon_storage()],extra_icons.cannon_0)
	_stat(stats,"BREITSEITE","%d Schaden je Kugel" % sim.weapon_damage(0),icons.cannonball)
	_section("DECKS")
	for slot in CONTENT.DECK_SLOT_COUNT:
		var index=int(sim.deck_slots[slot])
		if index>=0:
			var deck: Dictionary=sim.decks[index]
			_row(deck_icons.cannon,"PLATZ %d · %s\n%s" % [slot+1,_deck_title(deck),_deck_effect(deck)],44,CONTENT.DECK_TIER_COLORS[int(deck.tier)])
		else:_row(null,"PLATZ %d · FREI\nDecks montierst du angedockt im Hafen." % (slot+1),44,Color("4a4234"))
	var tide=float(sim.buffs.tide_deck)
	_row(deck_icons.tide,"GEZEITENDECK · "+("aktiv %s · +10 Kanonenplätze" % _clock_text(tide) if tide>0 else "nicht aktiv"),44,SEA_MARKS.DECK_COLORS.tide if tide>0 else Color("4a4234"))
	_section("VORRÄTE")
	var stock=_grid(2)
	for key: String in CONTENT.SUPPLY_KEYS:_stat(stock,str(CONTENT.SUPPLIES[key].name).to_upper(),"%d an Bord" % int(sim.supplies[key]),_supply_icon(key))
	var links=_grid(2)
	_action("SPIELERPROFIL",func():_open_modal("Profil"),"normal",links)
	_action("DECKS VERWALTEN",func():_open_modal("Decks"),"normal",links)
	_action("KASTELLE",func():_open_modal("Kastelle"),"normal",links)
	_action("SCHIFFSDESIGN WÄHLEN",func():_open_modal("Werft"),"normal",links)
	_action("KANONENMONTAGE",func():_switch_tab("Werft","KANONEN"),"normal",links)
	_action("BEWAFFNUNG",func():_open_modal("Bewaffnung"),"normal",links)

## The ship window retains the detailed deck gems; the sea uses a compact edge strip.
func _draw_ship_stage(stage: Control) -> void:
	var w=stage.size.x;var h=stage.size.y
	stage.draw_style_box(SKIN.card(),Rect2(Vector2.ZERO,stage.size))
	var sea=Rect2(5,5,w-10,h-10)
	stage.draw_polygon(PackedVector2Array([sea.position,Vector2(sea.end.x,sea.position.y),sea.end,Vector2(sea.position.x,sea.end.y)]),PackedColorArray([Color("0c2f3c"),Color("0c2f3c"),Color("06161d"),Color("06161d")]))
	var center=Vector2(w*.5,h*.47)
	var breathing=.5+.5*sin(elapsed*.9)
	var design_accent: Color=_ship_design_accent(int(sim.player.skin))
	for i in 4:
		var radii=Vector2(w*(.16+.05*i),h*(.05+.018*i))
		var ring=PackedVector2Array()
		for j in 33:ring.append(center+Vector2(0,h*.15)+Vector2(cos(j*TAU/32+elapsed*.07),sin(j*TAU/32+elapsed*.07))*radii)
		stage.draw_polyline(ring,Color(design_accent,.11+.06*breathing-.02*i),1.4,true)
	var tex: Texture2D=skin_previews[int(sim.player.skin)]
	var box=Vector2(minf(w*.6,380.0),h*.52)
	var k=minf(box.x/maxf(tex.get_width(),1),box.y/maxf(tex.get_height(),1))
	var dims=tex.get_size()*k
	stage.draw_texture_rect(tex,Rect2(center-dims*Vector2(.5,.62),dims),false)
	var staff=sim.staff
	var name=str(skins[int(sim.player.skin)].name).to_upper()
	var tag="[%s] " % sim.guild.tag if not sim.guild.is_empty() else ""
	var title=tag+name
	var title_size:=17
	var badge=SEA_MARKS.badge_width(staff.badge(),font,12)+8 if staff.shows_badge() else 0.0
	var tw=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
	# The longer Elite 1 name and guild tag must fit small Android ship panels.
	while title_size>12 and tw+badge>w-88.0:
		title_size-=1
		tw=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
	var left=maxf(48.0,w*.5-(tw+badge)*.5)
	if staff.shows_badge():SEA_MARKS.staff_badge(stage,Vector2(left,22),staff.badge(),staff.color(),font,12)
	_canvas_text(stage,Vector2(left+badge+tw*.5,28),title,title_size,staff.color() if staff.shows_badge() else design_accent)
	if int(sim.player.skin)>=2 and int(sim.player.skin)<=11:
		_canvas_text(stage,Vector2(w-77,58),"ELITE · %02d" % (int(sim.player.skin)-1),11,Color(design_accent,.84))
	elif int(sim.player.skin)==1:
		_canvas_text(stage,Vector2(w-77,58),"TESTMODELL",11,Color(GOLD,.84))
	var tier=clampi(floori((sim.level-1)/4.0)+1,1,ROMAN.size()-1)
	stage.draw_circle(Vector2(34,34),18,Color("17303c"));stage.draw_arc(Vector2(34,34),18,0,TAU,28,Color("d8b46a"),2.0,true)
	_canvas_text(stage,Vector2(34,39),ROMAN[tier],13,Color("ffe6a8"))
	_canvas_text(stage,Vector2(34,66),"LV. %d" % sim.level,11,Color("ecd29a"))
	SEA_MARKS.deck_badge(stage,Vector2(w*.5,h-55),10,sim,elapsed)
	var mounted=0
	for index in sim.deck_slots:
		if int(index)>=0:mounted+=1
	_canvas_text(stage,Vector2(w*.5,h-12),"%d / 10 DECKS · GEZEITENDECK %s" % [mounted,_clock_text(float(sim.buffs.tide_deck)) if float(sim.buffs.tide_deck)>0 else "AUS"],12,Color("e2ecee"))

func _ammo_texture(index: int) -> Texture2D:
	# M3106: original screenshots supplied by user, cropped to 28 distinct
	# 96x96 selection portraits. Same exact images in the quick HUD and shop.
	if index<0 or index>=AMMO_UI.size():return null
	var key: String=str(AMMO_UI[index].icon)
	if not ammo_previews.has(key):
		var preview:=AtlasTexture.new()
		preview.atlas=USER_AMMO_ATLAS
		preview.region=Rect2(Vector2(float(posmod(index,7)*96),float(floori(index/7.0)*96)),Vector2(96,96))
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
		row.accent=COMBAT_FX.weapon_color(str(sim.AMMO_NAMES[i]))
		row.art=_ammo_texture(i)
		row.text="%s · Vorrat %d · %s" % [AMMO_UI[i].name,sim.player.ammo[i],AMMO_UI[i].use]
		row.tooltip_text=row.text
		row.set_meta("ammo_index",i);row.name="AmmoChoice%d" % i
		row.custom_minimum_size=Vector2(0,94);row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.pressed.connect(func():_choose_ammo(index))
		modal_body.add_child(row);ammo_rows.append(row)

# Drawn beneath the actual original-model preview: restrained sea and wake,
# not a replacement/synthetic illustration of the uploaded Black Crown GLB.
# Real sea art, a navy-to-turquoise undersea gradient, drifting wavelets and
# low foamy wake live BEHIND each ORIGINAL ship portrait, not on top of sails.
# For V2 RGB source renders, the per-TextureRect chroma key reveals this layer.
func _draw_shipyard_preview(frame: Control,index: int,chosen: bool,accent: Color) -> void:
	var dimensions: Vector2=frame.size
	if dimensions.x<35.0 or dimensions.y<35.0:return
	var w: float=dimensions.x
	var h: float=dimensions.y
	var inset: float=5.0
	var clock: float=elapsed if ship_animations_enabled else 0.0
	var shimmer: float=.5+.5*sin(clock*.86+float(index)*1.12)
	# The SAME painted ocean source as the game map, with a readable warm
	# studio-light gradient; leave frame borders unobscured.
	var ocean_area=Rect2(Vector2(inset,inset),Vector2(w-inset*2.0,h-inset*2.0))
	frame.draw_polygon(PackedVector2Array([
		Vector2(inset,inset),Vector2(w-inset,inset),
		Vector2(w-inset,h-inset),Vector2(inset,h-inset)
	]),PackedColorArray([
		Color("0b2937"),Color("0b3b49"),
		Color("105b65"),Color("073240")
	]))
	frame.draw_texture_rect(SHIPYARD_SEA_TILE,ocean_area,false,Color(.65,.95,.96,.19))
	# Broad, nearly transparent water contours; subtle enough to avoid
	# competing with the authentic gilded rigging and sail graphics.
	for band in 10:
		var line: PackedVector2Array=PackedVector2Array()
		var band_y: float=h*(.08+float(band)*.091)
		var phase: float=clock*.69+float(index)*.71+float(band)*.63
		for step in 20:
			var px: float=inset+(w-2.0*inset)*float(step)/19.0
			var py: float=band_y+sin(float(step)*.43+phase)*2.2+cos(float(step)*.91-phase*.67)*.75
			line.append(Vector2(px,py))
		frame.draw_polyline(line,Color(.68,.93,.97,.085+.045*shimmer),1.15,true)
	# Ship's soft contact shadow and refracted ellipse, under the actual hull.
	var center: Vector2=Vector2(w*.49,h*.73)
	var shadow: PackedVector2Array=PackedVector2Array()
	var contact: PackedVector2Array=PackedVector2Array()
	for sample in 33:
		var angle: float=float(sample)*TAU/32.0
		var unit: Vector2=Vector2(cos(angle),sin(angle))
		shadow.append(center+unit*Vector2(w*.255,h*.088))
		contact.append(center+unit*Vector2(w*.32,h*.124))
	frame.draw_colored_polygon(shadow,Color(.005,.045,.068,.33))
	frame.draw_polyline(contact,Color(.77,.96,.93,.17+.04*shimmer),1.2,true)
	# Moving broken foam on either side; never cover the ship foreground.
	for side in [-1.0,1.0]:
		var side_val: float=side
		var start_point: Vector2=center+Vector2(-w*.10,side_val*h*.07)
		var wake_points: PackedVector2Array=PackedVector2Array()
		for step in 15:
			var progress: float=float(step)/14.0
			wake_points.append(start_point+Vector2(-w*.19*progress,side_val*h*.068*progress+sin(progress*11.0-clock*1.85+side_val)*1.2))
		frame.draw_polyline(wake_points,Color(.81,.98,1.0,.15+.04*shimmer),1.2,true)
	# Per-design colored glints are restrained and remain within the water.
	for glint in 8:
		var seed: float=float(index*17+glint*29)
		var px: float=inset+10.0+fposmod(seed*11.7+clock*(3.0+float(glint%3)),maxf(1.0,w-inset*2.0-25.0))
		var py: float=h*(.18+float(glint)*.085)+sin(clock*.8+seed)*2.0
		var a: float=.095+.085*(.5+.5*sin(clock*1.7+seed))
		frame.draw_line(Vector2(px,py),Vector2(px+6.0+float(glint%3)*2.0,py),Color(accent,a),.95,true)
	if chosen:
		var activated: float=.65+.16*sin(clock*1.4)
		frame.draw_arc(Vector2(w-22.0,21.0),8.0,0.0,TAU,24,Color(accent,activated),1.8,true)
		frame.draw_circle(Vector2(w-22.0,21.0),2.8,Color(accent,.88))

func _start_shipyard_preview_motion(frames: Array[Control]) -> void:
	# One modest 8 FPS timer for ALL twelve cards, not twelve separate timers.
	var timer=Timer.new()
	timer.name="ShipyardPreviewMotion"
	timer.wait_time=.125
	timer.autostart=true
	timer.timeout.connect(func():
		# No 8 FPS background work during gameplay or when animation is off.
		if modal==null or not modal.visible or modal_kind!="Werft" or not ship_animations_enabled:return
		for frame: Control in frames:
			if is_instance_valid(frame) and frame.is_visible_in_tree():frame.queue_redraw()
	)
	modal_body.add_child(timer)

func _add_shipyard_card(index: int,container: Node,frames: Array[Control]) -> void:
	var choice: int=index
	var chosen: bool=index==int(sim.player.skin)
	var accent: Color=_ship_design_accent(index)
	var card=_card(accent,container)
	card.set_meta("ship_design_index",index)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",7)
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var frame=Panel.new()
	frame.name="ShipDesignPreview%d" % index
	frame.custom_minimum_size=Vector2(0,252 if index<=1 else 222)
	frame.clip_contents=true
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel",SKIN.icon_frame(accent))
	column.add_child(frame)
	frame.draw.connect(func():_draw_shipyard_preview(frame,choice,chosen,accent))
	frames.append(frame)
	var preview=_portrait(frame)
	preview.name="ShipDesignArtwork%d" % index
	preview.texture=skin_previews[index]
	# The ten mobile preview renders were exported on opaque #1c1c24.
	# Remove ONLY that background with a small shader, keeping the real
	# ship foreground untouched, so the seawater is visible behind it.
	if index>=2 and index<=11:
		var key_material=ShaderMaterial.new()
		key_material.shader=SHIPYARD_STUDIO_KEY
		preview.material=key_material
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.offset_left=6;preview.offset_top=6;preview.offset_right=-6;preview.offset_bottom=-6
	var status_text: String="AUSGERÜSTET" if chosen else ("EVENT" if index>=12 else "ELITE · %02d" % (index-1) if index>=2 else ("ORIGINAL · TEST" if index==1 else "BASISSCHIFF"))
	var badge=_text(frame,status_text,12,accent.lightened(.16))
	badge.name="ShipStatus%d" % index
	badge.position=Vector2(14,12)
	badge.add_theme_color_override("font_outline_color",Color("06161b"))
	badge.add_theme_constant_override("outline_size",4)
	var model_ok: bool=browser_classic or (mesh_layer!=null and mesh_layer.model_scenes.has(str(skins[index].mesh_key)))
	if index>=2 and not browser_classic:model_ok=model_ok and ResourceLoader.exists(mesh_layer.texture_path(index-1))
	var hint: String=str(skins[index].name).to_upper() if index>=12 else "ELITE %02d · %s" % [index-1,ELITE_V2_NAMES[index-2].to_upper()] if index>=2 else ("BLACK CROWN · ORIGINAL-TEST" if index==1 else "SCHATTENKRIEGSSCHIFF · STANDARD")
	var description=_text(column,hint,13,accent)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var details=_text(column,"Classic-2D-Ansichten aus dem Originalmodell" if browser_classic else ("Echtes 3D-GLB · 2,5D & 3D · Nur Design" if index>=2 else "Originalgeometrie · Gleiche Werte"),12,Color("c0d5d5"))
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var label: String=str(skins[index].name).to_upper()+"\n"+("AKTIV · AUSGERÜSTET" if chosen else ("AUSRÜSTEN · TEST" if model_ok else "TEXTUR / MODELL FEHLT"))
	var choose=_button(column,label,func():_equip(choice),"normal" if chosen else "primary")
	choose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	choose.custom_minimum_size.y=60
	choose.add_theme_font_size_override("font_size",12)
	choose.disabled=chosen or not model_ok

func _set_shipyard_filter(value: String) -> void:
	if not value in ["all","elite","original","event"]:return
	if shipyard_filter==value:return
	shipyard_filter=value
	# A new filter must begin at its first card, not an old deep-scroll offset.
	modal_scroll.restore(0)
	if modal!=null and modal.visible and modal_kind=="Werft":_open_modal("Werft")

func _open_shipyard() -> void:
	if _tab("Werft")=="KANONEN":
		_open_cannon_fitment()
		return
	_banner_card(painted.nav_shipyard,"WERFT · 10 ELITE-SCHIFFE","Zwei bestehende Designs bleiben erhalten. Elite 01–10 nutzen exakt dasselbe originale Black-Crown-GLB mit verschiedenen Texturen. Alle Designs kostenlos und jederzeit wechselbar; sämtliche Kampfwerte bleiben gleich.")
	var current: int=clampi(int(sim.player.skin),0,skins.size()-1)
	_note("AUSGERÜSTET · "+str(skins[current].name),_ship_design_accent(current))
	# On compact phones a dozen cards take a lot of scrolling. These controls
	# only filter the view; all 12 designs remain playable and saved unchanged.
	var filters=_grid(4)
	for entry in [["all","ALLE · 14"],["elite","ELITE · 10"],["original","STANDARD / TEST · 2"],["event","EVENT · 2"]]:
		var key: String=str(entry[0])
		var selected: bool=shipyard_filter==key
		var button=_action(str(entry[1])+(" ✓" if selected else ""),func():_set_shipyard_filter(key),"tab_on" if selected else "normal",filters)
		button.disabled=selected
	var frames: Array[Control]=[]
	if shipyard_filter in ["all","original"]:
		_section("STANDARD & UNVERÄNDERTES TESTMODELL")
		var original_cards=_grid(2 if modal_scroll.size.x>=700 else 1)
		for index in 2:_add_shipyard_card(index,original_cards,frames)
	if shipyard_filter in ["all","elite"]:
		_section("ELITE-DESIGNS 01–10 · V2")
		# Larger water-backed ship portraits: two columns on tablets and one
		# on narrow phones, with three only on genuinely wide desktop panels.
		var cols: int=3 if modal_scroll.size.x>=1260 else (2 if modal_scroll.size.x>=700 else 1)
		var elites=_grid(cols)
		for index in range(2,12):_add_shipyard_card(index,elites,frames)
	if shipyard_filter in ["all","event"]:
		_section("EVENT-DESIGNS")
		var events=_grid(2 if modal_scroll.size.x>=700 else 1)
		for index in range(12,14):_add_shipyard_card(index,events,frames)
	_start_shipyard_preview_motion(frames)
	_section("SCHIFFSAUSRÜSTUNG")
	var yard_links=_grid(2)
	_action("KANONEN MONTIEREN",func():_switch_tab("Werft","KANONEN"),"normal",yard_links)
	_action("MUNITION IM MARKT",func():_switch_tab("Markt","MUNITION"),"normal",yard_links)

func _open_cannon_fitment() -> void:
	_banner_card(extra_icons.cannon_0,"WERFT · GESCHÜTZMONTAGE","Kanonen werden aus dem Arsenal auf das Schiff montiert – auch außerhalb des Hafens, solange du nicht im Gefecht bist. Munition gehört ausschließlich in den Markt und ins Kampfmenü.")
	_section("KANONEN AN DEINEM SCHIFF")
	var stats=_grid(2)
	_stat(stats,"MONTIERT","%d Kanonen" % sim.mounted_cannons,extra_icons.cannon_0)
	_stat(stats,"FREIE PLÄTZE","%d von %d" % [maxi(0,sim.cannon_slots()-sim.equipped_cannons()),sim.cannon_slots()],painted.nav_shipyard)
	_stat(stats,"IM ARSENAL","%d Kanonen" % sim.cannon_storage(),extra_icons.cannon_1)
	_stat(stats,"AKTIV","%d Kanonen feuern" % sim.equipped_cannons(),extra_icons.cannon_0)
	_note("Geschützplätze hängen von Decks und Segnungen ab. Bei ablaufenden Boni bleiben überschüssige Kanonen montiert, aber vorübergehend inaktiv.")
	if not sim.can_refit_cannons():_note("Kanonenmontage derzeit gesperrt: Während des Gefechts, kurz nach einem Treffer oder auf einer Bonuskarte ist kein Umbau möglich.",Color("edc68c"))
	_section("KANONEN AN BORD BRINGEN")
	var fitting=_grid(3)
	for n in [1,5,999]:
		var count: int=n
		var label: String="ALLE MONTIEREN" if n==999 else "+%d MONTIEREN" % n
		var button=_action(label,func():
			sim.mount_cannons(count)
			_save_progress();_open_modal("Werft");_refresh_ui(),"normal",fitting)
		button.disabled=not sim.can_refit_cannons() or sim.cannon_storage()<=0 or sim.equipped_cannons()>=sim.cannon_slots()
	var storage=_grid(3)
	for n in [1,5,999]:
		var count: int=n
		var label: String="ALLE INS LAGER" if n==999 else "−%d INS LAGER" % n
		var button=_action(label,func():
			sim.unmount_cannons(count)
			_save_progress();_open_modal("Werft");_refresh_ui(),"normal",storage)
		button.disabled=not sim.can_refit_cannons() or sim.mounted_cannons<=0
	_section("GESCHÜTZPLÄTZE ERWEITERN")
	var links=_grid(2)
	_action("KANONEN IM MARKT KAUFEN",func():_switch_tab("Markt","AUSRÜSTUNG"),"normal",links)
	_action("KANONENDECKS",func():_open_modal("Decks"),"normal",links)

func _open_weapons() -> void:
	_banner_card(extra_icons.cannon_0,"BEWAFFNUNG · SCHIFFSARSENAL","Geschütze, Munition und Kampfbereitschaft sind getrennte Systeme. Die Werft montiert Kanonen, der Markt verkauft Kugeln und Items; das Munitionsmenü lädt die gewünschte Sorte.")
	var overview=_grid(2)
	_stat(overview,"GESCHÜTZE","%d/%d aktiv" % [sim.equipped_cannons(),sim.cannon_slots()],extra_icons.cannon_0)
	_stat(overview,"ARSENAL","%d Kanonen im Lager" % sim.cannon_storage(),extra_icons.cannon_1)
	_stat(overview,"FEUERKRAFT","%d Schaden pro Geschoss" % sim.weapon_damage(sim.ammo_mode),icons.cannonball)
	_stat(overview,"NACHLADEN","%.2f Sekunden" % sim.reload_time(),painted.spyglass)
	_section("GELADENE MUNITION")
	var index: int=sim.ammo_mode
	_row(_ammo_texture(index),"%s · %d Geschosse im Lager\nVerwendung: %s" % [AMMO_UI[index].name,int(sim.player.ammo[index]),str(AMMO_UI[index].use)],54,Color("b99a66"))
	var actions=_grid(2)
	_action("KANONEN MONTIEREN",func():_switch_tab("Werft","KANONEN"),"normal",actions)
	_action("MUNITION AUSWÄHLEN",func():_open_modal("Munition"),"normal",actions)
	_action("MUNITION KAUFEN",func():_switch_tab("Markt","MUNITION"),"normal",actions)
	_action("KASTELLE & TALENTE",func():_open_modal("Kastelle"),"normal",actions)
	_note("Die zahlreichen Sondermunitionen sind weiter im separaten Munitionsmenü vorhanden. Ihre Beta-Werte und Effekte werden später balanciert.")


# Marketplace is a real GOLD economy. There is deliberately no pretend
# online auction, no credit-card form, and no fake premium transaction.
func _open_market() -> void:
	_banner_card(painted.nav_harbor,"MARKT · HÄNDLER & HANDEL","Große Warenkarten mit Bestandsanzeige, Preis und direktem Kauf. Du kannst auch auf See einkaufen.")
	_section("DEIN GOLD · %s" % _thousands(int(sim.player.gold)))
	match _tab("Markt"):
		"AUSRÜSTUNG":
			_section("SCHIFFSGESCHÜTZE")
			var goods=_catalog_grid(2)
			var column=_catalog_tile(goods,extra_icons.cannon_1,"KANONENPAKET · 2 STÜCK","Besitz: %d · montiert: %d\nIm Arsenal: %d" % [int(sim.player.cannons),sim.mounted_cannons,sim.cannon_storage()],"%s GOLD" % _thousands(sim.cannon_price()),Color("ba9054"))
			var buy=_catalog_action(column,"2 KANONEN KAUFEN",func():
				sim.buy_cannons();_save_progress();_open_modal("Markt");_refresh_ui(),int(sim.player.cannons)>=sim.MAX_CANNONS or int(sim.player.gold)<sim.cannon_price())
			buy.name="MarketCannons"
			buy.tooltip_text="Gekaufte Kanonen kommen ins Arsenal und werden in der Werft montiert."
			var yard=_catalog_tile(goods,painted.nav_shipyard,"WERFT & ARSENAL","Geschützplätze und Schiffsausrüstung verwalten.","SCHIFFSAUSRÜSTUNG",Color("566f79"))
			_catalog_action(yard,"KANONEN MONTIEREN",func():_switch_tab("Werft","KANONEN"))
			_note("Kugeln gehören ausschließlich in den Munitionsmarkt. Neue Kanonen werden nicht automatisch aufs Schiff montiert.")
		"MUNITION":
			_section("STANDARDMUNITION & HARPUNEN")
			_note("Wähle die Ware anhand ihres Bildes. Der Preis gilt jeweils für ein Paket; im Kampf wird die Munition separat ausgewählt.")
			var basic=_catalog_grid(3)
			for i in AMMO_UI.size():
				if i==3:
					_section("SPEZIALMUNITION · BETA")
					basic=_catalog_grid(3)
				var index: int=i
				var data: Dictionary=AMMO_UI[i]
				var price: int=30 if index<3 else 80
				var stock: int=int(sim.player.ammo[index])
				var count: int=sim.ammo_pack(index)
				var tile=_catalog_tile(basic,_ammo_texture(index),str(data.name).to_upper(),"%s\nIm Lager: %s" % [str(data.use),_thousands(stock)],"+%d STÜCK · %d GOLD" % [count,price],Color("a6bfa3") if sim.ammo_mode==index else Color("a88959"))
				var purchase=_catalog_action(tile,"KAUFEN · %d GOLD" % price,func():
					sim.buy_ammo(index);_save_progress();_open_modal("Markt");_refresh_ui(),int(sim.player.hp)<=0 or int(sim.player.gold)<price)
				purchase.name="MarketAmmo"+str(index)
			_action("ZUR MUNITIONSWAHL",func():_open_modal("Munition"))
		"ITEMS":
			_section("VERBRAUCHSGEGENSTÄNDE")
			_note("Reparatur, Schutzschild und Spezialeffekte – direkte Käufe ohne Andocken.")
			var goods=_catalog_grid(3)
			for key: String in CONTENT.SUPPLY_KEYS:
				var item: String=key
				var config: Dictionary=CONTENT.SUPPLIES[key]
				var price: int=int(config.price)
				var count: int=int(config.pack)
				var tile=_catalog_tile(goods,_supply_icon(item),str(config.name).to_upper(),"%s\nIm Lager: %d" % [str(config.effect),int(sim.supplies[item])],"+%d STÜCK · %d GOLD" % [count,price],Color("9a7e4f"))
				var buy=_catalog_action(tile,"KAUFEN · %d GOLD" % price,func():
					sim.buy_supply(item);_save_progress();_open_modal("Markt");_refresh_ui(),int(sim.player.gold)<price)
				buy.name="MarketItem_"+item
			_action("ZUR VERBRAUCHSAUSWAHL",func():_open_modal("Verbrauch"))
		"AUKTION":
			_section("SPIELERHANDEL · SPÄTER ONLINE")
			var auction=_catalog_grid(2)
			var tile=_catalog_tile(auction,painted.reward_chest,"AUKTIONSHAUS","Spielerangebote brauchen Serverkonten und sichere Besitzübertragung.","DERZEIT NICHT VERFÜGBAR",Color("566773"))
			var locked=_catalog_action(tile,"ONLINE-HANDEL GESPERRT",func():pass,true)
			locked.name="LockedAuction"
			_action("ZURÜCK ZUM MARKT",func():_switch_tab("Markt","AUSRÜSTUNG"))

func _open_premium_shop() -> void:
	_banner_card(painted.gold_coins,"KRONEN-SHOP · VORSCHAU","Große Artikelkarten wie im Markt – echte Zahlung und Premiumwährung bleiben in der lokalen Beta deaktiviert.")
	_section("KRONEN · NOCH NICHT AKTIV")
	var display=_catalog_grid(2)
	var offers=["Kronen-Paket · Klein","Kronen-Paket · Mittel","Kronen-Paket · Groß","Saisonpass · Premium"]
	for i in offers.size():
		var title: String=str(offers[i])
		var art: Texture2D=painted.reward_chest if i==3 else painted.gold_coins
		var tile=_catalog_tile(display,art,title.to_upper(),"Preis und Gegenwert werden erst nach Abschluss des Balancings festgelegt.","KEIN GELDVERKEHR",Color("78615f"))
		var inactive=_catalog_action(tile,"NOCH NICHT KAUFBAR",func():pass,true)
		inactive.name="DisabledPayment"
	_note("Keine Zahlung, kein fingiertes Guthaben. Kronen und Echtgeldkäufe benötigen Serverkonten sowie gültige Kaufbestätigungen.")
	var links=_grid(2)
	_action("GOLD-MARKTPLATZ",func():_open_modal("Markt"),"normal",links)
	_action("SAISONPASS ANSEHEN",func():_open_modal("Battle Pass"),"normal",links)

func _open_harbor() -> void:
	var name: String="PORT AZUR" if sim.map_id==0 else "HAFEN"
	if not sim.has_harbor():
		_banner_card(painted.nav_harbor,"BONUSKARTE · KEIN HAFEN","Du bist in einer Bonuskarteninstanz. Über BONUSKARTE VERLASSEN kehrst du zum normalen Seegebiet zurück.")
	elif not sim.docked:
		_banner_card(painted.nav_harbor,"%s · EINLAUFEN" % name,"Zum Schutz, zur Reparatur und für stationäre Hafendienste kannst du am goldenen Anleger festmachen. Entfernung: %d m." % roundi(sim.player.pos.distance_to(sim.harbor)))
		var navigation=_grid(2)
		_primary("KURS ZUM HAFEN",func():sim.course(sim.harbor);_close_modal(),navigation)
		var dock_button=_action("ANDOCKEN",func():
			if sim.dock():_save_progress();_open_modal("Hafen")
			_refresh_ui(),"normal",navigation)
		dock_button.disabled=not sim.can_dock()
	else:
		_banner_card(painted.nav_harbor,"%s · ANKERPLATZ" % name,"Im geschützten Hafen kannst du reparieren, Kastelle ausbauen und stationäre Dienste benutzen. Handel und Schiffsausrüstung funktionieren auch außerhalb des Hafens.")
		match _tab("Hafen"):
			"DOCK":
				_section("TROCKENDOCK & REPARATUREN")
				var cost: int=sim.harbor_repair_cost()
				var repair=_with_icon(_action("RUMPF REPARIEREN · %d GOLD" % cost,func():
					sim.harbor_repair();_save_progress();_open_modal("Hafen");_refresh_ui()),painted.gold_coins)
				repair.disabled=cost<=0 or int(sim.player.gold)<cost
				_section("STATIONÄRE AUSBAUTEN · VORLÄUFIG")
				var castles: int=0
				for key: String in CONTENT.UPGRADE_KEYS:castles+=int(sim.upgrades[key])
				_with_icon(_action("KASTELLE · %d/%d STUFEN" % [castles,CONTENT.UPGRADE_KEYS.size()*CONTENT.CASTLE_MAX],func():_open_modal("Kastelle")),painted.nav_castles)
				_note("Die Hafenzuordnung der Kastelle ist vorläufig. Talente lassen sich bereits auf See verteilen.")
			"DIENSTE":
				_section("HAFENDIENSTE")
				var services=_grid(2)
				_with_icon(_action("GEZEITENKESSEL",func():_open_modal("Kessel"),"normal",services),painted.nav_kessel)
				_with_icon(_action("DECKWERFT & DECKS",func():_open_modal("Decks"),"normal",services),painted.tide_deck)
				_note("Weitere Hafengebäude und Dienstleistungen bestimmen wir später. Markt, Items, Schiffe, Kanonen und Talente sind unabhängig vom Andocken erreichbar.")
			_:
				_note("Wähle DOCK oder DIENSTE.",Color("bac7c7"))
		_primary("ABLEGEN",func():sim.depart();_close_modal();_refresh_ui())
	if not sim.docked:
		_note("Der Markt, die Werft und die Talentübersicht sind auch ohne Hafen erreichbar. Öffne dafür die jeweiligen Menüs.",Color("9bd6bd"))
	_action("UPDATES PRÜFEN",func():
		_save_progress()
		get_tree().set_meta("abyssal_manual_update",true)
		get_tree().change_scene_to_file("res://updater/launcher.tscn"))

func _open_logbook() -> void:
	if _tab("Logbuch")=="VERTRÄGE":
		_open_sea_contracts()
		return
	_info("KAMPAGNE · LV. %d · %d/%d AUFTRÄGE ERLEDIGT" % [sim.level,mini(sim.quest_index,CONTENT.QUESTS.size()),CONTENT.QUESTS.size()],CYAN)
	if _tab("Logbuch")=="VERLAUF":
		_section("ABGESCHLOSSENE AUFTRÄGE")
		if sim.quest_index==0:_note("Noch kein Auftrag abgeschlossen. Deinen nächsten Schritt findest du unter AKTUELL.")
		for i in mini(sim.quest_index,CONTENT.QUESTS.size()):
			var q: Dictionary=CONTENT.QUESTS[i]
			_row(painted.nav_quests,"ERLEDIGT · %s\n%s" % [q.name,q.description],48,Color("6fd37a"))
	else:
		var q: Dictionary=sim.current_quest()
		if q.is_empty():
			_section("KAMPAGNE ABGESCHLOSSEN")
			_note("Alle bisherigen Aufträge sind erledigt. Bonuskarten, Seeungeheuer und Veranstaltungen bleiben verfügbar.")
			_action("SEEVERTRÄGE ANNEHMEN",func():_switch_tab("Logbuch","VERTRÄGE"),"primary")
			_action("BONUSKARTEN ÖFFNEN",func():_open_modal("Bonuskarten"))
		else:
			_section("DEIN AKTIVER AUFTRAG")
			var progress: int=mini(sim.quest_progress(),int(q.goal))
			var column=_row(painted.nav_quests,"AKTIV · %s\n%s\nBelohnung: %d Gold · %d EP · %d Essenz" % [q.name,q.description,q.gold,q.xp,q.essence],56,Color("ffd27a"))
			column.name="ActiveQuest"
			_meter("FORTSCHRITT",progress,int(q.goal),Color("62bdae"),"%d / %d" % [progress,q.goal])
			var claim=_primary("BELOHNUNG ABHOLEN",func():sim.claim_quest();_save_progress();_open_modal("Logbuch");_refresh_ui())
			claim.name="QuestClaim";claim.disabled=progress<int(q.goal)
			if progress<int(q.goal):
				var destination: String="Monster" if str(q.stat)=="monsters" else ("Seekarten" if str(q.stat) in ["north","abyss"] else "Hilfe")
				_action("MONSTER FINDEN" if destination=="Monster" else ("ROUTE AUF DER WELTKARTE" if destination=="Seekarten" else "HINWEISE ZUR SEEKARTE"),func():_open_modal(destination))
			if sim.quest_index+1<CONTENT.QUESTS.size():
				var next: Dictionary=CONTENT.QUESTS[sim.quest_index+1]
				_note("DANACH · %s\n%s" % [next.name,next.description],Color("94abad"))
	_section("LETZTE MELDUNGEN")
	var recent=message_history.duplicate();recent.reverse()
	_note("\n".join(recent) if not recent.is_empty() else "Noch keine Meldungen",Color("d6e2e4"))

func _open_sea_contracts() -> void:
	_info("WIEDERHOLBARE SEEVERTRÄGE",CYAN)
	_note("Fortschritt zählt ab Annahme. Drei Verträge parallel; nach dem Abholen erneut annehmen.")
	for key: String in sim.CONTRACTS.ORDER:
		var contract_key: String=key
		var data: Dictionary=sim.sea_contracts.info(sim,key)
		var column=_row(painted.boss_wave if key=="hunt" else (painted.reward_chest if key=="salvage" else painted.nav_ship),"%s\n%s\n%d Gold · %d EP · %d Essenz" % [data.name,data.description,data.gold,data.xp,data.essence],56,Color("70c3a7") if bool(data.ready) else GOLD)
		column.name="SeaContract_"+key
		var progress=_bar(column)
		progress.name="SeaContractProgress_"+key
		progress.custom_minimum_size.y=12;progress.max_value=int(data.goal);progress.value=int(data.progress)
		var state: String="BEREIT ZUM ABHOLEN" if bool(data.ready) else ("IN ARBEIT · %d / %d" % [data.progress,data.goal] if bool(data.active) else "NOCH NICHT ANGENOMMEN")
		var state_label=_note("%s · %d× erfüllt" % [state,data.completed],CYAN,column)
		state_label.name="SeaContractState_"+key
		var action=_row_button(column,"BELOHNUNG ABHOLEN" if bool(data.ready) else ("IN ARBEIT" if bool(data.active) else "ANNEHMEN"),func():
			if bool(sim.sea_contracts.info(sim,contract_key).active):sim.sea_contracts.claim(sim,contract_key)
			else:sim.sea_contracts.accept(sim,contract_key)
			_save_progress();_open_modal("Logbuch");_refresh_ui(),(bool(data.active) and not bool(data.ready)) or sim.staff.active(),"primary")
		action.name="SeaContractAction_"+key
		if key=="hunt":_row_button(column,"MONSTER FINDEN",func():_open_modal("Monster"))
	_note("Keine Battle Points: Diese Aufträge sind PvE-Inhalte. Sie sind unabhängig von Kampagne, Tagesbonus und Saisonpass.")

func _refresh_contract_rows() -> void:
	for key: String in sim.CONTRACTS.ORDER:
		var action: Button=modal_body.find_child("SeaContractAction_"+key,true,false) as Button
		if action==null:continue
		var data: Dictionary=sim.sea_contracts.info(sim,key)
		action.text="BELOHNUNG ABHOLEN" if bool(data.ready) else ("IN ARBEIT" if bool(data.active) else "ANNEHMEN")
		action.disabled=(bool(data.active) and not bool(data.ready)) or sim.staff.active()
		var progress: ProgressBar=modal_body.find_child("SeaContractProgress_"+key,true,false) as ProgressBar
		if progress!=null:progress.value=int(data.progress)
		var label: Label=modal_body.find_child("SeaContractState_"+key,true,false) as Label
		if label!=null:label.text=("BEREIT ZUM ABHOLEN" if bool(data.ready) else ("IN ARBEIT · %d / %d" % [data.progress,data.goal] if bool(data.active) else "NOCH NICHT ANGENOMMEN"))+" · %d× erfüllt" % data.completed

func _open_ranking() -> void:
	var ranks=["Schiffsjunge","Matrose","Bootsmann","Steuermann","Leutnant","Kapitän","Kommodore","Admiral"]
	_banner_card(painted.nav_ranking,"KAPITÄNSRANG · %s" % ranks[clampi(floori((sim.level-1)/2.5),0,ranks.size()-1)].to_upper(),"Kapitänsstufe %d · Erfahrung %s / %s\nGold %s\nVersenkte Schiffe %d · davon Elite %d\nSeeungeheuer %d · Beutekisten %d\nAufträge %d / %d · Seegebiete %d / %d" % [sim.level,_thousands(sim.xp),_thousands(sim.xp_required()),_thousands(int(sim.player.gold)),sim.kills,sim.elite_kills,sim.monster_kills,sim.loot_collected,mini(sim.quest_index,CONTENT.QUESTS.size()),CONTENT.QUESTS.size(),sim.visited.count(true),CONTENT.SEA_MAP_COUNT])
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

func _open_castles() -> void:
	if _tab("Kastelle")=="TALENTE":
		_banner_card(painted.nav_castles,"KAPITÄNSTALENTE","Drei Fachgebiete mit spürbaren Effekten. Die Punkte erhältst du durch Kapitänsstufen und kannst sie jederzeit vergeben.")
		_section("FREIE TALENTPUNKTE · %d" % sim.talent_points_available())
		var choices=_catalog_grid(3)
		for key: String in CONTENT.TALENT_KEYS:
			var talent_key: String=key
			var config: Dictionary=CONTENT.TALENTS[key]
			var stage: int=int(sim.talents[key])
			var tile=_catalog_tile(choices,_art(str(config.icon)),str(config.name).to_upper(),"%s · %s" % [str(config.role),str(config.effect)],"TALENT · STUFE %d/%d" % [stage,CONTENT.TALENT_MAX],Color("c9a35e") if stage>0 else Color("5e7683"))
			var gauge=_bar(tile)
			gauge.max_value=CONTENT.TALENT_MAX
			gauge.value=stage
			gauge.custom_minimum_size.y=12
			_note("Talentbonus: +%d %% → +%d %%" % [stage*2,mini(CONTENT.TALENT_MAX,stage+1)*2],Color("bde5d4"),tile)
			var talent_action: String="TALENT VOLLSTÄNDIG" if stage>=CONTENT.TALENT_MAX else ("KEINE TALENTPUNKTE" if sim.talent_points_available()<=0 else "PUNKT VERGEBEN")
			var upgrade=_catalog_action(tile,talent_action,func():
				sim.learn_talent(talent_key);_save_progress();_open_modal("Kastelle");_refresh_ui(),stage>=CONTENT.TALENT_MAX or sim.talent_points_available()<=0)
			upgrade.name="Talent_"+key
		_note("Talentvergabe ist weltweit möglich. Kastelle sind weiterhin stationäre Bauten und vorerst an den Hafen gebunden.",Color("a7cfc5"))
		return
	_banner_card(painted.nav_castles,"KASTELLE · DAUERHAFTE AUSBAUTEN","Sechs getrennte Bauzweige, freigeschaltet durch Kapitänsstufen. Bilder, Effekte, Ausbaustufe und Preis auf einer Karte.")
	var total: int=0
	for key: String in CONTENT.UPGRADE_KEYS:total+=int(sim.upgrades[key])
	_section("AUSBAUSTAND · %d/%d · FREI BIS STUFE %d" % [total,CONTENT.UPGRADE_KEYS.size()*CONTENT.CASTLE_MAX,sim.castle_cap()])
	if not sim.docked:_note("Kastelle werden vorerst nur am Hafen ausgebaut. Die Übersicht funktioniert überall.",Color("e1b979"))
	_note("Vorschau mit deiner aktuellen Ausrüstung. Ein Kauf verbessert jeweils genau eine Stufe.",Color("bde5d4"))
	var upgrades=_catalog_grid(3)
	for key: String in CONTENT.UPGRADE_KEYS:_upgrade_row(key,upgrades)
	_action("ZU DEN TALENTEN · %d PUNKTE FREI" % sim.talent_points_available(),func():_switch_tab("Kastelle","TALENTE"))
	var paths=_grid(2)
	if not sim.docked:_action("HAFEN & ANDOCKEN",func():_open_modal("Hafen"),"normal",paths)
	_action("DECKS & GESCHÜTZPLÄTZE",func():_open_modal("Decks"),"normal",paths)
	_action("WERFT & KANONEN",func():_switch_tab("Werft","KANONEN"),"normal",paths)

func _open_battle_pass() -> void:
	_banner_card(painted.nav_bonus,"SAISONPASS · FREIE BETA-SAISON","Spiele, sammle Fortschritt und hole kostenfreie Belohnungen ab. Die Premiumspur bleibt gesperrt, bis sichere Konten und Zahlungen existieren.")
	var current: int=sim.battle_pass_progress()
	var maximum: int=int(CONTENT.BATTLE_PASS_FREE.back().need)
	_section("DEIN SAISONFORTSCHRITT · %d / %d" % [current,maximum])
	var progress=_bar(modal_body)
	progress.max_value=maximum
	progress.value=min(current,maximum)
	progress.custom_minimum_size.y=15
	_section("KOSTENLOSE BELOHNUNGEN")
	var rewards=_catalog_grid(3)
	for i in CONTENT.BATTLE_PASS_FREE.size():
		var index: int=i
		var tier: Dictionary=CONTENT.BATTLE_PASS_FREE[i]
		var claimed: bool=sim.battle_pass_claimed.has(i)
		var unlocked: bool=current>=int(tier.need)
		var status: String="ABGEHOLT" if claimed else ("FREIGESCHALTET" if unlocked else "NOCH GESPERRT")
		var image: Texture2D=painted.reward_chest if i%2==0 else painted.gold_coins
		var tile=_catalog_tile(rewards,image,"STUFE %d · %s" % [i+1,str(tier.name).to_upper()],"%d Gold + %d Essenz" % [int(tier.gold),int(tier.essence)],"%d PUNKTE · %s" % [int(tier.need),status],Color("508d73") if claimed else (Color("bc9258") if unlocked else Color("5a6570")))
		var button=_catalog_action(tile,"ABGEHOLT" if claimed else ("KOSTENLOS ABHOLEN" if unlocked else "NOCH GESPERRT"),func():
			sim.claim_battle_pass_free(index);_save_progress();_open_modal("Battle Pass");_refresh_ui(),claimed or not unlocked)
		button.name="FreePassClaim"+str(i)
	_section("PREMIUMSPUR · ZUKÜNFTIG")
	_note("Kein aktives Abo oder Echtgeldkauf. Die Premium-Belohnungen erscheinen erst mit sicherer serverseitiger Freischaltung.")
	var disabled=_action("PREMIUM NOCH NICHT VERFÜGBAR",func():pass)
	disabled.disabled=true

func _upgrade_value(value: Variant,unit: String) -> String:
	if unit=="s":return ("%.2f s" % float(value)).replace(".",",")
	if unit=="m/s":return ("%.1f m/s" % float(value)).replace(".",",")
	return _thousands(int(value))+(" "+unit if not unit.is_empty() else "")

func _upgrade_row(key: String,parent: Node=null) -> void:
	var config: Dictionary=CONTENT.UPGRADES[key]
	var preview: Dictionary=sim.castle_upgrade_preview(key)
	var stage: int=int(preview.stage)
	var art_key: String=key+"_%d" % mini(2,stage) if key in ["cannon","harpoon"] else str(config.icon)
	var tile=_catalog_tile(parent,_art(art_key),str(config.name).to_upper(),"%s\n%s" % [str(config.role),str(config.effect)],"STUFE %d/%d" % [stage,CONTENT.CASTLE_MAX],Color("c9a35e") if stage>0 else Color("607785"))
	var comparison: Array[String]=[]
	for row: Dictionary in preview.rows:
		comparison.append("%s\n%s → %s" % [row.label,_upgrade_value(row.before,str(row.unit)),_upgrade_value(row.after,str(row.unit))])
	var values=_note("\n".join(comparison),Color("bde5d4"),tile)
	values.name="CastlePreview_"+key
	var progress=_bar(tile)
	progress.max_value=CONTENT.CASTLE_MAX;progress.value=stage;progress.custom_minimum_size.y=12
	var reason: String=str(preview.reason)
	var cost: int=int(preview.cost)
	if cost>=0:_note("Preis: %s Gold · Bestand: %s" % [_thousands(cost),_thousands(int(sim.player.gold))],GOLD,tile)
	var upgrade=_catalog_action(tile,reason if not reason.is_empty() else "VERBESSERN · %s Gold" % _thousands(cost),func():
		sim.buy_upgrade(key);_save_progress();_open_modal("Kastelle");_refresh_ui(),not bool(preview.can_upgrade))
	upgrade.name="CastleUpgrade_"+key
	upgrade.tooltip_text=reason if not reason.is_empty() else "Eine Stufe ausbauen; die Vorschau zeigt die daraus entstehenden Werte."


func _deck_title(deck: Dictionary) -> String:
	return "%sDECK · STUFE %d/%d" % [str(CONTENT.DECK_TIERS[int(deck.tier)]).to_upper(),int(deck.get("stage",1)),CONTENT.DECK_STAGE_MAX]

func _deck_effect(deck: Dictionary) -> String:
	return "+%d KANONENPLÄTZE · +%d RUMPF-HP · BETA-WERTE" % [sim.deck_cannon_bonus(int(deck.tier),int(deck.get("stage",1))),sim.deck_hp_bonus(int(deck.tier),int(deck.get("stage",1)))]

const DECK_ART := {"cannon":"cannon_1","armor":"upgrade_hull","hunter":"harpoon_1","navigation":"upgrade_sails","logistics":"castle_crew"}

func _open_selected_deck(index: int) -> void:
	if index<0 or index>=sim.decks.size():return
	focused_deck_index=index
	_switch_tab("Decks","LAGER")

## A fixed 3×5 progression map: stage, material and target promotion
## remain visible on compact phones without fifteen separate tall cards.
func _deck_progression_roadmap(info: Dictionary) -> void:
	_section("AUSBAUWEG · 15 STUFEN")
	var material_names: Array[String]=["GOLD","PERLEN","KRISTALL"]
	var roman: Array[String]=["I","II","III","IV","V"]
	for material in 3:
		var material_color: Color=CONTENT.DECK_TIER_COLORS[material]
		var row_panel: PanelContainer=_card(Color(material_color.r,material_color.g,material_color.b,.9))
		row_panel.name="DeckRoadmap_"+str(material_names[material])
		var column=VBoxContainer.new()
		column.add_theme_constant_override("separation",5)
		row_panel.add_child(column)
		var heading=_text(column,material_names[material]+" · STUFEN I–V",13,material_color)
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var path=GridContainer.new()
		path.columns=5
		path.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		path.add_theme_constant_override("h_separation",4)
		path.add_theme_constant_override("v_separation",4)
		column.add_child(path)
		for stage in CONTENT.DECK_STAGE_MAX:
			var rank: int=stage+1
			var complete: bool=material<int(info.tier) or (material==int(info.tier) and rank<int(info.stage))
			var current: bool=material==int(info.tier) and rank==int(info.stage)
			var upcoming: bool=not bool(info.maximum) and material==int(info.next_tier) and rank==int(info.next_stage)
			var tile: PanelContainer=_card(material_color if current else (Color(material_color.r,material_color.g,material_color.b,.35) if complete or upcoming else Color(0,0,0,0)),path)
			tile.name="DeckStage_%s_%d" % [material_names[material],rank]
			tile.custom_minimum_size=Vector2(0,49)
			tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			var number=_text(tile,roman[stage],14,Color("fff0c4") if current else (material_color if complete or upcoming else Color("687982")))
			number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			number.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			number.custom_minimum_size.y=32
			if current:tile.tooltip_text="Aktuell ausgebaut"
			elif upcoming:tile.tooltip_text="Nächstes Upgrade"
			elif complete:tile.tooltip_text="Bereits freigeschaltet"
			else:tile.tooltip_text="Spätere Deckstufe"

func _open_decks() -> void:
	_banner_card(painted.tide_deck,"10 STANDARDDECKS · 3 SONDERDECKS","Alle zehn normalen Decks sind identisch und frei kombinierbar. Gold I–V → Perlen I–V → Kristall I–V. Jedes montierte Deck bringt Kanonenplätze UND zusätzliche Rumpf-HP (Beta-Balance).")
	match _tab("Decks"):
		"SCHIFF":
			_section("DECKS AN DEINEM SCHIFF · %d/10" % (CONTENT.DECK_SLOT_COUNT-sim.deck_slots.count(-1)))
			var stage=Control.new()
			stage.name="DeckOverview"
			stage.custom_minimum_size=Vector2(0,143)
			stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
			stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			stage.draw.connect(func():
				stage.draw_style_box(SKIN.card(),Rect2(Vector2.ZERO,stage.size))
				SEA_MARKS.deck_badge(stage,Vector2(stage.size.x*.5,52),10.0,sim,elapsed)
				_canvas_text(stage,Vector2(stage.size.x*.5,108),"10 GLEICHE DECKS · ZWEI REIHEN MIT JE FÜNF",12,Color("ecd29a"))
				_canvas_text(stage,Vector2(stage.size.x*.5,129),"GOLD · PERLEN · KRISTALL",11,Color("c4d5db")))
			modal_body.add_child(stage)
			_start_deck_motion(stage)
			var tier_counts: Array[int]=[0,0,0]
			for deck_slot in sim.deck_slots:
				var index: int=int(deck_slot)
				if index<0 or index>=sim.decks.size():continue
				tier_counts[clampi(int(sim.decks[index].tier),0,2)]+=1
			_note("MONTIERT · %d GOLD / %d PERLEN / %d KRISTALL\nBONUS: +%d KANONENPLÄTZE · +%d RUMPF-HP" % [tier_counts[0],tier_counts[1],tier_counts[2],int(sim.deck_value("cannon")),sim.mounted_deck_hp()],Color("d4e6d9"))
			_section("DEIN DECKPLAN · 2 REIHEN MIT JE 5 PLÄTZEN")
			var compact_slots=GridContainer.new()
			compact_slots.name="DeckShipMatrix"
			compact_slots.columns=5
			compact_slots.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			compact_slots.add_theme_constant_override("h_separation",4)
			compact_slots.add_theme_constant_override("v_separation",6)
			modal_body.add_child(compact_slots)
			for slot in CONTENT.DECK_SLOT_COUNT:
				var place: int=slot
				var index: int=int(sim.deck_slots[slot])
				var mounted: bool=index>=0 and index<sim.decks.size()
				var label: String="%02d\nFREI" % (slot+1)
				if mounted:
					var deck: Dictionary=sim.decks[index]
					label="%02d\n%s %d" % [slot+1,["GOLD","PERL.","KRIST."][int(deck.tier)],int(deck.get("stage",1))]
				var focus_index: int=index
				var focus=_row_button(compact_slots,label,func():
					if focus_index>=0:_open_selected_deck(focus_index)
					else:_switch_tab("Decks","LAGER"),false,"primary" if mounted else "normal")
				focus.name="DeckSlotFocus"+str(slot)
				focus.custom_minimum_size=Vector2(45,70)
				focus.add_theme_font_size_override("font_size",12)
				focus.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				if mounted:
					var material_color: Color=CONTENT.DECK_TIER_COLORS[int(sim.decks[index].tier)]
					focus.add_theme_color_override("font_color",material_color)
					focus.add_theme_color_override("font_hover_color",material_color.lightened(.25))
			_note("TIPP AUF EINEN PLATZ: Öffnet genau dieses Deck mit Stufenplan, Materialwechsel, Kanonen- und HP-Bonus, Kosten und Montage.")
			_action("DECKS AUS LAGER MONTIEREN",func():_switch_tab("Decks","LAGER"))
			_section("OPTIONAL · MONTIERTE DECKS GEMEINSAM VERBESSERN")
			var fleet_preview: Dictionary=sim.deck_fleet_upgrade_preview()
			var bundle_count: int=int(fleet_preview.count)
			if bundle_count>0:
				_note("%d montierte Decks erhalten jeweils GENAU EINE Ausbaustufe. Keine Lagerdecks betroffen. Gesamtpreis: %d Gold%s. Bonus aus dem Upgrade: +%d Kanonenplätze UND +%d Rumpf-HP (Beta)." % [bundle_count,int(fleet_preview.gold),(" + %d Essenz" % int(fleet_preview.essence)) if int(fleet_preview.essence)>0 else "",int(fleet_preview.cannon_gain),int(fleet_preview.hp_gain)],Color("f1d19b"))
			else:
				_note("Noch keine aufwertbaren Standarddecks montiert.")
			var batch_button=_action("MONTIERTE DECKS · 1 STUFE JE DECK",func():
				if sim.upgrade_mounted_decks():
					_save_progress()
					_open_modal("Decks")
					_refresh_ui(),"primary")
			batch_button.name="DeckFleetUpgrade"
			batch_button.disabled=not bool(fleet_preview.can_upgrade)
			batch_button.tooltip_text="Erst prüfen: "+str(fleet_preview.reason) if not bool(fleet_preview.can_upgrade) else "Alle montierten Decks einmal verbessern; Kosten werden zusammen abgezogen"
		"LAGER":
			_section("DECKWERFT · %d/%d EXEMPLARE" % [sim.decks.size(),CONTENT.DECK_INVENTORY_MAX])
			if not sim.docked:_note("Deckmontage und Upgrades sind nur im Hafen möglich.",Color("e1b979"))
			if sim.decks.is_empty():
				_note("Du hast noch keine Decks. Kaufe ein Golddeck, um einen der zehn Plätze zu bestücken.")
				_action("ERSTES GOLDDECK KAUFEN",func():_switch_tab("Decks","KAUFEN"))
			else:
				if focused_deck_index<0 or focused_deck_index>=sim.decks.size():
					focused_deck_index=0
					for mounted_index in sim.deck_slots:
						if int(mounted_index)>=0 and int(mounted_index)<sim.decks.size():
							focused_deck_index=int(mounted_index)
							break
				_section("MONTIERTE DECKS · PLATZ ANTIPPEN")
				var quick=GridContainer.new()
				quick.name="DeckSlotSelector"
				quick.columns=5
				quick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				quick.add_theme_constant_override("h_separation",4)
				quick.add_theme_constant_override("v_separation",5)
				modal_body.add_child(quick)
				for slot in CONTENT.DECK_SLOT_COUNT:
					var deck_index: int=int(sim.deck_slots[slot])
					var tag: String="FREI"
					if deck_index>=0 and deck_index<sim.decks.size():
						var material: int=int(sim.decks[deck_index].tier)
						tag=["GOLD","PERLEN","KRIST."][material]+" "+str(int(sim.decks[deck_index].get("stage",1)))
					var slot_number: int=slot
					var picker_button=_row_button(quick,"%02d\n%s" % [slot+1,tag],func():
						var found: int=int(sim.deck_slots[slot_number])
						if found>=0:_open_selected_deck(found)
						else:_switch_tab("Decks","LAGER"),deck_index<0,"primary" if deck_index==focused_deck_index else "normal")
					picker_button.name="DeckSlotSelect"+str(slot)
					picker_button.custom_minimum_size=Vector2(45,65)
					picker_button.add_theme_font_size_override("font_size",12)
					picker_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				var index: int=focused_deck_index
				var deck: Dictionary=sim.decks[index]
				var info: Dictionary=sim.deck_upgrade_info(index)
				var current_slot: int=sim.deck_slots.find(index)
				var next_name: String="MAXIMAL AUSGEBAUT" if bool(info.maximum) else "%sDECK STUFE %d" % [str(CONTENT.DECK_TIERS[int(info.next_tier)]).to_upper(),int(info.next_stage)]
				_section("AUSGEWÄHLT · DECK %02d" % (index+1))
				var status: String="MONTIERT AUF PLATZ %02d" % (current_slot+1) if current_slot>=0 else "IM LAGER · NOCH NICHT MONTIERT"
				var description: String="JETZT: %s · +%d Kanonenplätze · +%d HP\nNÄCHSTES: %s · +%d Kanonenplätze · +%d HP" % [_deck_title(deck),int(info.cannons_now),int(info.hp_now),next_name,int(info.cannons_next),int(info.hp_next)]
				var tile=_catalog_tile(modal_body,deck_icons.cannon,"STANDARDDECK %02d" % (index+1),description,status,CONTENT.DECK_TIER_COLORS[int(deck.tier)])
				var progress=_bar(tile)
				progress.name="DeckLevelProgress"+str(index)
				progress.max_value=CONTENT.DECK_STAGE_MAX
				progress.value=int(info.stage)
				progress.custom_minimum_size.y=16
				var now_vs_next=_note("%s  →  %s" % [_deck_title(deck),next_name],CONTENT.DECK_TIER_COLORS[int(info.next_tier)],tile)
				now_vs_next.name="DeckNextPreview"+str(index)
				if bool(info.maximum):
					var max_button=_catalog_action(tile,"KRISTALL V · VOLLSTÄNDIG AUSGEBAUT",func():pass,true)
					max_button.name="DeckMax"+str(index)
				else:
					var price: String="%d GOLD%s" % [int(info.gold),(" + %d ESSENZ" % int(info.essence)) if int(info.essence)>0 else ""]
					var gain: int=int(info.cannons_next)-int(info.cannons_now)
					var hp_gain: int=int(info.hp_next)-int(info.hp_now)
					var hint: String="MATERIALWECHSEL" if bool(info.promoting) else "NÄCHSTE STUFE"
					var upgrade=_catalog_action(tile,"%s: %s · +%d KANONEN · +%d HP · %s" % [hint,next_name,gain,hp_gain,price],func():
						if sim.upgrade_deck(index):
							_save_progress()
							_open_modal("Decks")
							_refresh_ui(),not sim.docked or sim.level<int(info.captain_level) or int(sim.player.gold)<int(info.gold) or sim.essence<int(info.essence))
					upgrade.name="DeckUpgrade"+str(index)
					upgrade.tooltip_text="Ab Kapitänsstufe %d · Kanonen- und HP-Werte vorläufig" % int(info.captain_level)
				var choice=OptionButton.new()
				choice.name="DeckSlotPicker"+str(index)
				choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				choice.custom_minimum_size.y=50
				choice.add_theme_font_size_override("font_size",14)
				for deck_slot in CONTENT.DECK_SLOT_COUNT:
					var occupant: int=int(sim.deck_slots[deck_slot])
					choice.add_item("Platz %02d%s" % [deck_slot+1," · BELEGT / AUSTAUSCH" if occupant>=0 and occupant!=index else ""])
				choice.select(current_slot if current_slot>=0 else maxi(0,sim.deck_slots.find(-1)))
				tile.add_child(choice)
				var equip=_catalog_action(tile,"AUFS SCHIFF MONTIEREN / UMSETZEN",func():
					if sim.equip_deck(index,choice.selected):
						_save_progress()
						_open_modal("Decks")
						_refresh_ui(),not sim.docked)
				equip.name="DeckEquip"+str(index)
				if current_slot>=0:
					var remove=_catalog_action(tile,"DECK VON SCHIFF ABBAUEN",func():
						if sim.unequip_deck(current_slot):
							_save_progress()
							_open_modal("Decks")
							_refresh_ui(),not sim.docked)
					remove.name="DeckRemove"+str(current_slot)
				_deck_progression_roadmap(info)
				_section("WEITERE DECKS IM LAGER")
				var spare_list=_grid(2)
				var spare_count:=0
				for other in sim.decks.size():
					if sim.deck_slots.has(other):continue
					spare_count+=1
					var other_index: int=other
					var entry: Dictionary=sim.decks[other]
					var item=_row_button(spare_list,"DECK %02d · %s STUFE %d" % [other+1,CONTENT.DECK_TIERS[int(entry.tier)].to_upper(),int(entry.get("stage",1))],func():_open_selected_deck(other_index),false,"primary" if other==focused_deck_index else "normal")
					item.name="DeckReserve"+str(other)
					item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				if spare_count==0:_note("Keine weiteren Decks auf Lager. Alle erworbenen Decks sind montiert.")
				_action("NEUE GOLDDECKS KAUFEN",func():_switch_tab("Decks","KAUFEN"))
		"SPEZIAL":
			_section("DREI SONDERDECKS · AUSSERHALB DER 10 PLÄTZE")
			_note("Gezeitendeck, Runendeck und Korsarendeck wirken zusätzlich. Sie belegen niemals einen der zehn normalen Deckplätze.")
			var special=_catalog_grid(3)
			var tide: float=float(sim.buffs.tide_deck)
			var tide_tile=_catalog_tile(special,deck_icons.tide,"GEZEITENDECK","+10 Kanonenplätze bei Aktivierung","AKTIV · %s" % _clock_text(tide) if tide>0 else "AUS DEM GEZEITENKESSEL",SEA_MARKS.DECK_COLORS.tide)
			_catalog_action(tide_tile,"ZUM GEZEITENKESSEL",func():_open_modal("Kessel"))
			for key: String in CONTENT.SPECIAL_DECKS:
				var deck_key: String=key
				var config: Dictionary=CONTENT.SPECIAL_DECKS[key]
				var left: float=float(sim.buffs[key])
				var kessel_only: bool=str(config.get("source","market"))=="kessel"
				var status_text: String="AKTIV · %s" % _clock_text(left) if left>0 else ("AUS DEM GEZEITENKESSEL" if kessel_only else "30 MIN · %d GOLD" % int(config.price))
				var tile=_catalog_tile(special,deck_icons[key.trim_suffix("_deck")],str(config.name).to_upper(),str(config.effect),status_text,config.color)
				if kessel_only:
					var link=_catalog_action(tile,"IM KESSEL GEWINNEN",func():_open_modal("Kessel"))
					link.name="SpecialDeck_"+key
				else:
					var buy=_catalog_action(tile,"AKTIVIEREN" if sim.level>=int(config.level) else "AB STUFE %d" % int(config.level),func():
						sim.buy_special_deck(deck_key);_save_progress();_open_modal("Decks");_refresh_ui(),not sim.docked or sim.level<int(config.level) or int(sim.player.gold)<int(config.price))
					buy.name="SpecialDeck_"+key
			_section("SEGEN & GUNST · GETRENNT VON DEN 13 DECKS")
			var blessing=_catalog_tile(modal_body,deck_icons.blessing,"KRISTALLSEGEN","Ein eigenständiger zeitlich begrenzter Schiffsbonus, kein zusätzliches Deck.","AKTIV · %s" % _clock_text(float(sim.buffs.blessing)) if sim.has_blessing() else "AUS DEM GEZEITENKESSEL",Color("b881e3"))
			_catalog_action(blessing,"ZUM KESSEL",func():_open_modal("Kessel"))
			_note("Weitere eigenständige Segnungen, beispielsweise Königsgunst, können wir später ergänzen. Es wird dafür aktuell kein Bonus vorgetäuscht.")
		"KAUFEN":
			_section("STANDARDDECK · GOLD STUFE I")
			_note("Es gibt nur eine normale Deckart. Du darfst mehrere gleiche Golddecks erwerben und jedes einzeln ausbauen: Gold I–V → Perlen I–V → Kristall I–V.")
			var yard=_catalog_grid(2)
			var config: Dictionary=CONTENT.DECKS.cannon
			var tile=_catalog_tile(yard,deck_icons.cannon,"GOLDDECK · STUFE I","+%d Kanonenplätze UND +%d Rumpf-HP je montiertes Deck · Beta-Werte" % [sim.deck_cannon_bonus(0,1),sim.deck_hp_bonus(0,1)],"%d GOLD PRO DECK" % int(config.price),CONTENT.DECK_TIER_COLORS[0])
			var buy=_catalog_action(tile,"EIN GOLDDECK KAUFEN",func():
				if sim.buy_deck("cannon"):
					focused_deck_index=sim.decks.size()-1
					_save_progress()
					_switch_tab("Decks","LAGER")
					_refresh_ui(),not sim.docked or sim.decks.size()>=CONTENT.DECK_INVENTORY_MAX or int(sim.player.gold)<int(config.price))
			buy.name="DeckBuy_cannon"
			if not sim.docked:_note("Deckkauf und -umbau vorerst nur im Hafen möglich.",Color("e1b979"))
		_:
			_note("Wähle SCHIFF, LAGER, SPEZIAL oder KAUFEN.")

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
		var pack=" ×%d" % int(entry.amount) if int(entry.amount)>1 and str(entry.id) not in ["tide_deck","storm_deck"] else ""
		var label=_note("%d %% · %s%s · %s" % [entry.weight,entry.name,pack,CONTENT.RARITIES[int(entry.rarity)]],RARITY_INK[int(entry.rarity)],table)
		label.add_theme_font_size_override("font_size",13)
	_note("Mehrere identische Decks sind ausdrücklich erlaubt. Nur bei vollem Decklager gibt es für weitere Deckfunde %d Essenz." % CONTENT.DUPLICATE_DECK_ESSENCE,Color("84999c"))

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
		"storm_deck":return deck_icons.storm
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
		if sim.in_bonus_map():_row_button(column,"BONUSKARTE VERLASSEN",func():_close_modal();_interact(),false,"danger")
	var tints=[Color("cd8a4c"),Color("c9d2d6"),Color("ffd27a")]
	for i in CONTENT.BONUS_TIERS.size():
		var index=i
		var tier: Dictionary=CONTENT.BONUS_TIERS[i]
		var region: Dictionary=CONTENT.MAPS[int(tier.map)]
		var running=not sim.bonus.is_empty() and int(sim.bonus.tier)==i
		var pieces: int=int(sim.bonus_pieces[i])
		var need: int=int(tier.fragments)
		var column=_row(painted.scroll_fragment,"%s-BONUSKARTE · %s %s\nAb Lv. %d · Gegnerstärke ×%s · Teile %d/%d · Schriftrollen %d" % [str(tier.name).to_upper(),region.name,region.code,tier.level,str(region.enemy_scale).replace(".",","),pieces,need,sim.scrolls[i]],64,tints[i])
		# Map board uses real parchment fragment art, not placeholder diamonds.
		# Five tiles per row remain usable on compact phone panels.
		var progress=GridContainer.new()
		progress.columns=5
		progress.add_theme_constant_override("h_separation",6)
		progress.add_theme_constant_override("v_separation",6)
		progress.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_child(progress)
		progress.name="BonusFragments"+str(tier.name)
		for part in need:
			var filled: bool=part<pieces
			var slot=_picture(progress,painted.scroll_fragment,32,true)
			slot.modulate=Color(1,1,1,1) if filled else Color(.42,.48,.48,.32)
			slot.tooltip_text="%s · Kartenteil %d/%d · %s" % [tier.name,part+1,need,"gefunden" if filled else "fehlt"]
		var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",6);column.add_child(buttons)
		_row_button(buttons,"TEIL EINSETZEN",func():sim.assign_bonus_piece(index);_save_progress();_open_modal("Bonuskarten");_refresh_ui(),sim.fragments<=0 or pieces>=need)
		_row_button(buttons,"ZUSAMMENSETZEN",func():sim.craft_scroll(index);_save_progress();_open_modal("Bonuskarten");_refresh_ui(),pieces+sim.fragments<need)
		var blocked=sim.in_bonus_map() or sim.level<int(tier.level) or (not running and (int(sim.scrolls[i])<=0 or not sim.bonus.is_empty()))
		_row_button(buttons,"FORTSETZEN" if running else ("AB LV. %d" % tier.level if sim.level<int(tier.level) else "STARTEN"),func():_start_bonus(index),blocked,"primary")
	_section("WELLEN")
	var waves=_grid(5)
	for i in CONTENT.BONUS_WAVES.size():
		var wave: Dictionary=CONTENT.BONUS_WAVES[i]
		var card=_card(Color("ff6a4d") if not str(wave.boss).is_empty() else Color(0,0,0,0),waves)
		_text(card,"%d · %s" % [i+1,wave.label],13,Color("fff0c8"))
	_note("Jede Welle zahlt Gold und 1 Gezeitenessenz. Die Truhe am Ende enthält Pulver, Platten, eine Notreparatur, einen Kristallsegen und ein Deck der Kartenstufe.\nKein Lebenssystem: Wirst du versenkt, geht es nach 8 Sekunden an derselben Welle weiter. Verlassen speichert die aktuelle Welle.")
	_note("Kartenteile erhältst du im Gezeitenkessel und als Spielbelohnungen. Wähle aus, für welche Bonuskarte du ein gefundenes Fragment einsetzt. Bisherige Fragmente bleiben erhalten; Belohnungen passen wir später an.",Color("84999c"))

func _start_bonus(tier: int) -> void:
	# Failed starts must never undock the captain or hide the menu.
	var issue: String=sim.bonus_entry_issue(tier)
	if not issue.is_empty():
		sim.message=issue
		_refresh_ui()
		return
	if sim.docked:sim.depart()
	if not sim.start_bonus(tier):
		_refresh_ui()
		return
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

func _open_guild_home() -> void:
	var tier: int=sim.guild_home_tier()
	var tier_name: String=str(CONTENT.GUILD_HOME_TIERS[tier-1])
	var treasury: int=int(sim.guild_home.get("treasury",0))
	var capacity: int=sim.guild_treasury_capacity()
	var upgrade_cost: int=sim.guild_home_upgrade_cost()
	_section("DAUERHAFTE GILDENHEIMAT · STUFE %d/5" % tier)
	_row(painted.nav_guild,"[%s] %s · %s\nUnabhängig von eroberten Weltinseln" % [sim.guild.tag,sim.guild.name,tier_name],60,Color("b9dcce"))
	_note("Diese Heimatbasis bleibt auch erhalten, wenn deine Gilde die umkämpfte Korsarenfestung verliert. Das ist die eigene lokale Basis gemäß Masterkonzept V3.8; eine befahrbare instanzierte 3D-/2,5D-Insel und Online-Mitgliederrechte werden separat umgesetzt.")
	_section("GILDENKASSE · %s / %s GOLD" % [_thousands(treasury),_thousands(capacity)])
	_note("Einzahlungen und Auszahlungen verschieben vorhandenes Gold zwischen deinem Kapitän und der Gildenkasse. Es wird kein Gold erzeugt. Erweiterungen werden aus der Kasse bezahlt.",Color("b0cdcf"))
	var cash=_grid(2)
	for value in [100,500,2000]:
		var amount: int=value
		var deposit=_action("+ %s GOLD EINZAHLEN" % _thousands(amount),func():
			sim.guild_deposit(amount)
			_save_progress();_open_modal("Gilde");_refresh_ui(),"normal",cash)
		deposit.disabled=int(sim.player.gold)<amount or treasury+amount>capacity
		var withdraw=_action("− %s GOLD ENTNEHMEN" % _thousands(amount),func():
			sim.guild_withdraw(amount)
			_save_progress();_open_modal("Gilde");_refresh_ui(),"normal",cash)
		withdraw.disabled=treasury<amount or int(sim.player.gold)+amount>99999999
	_section("AUSBAU DER HEIMATBASIS")
	if upgrade_cost>0:
		var next_name: String=str(CONTENT.GUILD_HOME_TIERS[tier])
		var upgrade=_primary("AUF STUFE %d · %s · %s GOLD" % [tier+1,next_name,_thousands(upgrade_cost)],func():
			sim.guild_upgrade_home()
			_save_progress();_open_modal("Gilde");_refresh_ui())
		upgrade.disabled=treasury<upgrade_cost
		_note("Neuer Gildenkassen-Höchstbetrag: %s Gold. Ausbaukosten und Stufenwerte sind Beta-Balancing." % _thousands(int(CONTENT.GUILD_HOME_TREASURY_CAPS[tier])),Color("9dd9c6"))
	else:
		_info("MAXIMALE BASISSTUFE ERREICHT · Souveräne Festung")
	_note("Einrichtungen des Masterplans: Gildenhalle, Lagerhaus, Werft, Arsenal, Leuchtturm, Marktsteg, Jägerloge und Kriegsraum. Weitere Gebäudefunktionen und Mitgliederrechte sind noch nicht freigeschaltet.",Color("819da0"))
	_action("ZUR WELTINSEL & BELAGERUNG",func():_switch_tab("Gilde","WELTINSEL"))
	
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
		if _tab("Gilde")=="HEIMATBASIS":
			_open_guild_home()
			return
		_row(painted.nav_guild,"[%s] %s\nAnführer: du (lokal)" % [sim.guild.tag,sim.guild.name],48,Color("ffd27a"))
	if _tab("Gilde")=="HEIMATBASIS":
		_note("Gründe eine Gilde, um eine eigene dauerhafte Heimatbasis, Ausbaustufen und die Gildenkasse freizuschalten.")
		return
	_section("GILDENINSEL · KORSARENFESTUNG")
	var status: Array[Dictionary]=sim.guild_tower_status()
	var state: String=""
	if sim.tower_friendly():
		state="[%s] verteidigt die Insel · noch %s · +10 %% Beutegold" % [sim.tower_tag(),_clock_text(sim.fortress_hold)]
	elif CONTENT.has_guild_island(sim.map_id):
		state="Belagerung [%s] · %d / %d Türme zerstört" % [sim.guild_owner_tag(sim.map_id),CONTENT.TOWERS.size()-sim.towers_alive(),CONTENT.TOWERS.size()]
	else:
		state="Schattengewässer %s · ab Lv. %d · Festung [%s]" % [CONTENT.MAPS[CONTENT.FORTRESS_MAP].code,CONTENT.MAPS[CONTENT.FORTRESS_MAP].level,sim.guild_owner_tag(CONTENT.FORTRESS_MAP)]
	_info(state)
	# A real-time siege board: each defense is separately destructible and
	# shows its own HP, shield, level and rebuild countdown. No fake towers
	# remain in the island backdrop after they are destroyed.
	var towers=_grid(2)
	for i in CONTENT.TOWERS.size():
		var spec: Dictionary=CONTENT.TOWERS[i]
		var report: Dictionary=status[i] if i<status.size() else {}
		var alive: bool=bool(report.get("alive",false))
		var accent: Color=Color("477c5e") if alive and sim.tower_friendly() else (Color("aa7049") if alive else Color("544c4a"))
		var card=_card(accent,towers)
		var column=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(column)
		column.add_theme_constant_override("separation",4)
		_picture(column,TOWER_TEXTURES[str(spec.kind)],48,false)
		var label=_text(column,"%02d · %s" % [i+1,str(spec.name)],12,Color("fff0c8"))
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if not report.is_empty():
			var line: String="STUFE %d · HP %d/%d · SCHILD %d" % [int(report.level),int(report.hp),int(report.max_hp),int(report.shield)] if alive else ("ZERSTÖRT · BIS ZUR EROBERUNG" if bool(report.get("siege_locked",false)) else "ZERSTÖRT · WIEDERAUFBAU IN %d s" % ceili(float(report.respawn)))
			var health=_text(column,line,11,Color("a6d7b5") if alive and sim.tower_friendly() else (Color("f3bd7b") if alive else Color("df9184")))
			health.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			health.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			var gauge=_bar(column)
			gauge.max_value=float(report.max_hp)
			gauge.value=float(report.hp)
			gauge.custom_minimum_size.y=8
		else:
			var preview=_text(column,"STATUS AUF DER SEEKARTE",11,Color("84999c"))
			preview.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var defended: Array[String]=[]
	for sea_id: int in CONTENT.SEA_MAP_IDS:
		if sim.guild_holding_remaining(sea_id)>0:
			defended.append("%s · %s" % [CONTENT.MAPS[sea_id].code,_clock_text(sim.guild_holding_remaining(sea_id))])
	if not defended.is_empty():_note("Eigene Gildeninseln: "+", ".join(defended),Color("a6d7b5"))
	_note("Kanonenturm: Doppelschuss · Mörserturm: weite Bögen · Kettenturm: bremst · Wächterturm: Schildaufladung. Mit eigener Gilde bleiben zerstörte feindliche Türme während der Belagerung ausgeschaltet, bis alle zwölf gefallen sind. Danach übernimmt deine Gilde die Insel. Der Innenhafen bleibt befahrbar.")
	_note("Eroberungen %d · zerstörte Türme %d" % [sim.fortress_conquests,sim.tower_kills],Color("ffd27a"))
	if CONTENT.has_guild_island(sim.map_id):
		var passage: Dictionary=sim.guild_harbor_waypoints()
		var courses=_grid(2)
		var entrance=_primary("KURS ZUR EINFAHRT",func():
			if sim.course(Vector2(passage.mouth)):_close_modal()
			_refresh_ui(),courses)
		entrance.disabled=sim.docked
		var harbor_course=_primary("KURS IN DEN INNENHAFEN",func():
			if sim.course(sim.harbor):_close_modal()
			_refresh_ui(),courses)
		harbor_course.disabled=sim.docked
	else:
		var travel=_primary("KURS SCHATTENGEWÄSSER",func():_navigate_region(CONTENT.FORTRESS_MAP))
		travel.disabled=sim.docked or sim.in_bonus_map() or sim.level<int(CONTENT.MAPS[CONTENT.FORTRESS_MAP].level)
	if sim.tower_friendly() and CONTENT.has_guild_island(sim.map_id):
		_section("GILDENTÜRME AUSBAUEN · MAXIMAL STUFE 5")
		for i in CONTENT.TOWERS.size():
			var tower_index: int=i
			var tier: int=int(sim.tower_levels[i])
			var cost: int=300*tier*tier
			var upgrade=_action("%s · STUFE %d · %s" % [CONTENT.TOWERS[i].name,tier,"MAX" if tier==5 else str(cost)+" GOLD"],func():sim.upgrade_guild_tower(tower_index);_save_progress();_open_modal("Gilde"))
			upgrade.disabled=tier>=5 or int(sim.player.gold)<cost
	if not sim.guild.is_empty():_action("GILDE AUFLÖSEN",func():sim.leave_guild();_save_progress();_open_modal("Gilde");_refresh_ui(),"danger")

# --- Sea charts and the chart guide -----------------------------------------------------------

func _open_charts() -> void:
	if _tab("Seekarten")=="ANLEITUNG":
		_open_chart_guide()
		return
	_section("40 SEEKARTEN · 1/1 BIS 20/2")
	# -1 is the complete overview, not an invalid page.
	var leaves=_grid(5)
	_action("ALLE 40",func():chart_chapter=-1;chart_pick=sim.map_id;_open_modal("Seekarten"),"tab_on" if chart_chapter==-1 else "normal",leaves)
	for leaf in 4:
		var pick: int=leaf
		_action("%d–%d" % [leaf*5+1,leaf*5+5],func():chart_chapter=pick;chart_pick=CONTENT.SEA_MAP_IDS[pick*10];_open_modal("Seekarten"),"tab_on" if leaf==chart_chapter else "normal",leaves)
	var chart=WORLD_CHART.new()
	chart.name="WorldChart"
	chart.sim=sim;chart.parchment=painted.chart_parchment;chart.font=font
	chart.selected=chart_pick if chart_pick>=0 else sim.map_id
	chart.chapter=chart_chapter
	chart.custom_minimum_size=Vector2(0,1190 if chart_chapter==-1 else (440 if modal.size.x>=640 else 390))
	chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chart.picked.connect(func(index: int):chart_pick=index;_open_modal("Seekarten"))
	modal_body.add_child(chart)
	_note("Alle 40 Karten stehen in der Übersicht in zwei Spuren. Nach unten scrollen; mit 1–5, 6–10, 11–15 oder 16–20 einen Abschnitt vergrößern.",Color("84999c"))
	_chart_details(chart.selected)

func _chart_details(index: int) -> void:
	var staff=sim.staff
	if index==WORLD_CHART.FORTRESS_NODE:
		var owner: String=sim.guild_owner_tag(CONTENT.FORTRESS_MAP)
		var column=_row(painted.tower_guardian,"KORSARENFESTUNG · IN %s %s\nGehalten von [%s] · %d Türme · ab Lv. %d" % [CONTENT.MAPS[CONTENT.FORTRESS_MAP].code,CONTENT.MAPS[CONTENT.FORTRESS_MAP].name,owner,CONTENT.TOWERS.size(),CONTENT.MAPS[CONTENT.FORTRESS_MAP].level],64,Color("ff6a4d"))
		var line=HBoxContainer.new();line.add_theme_constant_override("separation",6);column.add_child(line)
		_row_button(line,"GILDE & FESTUNG",func():_open_modal("Gilde"))
		if staff.active():_row_button(line,"STAFF-TELEPORT",func():_staff(func():sim.staff_teleport(CONTENT.FORTRESS_MAP,"fortress"),true),not staff.can("map" if not CONTENT.has_guild_island(sim.map_id) else "teleport"),"staff")
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
		lines.append("Kein Hafen, keine Randübergänge · Ausgang über BONUSKARTE VERLASSEN")
	else:
		var exits: Array[String]=[]
		for neighbor in CONTENT.sea_neighbors(index):exits.append(str(CONTENT.MAPS[neighbor].code))
		lines.append("Hafen: ja · Nachbarkarten: "+", ".join(exits))
		lines.append("Patrouillen, Elite-Schiffe und Seeungeheuer · Gegnerstärke ×%s" % str(region.enemy_scale).replace(".",","))
		if CONTENT.has_guild_island(index):
			lines.append("Gildeninsel mit 12 Türmen · Eigentümer [%s]" % sim.guild_owner_tag(index))
	var column=_row(extra_icons.world_chart,"\n".join(lines),64,Color("a02818") if hostile else Color("2f6b3a"))
	var line=HBoxContainer.new();line.add_theme_constant_override("separation",6);column.add_child(line)
	if bonus:
		_row_button(line,"BONUSKARTEN",func():_open_modal("Bonuskarten"))
	elif index==sim.map_id:
		_row_button(line,"DU BIST HIER",func():pass,true)
	else:
		var text="GESPERRT · LV. %d" % region.level if locked else ("KARTE WECHSELN" if sim.near_portal()==index else "KURS ZUM KARTENRAND")
		_row_button(line,text,func():_navigate_region(CONTENT.next_sea_on_route(sim.map_id,index)),locked or sim.docked or sim.in_bonus_map(),"primary")
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
	_section("KARTENRÄNDER & ÜBERFAHRT")
	_note("Die gesamte markierte Kartenkante führt in die jeweilige Nachbarkarte. Einfach an den Rand fahren: Du kommst auf der gegenüberliegenden Seite an derselben Querposition an. Osten/Westen verbindet 1 bis 20; Süden führt von Reihe /1 nach /2, Norden zurück. Graue Ränder sind Weltgrenzen, goldene Ränder benötigen eine höhere Kapitänsstufe. Nach einem Treffer wartet die Überfahrt 6 Sekunden. Die Weltkarte kann einen Kurs zum passenden Rand setzen.")
	_section("HAFEN & ANDOCKEN")
	_note("Das goldene Anker-Symbol markiert den Hafen. Innerhalb von 160 m und nach 6 Sekunden ohne Treffer kannst du andocken: Trockendock, vorläufige Kastellausbauten, Deckwerft und Gezeitenkessel. Markt, Munition, Items und Talente sind überall über die Menüs erreichbar. Kanonenmontage geht auch auf See außerhalb von Gefechten. Angedockt bist du geschützt; ABLEGEN bringt dich zurück auf See.")
	_section("NEUTRAL ODER FEINDLICH")
	_note("In neutralen Gewässern greifen Patrouillen erst an, wenn du sie beschießt. In feindlichen Gewässern eröffnen sie in der Nähe von selbst das Feuer. Die Farbe des Namens verrät es:")
	_guide("colors")
	_section("BONUSKARTEN & FESTUNG")
	_note("Bonuskarten B-1 bis B-3 erreichst du mit vollständig zusammengesetzten Karten aus Fragmenten. Fünf Wellen, Checkpoint nach jeder Welle, Truhe am Ende. Die Korsarenfestung auf 3/1 hat zwölf Türme und einen befahrbaren Innenhafen.")
	_section("MINIKARTE · LEGENDE")
	_guide("legend")
	_section("STEUERUNG AUF DER KARTE")
	_note("Freies Wasser: Kurs setzen. Gegner einmal antippen: nur anvisieren. FEUER bewusst drücken, STOPP beendet das Schießen. Doppel-Tipp-Angriff ist standardmäßig AUS und unter Anzeige > Steuerung zuschaltbar. Abwählen über ×/Esc. Minikarte: Kurs setzen. Joystick bewegt nur die Kamera. Zwei Finger oder Mausrad: Zoom.")

func _guide(mode: String) -> void:
	var diagram=CHART_GUIDE.new()
	diagram.mode=mode;diagram.font=font
	diagram.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_body.add_child(diagram)

# --- Display settings and game info -------------------------------------------------------

func _active_data_revision() -> int:
	var boot=get_tree().root.get_node_or_null("DataBoot")
	if boot!=null:return int(boot.active_revision)
	var file="res://assets/content_version.json"
	if FileAccess.file_exists(file):
		var data=JSON.parse_string(FileAccess.get_file_as_string(file))
		if data is Dictionary:return int(data.get("revision",0))
	return 0

func _open_display() -> void:
	_banner_card(hud_icons.gear,"ANZEIGE & HUD","Classic 2D: vier echte schräge Fahrtrichtungen und kurze Wechsel entlang des Kurses. 2,5D / 3D: normale direkte Steuerung mit 3D-Grafik.")
	_note("DATENUPDATE %d · CLASSIC 2D · 12 WERFT-DESIGNS" % _active_data_revision() if browser_classic else "DATENUPDATE %d · 11 GLB-RESSOURCEN · 12 WERFT-DESIGNS · %s" % [_active_data_revision(),render_mode.to_upper()],Color("97e0d5"))
	if _tab("Anzeige")=="GRAFIK":
		if OS.has_feature("web"):
			_section("BROWSER CLASSIC · 2D")
			_note("AKTIV · Originale 2D-Schiffsgrafiken, ruhiges Meeresmuster, keine 3D-Szene und kein WebGL-3D-Schattenpass.",Color("a1dacf"))
			_note("FPS: %d · Schiffe: 2D · 3D-Berechnung: AUS" % Engine.get_frames_per_second(),Color("f1d39a"))
			_note("Die Werft, Seekarten, Decks, Kämpfe und Steuerung funktionieren mit derselben Spielmechanik. 3D gibt es weiterhin in der APK/Desktop-Version.")
		else:
			_section("GRAFIKMODUS")
			for option in [["classic","CLASSIC 2D"],["hybrid","2,5D / HYBRID"],["3d","3D"]]:
				var key: String=str(option[0])
				var choice=_action(str(option[1])+(" · AKTIV" if render_mode==key else ""),func():_set_render_mode(key),"tab_on" if render_mode==key else "normal")
				choice.disabled=render_mode==key
			_note("Classic 2D: NE/SE/SW/NW sind echte kurze diagonale Fahrabschnitte. Die Abweichung vom gesetzten Kurs bleibt klein. 2,5D/3D fahren wieder direkt; beim Wechsel bleiben aktuelle Position und Ziel erhalten.")
		_section("SCHIFFE & SEEKARTE")
		var ship_grid=_grid(2)
		_action("SCHIFFSBEWEGUNG: "+("EIN" if ship_animations_enabled else "AUS"),func():_set_ship_visual_toggle("motion"),"tab_on" if ship_animations_enabled else "normal",ship_grid)
		_action("KIELWASSER: "+("EIN" if wake_effects_enabled else "AUS"),func():_set_ship_visual_toggle("wake"),"tab_on" if wake_effects_enabled else "normal",ship_grid)
		_note("Schaukeln, Rollen und Wasserspuren lassen sich separat deaktivieren. Kurs, Kollision und Kampflogik bleiben unverändert.",Color("a3c9cf"))
	if _tab("Anzeige")=="STEUERUNG":
		_section("KAMPFSTEUERUNG · ANTIPPEN")
		_note("Standard: Gegner antippen wählt nur das Ziel, niemals automatisch feuern. FEUER startet den Angriff, STOPP beendet ihn. Optional kannst du einen bewusst gesetzten Doppeltipp als Angriff aktivieren. Mit × oder Esc das Ziel vollständig abwählen.",Color("a3c9cf"))
		var double_grid=_grid(2)
		_action("DOPPELTIPP-ANGRIFF: "+("EIN" if double_tap_attack_enabled else "AUS · SICHER"),_toggle_double_tap_attack,"tab_on" if double_tap_attack_enabled else "normal",double_grid)
		_section("KLASSISCHE SEEKARTEN-NAVIGATION")
		var touch_layout: bool=_is_mobile_hud(get_viewport_rect().size,OS.has_feature("mobile") or DisplayServer.is_touchscreen_available())
		if touch_layout:
			_note("HANDY / TABLET: Schiff und Ziele direkt antippen. Kamera per Wischen oder Kamerapad verschieben, Ziel über × abwählen, Munition und Items rechts unten wählen. Kein Gedrückthalten einer Tastaturtaste nötig.",Color("a3c9cf"))
		else:
			_note("DESKTOP: Pfeiltasten verschieben die Karte, C zentriert das Schiff, K setzt einen Kurs zur Kartenmitte, M öffnet das Menü, A die Munition. Z / X / V benutzen die drei belegten Schnellplätze, Q wechselt ihre Seite. Leertaste feuert, Esc bricht ab.",Color("a3c9cf"))
		var classic_controls=_grid(1 if touch_layout else 3)
		_action("ZUM SCHIFF · C",func():_close_modal();_recenter_camera(),"normal",classic_controls)
		_action("KURS SETZEN · K",func():_close_modal();_classic_center_course(),"normal",classic_controls)
		_action("MUNITION · A",func():_close_modal();_toggle_ammo(),"normal",classic_controls)
	if _tab("Anzeige")=="HUD":
		_section("MOBILE FIRST / DESKTOP")
		_note("Touch: große Kampfaktionen rechts, drei frei belegbare Schnellplätze mit größeren Seitenreitern, Kamerapad links. Desktop: eigene Schnellleiste unten links plus Tastenkürzel. Inhalte, Belegung und Spielstand bleiben in beiden Ansichten gleich.",Color("a3c9cf"))
		_section("FENSTERGRÖSSE · ADAPTIV")
		var menu_grid=_grid(3)
		for option in [["compact","KOMPAKT"],["balanced","STANDARD"],["large","GROSS"]]:
			var mode: String=str(option[0])
			var selected: bool=menu_layout==mode
			var menu_button=_action(str(option[1])+(" ✓" if selected else ""),func():_set_menu_layout(mode),"tab_on" if selected else "normal",menu_grid)
			menu_button.disabled=selected
		_note("Fenster zentriert mit sichtbarem Meeresrand. Breite und Höhe passen sich dem Bildschirm an; die Munitionsauswahl bleibt ein kleines Kampfmenü.",Color("a3c9cf"))
		_section("HUD-GRÖSSE")
		for i in 3:
			var index=i
			var choice=_action((["KOMPAKT · mehr freie Seekarte","KOMFORT · größere Anzeigen","GROSS · beste Lesbarkeit"][i])+(" · AKTIV" if hud_size==i else ""),func():_set_display(index,journal_visible),"tab_on" if hud_size==i else "normal")
			choice.disabled=hud_size==i
		_action("HUD & WASSERBEWEGUNG: "+("EIN" if ambient_motion_enabled else "AUS"),_toggle_ambient_motion,"tab_on" if ambient_motion_enabled else "normal")
		_section("LEISTEN")
		var toggles=_grid(2)
		_action("AUFTRAGSLEISTE: "+("EIN" if journal_visible else "AUS"),func():_set_display(hud_size,not journal_visible),"normal",toggles)
		_action("JOYSTICK: "+("EIN" if camera_pad_visible else "AUS"),func():camera_pad_visible=not camera_pad_visible;_set_display(hud_size,journal_visible),"normal",toggles)
		_note("Die Auftragsleiste oben links öffnet das Logbuch. Der Joystick bewegt nur die Kamera: Seekarte erkunden, das Schiff hält seinen Kurs. Gefahren wird per Antippen. Fadenkreuz an der Karte: zurück zum Schiff. Fernrohr: nächstes sichtbares Ziel.")
		_action("STANDARD WIEDERHERSTELLEN",_reset_display_preferences)
	if _tab("Anzeige")=="EFFEKTE":
		_section("KAMPFEFFEKTE · SICHTBARE KUGELN PRO SCHUSS")
		_note("Nur Darstellung: keine zusätzlichen Treffer, kein erhöhter Schaden und kein zusätzlicher Munitionsverbrauch.",Color("b2c9ca"))
		var projectile_choices=_grid(4)
		for amount in [1,3,5,8]:
			var selected_count: int=amount
			var count_button=_action(str(amount)+(" ✓" if projectile_visual_count==amount else ""),func():_set_projectile_visual_count(selected_count),"tab_on" if projectile_visual_count==amount else "normal",projectile_choices)
			count_button.disabled=projectile_visual_count==amount
		_note("Standard: 3 · Leuchtkugeln wechseln zwischen Rot, Blau, Grün, Gold und Violett.",Color("bfcbdf"))
		_section("ANIMATIONEN & KAMPFEFFEKTE")
		_note("Jede Einstellung ist rein optisch und wirkt sofort in 2,5D und 3D. Auch bei ausgeschalteten Effekten bleiben die echten Geschosse und Treffer sichtbar.",Color("a3c9cf"))
		var effect_grid=_grid(2)
		for option in [["enabled","ALLE EFFEKTE"],["flight","FLUGSPUREN"],["muzzle","MÜNDUNGSBLITZE"],["impact","TREFFERANIMATIONEN"],["particles","PARTIKEL & TRÜMMER"],["water","WASSERFONTÄNEN"],["flashes","LICHTBLITZE"]]:
			var key: String=str(option[0])
			var active: bool=bool(vfx_flags.get(key,true))
			var fx_button=_action(str(option[1])+(": "+("EIN" if active else "AUS")),func():_set_vfx_flag(key),"tab_on" if active else "normal",effect_grid)
			fx_button.tooltip_text="Nur Optik · Schaden, Munition und Nachladen bleiben unverändert"
		_section("INTENSITÄT")
		var intensity_grid=_grid(4)
		for option in [[.65,"LEICHT"],[1.0,"NORMAL"],[1.35,"INTENSIV"],[1.7,"EXTREM"]]:
			var amount: float=float(option[0])
			var selected: bool=is_equal_approx(vfx_intensity,amount)
			var choice=_action(str(option[1])+(" ✓" if selected else ""),func():_set_vfx_intensity(amount),"tab_on" if selected else "normal",intensity_grid)
			choice.disabled=selected
		_note("Intensiv ist der Standard. Leicht reduziert Zeichnung und Partikel auf schwächeren Smartphones; Extrem liefert stärkere Treffer und sichtbare Folgewellen.",Color("bfcbdf"))

func _menu_hub_art(kind: String) -> Texture2D:
	match kind:
		"Hafen":return painted.nav_harbor
		"Werft":return painted.nav_shipyard
		"Kastelle":return painted.nav_castles
		"Munition":return icons.cannonball
		"Kessel":return painted.nav_kessel
		"Logbuch":return painted.nav_quests
		"Bonuskarten","Battle Pass":return painted.nav_bonus
		"Gilde","Freunde":return painted.nav_guild
		"Monster":return painted.boss_wave
		"Events":return painted.ammo_pumpkin
		"Profil","Rangliste":return painted.nav_ranking
		"Belohnungen":return painted.reward_chest
		"Bewaffnung":return extra_icons.cannon_0
		"Anzeige":return hud_icons.gear
		_:return painted.nav_menu

func _open_menu_hub() -> void:
	# One compact, grouped index instead of 11 persistent nav buttons.
	# All existing functional panels remain directly reachable.
	if online_client!=null and online_connected:
		_note("ONLINE-PRÄSENZTEST · %d Kapitäne auf dieser Karte. Andere Kapitäne sind mit Schiff, Design und HP-Anzeige sichtbar. Kampf, Schaden und Beute sind noch lokal." % online_population,Color("8bd7db"))
	else:
		_note("LOKALE BETA · Online-Anmeldung und WebSocket-Test können auf der Startseite unter Einstellungen & Konto eingerichtet werden. Es läuft noch kein öffentlicher MMO-Server.",Color("9fb9ba"))
	_section("SCHNELLZUGRIFF")
	var quick=_grid(clampi(int(modal_scroll.size.x/210.0),1,3))
	for item in [["HAFEN","Hafen"],["WERFT","Werft"],["KASTELLE","Kastelle"],["MUNITION","Munition"],["KESSEL","Kessel"],["LOGBUCH","Logbuch"]]:
		var destination: String=str(item[1])
		var button=_action(str(item[0]),func():_open_modal(destination),"normal",quick)
		button.name="MenuShortcut_"+destination
		_with_icon(button,_menu_hub_art(destination))
		button.add_theme_constant_override("icon_max_width",36)
		button.custom_minimum_size.y=62
		button.add_theme_font_size_override("font_size",14)
	_section("WELT & SOZIALES")
	var world=_grid(clampi(int(modal_scroll.size.x/210.0),1,3))
	for item in [["BONUSKARTEN","Bonuskarten"],["GILDE","Gilde"],["MONSTER","Monster"],["EVENTS","Events"],["FREUNDE","Freunde"],["RANGLISTE","Rangliste"]]:
		var destination: String=str(item[1])
		var button=_action(str(item[0]),func():_open_modal(destination),"normal",world)
		button.name="MenuShortcut_"+destination
		_with_icon(button,_menu_hub_art(destination))
		button.add_theme_constant_override("icon_max_width",36)
		button.custom_minimum_size.y=62
		button.add_theme_font_size_override("font_size",14)
	_section("KAPITÄN & SYSTEM")
	var captain=_grid(clampi(int(modal_scroll.size.x/210.0),1,3))
	for item in [["PROFIL","Profil"],["BELOHNUNGEN","Belohnungen"],["ARSENAL","Bewaffnung"],["ANZEIGE","Anzeige"],["HILFE","Spielinfo"],["SAISONPASS","Battle Pass"]]:
		var destination: String=str(item[1])
		var button=_action(str(item[0]),func():_open_modal(destination),"normal",captain)
		button.name="MenuShortcut_"+destination
		if destination=="Belohnungen" and (sim.rewards.daily_available() or sim.rewards.afk_gold()>0):
			button.text+=" · BEREIT"
			SKIN.dress(button,"primary")
		_with_icon(button,_menu_hub_art(destination))
		button.add_theme_constant_override("icon_max_width",36)
		button.custom_minimum_size.y=62
		button.add_theme_font_size_override("font_size",14)
	_action("ZUR STARTSEITE",func():_save_progress();get_tree().change_scene_to_file("res://start_hub.tscn"))

func _open_help() -> void:
	_section("GRAFIKMODUS · DATENUPDATE %d" % _active_data_revision())
	_note("Browser: Classic 2D fährt echte kurze diagonale Teilstrecken mit vier Ansichten; kein schwingender Sprite. App/Desktop 2,5D und 3D fahren direkt. Gemeinsame Schiffs- und Spielwerte bleiben erhalten.",Color("9be4df"))
	if not OS.has_feature("web"):
		var modes=_grid(3)
		for option in [["classic","CLASSIC 2D"],["hybrid","2,5D"],["3d","3D"]]:
			var key: String=str(option[0])
			var button=_action(str(option[1])+(" ✓" if key==render_mode else ""),func():_set_render_mode(key),"tab_on" if key==render_mode else "normal",modes)
			button.disabled=key==render_mode
	var links=_grid(2)
	_with_icon(_action("SPIELERPROFIL",func():_open_modal("Profil"),"normal",links),painted.nav_ranking)
	_with_icon(_action("TAGESBONUS & AFK",func():_open_modal("Belohnungen"),"normal",links),painted.reward_chest)
	_action("ZUM HAUPTMENÜ",func():_save_progress();get_tree().change_scene_to_file("res://start_hub.tscn"),"normal",links)
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
	_note("HAFEN: Trockendock, Kastelle, Deckwerft und Gezeitenkessel. Markt, Werft und Talente sind unabhängig vom Hafen erreichbar.\nKESSEL: Gezeitenessenz einwerfen, offene Preistabelle, Meilensteine bei 10, 25, 50 und 100.\nBONUSKARTEN: Fragmente zu Schriftrollen zusammensetzen, fünf Wellen mit Checkpoint.\nGILDE: Kürzel vor dem Schiffsnamen, Korsarenfestung mit zwölf Türmen in den Schattengewässern.",Color("e2ecee"))
	_section("TASTEN & GESTEN")
	_note("Zwei Finger / Mausrad / Plus und Minus an der Karte: Zoom. Joystick links unten oder Ziehen / rechte Maustaste: Kamera. Fernrohr / Tab: nächstes Ziel. Tasten 1 bis 3 Munition, 8 Leucht, 9 Kürbis, 0 Schnee, Minus Eis, 4 bis 7 Gegenstände, Q Schnellleiste.\n\nGastfortschritt wird auf diesem Gerät gespeichert. Lokales Spiel; noch kein öffentlicher MMO-Server.",Color("bac7c7"))

# --- Staff tools ----------------------------------------------------------------------

func _staff(action: Callable,leave: bool=false) -> void:
	action.call()
	_save_staff();_save_progress()
	if previous_region!=sim.map_id:
		_sync_region()
	elif leave:
		_close_modal();_recenter_camera();camera.position=sim.player.pos
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
	var places=[["harbor","HAFEN"],["start","STARTPUNKT"],["portal_east","RAND OST"],["portal_west","RAND WEST"]]
	if CONTENT.has_guild_island(sim.map_id):places.append(["fortress","KORSARENFESTUNG"])
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
	_staff_button(world,"FESTUNG ERNEUERN","world",func():sim.staff_world("reset_fortress"),false,"normal",not CONTENT.has_guild_island(sim.map_id))
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
	if online_client!=null and is_instance_valid(online_client):
		online_client.leave_world()
		online_players.clear()
		online_population=0
		call_deferred("_join_online_room")
	previous_region=sim.map_id
	chart_pick=-1
	_close_modal()
	_recenter_camera();camera.position=sim.player.pos
	_save_progress();_refresh_ui()
	_begin_loading(1.1)

func _navigate_region(destination: int) -> void:
	sim.request_portal(destination)
	if previous_region!=sim.map_id:_sync_region()
	else:_close_modal()
	_refresh_ui()

func _chart_course(point: Vector2) -> void:
	if sim.course(point):_send_online_course(point)
	_refresh_ui()

func _interact() -> void:
	if sim.in_bonus_map():
		sim.leave_bonus()
		if previous_region!=sim.map_id:_sync_region()
	elif sim.docked:
		sim.depart()
		_close_modal()
	elif sim.near_portal()>=0:
		_navigate_region(sim.near_portal())
	elif sim.pending_portal>=0:
		sim.pending_portal=-1;sim.player.path=[];sim.message="Überfahrt abgebrochen"
	elif sim.can_dock():
		if sim.dock():_open_modal("Hafen")
	else:
		sim.course(sim.harbor)
	_save_progress()
	_refresh_ui()

func _equip(index: int) -> void:
	var destination: String="Events" if modal_kind=="Events" else "Werft"
	if index<0 or index>=skins.size():return
	if browser_classic and index>=2:
		var delivery=get_tree().root.get_node_or_null("BrowserContent")
		if delivery!=null and not delivery.available("ship_designs"):
			sim.message="Schiffsdesign wird geladen …"
			_refresh_ui()
			if not await delivery.ensure("ship_designs"):
				sim.message="Schiffsdesign nicht geladen. Bitte erneut versuchen."
				_refresh_ui()
				return
			_refresh_ship_catalog()
	if not browser_classic and (mesh_layer==null or not mesh_layer.model_scenes.has(str(skins[index].mesh_key)) or (index>=2 and not ResourceLoader.exists(mesh_layer.texture_path(index-1)))):
		sim.message="3D-Modell oder Elite-Textur noch nicht verfügbar"
		_refresh_ui()
		return
	sim.player.skin=index
	ship_switch_pulse_at=elapsed
	sim.message=str(skins[index].name)+" aktiv"
	_save_progress()
	_open_modal(destination)
	_refresh_ui()

func _zoom(factor: float) -> void:
	desired_zoom=clampf(desired_zoom*factor,0.5,1.4)

# Godot delivers _input BEFORE GUI consumption. The former sea-input path
# used _unhandled_input exclusively, so HUD Control nodes could swallow
# touch-down but not touch-up. Such orphaned releases silently lost taps.
# World touches are claimed early; UI-origin touches still reach Buttons.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_world_touch(event)

func _handle_world_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch_ms=Time.get_ticks_msec()
		if event.pressed:
			if _hud_contains(event.position):
				_reset_enemy_tap()
				hud_touches[event.index]=true
				return # let the actual UI button/slider consume it
			touch_points[event.index]=event.position
			touch_starts[event.index]=event.position
			touch_invalid.erase(event.index)
			if touch_points.size()==1:
				drag_start=event.position
				dragging=false
				pinch_distance=0.0
			else:
				# A pinch can NEVER turn into a tap when one finger lifts.
				for finger in touch_points:touch_invalid[finger]=true
				var coordinates: Array=touch_points.values()
				pinch_distance=coordinates[0].distance_to(coordinates[1])
			get_viewport().set_input_as_handled()
		else:
			if hud_touches.has(event.index):
				hud_touches.erase(event.index)
				return # no world release, even when dragged out of the HUD
			if not touch_starts.has(event.index):
				return # discard orphaned release without cancelling a course
			var origin: Vector2=touch_starts[event.index]
			var moved: float=origin.distance_to(event.position)
			var can_tap: bool=not event.canceled and touch_points.size()==1 and not touch_invalid.has(event.index) and moved<=25.0
			touch_points.erase(event.index)
			touch_starts.erase(event.index)
			touch_invalid.erase(event.index)
			if touch_points.is_empty():
				pinch_distance=0.0
				dragging=false
			# No global cooldown after an ordinary one-finger tap! The old
			# +180 ms suppression broke rapid repeat-taps and target toggling.
			if can_tap and not _hud_contains(event.position):
				_tap(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if hud_touches.has(event.index):return
		if not touch_points.has(event.index):return
		touch_points[event.index]=event.position
		if touch_points.size()>=2:
			for finger in touch_points:touch_invalid[finger]=true
			var coords: Array=touch_points.values()
			var distance: float=coords[0].distance_to(coords[1])
			if pinch_distance>0.0 and distance>1.0:_zoom(distance/pinch_distance)
			pinch_distance=distance
		elif touch_starts.has(event.index) and event.position.distance_to(touch_starts[event.index])>25.0:
			touch_invalid[event.index]=true
			dragging=true
			_shift_camera(-event.relative/camera.zoom)
		elif touch_invalid.has(event.index):
			_shift_camera(-event.relative/camera.zoom)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		# Fallback for scripted tests and hardware that forwards unhandled
		# touch events. Normally the _input path already claimed the gesture.
		_handle_world_touch(event)
	elif event is InputEventMouseButton:
		# Touch gestures are owned by _input; Android also emits a synthetic mouse.
		if event.device==InputEvent.DEVICE_ID_EMULATION:return
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:_zoom(1.10)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:_zoom(1/1.10)
		elif event.button_index==MOUSE_BUTTON_LEFT and event.pressed and Time.get_ticks_msec()-last_touch_ms>350 and Time.get_ticks_msec()>=suppress_tap_until:
			_tap(event.position)
		elif event.button_index==MOUSE_BUTTON_RIGHT:
			dragging=event.pressed
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_shift_camera(-event.relative/camera.zoom)
	elif event is InputEventKey and event.pressed and not event.echo:
		# A text field or open menu owns keyboard input. Never fire, repair,
		# steer or consume ammunition while the captain edits a form.
		if event.keycode==KEY_ESCAPE:
			if modal.visible:_back_modal()
			elif sim.target>0:_cancel_target()
			get_viewport().set_input_as_handled()
			return
		if modal.visible or loading_left>0.0:return
		var focused: Control=get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:return
		if event.keycode==KEY_C:
			_recenter_camera();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_K:
			_classic_center_course();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_M:
			_open_modal("Menü");get_viewport().set_input_as_handled();return
		if event.keycode==KEY_A:
			_toggle_ammo();get_viewport().set_input_as_handled();return
		# Desktop-only physical keyboard bindings; the touch HUD doesn't need
		# a keyboard overlay or press-and-hold navigation widget.
		if not _is_mobile_hud(get_viewport_rect().size,OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
			if event.keycode==KEY_Q:
				quick_page=(quick_page+1)%3
				_persist_display_preferences()
				quick_bar.refresh()
				get_viewport().set_input_as_handled();return
			var desktop_slot_keys: Array=[KEY_Z,KEY_X,KEY_V]
			if event.keycode in desktop_slot_keys:
				_desktop_quick_action(desktop_slot_keys.find(event.keycode))
				get_viewport().set_input_as_handled();return
		if event.keycode==KEY_TAB:_cycle_target();get_viewport().set_input_as_handled()
		if event.keycode==KEY_SPACE:_toggle_fire()
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
	var controls: Array[Control]=[quick_bar,supply_selector,chrome,target_panel,chart_mini,quest_panel,attack,repair,ammo_selector,loadout_button,center_button,settings_button,render_toggle,target_cycle,camera_pad,zoom_in,zoom_out,interact,staff_pill]
	for item: Button in supply_buttons.values():controls.append(item)
	for control: Control in controls:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen):return true
	return false

# Ships have different projected hull lengths. Hit-test them directly in
# screen pixels, otherwise zoom and off-center 3D sails make selection fail.
func _browser_ship_screen_rect(actor: Dictionary) -> Rect2:
	var entry: Dictionary=classic_geometry.get(_classic_atlas_key(actor),{})
	if not browser_classic or entry.is_empty() or str(actor.get("kind",""))!="ship":return Rect2()
	var frame: Dictionary=entry.frames[_classic_frame_for_actor(actor)]
	var spec: Dictionary=VISUALS.geometry(frame,_actor_visual_length(actor))
	var world: Rect2=spec.destination
	world.position+=_visual_actor_pos(actor)
	return get_canvas_transform()*world

func _browser_ship_touch_rect(visible: Rect2) -> Rect2:
	# Fixed screen-pixel tolerance keeps small zoomed-out ships tappable.
	var size: Vector2=visible.size.max(Vector2(48,48))+Vector2(20,20)
	return Rect2(visible.get_center()-size*.5,size)

func _enemy_at_screen(screen: Vector2) -> int:
	var candidate_id: int=-1
	var closest: float=INF
	var canvas: Transform2D=get_canvas_transform()
	var zoom: float=camera.zoom.x if camera!=null else 1.0
	for npc: Dictionary in sim.npcs:
		if float(npc.hp)<=0.0:continue
		var visible: Rect2=_browser_ship_screen_rect(npc)
		if visible.has_area():
			if not _browser_ship_touch_rect(visible).has_point(screen):continue
			# Actual artwork wins over a neighbouring ship's touch padding.
			var inside: bool=visible.has_point(screen)
			var normalized: Vector2=(screen-visible.get_center())/visible.size.max(Vector2.ONE)
			var score: float=normalized.length_squared()+(0.0 if inside else 100.0)
			if score<closest:closest=score;candidate_id=int(npc.id)
			continue
		var projected: Vector2=canvas*(_visual_actor_pos(npc)-Vector2(0,25))
		var length: float=_actor_visual_length(npc)
		var radius: float=clampf(length*zoom*.57,78.0,116.0)
		if str(npc.get("kind","ship"))=="tower":radius=clampf(radius,72.0,95.0)
		var dist: float=screen.distance_to(projected)
		var score: float=dist+200.0
		if dist<=radius and score<closest:
			closest=score
			candidate_id=int(npc.id)
	return candidate_id

func _reset_enemy_tap() -> void:
	last_enemy_tap_id=-1
	last_enemy_tap_ms=-10000
	last_enemy_tap_screen=Vector2.ZERO

func _handle_enemy_tap(enemy_id: int,screen: Vector2,timestamp_ms: int=-1) -> void:
	if enemy_id<=0:return
	var now_ms: int=timestamp_ms if timestamp_ms>=0 else Time.get_ticks_msec()
	if last_enemy_tap_id==enemy_id and now_ms>=last_enemy_tap_ms and now_ms-last_enemy_tap_ms<DOUBLE_TAP_MIN_MS:return
	var same_double: bool=double_tap_attack_enabled and sim.target==enemy_id and last_enemy_tap_id==enemy_id and now_ms-last_enemy_tap_ms>=DOUBLE_TAP_MIN_MS and now_ms-last_enemy_tap_ms<=DOUBLE_TAP_ATTACK_MS and screen.distance_to(last_enemy_tap_screen)<=DOUBLE_TAP_ATTACK_RADIUS
	if sim.target!=enemy_id:
		# New target is selection-only, even if a different ship was firing.
		sim.firing=false
		sim.select(enemy_id)
	if same_double:
		# Never toggle firing OFF with a repeated tap. Existing reload,
		# ammo, line of sight, docking and range rules remain untouched.
		if not sim.firing and int(sim.player.hp)>0 and not sim.docked:
			sim.firing=true
			sim.repairing=false
			sim.message="Doppeltipp · Angriff gestartet"
		_reset_enemy_tap()
	else:
		last_enemy_tap_id=enemy_id
		last_enemy_tap_ms=now_ms
		last_enemy_tap_screen=screen
	_refresh_ui()

func _tap(screen: Vector2) -> void:
	if modal.visible or loading_left>0:return
	# Ships always win over nearby port and portal hitboxes, so tapping a
	# visible enemy selects it; a deliberate double-tap may start fire.
	var clicked_enemy: int=_enemy_at_screen(screen)
	if clicked_enemy>0:
		_handle_enemy_tap(clicked_enemy,screen)
		return
	_reset_enemy_tap()
	var point: Vector2=get_canvas_transform().affine_inverse()*screen
	# A graphic water berth is a deliberate, small interactive landmark.
	if sim.has_harbor() and point.distance_to(sim.harbor)<=maxf(84.0,45.0/maxf(.1,camera.zoom.x)):
		if sim.docked:
			_open_modal("Hafen")
		elif sim.can_dock():
			sim.dock()
			_open_modal("Hafen")
		elif sim.player.pos.distance_to(sim.harbor)>160.0:
			if sim.course(sim.harbor):sim.message="Kurs zum Inselhafen gesetzt · am Steg andocken"
		else:
			sim.message="Andocken erst 6 Sekunden nach dem letzten Treffer"
		_refresh_ui()
		return
	if sim.staff.tap_teleport and sim.staff.can("teleport"):
		sim.staff_teleport(sim.map_id,"",point)
		_save_staff()
	else:
		if sim.course(point):_send_online_course(point)
	_refresh_ui()

func _save_progress() -> void:
	var data: Dictionary=sim.export_save()
	var file =FileAccess.open(SAVE,FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(data));file.close()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE):return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:sim.restore_save(data);_save_progress()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_WM_CLOSE_REQUEST]:
		if camera_pad!=null:camera_pad.release()
		touch_points.clear();touch_starts.clear();touch_invalid.clear();hud_touches.clear();_reset_enemy_tap()
		if camera!=null:_save_progress()

func _load_display() -> void:
	if not FileAccess.file_exists(HUD_SAVE):return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(HUD_SAVE))
	if not data is Dictionary:return
	web_fast_mode=true if browser_classic else bool(data.get("web_fast_mode",true)) if OS.has_feature("web") else false
	hud_size=clampi(int(data.get("hud_size",1)),0,2)
	journal_visible=bool(data.get("journal_visible",true))
	camera_pad_visible=bool(data.get("camera_pad_visible",true))
	render_mode="classic" if OS.has_feature("web") else str(data.get("render_mode","hybrid"))
	if not render_mode in ["classic","hybrid","3d"]:render_mode="hybrid"
	browser_classic=render_mode=="classic"
	projectile_visual_count=COMBAT_FX.visual_count(int(data.get("projectile_visual_count",3)))
	var stored_flags: Variant=data.get("vfx_flags",{})
	if stored_flags is Dictionary:
		for key in VFX_DEFAULT_FLAGS:
			if stored_flags.get(key) is bool:vfx_flags[key]=stored_flags[key]
	vfx_intensity=clampf(float(data.get("vfx_intensity",1.35)),.65,1.7)
	ambient_motion_enabled=bool(data.get("ambient_motion_enabled",true))
	ship_animations_enabled=bool(data.get("ship_animations_enabled",true))
	wake_effects_enabled=bool(data.get("wake_effects_enabled",true))
	# All old true/false fullscreen preferences migrate to balanced windows.
	menu_layout=str(data.get("menu_layout","balanced"))
	if not menu_layout in ["compact","balanced","large"]:menu_layout="balanced"
	# Earlier builds silently enabled double-tap attack by default and stored
	# that value with unrelated HUD preferences. Treat pre-v2 settings as
	# unconfirmed: keep combat safe until the captain explicitly opts in.
	double_tap_attack_enabled=bool(data.get("double_tap_attack_enabled",false)) if int(data.get("combat_input_revision",0))>=2 else false
	quick_pages=preload("res://sea_expansion.gd").normalize_quick(data.get("quick_pages",[]))
	quick_page=clampi(int(data.get("quick_page",0)),0,2)

func _cycle_render_mode() -> void:
	if OS.has_feature("web"):return
	_set_render_mode({"classic":"hybrid","hybrid":"3d","3d":"classic"}.get(render_mode,"classic"))

func _persist_display_preferences() -> void:
	var file=FileAccess.open(HUD_SAVE,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"quick_pages":quick_pages,"quick_page":quick_page,"hud_size":hud_size,"journal_visible":journal_visible,"camera_pad_visible":camera_pad_visible,"render_mode":render_mode,"web_fast_mode":web_fast_mode,"projectile_visual_count":projectile_visual_count,"vfx_flags":vfx_flags,"vfx_intensity":vfx_intensity,"ambient_motion_enabled":ambient_motion_enabled,"ship_animations_enabled":ship_animations_enabled,"wake_effects_enabled":wake_effects_enabled,"menu_layout":menu_layout,"combat_input_revision":2,"double_tap_attack_enabled":double_tap_attack_enabled}))
		file.close()

## Browser-only render budget: no effect on collision, AI ticks, camera,
## movement speed, save progress, network tick rate, or native Android UI.
func _apply_web_performance() -> void:
	# Start quality high; only sustained slow frames reduce the ship GPU pass.
	web_fps_clock=0.0
	web_fps_frames=0
	web_fps_warmup=0.0
	web_fps_last=0.0
	web_quality_good_windows=0
	web_minimap_clock=0.0
	var active: bool=OS.has_feature("web") and web_fast_mode
	if mesh_layer!=null:mesh_layer.set_web_performance(active)
	if ocean!=null:ocean.set_shader_parameter("web_fast",active)
	if OS.has_feature("web"):
		var small_touch: bool=DisplayServer.is_touchscreen_available() or get_viewport_rect().size.y>get_viewport_rect().size.x
		# Classic 2D has no GPU-heavy 3D stage; don't retain the old artificial
		# 30 FPS mobile ceiling that made 60/120Hz phones look stuttery.
		Engine.max_fps=60 if browser_classic else ((30 if small_touch else 45) if active else 0)

## Adapt 3D resolution ONLY. Never alter simulation ticks, NPC density,
## steering, projectile trajectories or the sharp full-resolution HUD.
func _update_web_auto_quality(delta: float) -> void:
	if not OS.has_feature("web") or not web_fast_mode or mesh_layer==null:return
	if loading_left>0.0 or delta<=0.0:return
	web_fps_warmup+=delta
	if web_fps_warmup<4.0:return
	web_fps_clock+=delta
	web_fps_frames+=1
	if web_fps_clock<2.5:return
	var measured_fps: float=float(web_fps_frames)/maxf(web_fps_clock,0.1)
	web_fps_last=measured_fps
	web_fps_clock=0.0
	web_fps_frames=0
	var touch_browser: bool=DisplayServer.is_touchscreen_available() or get_viewport_rect().size.y>get_viewport_rect().size.x
	var target_fps: float=30.0 if touch_browser else 45.0
	var adjustment: Dictionary=mesh_layer.adaptive_quality_step(float(mesh_layer.web_quality),measured_fps,target_fps,web_quality_good_windows)
	web_quality_good_windows=int(adjustment.good_windows)
	mesh_layer.set_web_quality(float(adjustment.quality))

func _set_web_fast_mode(enabled: bool) -> void:
	if browser_classic:return
	if not OS.has_feature("web"):return
	web_fast_mode=enabled
	_apply_web_performance()
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _set_menu_layout(value: String) -> void:
	if not value in ["compact","balanced","large"]:return
	menu_layout=value
	_persist_display_preferences()
	_layout()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _toggle_double_tap_attack() -> void:
	double_tap_attack_enabled=not double_tap_attack_enabled
	_reset_enemy_tap()
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	_refresh_ui()

func _apply_ambient_motion() -> void:
	get_tree().set_meta("abyssal_ui_motion",ambient_motion_enabled)
	get_tree().set_group("living_hud","motion_enabled",ambient_motion_enabled)
	if ocean!=null:ocean.set_shader_parameter("surface_motion",ambient_motion_enabled)
	if not ambient_motion_enabled:
		for tween: Tween in wallet_tweens.values():
			if tween!=null and tween.is_valid():tween.kill()
		for label: Label in [gold_label,pearl_label,crystal_label]:
			if label!=null:label.modulate=Color.WHITE

func _toggle_ambient_motion() -> void:
	ambient_motion_enabled=not ambient_motion_enabled
	_apply_ambient_motion();_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")

func _wallet_feedback(values: Array) -> void:
	var labels: Array[Label]=[gold_label,pearl_label,crystal_label]
	for index in values.size():
		if ambient_motion_enabled and wallet_previous.size()==3 and int(values[index])!=wallet_previous[index]:
			var before: Tween=wallet_tweens.get(index)
			if before!=null and before.is_valid():before.kill()
			labels[index].modulate=Color("9bf2bc") if int(values[index])>wallet_previous[index] else Color("ffab91")
			var pulse: Tween=create_tween()
			pulse.tween_property(labels[index],"modulate",Color.WHITE,.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			wallet_tweens[index]=pulse
	wallet_previous.assign(values)

func _set_ship_visual_toggle(which: String) -> void:
	if which=="motion":ship_animations_enabled=not ship_animations_enabled
	elif which=="wake":wake_effects_enabled=not wake_effects_enabled
	else:return
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _set_vfx_flag(key: String) -> void:
	if not VFX_DEFAULT_FLAGS.has(key):return
	vfx_flags[key]=not bool(vfx_flags.get(key,true))
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _set_vfx_intensity(amount: float) -> void:
	vfx_intensity=clampf(amount,.65,1.7)
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _reset_display_preferences() -> void:
	camera_pad_visible=true
	projectile_visual_count=3
	vfx_flags=VFX_DEFAULT_FLAGS.duplicate(true)
	vfx_intensity=1.35
	web_fast_mode=OS.has_feature("web")
	_apply_web_performance()
	ambient_motion_enabled=true
	_apply_ambient_motion()
	ship_animations_enabled=true
	wake_effects_enabled=true
	menu_layout="balanced"
	double_tap_attack_enabled=false
	_reset_enemy_tap()
	_set_display(1,true)

func _set_projectile_visual_count(requested: int) -> void:
	projectile_visual_count=COMBAT_FX.visual_count(requested)
	_persist_display_preferences()
	if modal!=null and modal.visible and modal_kind=="Anzeige":_open_modal("Anzeige")
	queue_redraw()

func _set_render_mode(value: String) -> void:
	if OS.has_feature("web"):value="classic"
	if not value in ["classic","hybrid","3d"]:value="hybrid"
	if value=="classic":
		var previous: bool=browser_classic
		browser_classic=true;_load_classic_atlases()
		if not _classic_fleet_ready():
			browser_classic=previous;sim.message="Classic-Schiffsdaten fehlen · bitte Datenupdate laden";return
		render_mode="classic"
		if mesh_layer!=null:
			mesh_layer.hide();mesh_layer.stage.render_target_update_mode=SubViewport.UPDATE_DISABLED
			mesh_layer.queue_free();mesh_layer=null
	else:
		browser_classic=false;render_mode=value;_ensure_mesh_layer()
		mesh_layer.set_render_mode(value);render_mode=mesh_layer.mode
	# A mode change now replaces the REMAINING sailing legs but keeps
	# the live world position and final clicked destination. Re-send the
	# actual new course if a real multiplayer session is connected.
	var was_classic: bool=sim.classic_steering
	sim.set_classic_steering(browser_classic)
	if was_classic!=sim.classic_steering and online_connected and not sim.player.path.is_empty():
		_send_online_course(Vector2(sim.player.path.back()))
	classic_heading_cache.clear()
	if ocean!=null:ocean.set_shader_parameter("web_classic",browser_classic)
	_persist_display_preferences();_apply_web_performance()
	if camera!=null:_sync_plate_overlay()
	if modal.visible and modal_kind in ["Anzeige","Spielinfo"]:_open_modal(modal_kind)
	_refresh_ui();queue_redraw()

func _set_display(size_index: int,show_journal: bool) -> void:
	hud_size=clampi(size_index,0,2)
	journal_visible=show_journal
	_persist_display_preferences()
	_layout()
	_open_modal("Anzeige")
	_refresh_ui()

func _pan_camera(direction: Vector2,delta: float) -> void:
	if direction==Vector2.ZERO:return
	_shift_camera(direction*620.0*maxf(delta,0.0)/camera.zoom)

func _desktop_quick_action(slot: int) -> void:
	# Uses exactly the same saved slot as its corresponding touch button.
	# Never bypass the visible cooldown, docking or out-of-stock state.
	if slot<0 or slot>=quick_bar.slots.size() or modal.visible:return
	if quick_bar.slots[slot].disabled:return
	_use_supply(str(quick_pages[quick_page][slot]))

func _classic_keyboard_pan(delta: float) -> void:
	# The old sea chart let arrow keys inspect the map without steering.
	# Reuse the camera thumbpad speed and bounds; never affect ship physics.
	if modal==null or modal.visible or loading_left>0.0:return
	var focused: Control=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return
	var direction:=Vector2(
		int(Input.is_key_pressed(KEY_RIGHT))-int(Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_DOWN))-int(Input.is_key_pressed(KEY_UP)))
	if direction!=Vector2.ZERO:_pan_camera(direction.normalized(),delta)

func _classic_chart_center() -> Vector2:
	var view_center: Vector2=sim.player.pos if camera_locked else camera_anchor
	return view_center.clamp(Vector2(8,8),sim.WORLD-Vector2(8,8))

func _classic_center_course() -> void:
	# K navigates to the inspected chart center; C resumes normal follow.
	if modal.visible or loading_left>0.0:return
	var destination: Vector2=_classic_chart_center()
	if destination.distance_to(sim.player.pos)>=1.0:_chart_course(destination)

func _shift_camera(offset: Vector2) -> void:
	if camera_locked:camera_anchor=sim.player.pos+pan
	camera_locked=false
	camera_anchor=(camera_anchor+offset).clamp(Vector2.ZERO,sim.WORLD)
	pan=camera_anchor-sim.player.pos

func _recenter_camera() -> void:
	pan=Vector2.ZERO;camera_locked=true;camera_anchor=sim.player.pos
	if camera_pad!=null:camera_pad.release()

func _cancel_target() -> void:
	if sim.target<=0:return
	_reset_enemy_tap()
	sim.clear_target()
	portrait_target=-1
	_refresh_ui()

func _cycle_target() -> void:
	if modal.visible:return
	_reset_enemy_tap()
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

# --- Profile, consumables and return rewards -------------------------------------
func _supply_icon(key: String) -> Texture2D:
	var path: String="res://assets/ui/abyssal/"+str(CONTENT.SUPPLIES[key].icon)+".svg"
	return load(path) if ResourceLoader.exists(path) else painted.get(str(CONTENT.SUPPLIES[key].icon),painted.supply_repair)

func _open_consumables() -> void:
	for key: String in CONTENT.SUPPLY_KEYS:
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var active: bool=(sim.powder_on if key=="powder" else sim.plates_on) if bool(config.toggle) else false
		var wait: float=float(sim.cooldowns.get(key,0))
		var column=_row(_supply_icon(key),"%s · %d an Bord\n%s" % [config.name,sim.supplies[key],config.effect],56)
		var item: String=key
		var button=_row_button(column,"AUS" if active else ("%d s" % ceili(wait) if wait>0 else "AKTIVIEREN"),func():_use_supply(item),false,"tab_on" if active else "primary")
		button.name="Use_"+key;button.set_meta("supply_key",key)
		button.disabled=sim.docked or int(sim.player.hp)<=0 or wait>0 or (int(sim.supplies[key])<=0 and not active)
	_note("Nachschub über MARKT > ITEMS – auch unterwegs. Pulver und Platten bleiben bis zum Abschalten aktiv.")

func _wallet_amount(amount: int) -> String:
	return ("%.1f M" % (float(amount)/1000000.0)).replace(".",",") if amount>=1000000 else _thousands(amount)

func _open_profile() -> void:
	_banner_card(profile_avatar.texture,"PIRATENPROFIL",sim.captain_name+" · ID "+sim.captain_id)
	_note("Gold %s · Perlen %s · Kristalle %s" % [_thousands(int(sim.player.gold)),_thousands(sim.pearls),_thousands(sim.crystals)])
	_info("GILDE · [%s] %s" % [str(sim.guild.get("tag","–")),str(sim.guild.get("name",""))] if not sim.guild.is_empty() else "KEINE GILDE",GOLD)
	_note("Piratenrang %d · Kapitänsstufe %d\nBattle Points %d · %s" % [clampi(floori((sim.level-1)/4.0)+1,1,5),sim.level,sim.battle_points,"Noch ohne PvP-Rang" if sim.battle_points==0 else "PvP-Rang "+str(1+sim.battle_points/100)])
	_section("DEIN FORTSCHRITT")
	_meter("ERFAHRUNG",sim.xp_required() if sim.level>=20 else sim.xp,sim.xp_required(),Color("c59e45"),"MAX" if sim.level>=20 else "%s / %s" % [_thousands(sim.xp),_thousands(sim.xp_required())])
	var bp: Dictionary=sim.battle_point_progress()
	_meter("BATTLE POINTS",bp.current,bp.next-(bp.total-bp.current),Color("9a78bd"),"%s / %s BP" % [_thousands(bp.total),_thousands(bp.next)])
	var statistics=_grid(2)
	_stat(statistics,"SCHIFFE VERSENKT",_thousands(sim.kills),painted.nav_ship)
	_stat(statistics,"SEEUNGEHEUER",_thousands(sim.monster_kills),painted.boss_wave)
	_stat(statistics,"AUFTRÄGE","%d / %d" % [mini(sim.quest_index,CONTENT.QUESTS.size()),CONTENT.QUESTS.size()],painted.nav_quests)
	_stat(statistics,"SEEGEBIETE","%d / %d" % [sim.visited.count(true),CONTENT.SEA_MAP_COUNT],painted.nav_charts)
	var links=_grid(2)
	_action("GILDE VERWALTEN",func():_open_modal("Gilde"),"normal",links)
	_action("AUFTRÄGE",func():_open_modal("Logbuch"),"normal",links)
	_action("SEEKARTEN",func():_open_modal("Seekarten"),"normal",links)
	_action("BELOHNUNGEN",func():_open_modal("Belohnungen"),"normal",links)

	_section("NAMEN ÄNDERN")
	var name_field=_line_edit("Spielername · 2 bis 24 Zeichen",24)
	name_field.text=sim.captain_name
	_action("NAMEN SPEICHERN",func():
		var value: String=name_field.text.strip_edges()
		if value.length()>=2:sim.captain_name=value;_save_progress();_open_modal("Profil");_refresh_ui())

func _invite_share_text() -> String:
	return SHARE.invitation()

func _open_friends() -> void:
	_banner_card(painted.nav_guild,"FREUNDE & EINLADUNGEN","Teile die Beta mit anderen Piraten. Eine echte Freundesliste mit gemeinsamen Online-Spielern wird erst nach der Account- und Serveranbindung verfügbar.")
	_section("FREUNDE ZUR BETA EINLADEN")
	var invitation=_catalog_tile(_catalog_grid(1),painted.nav_charts,"KAPITÄNE ANHEUERN","Teile den Browser-Link: direkt testen, ohne Installation. Der Android-Download ist zusätzlich enthalten.","ÖFFENTLICHER BETA-LINK",Color("8ea29b"))
	var copy=_catalog_action(invitation,"SPIELELINK KOPIEREN",func():
		DisplayServer.clipboard_set(_invite_share_text())
		sim.message="Spielelink in die Zwischenablage kopiert"
		_open_modal("Freunde"))
	copy.name="InviteCopy"
	_note("Einladen funktioniert bereits über einen teilbaren Link. Es gibt noch keine automatisch registrierten Freundschaftsanfragen oder Einladungsprämien.")
	_section("FREUNDESLISTE & CROSSPLAY")
	var locked=_action("FREUNDE SUCHEN · ONLINE ERFORDERLICH",func():pass)
	locked.disabled=true
	_note("Freundschaftsanfragen, Einladungs-Codes mit Zuordnung, Online-Status und Referral-Belohnungen müssen vom Server geprüft werden. Keine fingierten Online-Freunde oder Auszahlungen.",Color("a8c4c8"))

func _open_rewards() -> void:
	_banner_card(painted.reward_chest,"TAGESBONUS · 7-TAGE-SERIE","Tägliche Beute wird einmal pro UTC-Tag vergeben. Jede siebte aufeinanderfolgende Abholung enthält die zusätzliche Essenz.")
	var available: bool=sim.rewards.daily_available()
	var today: int=floori(float(Time.get_unix_time_from_system())/86400.0)
	var step: int=(sim.rewards.streak%7)+1 if sim.rewards.last_claim_day==today-1 else 1
	if not available:step=sim.rewards.streak
	_section("TAGESKALENDER · %d/7" % step)
	var board=_grid(4 if modal_scroll.size.x>=680.0 else 2)
	for i in 7:
		var day: int=i+1
		var card=_card(Color("e4ba69") if day==step else Color("536970"),board)
		card.name="DailyDay"+str(day)
		var tile=VBoxContainer.new()
		tile.add_theme_constant_override("separation",5)
		card.add_child(tile)
		_text(tile,"TAG %d" % day,14,Color("f5dfac")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var picture=CenterContainer.new()
		picture.custom_minimum_size.y=76
		tile.add_child(picture)
		_picture(picture,painted.reward_chest,64,false)
		_text(tile,"%d GOLD" % (100+day*50),12,Color("cde2d9")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_text(tile,"+%d ESSENZ" % (2 if day==7 else 1),11,Color("b5d4c9")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_text(tile,"BEREIT" if available and day==step else ("HEUTE ABGEHOLT" if day==step else "SERIE"),11,Color("f3cd82") if day==step else Color("889e9e")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var ready_button=_primary("TAGESBONUS ABHOLEN · TAG %d" % step if available else "HEUTE BEREITS ABGEHOLT",func():
		if sim.rewards.claim_daily(sim):_save_progress()
		_open_modal("Belohnungen"))
	ready_button.name="DailyClaim"
	ready_button.disabled=not available
	_section("AFK-BEUTE · BIS ZU 8 STUNDEN")
	var gold: int=sim.rewards.afk_gold()
	_row(painted.gold_coins,"Bisher angesammelt: %s Gold\nDazu Vollkugeln nach Standzeit" % _thousands(gold),68,Color("b59156"))
	var afk=_primary("AFK-BEUTE ABHOLEN · %s GOLD" % _thousands(gold),func():
		if sim.rewards.claim_afk(sim):_save_progress()
		_open_modal("Belohnungen"))
	afk.name="AfkClaim"
	afk.disabled=gold<=0
	_note("Tageswechsel um 00:00 UTC. Diese lokalen Beta-Belohnungen werden noch nicht als Server-Währung geführt.")

# --- Organized navigation, seasonal content and configurable combat shortcuts ---
func _menu_shortcut(parent: Node,texture: Texture2D,title: String,description: String,kind: String) -> void:
	var tile=_catalog_tile(parent,texture,title,description,"DIREKTZUGRIFF",Color("ad8a58"))
	var button=_catalog_action(tile,"ZUM BEREICH",func():_open_modal(kind))
	button.name="MenuShortcut_"+kind.replace(" ","_")

func _open_info() -> void:
	_banner_card(painted.nav_menu,"KAPITÄNSMENÜ · DEIN SPIEL","Wähle oben eine Kategorie. Jedes Symbol öffnet eine echte Funktion – große Bilder und Bedienelemente statt eng gepackter Textbuttons.")
	match _tab("Spielinfo"):
		"KAPITÄN":
			_section("KAPITÄN & FORTSCHRITT")
			var grid=_catalog_grid(2)
			_menu_shortcut(grid,painted.nav_ranking,"SPIELERPROFIL","Name, Piratenrang & Battle Points","Profil")
			_menu_shortcut(grid,painted.reward_chest,"TAGESBONUS & AFK","7 Tage, Essenz & Vorräte","Belohnungen")
			_menu_shortcut(grid,painted.nav_guild,"FREUNDE EINLADEN","Beta an Freunde weitergeben","Freunde")
			_menu_shortcut(grid,painted.nav_quests,"LOGBUCH","Quest-Fortschritt & Aufträge","Logbuch")
			_menu_shortcut(grid,painted.nav_bonus,"SAISONPASS","Freie Belohnungsstufen","Battle Pass")
			_menu_shortcut(grid,painted.nav_ranking,"RANGLISTE","Spielerwertung & Statistik","Rangliste")
		"SCHIFF":
			_section("WERFT · ARSENAL · FORTSCHRITT")
			var grid=_catalog_grid(2)
			_menu_shortcut(grid,painted.nav_shipyard,"SCHIFFSWERFT","Designs & Kanonenmontage","Werft")
			_menu_shortcut(grid,painted.tide_deck,"DECKS & LAGER","Montage, Upgrades & Sonderdecks","Decks")
			_menu_shortcut(grid,painted.gold_coins,"MARKTPLATZ","Kanonen, Munition & Items","Markt")
			_menu_shortcut(grid,painted.nav_castles,"KASTELLE & TALENTE","Schiffausbau & Fähigkeitszweige","Kastelle")
			_menu_shortcut(grid,extra_icons.cannon_0,"ARSENAL","Bewaffnung & Geschützplätze","Bewaffnung")
			_menu_shortcut(grid,painted.gold_coins,"KRONEN-SHOP","Echtgeldkäufe derzeit gesperrt","Premium-Shop")
		"WELT":
			_section("WELT · GILDE · VERANSTALTUNGEN")
			var grid=_catalog_grid(2)
			_menu_shortcut(grid,painted.nav_charts,"WELTKARTE","Seekarten & Übergänge","Seekarten")
			_menu_shortcut(grid,painted.nav_bonus,"BONUSKARTEN","Fragmente, Wellen & Belohnungen","Bonuskarten")
			_menu_shortcut(grid,painted.boss_wave,"MONSTERJAGD","Seeungeheuer & Harpunen","Monster")
			_menu_shortcut(grid,painted.nav_guild,"GILDE","Heimatbasis & Gildeninsel","Gilde")
			_menu_shortcut(grid,painted.ammo_pumpkin,"EVENTS","Halloween & Entdeckerfahrt","Events")
			_menu_shortcut(grid,painted.nav_kessel,"GEZEITENKESSEL","Essenz & Belohnungen","Kessel")
		_:
			_section("BEDIENUNG & EINSTELLUNGEN")
			var grid=_catalog_grid(2)
			_menu_shortcut(grid,painted.nav_supplies,"VERBRAUCHSGÜTER","Items & Schnellzugriff","Verbrauch")
			_menu_shortcut(grid,painted.nav_menu,"SCHNELLLEISTEN","Neun persönliche Aktionsplätze","Schnellzugriff")
			_menu_shortcut(grid,painted.nav_menu,"GRAFIK & STEUERUNG","HUD, Kameras & Einstellungen","Anzeige")
			_menu_shortcut(grid,painted.nav_quests,"SPIELANLEITUNG","Steuerung & Hilfe","Hilfe")
			var links=_grid(2)
			_action("ZUM HAUPTMENÜ",func():_save_progress();get_tree().change_scene_to_file("res://start_hub.tscn"),"normal",links)
			_action("UPDATES PRÜFEN",func():_save_progress();get_tree().set_meta("abyssal_manual_update",true);get_tree().change_scene_to_file("res://updater/launcher.tscn"),"normal",links)

func _open_quick_config() -> void:
	_info("3 LEISTEN · JE 3 FREI BELEGBARE PLÄTZE")
	_note("Leiste und Platz wählen, dann einen Gegenstand zuweisen. Auf See aktiviert ein Tipp den belegten Platz. Die Belegung bleibt gespeichert.")
	var pages=_grid(3)
	for i in 3:
		var page: int=i
		_action("LEISTE %d" % (i+1),func():quick_page=page;_persist_display_preferences();_open_modal("Schnellzugriff"),"tab_on" if quick_page==i else "normal",pages)
	var places=_grid(3)
	for i in 3:
		var slot: int=i
		var key: String=quick_pages[quick_page][i]
		_action("PLATZ %d\n%s" % [i+1,CONTENT.SUPPLIES[key].short],func():quick_edit_slot=slot;_open_modal("Schnellzugriff"),"tab_on" if quick_edit_slot==i else "normal",places)
	_section("GEGENSTAND FÜR PLATZ %d" % (quick_edit_slot+1))
	for key: String in CONTENT.SUPPLY_KEYS:
		var item: String=key
		var config: Dictionary=CONTENT.SUPPLIES[key]
		var column=_row(_supply_icon(key),str(config.name)+"\n"+str(config.effect),44)
		var chosen: bool=quick_pages[quick_page][quick_edit_slot]==key
		_row_button(column,"BELEGT" if chosen else "ZUWEISEN",func():quick_pages[quick_page][quick_edit_slot]=item;_persist_display_preferences();quick_bar.refresh();_open_modal("Schnellzugriff"),chosen,"tab_on" if chosen else "normal")

func _open_events() -> void:
	var expansion=preload("res://sea_expansion.gd")
	_info("EVENTS · BETA-TESTMODUS",CYAN)
	_note("Event wählen: Jagd, Sammelfunde und Tausch sind im Beta-Test frei zugänglich.")
	var tabs=_grid(3)
	tabs.columns=3
	for key: String in ["halloween","columbus","off"]:
		var choice: String=key
		var tab=_action({"halloween":"HALLOWEEN","columbus":"COLUMBUS","off":"AUS"}[key],func():expansion.set_event(sim,choice);_save_progress();_open_modal("Events"),"tab_on" if sim.event_mode==key else "normal",tabs)
		tab.add_theme_font_size_override("font_size",12 if modal_scroll.size.x<420.0 else 14)
	var currency=_info(_event_currency_text(),GOLD)
	currency.name="EventCurrency"
	if expansion.EVENT_HUNTS.has(sim.event_mode):
		_section("EVENTJAGD · KANONEN")
		var enemy: Dictionary=expansion.event_target(sim)
		if not enemy.is_empty():
			var alive: bool=int(enemy.hp)>0
			var details: String=_event_hunt_details(enemy)
			var hunt=_row(_npc_ship_texture(enemy),details,64,Color("dda759"))
			hunt.name="EventHunt"
			hunt.get_child(0).name="EventHuntDetails"
			var choose=_row_button(hunt,"ANVISIEREN",func():_hunt_event_target(),not alive)
			choose.name="EventHuntSelect"
			var sail=_row_button(hunt,"HINFAHREN",func():_hunt_event_target(true),not alive or sim.docked)
			sail.name="EventHuntSail"
		_note("Nur der Abschuss des markierten Eventgegners gibt die zusätzliche Jagdprämie. Anvisieren und Hinfahren starten keinen Angriff.")
		_section("EVENTTAUSCH · ZEICHEN EINLÖSEN")
		for key: String in expansion.EVENT_TRADES:
			var offer: Dictionary=expansion.EVENT_TRADES[key]
			if str(offer.event)!=sim.event_mode:continue
			var offer_key: String=key
			var button=_primary("%s · %d ZEICHEN" % [offer.name,offer.cost],func():
				expansion.trade(sim,offer_key);_save_progress();_open_modal("Events");_refresh_ui())
			button.name="EventTrade_"+key
			button.disabled=int(sim.event_tokens.get(str(offer.event),0))<int(offer.cost) or sim.staff.active()
	_section("SAMMELFUNDE")
	_note("Halloween: schwimmende Kürbisse sammeln → Kürbiszeichen, Gold und Himmelsbrand. Columbus: Entdeckerfunde sammeln → Kompasszeichen, Gold und Lebensamulett. Sammelfunde kehren nach 120 Sekunden zurück.")
	if not sim.event_pickups.is_empty():
		_primary("KURS ZUM NÄCHSTEN EVENTFUND",func():
			var nearest: Vector2=sim.player.pos;var distance: float=INF
			for pickup: Dictionary in sim.event_pickups:
				if float(pickup.respawn)<=0 and pickup.pos.distance_to(sim.player.pos)<distance:nearest=pickup.pos;distance=nearest.distance_to(sim.player.pos)
			if distance<INF:sim.course(nearest);_close_modal();_refresh_ui())
	_section("EVENT-SCHIFFSDESIGNS · GLEICHE KAMPFWERTE")
	var cards=_grid(2 if modal_scroll.size.x>=565 else 1)
	var frames: Array[Control]=[]
	for index in [12,13]:_add_shipyard_card(index,cards,frames)
	_start_shipyard_preview_motion(frames)
	_note("Beide Event-Anstriche sind während der Beta kostenlos verfügbar und verändern deine Kampfwerte nicht.")

func _event_currency_text() -> String:
	return "Kürbiszeichen: %d · Kompasszeichen: %d" % [sim.event_tokens.halloween,sim.event_tokens.columbus]

func _event_hunt_details(enemy: Dictionary) -> String:
	var expansion=preload("res://sea_expansion.gd")
	var details: String="%s\nHP %s/%s · %d m entfernt\nJagdprämie: %d %s" % [enemy.name,_thousands(int(enemy.hp)),_thousands(int(enemy.max_hp)),roundi(sim.player.pos.distance_to(Vector2(enemy.pos))),expansion.hunt_token_reward(sim),"Kürbiszeichen" if sim.event_mode=="halloween" else "Kompasszeichen"]
	if int(enemy.hp)<=0:details+="\nRückkehr in %d s" % ceili(maxf(0,float(enemy.get("respawn",0))))
	return details

func _refresh_event_controls() -> void:
	var expansion=preload("res://sea_expansion.gd")
	var currency: Label=modal_body.find_child("EventCurrency",true,false) as Label
	if currency!=null:currency.text=_event_currency_text()
	var enemy: Dictionary=expansion.event_target(sim)
	var alive: bool=not enemy.is_empty() and int(enemy.hp)>0
	var details: Label=modal_body.find_child("EventHuntDetails",true,false) as Label
	if details!=null and not enemy.is_empty():details.text=_event_hunt_details(enemy)
	for control in ["EventHuntSelect","EventHuntSail"]:
		var button: Button=modal_body.find_child(control,true,false) as Button
		if button!=null:button.disabled=not alive or (control=="EventHuntSail" and sim.docked)
	for key: String in expansion.EVENT_TRADES:
		var button: Button=modal_body.find_child("EventTrade_"+key,true,false) as Button
		var offer: Dictionary=expansion.EVENT_TRADES[key]
		if button!=null:button.disabled=sim.event_mode!=str(offer.event) or int(sim.event_tokens.get(str(offer.event),0))<int(offer.cost) or sim.staff.active()

func _hunt_event_target(sail: bool=false) -> void:
	var enemy: Dictionary=preload("res://sea_expansion.gd").event_target(sim)
	if enemy.is_empty() or int(enemy.hp)<=0:return
	sim.firing=false;sim.select(int(enemy.id))
	if sail and not sim.docked and sim.player.pos.distance_to(Vector2(enemy.pos))>485.0:
		var direction: Vector2=sim.player.pos-Vector2(enemy.pos)
		if direction.length_squared()<.01:direction=Vector2.RIGHT
		sim.course(sim._free_water(Vector2(enemy.pos)+direction.normalized()*440.0))
	_close_modal();_refresh_ui()

# Active hunt roster is read from real NPCs, never a static fake catalog.
# Choosing a monster only selects it, and sailing stops at harpoon range:
# neither action activates fire or spends ammunition.
func _hunt_monster(enemy_id: int, sail: bool=false) -> void:
	var enemy: Dictionary=sim.actor(enemy_id)
	if enemy.is_empty() or str(enemy.get("kind",""))!="monster" or int(enemy.get("hp",0))<=0:
		sim.message="Dieses Seeungeheuer ist nicht mehr verfügbar"
		_refresh_ui()
		return
	sim.firing=false
	sim.select(enemy_id)
	if sail and not sim.docked:
		var direction: Vector2=sim.player.pos-Vector2(enemy.pos)
		if direction.length_squared()<.01:direction=Vector2.RIGHT
		var distance: float=sim.player.pos.distance_to(Vector2(enemy.pos))
		if distance>485.0:
			var point: Vector2=sim._free_water(Vector2(enemy.pos)+direction.normalized()*440.0)
			sim.course(point)
	_close_modal()
	_refresh_ui()

func _monster_details(info: Dictionary,name: String) -> String:
	if not bool(info.present):return name+"\nNicht auf dieser Seekarte vorhanden"
	if not bool(info.alive):return str(info.name)+"\nBesiegt · Rückkehr in %d s" % ceili(float(info.respawn))
	return "%s\nHP %s/%s · %s m entfernt\nGoldbeute: %s" % [info.name,_thousands(int(info.hp)),_thousands(int(info.max_hp)),_thousands(int(info.distance)),_thousands(int(info.gold))]

func _monster_readiness(info: Dictionary) -> String:
	if not bool(info.present) or not bool(info.alive):return "Harpunen im Lager: %s" % _thousands(int(sim.player.ammo[2]))
	return "%d Schaden/Harpune\nRichtwert: %d Harpunen · Vorrat: %s" % [info.damage,info.required,_thousands(int(sim.player.ammo[2]))]

func _load_harpoons() -> void:
	sim.firing=false
	sim.set_ammo(2)
	_save_progress();_open_modal("Monster");_refresh_ui()

func _open_harpoon_market() -> void:
	_switch_tab("Markt","MUNITION")
	_focus_harpoon_offer.call_deferred()

func _focus_harpoon_offer() -> void:
	var offer: Control=modal_body.find_child("MarketAmmo2",true,false) as Control
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(offer) or not offer.is_inside_tree() or not modal.visible or modal_kind!="Markt" or _tab("Markt")!="MUNITION":return
	var card: Control=offer.get_parent().get_parent() as Control
	var offset: Vector2=modal_scroll.get_global_transform().affine_inverse()*card.global_position
	modal_scroll.restore(roundi(maxf(0,float(modal_scroll.scroll_vertical)+offset.y)))

func _hunt_monster_key(key: String,sail: bool=false) -> void:
	var info: Dictionary=preload("res://sea_expansion.gd").monster_hunt_info(sim,key)
	if bool(info.alive):_hunt_monster(int(info.id),sail)
	else:_refresh_ui()

func _refresh_monster_controls() -> void:
	var expansion=preload("res://sea_expansion.gd")
	var living: int=0
	for spec: Dictionary in expansion.monster_specs():
		var key: String=str(spec.key)
		var info: Dictionary=expansion.monster_hunt_info(sim,key)
		if bool(info.alive):living+=1
		var details: Label=modal_body.find_child("MonsterDetails_"+key,true,false) as Label
		if details!=null:details.text=_monster_details(info,str(spec.name))
		var readiness: Label=modal_body.find_child("MonsterReadiness_"+key,true,false) as Label
		if readiness!=null:
			readiness.text=_monster_readiness(info)
			readiness.add_theme_color_override("font_color",Color("eda780") if bool(info.alive) and int(sim.player.ammo[2])<int(info.required) and not sim.staff.flag("unlimited_ammo") else CYAN)
		var bar: ProgressBar=modal_body.find_child("MonsterHP_"+key,true,false) as ProgressBar
		if bar!=null:
			bar.visible=bool(info.present)
			bar.max_value=maxi(1,int(info.get("max_hp",1)));bar.value=int(info.get("hp",0))
		for action in ["Select","Sail"]:
			var button: Button=modal_body.find_child("Monster"+str(action)+"_"+key,true,false) as Button
			if button!=null:button.disabled=not bool(info.alive) or (action=="Sail" and sim.docked)
	var summary: Label=modal_body.find_child("MonsterSummary",true,false) as Label
	if summary!=null:summary.text="%d/4 Monster lebendig · %s Harpunen im Lager" % [living,_thousands(int(sim.player.ammo[2]))]
	var load: Button=modal_body.find_child("LoadHuntHarpoons",true,false) as Button
	if load!=null:
		load.disabled=sim.ammo_mode==2;load.text="HARPUNEN GELADEN" if sim.ammo_mode==2 else "HARPUNEN LADEN"

func _open_monsters() -> void:
	var expansion=preload("res://sea_expansion.gd")
	_info("SEEUNGEHEUER · HARPUNENJAGD",CYAN)
	var prep=_grid(2)
	var load=_action("HARPUNEN LADEN",_load_harpoons,"normal",prep)
	load.name="LoadHuntHarpoons"
	var market=_action("ZUM HARPUNENMARKT",_open_harpoon_market,"normal",prep)
	market.name="HuntHarpoonMarket"
	_note("Bedarf: Solo-Richtwert mit aktueller Ausrüstung, ohne Zielmarkierung und Schildregeneration. Anvisieren und Hinfahren starten keinen Angriff.")
	var summary=_info("",CYAN);summary.name="MonsterSummary"
	var narrow: bool=modal_scroll.size.x<420.0
	var gallery: Node=_catalog_grid(1) if narrow else modal_body
	for spec: Dictionary in expansion.monster_specs():
		var key: String=str(spec.key)
		var info: Dictionary=expansion.monster_hunt_info(sim,key)
		var monster_art: Texture2D
		if key=="tiamat":
			var preview=AtlasTexture.new();preview.atlas=beast
			preview.region=Rect2(Vector2.ZERO,beast.get_size()/Vector2(CONTENT.MONSTER_COLUMNS,CONTENT.MONSTER_ROWS))
			monster_art=preview
		else:monster_art=expansion_art[key]
		var column: VBoxContainer
		var details_label: Label
		if narrow:
			column=_catalog_tile(gallery,monster_art,"",_monster_details(info,str(spec.name)),"",Color("b58d56"))
			column.find_child("CatalogTitle",true,false).hide()
			column.find_child("CatalogStatus",true,false).hide()
			details_label=column.find_child("CatalogDescription",true,false) as Label
		else:
			column=_row(monster_art,_monster_details(info,str(spec.name)),80,Color("b58d56"))
			details_label=column.get_child(0) as Label
		details_label.name="MonsterDetails_"+key
		var bar=_bar(column);bar.name="MonsterHP_"+key;bar.custom_minimum_size.y=10
		var readiness=_note(_monster_readiness(info),CYAN,column);readiness.name="MonsterReadiness_"+key
		var actions=_grid(2,column)
		var select=_row_button(actions,"ANVISIEREN",func():_hunt_monster_key(key),not bool(info.alive))
		select.name="MonsterSelect_"+key
		var sail=_row_button(actions,"HINFAHREN",func():_hunt_monster_key(key,true),not bool(info.alive) or sim.docked)
		sail.name="MonsterSail_"+key
	_refresh_monster_controls()

class_name PlatformProfile
extends Node

const LOW_SCALE := 0.72
const BALANCED_SCALE := 0.86
const HIGH_SCALE := 1.0

var profile_name := "desktop"
var quality_tier := "high"
var touch_ui := false
var _fps_samples: Array[float] = []
var _sample_timer := 0.0
var _adaptive_reduction_applied := false
var quality_preference := "auto"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detect_profile()
	var settings := ClientSettings.current(get_tree())
	if settings != null:
		settings.changed.connect(_settings_changed)
		quality_preference = str(settings.values.quality)
		if quality_preference != "auto":
			quality_tier = quality_preference
	_apply_base_profile()
	call_deferred("_apply_scene_quality")


func _process(delta: float) -> void:
	if get_tree().paused or quality_preference != "auto":
		return
	_sample_timer += delta
	if _sample_timer < 1.0:
		return
	_sample_timer = 0.0
	_fps_samples.append(Engine.get_frames_per_second())
	if _fps_samples.size() > 8:
		_fps_samples.pop_front()
	if _fps_samples.size() == 8 and not _adaptive_reduction_applied:
		var average := 0.0
		for sample in _fps_samples:
			average += sample
		average /= _fps_samples.size()
		if average < minf(60.0, float(Engine.max_fps)) * 0.7 and quality_tier != "low":
			quality_tier = "low"
			_adaptive_reduction_applied = true
			get_tree().root.set_meta("quality_tier", quality_tier)
			_apply_base_profile()
			_apply_scene_quality()


func _settings_changed() -> void:
	var settings := ClientSettings.current(get_tree())
	if settings == null:
		return
	quality_preference = str(settings.values.quality)
	_fps_samples.clear()
	_adaptive_reduction_applied = false
	_sample_timer = 0.0
	_detect_profile()
	if quality_preference != "auto":
		quality_tier = quality_preference
	_apply_base_profile()
	_apply_scene_quality()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		get_tree().root.set_meta("app_suspended", true)
		if touch_ui or OS.has_feature("web"):
			get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		get_tree().root.set_meta("app_suspended", false)
		get_tree().paused = false


func _detect_profile() -> void:
	var native_mobile := OS.has_feature("mobile")
	var mobile_web := OS.has_feature("web_android") or OS.has_feature("web_ios")
	var web := OS.has_feature("web")
	touch_ui = native_mobile or mobile_web
	if mobile_web:
		profile_name = "mobile_web"
		quality_tier = "low"
	elif native_mobile:
		profile_name = "mobile_native"
		quality_tier = "balanced"
	elif web:
		profile_name = "desktop_web"
		quality_tier = "balanced"
	else:
		profile_name = "desktop_native"
		quality_tier = "high"


func _apply_base_profile() -> void:
	if touch_ui:
		# Keep 48 logical-pixel controls touch-sized instead of shrinking a 1280px
		# desktop canvas to a phone's CSS viewport.
		get_tree().root.content_scale_size = Vector2i.ZERO
	get_tree().root.set_meta("platform_profile", profile_name)
	get_tree().root.set_meta("quality_tier", quality_tier)
	get_tree().root.set_meta("touch_ui", touch_ui)
	get_tree().root.set_meta("graphics_profile_contract",MobileGraphicsProfile.profile(quality_tier))
	Engine.max_fps = 60 if touch_ui or OS.has_feature("web") else 120
	match quality_tier:
		"low":
			get_viewport().scaling_3d_scale = LOW_SCALE
		"balanced":
			get_viewport().scaling_3d_scale = BALANCED_SCALE
		_:
			get_viewport().scaling_3d_scale = HIGH_SCALE
	var settings := ClientSettings.current(get_tree())
	if settings != null:
		Engine.max_fps = int(settings.values.fps_limit)
		get_viewport().scaling_3d_scale *= float(settings.values.render_scale)
		if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.values.vsync else DisplayServer.VSYNC_DISABLED)
			if not touch_ui:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_scene_quality() -> void:
	var low_quality := quality_tier == "low"
	var settings := ClientSettings.current(get_tree())
	for light in get_tree().get_nodes_in_group("quality_directional_lights"):
		if light is DirectionalLight3D:
			light.shadow_enabled = not low_quality and (settings == null or settings.values.shadows)
	for foam in get_tree().get_nodes_in_group("shoreline_foam"):
		if foam is GeometryInstance3D:
			foam.visibility_range_end = 34.0 if low_quality else 58.0

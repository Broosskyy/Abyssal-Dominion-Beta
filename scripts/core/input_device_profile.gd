class_name InputDeviceProfile
extends RefCounted
## M82 local presentation/input classification only.
## Crossplay gameplay rules must not depend on this profile.

static func detect(viewport_size:Vector2,dpi:float=-1.0)->Dictionary:
	if dpi < 0.0:
		dpi=float(DisplayServer.screen_get_dpi())
	var mobile_feature:=OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var touch_like:=mobile_feature or dpi>180.0
	var portrait:=viewport_size.x<viewport_size.y
	var compact:=viewport_size.y<600.0 or viewport_size.x<1050.0 or portrait
	var joypad:=not Input.get_connected_joypads().is_empty()
	var mode:="touch" if touch_like else ("gamepad" if joypad else "mouse_keyboard")
	var hud_profile:="mobile_portrait" if touch_like and portrait else ("mobile_landscape" if touch_like else ("desktop_compact" if compact else "desktop_wide"))
	return {
		"input_mode":mode,
		"hud_profile":hud_profile,
		"touch_like":touch_like,
		"portrait":portrait,
		"compact":compact,
		"dpi":dpi,
	}

static func touch_like(viewport_size:Vector2,dpi:float=-1.0)->bool:
	return bool(detect(viewport_size,dpi).get("touch_like",false))

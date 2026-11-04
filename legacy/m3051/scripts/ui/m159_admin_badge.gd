class_name M159AdminBadge
extends Control
var label:Label
func _ready()->void:
	mouse_filter=MOUSE_FILTER_IGNORE
	label=Label.new();label.text="";label.add_theme_font_size_override("font_size",14);add_child(label)
	set_process(true)
func _process(_delta:float)->void:
	var auth:=get_tree().get_first_node_in_group("admin_authorization") as AdminAuthorization
	var verified:=auth!=null and bool(get_tree().root.get_meta("server_authority_verified",false))
	var local_dev:=bool(get_tree().root.get_meta("admin_mode_local",false))
	label.text="ADMIN" if verified else ("DEV ADMIN" if local_dev else "")
	visible=not label.text.is_empty() and not InputDeviceProfile.touch_like(get_viewport_rect().size);position=Vector2(12,12)

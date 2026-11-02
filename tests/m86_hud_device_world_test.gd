extends Node
func _ready()->void:
	var rows:=HudLayoutQaProfiles.profiles()
	assert(rows.size()>=6)
	var notch:=HudLayoutQaProfiles.profile(2)
	assert(str(notch.id)=="phone_notch")
	var safe:=HudLayoutQaProfiles.safe_rect(notch)
	assert(safe.position.x>0.0)
	var audit:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m86_zero_area_audit.json"))
	assert(audit.guarded.size()>=10)
	var prod:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m86_asset_production_wave.json"))
	assert(prod.master_first_13.size()==13)
	print("M86_HUD_DEVICE_WORLD_PASS")

extends Node
func _ready()->void:
	var cadence:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m74_pl1_5_content_cadence.json"))
	var feedback:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m74_mobile_feedback_budget.json"))
	var encounter:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m74_encounter_presentation.json"))
	assert(cadence.levels.size()==5)
	assert(float(feedback.provocation_flash_seconds)==2.4)
	assert(encounter.profiles.has("provoked"))
	var neutral:=Node3D.new()
	add_child(neutral)
	neutral.set_meta("passive_until_attacked",true)
	neutral.set_meta("provoked",false)
	assert(EncounterPresentationCatalog.label(neutral)=="NEUTRAL")
	print("M74_FEEDBACK_POLISH_PASS")

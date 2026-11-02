class_name M173MenuProgressionCatalog
extends Node
const PATH := "res://data/m173_menu_progression_interaction.json"
var data:Dictionary={}
func _ready()->void:
	data=JsonDataLoader.load_dictionary(PATH);add_to_group("m173_menu_progression_catalog")
func progression_menu()->Dictionary:return data.get("progression_menu",{}) as Dictionary
func requirement_feedback()->Dictionary:return data.get("requirement_feedback",{}) as Dictionary
func guild_navigation()->Dictionary:return data.get("guild_panel_navigation",{}) as Dictionary
func authoring_guards()->Array:return data.get("authoring_guards",[]) as Array
func summary()->String:return "M173 · Progression-Auswahl/Requirements/Gildenpanel · %d Guards"%authoring_guards().size()

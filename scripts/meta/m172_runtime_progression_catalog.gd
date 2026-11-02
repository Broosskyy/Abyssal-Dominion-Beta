class_name M172RuntimeProgressionCatalog
extends Node
const PATH := "res://data/m172_runtime_progression_interaction.json"
var data:Dictionary={}
func _ready()->void:
	data=JsonDataLoader.load_dictionary(PATH);add_to_group("m172_runtime_progression_catalog")
func bonusmap_contract()->Dictionary:return data.get("bonusmap_runtime_presentation",{}) as Dictionary
func crafting_contract()->Dictionary:return data.get("crafting_feedback",{}) as Dictionary
func shipyard_contract()->Dictionary:return data.get("shipyard_hardening",{}) as Dictionary
func authoring_guards()->Array:return data.get("authoring_guards",[]) as Array
func summary()->String:return "M172 · Bonusmap/Crafting/Shipyard Runtime-Interaktion · %d Guards"%authoring_guards().size()

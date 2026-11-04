class_name M170MobileRuntimeCatalog
extends Node
const PATH := "res://data/m170_mobile_runtime_interaction.json"
var data:Dictionary={}
func _ready()->void:
	data=JsonDataLoader.load_dictionary(PATH);add_to_group("m170_mobile_runtime_catalog")
func overlay_priority()->Array:return data.get("overlay_priority",[]) as Array
func runtime_catalog_audit()->Array:return data.get("runtime_catalog_audit",[]) as Array
func mobile_screen_audit()->Array:return data.get("mobile_screen_audit",[]) as Array
func interaction_guards()->Array:return data.get("interaction_guards",[]) as Array
func summary()->String:return "M170 · %d Runtime-Bindings · %d Mobile-Screens · %d Interaction-Guards"%[runtime_catalog_audit().size(),mobile_screen_audit().size(),interaction_guards().size()]

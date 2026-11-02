class_name M171RuntimePresentationCatalog
extends Node
const PATH := "res://data/m171_runtime_presentation_interaction.json"
var data:Dictionary={}
func _ready()->void:
	data=JsonDataLoader.load_dictionary(PATH);add_to_group("m171_runtime_presentation_catalog")
func runtime_bindings()->Array:return data.get("runtime_presentation_bindings",[]) as Array
func interaction_audit()->Array:return data.get("interaction_audit",[]) as Array
func authoring_guards()->Array:return data.get("content_authoring_guards",[]) as Array
func summary()->String:return "M171 · %d Präsentationsbindungen · %d Interaktionschecks · %d Guards"%[runtime_bindings().size(),interaction_audit().size(),authoring_guards().size()]

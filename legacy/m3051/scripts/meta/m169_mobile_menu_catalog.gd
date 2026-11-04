class_name M169MobileMenuCatalog
extends Node

const PATH := "res://data/m169_mobile_menu_functionality.json"
var data:Dictionary = {}

func _ready()->void:
	data = JsonDataLoader.load_dictionary(PATH)
	add_to_group("m169_mobile_menu_catalog")

func mobile_profiles()->Array:return data.get("mobile_profiles",[]) as Array
func harbor_tabs()->Array:return data.get("harbor_tabs",[]) as Array
func interaction_audit()->Array:return data.get("interaction_audit",[]) as Array
func progression_connections()->Array:return data.get("progression_connections",[]) as Array
func summary()->String:return "M169 · %d Mobile-Profile · %d Menü-Audits · %d Progressionsbindungen"%[mobile_profiles().size(),interaction_audit().size(),progression_connections().size()]

class_name M176RuntimeFeedbackCatalog
extends Node

const PATH := "res://data/m176_runtime_feedback.json"
var data: Dictionary = {}

func _ready() -> void:
	data = JsonDataLoader.load_dictionary(PATH)
	add_to_group("m176_runtime_feedback_catalog")

static func current(tree: SceneTree) -> M176RuntimeFeedbackCatalog:
	if tree == null:
		return null
	return tree.get_first_node_in_group("m176_runtime_feedback_catalog") as M176RuntimeFeedbackCatalog

func notification_profile(id: String) -> Dictionary:
	var rows := data.get("notification_profiles", {}) as Dictionary
	return (rows.get(id, rows.get("default", {})) as Dictionary).duplicate(true)

func combat_routing() -> Dictionary:
	return data.get("combat_value_routing", {}) as Dictionary

func bonusmap_rules() -> Dictionary:
	return data.get("bonusmap_rules", {}) as Dictionary

func summary() -> String:
	return "M176 · Runtime Feedback · %d Notification-Profile" % (data.get("notification_profiles", {}) as Dictionary).size()

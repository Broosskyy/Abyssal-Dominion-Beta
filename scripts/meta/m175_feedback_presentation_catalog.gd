class_name M175FeedbackPresentationCatalog
extends Node

const PATH := "res://data/m175_feedback_presentation.json"
var data: Dictionary = {}

func _ready() -> void:
	data = JsonDataLoader.load_dictionary(PATH)
	add_to_group("m175_feedback_presentation_catalog")

static func current(tree: SceneTree) -> M175FeedbackPresentationCatalog:
	if tree == null:
		return null
	return tree.get_first_node_in_group("m175_feedback_presentation_catalog") as M175FeedbackPresentationCatalog

func damage_profile(viewport_size: Vector2, touch_like: bool) -> Dictionary:
	var id := "tablet_desktop"
	if touch_like:
		id = "compact_phone" if minf(viewport_size.x, viewport_size.y) < 390.0 else "phone"
	return (data.get("damage_number_profiles", {}) as Dictionary).get(id, {}) as Dictionary

func value_kind(id: String) -> Dictionary:
	return (data.get("value_kinds", {}) as Dictionary).get(id, {}) as Dictionary

func reward_presentation(rarity: String) -> Dictionary:
	var rows := data.get("reward_presentations", {}) as Dictionary
	return rows.get(rarity, rows.get("common", {})) as Dictionary

func vfx_profile(id: String) -> Dictionary:
	return (data.get("vfx_profiles", {}) as Dictionary).get(id, {}) as Dictionary

func hud_contract() -> Dictionary:
	return data.get("immutable_hud_contract", {}) as Dictionary

func summary() -> String:
	return "M175 · Combat/Reward/Mobile Feedback · %d Reward-Stufen" % (data.get("reward_presentations", {}) as Dictionary).size()

class_name M289PlayableVerticalSliceQA
extends Node3D
## Native QA scene adapter. It reports readiness and never fabricates PASS.

var last_snapshot: Dictionary = {}


func _ready() -> void:
	name = "M289PlayableVerticalSliceQA"
	add_to_group("m289_native_qa_scene")
	call_deferred("refresh")


func refresh() -> Dictionary:
	var runtime := get_tree().get_first_node_in_group("playable_vertical_slice_readiness") as M289PlayableVerticalSliceRuntime
	last_snapshot = runtime.readiness_view() if runtime != null else {"milestone":"M289", "native_status":"NOT_EVALUATED", "release_approved":false}
	set_meta("m289_readiness", last_snapshot.duplicate(true))
	return last_snapshot.duplicate(true)


func can_mark_pass() -> bool: return false
func can_approve_release() -> bool: return false

class_name M290FirstSortieIntegrationQA
extends Node3D
## Native QA adapter: reports integration state and cannot create gameplay/native truth.

var last_snapshot: Dictionary = {}


func _ready() -> void:
	name = "M290FirstSortieIntegrationQA"
	add_to_group("m290_native_qa_scene")
	call_deferred("refresh")


func refresh() -> Dictionary:
	var runtime := get_tree().get_first_node_in_group("first_sortie_integration") as M290FirstSortieIntegrationRuntime
	last_snapshot = runtime.presentation_view() if runtime != null else {"milestone":"M290", "status":"RUNTIME_MISSING", "native_status":"NOT_EVALUATED", "release_approved":false}
	set_meta("m290_first_sortie_snapshot", last_snapshot.duplicate(true))
	return last_snapshot.duplicate(true)


func can_simulate_gameplay_event() -> bool: return false
func can_mark_native_pass() -> bool: return false
func can_approve_release() -> bool: return false


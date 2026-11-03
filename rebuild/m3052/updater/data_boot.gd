extends Node
const MODEL=preload("res://updater/data_model.gd")
const RECORD="user://content_active.json"
const PREVIOUS="user://content_previous.json"
const SLOTS=["user://content_a.zip","user://content_b.zip"]
var embedded_revision=0
var active_revision=0
var pending_revision=0
var loaded_slots: Array[String]=[]
var game_loaded=false

func read_record(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var value=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func write_record(value: Dictionary,path: String=RECORD) -> bool:
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(value));file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK

func activate(saved: Dictionary) -> bool:
	if saved.get("slot") not in SLOTS or not MODEL.valid_spec(saved.get("spec")):return false
	if int(saved.spec.revision)<=embedded_revision:return false
	if not MODEL.verify_file(saved.spec,saved.slot):return false
	if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(saved.slot),true):return false
	active_revision=int(saved.spec.revision);loaded_slots.append(saved.slot)
	return true

func _init() -> void:
	var bundled=JSON.parse_string(FileAccess.get_file_as_string("res://assets/content_version.json")) if FileAccess.file_exists("res://assets/content_version.json") else {}
	embedded_revision=int(bundled.get("revision",0));active_revision=embedded_revision
	var saved=read_record(RECORD)
	var failed_trial=bool(saved.get("attempted",false)) and not bool(saved.get("confirmed",false))
	if not failed_trial and activate(saved):pass
	else:
		var previous=read_record(PREVIOUS)
		if activate(previous):saved=previous;write_record(previous)
	pending_revision=active_revision
	# Preserve an unconfirmed trial's fallback; never delete a mounted ZIP.
	var fallback=read_record(PREVIOUS).get("slot","") if not bool(saved.get("confirmed",false)) else ""
	for slot: String in SLOTS:
		if slot not in loaded_slots and slot!=fallback and FileAccess.file_exists(slot):DirAccess.remove_absolute(ProjectSettings.globalize_path(slot))

func accept(spec: Dictionary,source: String) -> String:
	if not MODEL.valid_spec(spec):return "invalid"
	if int(spec.revision)<=active_revision:return "stale"
	var slot=""
	for candidate: String in SLOTS:
		if candidate not in loaded_slots:slot=candidate;break
	if slot.is_empty():return "restart"
	if DirAccess.copy_absolute(source,ProjectSettings.globalize_path(slot))!=OK:return "copy_failed"
	var previous=read_record(RECORD)
	if previous.get("slot") in loaded_slots:write_record(previous,PREVIOUS)
	if not write_record({"slot":slot,"spec":spec,"confirmed":false,"attempted":false}):return "save_failed"
	pending_revision=int(spec.revision)
	if game_loaded:return "restart"
	if not ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(slot),true):return "mount_failed"
	loaded_slots.append(slot);active_revision=int(spec.revision)
	return "mounted"

func prepare_game() -> void:
	game_loaded=true
	var saved=read_record(RECORD)
	if int(saved.get("spec",{}).get("revision",0))==active_revision:
		saved.attempted=true;write_record(saved)

func mark_healthy() -> void:
	var saved=read_record(RECORD)
	if int(saved.get("spec",{}).get("revision",0))==active_revision:
		saved.confirmed=true;write_record(saved)

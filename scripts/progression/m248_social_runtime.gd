class_name M248SocialRuntime
extends Node
## M248 V3.8 Social/Friends/Groups/Chat read-only server replica.
## Local saves cache presentation preferences only; live social membership, delivery, moderation and contribution remain server-authoritative.
signal changed
const PATH := "res://data/m248_social_friends_groups_chat_contract.json"
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_preferences: Dictionary = {"active_channel":"region"}

func contract() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < revision: return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func clear_authoritative_snapshot() -> void:
	revision = -1
	authoritative_snapshot = {}
	changed.emit()

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {"source":"LOCAL_PREVIEW","revision":-1,"summary":{},"friends":[],"group":{},"chat":[],"public_profiles":[],"safety":{},"permissions":{}}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func friend_rows() -> Array:
	var rows = snapshot().get("friends", [])
	return rows as Array if rows is Array else []

func group_state() -> Dictionary:
	var value = snapshot().get("group", {})
	return value as Dictionary if value is Dictionary else {}

func group_member_rows() -> Array:
	var rows = group_state().get("members", [])
	return rows as Array if rows is Array else []

func chat_rows(channel: String = "") -> Array:
	var rows = snapshot().get("chat", [])
	if not rows is Array: return []
	if channel.is_empty(): return rows as Array
	var out: Array = []
	for value in rows:
		if value is Dictionary and str((value as Dictionary).get("channel", "")) == channel: out.append(value)
	return out

func public_profile_rows() -> Array:
	var rows = snapshot().get("public_profiles", [])
	return rows as Array if rows is Array else []

func set_local_preferences(preferences: Dictionary) -> void:
	# Presentation-only preferences never change server social state or moderation.
	local_preferences = preferences.duplicate(true)
	changed.emit()

func active_channel() -> String:
	return str(local_preferences.get("active_channel", "region"))

func export_state() -> Dictionary:
	# Cached server replica is non-authoritative after reconnect; local preferences are the only client-owned state.
	return {"revision":revision,"authoritative_snapshot":authoritative_snapshot.duplicate(true),"local_preferences":local_preferences.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached = state.get("authoritative_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		revision = int(state.get("revision", int((cached as Dictionary).get("revision", -1))))
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
	var prefs = state.get("local_preferences", {})
	if prefs is Dictionary and not (prefs as Dictionary).is_empty(): local_preferences = (prefs as Dictionary).duplicate(true)
	changed.emit()

func can_client_authoritatively_add_friend() -> bool: return false
func can_client_authoritatively_change_group() -> bool: return false
func can_client_authoritatively_deliver_chat() -> bool: return false
func can_client_authoritatively_set_ready() -> bool: return false
func can_client_authoritatively_block_or_mute() -> bool: return false
func can_client_authoritatively_resolve_report() -> bool: return false
func can_client_authoritatively_grant_group_credit() -> bool: return false

class_name CombatFeedback
extends Node
## Bounded presentation-only event buffer. No collision, reward or damage logic.
## Reconstructed from UIDamageText / LocalDamageEventData metadata, not method bodies.

const LIFE := 1.25
const MERGE_WINDOW := 0.12
const DESKTOP_LIMIT := 24
const MOBILE_LIMIT := 24 # M199 parity: UI scale may differ, feedback density may not.
var entries: Array[Dictionary] = []
var _serial := 0


func _ready() -> void:
	add_to_group("combat_feedback")


func _process(delta: float) -> void:
	for index in range(entries.size() - 1, -1, -1):
		entries[index].age += delta
		if float(entries[index].age) >= float(entries[index].get("life", LIFE)):
			entries.remove_at(index)


func clear() -> void:
	entries.clear()


func record_hit(target: Node3D, attacker: Node3D, amount: float, slowed: bool, critical: bool = false) -> void:
	record_value(target, attacker, amount, "critical" if critical else "damage", slowed)


func record_value(target: Node3D, attacker: Node3D, amount: float, kind: String, slowed: bool = false) -> void:
	if not is_instance_valid(target) or not is_finite(amount) or amount <= 0.0:
		return
	var positive := kind in ["heal", "repair", "shield", "block", "armor"]
	var own := (is_instance_valid(attacker) and attacker.is_in_group("player")) or (positive and target.is_in_group("player"))
	var settings := ClientSettings.current(get_tree())
	if settings != null and bool(settings.values.only_own_damage) and not own:
		return
	var target_id := target.get_instance_id()
	var attacker_id := attacker.get_instance_id() if is_instance_valid(attacker) else 0
	var profile := _profile()
	var merge_window := float(profile.get("merge_window", MERGE_WINDOW))
	if entries.size() >= int(profile.get("crowd_threshold", 8)):
		merge_window = float(profile.get("crowd_merge_window", merge_window))
	var kind_profile := _kind_profile(kind)
	# One short-window sum per target/source/kind; never merge player and NPC hits.
	for entry in entries:
		if entry.target_id == target_id and entry.attacker_id == attacker_id and entry.kind == kind and entry.age < merge_window:
			entry.amount += amount
			entry.slowed = entry.slowed or slowed
			return
	_serial += 1
	var anchor := target.get_node_or_null("Anchors/Nameplate") as Node3D
	var position := anchor.global_position if anchor != null else target.global_position + Vector3.UP * 3.6
	entries.append({"target_id": target_id, "attacker_id": attacker_id, "own": own,
		"incoming": target.is_in_group("player"), "amount": amount, "critical": kind == "critical",
		"kind": kind, "priority": int(kind_profile.get("priority", 1)), "scale": float(kind_profile.get("scale", 1.0)),
		"slowed": slowed, "position": position, "age": 0.0, "life": float(profile.get("life", LIFE)), "serial": _serial})
	while entries.size() > entry_limit():
		var remove_index := 0
		for index in entries.size():
			if int(entries[index].get("priority", 1)) < int(entries[remove_index].get("priority", 1)):
				remove_index = index
		entries.remove_at(remove_index)


func entry_limit() -> int:
	return int(_profile().get("max_entries", MOBILE_LIMIT if bool(get_tree().root.get_meta("touch_ui", false)) else DESKTOP_LIMIT))


func _profile() -> Dictionary:
	var catalog := M175FeedbackPresentationCatalog.current(get_tree())
	if catalog == null:
		return {}
	return catalog.damage_profile(get_viewport().get_visible_rect().size, bool(get_tree().root.get_meta("touch_ui", false)))


func _kind_profile(id: String) -> Dictionary:
	var catalog := M175FeedbackPresentationCatalog.current(get_tree())
	return catalog.value_kind(id) if catalog != null else {}


func display_entries() -> Array[Dictionary]:
	var settings := ClientSettings.current(get_tree())
	if settings != null and not settings.values.show_damage: return []
	var own_only := settings != null and bool(settings.values.only_own_damage)
	var effects := settings == null or bool(settings.values.effect_texts)
	var result: Array[Dictionary] = []
	for entry in entries:
		if own_only and not bool(entry.own):
			continue
		var item := entry.duplicate()
		var kind_profile := _kind_profile(str(entry.get("kind", "damage")))
		var suffix := str(kind_profile.get("suffix", "")) if effects else ""
		item.text = "%s%d%s" % [str(kind_profile.get("prefix", "−")), maxi(1, roundi(float(entry.amount))), suffix]
		if effects:
			if entry.slowed:
				item.text += " LANGSAM"
		var life := float(entry.get("life", LIFE))
		item.alpha = clampf((life - float(entry.age)) / 0.4, 0.0, 1.0)
		item.scale = float(entry.get("scale", 1.0)) * float(_profile().get("base_scale", 1.0))
		result.append(item)
	return result


static func place_label(anchor: Vector2, extent: Vector2, safe: Rect2, occupied: Array[Rect2]) -> Rect2:
	# Hide offscreen/blocked labels instead of piling them against the screen edge.
	if not safe.has_point(anchor) or extent.x > safe.size.x or extent.y > safe.size.y:
		return Rect2()
	for offset in [Vector2(0, -38), Vector2(0, -66), Vector2(0, -94), Vector2(100, -38), Vector2(-100, -38)]:
		var box := Rect2(anchor + offset - extent * 0.5, extent)
		if not safe.encloses(box):
			continue
		var blocked := false
		for other in occupied:
			if box.grow(3.0).intersects(other):
				blocked = true
				break
		if not blocked:
			return box
	return Rect2()

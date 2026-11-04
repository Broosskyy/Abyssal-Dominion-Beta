class_name TargetVisualCatalog
extends RefCounted

static func frame_slot(target: Node3D) -> String:
	if target == null:
		return "hud_target_frame"
	var kind := str(target.get_meta("encounter_kind",""))
	var rank := str(target.get_meta("encounter_rank",""))
	if kind == "monster":
		return "hud_target_monster"
	if bool(target.get_meta("is_admiral",false)) or rank == "boss":
		return "hud_target_admiral"
	if rank == "elite":
		return "hud_target_elite"
	return "hud_target_neutral" if EncounterRelation.status(target) == EncounterRelation.NEUTRAL else "hud_target_hostile"

static func relation_label(target: Node3D) -> String:
	if target == null: return ""
	return EncounterPresentationCatalog.label(target)

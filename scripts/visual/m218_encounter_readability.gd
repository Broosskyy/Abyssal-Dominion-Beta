class_name M218EncounterReadability
extends RefCounted
## Presentation-only encounter-class readability. No damage, collision, movement, reward or pickup authority.

static func sink_class_read(ship: Node3D) -> void:
	if ship == null or not is_instance_valid(ship): return
	var rarity := str(ship.get_meta("rarity", "common"))
	var kind := str(ship.get_meta("encounter_kind", "ship"))
	var encounter_class := "monster" if kind == "monster" or ship.is_in_group("monsters") else ("admiral" if bool(ship.get_meta("is_admiral", false)) or rarity == "boss" else ("elite" if rarity == "elite" else "normal"))
	ship.set_meta("m218_sink_class", encounter_class)
	ship.set_meta("m218_sink_read_until", Time.get_ticks_msec() + (1450 if encounter_class in ["admiral","monster"] else (1100 if encounter_class == "elite" else 850)))

static func boss_phase_read(ship: Node3D, phase: int) -> void:
	if ship == null or not is_instance_valid(ship): return
	ship.set_meta("m218_phase_shift", phase)
	ship.set_meta("m218_phase_shift_until", Time.get_ticks_msec() + 1800)
	ship.set_meta("m218_phase_label", "PHASE %d" % phase)

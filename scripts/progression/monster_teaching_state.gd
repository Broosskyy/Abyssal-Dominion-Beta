class_name MonsterTeachingState
extends RefCounted
## Session-only presentation state. Never changes progression, loot, combat or rewards.

static func visible(player:Node)->bool:
	if player==null:return false
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if voyage==null or voyage.map_level()!=3:return false
	return not bool(player.get_meta("m93_monster_teaching_seen",false))

static func dismiss(player:Node,reason:String)->void:
	if player==null:return
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if voyage!=null and voyage.map_level()==3:
		player.set_meta("m93_monster_teaching_seen",true)
		player.set_meta("m93_monster_teaching_reason",reason)

static func mark_harpoon_selected(player:Node)->void:
	dismiss(player,"harpoon_selected")

static func mark_monster_harpoon_hit(player:Node)->void:
	dismiss(player,"monster_harpoon_hit")

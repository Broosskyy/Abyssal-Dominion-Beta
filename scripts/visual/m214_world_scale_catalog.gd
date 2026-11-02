class_name M214WorldScaleCatalog
extends RefCounted
## Visual-master scale hierarchy only. Never changes collision, weapon range or navigation.

const SHIP_VISUAL_SCALE := {
	"player": 1.00,
	"npc_light": 0.88,
	"npc_standard": 0.96,
	"npc_heavy": 1.08,
	"elite": 1.12,
	"admiral": 1.18,
	"boss_ship": 1.24,
}
const ISLAND_RADIUS_CLASS := {
	"xs": Vector2(3.5, 5.5),
	"small": Vector2(5.5, 8.0),
	"medium": Vector2(8.0, 12.0),
	"large": Vector2(12.0, 18.0),
	"landmark": Vector2(18.0, 28.0),
}
const MONSTER_VISUAL_SCALE := {
	"normal": 0.92,
	"hunter": 1.04,
	"elite": 1.14,
	"boss": 1.28,
	"world_boss": 1.42,
}

static func ship_scale(role:String)->float:
	return float(SHIP_VISUAL_SCALE.get(role, 0.96))

static func island_class(radius:float)->String:
	if radius < 5.5:return "xs"
	if radius < 8.0:return "small"
	if radius < 12.0:return "medium"
	if radius < 18.0:return "large"
	return "landmark"

static func annotate_ship(ship:Node3D, role:String)->void:
	if ship==null:return
	ship.set_meta("m214_visual_role", role)
	ship.set_meta("m214_visual_scale", ship_scale(role))
	ship.set_meta("m214_scale_visual_only", true)

static func annotate_island(island:Node3D, radius:float)->void:
	if island==null:return
	island.set_meta("m214_island_class", island_class(radius))
	island.set_meta("m214_landmark", radius >= 18.0)
	island.set_meta("m214_scale_visual_only", true)

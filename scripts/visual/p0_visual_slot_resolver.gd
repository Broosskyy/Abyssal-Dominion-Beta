class_name P0VisualSlotResolver
extends RefCounted

const MASTER_TO_RUNTIME := {
	"SHIP-STARTER-001":"ship_small", "SHIP-STARTER-002":"ship_medium", "SHIP-STARTER-003":"ship_large",
	"NPC-SHIP-EARLY-001":"npc_friendly_coastal_sloop", "NPC-SHIP-EARLY-002":"npc_scout_01",
	"NPC-SHIP-EARLY-003":"npc_raider_01", "NPC-SHIP-EARLY-004":"npc_gunship_01", "NPC-SHIP-EARLY-005":"npc_heavy_01",
	"HARBOR-HAVENS-REACH":"harbor_havens_reach", "ISLAND-P0-001":"island_tropical_small",
	"ISLAND-P0-002":"island_tropical_medium", "ISLAND-P0-003":"island_cliff_cove", "ISLAND-P0-004":"island_sandbar_long",
	"MON-KRAKEN-001":"monster_early_01"
}

static func runtime_id(value: String) -> String:
	return str(MASTER_TO_RUNTIME.get(value, value))

static func npc_slot(ship: Node3D, profile_name: String) -> String:
	var production := str(ship.get_meta("production_slot",""))
	if not production.is_empty(): return runtime_id(production)
	if bool(ship.get_meta("is_admiral",false)): return "npc_admiral"
	var combat_level := int(ship.get_meta("combat_level", 999))
	# M69: generic P0 archetype mapping is strictly an early-game fallback.
	# Higher-level regional NPCs must use explicit production slots or their normal profile fallback.
	if combat_level <= BeginnerRules.LAST_BEGINNER_LEVEL:
		var archetype := str(ship.get_meta("archetype",""))
		match archetype:
			"scout": return "npc_scout_01"
			"tank": return "npc_heavy_01"
			"sniper": return "npc_gunship_01"
			"raider": return "npc_raider_01"
		if bool(ship.get_meta("passive_until_attacked",false)) and archetype.is_empty():
			return "npc_friendly_coastal_sloop"
	return AssetVisualLibrary.ship_slot(profile_name, ship.is_in_group("enemies"))

static func island_slot(island: Node3D, profile_name: String) -> String:
	var production := str(island.get_meta("production_slot",""))
	if not production.is_empty(): return runtime_id(production)
	var r := float(island.get_meta("island_radius",5.0))
	var a: Vector2 = island.get_meta("island_aspect",Vector2.ONE)
	if profile_name.begins_with("tropical"):
		if maxf(a.x,a.y) >= 1.35 or minf(a.x,a.y) <= 0.72:
			return "island_cliff_cove"
		return "island_tropical_small" if r < 7.0 else "island_tropical_medium"
	return "island_snow" if profile_name.begins_with("snow") else ("island_rock" if profile_name.begins_with("desert") else "island_tropical")

static func harbor_slot(port: Node3D) -> String:
	var production := str(port.get_meta("production_slot", ""))
	if not production.is_empty(): return runtime_id(production)
	var harbor_id:=str(port.get_meta("harbor_id",""))
	if harbor_id.is_empty():
		harbor_id=str(port.name).to_lower().replace("'","").replace(" ","_")
	return "harbor_havens_reach" if harbor_id=="havens_reach" else "harbor"

static func monster_slot(monster: Node3D) -> String:
	var production := str(monster.get_meta("production_slot",""))
	return runtime_id(production) if not production.is_empty() else "monster_early_01"

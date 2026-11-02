class_name M185MenuStatusCatalog
extends Node
## Honest menu-state summaries backed by the same runtime data as mutations.

const PATH := "res://data/m185_menu_content_clarity.json"
var data: Dictionary = {}

func _ready() -> void:
	add_to_group("m185_menu_status_catalog")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary: data = parsed

static func context(player: ShipMotor) -> Dictionary:
	if player == null: return {"title":"SPIELSTATUS", "state":"NICHT VERFÜGBAR", "detail":"Spielerzustand fehlt", "tone":"danger"}
	var inventory := player.get_node("Inventory") as PlayerInventory
	var world := player.get_tree().get_first_node_in_group("world_map") as WorldMapSystem
	var at_port := inventory.at_port()
	var region := inventory.current_region_id()
	var map_name := world.current_map_name() if world != null else "Unbekannte Seekarte"
	return {
		"title":"STANDORT",
		"state":"IM HAFEN" if at_port else "AUF SEE",
		"detail":"%s%s" % [map_name, " · %s" % region.replace("_", " ").capitalize() if not region.is_empty() else ""],
		"tone":"ready" if at_port else "info"
	}

static func bonusmap(id: String, progress: Node, map_level: int, inventory: PlayerInventory) -> Dictionary:
	if progress == null or inventory == null:
		return {"title":id.to_upper(), "state":"NICHT GELADEN", "detail":"Laufzeit nicht verfügbar", "tone":"danger", "progress":0.0}
	var required_level := 99
	var item := ""
	var cost := 0
	var active := bool(progress.get("active"))
	var wave := int(progress.get("wave"))
	var total_waves := 0
	var completions := int(progress.get("completions"))
	var extra := ""
	if progress is ExtendedBonusMapProgress:
		var cfg := (progress as ExtendedBonusMapProgress).config()
		required_level = int(cfg.get("eligibility_level", 99)); item = str(cfg.get("entry_item", "")); cost = int(cfg.get("entry_cost", 0)); total_waves = (cfg.get("waves", []) as Array).size()
	elif progress is GoldBonusMapProgress:
		var cfg := (progress as GoldBonusMapProgress).data()
		required_level = int(cfg.get("eligibility_level", 18)); item = "gold_chart_fragment"; cost = int((cfg.get("entry", {}) as Dictionary).get("gold_chart_fragments", 12)); total_waves = (progress as GoldBonusMapProgress).runtime_waves().size(); extra = " · Pity %d" % int((progress as GoldBonusMapProgress).pity_tokens)
	elif progress is AbyssBonusMapProgress:
		required_level = int((progress as AbyssBonusMapProgress).cfg("eligibility_level", 26)); item = (progress as AbyssBonusMapProgress).entry_item(); cost = (progress as AbyssBonusMapProgress).entry_cost(); total_waves = (progress as AbyssBonusMapProgress).kills().size()
	var owned := inventory.count(item) if not item.is_empty() else 0
	var state := "BEREIT"
	var tone := "ready"
	var detail := "%d/%d %s · ab PL%d · Abschlüsse %d%s" % [owned, cost, item.replace("_", " ").capitalize(), required_level, completions, extra]
	if active:
		state = "AKTIV · WELLE %d/%d" % [wave, maxi(1, total_waves)]; tone = "active"; detail = "Instanzfortschritt gespeichert · Abschlüsse %d%s" % [completions, extra]
	elif map_level < required_level:
		state = "GESPERRT · PL%d" % required_level; tone = "locked"
	elif not inventory.at_port():
		state = "NUR IM HAFEN"; tone = "warning"
	elif owned < cost:
		state = "FRAGMENTE FEHLEN"; tone = "warning"
	return {"title":"%s-BONUSMAP" % id.to_upper(), "state":state, "detail":detail, "tone":tone, "progress":float(wave) / float(maxi(1, total_waves)) if active else clampf(float(owned) / float(maxi(1, cost)), 0.0, 1.0)}


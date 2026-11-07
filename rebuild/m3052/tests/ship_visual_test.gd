extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	check(VISUALS.damage_state(2400,2400)==0,"healthy ship is intact")
	check(VISUALS.damage_state(840,2400)==1,"low HP uses damage state without a separate obsolete skin")
	check(VISUALS.damage_state(0,2400)==2,"zero HP is sunk")
	var headings=[Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
	for i in range(8):
		check(VISUALS.heading_eight(headings[i])==i,"eight compass headings remain correct "+str(i))
	check(VISUALS.heading_eight(Vector2.ZERO,6)==6,"stationary ship retains previous heading")
	var sample=[{"type":"impact","pos":Vector2.ZERO,"actor":4,"time":1.0,"value":31},{"type":"impact","pos":Vector2.ZERO,"actor":4,"time":1.08,"value":31}]
	check(VISUALS.impact_labels(sample,1.2).size()==1,"impact labels group simultaneous volleys")
	check(not VISUALS.landmark_label_visible(Vector2.ZERO,[{"hp":100,"pos":Vector2(0,50)}]),"captain suppresses overlapping landmark label")
	check(ResourceLoader.exists("res://assets/player/schattenkriegsschiff_shaded.glb"),"approved shaded captain GLB exists")
	check(ResourceLoader.exists("res://assets/npc/meshy/models/black_crown_corsair_elite_test.glb"),"original Black Crown Corsair Elite 1 GLB exists")
	check(ResourceLoader.exists("res://assets/player/black_crown_elite_1_preview.png"),"Elite 1 shipyard preview exists")
	for old_path in ["res://assets/player/test_ships/base_basic_pbr.glb","res://assets/player/test_ships/gemi11_uv.glb","res://assets/generated/ships/starter_small_8_intact.png","res://assets/fleet/redkorsar.png"]:
		check(not ResourceLoader.exists(old_path),"retired ship asset is not present: "+old_path)
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

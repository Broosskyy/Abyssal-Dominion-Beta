class_name MonsterAnimationAdapter
extends RefCounted
## Optional visual bridge. Gameplay never waits for or derives state from animation clips.

static func prepare(root: Node3D) -> Dictionary:
	var result := {"animation_player": false, "animation_tree": false, "available": []}
	if root == null: return result
	var players := root.find_children("*","AnimationPlayer",true,false)
	if players.is_empty(): return result
	var player := players[0] as AnimationPlayer
	result.animation_player = true
	for library_name in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		for animation_name in library.get_animation_list():
			result.available.append(str(animation_name))
	var trees := root.find_children("*","AnimationTree",true,false)
	result.animation_tree = not trees.is_empty()
	root.set_meta("m68_animation_contract_ready",true)
	return result

static func play_if_present(root: Node3D, aliases: Array) -> bool:
	if root == null: return false
	var players := root.find_children("*","AnimationPlayer",true,false)
	if players.is_empty(): return false
	var player := players[0] as AnimationPlayer
	for candidate in aliases:
		if player.has_animation(str(candidate)):
			player.play(str(candidate))
			return true
	return false


static func semantic_acceptance(root:Node3D)->Dictionary:
	var result:=prepare(root)
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m102_monster_animation_acceptance.json"))
	var aliases:Dictionary=parsed.get("semantic_aliases",{}) if parsed is Dictionary else {}
	var matched:Dictionary={}
	for semantic in aliases:
		matched[semantic]=false
		for candidate in aliases[semantic]:
			if str(candidate) in result.get("available",[]):matched[semantic]=true;break
	result["semantic"]=matched
	var complete:=true
	for semantic in ["idle","attack","hit","death"]:
		if not bool(matched.get(semantic,false)):complete=false
	result["final_hero_animation_ready"]=complete
	return result

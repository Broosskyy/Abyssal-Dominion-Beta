class_name ProgressionBandOverlay
extends RefCounted
static func apply(level_id:int,base:Dictionary)->Dictionary:
	var out:=base.duplicate(true)
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null:return out
	var registry:=LiveConfigRegistry.current(tree)
	if registry==null:return out
	var override:=registry.dictionary("rules.progression.levels."+str(level_id),{})
	for key in override.keys():out[key]=override[key]
	return out

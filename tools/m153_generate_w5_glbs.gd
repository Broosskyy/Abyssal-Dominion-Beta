extends SceneTree

func _initialize() -> void:
	_generate.call_deferred()

func _generate() -> void:
	var output_root := "res://assets/production_placeholders/late_fleet/w5/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_root))
	for row in W5ProductionBatch.all():
		var base_entry := ShipProductionArchitecture.entry(str(row.id))
		base_entry.merge(row, true)
		for lod in range(3):
			var model := W5PlaceholderFactory.create(base_entry, lod)
			var document := GLTFDocument.new(); var state := GLTFState.new()
			var append_error := document.append_from_scene(model, state)
			assert(append_error == OK)
			var key := "lod%d_path" % lod
			var target := ProjectSettings.globalize_path(str(row.get(key, "")))
			var write_error := document.write_to_filesystem(state, target)
			assert(write_error == OK)
			model.free()
	print("M153_W5_GLB_GENERATION_PASS ships=10 glbs=30")
	quit()

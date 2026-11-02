extends SceneTree
## QA original staged SeaBattles/SeaOfBones source sprite atlas rows.
## Writes real atlas strips from source into build artifact for manual inspection.
## A frame is NOT assumed intact just because its row index is zero.
const ADAPTER = preload("res://scripts/classic/m3035_render_adapter.gd")
const TARGETS := [
	{"pack":"seabattles", "name":"PlayerShip"},
	{"pack":"seabattles", "name":"NPC_0"},
	{"pack":"seabattles", "name":"NPC_1"},
	{"pack":"seabattles", "name":"NPC_2"},
	{"pack":"seaofbones", "name":"PlayerShip"},
	{"pack":"seaofbones", "name":"NPC_0"},
	{"pack":"seaofbones", "name":"NPC_1"}
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := "res://builds/atlas_audit"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var result: Array[Dictionary] = []
	for target: Dictionary in TARGETS:
		ADAPTER.active_pack = str(target["pack"])
		var name := str(target["name"])
		var cfg: Dictionary = ADAPTER.actor_config(name)
		var path: String = ADAPTER.local_path(name)
		if path.is_empty():
			push_error("Missing source atlas for " + str(target))
			quit(1)
			return
		var tex := load(path) as Texture2D
		if tex == null:
			push_error("Cannot decode atlas " + path)
			quit(1)
			return
		var img: Image = tex.get_image()
		if img.is_compressed():
			img.decompress()
		var cols := maxi(1, int(cfg.get("columns", 4)))
		var rows := maxi(1, int(cfg.get("rows", 2)))
		var cell_w := img.get_width() / cols
		var cell_h := img.get_height() / rows
		var opaque: Array[float] = []
		for row in rows:
			for col in cols:
				var frame := img.get_region(Rect2i(col*cell_w,row*cell_h,cell_w,cell_h))
				var n_opaque := 0
				for y in range(0, frame.get_height(), 8):
					for x in range(0, frame.get_width(), 8):
						if frame.get_pixel(x,y).a > 0.50:
							n_opaque += 1
				var area := ceili(float(frame.get_width()*frame.get_height())/64.0)
				opaque.append(float(n_opaque)/float(maxi(1,area)))
				# Separate real images: can inspect which frame is intact, which wreck.
				var out := "%s/%s_%s_row%d_col%d.png" % [folder, str(target["pack"]), name, row, col]
				var status := frame.save_png(ProjectSettings.globalize_path(out))
				if status != OK:
					push_error("Failed saving " + out)
					quit(1)
					return
		result.append({"pack":target["pack"],"actor":name,
			"source":cfg.get("path",path),"cols":cols,"rows":rows,
			"alpha_coverage_by_frame":opaque,
			"verified_healthy_row":cfg.get("verified_healthy_row","UNVERIFIED")})
	var report := JSON.stringify({"audit":"M304.7 ship atlas integrity", "sources":result}, "  ")
	var stream := FileAccess.open(ProjectSettings.globalize_path(folder + "/atlas_audit.json"), FileAccess.WRITE)
	if stream != null:
		stream.store_string(report)
		stream.close()
	print(report)
	quit(0)

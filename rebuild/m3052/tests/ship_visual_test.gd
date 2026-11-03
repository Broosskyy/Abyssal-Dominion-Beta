extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	var entries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visuals/ship_frames.json")).entries
	check(entries.size()==26,"all 26 runtime ship sources have measured frames")
	var headings=[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]
	for i in 4:check(VISUALS.heading_column(headings[i])==i,"authored direction order %d"%i)
	check(VISUALS.heading_column(Vector2(1,-0.03),3)==3 and VISUALS.heading_column(Vector2(1,0.03),3)==3,"small course jitter near east does not alternate atlas frames")
	check(VISUALS.facing_right(Vector2(1,0),false) and not VISUALS.facing_right(Vector2(-1,0),true),"east/west course changes actual reflection")
	check(VISUALS.facing_right(Vector2(0.01,-1),true) and not VISUALS.facing_right(Vector2(-0.01,-1),false),"vertical-course jitter retains prior reflection")
	var directional=0
	var singles=0
	var frames=0
	var ground=Vector2(300,240)
	for path in entries:
		var descriptor: Dictionary=entries[path]
		if descriptor.kind=="directional":directional+=1
		else:singles+=1
		var texture: Texture2D=load("res://"+str(path))
		check(texture!=null and texture.get_size()==Vector2(descriptor.size[0],descriptor.size[1]),"source texture dimensions match measurements: "+path)
		for frame: Dictionary in descriptor.frames:
			frames+=1
			var g: Dictionary=VISUALS.geometry(frame,156)
			var source: Rect2=g.source
			var dest: Rect2=g.destination
			check(source.position.x>=0 and source.position.y>=0 and source.end.x<=texture.get_width() and source.end.y<=texture.get_height(),"trimmed source stays within actual atlas: "+path)
			check(dest.size.x>0 and dest.size.y>0,"no negative destination rectangle used for reflections: "+path)
			check(is_equal_approx(maxf(dest.size.x,dest.size.y),156),"visible motif, not empty cell, determines world size: "+path)
			for flipped in [false,true]:
				var world: Rect2=VISUALS.world_rect(frame,ground,156,flipped)
				check(world.has_point(ground),"hull waterline stays under actor/target point when reflected: "+path)
				check(world.position.distance_to(ground)<220,"no whole-ship sideways jump: "+path)
			if descriptor.kind=="directional":check(int(frame.row)==1,"full sails retained independently of HP: "+path)
	check(directional==16 and singles==10 and frames==74,"16 four-view atlases plus ten honestly identified single-view sources")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

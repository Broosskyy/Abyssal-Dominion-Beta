extends SceneTree
const VISUALS=preload("res://ship_visuals.gd")
var failures: Array[String]=[]
var count:=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	var entries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visuals/ship_frames.json")).entries
	check(entries.size()==28,"26 retained sources and both Small Starter states have measured frames")
	var headings=[Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1),Vector2(1,1)]
	for i in 4:check(VISUALS.heading_column(headings[i])==i,"authored direction order %d"%i)
	check(VISUALS.heading_column(Vector2(1,-0.03),3)==3 and VISUALS.heading_column(Vector2(1,0.03),3)==3,"small course jitter near east does not alternate atlas frames")
	check(VISUALS.facing_right(Vector2(1,0),false) and not VISUALS.facing_right(Vector2(-1,0),true),"east/west course changes actual reflection")
	check(VISUALS.facing_right(Vector2(0.01,-1),true) and not VISUALS.facing_right(Vector2(-0.01,-1),false),"vertical-course jitter retains prior reflection")
	var eight_headings=[Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
	for i in 8:check(VISUALS.heading_eight(eight_headings[i])==i,"Small Starter compass direction %d"%i)
	check(VISUALS.heading_eight(Vector2.ZERO,6)==6,"stationary Small Starter retains last direction")
	check(VISUALS.heading_eight(Vector2.from_angle(-PI*0.375+0.02),0)==0,"course jitter retains north at boundary")
	check(VISUALS.heading_eight(Vector2.from_angle(-PI*0.375+0.09),0)==1,"direction changes after crossing hysteresis band")
	check(VISUALS.heading_eight(Vector2(-0.01,-1),0)==0,"north direction wraps across angular boundary")
	check(VISUALS.damage_state(2400,2400)==0,"full hull always uses intact state")
	check(VISUALS.damage_state(841,2400)==0,"hull above 35 percent stays intact")
	check(VISUALS.damage_state(840,2400)==1,"35 percent damage-state boundary is inclusive")
	check(VISUALS.damage_state(1,2400)==1,"positive critically low hull remains damaged and afloat")
	check(VISUALS.damage_state(0,2400)==2 and VISUALS.damage_state(-1,2400)==2,"zero and negative hull are sunk, not another sail state")
	check(VISUALS.damage_state(1260,3600)==1,"state boundary follows upgraded maximum hull")
	check(VISUALS.damage_state(1,0)==0,"invalid maximum hull does not divide by zero")
	var intact: Dictionary=entries["assets/generated/ships/starter_small_8_intact.png"]
	var damaged: Dictionary=entries["assets/generated/ships/starter_small_8_damaged.png"]
	check(intact.headings==damaged.headings and intact.size==damaged.size,"paired states keep the same heading order and canvas")
	for i in 8:
		var fa: Dictionary=intact.frames[i]
		var fb: Dictionary=damaged.frames[i]
		var a=Vector2(fa.rect[0]+fa.pivot[0],fa.rect[1]+fa.pivot[1])
		var b=Vector2(fb.rect[0]+fb.pivot[0],fb.rect[1]+fb.pivot[1])
		check(a.distance_to(b)<=1.01,"paired hull registration stays within one source pixel %d"%i)
		check(fa.reference_extent==fb.reference_extent,"state change preserves magnification %d"%i)
	var directional=0
	var singles=0
	var eight_sources=0
	var frames=0
	var ground=Vector2(300,240)
	for path in entries:
		var descriptor: Dictionary=entries[path]
		if descriptor.kind=="directional":directional+=1
		elif descriptor.kind=="eight_direction":eight_sources+=1
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
			if descriptor.kind=="eight_direction":
				check(is_equal_approx(float(g.scale),156.0/350.0),"fixed magnification across projected hull lengths: "+path)
			else:
				check(is_equal_approx(maxf(dest.size.x,dest.size.y),156),"visible motif, not empty cell, determines world size: "+path)
			for flipped in [false,true]:
				var world: Rect2=VISUALS.world_rect(frame,ground,156,flipped)
				check(world.has_point(ground),"hull waterline stays under actor/target point when reflected: "+path)
				check(world.position.distance_to(ground)<220,"no whole-ship sideways jump: "+path)
			if descriptor.kind=="directional":check(int(frame.row)==1,"full sails retained independently of HP: "+path)
	check(directional==16 and singles==10 and eight_sources==2 and frames==90,"16 four-view atlases, ten concept originals, eight intact plus eight damaged starter frames")
	var result={"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

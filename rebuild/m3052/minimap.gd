extends Control
const CONTENT=preload("res://content.gd")
## Chart squares shared by the minimap header and the sea-edge rulers.
const SQUARE:=144.0
var simulation: RefCounted
var camera_world:=Vector2.ZERO
var view_world:=Vector2(1600,900)
signal course_requested(point: Vector2)
static func column_name(x: float) -> String:return str(floori(maxf(x,0.0)/SQUARE)+1)
static func row_name(y: float) -> String:
	var index=floori(maxf(y,0.0)/SQUARE)
	var letters=""
	while true:
		letters=String.chr(65+index%26)+letters
		index=floori(index/26.0)-1
		if index<0:break
	return letters
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_STOP
func chart_rect() -> Rect2:return Rect2(Vector2(9,24),size-Vector2(18,44))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var inner=chart_rect()
		if inner.has_point(event.position):course_requested.emit((event.position-inner.position)/inner.size*simulation.WORLD)
		accept_event()
func _draw() -> void:
	if simulation==null:return
	var gold=Color("c9a35e")
	var wood_top=Color("4a3420");var wood_bottom=Color("24170c")
	draw_rect(Rect2(Vector2(0,2),size),Color(0,0,0,.4))
	draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]),PackedColorArray([wood_top,wood_top,wood_bottom,wood_bottom]))
	for y in range(5,int(size.y)-4,7):draw_line(Vector2(4,y),Vector2(size.x-4,y+2),Color(0,0,0,.12),1)
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),gold,false,1.5)
	draw_rect(Rect2(Vector2.ONE*4,size-Vector2.ONE*8),Color("7b5c33"),false,1)
	var font=ThemeDB.fallback_font
	var region: Dictionary=CONTENT.MAPS[simulation.map_id]
	var header="(%s)  X: %s  Y: %s" % [region.code,column_name(simulation.player.pos.x),row_name(simulation.player.pos.y)]
	var hw=font.get_string_size(header,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_string_outline(font,Vector2((size.x-hw)*.5,17),header,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("120b05"))
	draw_string(font,Vector2((size.x-hw)*.5,17),header,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f4dfae"))
	var r=chart_rect()
	draw_rect(r.grow(2),Color("120b05"))
	draw_rect(r,Color("0f3a66"))
	var columns=ceili(simulation.WORLD.x/SQUARE);var rows=ceili(simulation.WORLD.y/SQUARE)
	for x in range(1,columns):
		if x%5==0:draw_line(r.position+Vector2(r.size.x*x*SQUARE/simulation.WORLD.x,0),r.position+Vector2(r.size.x*x*SQUARE/simulation.WORLD.x,r.size.y),Color(.6,.8,1,.12),1)
	for y in range(1,rows):
		if y%5==0:draw_line(r.position+Vector2(0,r.size.y*y*SQUARE/simulation.WORLD.y),r.position+Vector2(r.size.x,r.size.y*y*SQUARE/simulation.WORLD.y),Color(.6,.8,1,.12),1)
	for island in simulation.islands:
		var shape=PackedVector2Array()
		for vertex: Vector2 in island.outline:shape.append(r.position+vertex/simulation.WORLD*r.size)
		var fortified: bool=bool(island.get("guild_fortress",false))
		draw_colored_polygon(shape,Color("9c9979") if fortified else Color("8fa17a"))
		if fortified:
			var held: bool=simulation.tower_friendly()
			var owner: String=simulation.tower_tag()
			var crown: Vector2=r.position+island.pos/simulation.WORLD*r.size
			draw_circle(crown,5.5,Color("258f70") if held else Color("d5a654"))
			draw_circle(crown,5.5,Color("fff3c7"),false,1.2,true)
			var tag: String="[%s]" % owner
			var tagwidth: float=font.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
			draw_string_outline(font,crown+Vector2(-tagwidth*.5,-9),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,Color("030c16"))
			draw_string(font,crown+Vector2(-tagwidth*.5,-9),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f2d18a"))
	for sparkle in simulation.sparkles:
		if float(sparkle.respawn)>0:continue
		var p: Vector2=r.position+sparkle.pos/simulation.WORLD*r.size
		draw_circle(p,1.8,Color("7ff5e6"))
	for npc in simulation.npcs:
		if int(npc.hp)<=0:continue
		var p: Vector2=r.position+npc.pos/simulation.WORLD*r.size
		if npc.kind=="tower":
			var held: bool=simulation.tower_friendly()
			draw_rect(Rect2(p-Vector2(2.5,2.5),Vector2(5,5)),Color("9fe7a8") if held else Color("ff8a4c"))
			draw_rect(Rect2(p-Vector2(2.5,2.5),Vector2(5,5)),Color("1a0c04"),false,1)
		else:
			var hostile=bool(npc.aggressive) or bool(region.npc_hostile)
			var color=Color("ff6d5c") if hostile else (Color("f0c35a") if npc.kind=="ship" else Color("d39cf0"))
			draw_circle(p,2.2 if not bool(npc.get("boss",false)) else 3.4,color)
		if int(npc.id)==int(simulation.target):draw_circle(p,4.0,Color("fff0c0"),false,1.2,true)
	for portal in simulation.portals:
		var p: Vector2=r.position+portal.pos/simulation.WORLD*r.size
		draw_circle(p,3.2,Color("a79edb"),false,1.2,true)
	if simulation.has_harbor():
		var port: Vector2=r.position+simulation.harbor/simulation.WORLD*r.size
		# A legible tiny harbor/berth silhouette, not another NPC dot.
		draw_circle(port,5.7,Color("061d2a",.87))
		draw_circle(port,5.7,Color("f4c56c"),false,1.1,true)
		draw_line(port+Vector2(0,-3.2),port+Vector2(0,3.2),Color("f4d68e"),1.6,true)
		draw_circle(port+Vector2(0,-3),1.3,Color("f4d68e"),false,1.1,true)
		draw_arc(port+Vector2(0,1.2),2.8,0,PI,12,Color("f4d68e"),1.5,true)
		draw_line(port-Vector2(3,0),port+Vector2(3,0),Color("f4d68e"),1.2,true)
	var box=Rect2(r.position+(camera_world-view_world*.5)/simulation.WORLD*r.size,view_world/simulation.WORLD*r.size)
	draw_rect(box.intersection(r),Color(.85,.95,1,.75),false,1)
	var player: Vector2=r.position+simulation.player.pos/simulation.WORLD*r.size
	var heading: Vector2=simulation.player.heading
	var side=Vector2(-heading.y,heading.x)
	var staff=simulation.staff
	if staff.shows_badge():
		var pulse=.5+.5*sin(Time.get_ticks_msec()/260.0)
		draw_circle(player,6.5+pulse*2.0,Color(staff.color(),.22))
		draw_arc(player,7.0+pulse*2.0,0,TAU,20,staff.color(),1.4,true)
	elif staff.hidden():
		draw_arc(player,6.5,0,TAU,16,Color(staff.color(),.45),1.0,true)
	draw_colored_polygon(PackedVector2Array([player+heading*5,player-heading*3.5+side*3.5,player-heading*3.5-side*3.5]),Color("9cfff0"))
	var title=str(region.name)
	var tw=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string_outline(font,Vector2((size.x-tw)*.5,size.y-6),title,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,Color("120b05"))
	draw_string(font,Vector2((size.x-tw)*.5,size.y-6),title,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e2c78e"))

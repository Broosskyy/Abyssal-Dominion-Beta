extends Panel
## Menu window: lacquered hull-blue body, carved header with a title ribbon, brass corner fittings.
var header := 52.0
var ribbon := Rect2()
var accent := Color("c9a35e")

func _ready() -> void:
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())

func _poly(points: Array,color) -> void:
	var packed=PackedVector2Array(points)
	if color is Color:draw_colored_polygon(packed,color)
	else:draw_polygon(packed,PackedColorArray(color))

func _draw() -> void:
	if size.x<60 or size.y<60:return
	var w=size.x;var h=size.y
	var gold=accent;var bright=accent.lightened(.35);var deep=Color("2a1d0e")
	for i in 3:draw_rect(Rect2(Vector2(-4-i*3,-2-i*2),size+Vector2(8+i*6,10+i*5)),Color(0,0,0,.12))
	_poly([Vector2(4,4),Vector2(w-4,4),Vector2(w-4,h-4),Vector2(4,h-4)],[Color("10303d"),Color("10303d"),Color("061218"),Color("061218")])
	for i in range(-int(h),int(w),26):draw_line(Vector2(i,h-4),Vector2(i+h*.55,4),Color(1,1,1,.018),1)
	# Header: dark carved wood with a soft lantern light from the middle.
	var head=Rect2(6,6,w-12,header-6)
	_poly([head.position,Vector2(head.end.x,head.position.y),head.end,Vector2(head.position.x,head.end.y)],[Color("3a2a17"),Color("3a2a17"),Color("1a1209"),Color("1a1209")])
	for y in range(int(head.position.y)+5,int(head.end.y)-2,6):draw_line(Vector2(head.position.x+4,y),Vector2(head.end.x-4,y+1),Color(0,0,0,.14),1)
	draw_line(Vector2(10,head.end.y+1),Vector2(w-10,head.end.y+1),Color(0,0,0,.6),3)
	draw_line(Vector2(10,head.end.y),Vector2(w-10,head.end.y),gold,1.6,true)
	_diamond(Vector2(w*.5,head.end.y),6,gold,deep)
	if ribbon.size.x>10:_ribbon(ribbon,gold)
	# Frame: heavy brass rim, inner dark groove and a fine inner gold line.
	draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color("120c06"),false,3)
	draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),gold,false,2.2)
	draw_rect(Rect2(Vector2(6,6),size-Vector2(12,12)),Color(0,0,0,.55),false,1.5)
	draw_rect(Rect2(Vector2(8,header+4),Vector2(w-16,h-header-12)),Color(gold,.28),false,1)
	draw_line(Vector2(12,4.5),Vector2(w-12,4.5),Color(bright,.55),1)
	for corner in [Vector2(0,0),Vector2(w,0),Vector2(w,h),Vector2(0,h)]:_corner(corner,gold,bright,deep)
	for x in [w*.25,w*.75]:
		_stud(Vector2(x,h-3.5),gold)
	for y in [h*.5]:
		_stud(Vector2(3.5,y),gold);_stud(Vector2(w-3.5,y),gold)
	_diamond(Vector2(w*.5,h-3.5),7,gold,deep)

func _ribbon(rect: Rect2,gold: Color) -> void:
	var notch=10.0
	var r=rect
	var tail=PackedVector2Array([Vector2(r.position.x-22,r.position.y+6),Vector2(r.position.x+6,r.position.y+6),Vector2(r.position.x+6,r.end.y+4),Vector2(r.position.x-22,r.end.y+4),Vector2(r.position.x-22+notch,r.get_center().y+5)])
	var tail2=PackedVector2Array([Vector2(r.end.x+22,r.position.y+6),Vector2(r.end.x-6,r.position.y+6),Vector2(r.end.x-6,r.end.y+4),Vector2(r.end.x+22,r.end.y+4),Vector2(r.end.x+22-notch,r.get_center().y+5)])
	for t in [tail,tail2]:
		draw_colored_polygon(t,Color("4a140e"))
		var edge=t.duplicate();edge.append(t[0]);draw_polyline(edge,Color(gold,.7),1.2,true)
	_poly([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)],[Color("8e2a1c"),Color("8e2a1c"),Color("5a170f"),Color("5a170f")])
	draw_line(r.position+Vector2(0,2),Vector2(r.end.x,r.position.y+2),Color(1,.8,.6,.25),1)
	draw_rect(r,gold,false,1.6)
	draw_rect(r.grow(-3),Color(gold,.35),false,1)

func _corner(at: Vector2,gold: Color,bright: Color,deep: Color) -> void:
	var dx=1.0 if at.x<size.x*.5 else -1.0
	var dy=1.0 if at.y<size.y*.5 else -1.0
	var o=at+Vector2(dx,dy)*2
	var plate=PackedVector2Array([o,o+Vector2(dx*30,0),o+Vector2(dx*26,dy*6),o+Vector2(dx*8,dy*8),o+Vector2(dx*6,dy*26),o+Vector2(0,dy*30)])
	draw_colored_polygon(plate,deep)
	var edge=plate.duplicate();edge.append(plate[0])
	draw_polyline(edge,gold,1.6,true)
	draw_arc(o+Vector2(dx,dy)*13,7,0,TAU,20,Color(gold,.8),1.2,true)
	draw_circle(o+Vector2(dx,dy)*13,3.2,bright)
	draw_circle(o+Vector2(dx,dy)*13,1.4,deep)
	for rivet in [o+Vector2(dx*22,dy*3.5),o+Vector2(dx*3.5,dy*22)]:
		draw_circle(rivet,1.8,bright)

func _stud(at: Vector2,gold: Color) -> void:
	draw_circle(at+Vector2(0,1),3.4,Color(0,0,0,.5))
	draw_circle(at,3,gold)
	draw_circle(at-Vector2(.8,.8),1.1,Color(1,.95,.8,.8))

func _diamond(at: Vector2,r: float,gold: Color,deep: Color) -> void:
	var points=PackedVector2Array([at+Vector2(0,-r),at+Vector2(r*1.3,0),at+Vector2(0,r),at+Vector2(-r*1.3,0)])
	draw_colored_polygon(points,deep)
	var edge=points.duplicate();edge.append(points[0])
	draw_polyline(edge,gold,1.4,true)
	draw_circle(at,r*.3,gold)

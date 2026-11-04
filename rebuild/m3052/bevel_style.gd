extends StyleBox
## Runtime-drawn bevel: rounded gradient body, upper sheen, metal rim and optional rivets.
## Drawn under the control's own text, so native wrapping and minimum sizes keep working.
var top := Color("1d3a45")
var bottom := Color("0c1b22")
var border := Color("8a6d40")
var border_width := 1.5
var radius := 6.0
var sheen := 0.16
var shadow := 0.45
var glow := Color(0,0,0,0)
var inner := Color(0,0,0,0)
var rivets := Color(0,0,0,0)
var accent := Color(0,0,0,0)

static func rounded(rect: Rect2,r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	# Keep opposite corner arcs apart: shared vertices make the polygon triangulation fail.
	r = minf(r,minf(rect.size.x,rect.size.y)*.5-.5)
	if r<.75:
		return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var centers := [rect.position+Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),rect.end-Vector2(r,r),Vector2(rect.position.x+r,rect.end.y-r)]
	var starts := [PI,PI*1.5,0.0,PI*.5]
	for c in 4:
		for i in 5:points.append(centers[c]+Vector2.from_angle(starts[c]+PI*.5*float(i)/4.0)*r)
	return points

func _draw(item: RID,rect: Rect2) -> void:
	if rect.size.x<3 or rect.size.y<3:return
	var rs := RenderingServer
	if shadow>0:rs.canvas_item_add_polygon(item,rounded(Rect2(rect.position+Vector2(0,2.5),rect.size),radius+1),PackedColorArray([Color(0,0,0,shadow)]))
	if glow.a>0:
		rs.canvas_item_add_polygon(item,rounded(rect.grow(4),radius+4),PackedColorArray([Color(glow,glow.a*.35)]))
		rs.canvas_item_add_polygon(item,rounded(rect.grow(2),radius+2),PackedColorArray([Color(glow,glow.a*.6)]))
	var body := rounded(rect,radius)
	var colors := PackedColorArray()
	for point in body:colors.append(top.lerp(bottom,clampf((point.y-rect.position.y)/rect.size.y,0,1)))
	rs.canvas_item_add_polygon(item,body,colors)
	if accent.a>0:
		var bar := Rect2(rect.position+Vector2(2,3),Vector2(3,rect.size.y-6))
		rs.canvas_item_add_rect(item,bar,accent)
	if sheen>0 and rect.size.y>8:
		var band := Rect2(rect.position+Vector2(2,1.5),Vector2(rect.size.x-4,rect.size.y*.46))
		var shine := rounded(band,maxf(radius-2,0))
		var tones := PackedColorArray()
		for point in shine:tones.append(Color(1,1,1,sheen*(1.0-clampf((point.y-band.position.y)/band.size.y,0,1))))
		rs.canvas_item_add_polygon(item,shine,tones)
	var outline := body.duplicate();outline.append(body[0])
	rs.canvas_item_add_polyline(item,outline,PackedColorArray([border]),border_width,true)
	if inner.a>0 and rect.size.x>12 and rect.size.y>12:
		var inset := rounded(rect.grow(-3.5),maxf(radius-3,0))
		inset.append(inset[0])
		rs.canvas_item_add_polyline(item,inset,PackedColorArray([inner]),1.0,true)
	if rivets.a>0 and rect.size.x>30 and rect.size.y>22:
		for corner in [rect.position+Vector2(7,7),Vector2(rect.end.x-7,rect.position.y+7),rect.end-Vector2(7,7),Vector2(rect.position.x+7,rect.end.y-7)]:
			rs.canvas_item_add_circle(item,corner+Vector2(0,.8),2.2,Color(0,0,0,.55))
			rs.canvas_item_add_circle(item,corner,1.8,rivets)

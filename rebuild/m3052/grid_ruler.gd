extends Control
## Sea-chart edge rulers: column numbers along the top, row letters down the left edge.
const MINI=preload("res://minimap.gd")
var world_to_screen:=Transform2D.IDENTITY
var hud_scale:=1.0
var top:=50.0
var left_bottom:=300.0
var world_size:=Vector2(4400,3200)
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _hud(world: Vector2) -> Vector2:return world_to_screen*world/hud_scale
func _draw() -> void:
	var font=ThemeDB.fallback_font
	var ink=Color(.86,.93,1,.62)
	var tick=Color(.86,.93,1,.3)
	var shadow=Color(.01,.05,.1,.55)
	var inverse=world_to_screen.affine_inverse()
	var first: Vector2=inverse*Vector2.ZERO
	var last: Vector2=inverse*(size*hud_scale)
	var step=MINI.SQUARE
	var column=floorf(maxf(first.x,0.0)/step)
	while column*step<minf(last.x,world_size.x):
		var edge=_hud(Vector2(column*step,0)).x
		var middle=_hud(Vector2((column+.5)*step,0)).x
		if edge>0:draw_line(Vector2(edge,top),Vector2(edge,top+5),tick,1)
		var label=MINI.column_name((column+.5)*step)
		var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
		if middle-width*.5>4 and middle+width*.5<size.x-4:
			draw_string_outline(font,Vector2(middle-width*.5,top+13),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,shadow)
			draw_string(font,Vector2(middle-width*.5,top+13),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,ink)
		column+=1
	var row=floorf(maxf(first.y,0.0)/step)
	while row*step<minf(last.y,world_size.y):
		var edge=_hud(Vector2(0,row*step)).y
		var middle=_hud(Vector2(0,(row+.5)*step)).y
		if edge>top+16 and edge<left_bottom:draw_line(Vector2(0,edge),Vector2(5,edge),tick,1)
		if middle>top+24 and middle<left_bottom:
			var label=MINI.row_name((row+.5)*step)
			draw_string_outline(font,Vector2(4,middle+4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,shadow)
			draw_string(font,Vector2(4,middle+4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,ink)
		row+=1

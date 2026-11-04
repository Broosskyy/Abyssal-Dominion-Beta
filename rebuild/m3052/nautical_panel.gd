extends Panel
## Reusable brass cornerwork, drawn at runtime without enlarged bitmap borders.
func _draw() -> void:
	if size.x<25 or size.y<25:return
	var gold=Color("b19055")
	var edge=Color(0.93,0.77,0.47,0.28)
	draw_line(Vector2(10,3),Vector2(size.x-10,3),edge,1,true)
	draw_line(Vector2(9,size.y-3),Vector2(size.x-9,size.y-3),Color(0,0,0,.55),1)
	for corner in [Vector2(5,5),Vector2(size.x-5,5),Vector2(5,size.y-5),size-Vector2(5,5)]:
		var inward=Vector2(1 if corner.x<size.x*.5 else -1,1 if corner.y<size.y*.5 else -1)
		draw_line(corner,corner+Vector2(inward.x*8,0),gold,1,true)
		draw_line(corner,corner+Vector2(0,inward.y*8),gold,1,true)
		draw_circle(corner,1.6,Color("e2c17c"))

extends ProgressBar
## Value remains authoritative; only the painted fill and loss trail interpolate.
var damage_feedback := true
var motion_enabled := true
var display_ratio := 0.0
var trail_ratio := 0.0
var feedback := 0.0
var loss := false
var initialized := false
var clock := 0.0
var redraw_clock := 0.0
var trail_hold := 0.0
func _ready() -> void:
	add_to_group("living_hud")
	motion_enabled=bool(get_tree().get_meta("abyssal_ui_motion",true))
	value_changed.connect(_changed)
func _changed(_value: float) -> void:
	if not initialized:return
	loss=damage_feedback and ratio<display_ratio
	feedback=1.0 if motion_enabled else 0.0
	trail_hold=.30 if loss else 0.0
	queue_redraw()
func _process(delta: float) -> void:
	var target: float=clampf(ratio,0.0,1.0)
	if not is_visible_in_tree():
		display_ratio=target;trail_ratio=target;feedback=0.0;initialized=true;return
	if not initialized:
		display_ratio=target;trail_ratio=target;initialized=true
	var previous_feedback: float=feedback
	var previous: float=display_ratio
	if not motion_enabled:
		display_ratio=target;trail_ratio=target;feedback=0.0
		if not is_equal_approx(previous,target):queue_redraw()
		return
	clock=fposmod(clock+delta,120.0)
	display_ratio=lerpf(display_ratio,target,1.0-exp(-delta*14.0))
	if absf(display_ratio-target)<.001:display_ratio=target
	trail_hold=maxf(0.0,trail_hold-delta)
	if not damage_feedback:trail_ratio=display_ratio
	elif trail_ratio<display_ratio:trail_ratio=display_ratio
	elif trail_hold<=0.0:trail_ratio=lerpf(trail_ratio,display_ratio,1.0-exp(-delta*5.0))
	feedback=maxf(0.0,feedback-delta*2.0)
	redraw_clock+=delta
	if redraw_clock>=1.0/30.0 and (display_ratio>0.0 or trail_ratio>.001 or feedback>0.0 or previous_feedback>0.0 or previous!=display_ratio):
		redraw_clock=0.0;queue_redraw()
func _draw() -> void:
	if size.x<5 or size.y<5:return
	var background: StyleBox=get_theme_stylebox("background")
	var fill: StyleBox=get_theme_stylebox("fill")
	var tint: Color=fill.bg_color if fill is StyleBoxFlat else Color("57bd79")
	draw_style_box(background,Rect2(Vector2.ZERO,size))
	var inner:=Rect2(Vector2(2,2),size-Vector2(4,4))
	var shown: float=display_ratio if initialized else ratio
	if trail_ratio>shown+.002:
		draw_rect(Rect2(inner.position,Vector2(inner.size.x*trail_ratio,inner.size.y)),Color(tint.lerp(Color("ffb69a"),.6),.55))
	if shown>0:
		var bar:=Rect2(inner.position,Vector2(inner.size.x*shown,inner.size.y))
		var points:=PackedVector2Array([bar.position,Vector2(bar.end.x,bar.position.y),bar.end,Vector2(bar.position.x,bar.end.y)])
		draw_polygon(points,PackedColorArray([tint.lightened(.22),tint.lightened(.14),tint.darkened(.26),tint.darkened(.16)]))
		draw_line(bar.position+Vector2(0,1),Vector2(bar.end.x,bar.position.y+1),Color(1,1,1,.28),1.0)
		draw_line(Vector2(bar.position.x,bar.end.y-1),bar.end-Vector2(0,1),Color(0,0,0,.32),1.0)
		if motion_enabled:
			var sweep: float=fposmod(clock*.16,1.4)-.2
			var x: float=inner.position.x+inner.size.x*sweep
			var left: float=clampf(x-7,bar.position.x,bar.end.x)
			var right: float=clampf(x+7,bar.position.x,bar.end.x)
			if right>left:draw_rect(Rect2(Vector2(left,bar.position.y+1),Vector2(right-left,maxf(1,bar.size.y-2))),Color(1,1,1,.075))
		if feedback>0:draw_rect(bar,Color(Color("ff9578") if loss else Color("e9ffd5"),feedback*.15))
	# Restrained machined edges replace the flat stock rectangles.
	draw_line(Vector2(3,size.y-2),Vector2(size.x-3,size.y-2),Color(0,0,0,.45),1)
	draw_line(Vector2(3,1),Vector2(size.x-3,1),Color(1,.9,.7,.14),1)
	if feedback>0:draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color(tint.lightened(.45),feedback*.6),false,1)

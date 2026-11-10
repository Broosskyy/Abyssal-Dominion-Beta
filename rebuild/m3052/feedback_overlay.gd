extends Control
## Uniform viewport-space combat/reward typography, independent of sea zoom.
var host
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	if host==null or host.sim==null or host.modal.visible:return
	var fs: int=clampi(roundi(get_viewport_rect().size.y/720.0*17.0),16,23)
	var lanes: Dictionary={}
	for event: Dictionary in host.sim.events:
		var age: float=host.sim.clock-float(event.time)
		if age<0 or age>1.65:continue
		var text: String=""
		var ink:=Color("f4d389")
		match str(event.type):
			"impact":
				text="−%d" % int(event.value);ink=Color("ff8c73") if int(event.actor)==0 else Color("fff1cf")
				if bool(event.get("powder",false)):text+="  PULVER +40%";ink=Color("ffb85e")
				if bool(event.get("plates",false)):text+="  PLATTEN −35%";ink=Color("83cfff")
			"level":text="STUFE %d" % int(event.value);ink=Color("ffe6a1")
			"loot":text="+%d GOLD" % int(event.value)
			"essence":text="+%d ESSENZ" % int(event.value);ink=Color("7ce5d1")
			"event_loot":text=str(event.get("label","EVENTFUND"));ink=Color("ffba69")
			_:continue
		var key: String=str(event.actor)+("hit" if event.type=="impact" else "reward")
		var lane: int=int(lanes.get(key,0));lanes[key]=lane+1
		var point: Vector2=host.get_canvas_transform()*event.pos
		point+=Vector2(0,-55-age*30-lane*(fs+6)-(38 if event.type!="impact" else 0))
		var width: float=host.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		point.x=clampf(point.x-width*.5,8.0,maxf(8.0,get_viewport_rect().size.x-width-8))
		if point.y<host.chrome.get_global_rect().end.y+fs:continue
		ink.a=clampf((1.65-age)*1.5,0,1)
		draw_string_outline(host.font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color(.01,.03,.05,ink.a))
		draw_string(host.font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,ink)

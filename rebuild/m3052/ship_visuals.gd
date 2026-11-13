extends RefCounted
## Geometry shared by runtime drawing and renderer regressions.
## Atlas order is NE, NW, SW, SE; it is not clockwise.
const CLOCKWISE_TO_ATLAS := [0,3,2,1]

static func facing_right(heading: Vector2,previous: bool) -> bool:
	if heading.x>0.15:return true
	if heading.x< -0.15:return false
	return previous

static func heading_column(heading: Vector2,previous: int=-1) -> int:
	if previous>=0 and previous<4:
		var angles=[-PI*0.25,-PI*0.75,PI*0.75,PI*0.25]
		if absf(wrapf(heading.angle()-float(angles[previous]),-PI,PI))<=PI*0.25+0.10:
			return previous
	var sector=posmod(roundi((heading.angle()+PI*0.25)/(PI*0.5)),4)
	return CLOCKWISE_TO_ATLAS[sector]

## Classic 2D uses four diagonal atlas views for a pixel-stepped hull
## while the simulated ship follows the true direct course.
## Eight-view atlas order is N, NE, E, SE, S, SW, W, NW.
const CLASSIC_FOUR_VIEW_ATLAS := [1,7,5,3] # NE, NW, SW, SE

static func heading_four(heading: Vector2,previous: int=-1) -> int:
	var prior_column: int=CLASSIC_FOUR_VIEW_ATLAS.find(previous)
	return CLASSIC_FOUR_VIEW_ATLAS[heading_column(heading,prior_column)]

## Frame-measured Seafight 208901: between video 3.85s and 5.18s,
## the GREEN CAPTAIN HP BAR follows a quantized TRIANGLE, not a sine.
## At 2340x1080 pixels: +/-10px perpendicular to a straight westbound
## world course; ~54px forward distance per cycle; ~0.436s observed cycle
## at the captured ship speed. Frame-to-frame position differences are
## about 2 px on EACH axis at ~59 fps. The ring, hull and HP share the pose.
## This is only drawing/visual velocity: no routes, physics or network data.
const CLASSIC_REFERENCE_AMP_PX := 10.0
const CLASSIC_REFERENCE_WAVELENGTH_PX := 54.0

static func classic_measured_step_pose(heading: Vector2,sailed_screen_px: float,amplitude_px: float=CLASSIC_REFERENCE_AMP_PX,wavelength_px: float=CLASSIC_REFERENCE_WAVELENGTH_PX) -> Dictionary:
	if heading.length_squared()<0.0001:
		return {"frame":CLASSIC_FOUR_VIEW_ATLAS[0],"pixel_x":0.0}
	var direction: Vector2=heading.normalized()
	var larger_axis: float=maxf(absf(direction.x),absf(direction.y))
	var cardinal_strength: float=absf(absf(direction.x)-absf(direction.y))/maxf(larger_axis,0.0001)
	# On a diagonal course, the actual 45-degree sprite can travel
	# directly. The telltale alternation occurs on cardinal routes.
	var strength: float=clampf(cardinal_strength*2.0,0.0,1.0)
	var amplitude: float=clampf(amplitude_px,0.0,25.0)*strength
	if amplitude<0.1:
		return {"frame":heading_four(heading,-1),"pixel_x":0.0}
	var wavelength: float=clampf(wavelength_px,8.0,180.0)
	var phase: float=fposmod(maxf(sailed_screen_px,0.0),wavelength)/wavelength
	var triangle: float=0.0
	var side_slope: float=4.0*amplitude/wavelength
	if phase<0.25:
		triangle=4.0*phase
	elif phase<0.75:
		triangle=2.0-4.0*phase
		side_slope= -side_slope
	else:
		triangle=4.0*phase-4.0
	# The frame is determined by the actual visible *step velocity*,
	# so a westbound ship uses NW/SW as the triangle rises/falls.
	var cross: Vector2=Vector2(-direction.y,direction.x)
	var visible_velocity: Vector2=direction+cross*side_slope
	return {"frame":heading_four(visible_velocity,-1),"pixel_x":float(roundi(triangle*amplitude))}

static func heading_eight(heading: Vector2,previous: int=-1) -> int:
	if heading.length_squared()<0.0001:return previous if previous>=0 and previous<8 else 0
	if previous>=0 and previous<8:
		var center=-PI*0.5+float(previous)*PI*0.25
		if absf(wrapf(heading.angle()-center,-PI,PI))<=PI*0.125+0.06:return previous
	return posmod(roundi((heading.angle()+PI*0.5)/(PI*0.25)),8)

## 0=intact, 1=damaged but afloat, 2=sunk. Damage threshold is a local test value.
static func damage_state(hp: float,max_hp: float) -> int:
	if hp<=0:return 2
	if max_hp>0 and hp/max_hp<=0.35:return 1
	return 0

static func geometry(frame: Dictionary,length: float) -> Dictionary:
	var data: Array=frame.rect
	var source=Rect2(float(data[0]),float(data[1]),float(data[2]),float(data[3]))
	var scale=length/float(frame.get("reference_extent",maxf(source.size.x,source.size.y)))
	var pivot=Vector2(float(frame.pivot[0]),float(frame.pivot[1]))*scale
	return {"source":source,"destination":Rect2(-pivot,source.size*scale),"scale":scale,"pivot":pivot}

## A shed wake belongs to its own sampled speed, not today's vessel speed.
static func wake_sample_strength(sample: Dictionary,now: float,lifetime: float) -> float:
	var age: float=now-float(sample.get("time",now))
	if lifetime<=0.0 or age<0.0 or age>=lifetime:return 0.0
	return clampf(float(sample.get("strength",1.0)),0.0,1.0)*pow(1.0-age/lifetime,1.5)

static func world_rect(frame: Dictionary,point: Vector2,length: float,flipped: bool) -> Rect2:
	var spec=geometry(frame,length)
	var local: Rect2=spec.destination
	if flipped:local.position.x=-local.end.x
	return Rect2(point+local.position,local.size)

## Captions stay clear of live ships passing through a dock or gate.
static func landmark_label_visible(point: Vector2,bodies: Array) -> bool:
	for body: Dictionary in bodies:
		if float(body.get("hp",0))>0 and point.distance_to(body.pos)<180:return false
	return true

## Display totals for closely spaced hits; simulation damage remains unchanged.
static func impact_labels(events: Array,now: float) -> Array[Dictionary]:
	var groups: Array[Dictionary]=[]
	for event: Dictionary in events:
		var age=now-float(event.time)
		if event.type!="impact" or age<0 or age>=1.48 or int(event.value)<=0:continue
		var merged=false
		for i in range(groups.size()-1,-1,-1):
			var group: Dictionary=groups[i]
			if int(group.actor)==int(event.actor) and float(event.time)-float(group.time)<=0.28:
				group.value+=int(event.value)
				merged=true
				break
		if not merged:groups.append({"actor":int(event.actor),"pos":event.pos,"time":float(event.time),"value":int(event.value),"lane":0})
	var lanes: Dictionary={}
	for i in range(groups.size()-1,-1,-1):
		var group: Dictionary=groups[i]
		group.lane=int(lanes.get(group.actor,0))
		lanes[group.actor]=int(group.lane)+1
	var visible: Array[Dictionary]=[]
	for group: Dictionary in groups:
		if now-float(group.time)<1.2:visible.append(group)
	return visible

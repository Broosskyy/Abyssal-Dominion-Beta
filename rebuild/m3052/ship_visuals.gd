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
const CLASSIC_CLOCKWISE_ATLAS := [1,3,5,7] # NE, SE, SW, NW

static func heading_four(heading: Vector2,previous: int=-1) -> int:
	var prior_column: int=CLASSIC_FOUR_VIEW_ATLAS.find(previous)
	return CLASSIC_FOUR_VIEW_ATLAS[heading_column(heading,prior_column)]

## Legacy four-view SeaBattle/Seafight-style PIXEL movement.
## The route is unchanged and the atlas is NEVER rotated.
## The drawn hull alone takes a few pixel-sized lateral steps as the player
## sails. Unlike a sinusoidal sway or a 1.4 s pendulum, the frame is chosen
## with digital error diffusion against the desired course (similar to
## rasterizing a straight line with only four possible diagonal directions).
## 32 world units at the normal 165 wu/s captain speed = ~0.19 seconds.
## Exact diagonals hold one pose; oblique headings naturally hold longer.
const CLASSIC_PIXEL_STEP_WORLD := 32.0
const CLASSIC_HULL_DRIFT_PX := 3.0

static func classic_pixel_pose(heading: Vector2,sailed_world: float,step_world: float=CLASSIC_PIXEL_STEP_WORLD,drift_px: float=CLASSIC_HULL_DRIFT_PX) -> Dictionary:
	if heading.length_squared()<0.0001:
		return {"frame":CLASSIC_FOUR_VIEW_ATLAS[0],"pixel_x":0.0}
	var quarter: float=PI*.5
	var angle: float=fposmod(heading.angle()+PI*.25,TAU)
	var sector: int=clampi(floori(angle/quarter),0,3)
	var share: float=fposmod(angle,quarter)/quarter
	var first: int=CLASSIC_CLOCKWISE_ATLAS[sector]
	var second: int=CLASSIC_CLOCKWISE_ATLAS[(sector+1)%4]
	if share<0.025:return {"frame":first,"pixel_x":0.0}
	if share>0.975:return {"frame":second,"pixel_x":0.0}
	step_world=clampf(step_world,12.0,80.0)
	drift_px=clampf(drift_px,0.0,8.0)
	var progress: float=maxf(sailed_world,0.0)/step_world
	var leg: int=floori(progress)
	var part: float=progress-float(leg)
	# Round an accumulated pixel-line error, instead of flipping to
	# a sprite every X seconds regardless of the destination.
	var before: int=floori(float(leg)*share+0.5)
	var after: int=floori(float(leg+1)*share+0.5)
	var second_facing: bool=after>before
	var correction: float=float(before)+(part if second_facing else 0.0)-(float(leg)+part)*share
	var strength: float=sin(share*PI)
	# Three actual SCREEN pixels at most, snapped to full pixels.
	# This is not a world-coordinate sidestep; the ring, camera and
	# nameplate stay on the unchanged simulated position.
	var offset_px: float=float(roundi(clampf(
		(correction-0.25*strength*strength)*8.0*strength,
		-drift_px,drift_px
	)))
	return {"frame":second if second_facing else first,"pixel_x":offset_px}

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

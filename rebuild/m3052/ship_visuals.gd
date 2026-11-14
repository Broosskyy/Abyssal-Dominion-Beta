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

## Classic 2D has four diagonal atlas views while all ships move directly
## along the actual continuous world route, including horizontal courses.
## Eight-view atlas order is N, NE, E, SE, S, SW, W, NW.
const CLASSIC_FOUR_VIEW_ATLAS := [1,7,5,3] # NE, NW, SW, SE

static func heading_four(heading: Vector2,previous: int=-1) -> int:
	var prior_column: int=CLASSIC_FOUR_VIEW_ATLAS.find(previous)
	return CLASSIC_FOUR_VIEW_ATLAS[heading_column(heading,prior_column)]

## Eight-view geometry remains available for optional native modes.
## Classic only selects images; it never quantizes physical movement.
static func heading_eight(heading: Vector2,previous: int=-1) -> int:
	if heading.length_squared()<0.0001:return previous if previous>=0 and previous<8 else 0
	if previous>=0 and previous<8:
		var center=-PI*0.5+float(previous)*PI*0.25
		if absf(wrapf(heading.angle()-center,-PI,PI))<=PI*0.125+0.06:return previous
	return posmod(roundi((heading.angle()+PI*0.5)/(PI*0.25)),8)

## Only four historic diagonal ship images, but ANY straight world heading.
## The old designs seem to rock between neighbouring facings as they sail.
## Do this with travelled DISTANCE only: no fake position, clock, turning arc,
## visual shove, screen-space path or network packet movement.
const CLASSIC_VIEW_CYCLE_WORLD := 96.0
static func heading_four_motion(heading: Vector2,distance: float,previous: int=-1) -> int:
	if heading.length_squared()<0.0001:
		return previous if previous in CLASSIC_FOUR_VIEW_ATLAS else 1
	# True 48x32 chart angles, not compass 45-degree diagonals.
	var tilt: float=atan2(32.0,48.0)
	var angles: Array[float]=[-PI+tilt,-tilt,tilt,PI-tilt]
	var frames: Array[int]=[7,1,3,5] # NW NE SE SW in angle order.
	var bearing: float=wrapf(heading.angle(),-PI,PI)
	if bearing<angles[0]:bearing+=TAU
	for i in 4:
		var lo: float=angles[i]
		var hi: float=angles[i+1] if i<3 else angles[0]+TAU
		if bearing>=lo and bearing<=hi:
			var weight: float=clampf((bearing-lo)/(hi-lo),0.0,1.0)
			if weight<=0.01:return frames[i]
			if weight>=0.99:return frames[(i+1)%4]
			var phase: float=fposmod(distance,CLASSIC_VIEW_CYCLE_WORLD)/CLASSIC_VIEW_CYCLE_WORLD
			return frames[(i+1)%4] if phase<weight else frames[i]
	return heading_four(heading,previous)

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

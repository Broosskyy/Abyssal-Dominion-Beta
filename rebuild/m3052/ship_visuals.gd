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

## Classic 2D follows physical 48×32 tile-centre raster steps; every
## sprite frame depicts the exact segment currently traversed.
## Eight-view atlas order is N, NE, E, SE, S, SW, W, NW.
const CLASSIC_FOUR_VIEW_ATLAS := [1,7,5,3] # NE, NW, SW, SE

static func heading_four(heading: Vector2,previous: int=-1) -> int:
	var prior_column: int=CLASSIC_FOUR_VIEW_ATLAS.find(previous)
	return CLASSIC_FOUR_VIEW_ATLAS[heading_column(heading,prior_column)]

## Eight-view geometry remains available for native modes. Classic chooses
## the original four diagonal images to match four grid-step bearings.
static func heading_eight(heading: Vector2,previous: int=-1) -> int:
	if heading.length_squared()<0.0001:return previous if previous>=0 and previous<8 else 0
	if previous>=0 and previous<8:
		var center=-PI*0.5+float(previous)*PI*0.25
		if absf(wrapf(heading.angle()-center,-PI,PI))<=PI*0.125+0.06:return previous
	return posmod(roundi((heading.angle()+PI*0.5)/(PI*0.25)),8)

## Classic 2D must NEVER draw an independent path around the course.
## Draw its familiar pixel-raster judder as tiny 48px rhythm steps around
## the real 3D/multiplayer line. 9px max side travel, no extra bends,
## reversals or A* waypoints. The same geometry works for all bearings.
static func classic_tethered_raster(start: Vector2,goal: Vector2,world: Vector2,initial_offset: Vector2=Vector2.ZERO) -> Dictionary:
	var delta: Vector2=goal-start
	var length: float=delta.length()
	if length<=0.0001:return {}
	var forward: Vector2=delta/length
	var side: Vector2=Vector2(-forward.y,forward.x)
	# Position comes ONLY from the authoritative world movement.
	var travelled: float=clampf((world-start).dot(forward),0.0,length)
	var distance_left: float=length-travelled
	# One complete 48px cycle, equivalent to alternating 24x16 edges
	# when sailing east/west. Starts at zero, so course changes don't jump.
	var phase: float=fposmod(travelled/48.0+0.25,1.0)
	var triangle: float=1.0-4.0*absf(phase-0.5)
	var edge_fade: float=clampf(minf(travelled,distance_left)/18.0,0.0,1.0)
	var lateral: float=9.0*triangle*edge_fade
	# Keep continuity if a tap redirects the captain mid-sprite step.
	var old_fade: float=clampf(1.0-travelled/24.0,0.0,1.0)
	var offset: Vector2=side*lateral+initial_offset*old_fade
	if offset.length_squared()>100.0:offset=offset.normalized()*10.0
	# The picture follows the local microstep, but physical headings
	# and 3D meshes remain completely independent of this visual sample.
	var slope: float=(2.0/3.0) if phase<0.5 else (-2.0/3.0)
	return {"pos":world+offset,"heading":(forward+side*slope).normalized(),
		"offset":offset,"progress":travelled}

## Draw along the SAME physical diagonal sublegs that the 30 Hz tile-grid simulation
## traversed. Interpolating only the tick endpoints cuts corners and makes
## the ship slide sideways whenever a tick straddles two raster legs.
## No artificial sprite wobble, extra waypoints or independent timer.
static func classic_trace_sample(segments: Array,progress: float) -> Dictionary:
	if segments.is_empty():return {}
	var total: float=0.0
	for segment: Dictionary in segments:
		total+=maxf(0.0,float(segment.get("distance",0.0)))
	if total<=0.0001:return {}
	var remaining: float=clampf(progress,0.0,1.0)*total
	for segment: Dictionary in segments:
		var distance: float=maxf(0.0,float(segment.get("distance",0.0)))
		if distance<=0.0001:continue
		if remaining<=distance:
			var start: Vector2=Vector2(segment.get("start",Vector2.ZERO))
			var finish: Vector2=Vector2(segment.get("end",start))
			return {"pos":start.lerp(finish,clampf(remaining/distance,0.0,1.0)),
				"heading":Vector2(segment.get("heading",finish-start))}
		remaining-=distance
	var last: Dictionary=segments.back()
	return {"pos":Vector2(last.get("end",Vector2.ZERO)),
		"heading":Vector2(last.get("heading",Vector2.RIGHT))}

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

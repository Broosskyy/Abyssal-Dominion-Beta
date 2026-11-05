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
		if event.type!="impact" or age<0 or age>=1.48:continue
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

## Place compact captions after hull drawing. The captain and selected target reserve
## space first. Other captions yield when the water is too crowded or covered by HUD.
## All rectangles are screen pixels, independent of camera zoom and HUD preferences.
static func layout_nameplates(entries: Array,viewport: Rect2,obstacles: Array) -> Dictionary:
	var ordered=entries.duplicate()
	ordered.sort_custom(func(a,b):return int(a.priority)<int(b.priority) if a.priority!=b.priority else int(a.id)<int(b.id))
	var occupied: Array=obstacles.duplicate()
	var placed: Dictionary={}
	for entry: Dictionary in ordered:
		var original: Rect2=entry.rect
		var gap=maxf(5.0,original.size.y*.2)
		var stride=original.size.y+gap
		var offsets=[Vector2.ZERO,Vector2(0,stride),Vector2(0,stride*2),Vector2(-original.size.x*.6,stride),Vector2(original.size.x*.6,stride),Vector2(0,-stride),Vector2(-original.size.x-gap,0),Vector2(original.size.x+gap,0),Vector2(0,stride*3),Vector2(0,-stride*2)]
		if int(entry.priority)<2:
			# Close hulls can fill the water beneath the captain on a short phone.
			# Important plates may move above the sails; ordinary NPCs yield instead.
			for row in range(2,8):
				for side in [0.0,-.6,.6,-1.0,1.0]:
					offsets.append(Vector2(side*(original.size.x+gap),-stride*row))
					if row<5:offsets.append(Vector2(side*(original.size.x+gap),stride*row))
		for offset: Vector2 in offsets:
			var candidate=Rect2(original.position+offset,original.size)
			if not viewport.encloses(candidate):continue
			var clear=true
			for blocked: Rect2 in occupied:
				if candidate.grow(gap*.3).intersects(blocked):clear=false;break
			if not clear:continue
			placed[int(entry.id)]=candidate
			occupied.append(candidate)
			break
		if int(entry.priority)<2 and not placed.has(int(entry.id)):
			# Last resort for a tightly zoomed phone: search remaining free water,
			# nearest first. This runs only when all nearby caption positions fail.
			var fallback: Array[Rect2]=[]
			for y in range(int(viewport.position.y),int(viewport.end.y-original.size.y),maxi(12,int(stride*.5))):
				for x in range(int(viewport.position.x),int(viewport.end.x-original.size.x),maxi(20,int(original.size.x*.25))):
					fallback.append(Rect2(Vector2(x,y),original.size))
			fallback.sort_custom(func(a,b):return a.position.distance_squared_to(original.position)<b.position.distance_squared_to(original.position))
			for candidate: Rect2 in fallback:
				var clear=true
				for blocked: Rect2 in occupied:
					if candidate.grow(gap*.3).intersects(blocked):clear=false;break
				if clear:
					placed[int(entry.id)]=candidate;occupied.append(candidate);break
	return placed

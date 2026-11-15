extends RefCounted
## Classic Seafight-era 48×32 isometric tile geometry. This is a
## SCREEN-SPACE DIAMOND lattice: neighbouring tile centres differ by
## (+24,+16), (-24,+16), (+24,-16), or (-24,-16). It is NOT a
## "travel 32 units diagonally then recalculate" approximation.
const ISO_TILE_WIDTH := 48.0
const ISO_TILE_HEIGHT := 32.0
const ISO_HALF_X := ISO_TILE_WIDTH*0.5
const ISO_HALF_Y := ISO_TILE_HEIGHT*0.5

## Exact globally anchored staggered grid: centres are (r,c) with
## x=(r % 2 ? 0 : 24)+48*c and y=16*(r+1), as in Sea Bandits.
## An equivalent axial (q,r) basis gives the four 24×16 neighbours.
## Unlike an actor-local lattice, clicking a new destination cannot shift
## the raster itself or desync player and NPC tile geometry.
static func classic_tile_center(cell: Vector2i) -> Vector2:
	return Vector2(ISO_HALF_X*(1.0+float(cell.x-cell.y)),ISO_HALF_Y*(1.0+float(cell.x+cell.y)))

static func classic_world_to_tile(world: Vector2) -> Vector2i:
	# Use the actual DIAMOND that contains the click, not Euclidean
	# distance to tile centres. Euclidean-nearest picks the WRONG square
	# close to the corners of this 48x32 staggered chart (e.g. 15,4).
	var x: float=(world.x-ISO_HALF_X)/ISO_HALF_X
	var y: float=(world.y-ISO_HALF_Y)/ISO_HALF_Y
	var q: float=0.5*(x+y)
	var r: float=0.5*(y-x)
	var guess_q: int=floori(q)
	var guess_r: int=floori(r)
	var selected: Vector2i=Vector2i(guess_q,guess_r)
	var best: float=INF
	for q_step in 3:
		for r_step in 3:
			var candidate: Vector2i=Vector2i(guess_q+q_step,guess_r+r_step)
			var center: Vector2=classic_tile_center(candidate)
			var diamond: float=absf(world.x-center.x)/ISO_HALF_X+absf(world.y-center.y)/ISO_HALF_Y
			if diamond<best:
				best=diamond
				selected=candidate
	return selected

## Physical 48x32 tile-walk, used by BOTH real 2D and real 3D sailing.
## Every full leg follows one of the four 24x16 diamond edges. This is
## the Seafight-era raster path, NOT a client-side animation offset.
## High-level pathfinder handles blocked shorelines; this stage chooses
## exactly one of four actual tile neighbours until the last small
## correction to the clicked coordinate. No view animation or oscillation
## of the underlying model can introduce an extra step.
static func classic_iso_route(start: Vector2,goal: Vector2) -> Array[Vector2]:
	var path: Array[Vector2]=[]
	var delta: Vector2=goal-start
	if delta.length_squared()<0.0001:return path
	var direct: Vector2=delta.normalized()
	if delta.length()<ISO_HALF_X:
		path.append(goal)
		return path
	var origin_tile: Vector2i=classic_world_to_tile(start)
	var goal_tile: Vector2i=classic_world_to_tile(goal)
	# Real player clicks select a tile center. NEVER push their goal
	# backward by one tile; the old "stay behind" heuristic created an
	# unnecessary extra heading change at the very end of a tap course.
	if classic_tile_center(goal_tile).distance_squared_to(goal)>0.0001:
		var dx: float=(goal.x-ISO_HALF_X)/ISO_HALF_X
		var dy: float=(goal.y-ISO_HALF_Y)/ISO_HALF_Y
		var q_floor: int=floori(0.5*(dx+dy))
		var r_floor: int=floori(0.5*(dy-dx))
		# Pick a goal tile behind the clicked point along the intended ray:
		# a nearest-centre round-up can overshoot and force a final U-turn.
		var best_score: float=INF
		for i in 4:
			for j in 4:
				var candidate: Vector2i=Vector2i(q_floor-1+i,r_floor-1+j)
				var center: Vector2=classic_tile_center(candidate)
				var residual: Vector2=goal-center
				if residual.dot(direct)<-0.001:continue
				var error: float=absf((center-start).cross(direct))
				var score: float=residual.length_squared()+2.0*error*error
				if score<best_score:
					best_score=score
					goal_tile=candidate
	var tile: Vector2i=origin_tile
	# A restored or spawned captain may start a few pixels away from an
	# authentic tile centre. Smoothly finish that short alignment once,
	# then ALL following legs are exactly 24x16. The retap logic holds
	# the current committed leg to its centre before planning a new path.
	var origin_center: Vector2=classic_tile_center(origin_tile)
	if start.distance_squared_to(origin_center)>0.0001:
		path.append(origin_center)
	var max_steps: int=absi(goal_tile.x-tile.x)+absi(goal_tile.y-tile.y)
	for step in mini(max_steps,2048):
		var move_q: bool=tile.x!=goal_tile.x
		var move_r: bool=tile.y!=goal_tile.y
		if not move_q and not move_r:break
		var next_q: Vector2i=tile+Vector2i(1 if goal_tile.x>tile.x else -1,0)
		var next_r: Vector2i=tile+Vector2i(0,1 if goal_tile.y>tile.y else -1)
		var choose_q: bool=move_q
		if move_q and move_r:
			var q_point: Vector2=classic_tile_center(next_q)
			var r_point: Vector2=classic_tile_center(next_r)
			var q_error: float=absf((q_point-start).cross(direct))
			var r_error: float=absf((r_point-start).cross(direct))
			if r_error+0.00001<q_error:choose_q=false
			elif absf(q_error-r_error)<0.00001:
				choose_q=q_point.distance_squared_to(goal)<=r_point.distance_squared_to(goal)
		elif move_r:choose_q=false
		tile=next_q if choose_q else next_r
		path.append(classic_tile_center(tile))
	if path.is_empty() or path[-1].distance_squared_to(goal)>0.0001:
		path.append(goal)
	return path

## Open sea also uses the real 48x32 lattice. The old implementation
## returned [goal], forcing a dead-straight physical path and hiding all
## zigzag tile motion inside a fake sprite animation.
static func classic_water_route(start: Vector2,goal: Vector2) -> Array[Vector2]:
	return classic_iso_route(start,goal)


## One physical diamond-grid course for all graphics and all coasts.
## First attempt the cross-track-balanced four-neighbour greedy tile
## route. If any real tile edge clips land, calculate an obstacle-safe
## four-neighbour A* detour with no straight-line smoothing.
static func classic_safe_route(start: Vector2,goal: Vector2,segment_clear: Callable,max_visited: int=16000) -> Array[Vector2]:
	var direct: Array[Vector2]=classic_water_route(start,goal)
	var previous: Vector2=start
	var viable: bool=true
	for waypoint: Vector2 in direct:
		if not bool(segment_clear.call(previous,waypoint)):
			viable=false
			break
		previous=waypoint
	if viable:return direct

	var begin: Vector2i=classic_world_to_tile(start)
	var target: Vector2i=classic_world_to_tile(goal)
	var begin_center: Vector2=classic_tile_center(begin)
	var target_center: Vector2=classic_tile_center(target)
	if start.distance_squared_to(begin_center)>0.0001 and not bool(segment_clear.call(start,begin_center)):
		return []
	if target_center.distance_squared_to(goal)>0.0001 and not bool(segment_clear.call(target_center,goal)):
		return []

	var base_step: float=Vector2(ISO_HALF_X,ISO_HALF_Y).length()
	var scores: Dictionary={}
	scores[begin]=0.0
	var parents: Dictionary={}
	var frontier: Array=[]
	_tile_heap_push(frontier,{"tile":begin,"g":0.0,
		"priority":float(absi(target.x-begin.x)+absi(target.y-begin.y))*base_step})
	var touched: int=0
	var directions: Array[Vector2i]=[Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]
	while not frontier.is_empty() and touched<max_visited:
		var entry: Dictionary=_tile_heap_pop(frontier)
		var cell: Vector2i=entry["tile"]
		var known_cost: float=float(scores.get(cell,INF))
		if float(entry["g"])>known_cost+0.001:continue
		if cell==target:
			var reverse: Array[Vector2]=[]
			var cursor: Vector2i=target
			while cursor!=begin:
				reverse.append(classic_tile_center(cursor))
				if not parents.has(cursor):return []
				cursor=parents[cursor]
			reverse.reverse()
			var result: Array[Vector2]=[]
			if start.distance_squared_to(begin_center)>0.0001:result.append(begin_center)
			result.append_array(reverse)
			if result.is_empty() or result[-1].distance_squared_to(goal)>0.0001:result.append(goal)
			# The coastline route stays on the same four diamond neighbours.
			# Do not smooth the A* result into direct visual/physics shortcuts.
			return result
		touched+=1
		var center: Vector2=classic_tile_center(cell)
		for delta: Vector2i in directions:
			var candidate: Vector2i=cell+delta
			var position: Vector2=classic_tile_center(candidate)
			if not bool(segment_clear.call(center,position)):continue
			var cost: float=known_cost+base_step
			if cost>=float(scores.get(candidate,INF))-0.001:continue
			scores[candidate]=cost
			parents[candidate]=cell
			# Admissible A* with a tiny cross-track tiebreaker. This
			# favours tidy Seafight-like courses when many shortest tile
			# paths exist, without choosing an off-grid shortcut.
			var estimate: float=float(absi(target.x-candidate.x)+absi(target.y-candidate.y))*base_step
			var lateral: float=absf((position-start).cross((goal-start).normalized()))
			_tile_heap_push(frontier,{"tile":candidate,"g":cost,
				"priority":cost+estimate+lateral*0.0001})
	return []


## Legacy utility (not called by physical Seafight raster navigation):
## historic shortcut smoothing would erase the four real grid directions.
static func _smooth_coastal_route(start: Vector2,rough: Array[Vector2],segment_clear: Callable) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	var anchor: Vector2=start
	var cursor: int=0
	while cursor<rough.size():
		var furthest: int=-1
		for probe in range(rough.size()-1,cursor-1,-1):
			if bool(segment_clear.call(anchor,rough[probe])):
				furthest=probe
				break
		if furthest<0:return []
		if anchor.distance_squared_to(rough[furthest])>0.0001:
			result.append(rough[furthest])
		anchor=rough[furthest]
		cursor=furthest+1
	return result


static func _tile_heap_push(heap: Array,item: Dictionary) -> void:
	heap.append(item)
	var index: int=heap.size()-1
	while index>0:
		var parent: int=(index-1)/2
		if float(heap[parent]["priority"])<=float(item["priority"]):break
		heap[index]=heap[parent]
		index=parent
	heap[index]=item


static func _tile_heap_pop(heap: Array) -> Dictionary:
	var first: Dictionary=heap[0]
	var last: Dictionary=heap.pop_back()
	if heap.is_empty():return first
	var index: int=0
	while true:
		var child: int=index*2+1
		if child>=heap.size():break
		if child+1<heap.size() and float(heap[child+1]["priority"])<float(heap[child]["priority"]):
			child+=1
		if float(last["priority"])<=float(heap[child]["priority"]):break
		heap[index]=heap[child]
		index=child
	heap[index]=last
	return first


## Classic 2D steering only: alternating 45-degree sea-chart legs with immediate heading snaps.
## Native 2.5D/3D keep direct navigation; network shares the sender's actual waypoint path.
static func diagonal_leg(start: Vector2,goal: Vector2,max_leg: float=96,first_side: int=1) -> Array[Vector2]:
	max_leg=maxf(1.0,max_leg)
	var result: Array[Vector2]=[]
	var delta=goal-start
	if delta.length()<0.01:return result
	var horizontal=absf(delta.x)>=absf(delta.y)
	var main=delta.x if horizontal else delta.y
	var cross=delta.y if horizontal else delta.x
	var forward=signf(main)
	var budgets=[(absf(main)+cross)*0.5,(absf(main)-cross)*0.5]
	var side=0 if first_side>=0 else 1
	var point=start
	for _i in ceili(absf(main)/max_leg)+2:
		if float(budgets[0])+float(budgets[1])<0.01:break
		if float(budgets[side])<0.01:side=1-side
		var amount=minf(max_leg,float(budgets[side]))
		var lateral=amount if side==0 else -amount
		point+=Vector2(forward*amount,lateral) if horizontal else Vector2(lateral,forward*amount)
		result.append(point)
		budgets[side]-=amount
		side=1-side
	if not result.is_empty():result[-1]=goal
	return result

## Four original compass headings (NE/SE/SW/NW), not an arbitrary
## 144-unit sawtooth. An error-bound digital compass steers each diagonal
## only as long as its offset from the ideal tap-to-sail line stays small.
##
## Dithering in the goal's dominant axis:
##  - east/west: move NE or SE, never a horizontal sprite
##  - north/south: move NW or NE, never a vertical sprite
##  - a near-diagonal goal: hold the appropriate heading almost all the way
##  - arbitrary goal: alternate only when the ideal straight course requires it
##
## max_offset is in WORLD units, not frames; it bounds the lateral error.
## It does not introduce a turning radius or alter the real ship speed.
static func classic_compass_leg(start: Vector2,goal: Vector2,max_offset: float=12.0,first_side: int=1) -> Array[Vector2]:
	var path: Array[Vector2]=[]
	var delta: Vector2=goal-start
	if delta.length_squared()<0.0001:return path
	max_offset=maxf(1.0,max_offset)
	var horizontal: bool=absf(delta.x)>=absf(delta.y)
	var main: float=absf(delta.x) if horizontal else absf(delta.y)
	var cross: float=delta.y if horizontal else delta.x
	var forward: float=signf(delta.x) if horizontal else signf(delta.y)
	var slope: float=cross/main
	# Exact budgets ensure arrival on the clicked coordinate, even when
	# one of the 4 compass headings has a very small residual budget.
	var positive: float=maxf(0.0,(main+cross)*0.5)
	var negative: float=maxf(0.0,(main-cross)*0.5)
	var travelled: float=0.0
	var lateral: float=0.0
	var side: int=1 if first_side>=0 else -1
	for _step in 2048:
		if positive+negative<0.0001:break
		var error: float=lateral-slope*travelled
		if positive<0.0001:side=-1
		elif negative<0.0001:side=1
		elif side==1 and error>=max_offset-0.00001:side=-1
		elif side==-1 and error<=-max_offset+0.00001:side=1
		var error_slope: float=float(side)-slope
		var to_limit: float=INF
		if absf(error_slope)>0.000001:
			to_limit=maxf(0.0,(float(side)*max_offset-error)/error_slope)
		var step: float=minf(positive if side==1 else negative,to_limit)
		if step<0.00001:
			side=-side
			continue
		travelled+=step
		lateral+=float(side)*step
		if side==1:positive-=step
		else:negative-=step
		var next_point: Vector2=start+(Vector2(forward*travelled,lateral) if horizontal else Vector2(lateral,forward*travelled))
		path.append(next_point)
	# Return no route rather than truncating one near the map edge or
	# the networking waypoint cap. Callers retain their collision-safe path.
	if positive+negative>0.002 or path.is_empty():return []
	path[path.size()-1]=goal
	return path

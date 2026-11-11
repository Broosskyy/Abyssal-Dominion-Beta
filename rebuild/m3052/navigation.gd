extends RefCounted
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

extends RefCounted
## Classic steering: short diagonal courses with immediate direction changes.
## Shared by sprites and GLB presentation so crossplay follows identical paths.
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

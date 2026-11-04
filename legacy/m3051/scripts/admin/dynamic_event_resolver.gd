class_name DynamicEventResolver
extends RefCounted

static func active_events(tree:SceneTree,unix_time:float=-1.0)->Array:
	var now:=TrustedTimeService.now(tree) if unix_time<0.0 else unix_time
	var trusted:=TrustedTimeService.is_trusted(tree)
	var services:=ServiceLocator.from(tree)
	var local_only:=services==null or services.time==null or services.time.local_only()
	var out:Array=[]
	for row in DynamicContentResolver.active_records(tree,"event"):
		var schedule:Dictionary=row.get("schedule",{})
		var requires_trusted:=bool(schedule.get("require_trusted_time",true))
		if requires_trusted and not trusted and not local_only:continue
		var start:=float(schedule.get("start_unix",0.0))
		var end:=float(schedule.get("end_unix",0.0))
		if (start<=0.0 or now>=start) and (end<=0.0 or now<=end):out.append(row)
	return out

static func multiplier(tree:SceneTree,key:String,unix_time:float=-1.0)->float:
	var value:=1.0
	for event in active_events(tree,unix_time):
		value*=float((event.get("multipliers",{}) as Dictionary).get(key,1.0))
	return value

static func status(tree:SceneTree)->Dictionary:
	var service:=TrustedTimeService.current(tree)
	return {
		"now_unix":TrustedTimeService.now(tree),
		"trusted":TrustedTimeService.is_trusted(tree),
		"authority":service.authority() if service!=null else "missing",
		"active_event_count":active_events(tree).size()
	}

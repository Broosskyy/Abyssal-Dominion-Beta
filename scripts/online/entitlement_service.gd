class_name EntitlementService
extends GameServiceFacade
## Current prototype has no real premium entitlement source.
func has(_key:String)->bool:return false
func source()->String:return "none_local_prototype"

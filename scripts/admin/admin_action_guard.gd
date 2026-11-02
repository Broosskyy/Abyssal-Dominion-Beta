class_name AdminActionGuard
extends RefCounted
static func authorization(tree:SceneTree)->AdminAuthorization:return tree.get_first_node_in_group("admin_authorization") as AdminAuthorization
static func check(tree:SceneTree,permission:String)->Dictionary:
	var auth:=authorization(tree)
	if auth==null:return {"allowed":false,"reason":"authorization_missing"}
	if not auth.can(permission):return {"allowed":false,"reason":"permission_denied","permission":permission}
	return {"allowed":true,"permission":permission,"staff_id":auth.staff_id}
static func request_envelope(tree:SceneTree,permission:String,action:String,target_type:String,target_id:String)->Dictionary:
	var result:=check(tree,permission)
	return {"request_id":"ADMIN-"+str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_msec()),"allowed_locally":bool(result.get("allowed",false)),"permission":permission,"action":action,"target_type":target_type,"target_id":target_id,"surface":"ingame_admin","server_execution_required":true,"staff_id":str(result.get("staff_id",""))}

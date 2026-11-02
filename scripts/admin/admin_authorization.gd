class_name AdminAuthorization
extends Node
signal identity_changed
const PATH:="res://data/admin_rbac_contract.json"
var staff_id:=""
var roles:PackedStringArray=[]
var permissions:PackedStringArray=[]
var verified:=false
var permission_version:=""
func _ready()->void:add_to_group("admin_authorization")
func apply_verified_identity(payload:Dictionary,server_verified:bool)->bool:
	if not server_verified:return false
	staff_id=str(payload.get("staff_id",""))
	if staff_id.is_empty():return false
	roles=PackedStringArray(payload.get("roles",[]))
	permissions=PackedStringArray(payload.get("permissions",[]))
	permission_version=str(payload.get("permission_version",""))
	verified=true
	get_tree().root.set_meta("staff_identity_verified",true)
	identity_changed.emit();return true
func clear()->void:
	staff_id="";roles=PackedStringArray();permissions=PackedStringArray();verified=false;permission_version=""
	get_tree().root.set_meta("staff_identity_verified",false);identity_changed.emit()
func can(permission:String)->bool:return verified and permission in permissions
func require(permission:String)->Dictionary:
	return {"allowed":can(permission),"permission":permission,"staff_id":staff_id if verified else "","verified":verified}
func surface_allowed()->bool:return can("admin.access")

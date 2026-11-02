class_name AdminContentRegistry
extends Node
signal drafts_changed
const TYPES_PATH:="res://data/admin_content_type_registry.json"
const DEFAULT_DRAFTS_PATH:="res://data/m126_admin_content_drafts.json"
const WORKFLOW:Array[String]=["draft","validated","review","approved","scheduled","active","archived","rolled_back"]
var types:Dictionary={}
var drafts:Dictionary={}
func _ready()->void:
	add_to_group("admin_content_registry")
	types=_read(TYPES_PATH).get("content_types",{})
	drafts=ContentDraftStore.load_or_seed(_read(DEFAULT_DRAFTS_PATH))
func _read(path:String)->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(path));return v if v is Dictionary else {}
func type_schema(type_id:String)->Dictionary:return (types.get(type_id,{}) as Dictionary).duplicate(true)
func supported_types()->PackedStringArray:return PackedStringArray(types.keys())
func records(type_id:String="")->Array:
	var out:Array=[]
	for row in drafts.get("records",[]):
		if row is Dictionary and (type_id.is_empty() or str(row.get("type",""))==type_id):out.append(row)
	return out
func validate_record(row:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var type_id:=str(row.get("type",""));var schema:=type_schema(type_id)
	if schema.is_empty():errors.append("unsupported_type");return errors
	for key in schema.get("required",[]):
		if not row.has(key) or (row[key] is String and str(row[key]).is_empty()):errors.append("required:"+str(key))
	var id:=str(row.get("id",""))
	if not id.begins_with(str(schema.get("id_prefix",""))):errors.append("invalid_id_prefix")
	for field in ["behavior_components","objective_components","reward_components","wave_components","phase_components"]:
		if row.get(field,[]) is Array:
			for error in ContentBehaviorEngine.validate_components(row.get(field,[])):errors.append(error)
	if type_id=="payment_product":
		for error in MonetizationAdminContract.validate_public_product(row):errors.append(error)
	if type_id=="shop_offer":
		var commerce:=get_tree().get_first_node_in_group("commerce_catalog") as M161CommerceCatalog
		if commerce!=null:
			for error in commerce.validate_offer(row):errors.append(error)
	return errors
func create_draft(type_id:String,id:String,name:String)->Dictionary:
	var schema:=type_schema(type_id)
	if schema.is_empty():return {}
	for existing in drafts.get("records",[]):
		if str(existing.get("id",""))==id:return {}
	var row:Dictionary={"type":type_id,"id":id,"name":name,"enabled":false,"revision":1,"status":"draft","environment":"LOCAL"}
	(drafts.get("records",[]) as Array).append(row);_commit();return row
func patch_draft(id:String,changes:Dictionary)->bool:
	for row in drafts.get("records",[]):
		if str(row.get("id",""))!=id:continue
		for key in changes.keys():
			if key not in ["type","id"]:row[key]=changes[key]
		row["revision"]=int(row.get("revision",0))+1;_commit();return true
	return false
func delete_draft(id:String)->bool:
	var rows:Array=drafts.get("records",[])
	for i in range(rows.size()):
		if str(rows[i].get("id",""))==id:rows.remove_at(i);_commit();return true
	return false

func clone_draft(id:String,new_id:String)->Dictionary:
	for row in drafts.get("records",[]):
		if row is Dictionary and str(row.get("id",""))==id:
			var clone:Dictionary=(row as Dictionary).duplicate(true)
			clone["id"]=new_id;clone["revision"]=1;clone["status"]="draft";clone["environment"]="LOCAL";clone["enabled"]=false
			(drafts.get("records",[]) as Array).append(clone);_commit();return clone
	return {}

func set_local_status(id:String,status:String)->bool:
	if status not in WORKFLOW:return false
	for row in drafts.get("records",[]):
		if row is Dictionary and str(row.get("id",""))==id:
			if status not in ["draft","validated","review","archived"]:return false
			var current:=str((row as Dictionary).get("status","draft"))
			var transitions:Dictionary={"draft":["validated","archived"],"validated":["draft","review","archived"],"review":["draft","archived"],"archived":["draft"]}
			if status==current:return true
			if status not in transitions.get(current,[]):return false
			(row as Dictionary)["status"]=status
			(row as Dictionary)["revision"]=int((row as Dictionary).get("revision",0))+1
			_commit();return true
	return false

func local_summary()->Dictionary:
	var by_type:Dictionary={};var by_status:Dictionary={}
	for row in drafts.get("records",[]):
		if not row is Dictionary:continue
		var type_id:=str((row as Dictionary).get("type","unknown"));var status:=str((row as Dictionary).get("status","draft"))
		by_type[type_id]=int(by_type.get(type_id,0))+1;by_status[status]=int(by_status.get(status,0))+1
	return {"records":records().size(),"types":types.size(),"by_type":by_type,"by_status":by_status,"authority":"LOCAL_PREVIEW_ONLY"}
func export_draft_snapshot()->Dictionary:
	return {"schema_version":1,"format":"abyssal-content-draft-v1","environment":"LOCAL","records":drafts.get("records",[]).duplicate(true),"authority":"LOCAL_ADMIN_PREVIEW_ONLY"}

func _commit()->void:
	drafts["format"]=ContentDraftStore.FORMAT
	drafts["authority"]="LOCAL_PREVIEW_ONLY"
	ContentDraftStore.save(drafts)
	drafts_changed.emit()

func permission_for(action:String)->String:
	var mapping:Dictionary={"create":"content.create","edit":"content.edit","validate":"content.validate","schedule":"content.schedule","publish":"content.publish","disable":"content.disable","rollback":"content.rollback"}
	return str(mapping.get(action,"content.read"))
func production_request(action:String,target_id:String)->Dictionary:
	return AdminActionGuard.request_envelope(get_tree(),permission_for(action),action,"content",target_id)

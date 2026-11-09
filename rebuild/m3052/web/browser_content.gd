extends Node
## Optional art delivery only. Never changes simulations, saves or wire protocol.
signal finished(key: String,ok: bool)
var packs: Dictionary={}
var mounted: Dictionary={}
var loading: Dictionary={}
var base_url: String=""
var cache_root: String="user://browser_art"

func _ready() -> void:
	var path="res://web/content_manifest.json"
	if FileAccess.file_exists(path):
		var value=JSON.parse_string(FileAccess.get_file_as_string(path))
		if value is Dictionary and int(value.get("schema",0))==1:packs=value.get("packs",{})
	if OS.has_feature("web"):base_url=str(JavaScriptBridge.eval("new URL('.', document.baseURI).href"))
	DirAccess.make_dir_recursive_absolute(cache_root)

func available(key: String) -> bool:
	return mounted.has(key) or not packs.has(key)

func _valid_spec(spec: Dictionary) -> bool:
	var pattern=RegEx.new()
	pattern.compile("^ships-[a-f0-9]{20}\\.zip$")
	var hash_pattern=RegEx.new()
	hash_pattern.compile("^[a-f0-9]{64}$")
	return pattern.search(str(spec.get("file","")))!=null and hash_pattern.search(str(spec.get("sha256","")))!=null and int(spec.get("bytes",0))>0 and int(spec.get("bytes",0))<=16000000

func _verify_and_mount(spec: Dictionary,path: String) -> bool:
	if not FileAccess.file_exists(path):return false
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()!=int(spec.bytes):return false
	if FileAccess.get_sha256(path)!=str(spec.sha256):return false
	var archive=ZIPReader.new()
	if archive.open(path)!=OK:return false
	for entry in archive.get_files():
		# Packs may add imported art, never scripts, account data or project settings.
		if ".." in entry.split("/") or entry.begins_with("/") or "\\" in entry or not (entry.ends_with(".ctex") or entry.ends_with(".png.import") or entry.ends_with(".webp.import") or entry.ends_with(".png") or entry.ends_with(".webp")):
			archive.close();return false
	archive.close()
	return ProjectSettings.load_resource_pack(ProjectSettings.globalize_path(path),false)

func ensure(key: String) -> bool:
	if available(key):return true
	if loading.has(key):
		while loading.has(key):await finished
		return mounted.has(key)
	var spec: Dictionary=packs[key]
	if not _valid_spec(spec):return false
	var path: String=cache_root+"/"+str(spec.file)
	if _verify_and_mount(spec,path):mounted[key]=true;return true
	if base_url.is_empty():return false
	loading[key]=true
	var request=HTTPRequest.new()
	request.timeout=30
	request.body_size_limit=16000000
	request.download_file=path+".part"
	add_child(request)
	var ok=false
	var error=request.request(base_url+str(spec.file))
	if error==OK:
		var result: Array=await request.request_completed
		if int(result[0])==HTTPRequest.RESULT_SUCCESS and int(result[1])==200:
			if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".part"),ProjectSettings.globalize_path(path))==OK:
				ok=_verify_and_mount(spec,path)
	request.queue_free()
	if not ok and FileAccess.file_exists(path+".part"):DirAccess.remove_absolute(path+".part")
	if ok:mounted[key]=true
	loading.erase(key)
	finished.emit(key,ok)
	return ok

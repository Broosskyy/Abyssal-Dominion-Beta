extends Node
const MODEL=preload("res://updater/update_model.gd")
const PENDING="user://abyssal_update_pending.json"
signal changed
var state="idle"
var message="Updates werden geprüft"
var progress=0.0
var spec: Dictionary={}
var native: Object
var request: HTTPRequest
var poll_elapsed=0.0
var worker: Thread
var verified_path=""
var auto_download=true

func _ready() -> void:
	if native==null and OS.get_name()=="Android" and Engine.has_singleton("AbyssalApkInstaller"):
		native=Engine.get_singleton("AbyssalApkInstaller")
	request=HTTPRequest.new()
	request.timeout=8.0
	request.body_size_limit=131072
	request.use_threads=true
	add_child(request)
	request.request_completed.connect(_manifest_complete)
	set_process(true)

func _set(next: String,text: String) -> void:
	state=next;message=text;changed.emit()

func check() -> void:
	if state in ["checking","downloading","paused","verifying","installing"]:return
	if native==null:
		_set("unsupported","App-Updates werden auf Android installiert.")
		return
	if _resume():return
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://updater/config.json"))
	auto_download=bool(config.get("auto_download",true))
	_set("checking","Neue Version wird gesucht …")
	var error=request.request(str(config.manifest_url),["Cache-Control: no-cache"])
	if error!=OK:_set("offline","Update-Prüfung momentan nicht erreichbar. Du kannst spielen.")

func _manifest_complete(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
		_set("offline","Update-Prüfung momentan nicht erreichbar. Du kannst spielen.")
		return
	var parsed=MODEL.manifest(JSON.parse_string(body.get_string_from_utf8()))
	if parsed.status=="invalid":_set("error","Update-Informationen konnten nicht bestätigt werden.");return
	if parsed.status=="current":_set("current","Dein Spiel ist aktuell.");return
	spec=parsed.spec.duplicate(true)
	_set("available","Neue Version verfügbar · %.1f MB"%(float(spec.bytes)/1000000.0))
	if auto_download:download()

func _resume() -> bool:
	if not FileAccess.file_exists(PENDING):return false
	var cached=JSON.parse_string(FileAccess.get_file_as_string(PENDING))
	if not MODEL.valid_spec(cached) or int(cached.version_code)<=MODEL.VERSION_CODE:
		native.call("discardBackgroundApk")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING))
		return false
	spec=cached
	var current=JSON.parse_string(str(native.call("queryBackgroundApk")))
	if not current is Dictionary or current.get("status") in ["missing","failed","size_mismatch","query_failed"]:return false
	if int(current.get("version",-1))!=int(spec.version_code):return false
	_apply_native_state(current)
	return true

func download() -> void:
	if native==null or not MODEL.valid_spec(spec) or int(spec.version_code)<=MODEL.VERSION_CODE:return
	if state in ["downloading","paused","verifying","installing"]:return
	# Persist metadata before enqueue. The native request itself is persisted by Android.
	var file=FileAccess.open(PENDING,FileAccess.WRITE)
	if file==null:_set("error","Update konnte nicht vorbereitet werden.");return
	file.store_string(JSON.stringify(spec));file.close()
	var result=str(native.call("enqueueBackgroundApk",str(spec.url),int(spec.version_code),str(spec.sha256),int(spec.bytes)))
	if result not in ["queued","active"]:_set("error","Download konnte nicht gestartet werden. Bitte erneut versuchen.");return
	_set("downloading","Update wird im Hintergrund heruntergeladen …")
	poll_elapsed=1.0

func _process(delta: float) -> void:
	if state=="verifying" and worker!=null and not worker.is_alive():
		var valid=worker.wait_to_finish()
		worker=null
		if not valid:
			native.call("discardBackgroundApk")
			_set("error","Update-Datei ist unvollständig oder beschädigt. Bitte erneut laden.")
		else:
			progress=1.0
			_set("ready","Update geprüft. Android-Installation wird geöffnet …")
			install()
	if state not in ["downloading","paused"] or native==null:return
	poll_elapsed+=delta
	if poll_elapsed<0.5:return
	poll_elapsed=0
	var data=JSON.parse_string(str(native.call("queryBackgroundApk")))
	if not data is Dictionary:_set("error","Downloadstatus konnte nicht gelesen werden.");return
	_apply_native_state(data)

func _apply_native_state(data: Dictionary) -> void:
	if int(data.get("version",-1))!=int(spec.get("version_code",-2)):_set("error","Update-Auftrag passt nicht zur Version.");return
	progress=clampf(float(data.get("received",0))/maxf(1,float(spec.bytes)),0,1)
	match str(data.get("status","")):
		"pending","running":_set("downloading","Update lädt · %d %%"%roundi(progress*100))
		"paused":_set("paused","Download pausiert. Android setzt ihn bei Verbindung fort.")
		"complete":
			verified_path=str(data.get("path",""))
			_set("verifying","Heruntergeladenes Update wird geprüft …")
			worker=Thread.new()
			var error=worker.start(MODEL.verify_file.bind(spec.duplicate(true),verified_path))
			if error!=OK:worker=null;_set("error","Update-Prüfung konnte nicht gestartet werden.")
		_:_set("error","Download unterbrochen. Du kannst ihn erneut starten.")

func install() -> void:
	if native==null or state not in ["ready","permission"]:return
	var result=str(native.call("installValidatedApk",verified_path,int(spec.version_code)))
	match result:
		"installer_opened":_set("installing","Bitte die Installation im Android-Fenster bestätigen.")
		"permission_required":_set("permission","Updates für diese App in Android erlauben, dann hier fortsetzen.")
		_:_set("error","Android konnte dieses Update nicht installieren. Du kannst weiterspielen.")

func _exit_tree() -> void:
	# Leaving the launcher never removes the Android DownloadManager request.
	if worker!=null:worker.wait_to_finish();worker=null

func _notification(what: int) -> void:
	if what==MainLoop.NOTIFICATION_APPLICATION_RESUMED and state=="installing":
		_set("ready","Installation noch offen. Du kannst sie fortsetzen oder spielen.")

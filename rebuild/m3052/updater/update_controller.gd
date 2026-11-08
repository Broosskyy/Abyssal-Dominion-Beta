extends Node
const MODEL=preload("res://updater/update_model.gd")
const TRANSFER=preload("res://updater/direct_transfer.gd")
const PENDING="user://abyssal_update_pending.json"
signal changed
var foreground_transfer=false
var fallback_reason=""
var direct: Node
var paused_for=0.0
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
	request.timeout=15.0
	request.body_size_limit=131072
	request.use_threads=true
	add_child(request)
	request.request_completed.connect(_manifest_complete)
	direct=TRANSFER.new();add_child(direct)
	direct.changed.connect(_direct_progress)
	direct.finished.connect(_direct_complete)
	direct.failed.connect(_direct_failed)
	set_process(true)

func set_status(next: String,text: String) -> void:
	state=next;message=text;changed.emit()

func check() -> void:
	if state in ["checking","downloading","paused","verifying","installing"]:return
	if native==null:
		set_status("unsupported","App-Updates werden auf Android installiert.")
		return
	if _resume():return
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://updater/config.json"))
	auto_download=bool(config.get("auto_download",true))
	set_status("checking","Neue Version wird gesucht …")
	var error=request.request(str(config.manifest_url),["Cache-Control: no-cache"])
	if error!=OK:set_status("offline","Update-Prüfung momentan nicht erreichbar. Du kannst spielen.")

func _manifest_complete(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
		set_status("offline","Update-Prüfung momentan nicht erreichbar. Du kannst spielen.")
		return
	var parsed=MODEL.manifest(JSON.parse_string(body.get_string_from_utf8()))
	if parsed.status=="invalid":set_status("error","Update-Informationen konnten nicht bestätigt werden.");return
	if parsed.status=="current":set_status("current","Dein Spiel ist aktuell.");return
	spec=parsed.spec.duplicate(true)
	set_status("available","Neue Version verfügbar · %.1f MB"%(float(spec.bytes)/1000000.0))
	if auto_download:download()

func _resume() -> bool:
	if not FileAccess.file_exists(PENDING):return false
	var cached=JSON.parse_string(FileAccess.get_file_as_string(PENDING))
	if not MODEL.valid_spec(cached) or int(cached.version_code)<=MODEL.VERSION_CODE:
		native.call("discardBackgroundApk")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING))
		return false
	spec=cached
	var local_path: String="user://abyssal_apk_updater/update_direct.apk"
	if FileAccess.file_exists(local_path):
		var candidate=FileAccess.open(local_path,FileAccess.READ)
		if candidate!=null:
			var size_bytes: int=candidate.get_length();candidate.close()
			if size_bytes==int(spec.bytes):foreground_transfer=true;_verify_download(ProjectSettings.globalize_path(local_path));return true
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
	if file==null:set_status("error","Update konnte nicht vorbereitet werden.");return
	file.store_string(JSON.stringify(spec));file.close()
	var result=str(native.call("enqueueBackgroundApk",str(spec.url),int(spec.version_code),str(spec.sha256),int(spec.bytes)))
	if result not in ["queued","active"]:_start_fallback("Android-Start: "+result);return
	foreground_transfer=false;paused_for=0
	set_status("downloading","Update wird im Hintergrund heruntergeladen …")
	poll_elapsed=1.0

func _process(delta: float) -> void:
	if state=="verifying" and worker!=null and not worker.is_alive():
		var valid=worker.wait_to_finish()
		worker=null
		if not valid:
			native.call("discardBackgroundApk");direct.cleanup();foreground_transfer=false
			set_status("error","Update-Datei ist unvollständig oder beschädigt. Bitte erneut laden.")
		else:
			foreground_transfer=false
			progress=1.0
			set_status("ready","Update geprüft. Android-Installation wird geöffnet …")
			install()
	if foreground_transfer:return
	if state=="paused":
		paused_for+=delta
		if paused_for>30:_start_fallback("Android-Download bleibt pausiert");return
	else:paused_for=0
	if state not in ["downloading","paused"] or native==null:return
	poll_elapsed+=delta
	if poll_elapsed<0.5:return
	poll_elapsed=0
	var data=JSON.parse_string(str(native.call("queryBackgroundApk")))
	if not data is Dictionary:set_status("error","Downloadstatus konnte nicht gelesen werden.");return
	_apply_native_state(data)

func _apply_native_state(data: Dictionary) -> void:
	if int(data.get("version",-1))!=int(spec.get("version_code",-2)):set_status("error","Update-Auftrag passt nicht zur Version.");return
	progress=clampf(float(data.get("received",0))/maxf(1,float(spec.bytes)),0,1)
	match str(data.get("status","")):
		"pending","running":set_status("downloading","Update lädt · %d %%"%roundi(progress*100))
		"paused":set_status("paused","Download pausiert. Android setzt ihn bei Verbindung fort.")
		"complete":_verify_download(str(data.get("path","")))
		_:_start_fallback(TRANSFER.native_reason(data))

func install() -> void:
	if native==null or state not in ["ready","permission"]:return
	var result=str(native.call("installValidatedApk",verified_path,int(spec.version_code)))
	match result:
		"installer_opened":set_status("installing","Bitte die Installation im Android-Fenster bestätigen.")
		"permission_required":set_status("permission","Updates für diese App in Android erlauben, dann hier fortsetzen.")
		_:set_status("error","Android konnte dieses Update nicht installieren. Du kannst weiterspielen.")

func _exit_tree() -> void:
	# Leaving the launcher never removes the Android DownloadManager request.
	if worker!=null:worker.wait_to_finish();worker=null

func _notification(what: int) -> void:
	if what==MainLoop.NOTIFICATION_APPLICATION_RESUMED and state=="installing":
		set_status("ready","Installation noch offen. Du kannst sie fortsetzen oder spielen.")

func _start_fallback(reason: String) -> void:
	if foreground_transfer or direct==null:return
	native.call("discardBackgroundApk")
	foreground_transfer=true;fallback_reason=reason
	set_status("downloading",reason+" · Ersatzdownload startet. App bitte offen lassen.")
	if not direct.start(str(spec.url),"user://abyssal_apk_updater/update_direct.apk",int(spec.bytes)):_direct_failed("Direktdownload konnte nicht gestartet werden")

func _direct_progress() -> void:
	if not foreground_transfer or not direct.active:return
	progress=direct.progress
	set_status("downloading","App-Direktdownload · %d %% · Versuch %d/3 · App offen lassen" % [roundi(progress*100),direct.attempt])

func _direct_complete(path: String) -> void:_verify_download(path)

func _direct_failed(reason: String) -> void:
	foreground_transfer=false
	set_status("error",fallback_reason+" · "+reason)

func _verify_download(path: String) -> void:
	verified_path=ProjectSettings.globalize_path(path)
	set_status("verifying","Heruntergeladenes Update wird geprüft …")
	worker=Thread.new()
	if worker.start(MODEL.verify_file.bind(spec.duplicate(true),verified_path))!=OK:worker=null;foreground_transfer=false;set_status("error","Update-Prüfung konnte nicht gestartet werden.")

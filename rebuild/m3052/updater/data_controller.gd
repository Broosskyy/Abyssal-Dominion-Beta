extends Node
const MODEL=preload("res://updater/data_model.gd")
const TRANSFER=preload("res://updater/direct_transfer.gd")
const PENDING="user://content_pending.json"
signal changed
var foreground_transfer=false
var fallback_reason=""
var direct: Node
var paused_for=0.0
var state="idle"
var message="Spieldaten werden geprüft …"
var progress=0.0
var spec: Dictionary={}
var native: Object
var request: HTTPRequest
var worker: Thread
var verified_path=""
var poll=0.0
var boot: Node

func set_status(value: String,text: String) -> void:
	state=value;message=text;changed.emit()

func _ready() -> void:
	boot=get_tree().root.get_node_or_null("DataBoot")
	if OS.get_name()=="Android" and Engine.has_singleton("AbyssalApkInstaller"):native=Engine.get_singleton("AbyssalApkInstaller")
	request=HTTPRequest.new();request.timeout=15;request.body_size_limit=131072;request.use_threads=true;add_child(request)
	request.request_completed.connect(_manifest_complete)
	direct=TRANSFER.new();add_child(direct)
	direct.changed.connect(_direct_progress)
	direct.finished.connect(_direct_complete)
	direct.failed.connect(_direct_failed)

func check() -> void:
	if native==null or boot==null:set_status("unsupported","Spieldaten sind bereit.");return
	if boot.pending_revision>boot.active_revision:set_status("restart","Datenupdate gespeichert. App schließen und neu öffnen zum Anwenden.");return
	if boot.loaded_slots.size()>=2:set_status("restart","Zum nächsten Datenupdate bitte die App neu öffnen.");return
	if FileAccess.file_exists(PENDING):
		var pending=JSON.parse_string(FileAccess.get_file_as_string(PENDING))
		if MODEL.valid_spec(pending) and int(pending.revision)>boot.active_revision:
			spec=pending
			var local_path: String="user://content_direct.zip"
			if FileAccess.file_exists(local_path):
				var candidate=FileAccess.open(local_path,FileAccess.READ)
				if candidate!=null:
					var size_bytes: int=candidate.get_length();candidate.close()
					if size_bytes==int(spec.bytes):foreground_transfer=true;_verify_download(local_path);return
			var current=JSON.parse_string(str(native.call("queryBackgroundPack")))
			if current is Dictionary and int(current.get("version",-1))==int(spec.revision) and current.get("status") in ["pending","running","paused","complete"]:
				apply_status(current);return
		if not MODEL.valid_spec(pending) or int(pending.revision)<=boot.active_revision:
			native.call("discardBackgroundPack");DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING))
	set_status("checking","Spielcode und Grafiken werden auf Updates geprüft …")
	if request.request(MODEL.MANIFEST,["Cache-Control: no-cache"])!=OK:set_status("offline","Datenserver nicht erreichbar. Gespeicherter Stand ist spielbar.")

func _manifest_complete(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200:set_status("offline","Datenserver nicht erreichbar. Gespeicherter Stand ist spielbar.");return
	var data=MODEL.manifest(JSON.parse_string(body.get_string_from_utf8()),boot.active_revision)
	if data.status=="current":set_status("current","Spiel und Daten sind aktuell.");return
	if data.status=="shell_required":set_status("current","Für neue Android-Funktionen bitte das App-Update installieren.");return
	if data.status!="available":set_status("error","Datenupdate konnte nicht authentifiziert werden.");return
	spec=data.spec
	download()

func download() -> void:
	if native==null or not MODEL.valid_spec(spec):return
	if state in ["downloading","paused","verifying"]:return
	var file=FileAccess.open(PENDING,FileAccess.WRITE)
	if file==null:set_status("error","Datenupdate konnte nicht vorbereitet werden.");return
	file.store_string(JSON.stringify(spec));file.close()
	var result=str(native.call("enqueueBackgroundPack",str(spec.url),int(spec.revision),str(spec.sha256),int(spec.bytes)))
	if result not in ["queued","active"]:_start_fallback("Android-Start: "+result);return
	foreground_transfer=false;paused_for=0
	set_status("downloading","Spieldaten laden im Hintergrund …");poll=1

func apply_status(data: Dictionary) -> void:
	if int(data.get("version",-1))!=int(spec.get("revision",-2)):set_status("error","Datenauftrag passt nicht zur Version.");return
	progress=clampf(float(data.get("received",0))/maxf(1,float(spec.bytes)),0,1)
	match str(data.get("status","")):
		"pending","running":set_status("downloading","Spielcode und Grafiken laden · %d %%"%roundi(progress*100))
		"paused":set_status("paused","Daten-Download pausiert bis zur nächsten Verbindung.")
		"complete":_verify_download(str(data.get("path","")))
		_:_start_fallback(TRANSFER.native_reason(data))

func _process(delta: float) -> void:
	if state=="verifying" and worker!=null and not worker.is_alive():
		var valid=worker.wait_to_finish();worker=null
		if not valid:native.call("discardBackgroundPack");direct.cleanup();foreground_transfer=false;set_status("error","Signatur oder Prüfsumme der Spieldaten stimmt nicht.");return
		var result=str(boot.accept(spec,verified_path))
		if result in ["mounted","restart"]:
			native.call("discardBackgroundPack");direct.cleanup();foreground_transfer=false
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING))
			progress=1
			set_status("current" if result=="mounted" else "restart","Spieldaten aktualisiert · keine APK-Installation nötig." if result=="mounted" else "Datenupdate gespeichert. App schließen und neu öffnen zum Anwenden.")
		else:foreground_transfer=false;direct.cleanup();set_status("error","Spieldaten konnten nicht sicher aktiviert werden. Vorheriger Stand bleibt erhalten.")
	if foreground_transfer:return
	if state=="paused":
		paused_for+=delta
		if paused_for>30:_start_fallback("Android-Download bleibt pausiert");return
	else:paused_for=0
	if state not in ["downloading","paused"] or native==null:return
	poll+=delta
	if poll<0.5:return
	poll=0
	var data=JSON.parse_string(str(native.call("queryBackgroundPack")))
	if data is Dictionary:apply_status(data)
	else:set_status("error","Datenstatus konnte nicht gelesen werden.")

func _exit_tree() -> void:
	if worker!=null:worker.wait_to_finish();worker=null

func _start_fallback(reason: String) -> void:
	if foreground_transfer or direct==null:return
	native.call("discardBackgroundPack")
	foreground_transfer=true;fallback_reason=reason
	set_status("downloading",reason+" · Ersatzdownload startet. App bitte offen lassen.")
	if not direct.start(str(spec.url),"user://content_direct.zip",int(spec.bytes)):_direct_failed("Direktdownload konnte nicht gestartet werden")

func _direct_progress() -> void:
	if not foreground_transfer or not direct.active:return
	progress=direct.progress
	set_status("downloading","Direktdownload · %d %% · Versuch %d/3 · App offen lassen" % [roundi(progress*100),direct.attempt])

func _direct_complete(path: String) -> void:_verify_download(path)

func _direct_failed(reason: String) -> void:
	foreground_transfer=false
	set_status("error",fallback_reason+" · "+reason)

func _verify_download(path: String) -> void:
	verified_path=ProjectSettings.globalize_path(path)
	set_status("verifying","Signatur und Inhalt des Datenupdates werden geprüft …")
	worker=Thread.new()
	if worker.start(MODEL.verify_file.bind(spec.duplicate(true),verified_path))!=OK:worker=null;foreground_transfer=false;set_status("error","Datenprüfung konnte nicht gestartet werden.")

extends Node
## Independent foreground recovery when Android's system download cannot finish.
## Callers authenticate the manifest first; activation still verifies size/hash/signature.
signal changed
signal finished(path: String)
signal failed(reason: String)
const ROOT="https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/"
const STALL_SECONDS := 45.0
const MAX_ATTEMPTS := 3
var http: HTTPRequest
var active := false
var progress := 0.0
var received := 0
var expected := 0
var path := ""
var url := ""
var attempt := 0
var stall := 0.0
var retry_wait := 0.0
var allow_local_test := false

func _ready() -> void:
	http=HTTPRequest.new();http.use_threads=true;http.timeout=0.0
	http.body_size_limit=350000000;http.max_redirects=10;http.accept_gzip=false
	add_child(http);http.request_completed.connect(_completed)

func start(download_url: String,destination: String,size_bytes: int) -> bool:
	if active or size_bytes<1000 or size_bytes>350000000:return false
	if not download_url.begins_with(ROOT) and not (allow_local_test and download_url.begins_with("http://127.0.0.1:")):return false
	if destination not in ["user://content_direct.zip","user://abyssal_apk_updater/update_direct.apk","user://direct_test.bin"]:return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))!=OK:return false
	url=download_url;path=destination;expected=size_bytes;attempt=0;progress=0;received=0;active=true
	_begin()
	return true

func _begin() -> void:
	attempt+=1;stall=0;received=0;retry_wait=0;progress=0
	http.download_file=ProjectSettings.globalize_path(path)
	var error: int=http.request(url,["Cache-Control: no-cache","Accept-Encoding: identity","User-Agent: AbyssalDominion-Updater"])
	if error!=OK:_retry("Verbindung konnte nicht geöffnet werden (%d)" % error)
	changed.emit()

func _retry(reason: String) -> void:
	if attempt>=MAX_ATTEMPTS:
		active=false;cleanup();failed.emit(reason+" · Bitte Verbindung und freien Speicher prüfen.")
	else:retry_wait=float(attempt)*1.5;stall=0;changed.emit()

func _completed(result: int,code: int,_headers: PackedStringArray,_body: PackedByteArray) -> void:
	if not active:return
	if result==HTTPRequest.RESULT_SUCCESS and code==200:
		var file=FileAccess.open(path,FileAccess.READ)
		if file!=null:
			var size_bytes: int=file.get_length();file.close()
			if size_bytes==expected:
				active=false;progress=1;received=size_bytes;finished.emit(path);return
	_retry("Direktdownload fehlgeschlagen (HTTP %d, Downloadcode %d)" % [code,result])

func _process(delta: float) -> void:
	if not active:return
	if retry_wait>0:
		retry_wait=maxf(0,retry_wait-delta)
		if retry_wait<=0:_begin()
		return
	var count: int=http.get_downloaded_bytes()
	if count!=received:received=count;stall=0
	else:stall+=delta
	progress=clampf(float(received)/maxf(1,expected),0,1);changed.emit()
	if stall>=STALL_SECONDS:
		http.cancel_request();_retry("45 Sekunden ohne neue Daten")

func cleanup() -> void:
	if not path.is_empty() and FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _exit_tree() -> void:
	if http!=null:http.cancel_request()
	active=false

static func native_reason(data: Dictionary) -> String:
	var code: int=int(data.get("reason",0))
	var message: String={1001:"Dateifehler",1004:"Serverantwort abgelehnt",1005:"Weiterleitungsfehler",1006:"Zu wenig freier Speicher",1008:"Download nicht fortsetzbar",1009:"Alte Download-Datei vorhanden"}.get(code,"Download unterbrochen")
	return message+" (Android %d · %s)" % [code,str(data.get("status","unbekannt"))]

extends Node
## Cross-platform HTTP + WebSocket transport. No secret is persisted in guest saves.
signal auth_completed(ok: bool,message: String)
signal snapshot_received(value: Dictionary)
signal connection_changed(connected: bool)
const PROTOCOL := 1
var server_url := ""
var token := ""
var account: Dictionary={}
var request: HTTPRequest
var socket := WebSocketPeer.new()
var joined := false
var connecting := false
var sequence := 0
var connect_started := 0
func _ready() -> void:
	request=HTTPRequest.new();request.timeout=12;request.body_size_limit=262144;add_child(request)
	request.request_completed.connect(_auth_result)
	if get_tree().has_meta("abyssal_session"):
		var session: Dictionary=get_tree().get_meta("abyssal_session")
		token=str(session.get("token",""));account=session.get("account",{});server_url=str(session.get("server_url",""))
func valid_server(value: String) -> bool:
	return (value.begins_with("https://") and value.length()>8) or value.begins_with("http://127.0.0.1:") or value.begins_with("http://localhost:")
func authenticate(email: String,password: String,username: String="",register: bool=false) -> void:
	if not valid_server(server_url):auth_completed.emit(false,"Noch kein Beta-Server verbunden. Gastspiel ist verfügbar.");return
	if request.get_http_client_status()!=HTTPClient.STATUS_DISCONNECTED:return
	var payload: Dictionary={"email":email.strip_edges(),"password":password,"username":username.strip_edges(),"protocol":PROTOCOL}
	var error: int=request.request(server_url.trim_suffix("/")+("/v1/register" if register else "/v1/login"),["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(payload))
	if error!=OK:auth_completed.emit(false,"Verbindung konnte nicht gestartet werden.")
func _auth_result(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	var value: Variant=JSON.parse_string(body.get_string_from_utf8())
	if result!=HTTPRequest.RESULT_SUCCESS or not value is Dictionary:
		auth_completed.emit(false,"Server nicht erreichbar. Dein Gastspiel bleibt verfügbar.");return
	if code!=200:
		auth_completed.emit(false,str(value.get("error","Anmeldung fehlgeschlagen")));return
	if not value.get("token") is String or not value.get("account") is Dictionary:
		auth_completed.emit(false,"Ungültige Serverantwort");return
	token=value.token;account=value.account
	get_tree().set_meta("abyssal_session",{"token":token,"account":account,"server_url":server_url})
	auth_completed.emit(true,"Angemeldet als "+str(account.get("username","Kapitän")))
func connect_world(map_id: int) -> Error:
	if token.is_empty() or not valid_server(server_url):return ERR_UNCONFIGURED
	var ws_url: String=server_url.replace("https://","wss://").replace("http://","ws://").trim_suffix("/")+"/v1/world"
	var error: Error=socket.connect_to_url(ws_url)
	if error==OK:connecting=true;connect_started=Time.get_ticks_msec();set_meta("map_id",map_id)
	return error
func _process(_delta: float) -> void:
	if not connecting and not joined:return
	socket.poll()
	var state: int=socket.get_ready_state()
	if state==WebSocketPeer.STATE_OPEN:
		if not joined:
			socket.send_text(JSON.stringify({"type":"join","protocol":PROTOCOL,"token":token,"map_id":get_meta("map_id",0)}));joined=true;connection_changed.emit(true)
		while socket.get_available_packet_count()>0:
			var value: Variant=JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if value is Dictionary:snapshot_received.emit(value)
	elif state==WebSocketPeer.STATE_CLOSED or (not joined and Time.get_ticks_msec()-connect_started>12000):
		connecting=false;joined=false;socket.close();connection_changed.emit(false)
func send_course(point: Vector2) -> void:
	if not joined or not point.is_finite():return
	sequence+=1
	socket.send_text(JSON.stringify({"type":"course","sequence":sequence,"x":point.x,"y":point.y}))
## Switch between room snapshots without losing the authenticated session.
func leave_world() -> void:
	if connecting or joined:socket.close()
	connecting=false
	joined=false
	connection_changed.emit(false)

func sign_out() -> void:
	leave_world();token="";account={}
	if get_tree().has_meta("abyssal_session"):get_tree().remove_meta("abyssal_session")

extends Node
## Shared Supabase Auth for browser and APK; existing WebSocket sea server remains
## authoritative for courses. No service-role key or password goes into guest saves.
signal auth_completed(ok: bool, message: String)
signal snapshot_received(value: Dictionary)
signal connection_changed(connected: bool)

const PROTOCOL := 2
const CONFIG_PATH := "res://online_config.json"
var server_url := ""
var supabase_url := ""
var publishable_key := ""
var token := ""
var refresh_token := ""
var expires_at_unix := 0
var account: Dictionary = {}
var request: HTTPRequest
var pending_action := ""
var socket := WebSocketPeer.new()
var joined := false
var hello_sent := false
var connecting := false
var sequence := 0
var connect_started := 0

func _ready() -> void:
    request = HTTPRequest.new()
    request.timeout = 12
    request.body_size_limit = 262144
    add_child(request)
    request.request_completed.connect(_auth_result)
    if FileAccess.file_exists(CONFIG_PATH):
        var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
        if config is Dictionary:
            supabase_url = str(config.get("supabase_url", "")).trim_suffix("/")
            publishable_key = str(config.get("supabase_publishable_key", ""))
    if get_tree().has_meta("abyssal_session"):
        var session: Dictionary = get_tree().get_meta("abyssal_session")
        token = str(session.get("token", ""))
        refresh_token = str(session.get("refresh_token", ""))
        expires_at_unix = int(session.get("expires_at_unix", 0))
        account = session.get("account", {})
        server_url = str(session.get("server_url", ""))

func _supabase_enabled() -> bool:
    return supabase_url.begins_with("https://") and publishable_key.begins_with("sb_publishable_") and not server_url.begins_with("http://127.0.0.1:") and not server_url.begins_with("http://localhost:")

func valid_server(value: String) -> bool:
    return (value.begins_with("https://") and value.length() > 8) or value.begins_with("http://127.0.0.1:") or value.begins_with("http://localhost:")

func authenticate(email: String, password: String, username: String = "", register: bool = false) -> void:
    if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        auth_completed.emit(false, "Anmeldung läuft bereits.")
        return
    email = email.strip_edges()
    username = username.strip_edges()
    if email.length() < 3 or not email.contains("@") or password.length() < 10 or password.length() > 128:
        auth_completed.emit(false, "E-Mail und Passwort prüfen (10–128 Zeichen).")
        return
    if register and (username.length() < 3 or username.length() > 24):
        auth_completed.emit(false, "Spielername benötigt 3–24 Zeichen.")
        return
    if _supabase_enabled():
        pending_action = "supabase_signup" if register else "supabase_login"
        var endpoint := "/auth/v1/signup" if register else "/auth/v1/token?grant_type=password"
        var payload: Dictionary = {"email": email, "password": password}
        if register:
            payload["data"] = {"username": username}
        var headers := ["Content-Type: application/json", "apikey: " + publishable_key]
        var error: Error = request.request(supabase_url + endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
        if error != OK:
            pending_action = ""
            auth_completed.emit(false, "Anmeldung konnte nicht gestartet werden.")
        return
    # Local-only legacy sandbox remains testable without Supabase.
    if not valid_server(server_url):
        auth_completed.emit(false, "Kein Online-Dienst verbunden. Gastspiel bleibt verfügbar.")
        return
    pending_action = "legacy"
    var payload: Dictionary = {"email": email, "password": password, "username": username, "protocol": PROTOCOL}
    var error: Error = request.request(server_url.trim_suffix("/") + ("/v1/register" if register else "/v1/login"), ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
    if error != OK:
        pending_action = ""
        auth_completed.emit(false, "Verbindung konnte nicht gestartet werden.")

func _persist_memory_session() -> void:
    get_tree().set_meta("abyssal_session", {
        "token": token,
        "refresh_token": refresh_token,
        "expires_at_unix": expires_at_unix,
        "account": account,
        "server_url": server_url,
    })

func _auth_result(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var action := pending_action
    pending_action = ""
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and not body.is_empty() else null
    if result != HTTPRequest.RESULT_SUCCESS or not parsed is Dictionary:
        if action != "supabase_refresh":
            auth_completed.emit(false, "Online-Dienst nicht erreichbar. Gastspiel bleibt verfügbar.")
        return
    var data: Dictionary = parsed
    if action.begins_with("supabase_"):
        if code < 200 or code >= 300:
            var message := str(data.get("msg", data.get("error_description", data.get("message", "Anmeldung fehlgeschlagen"))))
            if action != "supabase_refresh":
                auth_completed.emit(false, message)
            return
        if action == "supabase_signup" and not data.has("access_token"):
            auth_completed.emit(false, "Konto angelegt. Bitte E-Mail bestätigen und anschließend anmelden.")
            return
        var user: Variant = data.get("user", {})
        if not user is Dictionary:
            if action != "supabase_refresh":
                auth_completed.emit(false, "Ungültige Kontoantwort.")
            return
        var session_token := str(data.get("access_token", ""))
        if session_token.is_empty():
            if action != "supabase_refresh":
                auth_completed.emit(false, "Kein gültiges Sitzungstoken.")
            return
        token = session_token
        refresh_token = str(data.get("refresh_token", refresh_token))
        expires_at_unix = int(Time.get_unix_time_from_system()) + int(data.get("expires_in", 3600))
        var metadata: Variant = user.get("user_metadata", {})
        var name := str(metadata.get("username", "Kapitän")) if metadata is Dictionary else "Kapitän"
        if name.strip_edges().length() < 3:
            name = "Kapitän"
        account = {"id": str(user.get("id", "")), "username": name}
        _persist_memory_session()
        if action != "supabase_refresh":
            auth_completed.emit(true, "Angemeldet als " + name)
        return
    if code != 200 or not data.get("token") is String or not data.get("account") is Dictionary:
        auth_completed.emit(false, str(data.get("error", "Anmeldung fehlgeschlagen.")))
        return
    token = str(data.token)
    refresh_token = ""
    expires_at_unix = 0
    account = data.account
    _persist_memory_session()
    auth_completed.emit(true, "Angemeldet als " + str(account.get("username", "Kapitän")))

func _refresh_supabase_session() -> void:
    if not _supabase_enabled() or refresh_token.is_empty() or pending_action != "":
        return
    if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    pending_action = "supabase_refresh"
    var error: Error = request.request(
        supabase_url + "/auth/v1/token?grant_type=refresh_token",
        ["Content-Type: application/json", "apikey: " + publishable_key],
        HTTPClient.METHOD_POST,
        JSON.stringify({"refresh_token": refresh_token})
    )
    if error != OK:
        pending_action = ""

func connect_world(map_id: int) -> Error:
    if token.is_empty() or not valid_server(server_url):
        return ERR_UNCONFIGURED
    var ws_url: String = server_url.replace("https://", "wss://").replace("http://", "ws://").trim_suffix("/") + "/v1/world"
    var error: Error = socket.connect_to_url(ws_url)
    if error == OK:
        sequence = 0
        hello_sent = false
        connecting = true
        connect_started = Time.get_ticks_msec()
        set_meta("map_id", map_id)
    return error

func _process(_delta: float) -> void:
    if _supabase_enabled() and expires_at_unix > 0 and int(Time.get_unix_time_from_system()) >= expires_at_unix - 120:
        _refresh_supabase_session()
    if not connecting and not joined:
        return
    if connecting and not joined and Time.get_ticks_msec() - connect_started > 12000:
        leave_world()
        return
    socket.poll()
    var state: int = socket.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        if not hello_sent:
            hello_sent = true
            socket.send_text(JSON.stringify({"type": "join", "protocol": PROTOCOL, "token": token, "map_id": get_meta("map_id", 0)}))
        while socket.get_available_packet_count() > 0:
            var value: Variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
            if value is Dictionary:
                if value.get("type") == "welcome" and int(value.get("protocol", -1)) == PROTOCOL:
                    joined = true
                    connecting = false
                    connection_changed.emit(true)
                snapshot_received.emit(value)
    elif state == WebSocketPeer.STATE_CLOSED or (not joined and Time.get_ticks_msec() - connect_started > 12000):
        connecting = false
        joined = false
        socket.close()
        connection_changed.emit(false)

func send_course(point: Vector2, route: Array = [], navigation_mode: String = "", raster_preexpanded: bool = false) -> void:
    if not joined or not point.is_finite():
        return
    sequence += 1
    var payload: Dictionary = {"type": "course", "sequence": sequence, "x": point.x, "y": point.y}
    if navigation_mode == "classic_48x32":
        payload["navigation_mode"] = "classic_48x32"
        if raster_preexpanded:
            payload["raster_preexpanded"] = true
    if not route.is_empty():
        var points: Array = []
        for waypoint: Vector2 in route:
            points.append([waypoint.x, waypoint.y])
        payload["route"] = points
    socket.send_text(JSON.stringify(payload))

func send_appearance(skin: int, hp: int, maximum: int) -> void:
    if joined:
        socket.send_text(JSON.stringify({"type": "appearance", "skin": skin, "hp": hp, "max_hp": maximum}))

func leave_world() -> void:
    if connecting or joined:
        socket.close()
    socket = WebSocketPeer.new()
    connecting = false
    joined = false
    hello_sent = false
    sequence = 0
    connection_changed.emit(false)

func sign_out() -> void:
    leave_world()
    token = ""
    refresh_token = ""
    expires_at_unix = 0
    account = {}
    if get_tree().has_meta("abyssal_session"):
        get_tree().remove_meta("abyssal_session")

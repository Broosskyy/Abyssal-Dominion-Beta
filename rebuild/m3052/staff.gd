extends RefCounted
## Staff session: who is signed in, what the role may do, how the ship appears, and the audit trail.
## The simulation asks authorize() before every privileged action, so permissions live in one place.
const CONTENT = preload("res://content.gd")
const AUDIT_LIMIT := 200
var role := ""
var presence := "official"
var flags := {}
var audit: Array = []
var snapshot: Dictionary = {}
var started := 0
var tap_teleport := false
var touched := false

func _init() -> void:
	_reset_flags()

func _reset_flags() -> void:
	flags={}
	for key in CONTENT.STAFF_FLAG_ORDER:flags[key]=false

static func code_hash(code: String) -> String:
	var normalized=""
	for character in code.to_upper():
		if (character>="A" and character<="Z") or (character>="0" and character<="9"):normalized+=character
	return (CONTENT.STAFF_CODE_SALT+normalized).sha256_text()

static func role_for_code(code: String) -> String:
	var digest=code_hash(code)
	for key in CONTENT.STAFF_ROLE_ORDER:
		if str(CONTENT.STAFF_ROLES[key].code_sha256)==digest:return key
	return ""

func active() -> bool:
	return CONTENT.STAFF_ROLES.has(role)

func can(permission: String) -> bool:
	return active() and permission in CONTENT.STAFF_ROLES[role].permissions

func flag(key: String) -> bool:
	return active() and bool(flags.get(key,false))

func powers_on() -> bool:
	if not active():return false
	for key in flags:
		if bool(flags[key]):return true
	return false

func badge() -> String:
	return str(CONTENT.STAFF_ROLES[role].badge) if active() else ""

func color() -> Color:
	return CONTENT.STAFF_ROLES[role].color if active() else Color.WHITE

func title() -> String:
	return str(CONTENT.STAFF_ROLES[role].name) if active() else ""

## Badge, aura and chart marker are shown only in the official presence.
func shows_badge() -> bool:
	return active() and presence=="official"

func hidden() -> bool:
	return active() and presence in ["ghost","spectator"]

func spectating() -> bool:
	return active() and presence=="spectator"

func sign_in(code: String,save: Dictionary) -> bool:
	var granted=role_for_code(code)
	if granted.is_empty():
		record("Anmeldung abgelehnt","falscher Zugangscode",false)
		return false
	role=granted
	presence="official"
	_reset_flags()
	tap_teleport=false
	touched=false
	snapshot=save.duplicate(true)
	started=int(Time.get_unix_time_from_system())
	record("Anmeldung",title())
	return true

func sign_out(restored: bool) -> void:
	record("Abmeldung","Ausgangszustand wiederhergestellt" if restored else "Änderungen behalten · Spielstand markiert")
	role=""
	presence="official"
	_reset_flags()
	tap_teleport=false
	touched=false
	snapshot={}
	started=0

func record(action: String,detail: String="",allowed: bool=true) -> void:
	audit.append({"time":int(Time.get_unix_time_from_system()),"role":role if not role.is_empty() else "-","action":action,"detail":detail,"allowed":allowed})
	while audit.size()>AUDIT_LIMIT:audit.pop_front()

## Every privileged action passes here: refused actions are logged as well.
func authorize(permission: String,action: String,detail: String="") -> bool:
	if not can(permission):
		record(action,"verweigert · Recht fehlt: "+str(CONTENT.STAFF_PERMISSIONS.get(permission,permission)),false)
		return false
	record(action,detail)
	return true

func export_state() -> Dictionary:
	return {"schema":1,"role":role,"presence":presence,"flags":flags.duplicate(),"audit":audit.duplicate(true),
		"snapshot":snapshot.duplicate(true),"started":started,"touched":touched}

func restore_state(data: Dictionary) -> void:
	if int(data.get("schema",0))!=1:return
	var saved_role=str(data.get("role",""))
	role=saved_role if CONTENT.STAFF_ROLES.has(saved_role) else ""
	var saved_presence=str(data.get("presence","official"))
	presence=saved_presence if saved_presence in CONTENT.STAFF_PRESENCE_ORDER else "official"
	_reset_flags()
	var saved_flags: Variant=data.get("flags",{})
	if saved_flags is Dictionary and active():
		for key in CONTENT.STAFF_FLAG_ORDER:flags[key]=bool(saved_flags.get(key,false))
	audit=[]
	var saved_audit: Variant=data.get("audit",[])
	if saved_audit is Array:
		for entry: Variant in saved_audit:
			if entry is Dictionary:audit.append({"time":int(entry.get("time",0)),"role":str(entry.get("role","-")),"action":str(entry.get("action","")),"detail":str(entry.get("detail","")),"allowed":bool(entry.get("allowed",true))})
	while audit.size()>AUDIT_LIMIT:audit.pop_front()
	var saved_snapshot: Variant=data.get("snapshot",{})
	snapshot=saved_snapshot if saved_snapshot is Dictionary and active() else {}
	started=int(data.get("started",0)) if active() else 0
	touched=bool(data.get("touched",false)) and active()

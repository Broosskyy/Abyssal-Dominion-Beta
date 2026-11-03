extends RefCounted
const VERSION_CODE := 305701
const PACKAGE := "com.abyssaldominion.rebuild"
const CERT := "278a2899340d58b3db0aced5e0f306ebb121550bc34dc1e6948783424652fe3b"
const RELEASE_ROOT := "https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/"
const MAX_BYTES := 350000000

static func whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==float(int(value))

static func release_url(code: int) -> String:
	return RELEASE_ROOT+"abyssal-%d-android/ABYSSAL_DOMINION_%d.apk"%[code,code]

static func valid_spec(value: Variant) -> bool:
	if not value is Dictionary:return false
	if not whole(value.get("version_code")) or int(value.version_code)<1 or int(value.version_code)>1000000:return false
	if value.get("package")!=PACKAGE or value.get("certificate_sha256")!=CERT:return false
	if not whole(value.get("bytes")) or int(value.bytes)<1000000 or int(value.bytes)>MAX_BYTES:return false
	if not value.get("sha256") is String:return false
	var regex=RegEx.new()
	regex.compile("^[0-9a-f]{64}$")
	if regex.search(value.sha256)==null:return false
	return value.get("url")==release_url(int(value.version_code))

static func manifest(value: Variant,current: int=VERSION_CODE) -> Dictionary:
	if not value is Dictionary or value.get("schema")!=1 or value.get("channel")!="test":return {"status":"invalid"}
	var spec=value.get("latest")
	if not valid_spec(spec):return {"status":"invalid"}
	return {"status":"available" if int(spec.version_code)>current else "current","spec":spec}

static func verify_file(spec: Dictionary,path: String) -> bool:
	if not valid_spec(spec):return false
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:return false
	if file.get_length()!=int(spec.bytes):file.close();return false
	var hash=HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256)!=OK:file.close();return false
	while file.get_position()<file.get_length():
		var chunk=file.get_buffer(mini(524288,file.get_length()-file.get_position()))
		if chunk.is_empty() or hash.update(chunk)!=OK:file.close();return false
	file.close()
	return hash.finish().hex_encode()==spec.sha256

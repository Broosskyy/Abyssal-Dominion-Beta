extends RefCounted
const SHELL=305903
const ABI=1
const ENGINE="4.7.2.stable"
const ROOT="https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/"
const MANIFEST="https://raw.githubusercontent.com/Broosskyy/Abyssal-Dominion-Beta/main/updates/data.json"
const PUBLIC_KEY="res://updater/data_public.pem"

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==float(int(value))

static func valid_spec(value: Variant) -> bool:
	if not value is Dictionary:return false
	for key in ["revision","bytes","min_apk","abi"]:
		if not integer(value.get(key)):return false
	if value.revision<1 or value.revision>1000000 or value.bytes<1000 or value.bytes>250000000:return false
	if value.abi!=ABI or value.get("engine")!=ENGINE or value.min_apk<305901 or value.min_apk>SHELL:return false
	if not value.get("sha256") is String or not value.get("signature") is String:return false
	var regex=RegEx.new();regex.compile("^[0-9a-f]{64}$")
	if regex.search(value.sha256)==null:return false
	var rev=int(value.revision)
	if value.get("url")!=ROOT+"data-%d/ABYSSAL_DATA_%d.zip"%[rev,rev]:return false
	var sig_regex=RegEx.new();sig_regex.compile("^[A-Za-z0-9+/]{342}==$" )
	if sig_regex.search(value.signature)==null:return false
	var signature=Marshalls.base64_to_raw(value.signature)
	if signature.size()!=256:return false
	var key=CryptoKey.new()
	if key.load_from_string(FileAccess.get_file_as_string(PUBLIC_KEY),true)!=OK:return false
	return Crypto.new().verify(HashingContext.HASH_SHA256,value.sha256.hex_decode(),signature,key)

static func manifest(value: Variant,current: int) -> Dictionary:
	if not value is Dictionary or value.get("schema")!=1 or value.get("channel")!="test":return {"status":"invalid"}
	var spec=value.get("latest")
	if spec is Dictionary and integer(spec.get("min_apk")) and int(spec.min_apk)>SHELL:return {"status":"shell_required"}
	if not valid_spec(spec):return {"status":"invalid"}
	return {"status":"available" if int(spec.revision)>current else "current","spec":spec}

static func verify_file(spec: Dictionary,path: String) -> bool:
	if not valid_spec(spec):return false
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:return false
	if file.get_length()!=int(spec.bytes):file.close();return false
	var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256)
	while file.get_position()<file.get_length():
		var bytes=file.get_buffer(mini(524288,file.get_length()-file.get_position()))
		if bytes.is_empty():file.close();return false
		hash.update(bytes)
	file.close()
	if hash.finish().hex_encode()!=spec.sha256:return false
	var archive=ZIPReader.new()
	if archive.open(path)!=OK:return false
	for entry: String in archive.get_files():
		if entry.begins_with("/") or ".." in entry.split("/") or "\\" in entry or entry.begins_with("updater/") or entry.ends_with(".so"):
			archive.close();return false
	if "assets/content_version.json" not in archive.get_files():archive.close();return false
	var info=JSON.parse_string(archive.read_file("assets/content_version.json").get_string_from_utf8())
	archive.close()
	return info is Dictionary and info.get("revision")==spec.revision and info.get("abi")==ABI and info.get("engine")==ENGINE and info.get("min_apk")==spec.min_apk

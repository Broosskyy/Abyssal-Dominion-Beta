class_name TelemetryContract
extends RefCounted
## M101 local envelope/validation only. No remote analytics transport exists yet.
const FORBIDDEN_KEYS:=["password","token","receipt","card","secret","authorization","cookie"]
static func envelope(name:String,context:Dictionary={})->Dictionary:
	var clean:Dictionary={}
	for key in context:
		var lower:=str(key).to_lower()
		var forbidden:=false
		for item in FORBIDDEN_KEYS:
			if lower.contains(item):forbidden=true;break
		if not forbidden:clean[key]=context[key]
	var build:=BuildIdentity.data()
	return {
		"schema":1,"event_name":name,"timestamp_msec":Time.get_unix_time_from_system()*1000.0,
		"environment":str(build.get("environment","LOCAL_DEVELOPMENT")),
		"build_version":str(build.get("client_version","?")),
		"build_number":int(build.get("build_number",0)),
		"content_config_version":str(build.get("content_config_version","?")),
		"context":clean,"transport":"none_local_contract"
	}

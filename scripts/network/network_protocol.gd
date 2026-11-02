class_name NetworkProtocol
extends RefCounted
## Transport compatibility contract only. No combat authority or account identity.

const VERSION := 1
const BUILD := "M12"
const MAX_PACKET_BYTES := 4096


static func valid_hello(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	return value.get("type") == "hello" and value.get("protocol") == VERSION and value.get("build") == BUILD


static func valid_url(url: String, secure_page: bool = false) -> bool:
	if url.length() > 2048 or "@" in url or " " in url or "\n" in url:
		return false
	if secure_page:
		return url.begins_with("wss://") and url.length() > 6
	return (url.begins_with("ws://") and url.length() > 5) or (url.begins_with("wss://") and url.length() > 6)

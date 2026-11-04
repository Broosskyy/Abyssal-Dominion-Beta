class_name StableContentSeed
extends RefCounted
## FNV-1a style deterministic 32-bit seed. Avoids runtime String.hash() as content/world truth.
static func from_parts(parts:Array)->int:
	var h:int=2166136261
	for part in parts:
		for byte in str(part).to_utf8_buffer():
			h=h^int(byte)
			h=int((h*16777619)&0x7fffffff)
		h=h^31
	return maxi(1,h)

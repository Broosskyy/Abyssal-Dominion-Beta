class_name ShipVisualSocketAdapter
extends RefCounted

static func ensure_visual_sockets(root: Node3D, bounds: AABB) -> Dictionary:
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	var definitions := {
		"socket_muzzle_port": Vector3(center.x - half.x * 0.82, maxf(0.35, center.y), center.z),
		"socket_muzzle_starboard": Vector3(center.x + half.x * 0.82, maxf(0.35, center.y), center.z),
		"socket_wake": Vector3(center.x, 0.02, center.z - half.z * 0.92),
		"socket_bow_foam": Vector3(center.x, 0.02, center.z + half.z * 0.92),
		"socket_nameplate": Vector3(center.x, maxf(bounds.end.y + 0.45, 1.0), center.z),
		"socket_selection": Vector3(center.x, 0.02, center.z)
	}
	var result := {}
	for id in definitions:
		var existing := root.find_child(id,true,false)
		if existing is Node3D:
			result[id] = existing
			continue
		var marker := Marker3D.new()
		marker.name = id
		marker.position = definitions[id]
		marker.set_meta("classification","DERIVED_VISUAL_FALLBACK")
		root.add_child(marker)
		result[id] = marker
	return result

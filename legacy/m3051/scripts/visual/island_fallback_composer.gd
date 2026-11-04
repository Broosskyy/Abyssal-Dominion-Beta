class_name IslandFallbackComposer
extends RefCounted
## Adds low-cost visual lobes to procedural/shared island fallbacks only.
## Collision/navigation remain on the island wrapper and are never derived from these meshes.

static func apply(island: Node3D, profile_id: String) -> void:
	var p:=IslandCompositionCatalog.profile(profile_id)
	if p.is_empty(): return
	var old:=island.get_node_or_null("M71IslandComposition")
	if old != null: old.queue_free()
	var root:=Node3D.new()
	root.name="M71IslandComposition"
	root.set_meta("classification","POLISHED_PROCEDURAL_FALLBACK")
	island.add_child(root)
	var radius:=float(island.get_meta("island_radius",5.0))
	var aspect:Array=p.get("aspect",[1.0,1.0])
	var h:=float(p.get("height",0.8))
	for i in p.get("lobes",[]).size():
		var l:Array=p.get("lobes",[])[i]
		var scale_factor:=float(l[2])
		var rock:=MeshInstance3D.new()
		rock.name="RockLobe_%02d"%i
		rock.mesh=FallbackPrimitiveLibrary.cylinder(0.72,1.0,maxf(0.45,h*1.15))
		rock.position=Vector3(float(l[0])*radius*float(aspect[0]),0.54,float(l[1])*radius*float(aspect[1]))
		rock.scale=Vector3(radius*scale_factor*float(aspect[0]),1.0,radius*scale_factor*0.72*float(aspect[1]))
		rock.material_override=EnvironmentMaterialCatalog.rock()
		root.add_child(rock)
		var cap:=MeshInstance3D.new()
		cap.name="GroundLobe_%02d"%i
		cap.mesh=FallbackPrimitiveLibrary.cylinder(0.92,1.0,0.22)
		cap.position=rock.position+Vector3.UP*(h*0.52+0.28)
		cap.scale=Vector3(radius*scale_factor*0.90*float(aspect[0]),1.0,radius*scale_factor*0.62*float(aspect[1]))
		cap.material_override=EnvironmentMaterialCatalog.vegetation()
		root.add_child(cap)


	# M87: profile-specific asymmetry makes procedural fallbacks read as islands, not round platforms.
	if profile_id in ["cliff_cove","thin_spit","long_shoal"]:
		_add_silhouette_accent(root,profile_id,radius,aspect,h)
	_add_m191_edge_break(root,profile_id,radius,h)

static func _add_silhouette_accent(root:Node3D,profile_id:String,radius:float,aspect:Array,h:float)->void:
	var accent:=MeshInstance3D.new()
	accent.name="M87SilhouetteAccent"
	match profile_id:
		"cliff_cove":
			accent.mesh=FallbackPrimitiveLibrary.box(Vector3(radius*0.72,h*1.5,radius*0.28))
			accent.position=Vector3(-radius*0.42,h*0.72,radius*0.32)
			accent.rotation_degrees.y=-24.0
		"thin_spit":
			accent.mesh=FallbackPrimitiveLibrary.sphere(radius*0.20,radius*0.26)
			accent.scale=Vector3(1.9,0.35,0.58)
			accent.position=Vector3(radius*0.62,h*0.30,-radius*0.12)
			accent.rotation_degrees.y=28.0
		"long_shoal":
			accent.mesh=FallbackPrimitiveLibrary.sphere(radius*0.28,radius*0.34)
			accent.scale=Vector3(1.65,0.42,0.72)
			accent.position=Vector3(-radius*0.70,h*0.32,radius*0.16)
			accent.rotation_degrees.y=-18.0
	accent.material_override=EnvironmentMaterialCatalog.rock()
	root.add_child(accent)


static func _add_m191_edge_break(root:Node3D,profile_id:String,radius:float,h:float)->void:
	var accent:=MeshInstance3D.new()
	accent.name="M191EdgeBreak"
	accent.mesh=FallbackPrimitiveLibrary.sphere(radius*0.22,radius*0.28)
	var side:float=-1.0 if profile_id in ["cliff_cove","long_shoal"] else 1.0
	accent.position=Vector3(side*radius*0.62,maxf(0.18,h*0.28),radius*0.30)
	accent.scale=Vector3(1.35,0.34,0.66)
	accent.rotation_degrees.y=side*19.0
	accent.material_override=EnvironmentMaterialCatalog.rock()
	accent.set_meta("visual_only",true)
	root.add_child(accent)

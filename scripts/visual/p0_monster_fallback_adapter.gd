class_name P0MonsterFallbackAdapter
extends RefCounted

static func apply_first_monster(ship:Node3D)->void:
	if ship==null:return
	var visual:=ship.get_node_or_null("Visual") as Node3D
	if visual==null:return
	var root:=Node3D.new();root.name="P0KrakenReadability";root.set_meta("visual_only",true);visual.add_child(root)
	# Radial tentacle roots make the creature read as a monster from the oblique mobile camera.
	for i in range(6):
		var angle:=TAU*float(i)/6.0
		var tentacle:=MeshInstance3D.new()
		tentacle.name="KrakenArm_%02d"%i
		tentacle.mesh=FallbackPrimitiveLibrary.cylinder(0.15,0.34,2.6+0.2*float(i%2))
		tentacle.position=Vector3(cos(angle)*1.85,-0.18,sin(angle)*1.85)
		tentacle.rotation_degrees=Vector3(58.0*sin(angle),0.0,58.0*cos(angle))
		tentacle.material_override=EnvironmentMaterialCatalog.monster_skin()
		root.add_child(tentacle)
	var crown:=MeshInstance3D.new();crown.name="KrakenMantle"
	crown.mesh=FallbackPrimitiveLibrary.sphere(0.75,1.2);crown.position=Vector3(0,1.35,0.55);crown.scale=Vector3(1.25,1.15,1.35)
	crown.material_override=EnvironmentMaterialCatalog.monster_skin();root.add_child(crown)
	ship.set_meta("production_slot","MON-KRAKEN-001")
	ship.set_meta("monster_family","kraken")
	ship.set_meta("p0_mobile_readability_ready",true)
	ship.set_meta("placeholder_replacement_ready",true)

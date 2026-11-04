class_name ProceduralShipSilhouetteAdapter
extends RefCounted

static func production_slot_for_gameplay_ship(ship_id:String)->String:
	if ship_id.begins_with("ship_main_"):
		var suffix:=ship_id.trim_prefix("ship_main_")
		return "SHIP-PROG-%03d"%int(suffix)
	if ship_id==BeginnerRules.START_SHIP:return "SHIP-STARTER-001"
	var rewards:Array=BeginnerRules.SHIP_REWARDS.values()
	var index:=rewards.find(ship_id)
	if index>=0:return "SHIP-STARTER-%03d"%mini(3,index+2)
	return ""

static func apply(ship:Node3D,slot_id:String)->void:
	if ship==null or slot_id.is_empty():return
	var profile:=ProductionPlaceholderContract.ship_silhouette(slot_id)
	if profile.is_empty():return
	var visual:=ship.get_node_or_null("Visual") as Node3D
	if visual==null:return
	var silhouette:=str(profile.get("silhouette","compact_sloop"))
	var length_class:=str(profile.get("length_class","medium"))
	var length_mult:=float(profile.get("length_mult",{"small":0.84,"medium":1.0,"large":1.12,"long":1.28,"heavy":1.18}.get(length_class,1.0)))
	var width_mult:=float(profile.get("width_mult",1.0))
	var height_mult:=float(profile.get("height_mult",1.0))
	if not profile.has("width_mult"):
		match silhouette:
			"compact_sloop":width_mult=0.82;height_mult=0.90
			"lean_cutter":width_mult=0.72;height_mult=0.84
			"broad_brig":width_mult=1.18;height_mult=1.02
			"long_corvette":width_mult=0.88;height_mult=0.90
			"heavy_galleon":width_mult=1.30;height_mult=1.16
			"high_stern_raider":width_mult=0.96;height_mult=1.20
			"low_fast_hunter":width_mult=0.76;height_mult=0.76
			"wide_brawler":width_mult=1.36;height_mult=0.92
			"ornate_flagship":width_mult=1.16;height_mult=1.28
			"asymmetric_relic":width_mult=1.08;height_mult=1.10
	visual.scale=Vector3(width_mult,height_mult,length_mult)
	var mast_mult:float=float({"low":0.78,"balanced":1.0,"tall":1.22}.get(str(profile.get("mast_profile","balanced")),1.0))
	for child in visual.get_children():
		if child is Node3D and (str(child.name).begins_with("Mast") or str(child.name).begins_with("Sail")):
			(child as Node3D).scale.y*=mast_mult
	# Cheap visual-only masses strengthen bow/stern identity at mobile gameplay zoom.
	if visual.get_node_or_null("M141SilhouetteAccent")==null:
		var accent:=Node3D.new();accent.name="M141SilhouetteAccent";accent.set_meta("visual_only",true);visual.add_child(accent)
		if silhouette in ["starter_galleon","heavy_barque","heavy_galleon","high_stern_raider","ornate_flagship"]:
			var stern:=MeshInstance3D.new();stern.name="HighStern";stern.mesh=FallbackPrimitiveLibrary.box(Vector3(1.6,0.8,0.75))
			stern.position=Vector3(0,1.05,-2.0);stern.material_override=EnvironmentMaterialCatalog.harbor_wood();accent.add_child(stern)
		if silhouette in ["corsair_cutter","hunter_schooner","lean_cutter","long_corvette","low_fast_hunter"]:
			var bow:=MeshInstance3D.new();bow.name="LongBow";bow.mesh=FallbackPrimitiveLibrary.box(Vector3(0.75,0.28,1.2))
			bow.position=Vector3(0,0.35,2.8);bow.material_override=EnvironmentMaterialCatalog.harbor_wood();accent.add_child(bow)
		if silhouette in ["starter_sloop","coastal_sloop"]:
			var sail_mark:=MeshInstance3D.new();sail_mark.name="StarterSailMass";sail_mark.mesh=FallbackPrimitiveLibrary.box(Vector3(1.1,0.08,0.75))
			sail_mark.position=Vector3(0,1.65,0.4);sail_mark.material_override=EnvironmentMaterialCatalog.sail_canvas();accent.add_child(sail_mark)
	ship.set_meta("production_slot",slot_id)
	ship.set_meta("procedural_silhouette",silhouette)
	ship.set_meta("silhouette_profile",profile.duplicate(true))
	ship.set_meta("placeholder_replacement_ready",true)

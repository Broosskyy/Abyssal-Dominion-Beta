class_name HavensReachVisualComposer
extends RefCounted
const MODULES:Array=[
	{"id":"HARBOR-HAVENS-REACH-DOCK","name":"MainDock","position":Vector3(0,0.15,0),"size":Vector3(7.2,0.22,1.8),"kind":"wood"},
	{"id":"HARBOR-HAVENS-REACH-WAREHOUSE","name":"Warehouse","position":Vector3(-4.8,0.65,3.4),"size":Vector3(2.8,1.3,2.2),"kind":"wood"},
	{"id":"HARBOR-HAVENS-REACH-MARKET","name":"Market","position":Vector3(4.7,0.48,3.1),"size":Vector3(2.6,0.95,2.0),"kind":"canvas"},
	{"id":"HARBOR-HAVENS-REACH-SHIPYARD","name":"Shipyard","position":Vector3(-5.6,0.5,7.3),"size":Vector3(2.8,1.0,2.5),"kind":"wood"},
	{"id":"HARBOR-HAVENS-REACH-BEACON","name":"Beacon","position":Vector3(5.4,1.0,7.0),"size":Vector3(0.7,2.0,0.7),"kind":"stone"},
]
static func apply(port:Node3D)->void:
	if port==null or port.get_node_or_null("P0HarborVisual")!=null:return
	var root:=Node3D.new();root.name="P0HarborVisual";root.set_meta("visual_only",true);root.set_meta("production_priority","P0");port.add_child(root)
	for row in MODULES:
		var socket:=Node3D.new();socket.name=str(row.name);socket.position=row.position
		socket.set_meta("production_slot",str(row.id));socket.set_meta("placeholder_replacement_ready",true);root.add_child(socket)
		var mesh:=MeshInstance3D.new();mesh.name="Placeholder";mesh.mesh=FallbackPrimitiveLibrary.box(row.size)
		match str(row.kind):
			"stone":mesh.material_override=EnvironmentMaterialCatalog.harbor_stone()
			"canvas":mesh.material_override=EnvironmentMaterialCatalog.sail_canvas()
			_:mesh.material_override=EnvironmentMaterialCatalog.harbor_wood()
		socket.add_child(mesh)
	root.set_meta("module_count",MODULES.size())
	root.set_meta("mobile_readability_rule","dock_beacon_market_shipyard_separate_masses")

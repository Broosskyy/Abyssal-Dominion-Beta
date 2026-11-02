class_name CompanionVisualFactory
extends RefCounted

static func create(definition: Dictionary) -> Node3D:
	var root := Node3D.new(); root.name = "M152CompanionFallback"; root.set_meta("visual_only",true); root.set_meta("final_glb",false); root.set_meta("collision_authority",false)
	var id := str(definition.get("id", "")); var color := _color(id); var body := MeshInstance3D.new(); body.name = "Body"; var mesh := SphereMesh.new(); mesh.radius = 0.42; mesh.height = 0.72; body.mesh = mesh; body.material_override = _material(color); root.add_child(body)
	if "GULL" in id:
		_wing(root,-0.52,color.lightened(0.25)); _wing(root,0.52,color.lightened(0.25))
	elif "CRAB" in id:
		body.scale = Vector3(1.35,0.55,1.0); _claw(root,-0.62,color); _claw(root,0.62,color)
	elif "KRAKEN" in id:
		for i in 6: _tentacle(root,i,color)
	elif "SKIFF" in id:
		body.mesh = BoxMesh.new(); (body.mesh as BoxMesh).size = Vector3(0.95,0.35,1.65); _mast(root,color.lightened(0.35))
	elif "LANTERN" in id:
		var ring := MeshInstance3D.new(); var torus := TorusMesh.new(); torus.inner_radius=0.48; torus.outer_radius=0.56; ring.mesh=torus; ring.rotation_degrees.x=90; ring.material_override=_material(color,true); root.add_child(ring)
	else:
		body.material_override = _material(color,true)
	return root

static func _wing(root:Node3D,x:float,color:Color)->void:
	var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=Vector3(0.72,0.08,0.34);n.mesh=m;n.position=Vector3(x,0,0);n.rotation_degrees.z=18.0*sign(x);n.material_override=_material(color);root.add_child(n)
static func _claw(root:Node3D,x:float,color:Color)->void:
	var n:=MeshInstance3D.new();var m:=SphereMesh.new();m.radius=0.25;m.height=0.35;n.mesh=m;n.position=Vector3(x,0.05,-0.22);n.material_override=_material(color);root.add_child(n)
static func _tentacle(root:Node3D,i:int,color:Color)->void:
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=0.05;m.bottom_radius=0.10;m.height=0.7;m.radial_segments=7;n.mesh=m;var a:=TAU*float(i)/6.0;n.position=Vector3(cos(a)*0.28,-0.44,sin(a)*0.28);n.rotation_degrees=Vector3(18*cos(a),0,18*sin(a));n.material_override=_material(color);root.add_child(n)
static func _mast(root:Node3D,color:Color)->void:
	var n:=MeshInstance3D.new();var m:=BoxMesh.new();m.size=Vector3(0.75,0.62,0.06);n.mesh=m;n.position=Vector3(0,0.5,0);n.material_override=_material(color);root.add_child(n)
static func _material(color:Color,emission:bool=false)->StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.72
	if emission:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=0.45
	return m
static func _color(id:String)->Color:
	if "GULL" in id:return Color("dce7e8")
	if "CRAB" in id:return Color("bd593d")
	if "SPRITE" in id:return Color("4fc9d6")
	if "KRAKEN" in id:return Color("7351a2")
	if "SKIFF" in id:return Color("536b72")
	return Color("5ad9c4")

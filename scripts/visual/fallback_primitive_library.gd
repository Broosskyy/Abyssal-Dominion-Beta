class_name FallbackPrimitiveLibrary
extends RefCounted
## M80 shared visual-only primitive resources.
## Mesh resources are reused; nodes remain separate and gameplay never depends on them.

static var _boxes:Dictionary={}
static var _spheres:Dictionary={}
static var _cylinders:Dictionary={}
static var _torus:Dictionary={}
static var _quads:Dictionary={}

static func box(size:Vector3)->BoxMesh:
	var key:="%0.3f|%0.3f|%0.3f"%[size.x,size.y,size.z]
	if not _boxes.has(key):
		var mesh:=BoxMesh.new()
		mesh.size=size
		_boxes[key]=mesh
	return _boxes[key] as BoxMesh

static func sphere(radius:float,height:float)->SphereMesh:
	var key:="%0.3f|%0.3f"%[radius,height]
	if not _spheres.has(key):
		var mesh:=SphereMesh.new()
		mesh.radius=radius
		mesh.height=height
		_spheres[key]=mesh
	return _spheres[key] as SphereMesh

static func cylinder(top_radius:float,bottom_radius:float,height:float)->CylinderMesh:
	var key:="%0.3f|%0.3f|%0.3f"%[top_radius,bottom_radius,height]
	if not _cylinders.has(key):
		var mesh:=CylinderMesh.new()
		mesh.top_radius=top_radius
		mesh.bottom_radius=bottom_radius
		mesh.height=height
		_cylinders[key]=mesh
	return _cylinders[key] as CylinderMesh

static func torus(inner_radius:float,outer_radius:float)->TorusMesh:
	var key:="%0.3f|%0.3f"%[inner_radius,outer_radius]
	if not _torus.has(key):
		var mesh:=TorusMesh.new()
		mesh.inner_radius=inner_radius
		mesh.outer_radius=outer_radius
		_torus[key]=mesh
	return _torus[key] as TorusMesh

static func quad(size:Vector2)->QuadMesh:
	var key:="%0.3f|%0.3f"%[size.x,size.y]
	if not _quads.has(key):
		var mesh:=QuadMesh.new()
		mesh.size=size
		_quads[key]=mesh
	return _quads[key] as QuadMesh


static func mesh_node(name:String,mesh:Mesh,material:Material,position:Vector3=Vector3.ZERO)->MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.name=name
	node.mesh=mesh
	node.position=position
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

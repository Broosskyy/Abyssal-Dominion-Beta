extends RefCounted
## Small cached 2D deformation cycles: original raster detail is preserved.
## No runtime 3D viewport, extra texture download or per-frame mesh allocation.
const FRAMES := 16
const GRID := Vector2i(20,16)
static var cycles: Dictionary={}

static func offset(key: String, uv: Vector2, phase: float) -> Vector2:
	var side: float=uv.x-.5
	match key:
		"kraken":
			# The mantle and eyes stay planted; the outer arms curl in waves.
			var arms: float=smoothstep(.12,.48,uv.distance_to(Vector2(.53,.35)))
			return Vector2(sin(phase+uv.y*9.0+side*5.0)*.035,cos(phase+uv.x*11.0)*.025)*arms
		"serpent":
			# A wave travels from the neck into the tail, rather than rotating
			# the entire illustration around its center.
			var tail: float=smoothstep(.12,.9,uv.x)
			return Vector2(sin(phase-uv.x*7.0)*.015,sin(phase-uv.x*8.0)*.045)*tail
		"crab":
			# Alternating side limbs and a slower front-claw squeeze.
			var legs: float=smoothstep(.15,.43,absf(side))
			var claw: float=smoothstep(.52,.93,uv.y)*(1.0-legs*.6)
			return Vector2(sin(phase+uv.y*12.0+signf(side)*PI*.5)*.024*legs+sin(phase)*.019*claw,cos(phase+uv.y*12.0+signf(side)*PI*.5)*.028*legs-sin(phase)*.022*claw)
	return Vector2.ZERO

static func frame(key: String, time: float, id: int, moving: bool) -> ArrayMesh:
	if not cycles.has(key):
		var frames: Array[ArrayMesh]=[]
		frames.append(_mesh(key,0.0,false))
		for i in FRAMES:frames.append(_mesh(key,TAU*float(i)/FRAMES,true))
		cycles[key]=frames
	var index: int=1+posmod(floori(time*8.0)+id*3,FRAMES) if moving else 0
	return cycles[key][index]

static func _mesh(key: String, phase: float, moving: bool) -> ArrayMesh:
	var vertices:=PackedVector2Array()
	var uvs:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for y in GRID.y+1:
		for x in GRID.x+1:
			var uv:=Vector2(float(x)/GRID.x,float(y)/GRID.y)
			uvs.append(uv)
			vertices.append(uv-Vector2(.5,.5)+(offset(key,uv,phase) if moving else Vector2.ZERO))
	for y in GRID.y:
		for x in GRID.x:
			var a: int=y*(GRID.x+1)+x
			indices.append_array(PackedInt32Array([a,a+1,a+GRID.x+1,a+1,a+GRID.x+2,a+GRID.x+1]))
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

class_name EnvironmentMaterialCatalog
extends RefCounted

static func standard(id: String, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var tex := TextureMaterialCatalog.texture(id)
	if tex != null:
		material.albedo_texture = tex
	material.albedo_color = tint
	material.roughness = 0.82
	material.metallic = 0.0
	return material

static func sand() -> StandardMaterial3D:
	return standard("sand_base", Color("e2c486"))

static func rock() -> StandardMaterial3D:
	return standard("rock_base", Color("8f8678"))

static func vegetation() -> StandardMaterial3D:
	var material := standard("vegetation_base", Color("628a55"))
	material.roughness = 0.9
	return material

static func harbor_wood() -> StandardMaterial3D:
	return standard("harbor_wood", Color("95643c"))

static func harbor_stone() -> StandardMaterial3D:
	return standard("harbor_stone", Color("8b918c"))

static func sail_canvas() -> StandardMaterial3D:
	return standard("sail_canvas", Color("d8cfb5"))

static func bone() -> StandardMaterial3D:
	return standard("bone", Color("d8d0b7"))

static func monster_skin() -> StandardMaterial3D:
	var material:=standard("monster_skin",Color("344b4a"))
	material.roughness=0.68
	return material

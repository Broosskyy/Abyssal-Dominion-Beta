class_name M155LootQaScene
extends Node3D

const IDS := ["loot_coin_cache","loot_salvage_bundle","loot_chest_rare","loot_admiral_vault","repair_crate"]
const LABELS := ["COIN CACHE","SALVAGE BUNDLE","TIER CHEST","ADMIRAL VAULT","REPAIR CRATE"]

func _ready()->void:
	name="M155LootQA"
	set_meta("milestone","M155")
	set_meta("purpose","clean-room loot GLB gameplay readability / replacement QA")
	_build_environment()
	for i in IDS.size():_add_asset(IDS[i],LABELS[i],Vector3((i-2)*4.1,0,0))

func _build_environment()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("123746");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c6d5d7");env.ambient_light_energy=0.9;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-28,0);sun.light_energy=1.15;sun.shadow_enabled=true;add_child(sun)
	var camera:=Camera3D.new();camera.position=Vector3(0,15,18);camera.fov=46;camera.current=true;add_child(camera);camera.look_at(Vector3(0,0,0))
	var deck:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(24,9);deck.mesh=plane;deck.position.y=-0.65;var mat:=StandardMaterial3D.new();mat.albedo_color=Color("1a5360");mat.roughness=0.72;deck.material_override=mat;add_child(deck)

func _add_asset(id:String,label_text:String,pos:Vector3)->void:
	var holder:=Node3D.new();holder.name=id;holder.position=pos;add_child(holder)
	var visual:=AssetVisualLibrary.install(holder,id)
	if visual!=null:visual.rotation_degrees.y=-22
	var label:=Label3D.new();label.text=label_text;label.position=Vector3(0,1.6,0);label.font_size=30;label.outline_size=8;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;holder.add_child(label)

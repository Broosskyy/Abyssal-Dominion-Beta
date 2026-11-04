class_name BonusMapInstanceRouter
extends Node3D
signal instance_changed(active:bool,kind:String)
const PATH:="res://data/m117_bonusmap_instances.json"
var world:WorldMapSystem
var player:ShipMotor
var active_kind:=""
var instance_root:Node3D
var return_sector:=Vector2i.ZERO
var return_position:=Vector3.ZERO
var wave_director:BonusMapWaveDirector
func setup(map:WorldMapSystem,captain:ShipMotor)->void:world=map;player=captain
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
func active()->bool:return not active_kind.is_empty() and is_instance_valid(instance_root)
func enter(kind:String)->bool:
	if active() or world==null or player==null:return false
	var def:=((data().get("instances",{}) as Dictionary).get(kind,{}) as Dictionary)
	if def.is_empty():
		var dynamic:=DynamicContentResolver.by_id(get_tree(),"encounter",kind)
		if not dynamic.is_empty():def={"size":float(dynamic.get("arena_size",64.0))}
	if def.is_empty():return false
	return_sector=world.current_sector;return_position=player.position;active_kind=kind
	world.set_process(false)
	if world.sector_content!=null:world.sector_content.visible=false
	instance_root=Node3D.new();instance_root.name="BonusMapInstance_"+kind;world.add_child(instance_root)
	player.position=Vector3.ZERO;player.stop_ship()
	player.set_meta("bonusmap_instance_kind",kind);player.set_meta("bonusmap_instance_owned",true)
	_build_arena(def)
	instance_changed.emit(true,kind);return true
func exit()->void:
	if not active():return
	if wave_director!=null:wave_director.clear()
	instance_root.queue_free();instance_root=null
	player.set_meta("bonusmap_instance_kind","");player.set_meta("bonusmap_instance_owned",false)
	active_kind=""
	if world.sector_content!=null:world.sector_content.visible=true
	world.set_process(true);world.restore_sector(return_sector);player.position=return_position;player.stop_ship()
	instance_changed.emit(false,"")
func _build_arena(def:Dictionary)->void:
	var sea:=MeshInstance3D.new();sea.name="InstanceSea"
	var mesh:=PlaneMesh.new();mesh.size=Vector2(float(def.get("size",64)),float(def.get("size",64)));sea.mesh=mesh
	instance_root.add_child(sea)
	for i in 4:
		var marker:=MeshInstance3D.new();marker.name="Boundary_%d"%i
		var box:=BoxMesh.new();box.size=Vector3(12,0.35,3);marker.mesh=box
		marker.position=Vector3(-24.0+i*16.0,0.1,-28.0 if i%2==0 else 28.0);instance_root.add_child(marker)
	wave_director=BonusMapWaveDirector.new();wave_director.name="BonusMapWaveDirector";instance_root.add_child(wave_director)
	wave_director.setup(active_kind,instance_root,player)
	wave_director.start_wave(1)
func owns(ship:Node)->bool:return active() and ship!=null and instance_root.is_ancestor_of(ship)

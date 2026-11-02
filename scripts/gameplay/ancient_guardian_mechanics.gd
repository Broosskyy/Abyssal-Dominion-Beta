class_name AncientGuardianMechanics
extends Node
signal mechanic_fired(kind:String)
var ship:ShipMotor
var target:ShipMotor
var kind:=""
var timer:=4.0
var telegraph:=0.0
var pending:=""
var telegraph_root:Node3D
var pulse_ring:MeshInstance3D
var barrier_ring:MeshInstance3D

func setup(owner_ship:ShipMotor,player:ShipMotor,mechanic:String)->void:
	ship=owner_ship
	target=player
	kind=mechanic
	_build_placeholder_visuals()

func _build_placeholder_visuals()->void:
	telegraph_root=Node3D.new()
	telegraph_root.name="TelegraphPlaceholder"
	ship.add_child(telegraph_root)
	telegraph_root.set_meta("asset_slot","vfx_relic_barrier_telegraph_01" if kind=="relic_barrier" else "vfx_pressure_pulse_telegraph_01")
	telegraph_root.set_meta("placeholder_replacement_ready",true)
	var ring:=TorusMesh.new()
	ring.inner_radius=7.5 if kind=="pressure_pulse" else 3.3
	ring.outer_radius=8.0 if kind=="pressure_pulse" else 3.7
	ring.rings=24
	ring.ring_segments=12
	var mesh:=MeshInstance3D.new()
	mesh.mesh=ring
	mesh.rotation_degrees.x=90.0
	mesh.visible=false
	var mat:=StandardMaterial3D.new()
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color(0.74,0.18,0.92,0.55) if kind=="pressure_pulse" else Color(0.25,0.72,1.0,0.48)
	mesh.material_override=mat
	telegraph_root.add_child(mesh)
	if kind=="pressure_pulse":pulse_ring=mesh
	else:barrier_ring=mesh

func _process(delta:float)->void:
	if ship==null or target==null:return
	var near_enough:=ship.global_position.distance_to(target.global_position)<=72.0
	if telegraph_root!=null:telegraph_root.visible=near_enough
	if not near_enough:return
	if telegraph>0.0:
		telegraph-=delta
		var progress:=1.0-clampf(telegraph/(1.6 if kind=="relic_barrier" else 1.25),0.0,1.0)
		var visual:=barrier_ring if kind=="relic_barrier" else pulse_ring
		if visual!=null:
			visual.visible=true
			visual.scale=Vector3.ONE*(0.72+progress*0.28)
		if telegraph<=0.0:_fire()
		return
	timer-=delta
	if timer<=0.0:
		pending=kind
		telegraph=1.6 if kind=="relic_barrier" else 1.25
		ship.set_meta("danger_telegraph",pending)
		ship.set_meta("danger_telegraph_until",Time.get_ticks_msec()/1000.0+telegraph)
		timer=9.0 if kind=="relic_barrier" else 7.0

func _fire()->void:
	var visual:=barrier_ring if pending=="relic_barrier" else pulse_ring
	if visual!=null:visual.visible=false
	if pending=="relic_barrier":
		var health:=ship.get_node_or_null("Health") as ShipHealth
		if health!=null:health.grant_temporary_barrier(maxf(180.0,health.max_health*0.16),4.5)
	elif pending=="pressure_pulse" and ship.global_position.distance_to(target.global_position)<=16.0:
		var health:=target.get_node_or_null("Health") as ShipHealth
		if health!=null:health.apply_damage(135.0,ship,0.18,0.25,false)
		target.add_speed_effect("titan_pressure",0.72,2.8)
	ship.set_meta("danger_telegraph","")
	mechanic_fired.emit(pending)
	pending=""

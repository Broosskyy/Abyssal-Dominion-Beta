class_name VoidMonsterMechanics
extends Node
var ship:ShipMotor
var target:ShipMotor
var phase:=1
var timer:=5.0
func setup(owner_ship:ShipMotor,player:ShipMotor)->void:
	ship=owner_ship;target=player
	ship.set_meta("void_phase",phase)
	ship.set_meta("mechanic_asset_slot","vfx_void_phase_telegraph_01")
func _process(delta:float)->void:
	if ship==null or target==null:return
	var health:=ship.get_node_or_null("Health") as ShipHealth
	if health==null:return
	var ratio:float=health.normalized()
	var wanted:=3 if ratio<=0.33 else (2 if ratio<=0.66 else 1)
	if wanted!=phase:
		phase=wanted;ship.set_meta("void_phase",phase);ship.set_meta("danger_telegraph","void_phase_%d"%phase)
	timer-=delta
	if timer<=0.0:
		timer=maxf(3.2,6.2-float(phase))
		if ship.global_position.distance_to(target.global_position)<=14.0+phase*2.0:
			var target_health:=target.get_node_or_null("Health") as ShipHealth
			if target_health!=null:target_health.apply_damage(90.0+phase*35.0,ship,0.12*phase,0.08*phase,false)

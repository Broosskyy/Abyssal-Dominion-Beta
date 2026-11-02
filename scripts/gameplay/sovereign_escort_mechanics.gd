class_name SovereignEscortMechanics
extends Node
var ship:ShipMotor
var target:ShipMotor
var aura_timer:=0.0
func setup(owner_ship:ShipMotor,player:ShipMotor)->void:
	ship=owner_ship;target=player
	ship.set_meta("encounter_role","hero_escort")
	ship.set_meta("asset_slot","NPC-SHIP-SOV-004")
	ship.set_meta("placeholder_replacement_ready",true)
func _process(delta:float)->void:
	if ship==null or target==null:return
	aura_timer-=delta
	if aura_timer>0.0:return
	aura_timer=5.0
	var health:=ship.get_node_or_null("Health") as ShipHealth
	if health!=null and ship.global_position.distance_to(target.global_position)<=24.0:
		health.grant_temporary_barrier(maxf(90.0,health.max_health*0.08),3.0)

extends SceneTree
const ZONE = preload("res://scripts/network/classic_zone.gd")
var failed: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok: failed.append(label)
func _initialize() -> void:
	var z := ZONE.new()
	z.join(2)
	z.join(3)
	var seq := 0
	seq+=1
	check(z.command(2,{"seq":seq,"op":"move","x":40.0,"z":0.0}),"accept route")
	for i in 20: z.step(0.05)
	check(absf(z.players[2].x-11.0)<0.01,"server speed bounded to eleven per second")
	check(not z.command(2,{"seq":seq,"op":"move","x":130.0,"z":90.0}),"reject replay")
	seq+=1
	check(not z.command(2,{"seq":seq,"op":"move","x":INF,"z":0}),"reject nonfinite")
	seq+=1
	check(not z.command(2,{"seq":seq,"op":"move","x":-42.0,"z":-27.0}),"reject inside island")
	seq+=1
	check(not z.command(2,{"seq":seq,"op":"move","x":100000,"z":0}),"reject outside zone")
	seq+=1
	check(not z.command(2,{"seq":seq,"op":"buy","item":0}),"no money no ammo purchase")
	check(z.players[2].ammo[0]==100,"no free ammo")
	z.players[2].x=0.0
	z.players[2].z=0.0
	z.players[2].path=[]
	seq+=1
	check(z.command(2,{"seq":seq,"op":"target","target":0}),"target NPC")
	seq+=1
	z.command(2,{"seq":seq,"op":"fire","enabled":true})
	for i in 125: z.step(0.05)
	check(int(z.npcs[0].hp)==0,"NPC damage computed on server")
	check(int(z.players[2].ammo[0])==95,"five shots consume five rounds")
	check(int(z.players[2].kills)==1 and z.drops.size()==1,"one kill one drop")
	check(int(z.players[2].gold)==0,"gold only on collection")
	z.players[3].x=-13.0
	z.players[3].z=-25.0
	z.step(0.05)
	check(int(z.players[3].gold)==0,"other player cannot steal owned loot")
	seq+=1
	check(z.command(2,{"seq":seq,"op":"move","x":-13.0,"z":-25.0}),"route to loot")
	for i in 60:z.step(0.05)
	check(int(z.players[2].gold)==50 and z.drops.is_empty(),"one collection credits wallet")
	for i in 10:z.step(0.05)
	check(int(z.players[2].gold)==50,"no duplicate reward")
	seq+=1
	check(z.command(2,{"seq":seq,"op":"buy","item":0}),"valid purchase")
	check(int(z.players[2].gold)==35 and int(z.players[2].ammo[0])==145,"atomic balance and ammo")
	var snapshot := z.snapshot()
	check(not snapshot.players[0].has("path"),"private routing not serialized")
	check(snapshot.players.size()==2,"both players in common zone")
	print(JSON.stringify({"test":"zone_simulation","status":"PASS" if failed.is_empty() else "FAIL","failed":failed}))
	quit(0 if failed.is_empty() else 1)

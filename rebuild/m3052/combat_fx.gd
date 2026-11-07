extends RefCounted
const IMPACT_FX=preload("res://impact_fx.gd")
const SPRITE_FX=preload("res://sprite_fx.gd")
## M3100 — original, texture-free sea combat VFX for actual airborne munitions.
## Drawn in chart world coordinates, independent of the 2.5D/3D GLB renderer.
## Pure visual functions: never mutate HP, cooldowns, ammunition or target state.
const WEAPONS := ["cannon","chain","harpoon","flare","pumpkin","snow","ice","fire","poison","shrapnel","lightning","holy","shadow","wind","earth","water","cursed","bleed","necro","gold","crystal","explosive","arcane","spectral","lava","light","armor_piercing","gas","mortar"]
# M3102: one real hit can render a burst of several cosmetic orbs.
const VISIBLE_COUNTS := [1,3,5,8]
const RADIANT_COLORS := [Color("ff344f"),Color("2db5ff"),Color("56ef7c"),Color("ffdb54"),Color("bf58ff")]

static func visual_count(requested: int) -> int:
	return requested if requested in VISIBLE_COUNTS else 3

static func radiant_color(shot_id: int,orb: int=0) -> Color:
	return RADIANT_COLORS[posmod(shot_id+orb,RADIANT_COLORS.size())]

static func orb_offset(shot: Dictionary,index: int,count: int,clock: float) -> Vector2:
	var total: int=visual_count(count)
	if total==1:return Vector2.ZERO
	# M3104: distinct marbles in a compact, staggered pile, not a row.
	# Leave a visible air gap between the solid projectile silhouettes even
	# while travelling at normal game zoom. The entire pile stays coherent.
	var pile: Array[Vector2]=[]
	match total:
		3:
			# One up front and two behind, with space to read each sphere.
			pile=[Vector2(0,-10.0),Vector2(-8.7,5.2),Vector2(8.7,5.2)]
		5:
			pile=[Vector2(0,-16.0),Vector2(-9.0,-1.0),Vector2(9.0,-1.0),
				Vector2(-9.0,14.0),Vector2(9.0,14.0)]
		8:
			pile=[Vector2(-9.0,-17.0),Vector2(9.0,-17.0),
				Vector2(-18.0,-1.0),Vector2(0,-1.0),Vector2(18.0,-1.0),
				Vector2(-18.0,15.0),Vector2(0,15.0),Vector2(18.0,15.0)]
	if index<0 or index>=pile.size():return Vector2.ZERO
	var direction: Vector2=Vector2(shot.get("pos",Vector2.ZERO))-Vector2(shot.get("start",Vector2.ZERO))
	if direction.length_squared()<.1:direction=Vector2(shot.get("visual_heading",Vector2.RIGHT))
	if direction.length_squared()<.001:direction=Vector2.RIGHT
	direction=direction.normalized()
	var side:=Vector2(-direction.y,direction.x)
	var place: Vector2=pile[index]
	var shimmer: float=sin(clock*3.1+float(index)*2.3+float(int(shot.get("id",0))%13))*.35
	return side*(place.x+shimmer)+direction*(place.y+shimmer*.45)

static func _projectile_speed(weapon: String) -> float:
	return 530.0 if weapon=="harpoon" else (380.0 if weapon=="mortar" else 470.0)

static func weapon_color(weapon: String, hostile: bool=false) -> Color:
	match weapon:
		"cannon":return Color("ff9a52") if hostile else Color("e2be83")
		"chain":return Color("c7ddde")
		"harpoon":return Color("8cd7ba")
		"flare":return Color("ffcd58")
		"pumpkin":return Color("ff8538")
		"snow":return Color("ebfaff")
		"ice":return Color("62dfff")
		"mortar":return Color("f0ad79")
		"fire":return Color("ff6a29")
		"poison":return Color("75ff36")
		"shrapnel":return Color("c7d1d6")
		"lightning":return Color("3fb7ff")
		"holy":return Color("ffe9a8")
		"shadow":return Color("a05ce9")
		"wind":return Color("dcf7ff")
		"earth":return Color("c49b6b")
		"water":return Color("69daff")
		"cursed":return Color("d877fc")
		"bleed":return Color("ff485b")
		"necro":return Color("85f89e")
		"gold":return Color("ffe171")
		"crystal":return Color("b775ff")
		"explosive":return Color("ff9a49")
		"arcane":return Color("d29bff")
		"spectral":return Color("62f1df")
		"lava":return Color("ff641e")
		"light":return Color("fff2b8")
		"armor_piercing":return Color("cbd7df")
		"gas":return Color("b2ee62")
	return Color("e2be83")

static func lift(weapon: String,progress: float) -> float:
	# A simple screen-projected parabola: shells are elevated during travel but
	# always return to the recipient's waterline on impact.
	var arc: float=110.0 if weapon=="mortar" else (44.0 if weapon in ["flare","pumpkin"] else (20.0 if weapon=="harpoon" else 31.0))
	return sin(clampf(progress,0.0,1.0)*PI)*arc

static func projectile_center(shot: Dictionary) -> Vector2:
	var progress: float=clampf(float(shot.get("traveled",0.0))/maxf(1.0,float(shot.get("distance",1.0))),0.0,1.0)
	var center: Vector2=Vector2(shot.get("pos",Vector2.ZERO))-Vector2(0.0,lift(str(shot.get("weapon","cannon")),progress))
	# Real salvos contain staggered physical shots. Re-align ONLY their
	# appearance so the group stays together as one ammunition pile.
	if int(shot.get("salvo_count",1))>1:
		var heading: Vector2=Vector2(shot.get("visual_heading",Vector2.RIGHT))
		if heading.length_squared()>.001:heading=heading.normalized()
		else:heading=Vector2.RIGHT
		var launch_offset: Vector2=Vector2(shot.get("start",Vector2.ZERO))-Vector2(shot.get("salvo_origin",Vector2(shot.get("start",Vector2.ZERO))))
		center-=launch_offset
		center+=heading*float(shot.get("salvo_index",0))*.08*_projectile_speed(str(shot.get("weapon","cannon")))
	return center

static func _ellipse(canvas: CanvasItem,at: Vector2,radii: Vector2,ink: Color,width: float) -> void:
	var vertices:=PackedVector2Array()
	for k in 33:
		var angle: float=float(k)*TAU/32.0
		vertices.append(at+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
	canvas.draw_polyline(vertices,ink,width,true)

static func _star(canvas: CanvasItem,at: Vector2,radius: float,color: Color,rotation: float=0.0) -> void:
	for axis in 4:
		var angle: float=rotation+float(axis)*PI*0.25
		var direction:=Vector2(cos(angle),sin(angle))
		var extent: float=radius if axis%2==0 else radius*0.55
		canvas.draw_line(at-direction*extent,at+direction*extent,color,1.15,true)

static func draw_projectile(canvas: CanvasItem,shot: Dictionary,clock: float,visible_orbs: int=3) -> void:
	if float(shot.get("age",-1.0))<0.0:return
	var n: int=visual_count(visible_orbs)
	for orb in n:
		_draw_one_projectile(canvas,shot,clock,orb_offset(shot,orb,n,clock),orb)

static func _draw_one_projectile(canvas: CanvasItem,shot: Dictionary,clock: float,offset: Vector2,orb: int) -> void:
	var weapon: String=str(shot.get("weapon","cannon"))
	var pos: Vector2=projectile_center(shot)+offset
	var direction: Vector2=Vector2(shot.get("pos",Vector2.ZERO))-Vector2(shot.get("start",Vector2.ZERO))
	if direction.length_squared()<1.0:direction=Vector2(shot.get("visual_heading",Vector2.RIGHT))
	if direction.length_squared()<0.001:direction=Vector2.RIGHT
	direction=direction.normalized()
	var side:=Vector2(-direction.y,direction.x)
	var seed: float=float((int(shot.get("id",0))+orb*13)%91)
	var phase: float=clock*12.0+seed
	var hostile: bool=int(shot.get("source",0))!=0
	var ink: Color=radiant_color(int(shot.get("id",0)),orb) if weapon=="flare" else weapon_color(weapon,hostile)
	# Layer changing transparent artwork beneath the detailed projectile model.
	SPRITE_FX.draw_flight(canvas,pos,direction,weapon,clock,int(shot.get("id",0))+orb*17)
	match weapon:
		"chain":
			var spin: float=clock*17.0+seed
			var axle: Vector2=Vector2(cos(spin),sin(spin))*5.0
			canvas.draw_line(pos-axle,pos+axle,Color("141c22"),3.7,true)
			canvas.draw_line(pos-axle,pos+axle,Color("d0d3c1"),1.0,true)
			for ball in [pos-axle,pos+axle]:
				canvas.draw_circle(ball,3.8,Color("09151c"))
				canvas.draw_circle(ball,2.9,Color("7f9aa2"))
				canvas.draw_circle(ball+Vector2(-.8,-1.0),.95,Color("f5e8c9"))
		"harpoon":
			var nose: Vector2=pos+direction*9.0
			var back: Vector2=pos-direction*11.0
			canvas.draw_line(back,nose,Color("172d36"),4.0,true)
			canvas.draw_line(back,nose,Color("b8cbb8"),1.9,true)
			var tip:=PackedVector2Array([nose+direction*5.0,nose-direction*4.0+side*3.1,nose-direction*4.0-side*3.1])
			canvas.draw_colored_polygon(tip,Color("e0f4dd"))
			canvas.draw_line(back+side*4.5,back-side*4.5,Color("8bcdac"),1.7,true)
		"flare":
			# Leuchtkugeln: five jeweled colours, each with a metallic equator,
			# moving facets, white specular centre and a matching light trail.
			var pulse: float=0.5+0.5*sin(phase*1.5)
			canvas.draw_circle(pos,11.4+pulse*2.0,Color(ink,.13))
			canvas.draw_circle(pos,7.7,Color(ink,.26))
			canvas.draw_circle(pos,5.3,Color("12121a",.96))
			canvas.draw_circle(pos,4.65,ink.darkened(.32))
			canvas.draw_circle(pos+Vector2(-.9,-1.1),3.1,ink.lightened(.20))
			canvas.draw_colored_polygon(PackedVector2Array([pos+Vector2(-2.9,-2.2),pos+Vector2(.1,-4.2),pos+Vector2(3.3,-.5),pos+Vector2(-.9,.1)]),Color(ink.lightened(.67),.66))
			canvas.draw_arc(pos,4.75,.18,PI-.18,12,Color("eac77c",.83),1.35,true)
			canvas.draw_circle(pos+Vector2(-1.8,-2.4),1.3,Color("ffffff",.82))
			_star(canvas,pos,7.8+pulse*1.4,Color(ink.lightened(.75),.56),phase*.08)
		"pumpkin":
			canvas.draw_circle(pos,8.0,Color("ff7139",.14))
			canvas.draw_circle(pos,5.0,Color("b84a1b"))
			canvas.draw_circle(pos+Vector2(-1.0,-1.2),3.7,Color("ffab49"))
			canvas.draw_circle(pos+Vector2(1.8,.5),1.2,Color("fff3ae"))
			for spark in 3:
				var angle: float=phase*.28+float(spark)*TAU/3.0
				canvas.draw_circle(pos+Vector2(cos(angle),sin(angle))*7.5,1.0,Color("ffbf62",.72))
		"snow":
			canvas.draw_circle(pos,7.2,Color("d2f4ff",.16))
			canvas.draw_circle(pos,4.3,Color("f0ffff"))
			canvas.draw_circle(pos-Vector2(.8,.8),1.65,Color("85c9ed"))
			for spoke in 3:
				var angle: float=clock*2.0+float(spoke)*PI/3.0
				var axis:=Vector2(cos(angle),sin(angle))
				canvas.draw_line(pos-axis*6.1,pos+axis*6.1,Color("d9ffff",.82),1.0,true)
		"ice":
			canvas.draw_circle(pos,8.2,Color("48c9ff",.16))
			var crystal:=PackedVector2Array([pos+direction*8.5,pos+side*4.1,pos-direction*6.4,pos-side*4.1])
			canvas.draw_colored_polygon(crystal,Color("4ebbd9"))
			canvas.draw_line(pos-direction*5.0,pos+direction*6.0,Color("e4ffff"),1.55,true)
			canvas.draw_line(pos+side*3.0,pos+direction*5.0,Color("b6efff"),.9,true)
		"fire","poison","shrapnel","lightning","holy","shadow","wind","earth","water","cursed","bleed","necro","gold","crystal","explosive","arcane","spectral","lava","light","armor_piercing","gas":
			_draw_special_projectile(canvas,pos,direction,weapon,ink,phase)
		"mortar":
			_ellipse(canvas,Vector2(shot.get("pos",pos)),Vector2(8.0,3.3),Color(0,0,0,.26),1.1)
			canvas.draw_circle(pos,7.6,Color("19222c"))
			canvas.draw_circle(pos,5.9,Color("4c4b46"))
			canvas.draw_circle(pos+Vector2(-1.8,-2.4),2.3,Color("ffd4a2"))
		_:
			canvas.draw_circle(pos,5.0,Color("0a1620",.78))
			canvas.draw_circle(pos,3.9,Color("3d4446") if not hostile else Color("804439"))
			canvas.draw_circle(pos-Vector2(1.1,1.4),1.4,Color(ink))
	# A faint shadow follows the visible arc, not the hit logic.
	if weapon in ["flare","pumpkin","snow","ice"]:
		canvas.draw_circle(pos-direction*5.0,2.3,Color(ink,.14))

static func _draw_special_projectile(canvas: CanvasItem,p: Vector2,dir: Vector2,weapon: String,ink: Color,phase: float) -> void:
	# M3105: readable metallic/elemental spheres, distinguishable at game zoom.
	var side:=Vector2(-dir.y,dir.x)
	var energy: bool=weapon not in ["earth","shrapnel","armor_piercing"]
	if energy:
		canvas.draw_circle(p,11.5,Color(ink,.16))
		canvas.draw_circle(p,8.8,Color(ink,.15))
	canvas.draw_circle(p,6.7,Color("091821"))
	canvas.draw_circle(p,5.9,Color(ink.darkened(.62)))
	canvas.draw_circle(p+Vector2(-1.3,-1.4),4.5,Color(ink,.85))
	canvas.draw_circle(p-Vector2(1.8,2.6),1.55,Color("ffffff",.75))
	match weapon:
		"shrapnel","armor_piercing":
			for i in 5:
				var a: float=phase*.12+float(i)*TAU/5.0
				var axis:=Vector2(cos(a),sin(a))
				var tip: Vector2=p+axis*(10.0 if weapon=="shrapnel" else 12.0)
				canvas.draw_colored_polygon(PackedVector2Array([tip,p+axis*3.0+Vector2(-axis.y,axis.x)*2.5,p+axis*3.0-Vector2(-axis.y,axis.x)*2.5]),Color("dce0db"))
			if weapon=="armor_piercing":
				canvas.draw_line(p-dir*4,p+dir*14,Color("eff5ee"),3.0,true)
				canvas.draw_line(p+dir*14,p+dir*18,Color("ffffff"),1.0,true)
		"crystal","cursed","arcane":
			var diamond:=PackedVector2Array([p-dir*6.0,p-side*4.5,p+dir*7.5,p+side*4.5])
			canvas.draw_colored_polygon(diamond,Color(ink.lightened(.45),.83))
			canvas.draw_line(p-dir*5.0,p+dir*5.0,Color("ffffff",.75),1.1,true)
			if weapon in ["cursed","arcane"]:
				canvas.draw_arc(p,9.1,phase*.25,phase*.25+PI*1.35,17,Color(ink,.64),1.4,true)
		"wind","water","shadow":
			for swirl in 2:
				var a: float=phase*.28+float(swirl)*PI
				canvas.draw_arc(p,7.6,a,a+PI*.8,15,Color(ink.lightened(.5),.9),1.8,true)
		"fire","lava","explosive":
			var flame: Vector2=p-dir*(9.0+3.0*sin(phase))
			canvas.draw_line(p,flame,Color("ff9d3c",.91),3.8,true)
			canvas.draw_circle(flame,2.8,Color("ffe8a4",.87))
		"poison","gas":
			for bubble in 3:
				var a: float=phase*.35+float(bubble)*TAU/3.0
				canvas.draw_circle(p+Vector2(cos(a),sin(a))*8.0,2.0,Color(ink,.66))
		"lightning":
			canvas.draw_line(p+side*8.0,p-dir*2.0,Color("faffff"),1.3,true)
			canvas.draw_line(p-dir*2.0,p-side*7.5,Color(ink.lightened(.65)),1.7,true)
		"holy","light","gold":
			_star(canvas,p,10.0,Color("fff5db",.75),phase*.12)
			if weapon=="gold":canvas.draw_arc(p,5.5,0,TAU,15,Color("ffe9ab"),1.8,true)
		"necro","spectral":
			canvas.draw_circle(p-dir*1.4-side*1.9,1.35,Color("0d2434"))
			canvas.draw_circle(p-dir*1.4+side*1.9,1.35,Color("0d2434"))
			canvas.draw_line(p-dir*1.5,p+dir*3.3,Color("caffee"),.85,true)
		"bleed":
			canvas.draw_line(p-dir*4.0,p+dir*4.0,Color("ffdee0"),1.3,true)
			canvas.draw_circle(p+side*3.6,1.9,Color("ffcebd"))
		"earth":
			for stone in 4:
				var a: float=float(stone)*TAU/4.0+phase*.04
				var v:=Vector2(cos(a),sin(a))
				canvas.draw_line(p,p+v*4.6,Color("ecdbad",.81),1.3,true)
		_:
			pass

static func draw_muzzle(canvas: CanvasItem,event: Dictionary,age: float,clock: float) -> void:
	if age<0.0 or age>=0.42:return
	var fade: float=1.0-age/.42
	var origin: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var weapon: String=str(event.get("weapon","cannon"))
	var direction: Vector2=Vector2(event.get("heading",Vector2.RIGHT))
	if direction.length_squared()<.01:direction=Vector2.RIGHT
	direction=direction.normalized()
	var side:=Vector2(-direction.y,direction.x)
	var burst: Vector2=origin+direction*23.0
	var ink: Color=weapon_color(weapon,int(event.get("actor",0))!=0)
	var amount: int=mini(3,maxi(1,int(event.get("value",1))))
	for i in amount:
		var at: Vector2=burst+side*(float(i)-float(amount-1)*.5)*13.0
		var radius: float=(6.0+age*33.0)
		canvas.draw_circle(at+direction*5.0,radius,Color("a2abb1",.11*fade))
		canvas.draw_circle(at,4.0+age*15.0,Color("eee3c4",.13*fade))
		_star(canvas,at,7.0*fade+1.0,Color(ink,.60*fade),clock*.1)
		canvas.draw_line(at,at+direction*(14.0+age*17.0),Color("ffe6b6",.55*fade),1.8,true)

static func draw_impact(canvas: CanvasItem,event: Dictionary,age: float,clock: float) -> void:
	if age<0.0 or age>=1.8:return
	var weapon: String=str(event.get("weapon","cannon"))
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var seed: float=float(int(event.get("vfx_seed",event.get("actor",0)))%23)
	var impact_color: Color=weapon_color(weapon)
	var fade: float=pow(maxf(0.0,1.0-age/1.05),1.25)
	var spread: float=1.0+age*3.2
	# Water ring is always low-opacity so enemies, HP bars and target circles
	# remain visible while multiple broadsides hit the same actor.
	_ellipse(canvas,p+Vector2(0,2.0),Vector2(7.5+age*42.0,3.3+age*15.0),Color("a5eaf0",.26*fade),1.65)
	_ellipse(canvas,p,Vector2(5.5+age*27.0,2.0+age*10.0),Color(impact_color,.52*fade),1.6)
	if age<.22:
		var hot: float=1.0-age/.22
		canvas.draw_circle(p,10.0+age*30.0,Color(impact_color,.18*hot))
		canvas.draw_circle(p,5.0+age*18.0,Color("fff5cf",.38*hot))
	var particles: int=8 if weapon in ["pumpkin","ice","snow"] else 6
	for j in particles:
		var a: float=float(j)*TAU/float(particles)+seed*.16
		var axis:=Vector2(cos(a),sin(a))
		var trail: Vector2=p+Vector2(axis.x*spread*8.0,axis.y*spread*4.4)-Vector2(0.0,sin(clampf(age,0.0,1.0)*PI)*8.0)
		var sparkle: Color=impact_color
		if weapon=="snow":sparkle=Color("f4ffff")
		elif weapon=="chain":sparkle=Color("dbe6ea")
		elif weapon=="harpoon":sparkle=Color("7fd9ae")
		canvas.draw_line(trail-axis*(3.8*fade),trail+axis*(2.5*fade),Color(sparkle,.65*fade),1.3,true)
		if j%2==0:canvas.draw_circle(trail,1.2+fade,Color(sparkle,.48*fade))
	match weapon:
		"flare":
			# A five-colour flash echoes the jewel ammunition without changing
			# the existing target-mark bonus or its duration.
			for n in 5:
				var angle: float=float(n)*TAU/5.0+age*2.0
				var center: Vector2=p+Vector2(cos(angle)*(.8+age*29.0),sin(angle)*(.4+age*14.0))
				_star(canvas,center,4.8+fade*4.0,Color(radiant_color(int(event.get("vfx_seed",0)),n),.64*fade),clock*.15)
		"pumpkin":
			for fragment in 5:
				var a: float=float(fragment)*TAU/5.0+seed
				var offset:=Vector2(cos(a),sin(a)*.55)*(9.0+age*61.0)
				canvas.draw_circle(p+offset-Vector2(0,age*15.0),2.6*fade,Color("ff8d36",.87*fade))
		"snow":
			_flake_burst(canvas,p,age,fade,false)
		"ice":
			_flake_burst(canvas,p,age,fade,true)
		"chain":
			_ellipse(canvas,p,Vector2(7+age*24,4+age*12),Color("b2c9d1",.48*fade),1.4)
		"harpoon":
			for bolt in 3:
				var a: float=float(bolt)*TAU/3.0
				var tip:=p+Vector2(cos(a),sin(a))*(4.0+age*18.0)
				canvas.draw_line(p,tip,Color("a9dac7",.35*fade),.95,true)
		"mortar":
			canvas.draw_circle(p,18.0+age*25.0,Color("d0a07e",.13*fade))
			_ellipse(canvas,p,Vector2(15+age*42,7+age*22),Color("e5bc8e",.45*fade),2.0)
		_:
			pass
	IMPACT_FX.draw(canvas,event,age,clock,weapon_color(weapon))

static func _flake_burst(canvas: CanvasItem,p: Vector2,age: float,fade: float,hard: bool) -> void:
	var tint: Color=Color("66dcff") if hard else Color("edffff")
	var spokes: int=6 if hard else 5
	for j in spokes:
		var theta: float=float(j)*TAU/float(spokes)+(age*.9 if hard else age*.4)
		var center: Vector2=p+Vector2(cos(theta),sin(theta))*((12.0 if hard else 9.0)+age*35.0)
		if hard:
			var v:=Vector2(cos(theta),sin(theta))
			var n:=Vector2(-v.y,v.x)
			var diamond:=PackedVector2Array([center+v*6.0*fade,center+n*2.1*fade,center-v*3.5*fade,center-n*2.1*fade])
			canvas.draw_colored_polygon(diamond,Color(tint,.56*fade))
		else:
			_star(canvas,center,3.0+fade*2.0,Color(tint,.72*fade),theta)

static func active_statuses(actor: Dictionary,now: float) -> Array[String]:
	var statuses: Array[String]=[]
	if float(actor.get("spotted",0.0))>now:statuses.append("flare")
	if bool(actor.get("frozen",false)) or float(actor.get("ice",0.0))>0.0:
		statuses.append("ice")
	elif float(actor.get("slow",0.0))>0.0:
		statuses.append("snow" if float(actor.get("slow_rate",1.0))<0.45 else "chain")
	return statuses

static func draw_status(canvas: CanvasItem,actor: Dictionary,at: Vector2,now: float,hull_length: float) -> void:
	# These are peripheral, translucent world-space cues, so they cannot cover
	# hull texture, enemy HP, selected target, the player's decks or combat HUD.
	var states: Array[String]=active_statuses(actor,now)
	if states.is_empty():return
	var phase: float=now*2.4+float(int(actor.get("id",0))%11)
	var half_width: float=hull_length*.39
	for state in states:
		match state:
			"flare":
				var bright: float=.5+.5*sin(phase*2.2)
				for spot in 5:
					var a: float=phase*.4+float(spot)*TAU/5.0
					var glimmer:=at+Vector2(cos(a)*half_width*.86,sin(a)*half_width*.32)
					var hue: Color=radiant_color(int(actor.get("id",0)),spot)
					_star(canvas,glimmer,3.8+1.5*bright,Color(hue,.48+.24*bright),phase*.3)
			"ice":
				var frost: float=clampf(float(actor.get("ice",1.0))/3.2,.35,1.0)
				_ellipse(canvas,at,Vector2(half_width*.95,half_width*.37),Color("9de8ff",.37*frost),1.55)
				for shard in 7:
					var a: float=float(shard)*TAU/7.0+phase*.12
					var pos:=at+Vector2(cos(a)*half_width*.86,sin(a)*half_width*.31)
					var v:=Vector2(cos(a),sin(a))
					var cross:=Vector2(-v.y,v.x)
					canvas.draw_colored_polygon(PackedVector2Array([pos+v*(4.0+frost*2.0),pos+cross*1.9,pos-v*2.9,pos-cross*1.9]),Color("b4f5ff",.58*frost))
			"snow":
				_ellipse(canvas,at,Vector2(half_width*.89,half_width*.34),Color("d5f5ff",.23),1.2)
				for flake in 5:
					var a: float=float(flake)*TAU/5.0+phase*.24
					var pos:=at+Vector2(cos(a)*half_width*.83,sin(a)*half_width*.34)-Vector2(0,4.0+3.0*sin(phase+float(flake)))
					_star(canvas,pos,3.0,Color("f0ffff",.53),a)
			"chain":
				_ellipse(canvas,at,Vector2(half_width*.83,half_width*.32),Color("b3cfda",.22),1.2)
				for coil in 4:
					var a: float=phase*.24+float(coil)*TAU/4.0
					var pos:=at+Vector2(cos(a)*half_width*.8,sin(a)*half_width*.3)
					canvas.draw_arc(pos,3.0,a,a+PI*1.5,10,Color("c9e4e6",.39),1.0,true)

static func draw_sinking(canvas: CanvasItem,event: Dictionary,age: float) -> void:
	if age<0.0 or age>=1.2:return
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var fade: float=1.0-age/1.2
	_ellipse(canvas,p,Vector2(6+age*66.0,4+age*26.0),Color("b9e5e5",.5*fade),2.3)
	canvas.draw_circle(p-Vector2(0,age*14.0),18+age*33.0,Color("4e5e66",.15*fade))
	for bubble in 7:
		var a: float=float(bubble)*TAU/7.0
		var offset:=Vector2(cos(a)*(10+age*56),sin(a)*(6+age*22))
		canvas.draw_circle(p+offset-Vector2(0,age*9),1.5+fade*2.8,Color("e2faff",.46*fade))

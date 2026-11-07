extends RefCounted
## M3100 — original, texture-free sea combat VFX for actual airborne munitions.
## Drawn in chart world coordinates, independent of the 2.5D/3D GLB renderer.
## Pure visual functions: never mutate HP, cooldowns, ammunition or target state.
const WEAPONS := ["cannon","chain","harpoon","flare","pumpkin","snow","ice","mortar"]

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
	return Color("e2be83")

static func lift(weapon: String,progress: float) -> float:
	# A simple screen-projected parabola: shells are elevated during travel but
	# always return to the recipient's waterline on impact.
	var arc: float=110.0 if weapon=="mortar" else (44.0 if weapon in ["flare","pumpkin"] else (20.0 if weapon=="harpoon" else 31.0))
	return sin(clampf(progress,0.0,1.0)*PI)*arc

static func projectile_center(shot: Dictionary) -> Vector2:
	var progress: float=clampf(float(shot.get("traveled",0.0))/maxf(1.0,float(shot.get("distance",1.0))),0.0,1.0)
	return Vector2(shot.get("pos",Vector2.ZERO))-Vector2(0.0,lift(str(shot.get("weapon","cannon")),progress))

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

static func draw_projectile(canvas: CanvasItem,shot: Dictionary,clock: float) -> void:
	if float(shot.get("age",-1.0))<0.0:return
	var weapon: String=str(shot.get("weapon","cannon"))
	var pos: Vector2=projectile_center(shot)
	var direction: Vector2=Vector2(shot.get("pos",Vector2.ZERO))-Vector2(shot.get("start",Vector2.ZERO))
	if direction.length_squared()<1.0:direction=Vector2(shot.get("visual_heading",Vector2.RIGHT))
	if direction.length_squared()<0.001:direction=Vector2.RIGHT
	direction=direction.normalized()
	var side:=Vector2(-direction.y,direction.x)
	var seed: float=float(int(shot.get("id",0))%91)
	var phase: float=clock*12.0+seed
	var hostile: bool=int(shot.get("source",0))!=0
	var ink: Color=weapon_color(weapon,hostile)
	var speed_scale: float=1.0 if weapon=="harpoon" else 0.82
	# Four to six translucent trail particles read as moving smoke or embers.
	# They are deterministic per shot, bounded, and require no particle textures.
	var trail_count: int=4 if weapon=="harpoon" else 6
	for t in trail_count:
		var step: float=float(t)+1.0
		var behind: Vector2=pos-direction*(step*6.2*speed_scale)
		behind+=side*sin(phase*.65+step*1.43)*(1.4+step*.24)
		var falloff: float=1.0-step/float(trail_count+1)
		var tail: Color=ink if weapon in ["flare","pumpkin","ice","snow"] else Color("9ba9aa")
		if weapon=="harpoon":tail=Color("a9bdad")
		if weapon=="chain":tail=Color("7d9a9b")
		canvas.draw_circle(behind,1.25+step*.37,Color(tail,.09+.23*falloff))
		if t%2==0 and weapon in ["flare","pumpkin","ice","snow"]:
			canvas.draw_circle(behind+side*(2.0+sin(phase+step)*1.5),.75+falloff,Color(ink,.34*falloff))
	var shoulder: Vector2=pos-direction*11.0
	canvas.draw_line(shoulder,pos,Color(ink,.46),2.2,true)
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
			var pulse: float=0.5+0.5*sin(phase*1.5)
			canvas.draw_circle(pos,10.5+pulse*2.0,Color("ff9836",.12))
			canvas.draw_circle(pos,7.3,Color("ffca48",.22))
			canvas.draw_circle(pos,4.2,Color("ff8a35"))
			canvas.draw_circle(pos,2.2,Color("fff5b5"))
			_star(canvas,pos,8.0+pulse*2.2,Color("fff2ae",.64),phase*.08)
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
	if age<0.0 or age>=1.05:return
	var weapon: String=str(event.get("weapon","cannon"))
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var seed: float=float(int(event.get("actor",0))%17)
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
			if age<.55:_star(canvas,p-Vector2(0,9.0+age*16.0),13.0+age*19.0,Color("fff2a4",fade*.73),clock*.15)
		"pumpkin":
			for fragment in 5:
				var a: float=float(fragment)*TAU/5.0+seed
				var offset:=Vector2(cos(a),sin(a)*.55)*(9.0+age*61.0)
				canvas.draw_circle(p+offset-Vector2(0,age*15.0),2.6*fade,Color("ff8d36",.87*fade))
		"snow":
			forflake(canvas,p,age,fade,false)
		"ice":
			forflake(canvas,p,age,fade,true)
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

static func forflake(canvas: CanvasItem,p: Vector2,age: float,fade: float,hard: bool) -> void:
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

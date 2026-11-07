extends RefCounted
## M3105: independent, lightweight impact animation pass for all sea ammunition.
## Draw after the actual hulls, before HUD/plates. No gameplay mutations.

static func ellipse(c: CanvasItem,p: Vector2,r: Vector2,ink: Color,width: float=1.7) -> void:
	var pts:=PackedVector2Array()
	for i in 37:
		var angle:=float(i)*TAU/36.0
		pts.append(p+Vector2(cos(angle)*r.x,sin(angle)*r.y))
	c.draw_polyline(pts,ink,width,true)

static func flash(c: CanvasItem,p: Vector2,r: float,ink: Color,opacity: float=1.0) -> void:
	for i in 6:
		var angle:=float(i)*TAU/6.0
		var axis:=Vector2(cos(angle),sin(angle))
		c.draw_line(p-axis*r*.48,p+axis*r,Color(ink,.64*opacity),2.0,true)
	c.draw_circle(p,4.0+opacity*3.0,Color("fff8e5",.56*opacity))

static func shard(c: CanvasItem,p: Vector2,axis: Vector2,length: float,ink: Color) -> void:
	var side:=Vector2(-axis.y,axis.x)
	c.draw_colored_polygon(PackedVector2Array([p+axis*length,p+side*length*.23,p-axis*length*.42,p-side*length*.23]),ink)

static func draw(c: CanvasItem,event: Dictionary,age: float,clock: float,ink: Color) -> void:
	if age<0.0 or age>=1.8:return
	var weapon: String=str(event.get("weapon","cannon"))
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var seed: float=float(int(event.get("vfx_seed",event.get("actor",0)))%29)
	var fade: float=pow(maxf(0.0,1.0-age/1.8),1.28)
	var burst: float=1.0-clampf(age/.28,0.0,1.0)
	var wave: float=sin(clampf(age/.92,0.0,1.0)*PI)
	# Every hit: a brilliant initial impact, widening bright white foam, and
	# high water jets that are actually legible at normal mobile game zoom.
	if age<.31:
		c.draw_circle(p,14.0+age*52.0,Color(ink,.27*burst))
		c.draw_circle(p,9.0+age*34.0,Color("fffaf0",.40*burst))
		flash(c,p-Vector2(0,6),19.0+age*36.0,Color("fff7e7"),burst)
	ellipse(c,p+Vector2(0,3),Vector2(15.0+age*67.0,6.0+age*26.0),Color("c6f3ff",.51*fade),2.25)
	ellipse(c,p+Vector2(0,1),Vector2(7.0+age*46.0,2.5+age*18.0),Color(ink,.52*fade),1.8)
	if age<1.12:
		for n in 9:
			var lane: float=float(n-4)/4.0
			var tip: Vector2=p+Vector2(lane*(12.0+age*54.0),-(20.0+age*74.0)*wave*(1.0-absf(lane)*.43)+age*11.0)
			c.draw_line(p+Vector2(lane*5.0,0),tip,Color("b8f4ff",.39*fade),1.4,true)
			c.draw_circle(tip,1.5+fade*2.4,Color("f2ffff",.65*fade))
	# Material-specific signature. No extra hit detection and no status effects.
	match weapon:
		"fire","lava","explosive","pumpkin":
			for i in 12:
				var a: float=float(i)*TAU/12.0+seed*.08
				var axis:=Vector2(cos(a),sin(a))
				var at: Vector2=p+Vector2(axis.x*(8.0+age*76.0),axis.y*(6.0+age*43.0)-age*29.0)
				var bright: Color=Color("ffdf89") if i%2==0 else Color("ff7131")
				c.draw_line(at-axis*(5.0*fade),at+axis*(11.0*fade),Color(bright,.79*fade),2.1,true)
				c.draw_circle(at,1.8+2.4*fade,Color(bright,.80*fade))
			for puff in 5:
				var a: float=float(puff)*TAU/5.0+seed
				var at:=p+Vector2(cos(a)*age*23.0,-age*35.0+sin(a)*12.0)
				c.draw_circle(at,7.0+age*23.0,Color("3c3b3d",.17*fade))
		"ice","snow","crystal":
			for i in 12:
				var a: float=float(i)*TAU/12.0+seed*.05
				var v:=Vector2(cos(a),sin(a))
				var at:=p+Vector2(v.x*(7.0+age*67.0),v.y*(5.0+age*29.0)-age*28.0)
				var frost: Color=Color("e6ffff") if weapon=="snow" else (Color("d6aaff") if weapon=="crystal" else Color("78ddff"))
				shard(c,at,v,8.0+18.0*fade,Color(frost,.77*fade))
			ellipse(c,p,Vector2(20+age*51,7+age*18),Color(ink,.56*fade),2.0)
		"poison","gas":
			for i in 10:
				var a: float=float(i)*TAU/10.0+seed*.1
				var at:=p+Vector2(cos(a)*(9.0+age*36.0),-age*48.0+sin(a)*(8.0+age*17.0))
				c.draw_circle(at,9.0+age*17.0,Color(ink,.17*fade))
				c.draw_circle(at+Vector2(2.0,-6.0),1.6+fade*3.0,Color("ceff7b",.52*fade))
		"lightning":
			for i in 8:
				var a: float=float(i)*TAU/8.0+seed*.04
				var v:=Vector2(cos(a),sin(a))
				var cross:=Vector2(-v.y,v.x)
				var mid:=p+v*(13.0+age*24.0)+cross*sin(clock*19.0+float(i))*8.0
				var tip:=p+v*(34.0+age*57.0)
				c.draw_line(p,mid,Color("d4ffff",.78*fade),2.0,true)
				c.draw_line(mid,tip,Color(ink,.88*fade),1.8,true)
				c.draw_circle(tip,2.0,Color("ffffff",.83*fade))
		"wind","water":
			for i in 5:
				var radius: float=10.0+age*34.0+float(i)*6.0
				c.draw_arc(p-Vector2(0,age*13.0),radius,clock*.6+float(i),clock*.6+float(i)+PI,24,Color(ink,.51*fade),2.0,true)
			if weapon=="water":
				for i in 10:
					var a: float=float(i)*TAU/10.0
					var at:=p+Vector2(cos(a)*(10.0+age*64.0),-age*58.0+sin(a)*age*18.0)
					c.draw_circle(at,2.1+fade*2.2,Color("f0ffff",.71*fade))
		"shadow","cursed","arcane":
			for i in 3:
				var radius: float=13.0+age*37.0+float(i)*10.0
				c.draw_arc(p-Vector2(0,age*9.0),radius,clock*.5+float(i)*1.3,clock*.5+float(i)*1.3+PI*1.3,26,Color(ink,.64*fade),2.0,true)
			for i in 7:
				var a: float=float(i)*TAU/7.0+seed*.07
				var mark:=p+Vector2(cos(a),sin(a))*(20.0+age*43.0)
				flash(c,mark,2.3+4.0*fade,Color("f6d4ff"),fade)
		"holy","light","gold","flare":
			for i in 12:
				var a: float=float(i)*TAU/12.0+seed*.09
				var v:=Vector2(cos(a),sin(a))
				var start:=p+v*(11.0+age*23.0)
				var stop:=p+v*(27.0+age*76.0)
				var hue: Color=[Color("ff4057"),Color("45bdff"),Color("7bf46f"),Color("ffe486"),Color("c978ff")][posmod(i+int(seed),5)] if weapon=="flare" else ink
				c.draw_line(start,stop,Color(hue,.69*fade),2.0,true)
				if i%3==0:flash(c,stop,5.0+6.0*fade,hue,fade)
		"shrapnel","armor_piercing","earth","cannon","chain","mortar":
			for i in 11:
				var a: float=float(i)*TAU/11.0+seed*.08
				var v:=Vector2(cos(a),sin(a))
				var at:=p+Vector2(v.x*age*72.0,v.y*age*48.0-age*11.0)
				if weapon in ["shrapnel","armor_piercing","earth"]:
					shard(c,at,v,7.0+13.0*fade,Color(ink,.79*fade))
				else:
					c.draw_circle(at,1.8+2.1*fade,Color("f0f1e5",.65*fade))
			for puff in 5:
				var a: float=float(puff)*TAU/5.0+seed
				var at:=p+Vector2(cos(a)*age*28.0,-9.0-age*32.0+sin(a)*12.0)
				c.draw_circle(at,8.0+age*19.0,Color("57616b",.14*fade))
		"necro","spectral":
			for i in 7:
				var a: float=float(i)*TAU/7.0+seed*.1
				var at:=p+Vector2(cos(a)*(10.0+age*44.0),-age*53.0+sin(a)*18.0)
				c.draw_circle(at,5.0+age*4.0,Color(ink,.38*fade))
				c.draw_circle(at+Vector2(-1.8,-1.5),1.2,Color("0b2430",fade))
				c.draw_circle(at+Vector2(1.8,-1.5),1.2,Color("0b2430",fade))
		"bleed":
			for i in 11:
				var a: float=float(i)*TAU/11.0+seed*.05
				var v:=Vector2(cos(a),sin(a))
				var at:=p+Vector2(v.x*age*72.0,v.y*age*43.0-age*20.0)
				c.draw_circle(at,2.6+fade*2.1,Color("ed445f",.76*fade))
				c.draw_line(at,at+Vector2(0,9.0*fade),Color("ac163a",.64*fade),1.7,true)
		_:
			pass

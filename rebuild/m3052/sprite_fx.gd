extends RefCounted
## M3107 — differentiated, user-controllable 8x8 sprite VFX and animated impact choreography.
## Real artwork frames replace the static CanvasItem circles and lines.
const SHEET: Texture2D=preload("res://assets/vfx/abyssal_impact_8x8.svg")
const FRAME_SIZE := 128.0
const FRAME_COUNT := 8
const IMPACT_DURATION := 1.55
const FAMILY_NAMES := ["fire","ice","lightning","poison","arcane","water","smoke","radiant"]

static func family_for_weapon(weapon: String) -> int:
	if weapon in ["fire","lava","explosive","pumpkin"]:return 0
	if weapon in ["ice","snow","crystal"]:return 1
	if weapon=="lightning":return 2
	if weapon in ["poison","gas","necro"]:return 3
	if weapon in ["shadow","cursed","arcane","spectral"]:return 4
	if weapon in ["wind","water"]:return 5
	if weapon in ["cannon","chain","harpoon","mortar","shrapnel","armor_piercing","earth"]:return 6
	return 7

static func src_rect(row: int,frame: int) -> Rect2:
	return Rect2(Vector2(float(clampi(frame,0,7))*FRAME_SIZE,float(clampi(row,0,7))*FRAME_SIZE),Vector2(FRAME_SIZE,FRAME_SIZE))

static func _draw(canvas: CanvasItem,at: Vector2,row: int,phase: float,size: Vector2,opacity: float) -> void:
	if opacity<=0.0:return
	var blend: float=clampf(phase,0.0,.9999)*float(FRAME_COUNT-1)
	var first: int=clampi(floori(blend),0,FRAME_COUNT-1)
	var second: int=mini(FRAME_COUNT-1,first+1)
	var fraction: float=blend-float(first)
	var dest:=Rect2(at-size*.5,size)
	if first==second:
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,first),Color(1,1,1,minf(1.0,opacity)))
	else:
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,first),Color(1,1,1,minf(1.0,opacity*(1.0-fraction))))
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,second),Color(1,1,1,minf(1.0,opacity*fraction)))


const UNIQUE_SIGNATURES := ["cannon","chain","harpoon","flare","pumpkin","snow","ice","fire","poison","shrapnel","lightning","holy","shadow","wind","earth","water","cursed","bleed","necro","gold","crystal","explosive","arcane","spectral","lava","light","armor_piercing","gas","mortar"]

static func signature_index(weapon: String) -> int:
	return maxi(0,UNIQUE_SIGNATURES.find(weapon))

static func _tint(weapon: String) -> Color:
	match weapon:
		"cannon":return Color("e7ccab")
		"chain":return Color("c6e6e3")
		"harpoon":return Color("91dfbf")
		"flare":return Color("ffd269")
		"pumpkin":return Color("ff9346")
		"snow":return Color("f5ffff")
		"ice":return Color("70d8ff")
		"fire":return Color("ff6b2c")
		"poison":return Color("80ed48")
		"shrapnel":return Color("bccdd5")
		"lightning":return Color("73bfff")
		"holy":return Color("ffe2a0")
		"shadow":return Color("9e64cc")
		"wind":return Color("beeef5")
		"earth":return Color("bd986e")
		"water":return Color("59d5ef")
		"cursed":return Color("c784fa")
		"bleed":return Color("eb425d")
		"necro":return Color("9cfc7b")
		"gold":return Color("f9cf56")
		"crystal":return Color("b99aff")
		"explosive":return Color("ffb25d")
		"arcane":return Color("da9efc")
		"spectral":return Color("78f9df")
		"lava":return Color("ed4f22")
		"light":return Color("fff8ca")
		"armor_piercing":return Color("e0e5ec")
		"gas":return Color("d5f48d")
		"mortar":return Color("c4a58d")
	return Color.WHITE

static func _streak(canvas: CanvasItem,at: Vector2,toward: Vector2,ink: Color,reach: float,opacity: float) -> void:
	var direction: Vector2=toward.normalized() if toward.length_squared()>.001 else Vector2.UP
	canvas.draw_line(at-direction*reach*.3,at+direction*reach,Color(ink,opacity),2.1,true)
	canvas.draw_circle(at+direction*reach,1.8,Color(ink.lightened(.35),opacity*.85))

static func draw_flight(canvas: CanvasItem,at: Vector2,direction: Vector2,weapon: String,clock: float,seed: int=0,intensity: float=1.0,particles: bool=true) -> void:
	var dir: Vector2=direction.normalized() if direction.length_squared()>.00001 else Vector2.RIGHT
	var side:=Vector2(-dir.y,dir.x)
	var signature: int=signature_index(weapon)
	var pulse: float=fposmod(clock*(3.7+float(signature%5)*.42)+float(seed)*.077,1.0)
	var strength: float=clampf(intensity,.35,1.8)
	var size_scale: float=clampf(.79+float(signature%6)*.082, .7,1.3)*sqrt(strength)
	var row: int=family_for_weapon(weapon)
	var amount: int=3 if particles else 1
	for n in amount:
		var offset: float=11.0+float(n)*15.0
		var side_offset: float=sin(clock*8.0+float(seed+n)*1.23)*float(n+1)*2.2
		var location: Vector2=at-dir*offset+side*side_offset
		var size: float=(38.0-float(n)*6.0)*size_scale
		_draw(canvas,location,row,fposmod(pulse+float(n)*.29,1.0),Vector2(size,size*.90),(.57-float(n)*.15)*strength)
	if weapon=="lightning":
		var pivot: Vector2=at-dir*19.0+side*sin(clock*24+float(seed))*7.0
		canvas.draw_line(at,pivot,Color("b5f9ff",.75),2.0,true)
		canvas.draw_line(pivot,at-dir*39.0,Color("55bbff",.52),1.5,true)
	elif weapon in ["fire","lava","explosive"]:
		canvas.draw_line(at-dir*8.0,at-dir*(24.0+sin(clock*13.0)*7.0),Color(_tint(weapon),.65),3.3,true)
	elif weapon in ["ice","crystal","snow"]:
		_streak(canvas,at-dir*10.0,side,_tint(weapon),6.0,.55)

static func draw_muzzle(canvas: CanvasItem,event: Dictionary,age: float,intensity: float=1.0,particles: bool=true,flashes: bool=true) -> void:
	if age<0.0 or age>=.52:return
	var weapon: String=str(event.get("weapon","cannon"))
	var origin: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var heading: Vector2=Vector2(event.get("heading",Vector2.RIGHT))
	if heading.length_squared()<.01:heading=Vector2.RIGHT
	heading=heading.normalized()
	var side:=Vector2(-heading.y,heading.x)
	var strength: float=clampf(intensity,.35,1.8)
	var fade: float=pow(1.0-age/.52,1.15)
	var kick: float=1.0+age*1.5
	_draw(canvas,origin+heading*(22.0+age*28.0),family_for_weapon(weapon),age/.52,Vector2(92,81)*kick*sqrt(strength),fade*strength)
	if particles:
		_draw(canvas,origin+heading*45.0,6,age/.52,Vector2(49,42)*kick,fade*.53*strength)
		for n in 6:
			var angle: float=float(n)*TAU/6.0+float(signature_index(weapon))*.2
			var axis:=heading.rotated((angle-PI)*.38)
			var location: Vector2=origin+heading*24.0+side*sin(angle)*12.0
			_streak(canvas,location,axis,_tint(weapon),(10.0+age*48.0)*fade,fade*.75)
	if flashes and age<.14:
		canvas.draw_circle(origin+heading*30.0,(12.0+age*40.0)*sqrt(strength),Color("fff3cb",(.54-age*3.0)*strength))

static func _foam(canvas: CanvasItem,p: Vector2,age: float,intensity: float) -> void:
	if age>=1.30:return
	var life: float=1.0-age/1.3
	var expansion: float=1.0+age*2.2
	var bright:=Color("c9f7ff",.48*life)
	canvas.draw_arc(p+Vector2(0,5),12.0*expansion,0.0,TAU,36,bright,2.4*intensity,true)
	canvas.draw_arc(p+Vector2(0,6),20.0*expansion,.4,TAU-.5,36,Color("f2ffff",.20*life),1.4*intensity,true)
	for n in 8:
		var angle: float=float(n)*TAU/8.0+float(n%3)*.13
		var axis:=Vector2(cos(angle),sin(angle))
		var spray: Vector2=p+Vector2(axis.x*(12.0+age*62.0),-sin(age/1.30*PI)*(22.0+float(n%3)*13.0)+axis.y*age*14.0)
		canvas.draw_circle(spray,(2.1+float(n%3))*(.45+.55*life),Color("e3ffff",life*.75))
		canvas.draw_line(p+axis*5.0,spray,Color("c8f6ff",life*.24),1.35,true)

static func _distinctive_impact(canvas: CanvasItem,p: Vector2,weapon: String,age: float,intensity: float,particles: bool) -> void:
	var id: int=signature_index(weapon)
	var life: float=pow(maxf(0.0,1.0-age/1.65),1.15)
	var ink: Color=_tint(weapon)
	var count: int=(6+id%5) if particles else 3
	var spin: float=age*(1.7+float(id%4)*.35)
	var distance: float=(12.0+age*(46.0+float(id%5)*7.0))*sqrt(intensity)
	var angular_offset: float=float(id)*.173
	for n in count:
		var angle: float=TAU*float(n)/float(count)+angular_offset+spin*(1.0 if id%2==0 else -1.0)
		var axis:=Vector2(cos(angle),sin(angle))
		var side:=Vector2(-axis.y,axis.x)
		var point: Vector2=p+Vector2(axis.x*distance,axis.y*distance*.66-age*24.0)
		match weapon:
			"chain":
				canvas.draw_arc(point,4.0+life*6.0,angle,angle+PI*1.3,10,Color(ink,life*.84),2.3,true)
			"harpoon","armor_piercing":
				var tip:=point+axis*(14.0+life*13.0)
				canvas.draw_line(point-axis*6.0,tip,Color(ink,life*.83),2.8,true)
				canvas.draw_line(tip,tip-axis*6.0+side*3.0,Color("f4ffff",life*.78),1.2,true)
			"snow":
				canvas.draw_line(point-side*5.5,point+side*5.5,Color(ink,life*.9),1.5,true)
				canvas.draw_line(point-axis*5.5,point+axis*5.5,Color(ink,life*.9),1.5,true)
			"ice","crystal":
				var shard:=PackedVector2Array([point+axis*(13.0+life*8.0),point+side*5.0,point-axis*7.0,point-side*5.0])
				canvas.draw_colored_polygon(shard,Color(ink,life*.72))
				canvas.draw_line(point-axis*5.0,point+axis*10.0,Color("f7ffff",life*.6),1.0,true)
			"lightning":
				var mid:=point+side*sin(age*29.0+float(n)*4.1)*11.0
				canvas.draw_line(p,mid,Color("c9ffff",life*.88),2.2,true)
				canvas.draw_line(mid,point+axis*15.0,Color(ink,life*.95),1.8,true)
			"fire","lava","explosive","pumpkin":
				var rise: float=(28.0+float(n%3)*11.0)*sin(minf(1.0,age/1.65)*PI)
				canvas.draw_circle(point-Vector2(0,rise),4.0+life*5.0,Color(ink,life*.69))
				_streak(canvas,point-Vector2(0,rise),Vector2.UP,ink,8.0+life*16.0,life*.87)
			"poison","gas","necro","spectral":
				var cloud: float=7.0+age*13.0+float(n%3)*3.0
				canvas.draw_circle(point-Vector2(0,age*25.0),cloud,Color(ink,life*.18))
				canvas.draw_circle(point-Vector2(0,age*30.0+cloud*.45),2.5+life*3.0,Color(ink.lightened(.4),life*.54))
			"wind","water":
				canvas.draw_arc(point,9.0+age*12.0,angle,angle+PI,14,Color(ink,life*.7),2.2,true)
				_streak(canvas,point,axis,Color("d8ffff"),life*9.0,life*.65)
			"shadow","cursed","arcane":
				var r: float=7.0+life*11.0
				canvas.draw_arc(point,r,angle+spin,angle+spin+PI*1.4,14,Color(ink,life*.71),2.2,true)
				if weapon=="cursed":
					canvas.draw_line(point-side*3.5,point+side*3.5,Color("f7d5ff",life*.8),1.4,true)
			"holy","light","gold","flare":
				var ray: Color=Color.from_hsv(float(n%5)/5.0,.75,1.0) if weapon=="flare" else ink
				_streak(canvas,point,axis,ray,(12.0+life*16.0),life*.92)
				if weapon=="gold":canvas.draw_arc(point,life*5.0+2.0,0,TAU,12,Color("fff1a8",life*.80),2.1,true)
			"bleed":
				canvas.draw_circle(point-Vector2(0,age*15.0),2.3+life*3.5,Color(ink,life*.86))
				canvas.draw_line(point,point+Vector2(0,9.0*life),Color("991a3c",life*.7),1.6,true)
			"shrapnel","earth","cannon","mortar":
				var fragment:=PackedVector2Array([point+axis*8.0,point+side*4.0,point-axis*5.0,point-side*4.0])
				canvas.draw_colored_polygon(fragment,Color(ink,life*.67))
				if weapon=="cannon" or weapon=="mortar":
					canvas.draw_circle(point-Vector2(0,age*19.0),8.0+age*11.0,Color("68717b",life*.12))
			_:
				_streak(canvas,point,axis,ink,life*17.0,life*.85)
	# Distinct animated centers and second beats, so weapons sharing sprite
	# families no longer have identical timing, silhouettes or debris.
	if weapon in ["shadow","cursed","arcane","spectral"]:
		for ring in 3:
			var radius: float=(11.0+float(ring)*10.0+age*20.0)*sqrt(intensity)
			canvas.draw_arc(p-Vector2(0,age*17.0),radius,spin+float(ring)*.65,spin+PI*1.55+float(ring)*.65,24,Color(ink,life*.48),2.0,true)
	elif weapon in ["water","wind"]:
		for ring in 4:
			var radius: float=10.0+age*23.0+float(ring)*7.5
			canvas.draw_arc(p, radius,spin*1.1+float(ring),spin*1.1+PI+float(ring),22,Color(ink,life*.51),2.0,true)
	elif weapon in ["lightning","holy","light","flare"]:
		canvas.draw_circle(p,10.0+age*19.0,Color(ink,life*.23))
	elif weapon in ["explosive","mortar"]:
		_draw(canvas,p-Vector2(0,age*38.0),6,fposmod(age*.82,.999),Vector2(120,107)*sqrt(intensity),life*.53)

static func draw_impact(canvas: CanvasItem,event: Dictionary,age: float,intensity: float=1.0,particles: bool=true,water: bool=true,flashes: bool=true) -> void:
	if age<0.0 or age>=IMPACT_DURATION:return
	var weapon: String=str(event.get("weapon","cannon"))
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var strength: float=clampf(intensity,.35,1.8)
	var phase: float=clampf(age/IMPACT_DURATION,0.0,1.0)
	var fade: float=pow(maxf(0.0,1.0-phase),.63)
	var signature: int=signature_index(weapon)
	var grow: float=1.0+phase*(.45+float(signature%4)*.11)
	var size_scale: float=sqrt(strength)*(.91+float(signature%5)*.067)
	if flashes and age<.23:
		_draw(canvas,p-Vector2(0,12),7,age/.23,Vector2(160,155)*size_scale,(1.0-age/.23)*.91*strength)
	if water:_foam(canvas,p,age,strength)
	_draw(canvas,p-Vector2(0,23.0+phase*29.0),family_for_weapon(weapon),phase,Vector2(167,172)*grow*size_scale,.98*fade*strength)
	if particles:
		var secondary: float=clampf((age-.13)/1.15,0.0,.999)
		_draw(canvas,p-Vector2(0,29.0+phase*33.0),family_for_weapon(weapon),secondary,Vector2(120,139)*grow*size_scale,.53*fade*strength)
	_distinctive_impact(canvas,p,weapon,age,strength,particles)

static func animated_frame(age: float,duration: float=IMPACT_DURATION) -> int:
	return clampi(floori(clampf(age/maxf(.001,duration),0.0,.9999)*float(FRAME_COUNT)),0,FRAME_COUNT-1)

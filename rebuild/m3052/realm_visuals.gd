extends RefCounted
## M390 original game-drawn maritime landmarks and monster water VFX.
## All strokes are decorative, world-anchored and outside the authoritative
## physics. No new GLB, duplicate island colliders, shader samples or timers.
## Rendering uses the same CanvasItem in Android Classic, WebGL and native 3D.
const ECOLOGY=preload("res://realm_ecology.gd")

const REGION_ACCENTS=[
	Color("d4e9b1"), # Warm Caribbean / beach rocks
	Color("e8c480"), # Merchant lanterns and navigational lights
	Color("c8e7f5"), # Northern ice crystals
	Color("d9a583"), # Coastal gun fort stones
	Color("a1bfc9")  # Ancient stone ruins, not universal dark fantasy
]
const REGION_INKS=[
	Color("426f55"),Color("5c6466"),Color("64899d"),Color("61545b"),Color("546c75")
]
const ART_ROLES=[
	["Palmenwache","Korallensteg","Küstenfeuer"],
	["Leuchtfeuer","Handelssteg","Lotsenturm"],
	["Eiskliffs","Frostwarte","Polarfeuer"],
	["Bastion","Wrackmast","Kanonenwache"],
	["Versunkener Bogen","Knochenriff","Tiefenwarte"]
]
const DECORATED_SLOTS=[0,4,7] # Three islands per original lane, six per realm.

static func valid_realm(realm_id:int)->bool:
	return realm_id>=1 and realm_id<=20

static func zone_index(realm_id:int)->int:
	return int((realm_id-1)/4) if valid_realm(realm_id) else -1

static func accent(realm_id:int)->Color:
	var zone:int=zone_index(realm_id)
	return REGION_ACCENTS[zone] if zone>=0 else Color("9fbac1")

static func landmark_key(realm_id:int,island_index:int,half:int)->String:
	if not valid_realm(realm_id) or island_index<0 or island_index>=9 or not half in [0,1]:
		return ""
	if not island_index in DECORATED_SLOTS:return ""
	var variant:int=posmod(island_index+realm_id+half,3)
	return "%s · %s" % [str(ECOLOGY.biome(realm_id)),str(ART_ROLES[zone_index(realm_id)][variant])]

static func landmark_variant(realm_id:int,island_index:int,half:int)->int:
	if landmark_key(realm_id,island_index,half).is_empty():return -1
	return posmod(island_index+realm_id+half,3)

static func island_anchor(island:Dictionary)->Vector2:
	# Occupies only land inside the existing, matching island texture footprint.
	return Vector2(island.get("pos",Vector2.ZERO))+Vector2(-float(island.get("width",400.0))*.055,-float(island.get("width",400.0))*.17)

static func _poly(canvas:CanvasItem,points:Array[Vector2],color:Color)->void:
	canvas.draw_colored_polygon(PackedVector2Array(points),color)

static func _arch(canvas:CanvasItem,a:Vector2,b:Vector2,color:Color,weight:float=2.0)->void:
	canvas.draw_line(a,b,color,weight,true)

static func _ribbon(canvas:CanvasItem,center:Vector2,radius:Vector2,color:Color,weight:float=1.4)->void:
	var points:=PackedVector2Array()
	for i in 17:
		var angle:float=TAU*float(i)/16.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	canvas.draw_polyline(points,color,weight,true)

static func _shadow(canvas:CanvasItem,at:Vector2,width:float)->void:
	_poly(canvas,[at+Vector2(-width,4),at+Vector2(-width*.35,-4),at+Vector2(width*.88,0),at+Vector2(width*.4,10)],Color("182e32",.26))

static func draw_island_landmark(canvas:CanvasItem,island:Dictionary,realm_id:int,island_index:int,half:int,seconds:float,low_detail:bool=false)->void:
	var variant:int=landmark_variant(realm_id,island_index,half)
	if variant<0:return
	var region:int=zone_index(realm_id)
	var size:float=clampf(float(island.get("width",400.0))/490.0,.72,1.24)
	var at:Vector2=island_anchor(island)
	var accent_color:Color=REGION_ACCENTS[region]
	# One world-space origin and one reset, no camera/reprojection tricks.
	canvas.draw_set_transform(at,0.0,Vector2.ONE*size)
	_shadow(canvas,Vector2.ZERO,42)
	match region:
		0:_draw_tropical(canvas,variant,accent_color,seconds,low_detail)
		1:_draw_trading(canvas,variant,accent_color,seconds,low_detail)
		2:_draw_northern(canvas,variant,accent_color,seconds,low_detail)
		3:_draw_war_coast(canvas,variant,accent_color,seconds,low_detail)
		4:_draw_ruins(canvas,variant,accent_color,seconds,low_detail)
	canvas.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func _draw_tropical(canvas:CanvasItem,variant:int,tint:Color,seconds:float,low:bool)->void:
	# Bent palms and a low limestone watch-stone: warm maritime, not anime.
	var shift:float=float(variant)*12.0
	for index in 2:
		var base:=Vector2(-27+index*48,6)
		var tip:=base+Vector2((-13 if index==0 else 10),-44-shift*.42)
		_arch(canvas,base,tip,Color("684832"),5.0)
		_arch(canvas,base+Vector2(1,0),tip+Vector2(1,0),Color("a3815d",.66),1.4)
		for blade in 4:
			var d:=Vector2(float(blade-1.5)*15.0,-8.0-float(blade%2)*5.0)
			_poly(canvas,[tip,tip+d*.64+Vector2(0,2),tip+d],Color("3c7960") if blade%2==0 else Color("63a16c"))
			if not low:_arch(canvas,tip,tip+d*.78,Color(tint,.32),1.0)
	_poly(canvas,[Vector2(-10,6),Vector2(6,-10),Vector2(21,-10),Vector2(31,6)],Color("c1ab82"))
	_poly(canvas,[Vector2(3,-9),Vector2(10,-17),Vector2(19,-16),Vector2(23,-9)],Color("e9d0a2"))
	if not low:
		canvas.draw_circle(Vector2(14,-17),2.8,Color("ffe1a4",.55+.25*sin(seconds*1.4)))

static func _draw_trading(canvas:CanvasItem,variant:int,tint:Color,seconds:float,low:bool)->void:
	# Stone lighthouse / customs watch; visible beacon without a giant bloom.
	var height:float=58.0+float(variant)*9.0
	_poly(canvas,[Vector2(-20,7),Vector2(-15,-height),Vector2(6,-height),Vector2(16,7)],Color("b9b8a7"))
	_poly(canvas,[Vector2(-18,7),Vector2(-14,-height),Vector2(-5,-height),Vector2(-1,7)],Color("77878a"))
	for band in 3:
		var y:float=-height+18.0+float(band)*15.0
		_arch(canvas,Vector2(-15,y),Vector2(11,y+2),Color("5e7273",.50),2.2)
	_poly(canvas,[Vector2(-21,-height+2),Vector2(-10,-height-12),Vector2(8,-height-12),Vector2(16,-height+2)],Color("485d68"))
	_poly(canvas,[Vector2(-11,-height),Vector2(-8,-height-6),Vector2(7,-height-6),Vector2(7,-height)],Color("ecbf68"))
	canvas.draw_circle(Vector2(-2,-height-5),5.0,Color(tint,.35+.25*sin(seconds*1.9)))
	if not low:
		_arch(canvas,Vector2(14,7),Vector2(49,11),Color("8b7456"),3.0)
		for post in 2:_arch(canvas,Vector2(24+post*18,5),Vector2(24+post*18,18),Color("594d3f"),2.0)

static func _draw_northern(canvas:CanvasItem,variant:int,tint:Color,seconds:float,low:bool)->void:
	# Sharp layered arctic ice, cool translucent rim-light and no movement of
	# the actual collision geometry. Only the highlight alpha slowly changes.
	var height:float=64.0+float(variant)*8.0
	_poly(canvas,[Vector2(-37,8),Vector2(-26,-height*.4),Vector2(-6,-height),Vector2(12,-height*.32),Vector2(30,8)],Color("86aec0"))
	_poly(canvas,[Vector2(-26,-height*.4),Vector2(-6,-height),Vector2(-2,6),Vector2(-37,8)],Color("bddce9"))
	_poly(canvas,[Vector2(-6,-height),Vector2(12,-height*.32),Vector2(30,8),Vector2(-2,6)],Color("5d92b1"))
	_poly(canvas,[Vector2(14,7),Vector2(35,-height*.48),Vector2(47,7)],Color("c8e1e8"))
	_arch(canvas,Vector2(-6,-height),Vector2(-3,-height*.16),Color(tint,.78),2)
	if not low:
		_arch(canvas,Vector2(14,-height*.25),Vector2(19,4),Color("f1faff",.3+.1*sin(seconds*.8)),1.4)

static func _draw_war_coast(canvas:CanvasItem,variant:int,tint:Color,seconds:float,low:bool)->void:
	# Compact bastion, ruined battlements and a wind-worn naval standard.
	var h:float=40.0+float(variant)*9.0
	_poly(canvas,[Vector2(-34,9),Vector2(-29,-h),Vector2(24,-h),Vector2(31,9)],Color("8b8373"))
	_poly(canvas,[Vector2(-34,9),Vector2(-29,-h),Vector2(-10,-h),Vector2(-4,9)],Color("b4a78f"))
	for battlement in 4:
		var x:float=-27.0+float(battlement)*15.0
		_poly(canvas,[Vector2(x,-h+3),Vector2(x,-h-10),Vector2(x+9,-h-10),Vector2(x+9,-h+3)],Color("aaa18e") if battlement%2==0 else Color("746f64"))
	_arch(canvas,Vector2(12,-h-8),Vector2(14,-h-43),Color("584438"),3)
	_poly(canvas,[Vector2(14,-h-43),Vector2(45,-h-36),Vector2(29,-h-25),Vector2(14,-h-29)],Color("8a453e"))
	_arch(canvas,Vector2(18,-h-37),Vector2(33,-h-34),Color(tint,.55),1.6)
	if not low:
		_arch(canvas,Vector2(-27,-h+16),Vector2(8,-h+16),Color("555c59",.42),2.0)

static func _draw_ruins(canvas:CanvasItem,variant:int,tint:Color,seconds:float,low:bool)->void:
	# Weathered sea arches and reef fossils, understated ancient-maritime tone.
	var h:float=54.0+float(variant)*10.0
	for side in 2:
		var x:float=-29.0+float(side)*47.0
		_poly(canvas,[Vector2(x-9,7),Vector2(x-7,-h),Vector2(x+8,-h),Vector2(x+11,7)],Color("849b99") if side==0 else Color("667f82"))
		_arch(canvas,Vector2(x-7,-h),Vector2(x+8,-h),Color("cad9c9",.5),1.3)
	canvas.draw_arc(Vector2(-5,-h+10),24,PI,TAU,18,Color("9fb0aa"),7.0,true)
	canvas.draw_arc(Vector2(-5,-h+10),24,PI,TAU,18,Color(tint,.62),1.4,true)
	if not low:
		for rib in 3:
			var x:float=37+rib*11
			var y:float=6-rib*3
			_arch(canvas,Vector2(x,y),Vector2(x-5,y-22+rib*2),Color("c0c9b4",.69),2.5)
		canvas.draw_circle(Vector2(-5,-h+11),2.7,Color("c2e7da",.3+.1*sin(seconds*.74)))

static func monster_ink(realm_id:int)->Color:
	var zone:int=zone_index(realm_id)
	return REGION_ACCENTS[zone] if zone>=0 else Color("a9dfde")

static func draw_monster_presence(canvas:CanvasItem,actor:Dictionary,realm_id:int,seconds:float,low_detail:bool=false)->void:
	if not valid_realm(realm_id) or int(actor.get("hp",0))<=0:return
	var at:Vector2=Vector2(actor.get("pos",Vector2.ZERO))
	var primary:Color=monster_ink(realm_id)
	var guardian:bool=int(actor.get("id",-1))==100
	var pulse:float=.5+.5*sin(seconds*(.95 if guardian else 1.35)+float(actor.get("id",0))*.31)
	var width:float=112.0 if guardian else 82.0
	_ribbon(canvas,at+Vector2(0,28),Vector2(width*(1.0+pulse*.06),20+pulse*5),Color(primary,.16+pulse*.14),1.6)
	if guardian and not low_detail:
		_ribbon(canvas,at+Vector2(0,28),Vector2(width+21+pulse*6,28+pulse*3),Color(primary,.07+pulse*.08),1.2)
	var fraction:float=float(actor.get("hp",1))/maxf(1.0,float(actor.get("max_hp",1)))
	if fraction<=.35:
		for i in (3 if low_detail else 6):
			var angle:float=float(i)*TAU/(3.0 if low_detail else 6.0)
			var offset:=Vector2(cos(angle)*width*.68,sin(angle)*20)
			canvas.draw_circle(at+offset+Vector2(0,22-7*pulse),2.1+pulse*2.0,Color("d2eced",.3+.25*pulse))

static func draw_monster_impact(canvas:CanvasItem,event:Dictionary,age:float,realm_id:int,low_detail:bool=false)->void:
	if not valid_realm(realm_id) or age<0.0 or age>=1.25:return
	var p:Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var color:Color=monster_ink(realm_id)
	var fade:float=1.0-age/1.25
	_ribbon(canvas,p+Vector2(0,9),Vector2(17+age*57.0,6+age*24.0),Color(color,.58*fade),2.0)
	for spray in (3 if low_detail else 5):
		var angle:float=PI+float(spray+1)*PI/float(6 if low_detail else 7)
		var velocity:=Vector2(cos(angle),sin(angle))*float(25+spray*6)
		var origin:=p+Vector2(0,8)
		canvas.draw_line(origin+velocity*age,origin+velocity*(age+.21)-Vector2(0,13*age),Color("cce5e8",.35*fade),1.3,true)

static func draw_monster_sinking(canvas:CanvasItem,event:Dictionary,age:float,realm_id:int,low_detail:bool=false)->void:
	if not valid_realm(realm_id) or age<0.0 or age>=1.2:return
	var center:Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var fade:float=1.0-age/1.2
	var color:Color=monster_ink(realm_id)
	_ribbon(canvas,center,Vector2(45+age*100.0,17+age*41),Color(color,.51*fade),2.3)
	var count:int=4 if low_detail else 9
	for i in count:
		var angle:float=float(i)*TAU/float(count)+.3
		var origin:=center+Vector2(cos(angle)*(18+age*82),sin(angle)*(8+age*28))
		canvas.draw_circle(origin-Vector2(0,age*10),2.0+fade*3.0,Color("e2f4ef",.52*fade))

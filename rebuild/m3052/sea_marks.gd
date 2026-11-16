extends RefCounted
## Small vector marks shared by nameplates, minimap, chart and menus: deck tiles, staff badges,
## padlocks and check marks. The bundled font has no symbol glyphs, so these are drawn.
const DECK_COLORS := {"cannon":Color("ff7a45"),"armor":Color("9cbde3"),"hunter":Color("6fd37a"),"navigation":Color("4fd6ec"),"logistics":Color("f2c14e"),"tide":Color("3fe8cf")}
const ROMAN := ["I","II","III"]
# Every image is an independent transparent Godot texture (NOT an atlas,
# combined badge, timed buff, or drawn procedural surrogate).
const EXTENSION_ART := {
	"mojo_frame":preload("res://assets/ui/deck_extensions/mojo_bone_frame.svg"),
	"crown_left":preload("res://assets/ui/deck_extensions/left_crown.svg"),
	"crest_right":preload("res://assets/ui/deck_extensions/upper_right_crest.svg"),
	"skull_top_left":preload("res://assets/ui/deck_extensions/skull_top_left.svg"),
	"skull_top_right":preload("res://assets/ui/deck_extensions/skull_top_right.svg"),
	"skull_bottom":preload("res://assets/ui/deck_extensions/skull_bottom.svg")
}
const EXTENSION_KEYS := ["mojo_frame","crown_left","crest_right","skull_top_left","skull_top_right","skull_bottom"]


static func gem(canvas: CanvasItem,center: Vector2,r: float,color: Color,tier: int,lit: bool,font: Font=null,glow: float=0.0) -> void:
	var w=r*.82
	var outline=PackedVector2Array([center+Vector2(0,-r),center+Vector2(w,0),center+Vector2(0,r),center+Vector2(-w,0)])
	var shadow=PackedVector2Array()
	for p in outline:shadow.append(p+Vector2(0,1.4))
	canvas.draw_colored_polygon(shadow,Color(0,0,0,.55))
	if not lit:
		canvas.draw_colored_polygon(outline,Color("0d1a20"))
		var edge=outline.duplicate();edge.append(outline[0])
		canvas.draw_polyline(edge,Color("5d5240"),1.2,true)
		canvas.draw_circle(center,r*.16,Color("3a362c"))
		return
	if glow>0:canvas.draw_circle(center,r*1.5,Color(color,.18*glow))
	var dark=color.darkened(.45);var light=color.lightened(.4)
	canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-r),center+Vector2(w,0),center,center+Vector2(-w,0)]),color)
	canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-w,0),center,center+Vector2(0,r)]),dark)
	canvas.draw_colored_polygon(PackedVector2Array([center,center+Vector2(w,0),center+Vector2(0,r)]),color.darkened(.2))
	canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-r),center+Vector2(-w*.5,-r*.5),center+Vector2(0,-r*.2)]),Color(light,.9))
	var rim=outline.duplicate();rim.append(outline[0])
	canvas.draw_polyline(rim,Color("fff0c2"),maxf(1.6,r*.16),true)
	canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-r*.55),center+Vector2(w*.28,-r*.15),center+Vector2(0,-r*.05)]),Color(1,1,1,.35))
	if font!=null and tier>=0 and r>=9:
		var text: String=ROMAN[clampi(tier,0,2)]
		var fs=maxi(8,roundi(r*.78))
		var tw=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		canvas.draw_string_outline(font,center+Vector2(-tw*.5,fs*.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color(0,0,0,.85))
		canvas.draw_string(font,center+Vector2(-tw*.5,fs*.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color.WHITE)
	elif tier>=0:
		for i in tier+1:canvas.draw_circle(center+Vector2((float(i)-tier*.5)*r*.42,r+2.6),1.1,Color("f5d78d"))

## Fixed physical slots: five columns, two rows. Colour means material, not role.
static func deck_cells(center: Vector2,r: float) -> Array[Vector2]:
	var cells: Array[Vector2]=[]
	for slot in 10:cells.append(center+Vector2((slot%5-2)*r*1.9,(floori(slot/5.0)-.5)*r*1.9))
	return cells

## Original vector deck fittings. Each slot has hand-drawn steel rails, rivets,
## inset enamel and a subtle animated reflection if a real deck is mounted.
static func deck_tile(canvas: CanvasItem,center: Vector2,r: float,color: Color,active: bool,phase: float=0.0) -> void:
	var rect=Rect2(center-Vector2.ONE*r,Vector2.ONE*r*2.0)
	canvas.draw_rect(rect.grow(1.3),Color("050f17"))
	canvas.draw_rect(rect,Color("2b3c46"))
	canvas.draw_rect(rect.grow(-.65),Color("101f2b") if not active else color.darkened(.62))
	canvas.draw_line(rect.position+Vector2(0,1),Vector2(rect.end.x,rect.position.y+1),Color("a7b8bf",.65),.7,true)
	canvas.draw_line(rect.position+Vector2(1,0),Vector2(rect.position.x+1,rect.end.y),Color("92a4ab",.4),.7,true)
	if active:
		var inset=rect.grow(-1.25)
		canvas.draw_rect(inset,color.darkened(.22))
		canvas.draw_rect(Rect2(inset.position,Vector2(inset.size.x,inset.size.y*.43)),color.lightened(.17))
		canvas.draw_line(inset.position+Vector2(1,.7),Vector2(inset.end.x-1,inset.position.y+.7),color.lightened(.53),.9,true)
		var glint=(.5+.5*sin(phase))*.24
		canvas.draw_rect(inset.grow(-.5),Color(1,1,1,glint),false,.7,true)
	else:
		canvas.draw_rect(rect.grow(-2),Color("0b1922"))
		canvas.draw_line(rect.position+Vector2(2,2),rect.end-Vector2(2,2),Color("435866",.4),.75,true)
	for side in [-1.0,1.0]:
		var pin=center+Vector2(side*(r-.7),-r+.65)
		canvas.draw_circle(pin,.58,Color("d6d0b6",.85))
		canvas.draw_circle(pin,.28,Color("334249"))

static func deck_tiles(canvas: CanvasItem,center: Vector2,r: float,entries: Array,time_seconds: float=0.0) -> void:
	var cells=deck_cells(center,r)
	# Continuous hand-made crossbars turn loose boxes into a fitted deck assembly.
	for row in 2:
		var y=center.y+(float(row)-.5)*r*1.9
		canvas.draw_line(Vector2(cells[row*5].x-r*.85,y),Vector2(cells[row*5+4].x+r*.85,y),Color("d2c5a6",.30),1.0,true)
	for slot in 10:
		var entry: Dictionary=entries[slot] if slot<entries.size() else {}
		deck_tile(canvas,cells[slot],r*.78,entry.get("color",Color.WHITE),bool(entry.get("lit",false)),time_seconds*2.1+float(slot)*.63)

static func metal(canvas: CanvasItem,center: Vector2,r: float,vertices: Array,side: float=1.0,active: bool=true) -> void:
	var points=PackedVector2Array()
	for v: Vector2 in vertices:points.append(center+Vector2(v.x*side,v.y)*r)
	var edge=points.duplicate();edge.append(points[0])
	canvas.draw_polyline(edge,Color("08121a"),3.0,true)
	var low=INF;var high=-INF
	for point in points:low=minf(low,point.y);high=maxf(high,point.y)
	var shades=PackedColorArray()
	for point in points:
		var top=Color("e2dfc9") if active else Color("b4c0bf")
		var bottom=Color("72786d") if active else Color("495d67")
		shades.append(top.lerp(bottom,(point.y-low)/maxf(.01,high-low)))
	canvas.draw_polygon(points,shades)
	canvas.draw_polyline(edge,Color("e6dfc4") if active else Color("b2bbba"),.7,true)
	if points.size()>2:
		canvas.draw_line(points[0],points[1],Color("fff3d4") if active else Color("c6cecd"),1.0,true)
		canvas.draw_line(points[points.size()-2],points[points.size()-1],Color("414d52"),1.2,true)

## Sculpted side fittings replace the old round ability buttons. Inactive fittings
## stay bare steel; active decks have their own coloured inlay, with no fake timer.
static func special_deck_arm(canvas: CanvasItem,center: Vector2,r: float,side: float,key: String,active: bool,time_seconds: float=0.0) -> void:
	var upper=key in ["tide","storm"]
	var shape: Array=[Vector2(5.25,-1.7),Vector2(8.2,-.1),Vector2(11.55,.05),Vector2(11.65,-1.25),Vector2(12.1,-1.65),Vector2(12.0,1.1),Vector2(8.0,.8),Vector2(5.25,-.1)] if upper else [Vector2(4.7,2.05),Vector2(7.4,2.65),Vector2(8.2,2.25),Vector2(8.5,2.65),Vector2(9.5,2.65),Vector2(9.8,3.1),Vector2(9.45,3.5),Vector2(8.5,3.35),Vector2(8.2,3.65),Vector2(7.7,3.4),Vector2(4.7,3.15)]
	metal(canvas,center,r,shape,side,active)
	if upper:
		var joint=center+Vector2(side*8.0,.32)*r
		canvas.draw_line(joint-Vector2(0,r*.44),joint+Vector2(0,r*.44),Color("293d48"),.8,true)
		canvas.draw_circle(joint+Vector2(side*r*.4,0),maxf(.65,r*.11),Color("e9e2ca"),true,-1,true)
	var ink: Color={"tide":Color("5de0d4"),"storm":Color("80bdff"),"salvage":Color("edc36a"),"blessing":Color("bd78f2")}[key]
	var origin=center+Vector2(side*(7.5 if upper else 6.3),.2 if upper else 2.8)*r
	if not active:
		# Engraved pictogram, visible but dormant; never imply a buff is owned.
		canvas.draw_circle(origin,r*.39,Color("172e37",.7))
		return
	var pulse=.55+.45*sin(time_seconds*2.3+(0.0 if upper else 1.8))
	canvas.draw_circle(origin,r*.8,Color(ink,.04+.07*pulse))
	canvas.draw_circle(origin,r*.47,Color("0b1e28",.82))
	canvas.draw_arc(origin,r*.48,-PI*.66,PI*.66,12,Color(ink,.54+.35*pulse),.95,true)
	if key=="tide":
		for row in 2:
			var wave=PackedVector2Array()
			for i in 7:wave.append(origin+Vector2((i-3)*r*.14,(row-.5)*r*.3+sin(float(i)*PI*.58+time_seconds*1.6)*r*.10))
			canvas.draw_polyline(wave,ink,1.2,true)
	elif key=="storm":
		canvas.draw_colored_polygon(PackedVector2Array([origin+Vector2(-r*.14,-r*.4),origin+Vector2(r*.15,-r*.4),origin+Vector2(0,0),origin+Vector2(r*.24,0),origin+Vector2(-r*.19,r*.43),origin+Vector2(-r*.05,r*.08),origin+Vector2(-r*.23,r*.08)]),ink)
	elif key=="salvage":
		canvas.draw_line(origin-Vector2(0,r*.35),origin+Vector2(0,r*.29),ink,1.35,true)
		canvas.draw_arc(origin+Vector2(0,r*.14),r*.25,0,PI,10,ink,1.3,true)
		canvas.draw_line(origin+Vector2(-r*.22,-r*.12),origin+Vector2(r*.22,-r*.12),ink,1.15,true)
	elif key=="blessing":
		canvas.draw_colored_polygon(PackedVector2Array([origin+Vector2(0,-r*.46),origin+Vector2(r*.31,0),origin+Vector2(0,r*.46),origin+Vector2(-r*.31,0)]),ink)
		canvas.draw_line(origin-Vector2(0,r*.25),origin,Color("f6e5ff",.8),1.0,true)

## A small pirate crest above the deck tiles, rather than a row of ability discs.
static func pirate_crest(canvas: CanvasItem,center: Vector2,r: float) -> void:
	for side in [-1.0,1.0]:
		metal(canvas,center,r,[Vector2(.5,-.35),Vector2(1.65,-1.0),Vector2(1.95,-.75),Vector2(1.75,-.4),Vector2(.6,.2)],side)
		metal(canvas,center,r,[Vector2(.4,.2),Vector2(1.65,.85),Vector2(1.85,.55),Vector2(1.6,.3),Vector2(.55,-.3)],side)
	canvas.draw_circle(center-Vector2(0,r*.23),r*.95,Color("07121a"))
	canvas.draw_circle(center-Vector2(0,r*.23),r*.8,Color("c8c8b6"))
	canvas.draw_circle(center-Vector2(r*.16,r*.46),r*.52,Color("e9e3cd"))
	canvas.draw_rect(Rect2(center+Vector2(-r*.52,r*.05),Vector2(r*1.04,r*.75)),Color("b8bcad"))
	for side in [-1.0,1.0]:canvas.draw_circle(center+Vector2(side*r*.35,-r*.1),r*.23,Color("162532"))
	canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(0,r*.12),center+Vector2(-r*.16,r*.4),center+Vector2(r*.16,r*.4)]),Color("27343b"))
	for x in [-.25,.05,.35]:canvas.draw_line(center+Vector2(x*r,r*.5),center+Vector2(x*r,r*.77),Color("4a5557"),.6,true)
	canvas.draw_arc(center-Vector2(0,r*.24),r*.82,PI*1.08,PI*1.95,12,Color("fff1c6",.6),.75,true)
	canvas.draw_circle(center+Vector2(-r*.32,-r*.41),r*.10,Color("ffffff",.52))

## M383: each pictogram in the user's screenshot is its OWN upgrade slot.
## The Mojo bone frame is a separately equipped extension, never the
## background of a precomposed static "deck badge". The old central cannon
## count is gone; ten mounted ordinary decks occupy its exact position.
static func reference_deck_geometry(r: float) -> Dictionary:
	return {
		"left_crown":Vector2(-6.9*r,-.85*r),
		"right_crown":Vector2(6.9*r,-.85*r),
		"skulls":[Vector2(-1.55*r,-1.05*r),Vector2(1.55*r,-1.05*r)],
		"number":Vector2(0,1.35*r), # Legacy layout key: NOW ten deck pips, never a number.
		"deck_pips":Vector2(0,1.35*r),
		"bottom_crest":Vector2(0,4.15*r),
		"mojo_frame":Vector2(0,1.45*r)
	}

static func deck_extension_state(sim) -> Dictionary:
	var state: Dictionary={}
	var installed: Variant=sim.deck_extensions if sim!=null else {}
	for key: String in EXTENSION_KEYS:
		state[key]=bool(installed.get(key,false)) if installed is Dictionary else false
	return state

static func reference_deck_layers(sim) -> Array[Dictionary]:
	var state: Dictionary=deck_extension_state(sim)
	var result: Array[Dictionary]=[]
	for key: String in EXTENSION_KEYS:
		result.append({"key":key,"installed":bool(state[key]),"asset":EXTENSION_ART[key]})
	return result

static func _draw_reference_module(canvas: CanvasItem,center: Vector2,r: float,key: String,installed: bool,at: Vector2,dimensions: Vector2) -> void:
	# No ghost extension is silently granted. Missing equipment is absent,
	# not falsely rendered as a permanent crown, skull or Mojo buff.
	if not installed:return
	var image: Texture2D=EXTENSION_ART.get(key)
	if image==null:return
	var px_size: Vector2=dimensions*r
	canvas.draw_texture_rect(image,Rect2(center+at-px_size*.5,px_size),false)

static func _reference_deck_pips(canvas: CanvasItem,center: Vector2,r: float,entries: Array) -> void:
	# Ten INDIVIDUAL normal slots: 2 x 5 points exactly where the
	# old '133/411/656' number was. Material colour is live game data.
	for slot in 10:
		var entry: Dictionary=entries[slot] if slot<entries.size() else {}
		var point: Vector2=center+Vector2((float(slot%5)-2.0)*r*.92,(float(floori(slot/5.0))-.5)*r*.92)
		var lit: bool=bool(entry.get("lit",false))
		var ink: Color=Color(entry.get("color",Color("536373"))) if lit else Color("536477")
		var size: Vector2=Vector2(r*.61,r*.51)
		var rect: Rect2=Rect2(point-size*.5,size)
		canvas.draw_rect(rect.grow(maxf(.55,r*.11)),Color("08141d"),true)
		canvas.draw_rect(rect,ink if lit else ink.darkened(.44),true)
		canvas.draw_line(point+Vector2(-size.x*.38,-size.y*.28),point+Vector2(size.x*.25,-size.y*.28),ink.lightened(.25) if lit else Color("56616b",.45),maxf(.55,r*.085),true)

static func deck_badge(canvas: CanvasItem,center: Vector2,r: float,sim,_time_seconds: float=0.0) -> void:
	var layout: Dictionary=reference_deck_geometry(r)
	var owned: Dictionary=deck_extension_state(sim)
	# Mojo is the BONE FRAME: draw BEHIND all five independent extensions.
	_draw_reference_module(canvas,center,r,"mojo_frame",bool(owned.mojo_frame),Vector2(layout.mojo_frame),Vector2(18.8,7.65))
	# Crown left and the top-right crest are distinct, not a paired toggle.
	_draw_reference_module(canvas,center,r,"crown_left",bool(owned.crown_left),Vector2(layout.left_crown),Vector2(2.8,2.9))
	_draw_reference_module(canvas,center,r,"crest_right",bool(owned.crest_right),Vector2(layout.right_crown),Vector2(2.8,2.9))
	var tops: Array=layout.skulls
	_draw_reference_module(canvas,center,r,"skull_top_left",bool(owned.skull_top_left),Vector2(tops[0]),Vector2(2.45,2.45))
	_draw_reference_module(canvas,center,r,"skull_top_right",bool(owned.skull_top_right),Vector2(tops[1]),Vector2(2.45,2.45))
	_reference_deck_pips(canvas,center+Vector2(layout.deck_pips),r,deck_entries(sim))
	_draw_reference_module(canvas,center,r,"skull_bottom",bool(owned.skull_bottom),Vector2(layout.bottom_crest),Vector2(2.45,2.45))
	# Timed Gezeiten/Runen/Korsaren-Buffs remain in the normal buff UI.
	# Neither a timer nor the cannon count unlocks ornamental modules.

## Kristallsegen beside the deck row: the crystal, a gold ring and a timer that runs down.
static func blessing_crystal(canvas: CanvasItem,center: Vector2,r: float,texture: Texture2D,remaining: float,total: float) -> void:
	var pulse=.5+.5*sin(Time.get_ticks_msec()/240.0)
	canvas.draw_circle(center,r*1.45,Color("c69bff",.16+.14*pulse))
	canvas.draw_circle(center+Vector2(0,1.5),r,Color(0,0,0,.45))
	canvas.draw_circle(center,r*.92,Color("140818"))
	if texture!=null:
		var s=r*1.55
		canvas.draw_texture_rect(texture,Rect2(center-Vector2(s,s)*.5,Vector2(s,s)),false)
	var ratio=clampf(remaining/maxf(total,.001),0.0,1.0)
	canvas.draw_arc(center,r*1.12,-PI*.5,-PI*.5+TAU*ratio,28,Color("f3d2ff"),maxf(2.0,r*.16),true)
	canvas.draw_arc(center,r*1.12,0,TAU,28,Color("f5d78d"),maxf(1.3,r*.09),true)

## Staff role badge: a pointed shield plate in the role colour with the role tag.
static func staff_badge(canvas: CanvasItem,left_middle: Vector2,tag: String,color: Color,font: Font,fs: int=11) -> float:
	var tw=font.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var h=fs+6.0
	var w=tw+16.0
	var o=left_middle-Vector2(0,h*.5)
	var plate=PackedVector2Array([o+Vector2(5,0),o+Vector2(w-5,0),o+Vector2(w,h*.5),o+Vector2(w-5,h),o+Vector2(5,h),o+Vector2(0,h*.5)])
	var shade=PackedVector2Array()
	for p in plate:shade.append(p+Vector2(0,1.5))
	canvas.draw_colored_polygon(shade,Color(0,0,0,.6))
	canvas.draw_polygon(plate,PackedColorArray([color.lightened(.15),color.lightened(.15),color.darkened(.35),color.darkened(.45),color.darkened(.45),color.darkened(.2)]))
	var edge=plate.duplicate();edge.append(plate[0])
	canvas.draw_polyline(edge,Color("fff0c8"),1.3,true)
	canvas.draw_string_outline(font,o+Vector2(8,h*.5+fs*.36),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color(0,0,0,.8))
	canvas.draw_string(font,o+Vector2(8,h*.5+fs*.36),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color.WHITE)
	return w

static func badge_width(tag: String,font: Font,fs: int=11) -> float:
	return font.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x+16.0

static func padlock(canvas: CanvasItem,center: Vector2,s: float,color: Color) -> void:
	canvas.draw_arc(center-Vector2(0,s*.25),s*.32,PI,TAU,12,color,maxf(1.5,s*.12),true)
	canvas.draw_rect(Rect2(center+Vector2(-s*.45,-s*.25),Vector2(s*.9,s*.7)),color)
	canvas.draw_circle(center+Vector2(0,s*.05),s*.1,Color(0,0,0,.7))

static func check(canvas: CanvasItem,center: Vector2,s: float,color: Color) -> void:
	var arm=PackedVector2Array([center+Vector2(-s*.45,0),center+Vector2(-s*.12,s*.32),center+Vector2(s*.48,-s*.38)])
	canvas.draw_polyline(arm,Color(0,0,0,.6),maxf(2.5,s*.28),true)
	canvas.draw_polyline(arm,color,maxf(1.5,s*.16),true)

static func deck_entries(sim) -> Array:
	var entries: Array=[]
	for slot in 10:
		var index=int(sim.deck_slots[slot])
		if index>=0 and index<sim.decks.size():
			var deck: Dictionary=sim.decks[index]
			entries.append({"slot":slot,"color":sim.CONTENT.DECK_TIER_COLORS[int(deck.tier)],"tier":int(deck.tier),"lit":true})
		else:entries.append({"slot":slot,"lit":false,"tier":-1})
	return entries

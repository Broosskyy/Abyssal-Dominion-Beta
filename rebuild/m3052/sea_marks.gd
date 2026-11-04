extends RefCounted
## Small vector marks shared by nameplates, minimap, chart and menus: deck gems, staff badges,
## padlocks and check marks. The bundled font has no symbol glyphs, so these are drawn.
const DECK_COLORS := {"cannon":Color("ff7a45"),"armor":Color("9cbde3"),"hunter":Color("6fd37a"),"navigation":Color("4fd6ec"),"logistics":Color("f2c14e"),"tide":Color("3fe8cf")}
const ROMAN := ["I","II","III"]

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
	canvas.draw_polyline(rim,Color("f5d78d"),1.3,true)
	if font!=null and tier>=0 and r>=9:
		var text: String=ROMAN[clampi(tier,0,2)]
		var fs=maxi(8,roundi(r*.78))
		var tw=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		canvas.draw_string_outline(font,center+Vector2(-tw*.5,fs*.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color(0,0,0,.85))
		canvas.draw_string(font,center+Vector2(-tw*.5,fs*.36),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color.WHITE)
	elif tier>=0:
		for i in tier+1:canvas.draw_circle(center+Vector2((float(i)-tier*.5)*r*.42,r+2.6),1.1,Color("f5d78d"))

## Deck strip under a nameplate: chevrons left and right, one gem per slot.
static func gem_row(canvas: CanvasItem,center: Vector2,r: float,entries: Array,font: Font=null) -> void:
	var gap=r*2.05
	var half=(entries.size()-1)*gap*.5
	for side in [-1.0,1.0]:
		var tip=center+Vector2(side*(half+r*1.55),0)
		var arm=PackedVector2Array([tip+Vector2(-side*r*.45,-r*.5),tip,tip+Vector2(-side*r*.45,r*.5)])
		canvas.draw_polyline(arm,Color(0,0,0,.6),3.0,true)
		canvas.draw_polyline(arm,Color("e6c886"),1.5,true)
	for i in entries.size():
		var entry: Dictionary=entries[i]
		gem(canvas,center+Vector2(-half+i*gap,0),r,entry.get("color",Color.WHITE),int(entry.get("tier",-1)),bool(entry.get("lit",false)),font,float(entry.get("glow",0.0)))

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
	for slot in 2:
		var index=int(sim.deck_slots[slot])
		if index>=0 and index<sim.decks.size():
			var deck: Dictionary=sim.decks[index]
			entries.append({"color":DECK_COLORS.get(str(deck.type),Color.WHITE),"tier":int(deck.tier),"lit":true})
		else:entries.append({"lit":false})
	var tide=float(sim.buffs.tide_deck)>0
	entries.append({"color":DECK_COLORS.tide,"tier":-1,"lit":tide,"glow":1.0 if tide else 0.0})
	return entries

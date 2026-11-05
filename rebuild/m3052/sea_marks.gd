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
	for slot in 10:cells.append(center+Vector2((slot%5-2)*r*2.2,(floori(slot/5.0)-.5)*r*2.35))
	return cells

static func gem_row(canvas: CanvasItem,center: Vector2,r: float,entries: Array,font: Font=null) -> void:
	var cells=deck_cells(center,r)
	for slot in 10:
		var entry: Dictionary=entries[slot] if slot<entries.size() else {}
		gem(canvas,cells[slot],r,entry.get("color",Color.WHITE),-1,bool(entry.get("lit",false)),null)
	for side in [-1.0,1.0]:
		var tip=center+Vector2(side*r*6.2,0)
		var arm=PackedVector2Array([tip+Vector2(-side*r,-r*1.35),tip,tip+Vector2(-side*r,r*1.35)])
		canvas.draw_polyline(arm,Color(0,0,0,.6),3.0,true)
		canvas.draw_polyline(arm,Color("c6a86d"),1.3,true)

## Four distinct original symbols surround the normal decks. Unowned/inactive
## special decks stay dim; only active timers light the icon and its outer arc.
static func special_deck_icon(canvas: CanvasItem,center: Vector2,r: float,key: String,active: bool,ratio: float=0.0) -> void:
	var colors={"tide":Color("5de0d4"),"storm":Color("80bdff"),"salvage":Color("edc36a"),"blessing":Color("bd78f2")}
	var ink: Color=colors[key] if active else Color("556975",.5)
	canvas.draw_circle(center,r,Color("06141d",.75))
	canvas.draw_arc(center,r,0,TAU,24,Color("c6a86d",.7) if active else Color("53606a",.4),1.0,true)
	if active:canvas.draw_arc(center,r+2,-PI*.5,-PI*.5+TAU*clampf(ratio,0,1),24,ink,1.3,true)
	if key=="tide":
		for row in 2:
			var line=PackedVector2Array()
			for i in 9:line.append(center+Vector2((i-4)*r*.18,sin(i*PI*.5)*r*.17+(row-.5)*r*.45))
			canvas.draw_polyline(line,ink,1.5,true)
	elif key=="storm":
		var bolt=PackedVector2Array([center+Vector2(.25,-.72)*r,center+Vector2(-.4,.06)*r,center+Vector2(.08,.06)*r,center+Vector2(-.25,.72)*r,center+Vector2(.48,-.15)*r,center+Vector2(.05,-.15)*r])
		canvas.draw_colored_polygon(bolt,ink)
	elif key=="salvage":
		canvas.draw_circle(center-Vector2(0,r*.5),r*.17,ink,false,1.3,true)
		canvas.draw_line(center-Vector2(0,r*.32),center+Vector2(0,r*.5),ink,1.5,true)
		canvas.draw_arc(center,r*.53,0,PI,16,ink,1.5,true)
		canvas.draw_line(center+Vector2(-r*.35,-r*.03),center+Vector2(r*.35,-r*.03),ink,1.2,true)
	else:gem(canvas,center,r*.72,ink,-1,active)

static func deck_badge(canvas: CanvasItem,center: Vector2,r: float,sim) -> void:
	gem_row(canvas,center,r,deck_entries(sim))
	var tide=float(sim.buffs.tide_deck)
	if tide>0:
		for side in [-1.0,1.0]:
			var edge=PackedVector2Array([center+Vector2(side*r*5.2,-r*2.8),center+Vector2(side*r*6.9,-r*1.9),center+Vector2(side*r*7.2,0),center+Vector2(side*r*6.9,r*1.9),center+Vector2(side*r*5.2,r*2.8)])
			canvas.draw_polyline(edge,Color("5de0d4",.8),1.4,true)
	var x=r*8.2;var y=r*1.65;var icon=r*1.35
	special_deck_icon(canvas,center+Vector2(-x,-y),icon,"tide",tide>0,tide/1800.0)
	special_deck_icon(canvas,center+Vector2(x,-y),icon,"storm",float(sim.buffs.storm_deck)>0,float(sim.buffs.storm_deck)/1800.0)
	special_deck_icon(canvas,center+Vector2(-x,y),icon,"salvage",float(sim.buffs.salvage_deck)>0,float(sim.buffs.salvage_deck)/1800.0)
	special_deck_icon(canvas,center+Vector2(x,y),icon,"blessing",sim.has_blessing(),float(sim.buffs.blessing)/900.0)

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

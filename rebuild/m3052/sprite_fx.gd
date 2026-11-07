extends RefCounted
## M3106 — frame-by-frame textured sea battle VFX. 8 rows x 8 frames.
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
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,first),Color(1,1,1,opacity))
	else:
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,first),Color(1,1,1,opacity*(1.0-fraction)))
		canvas.draw_texture_rect_region(SHEET,dest,src_rect(row,second),Color(1,1,1,opacity*fraction))

static func draw_flight(canvas: CanvasItem,at: Vector2,direction: Vector2,weapon: String,clock: float,seed: int=0) -> void:
	var dir: Vector2=direction.normalized() if direction.length_squared()>.00001 else Vector2.RIGHT
	var row: int=family_for_weapon(weapon)
	var pulse: float=fposmod(clock*4.4+float(seed)*.077,1.0)
	# Separate animated sprite puffs sweep behind the physical ball, creating
	# motion and changing shape rather than an unchanging geometric trail.
	_draw(canvas,at-dir*12.0,row,pulse,Vector2(36,34),.53)
	_draw(canvas,at-dir*25.0,row,fposmod(pulse+.35,1.0),Vector2(30,28),.36)
	_draw(canvas,at-dir*38.0,row,fposmod(pulse+.72,1.0),Vector2(25,23),.21)

static func draw_muzzle(canvas: CanvasItem,event: Dictionary,age: float) -> void:
	if age<0.0 or age>=.48:return
	var weapon: String=str(event.get("weapon","cannon"))
	var origin: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var heading: Vector2=Vector2(event.get("heading",Vector2.RIGHT))
	if heading.length_squared()<.01:heading=Vector2.RIGHT
	heading=heading.normalized()
	_draw(canvas,origin+heading*24.0,family_for_weapon(weapon),age/.48,Vector2(78,70),1.0-age/.52)
	_draw(canvas,origin+heading*42.0,6,age/.48,Vector2(46,43),.46*(1.0-age/.48))

static func draw_impact(canvas: CanvasItem,event: Dictionary,age: float) -> void:
	if age<0.0 or age>=IMPACT_DURATION:return
	var weapon: String=str(event.get("weapon","cannon"))
	var p: Vector2=Vector2(event.get("pos",Vector2.ZERO))
	var phase: float=clampf(age/IMPACT_DURATION,0.0,1.0)
	var fade: float=pow(maxf(0.0,1.0-phase),.56)
	var growing: float=1.0+phase*.33
	# Fast bright impact. Then separate plumes and a dynamic elemental explosion.
	# All framed visuals are transparent: hull, nameplate and targeting stay visible.
	if age<.25:
		_draw(canvas,p-Vector2(0,10),7,age/.25,Vector2(130,124),.88*(1.0-age/.27))
	_draw(canvas,p+Vector2(0,10),5,clampf((age-.055)/1.26,0,1),Vector2(160,123)*growing,.77*fade)
	var family: int=family_for_weapon(weapon)
	_draw(canvas,p-Vector2(0,24+phase*13),family,phase,Vector2(155,156)*growing,.91*fade)
	if weapon in ["fire","lava","explosive","ice","crystal","lightning","shadow","cursed","necro","gas","poison"]:
		_draw(canvas,p-Vector2(0,27+phase*14),family,fposmod(phase+.18,1.0),Vector2(104,117)*growing,.30*fade)

static func animated_frame(age: float,duration: float=IMPACT_DURATION) -> int:
	return clampi(floori(clampf(age/maxf(.001,duration),0.0,.9999)*float(FRAME_COUNT)),0,FRAME_COUNT-1)

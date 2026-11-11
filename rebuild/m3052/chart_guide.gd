extends Control
## Diagrams for the chart guide: the square grid with an example position, the minimap legend
## and the nameplate colours. Drawn with the same marks the sea and the minimap use.
const SEA_MARKS = preload("res://sea_marks.gd")
const MINI = preload("res://minimap.gd")
var mode := "grid"
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y={"grid":190.0,"legend":176.0,"colors":156.0}.get(mode,150.0)

func _draw() -> void:
	var panel=Rect2(Vector2.ZERO,size)
	draw_rect(panel,Color("0a1a21"))
	draw_rect(panel,Color("6b5634"),false,1.2)
	match mode:
		"grid":_grid()
		"legend":_legend()
		"colors":_colors()

func _text(point: Vector2,text: String,fs: int,color: Color,center: bool=false) -> void:
	var x=point.x-(font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x*.5 if center else 0.0)
	draw_string_outline(font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color("041016"))
	draw_string(font,Vector2(x,point.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func _grid() -> void:
	var columns=8;var rows=4
	var area=Rect2(36,30,minf(size.x*.55,340),size.y-46)
	var cell=Vector2(area.size.x/columns,area.size.y/rows)
	draw_rect(area,Color("0f3a66"))
	for x in columns+1:draw_line(area.position+Vector2(cell.x*x,0),area.position+Vector2(cell.x*x,area.size.y),Color(.6,.8,1,.25),1)
	for y in rows+1:draw_line(area.position+Vector2(0,cell.y*y),area.position+Vector2(area.size.x,cell.y*y),Color(.6,.8,1,.25),1)
	for x in columns:_text(area.position+Vector2(cell.x*(x+.5),-8),MINI.column_name(x*MINI.SQUARE),11,Color("f4dfae"),true)
	for y in rows:_text(area.position+Vector2(-16,cell.y*(y+.55)+4),MINI.row_name(y*MINI.SQUARE),11,Color("f4dfae"),true)
	var square=Rect2(area.position+Vector2(cell.x*3,cell.y*2),cell)
	draw_rect(square,Color("ffd27a",.28))
	draw_rect(square,Color("ffd27a"),false,1.6)
	var ship=square.get_center()
	draw_colored_polygon(PackedVector2Array([ship+Vector2(7,0),ship+Vector2(-5,5),ship+Vector2(-5,-5)]),Color("9cfff0"))
	var x=area.end.x+18
	_text(Vector2(x,area.position.y+12),"Beispiel: X 4 · Y C",14,Color("ffd27a"))
	_text(Vector2(x,area.position.y+36),"Spalten = Zahlen (X)",13,Color("e2ecee"))
	_text(Vector2(x,area.position.y+56),"Zeilen = Buchstaben (Y)",13,Color("e2ecee"))
	_text(Vector2(x,area.position.y+76),"1 Quadrat = %d m" % roundi(MINI.SQUARE),13,Color("e2ecee"))
	_text(Vector2(x,area.position.y+104),"Minikarte oben: (1-1) X: 4 Y: C",12,Color("80e3dc"))

func _legend() -> void:
	var entries=[["player","Dein Schiff · Spitze = Fahrtrichtung"],["neutral","Neutrales Schiff"],["hostile","Feindlich oder im Kampf"],["monster","Seeungeheuer"],
		["tower","Festungsturm · grün = deine Gilde"],["edge","Kartenrand · Nachbarkarte"],["harbor","Hafen · andocken"],["sparkle","Glitzernde Strömung · Essenz"],["staff","Spielteam · offizieller Staff"]]
	var columns=2 if size.x>520 else 1
	var per=ceili(float(entries.size())/columns)
	var col_w=size.x/columns
	for i in entries.size():
		var c=floori(float(i)/per);var row=i%per
		var at=Vector2(18+c*col_w,22+row*30)
		_mark(entries[i][0],at)
		_text(at+Vector2(18,5),entries[i][1],13,Color("e2ecee"))

func _mark(kind: String,p: Vector2) -> void:
	match kind:
		"player":draw_colored_polygon(PackedVector2Array([p+Vector2(7,0),p+Vector2(-5,5),p+Vector2(-5,-5)]),Color("9cfff0"))
		"neutral":draw_circle(p,4,Color("f0c35a"))
		"hostile":draw_circle(p,4,Color("ff6d5c"))
		"monster":draw_circle(p,4,Color("d39cf0"))
		"tower":
			draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),Color("ff8a4c"))
			draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),Color("1a0c04"),false,1)
		"edge":draw_line(p-Vector2(7,0),p+Vector2(7,0),Color("6ad7d2"),2.0,true)
		"harbor":
			draw_circle(p,4.5,Color("f4c56c"));draw_circle(p,4.5,Color("2a1a08"),false,1,true)
		"sparkle":draw_circle(p,3,Color("7ff5e6"))
		"staff":
			draw_circle(p,8,Color(Color("ff6a4d"),.22));draw_arc(p,8,0,TAU,20,Color("ff6a4d"),1.4,true)
			draw_colored_polygon(PackedVector2Array([p+Vector2(5,0),p+Vector2(-4,4),p+Vector2(-4,-4)]),Color("9cfff0"))

func _colors() -> void:
	var entries=[[Color("f1e6cc"),"Neutral · greift erst nach deinem Angriff an"],[Color("ff9d8a"),"Feindlich · greift in der Nähe an"],[Color("ffd98a"),"Elite-Schiff · mehr Rumpf und Schild"],
		[Color("e4b6ee"),"Seeungeheuer · nur Harpunen"]]
	for i in entries.size():
		var y=24+i*27
		draw_rect(Rect2(18,y-9,26,10),entries[i][0])
		_text(Vector2(54,y),entries[i][1],13,Color("e2ecee"))
	var badge_x=18.0
	var y=24+entries.size()*27
	for role in [["ADM",Color("ff6a4d")],["GM",Color("ffc04d")],["MOD",Color("4fc3ff")],["QA",Color("7be07b")]]:
		badge_x+=SEA_MARKS.staff_badge(self,Vector2(badge_x,y-4),role[0],role[1],font,11)+6
	_text(Vector2(badge_x+6,y),"Abzeichen des Spielteams",13,Color("e2ecee"))

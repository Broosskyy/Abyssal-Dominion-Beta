extends RefCounted
## Shared menu skins: bevelled buttons, item cards, icon frames and tabs.
const BEVEL = preload("res://bevel_style.gd")
const GOLD := Color("dcc18a")
## variant -> state -> [top, bottom, rim]
const BUTTONS := {
	"normal":{"normal":["21424e","0d1d24","8a6d40"],"hover":["2b5462","10262e","e2c17c"],"pressed":["0d1d24","1b3843","f5d78d"],"disabled":["121d22","0a1317","4a4234"]},
	"primary":{"normal":["e2b867","8f5f20","fff0c2"],"hover":["f2ca7a","a06c26","ffffff"],"pressed":["8f5f20","c99448","fff0c2"],"disabled":["4a4030","2c251a","6b5c42"]},
	"danger":{"normal":["8a3426","42150e","e7957a"],"hover":["a2402f","531b12","ffc0a8"],"pressed":["42150e","7a2c20","ffc0a8"],"disabled":["2c1a17","1b0f0c","5a3a32"]},
	"staff":{"normal":["5a2a6e","241032","d0a0ff"],"hover":["6c3484","2c143c","f0d8ff"],"pressed":["241032","4c2460","f0d8ff"],"disabled":["241a2a","15101a","4a3a52"]},
	"tab":{"normal":["1a2c33","0b161b","5e4d33"],"hover":["24404a","0e1e24","b8955a"],"pressed":["0b161b","1a2c33","dcc18a"],"disabled":["11191d","0a1013","3a342a"]},
	"tab_on":{"normal":["3b5f69","15303a","f5d78d"],"hover":["3b5f69","15303a","f5d78d"],"pressed":["3b5f69","15303a","f5d78d"],"disabled":["3b5f69","15303a","f5d78d"]},
	"close":{"normal":["8a3426","3d120c","f0c87a"],"hover":["a8402f","4f1912","fff0c2"],"pressed":["3d120c","8a3426","fff0c2"],"disabled":["2c1a17","1b0f0c","5a3a32"]}
}
const TEXT := {"primary":Color("2a1606"),"tab":Color("c9b38a"),"tab_on":Color("fff0c8"),"close":Color("fff0c8")}

static func bevel(top: Color,bottom: Color,rim: Color,radius: float=6.0,margin: float=8.0) -> StyleBox:
	var style=BEVEL.new()
	style.top=top;style.bottom=bottom;style.border=rim;style.radius=radius
	style.content_margin_left=margin+2;style.content_margin_right=margin+2
	style.content_margin_top=margin*.6;style.content_margin_bottom=margin*.6
	return style

static func dress(button: Button,variant: String="normal",radius: float=6.0) -> void:
	var palette: Dictionary=BUTTONS.get(variant,BUTTONS.normal)
	for state in ["normal","hover","pressed","disabled"]:
		var tones: Array=palette[state]
		var style=bevel(Color(tones[0]),Color(tones[1]),Color(tones[2]),radius,6.0)
		if variant=="close":style.radius=radius;style.sheen=.28
		if state=="hover":style.glow=Color(tones[2])
		if state=="pressed":style.sheen=.05;style.shadow=.2
		if state=="disabled":style.sheen=.04;style.shadow=.2
		if variant=="primary":style.inner=Color(1,.95,.75,.35)
		if variant in ["tab","tab_on"]:style.shadow=.25
		if variant=="tab_on":style.glow=Color("f5d78d",.6);style.inner=Color(1,1,1,.12)
		button.add_theme_stylebox_override(state,style)
		if state=="pressed":button.add_theme_stylebox_override("hover_pressed",style)
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	var ink: Color=TEXT.get(variant,Color("f3e0b6"))
	for key in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:button.add_theme_color_override(key,ink)
	button.add_theme_color_override("font_disabled_color",Color("6f6450") if variant!="primary" else Color("8c7a58"))
	var dark=variant in ["primary"]
	button.add_theme_color_override("font_outline_color",Color(1,.94,.78,.35) if dark else Color("061016"))
	button.add_theme_constant_override("outline_size",0 if dark else 3)

static func card(accent: Color=Color(0,0,0,0),margin: float=10.0) -> StyleBox:
	var style=bevel(Color("142a33"),Color("0a161c"),Color("6b5634"),8.0,margin)
	style.content_margin_left=margin+(4 if accent.a>0 else 0);style.content_margin_right=margin
	style.content_margin_top=margin;style.content_margin_bottom=margin
	style.sheen=.07;style.shadow=.4;style.inner=Color(1,.9,.6,.07);style.accent=accent
	return style

## Restrained gallery stage for real ship/equipment art.
## Shared by Market, Decks, Talents and Castles without extra textures.
# Banner-grade header for the main game systems. This prominent, wide
# illustrated surface replaces the tiny icon-and-text info rows.
static func feature_banner(rim: Color=Color("c9a35e")) -> StyleBox:
	var style=bevel(Color("234e59"),Color("061922"),rim,14.0,13.0)
	style.sheen=.25
	style.shadow=.62
	style.inner=Color(1,.95,.65,.19)
	style.accent=rim
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=12
	style.content_margin_bottom=12
	return style

static func catalog_art(rim: Color=Color("b08a4c")) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=Color("103442")
	style.border_color=Color(rim.r,rim.g,rim.b,.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left=8
	style.content_margin_right=8
	style.content_margin_top=8
	style.content_margin_bottom=8
	style.shadow_color=Color(0,0,0,.28)
	style.shadow_size=3
	return style

static func icon_frame(rim: Color=Color("b08a4c")) -> StyleBox:
	var style=bevel(Color("27434c"),Color("09141a"),rim,10.0,4.0)
	style.content_margin_left=4;style.content_margin_right=4;style.content_margin_top=4;style.content_margin_bottom=4
	style.sheen=.12;style.inner=Color(0,0,0,.5)
	return style

static func note() -> StyleBox:
	var style=bevel(Color("0e2028"),Color("0a171d"),Color("3c4a48"),6.0,9.0)
	style.content_margin_left=12;style.sheen=0.0;style.shadow=.25;style.accent=Color("6f8f8c",.8)
	return style

static func scrollbar(bar: ScrollBar) -> void:
	if bar is HScrollBar:bar.custom_minimum_size.y=8
	else:bar.custom_minimum_size.x=12
	var track=StyleBoxFlat.new();track.bg_color=Color(.02,.06,.08,.85);track.set_corner_radius_all(6)
	track.border_color=Color("4f4130");track.set_border_width_all(1);track.content_margin_left=5;track.content_margin_right=5
	bar.add_theme_stylebox_override("scroll",track);bar.add_theme_stylebox_override("scroll_focus",track)
	for entry in [["grabber","b8914f"],["grabber_highlight","e2c17c"],["grabber_pressed","f5d78d"]]:
		var grab=StyleBoxFlat.new();grab.bg_color=Color(entry[1]);grab.set_corner_radius_all(5)
		grab.border_color=Color("3a2810");grab.set_border_width_all(1)
		bar.add_theme_stylebox_override(entry[0],grab)

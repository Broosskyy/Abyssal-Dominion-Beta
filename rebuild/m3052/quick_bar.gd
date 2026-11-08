extends Control
signal used(slot: int)
signal page_picked(page: int)
signal configure
var host
var tabs: Array[Button]=[]
var slots: Array[Button]=[]
var edit: Button
func _ready() -> void:
	for page in 3:
		var index: int=page
		var button=Button.new();button.text=str(page+1);button.focus_mode=Control.FOCUS_NONE
		host.SKIN.dress(button,"tab");button.pressed.connect(func():page_picked.emit(index));add_child(button);tabs.append(button)
	edit=Button.new();edit.text="⚙";edit.tooltip_text="Schnellleiste selbst belegen";edit.focus_mode=Control.FOCUS_NONE
	host.SKIN.dress(edit,"normal");edit.pressed.connect(func():configure.emit());add_child(edit)
	for slot in 3:
		var index: int=slot
		var button=host._orb(self,"",null,func():used.emit(index),"")
		slots.append(button)
	resized.connect(_layout);_layout()
func _layout() -> void:
	if edit==null:return
	var side: float=(size.x-16.0)/3.0
	for i in 3:
		tabs[i].position=Vector2(i*(size.x-32)/3.0,0);tabs[i].size=Vector2((size.x-32)/3.0-3,25)
		slots[i].position=Vector2(i*(side+8),29);slots[i].size=Vector2(side,side)
	edit.position=Vector2(size.x-28,0);edit.size=Vector2(28,25)
func refresh() -> void:
	if slots.size()!=3:return
	for i in 3:
		tabs[i].modulate=Color("ffd27a") if host.quick_page==i else Color("abb9bd")
		var key: String=host.quick_pages[host.quick_page][i]
		var config: Dictionary=host.CONTENT.SUPPLIES[key]
		var wait: float=float(host.sim.cooldowns.get(key,0))
		var active: bool=(key=="powder" and host.sim.powder_on) or (key=="plates" and host.sim.plates_on)
		host._set_orb(slots[i],host._supply_icon(key),str(host.sim.supplies[key]),active,str(config.short))
		slots[i].set("cooldown",wait/maxf(1.0,float(config.get("cooldown",1))))
		slots[i].set("state_label",str(ceili(wait))+" s" if wait>0 else ("AKTIV" if active else ""))
		slots[i].tooltip_text=str(config.name)+" · "+str(config.effect)
		slots[i].disabled=host.sim.docked or int(host.sim.player.hp)<=0 or wait>0 or (int(host.sim.supplies[key])<=0 and not active)

class_name M159ShipExtensionVisuals
extends Node3D
## Visual-only deck stack + blessing presentation. Gameplay authority stays in inventory/server contracts.
var ship:ShipMotor
var deck_root:Node3D
var aura_root:Node3D
var special_deck_root:Node3D
var cannon_mastery_root:Node3D
var equipment_root:Node3D
var pulse:=0.0

func _ready()->void:
	ship=get_parent() as ShipMotor
	deck_root=Node3D.new();deck_root.name="VisibleDeckStack";add_child(deck_root)
	aura_root=Node3D.new();aura_root.name="BlessingVFX";add_child(aura_root)
	special_deck_root=Node3D.new();special_deck_root.name="SpecialDeckVFX";add_child(special_deck_root)
	cannon_mastery_root=Node3D.new();cannon_mastery_root.name="CannonMasteryVFX";add_child(cannon_mastery_root)
	equipment_root=Node3D.new();equipment_root.name="M207VisibleShipEquipment";add_child(equipment_root)
	_rebuild_decks();_rebuild_aura();_rebuild_special_deck_vfx();_rebuild_cannon_mastery();_rebuild_visible_equipment()
	var inv:=ship.get_node_or_null("Inventory") as PlayerInventory
	if inv!=null:inv.inventory_changed.connect(_sync)
	var progression:=ship.get_node_or_null("Progression") as PlayerProgression
	if progression!=null:progression.progression_changed.connect(_sync)

func _process(delta:float)->void:
	pulse+=delta
	if bool(ship.get_meta("crystal_blessing_active",false)) and Time.get_ticks_msec()/1000.0>=float(ship.get_meta("crystal_blessing_until",0.0)):
		ship.set_meta("crystal_blessing_active",false);_rebuild_aura()
	if aura_root.visible:
		aura_root.rotation.y+=delta*0.55
		var s:=1.0+sin(pulse*3.0)*0.06;aura_root.scale=Vector3(s,1.0,s)
	if special_deck_root.visible:
		special_deck_root.rotation.y-=delta*0.18
		var ds:=1.0+sin(pulse*1.8)*0.035;special_deck_root.scale=Vector3(ds,1.0,ds)

func _sync()->void:_rebuild_decks();_rebuild_aura();_rebuild_special_deck_vfx();_rebuild_cannon_mastery();_rebuild_visible_equipment()
func _clear(root:Node)->void:
	for child in root.get_children():child.queue_free()

func _rebuild_decks()->void:
	_clear(deck_root)
	var inv:=ship.get_node_or_null("Inventory") as PlayerInventory
	if inv==null:return
	var count:=clampi(inv.deck_level(),0,10)
	var wood:=StandardMaterial3D.new();wood.albedo_color=Color("60462f");wood.roughness=0.74
	var edge:=StandardMaterial3D.new();edge.albedo_color=Color("a77a3f");edge.metallic=0.24;edge.roughness=0.48
	var dark:=StandardMaterial3D.new();dark.albedo_color=Color("2b211a");dark.roughness=0.82
	for i in range(count):
		var layer_root:=Node3D.new();layer_root.name="M206DeckLayer_%02d"%(i+1);deck_root.add_child(layer_root)
		var y:=-0.43-(float(i)*0.072)
		var plate:=MeshInstance3D.new();plate.name="DeckPlate"
		var plate_mesh:=BoxMesh.new();plate_mesh.size=Vector3(2.50-float(i)*0.018,0.050,5.30-float(i)*0.020);plate.mesh=plate_mesh;plate.position=Vector3(0,y,-0.06);plate.material_override=wood;plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;layer_root.add_child(plate)
		for side in [-1.0,1.0]:
			var rail:=MeshInstance3D.new();rail.name="DeckRailPort" if side<0 else "DeckRailStarboard"
			var rail_mesh:=BoxMesh.new();rail_mesh.size=Vector3(0.11,0.065,4.92);rail.mesh=rail_mesh;rail.position=Vector3(side*(1.26-float(i)*0.008),y-0.012,-0.04);rail.material_override=edge;rail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;layer_root.add_child(rail)
		var keel:=MeshInstance3D.new();keel.name="DeckKeel"
		var keel_mesh:=BoxMesh.new();keel_mesh.size=Vector3(0.16,0.072,5.54);keel.mesh=keel_mesh;keel.position=Vector3(0,y-0.025,-0.06);keel.material_override=dark;keel.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;layer_root.add_child(keel)
		if i%2==1 or i==9:
			for z in [-1.65,0.0,1.65]:
				var brace:=MeshInstance3D.new();brace.name="DeckBrace"
				var brace_mesh:=BoxMesh.new();brace_mesh.size=Vector3(2.62-float(i)*0.014,0.032,0.10);brace.mesh=brace_mesh;brace.position=Vector3(0,y-0.046,z);brace.material_override=edge;brace.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;layer_root.add_child(brace)
		layer_root.set_meta("visual_only",true);layer_root.set_meta("m206_under_ship_deck",true);layer_root.set_meta("deck_level",i+1)
	deck_root.set_meta("visible_decks",count);deck_root.set_meta("visual_only",true);deck_root.set_meta("m206_progressive_under_ship_stack",true)

func _rebuild_aura()->void:
	_clear(aura_root)
	var active:=bool(ship.get_meta("crystal_blessing_active",false));aura_root.visible=active
	if not active:return
	for i in range(8):
		var crystal:=MeshInstance3D.new();var mesh:=PrismMesh.new();mesh.size=Vector3(0.12,0.45,0.12);crystal.mesh=mesh
		var a:=TAU*float(i)/8.0;crystal.position=Vector3(cos(a)*2.1,0.55+0.12*(i%2),sin(a)*2.1)
		crystal.rotation_degrees=Vector3(0,rad_to_deg(-a),0)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color("69d9ff");mat.emission_enabled=true;mat.emission=Color("4abcf5");mat.emission_energy_multiplier=1.7;crystal.material_override=mat
		crystal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;aura_root.add_child(crystal)
	var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=1.95;torus.outer_radius=2.03;ring.mesh=torus;ring.position.y=0.08
	var rm:=StandardMaterial3D.new();rm.albedo_color=Color(0.25,0.8,1.0,0.55);rm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;rm.emission_enabled=true;rm.emission=Color("3cc9ff");rm.emission_energy_multiplier=1.2;ring.material_override=rm;aura_root.add_child(ring)

func _rebuild_special_deck_vfx()->void:
	_clear(special_deck_root)
	var inv:=ship.get_node_or_null("Inventory") as PlayerInventory
	var cat:=get_tree().get_first_node_in_group("m162_system_catalog") as M162SystemCatalog
	if inv==null or cat==null:special_deck_root.visible=false;return
	var id:=inv.equipped_special_deck();var row:=cat.definition("special_decks",id)
	if id.is_empty() or row.is_empty():special_deck_root.visible=false;return
	special_deck_root.visible=true
	var color:=Color(str(row.get("vfx_color","65bde8")))
	# M206: the equipped special deck is readable as a physical visual layer below the normal deck stack.
	var normal_count:=clampi(inv.deck_level(),0,10)
	var special_plate:=MeshInstance3D.new();special_plate.name="M206SpecialDeckPlate"
	var special_mesh:=BoxMesh.new();special_mesh.size=Vector3(2.72,0.075,5.72);special_plate.mesh=special_mesh;special_plate.position=Vector3(0,-0.50-float(normal_count)*0.072,-0.05)
	var special_mat:=StandardMaterial3D.new();special_mat.albedo_color=Color(color.r*0.36,color.g*0.36,color.b*0.36,0.92);special_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;special_mat.metallic=0.28;special_mat.roughness=0.48;special_mat.emission_enabled=true;special_mat.emission=color;special_mat.emission_energy_multiplier=0.24
	special_plate.material_override=special_mat;special_plate.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;special_plate.set_meta("visual_only",true);special_plate.set_meta("m206_special_deck_under_ship",true);special_deck_root.add_child(special_plate)
	for side in [-1.0,1.0]:
		var fin:=MeshInstance3D.new();fin.name="M206SpecialDeckRail"
		var fin_mesh:=BoxMesh.new();fin_mesh.size=Vector3(0.12,0.10,5.05);fin.mesh=fin_mesh;fin.position=Vector3(side*1.38,special_plate.position.y-0.015,-0.04);fin.material_override=special_mat;fin.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;fin.set_meta("visual_only",true);special_deck_root.add_child(fin)
	var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=2.32;torus.outer_radius=2.38;ring.mesh=torus;ring.position.y=-0.22
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(color.r,color.g,color.b,0.34);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=0.75;ring.material_override=mat;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;special_deck_root.add_child(ring)
	for i in range(4):
		var mark:=MeshInstance3D.new();var mesh:=PrismMesh.new();mesh.size=Vector3(0.08,0.18,0.3);mark.mesh=mesh;var a:=TAU*float(i)/4.0;mark.position=Vector3(cos(a)*2.35,0.0,sin(a)*2.35);mark.material_override=mat;mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;special_deck_root.add_child(mark)
	special_deck_root.set_meta("profile",str(row.get("vfx_profile","")))
	special_deck_root.set_meta("visual_only",true)

func _rebuild_cannon_mastery()->void:
	_clear(cannon_mastery_root)
	var inv:=ship.get_node_or_null("Inventory") as PlayerInventory
	if inv==null:return
	var tracks:=["barrel","carriage","chamber","runes"]
	var total:=0
	for id in tracks:total+=inv.cannon_track_level(id)
	var stage:=0
	if total>=4:stage=1
	if total>=12:stage=2
	if total>=20:stage=3
	if total>=30:stage=4
	if total>=40:stage=5
	cannon_mastery_root.visible=stage>0
	if stage<=0:return
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("c4934d");mat.metallic=0.65;mat.roughness=0.34
	if stage>=4:
		mat.emission_enabled=true;mat.emission=Color("ffc66d");mat.emission_energy_multiplier=0.45 if stage==4 else 0.9
	for i in range(stage*2):
		var marker:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(0.13,0.10,0.42);marker.mesh=mesh
		var side:=-1.0 if i%2==0 else 1.0;var row:=float(i/2);marker.position=Vector3(side*(1.13+0.05*row),0.18,-1.15+row*0.62);marker.material_override=mat;marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;cannon_mastery_root.add_child(marker)
	cannon_mastery_root.set_meta("mastery_total",total);cannon_mastery_root.set_meta("visual_stage",stage);cannon_mastery_root.set_meta("visual_only",true)


func _visual_material(color:Color,metallic:float=0.3,roughness:float=0.48,emission:float=0.0)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.metallic=metallic;mat.roughness=roughness
	if emission>0.0:
		mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=emission
	return mat

func _box_marker(parent:Node3D,name_value:String,size_value:Vector3,pos:Vector3,mat:Material)->MeshInstance3D:
	var marker:=MeshInstance3D.new();marker.name=name_value
	var mesh:=BoxMesh.new();mesh.size=size_value;marker.mesh=mesh;marker.position=pos;marker.material_override=mat
	marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;marker.set_meta("visual_only",true);parent.add_child(marker);return marker

func _cylinder_marker(parent:Node3D,name_value:String,radius:float,height:float,pos:Vector3,rotation:Vector3,mat:Material)->MeshInstance3D:
	var marker:=MeshInstance3D.new();marker.name=name_value
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;marker.mesh=mesh;marker.position=pos;marker.rotation_degrees=rotation;marker.material_override=mat
	marker.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;marker.set_meta("visual_only",true);parent.add_child(marker);return marker

func _rebuild_visible_equipment()->void:
	_clear(equipment_root)
	var progression:=ship.get_node_or_null("Progression") as PlayerProgression
	var inv:=ship.get_node_or_null("Inventory") as PlayerInventory
	if progression==null or inv==null:return
	var hull_level:=int(progression.upgrades.get("hull",0));var cannon_level:=int(progression.upgrades.get("cannon",0));var sail_level:=int(progression.upgrades.get("sails",0))
	var hull_stage:=M207ShipEquipmentStageCatalog.stage_for_level(hull_level);var cannon_stage:=M207ShipEquipmentStageCatalog.stage_for_level(cannon_level);var sail_stage:=M207ShipEquipmentStageCatalog.stage_for_level(sail_level)
	var metal:=_visual_material(Color("7c8587"),0.66,0.31);var gold:=_visual_material(Color("c4934d"),0.58,0.36);var dark:=_visual_material(Color("26343a"),0.42,0.47);var sail:=_visual_material(Color("b9b29f"),0.05,0.88)
	# M207 hull armor: representative visual bands only. Authoritative collision remains wrapper-owned.
	if hull_stage>0:
		for side in [-1.0,1.0]:
			for row in range(hull_stage+1):
				var z:=-1.55+float(row)*(3.1/maxf(1.0,float(hull_stage)))
				_box_marker(equipment_root,"M207HullArmor",Vector3(0.09,0.20+0.025*hull_stage,0.62),Vector3(side*1.37,-0.04,z),metal)
	# M207 representative cannon battery. Projectile origins and broadside math remain in ShipWeapons.
	if cannon_stage>0:
		for side in [-1.0,1.0]:
			for row in range(cannon_stage+1):
				var z:=-1.55+float(row)*(3.1/maxf(1.0,float(cannon_stage)))
				_cylinder_marker(equipment_root,"M207CannonBattery",0.065,0.48,Vector3(side*1.46,0.24,z),Vector3(0,0,90),dark)
				_box_marker(equipment_root,"M207CannonCarriage",Vector3(0.18,0.10,0.24),Vector3(side*1.30,0.20,z),gold)
	# M207 sail/rigging stage is deliberately sparse so it does not hide authored hull silhouettes.
	if sail_stage>0:
		var mast_height:=1.70+float(sail_stage)*0.13
		_cylinder_marker(equipment_root,"M207RigMast",0.055,mast_height,Vector3(0,0.60,0.18),Vector3.ZERO,gold)
		for side in [-1.0,1.0]:
			var panel:=_box_marker(equipment_root,"M207SailReinforcement",Vector3(0.035,0.58+0.08*sail_stage,0.72+0.08*sail_stage),Vector3(side*0.35,0.72,0.18),sail)
			panel.rotation_degrees=Vector3(0,0,side*8.0)
	# Selected harpoon receives a small bow rack so monster-hunter loadouts read on the world model.
	var harpoon_id:=inv.selected_harpoon()
	if not harpoon_id.is_empty():
		_box_marker(equipment_root,"M207HarpoonRack",Vector3(0.58,0.13,0.40),Vector3(0,0.27,2.12),gold)
		for side in [-1.0,1.0]:_cylinder_marker(equipment_root,"M207HarpoonSpear",0.035,0.88,Vector3(side*0.17,0.34,2.42),Vector3(90,0,0),metal)
	# Ram is a presentation hint at high hull investment; no collision or damage authority is attached.
	if hull_stage>=4:
		var ram:=_box_marker(equipment_root,"M207BowRam",Vector3(0.26,0.20,0.92+0.12*(hull_stage-4)),Vector3(0,-0.03,2.86),metal);ram.rotation_degrees.x=-8.0
	equipment_root.set_meta("visual_only",true);equipment_root.set_meta("m207_equipment_silhouette",true);equipment_root.set_meta("collision_authority",false)
	equipment_root.set_meta("hull_stage",hull_stage);equipment_root.set_meta("cannon_stage",cannon_stage);equipment_root.set_meta("sail_stage",sail_stage);equipment_root.set_meta("selected_harpoon",harpoon_id)

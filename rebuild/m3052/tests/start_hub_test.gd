extends SceneTree
# Signed-pack regression for the new responsive captain home and social hub.
var failures: Array[String]=[]
var checks: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sim_class=load("res://simulation.gd")
	var mock=sim_class.new()
	var day_stamp: int=199999*86400+123
	var gold_before: int=int(mock.player.gold)
	var essence_before: int=mock.essence
	check(mock.rewards.daily_available(day_stamp),"daily reward is initially claimable")
	check(mock.rewards.claim_daily(mock,day_stamp),"first daily reward is claimable exactly once")
	check(int(mock.player.gold)==gold_before+150 and mock.essence==essence_before+1 and mock.rewards.streak==1,"day one deposits real 150 gold and 1 essence")
	var repeat_claim: bool=mock.rewards.claim_daily(mock,day_stamp+600)
	check(not repeat_claim,"same UTC day cannot duplicate daily reward")
	check(int(mock.player.gold)==gold_before+150,"repeating a claim must not change the gold balance")
	check(mock.rewards.claim_daily(mock,day_stamp+86400) and mock.rewards.streak==2,"next UTC day extends consecutive streak")
	var old_save: Dictionary=mock.rewards.snapshot(day_stamp+86400)
	var restored=sim_class.new()
	restored.rewards.restore(old_save,day_stamp+86400+200)
	var restored_claim=restored.rewards.claim_daily(restored,day_stamp+86400+300)
	check(not restored_claim,"restored reward ledger never pays again after reload")
	check(mock.rewards.claim_daily(mock,day_stamp+3*86400) and mock.rewards.streak==1,"missing a day resets daily reward streak")
	root.size=Vector2i(2340,1080)
	var hub=load("res://start_hub.tscn").instantiate()
	root.add_child(hub)
	current_scene=hub
	await process_frame
	hub._enter_home()
	await process_frame
	check(hub.page=="home" and hub.body.find_child("SailButton",true,false)!=null,"captain opens functional home with prominent Play button")
	check(hub.body.find_child("FeaturedNews",true,false)!=null and hub.body.find_child("FeaturedArtwork",true,false)!=null,"home features illustrated carousel with existing game artwork")
	check(hub.body.find_children("HomeActionCard*","PanelContainer",true,false).size()==9,"home has 3 illustrated news teasers and 6 active menu cards rather than a wall of 12")
	check(hub.body.find_child("HubTab_friends",true,false)!=null and hub.body.find_child("HubTab_logbook",true,false)!=null,"home provides navigation to friends and logbook")
	var hero: Node=hub.body.find_child("FeaturedNews",true,false)
	var sail: Node=hub.body.find_child("SailButton",true,false)
	check(hub.body.get_children().find(hero)<hub.body.get_children().find(sail),"featured sea-MMO artwork comes before Play and dense navigation on the start screen")
	check(hub.body.find_child("FeaturedAction",true,false)!=null and hub.featured_action.text=="WELTKARTE ÖFFNEN","hero action is tied to visible feature, not a generic start button")
	check(hub._invite_text().contains("github.com/Broosskyy"),"home invite remains a grounded public beta link")
	var before: String=hub.featured_title.text
	hub._featured_shift(1)
	check(hub.featured_index==1 and hub.featured_title.text!=before,"news slide controls change actual visual and text")
	check(hub.featured_action.text=="ZUR WERFT" and str(hub.NEWS_FRAMES[hub.featured_index].action)=="Werft","featured Werft slide opens the real shipyard")
	hub._featured_shift(1)
	check(hub.featured_action.text=="BONUSKARTEN ÖFFNEN" and str(hub.NEWS_FRAMES[hub.featured_index].action)=="Bonuskarten","feature carousel links to Bonuskarten rather than always starting open sea")
	hub._switch_home_section("SCHIFF & HANDEL")
	check(hub.home_section=="SCHIFF & HANDEL" and hub.body.find_children("HomeActionCard*","PanelContainer",true,false).size()==9,"ship/market/decks/castles are one compact home category")
	hub._switch_home_section("KAPITÄN & BONUS")
	check(hub.home_section=="KAPITÄN & BONUS" and hub.body.find_child("HomeDailyButton",true,false)!=null,"captain tab and daily shortcut are accessible without scrolling through 12 menus")
	hub._switch_home_section("ABENTEUER")
	var wide_bounds: Rect2=hub.panel.get_global_rect()
	check(wide_bounds.position.x>0 and wide_bounds.end.x<2340 and wide_bounds.size.x>1100,"home uses large centered desktop/landscape view with safe margins")
	root.size=Vector2i(720,1280)
	await process_frame
	hub._layout()
	var narrow_bounds: Rect2=hub.panel.get_global_rect()
	check(narrow_bounds.position.x>=0 and narrow_bounds.end.x<=720 and narrow_bounds.end.y<=1280,"home dashboard fits phone portrait margins: "+str(narrow_bounds))
	check(hub.body.find_child("HomeNavigationScroller",true,false)!=null and hub.body.find_child("HomeNavigationScroller",true,false).size.x>0,"portrait has visible swipeable home navigation")
	check(hub.body.find_child("FeaturedNews",true,false)!=null and hub.body.find_child("HomeDailyButton",true,false)!=null,"mobile home retains feature card and daily reward entry")
	root.size=Vector2i(480,900)
	await process_frame
	hub._layout()
	check(hub.panel.get_global_rect().end.x<=480 and hub.panel.get_global_rect().end.y<=900,"narrow phone home fits safely without horizontal clipping")
	hub._show("rewards")
	await process_frame
	check(hub.body.find_child("DailyDay1",true,false)!=null and hub.body.find_child("DailyDay7",true,false)!=null,"daily calendar has all seven real bonus day tiles")
	var claim: Button=hub.body.find_child("DailyClaim",true,false) as Button
	check(claim!=null and not claim.disabled,"daily claim action is accessible to fresh captain")
	var amount: int=int(hub.sim.player.gold)
	if claim!=null and not claim.disabled:claim.pressed.emit()
	check(int(hub.sim.player.gold)==amount+150 and hub.sim.rewards.streak==1,"home daily claim writes to real player inventory")
	var repeated: Button=hub.body.find_child("DailyClaim",true,false) as Button
	check(repeated!=null and repeated.disabled and int(hub.sim.player.gold)==amount+150,"home disables repeated same-day claim")
	hub._show("friends")
	check(hub.body.find_child("InviteCopy",true,false)!=null,"friends page has a working copy invitation control")
	check(hub._invite_text().contains("github.com/Broosskyy/Abyssal-Dominion-Beta/releases"),"invitation points to a real public download page")
	var disabled_friends: bool=false
	for button: Button in hub.body.find_children("*","Button",true,false):
		if button.text.contains("FREUNDESLISTE"):disabled_friends=button.disabled
	check(disabled_friends,"online-only friends list is not falsely active in offline beta")
	hub._show("logbook")
	check(hub.body.find_child("SailButton",true,false)==null,"logbook doesn't accidentally duplicate game launch button")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

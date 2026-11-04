class_name VoyageProgress
extends Node
## M32 beginner map progression; local tuning, not recovered server rules.
signal changed
const TRIAL_GOALS := BeginnerRules.GOALS
var completed_trials := 0
var trial_active := false
var trial_passed := false
var trial_counts := {"sink": 0, "loot": 0, "dock": 0}
var legacy_access := false
var event_seconds := 0.0
var event_tokens := 0
var event_cooldown := 0.0
var advanced_map_level := BeginnerRules.ELITE_MAP_LEVEL

func beginner_trial_goals()->Dictionary:return GameplayRuleset.dictionary(get_tree(),"beginner_trial.goals",TRIAL_GOALS)
func beginner_trial_reward()->Dictionary:return GameplayRuleset.dictionary(get_tree(),"beginner_trial.reward",{"gold":BeginnerRules.REWARD_COINS,"xp":BeginnerRules.REWARD_XP})
func _ready() -> void:
	(get_parent().get_node("Health") as ShipHealth).ship_sunk.connect(_on_sunk)

func _process(delta: float) -> void:
	var before := ceili(event_seconds)
	event_seconds = maxf(0, event_seconds - delta)
	event_cooldown = maxf(0, event_cooldown - delta)
	if before != ceili(event_seconds): changed.emit()

func start_trial() -> bool:
	var ship := get_parent() as ShipMotor
	var inventory := ship.get_node("Inventory") as PlayerInventory
	if trial_active or beginner_complete() or not inventory.at_port(): return false
	if (ship.get_node("Health") as ShipHealth).is_sunk: return false
	trial_counts = {"sink": 0, "loot": 0, "dock": 0}
	trial_active = true
	changed.emit()
	return true

func record(kind: String) -> void:
	if trial_active and trial_counts.has(kind):
		# Combat/salvage must happen in this assignment's map tier. A port in
		# any unlocked tier can receive the return visit (tiers 2/5 have no port).
		var world := get_tree().get_first_node_in_group("world_map") as WorldMapSystem
		var valid := world != null and world.current_map_level() == map_level()
		if kind == "dock":
			valid = trial_counts.sink >= int(beginner_trial_goals().get("sink",1)) and trial_counts.loot >= int(beginner_trial_goals().get("loot",1)) and (get_parent().get_node("Inventory") as PlayerInventory).at_port()
		if valid: trial_counts[kind] = mini(int(beginner_trial_goals().get(kind,1)),int(trial_counts[kind])+1)
	if event_seconds > 0:
		var token_rewards:=GameplayRuleset.dictionary(get_tree(),"beginner_trial.event_token_rewards",{"sink":10,"loot":5,"dock":0})
		event_tokens=mini(999999,event_tokens+int(token_rewards.get(kind,0)))
	changed.emit()

func trial_ready() -> bool:
	if not trial_active: return false
	for kind in beginner_trial_goals():
		if int(trial_counts.get(kind,0))<int(beginner_trial_goals()[kind]): return false
	return true

func claim_trial() -> bool:
	if not trial_ready() or beginner_complete() or not (get_parent().get_node("Inventory") as PlayerInventory).at_port(): return false
	if (get_parent().get_node("Health") as ShipHealth).is_sunk: return false
	completed_trials += 1
	trial_passed = true
	trial_active = false
	(get_parent() as ShipMotor).set_meta("trial_completion_feedback_until", Time.get_ticks_msec() / 1000.0 + 4.0)
	trial_counts = {"sink": 0, "loot": 0, "dock": 0}
	(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_earned_starters()
	var progression := get_parent().get_node("Progression") as PlayerProgression
	var services:=ServiceLocator.from(get_tree())
	var reward:=beginner_trial_reward()
	var gold:=int(reward.get("gold",BeginnerRules.REWARD_COINS));var reward_xp:=int(reward.get("xp",BeginnerRules.REWARD_XP))
	if services!=null and services.rewards!=null:
		services.rewards.apply(RewardBundleService.bundle("beginner_trial:"+str(completed_trials),"beginner_trial",gold,reward_xp))
	else:
		progression.add_coins(gold);progression.add_xp(reward_xp)
	changed.emit()
	return true

func can_enter(sector: Vector2i) -> bool:
	var row:=WorldSectorRegistry.by_coord(sector)
	if row.is_empty():return false
	return legacy_access or int(row.get("pirate_level",999))<=map_level()

func map_level() -> int:
	if beginner_complete():
		return maxi(BeginnerRules.ELITE_MAP_LEVEL, advanced_map_level)
	return completed_trials + 1


func record_post_beginner_boss(defeated_map_level: int) -> String:
	if not beginner_complete(): return ""
	if defeated_map_level != advanced_map_level: return ""
	if defeated_map_level in [10,15,20,25,30,35,40,45,50,55,60]:return ""
	var roster := get_parent().get_node("ShipRoster") as PlayerShipRoster
	# Reward is attached to the defeated boss milestone, not to merely entering a map level.
	var awarded := roster.award_boss_progression_ship(defeated_map_level)
	advanced_map_level = mini(60, advanced_map_level + 1)
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	changed.emit()
	return awarded



func post_beginner_trial_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	return advanced_map_level==10 and post!=null and post.trial_ready(10)

func claim_post_beginner_trial()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(10):return false
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	var awarded:=roster.award_boss_progression_ship(10)
	advanced_map_level=11
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 10 BESTANDEN · KARTENLEVEL 11 FREI")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+4.5)
	changed.emit()
	return true


func post_beginner_trial15_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	return advanced_map_level==15 and post!=null and post.trial_ready(15)

func claim_post_beginner_trial15()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial15_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(15):return false
	advanced_map_level=16
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 15 BESTANDEN · KARTENLEVEL 16 FREI")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+4.5)
	changed.emit()
	return true


func post_beginner_trial20_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	return advanced_map_level==20 and post!=null and post.trial_ready(20)

func claim_post_beginner_trial20()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial20_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(20):return false
	advanced_map_level=21
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 20 BESTANDEN · KARTENLEVEL 21 FREI")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit()
	return true


func post_beginner_trial25_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	return advanced_map_level==25 and post!=null and post.trial_ready(25)
func claim_post_beginner_trial25()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	var spec:=get_parent().get_node_or_null("BuildSpecialization") as BuildSpecialization
	if not inventory.at_port() or not post_beginner_trial25_ready() or spec==null or spec.selected.is_empty():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(25):return false
	advanced_map_level=26
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 25 BESTANDEN · KARTENLEVEL 26 / ABYSS FREI")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit();return true


func post_beginner_trial30_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	return advanced_map_level==30 and post!=null and post.trial_ready(30)
func claim_post_beginner_trial30()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	var corruption:=get_parent().get_node_or_null("AbyssCorruption") as AbyssCorruption
	if not inventory.at_port() or not post_beginner_trial30_ready() or corruption==null:return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(30):return false
	advanced_map_level=31
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 30 BESTANDEN · KARTENLEVEL 31 / ANCIENT SEAS FREI")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit();return true

func post_beginner_trial35_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var prep:=get_parent().get_node_or_null("WorldBossPrep") as WorldBossPrep
	if prep!=null:prep.refresh_inventory(get_parent().get_node_or_null("Inventory") as PlayerInventory)
	return advanced_map_level==35 and post!=null and post.trial_ready(35) and prep!=null and prep.ready()
func claim_post_beginner_trial35()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial35_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(35):return false
	advanced_map_level=36
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 35 BESTANDEN · VOID SEA FREIGESCHALTET")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit();return true

func post_beginner_trial40_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	return advanced_map_level==40 and post!=null and post.trial_ready(40) and runtime!=null and runtime.complete(40)
func claim_post_beginner_trial40()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial40_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(40):return false
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if runtime==null or not runtime.consume(40):return false
	advanced_map_level=41
	var roster:=get_parent().get_node("ShipRoster") as PlayerShipRoster
	roster.unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 40 BESTANDEN · SOVEREIGN WATERS FREIGESCHALTET")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit()
	return true

func post_beginner_trial45_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	return advanced_map_level==45 and post!=null and post.trial_ready(45) and runtime!=null and runtime.complete(45)
func claim_post_beginner_trial45()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial45_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(45):return false
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if runtime==null or not runtime.consume(45):return false
	advanced_map_level=46
	(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 45 BESTANDEN · ABYSSAL DOMINION FREIGESCHALTET")
	(get_parent() as ShipMotor).set_meta("dock_message_until",Time.get_ticks_msec()/1000.0+5.0)
	changed.emit()
	return true

func post_beginner_trial50_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	return advanced_map_level==50 and post!=null and post.trial_ready(50) and runtime!=null and runtime.complete(50)
func claim_post_beginner_trial50()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial50_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(50):return false
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if runtime==null or not runtime.consume(50):return false
	advanced_map_level=51
	(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 50 BESTANDEN · DREADWATER MARCH FREIGESCHALTET")
	changed.emit();return true

func post_beginner_trial55_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	return advanced_map_level==55 and post!=null and post.trial_ready(55) and runtime!=null and runtime.complete(55)
func claim_post_beginner_trial55()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial55_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(55):return false
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if runtime==null or not runtime.consume(55):return false
	advanced_map_level=56
	(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_main_progression_for_map_level(advanced_map_level)
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 55 BESTANDEN · IRON MAW REACH FREIGESCHALTET")
	changed.emit();return true

func post_beginner_trial60_ready()->bool:
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	return advanced_map_level==60 and post!=null and post.trial_ready(60) and runtime!=null and runtime.complete(60)
func claim_post_beginner_trial60()->bool:
	var inventory:=get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or not post_beginner_trial60_ready():return false
	var post:=get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress
	if not post.claim_trial(60):return false
	var runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if runtime==null or not runtime.consume(60):return false
	var prestige:=get_parent().get_node_or_null("EndgamePrestigeRotation") as EndgamePrestigeRotation
	if prestige!=null:prestige.unlock()
	(get_parent() as ShipMotor).set_meta("dock_message","PIRATENPRÜFUNG 60 BESTANDEN · ENDGAME PRESTIGE FREIGESCHALTET")
	changed.emit();return true

func beginner_complete() -> bool:
	return completed_trials >= BeginnerRules.LAST_BEGINNER_LEVEL

func elite_progression_unlocked() -> bool:
	return map_level() >= BeginnerRules.ELITE_MAP_LEVEL

func presentation_card() -> Dictionary:
	return BeginnerQuestPresentation.level_card(self)

func presentation_objectives() -> Array[Dictionary]:
	return BeginnerQuestPresentation.objectives(self)

func presentation_primary() -> Dictionary:
	return BeginnerQuestPresentation.primary(self)

func next_reward_text() -> String:
	if beginner_complete(): return "Hauptprogression · Kartenlevel %d · Admiral besiegen; Kartenlevel schafft nur Eligibility, Designs werden erspielt." % map_level()
	var result := "Kartenlevel %d + %d Gold / %d XP" % [map_level() + 1, BeginnerRules.REWARD_COINS, BeginnerRules.REWARD_XP]
	if BeginnerRules.SHIP_REWARDS.has(map_level()):
		var id: String = BeginnerRules.SHIP_REWARDS[map_level()]
		result += " + " + str(ShipCatalog.ship(ShipCatalog.index_of(id)).display_name)
	if completed_trials == 0: result += " + AUTO"
	return result

func auto_unlocked() -> bool:
	return trial_passed or legacy_access

func start_event() -> bool:
	if event_seconds > 0 or event_cooldown > 0 or not (get_parent().get_node("Inventory") as PlayerInventory).at_port(): return false
	event_seconds = 900.0
	event_cooldown = 1200.0
	changed.emit()
	return true

func buy_event_repair() -> bool:
	var inventory := get_parent().get_node("Inventory") as PlayerInventory
	if not inventory.at_port() or event_tokens < 15 or inventory.count("repair") >= PlayerInventory.MAX_STOCK: return false
	event_tokens -= 15
	inventory.set_count("repair", inventory.count("repair") + 1)
	changed.emit()
	return true

func _on_sunk(_ship: ShipMotor, _attacker: Node3D) -> void:
	if trial_active:
		trial_active = false
		trial_counts = {"sink": 0, "loot": 0, "dock": 0}
		changed.emit()

func export_state() -> Dictionary:
	return {"beginner_version": BeginnerRules.BEGINNER_SAVE_VERSION, "completed_trials": completed_trials,
		"trial_active": trial_active, "trial_passed": trial_passed, "trial_counts": trial_counts.duplicate(),
		"advanced_map_level": advanced_map_level,
		"post_beginner_progress":(get_parent().get_node("PostBeginnerProgress") as PostBeginnerProgress).export_state() if get_parent().has_node("PostBeginnerProgress") else {},
		"silver_bonusmap":(get_parent().get_node("SilverBonusMapProgress") as ExtendedBonusMapProgress).export_state() if get_parent().has_node("SilverBonusMapProgress") else {},
		"gold_bonusmap":(get_parent().get_node("GoldBonusMapProgress") as GoldBonusMapProgress).export_state() if get_parent().has_node("GoldBonusMapProgress") else {},
		"build_specialization":(get_parent().get_node("BuildSpecialization") as BuildSpecialization).export_state() if get_parent().has_node("BuildSpecialization") else {},
		"abyss_corruption":(get_parent().get_node("AbyssCorruption") as AbyssCorruption).export_state() if get_parent().has_node("AbyssCorruption") else {},
		"abyss_bonusmap":(get_parent().get_node("AbyssBonusMapProgress") as AbyssBonusMapProgress).export_state() if get_parent().has_node("AbyssBonusMapProgress") else {},
		"legendary_bonusmap":(get_parent().get_node("LegendaryBonusMapProgress") as ExtendedBonusMapProgress).export_state() if get_parent().has_node("LegendaryBonusMapProgress") else {},
		"legendary_forge":(get_parent().get_node("LegendaryFragmentForge") as LegendaryFragmentForge).export_state() if get_parent().has_node("LegendaryFragmentForge") else {},
		"world_boss_prep":(get_parent().get_node("WorldBossPrep") as WorldBossPrep).export_state() if get_parent().has_node("WorldBossPrep") else {},
		"pirate_trial_runtime":(get_parent().get_node("PirateTrialRuntime") as PirateTrialRuntime).export_state() if get_parent().has_node("PirateTrialRuntime") else {},
		"endgame_prestige":(get_parent().get_node("EndgamePrestigeRotation") as EndgamePrestigeRotation).export_state() if get_parent().has_node("EndgamePrestigeRotation") else {},
		"ancient_equipment":(get_parent().get_node("AncientEquipment") as AncientEquipment).export_state() if get_parent().has_node("AncientEquipment") else {},
		"legacy_access": legacy_access, "event_seconds": event_seconds, "event_tokens": event_tokens, "event_cooldown": event_cooldown}

func import_state(data: Dictionary, legacy: bool = false) -> void:
	legacy_access = legacy or (data.get("legacy_access") is bool and data.legacy_access)
	advanced_map_level = safe_int(data.get("advanced_map_level", BeginnerRules.ELITE_MAP_LEVEL), BeginnerRules.ELITE_MAP_LEVEL, 60)
	var post:=get_parent().get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	if post!=null and data.get("post_beginner_progress",{}) is Dictionary:
		post.import_state(data.get("post_beginner_progress",{}))
	var silver:=get_parent().get_node_or_null("SilverBonusMapProgress") as ExtendedBonusMapProgress
	if silver!=null and data.get("silver_bonusmap",{}) is Dictionary:silver.import_state(data.get("silver_bonusmap",{}))
	var gold:=get_parent().get_node_or_null("GoldBonusMapProgress") as GoldBonusMapProgress
	if gold!=null and data.get("gold_bonusmap",{}) is Dictionary:gold.import_state(data.get("gold_bonusmap",{}))
	var spec:=get_parent().get_node_or_null("BuildSpecialization") as BuildSpecialization
	if spec!=null and data.get("build_specialization",{}) is Dictionary:spec.import_state(data.get("build_specialization",{}))
	var corruption:=get_parent().get_node_or_null("AbyssCorruption") as AbyssCorruption
	if corruption!=null and data.get("abyss_corruption",{}) is Dictionary:corruption.import_state(data.get("abyss_corruption",{}))
	var abyss_map:=get_parent().get_node_or_null("AbyssBonusMapProgress") as AbyssBonusMapProgress
	if abyss_map!=null and data.get("abyss_bonusmap",{}) is Dictionary:abyss_map.import_state(data.get("abyss_bonusmap",{}))
	var legendary_bonus:=get_parent().get_node_or_null("LegendaryBonusMapProgress") as ExtendedBonusMapProgress
	if legendary_bonus!=null and data.get("legendary_bonusmap",{}) is Dictionary:legendary_bonus.import_state(data.get("legendary_bonusmap",{}))
	var legendary_forge:=get_parent().get_node_or_null("LegendaryFragmentForge") as LegendaryFragmentForge
	if legendary_forge!=null and data.get("legendary_forge",{}) is Dictionary:legendary_forge.import_state(data.get("legendary_forge",{}))
	var prestige:=get_parent().get_node_or_null("EndgamePrestigeRotation") as EndgamePrestigeRotation
	if prestige!=null and data.get("endgame_prestige",{}) is Dictionary:prestige.import_state(data.get("endgame_prestige",{}))
	var trial_runtime:=get_parent().get_node_or_null("PirateTrialRuntime") as PirateTrialRuntime
	if trial_runtime!=null and data.get("pirate_trial_runtime",{}) is Dictionary:trial_runtime.import_state(data.get("pirate_trial_runtime",{}))
	var prep_state:=get_parent().get_node_or_null("WorldBossPrep") as WorldBossPrep
	if prep_state!=null and data.get("world_boss_prep",{}) is Dictionary:prep_state.import_state(data.get("world_boss_prep",{}))
	var ancient_equipment:=get_parent().get_node_or_null("AncientEquipment") as AncientEquipment
	if ancient_equipment!=null and data.get("ancient_equipment",{}) is Dictionary:ancient_equipment.import_state(data.get("ancient_equipment",{}))
	# M77 progression reconciliation:
	# - New saves use canonical PL2/PL3 starter rewards.
	# - v1 saves keep any reward they were entitled to under the old stage-1/stage-5 mapping.
	# - pre-version M31 trial_passed maps to one completed assignment only.
	var old_passed: bool = data.get("trial_passed") is bool and data.trial_passed
	var source_version := safe_int(data.get("beginner_version", 0), 0, BeginnerRules.BEGINNER_SAVE_VERSION)
	completed_trials = safe_int(data.get("completed_trials", 0), 0, BeginnerRules.LAST_BEGINNER_LEVEL) if data.has("beginner_version") else (1 if old_passed else 0)
	trial_passed = completed_trials > 0
	_apply_legacy_starter_entitlements(source_version)
	trial_active = not beginner_complete() and data.get("trial_active") is bool and data.trial_active
	var counts: Variant = data.get("trial_counts", {})
	for key in TRIAL_GOALS:
		trial_counts[key] = safe_int(counts.get(key, 0), 0, TRIAL_GOALS[key]) if counts is Dictionary else 0
		if not trial_active: trial_counts[key] = 0
	event_seconds = safe_int(data.get("event_seconds", 0), 0, 900)
	event_tokens = safe_int(data.get("event_tokens", 0), 0, 999999)
	event_cooldown = maxf(event_seconds, safe_int(data.get("event_cooldown", 0), 0, 1200))
	(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_earned_starters()
	if beginner_complete():
		(get_parent().get_node("ShipRoster") as PlayerShipRoster).unlock_main_progression_for_map_level(advanced_map_level)
	changed.emit()

func _apply_legacy_starter_entitlements(source_version: int) -> void:
	# Only explicit beginner schema v1 had the old stage-1/stage-5 starter entitlement.
	# Pre-version M31 saves (source_version == 0) map trial_passed to one completion,
	# but must NOT fabricate a legacy Clipper entitlement.
	if source_version != 1:
		return
	var roster := get_parent().get_node_or_null("ShipRoster") as PlayerShipRoster
	if roster == null:
		return
	var added:=false
	for stage in BeginnerRules.LEGACY_SHIP_REWARDS_V1:
		if completed_trials >= int(stage):
			var ship_id := str(BeginnerRules.LEGACY_SHIP_REWARDS_V1[stage])
			if not roster.owns_ship(ship_id) and roster.award_ship(ship_id, false):
				roster.record_local_migration("legacy_beginner_reward_v1", ship_id, int(stage))
				added=true
	if added:
		roster.roster_changed.emit()

static func safe_int(value: Variant, minimum: int, maximum: int) -> int:
	if not (value is int or value is float) or not is_finite(float(value)): return minimum
	return int(clampf(float(value), minimum, maximum))

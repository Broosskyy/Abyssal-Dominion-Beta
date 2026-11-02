extends Node3D

const Factory = preload("res://scripts/core/procedural_factory.gd")
const PlayerInputScript = preload("res://scripts/gameplay/player_input.gd")
const ShipWeaponsScript = preload("res://scripts/gameplay/ship_weapons.gd")
const ShipHealthScript = preload("res://scripts/gameplay/ship_health.gd")
const EnemyAiScript = preload("res://scripts/gameplay/enemy_ship_ai.gd")
const CameraRigScript = preload("res://scripts/gameplay/camera_rig.gd")
const HudScript = preload("res://scripts/ui/game_hud.gd")
const WorldMapScript = preload("res://scripts/world/world_map_system.gd")
const TargetingScript = preload("res://scripts/combat/targeting_system.gd")
const PlatformProfileScript = preload("res://scripts/core/platform_profile.gd")
const GameStateScript = preload("res://scripts/core/game_state.gd")
const ProgressionScript = preload("res://scripts/progression/player_progression.gd")
const ShipRosterScript = preload("res://scripts/progression/player_ship_roster.gd")
const MissionScript = preload("res://scripts/progression/mission_system.gd")
const EventRuntimeScript = preload("res://scripts/events/event_runtime.gd")
const AdminRuntimeScript = preload("res://scripts/admin/admin_mode_runtime.gd")
const AdminOverlayScript = preload("res://scripts/admin/admin_overlay.gd")


func _ready() -> void:
	add_to_group("gameplay_root")
	get_tree().root.set_meta("environment_id","LOCAL_DEVELOPMENT")
	get_tree().root.set_meta("server_authority_verified",false)
	get_tree().root.set_meta("build_identity",BuildIdentity.compact())
	get_tree().root.set_meta("compatibility_gate",CompatibilityGate.local_check())
	var live_config:=LiveConfigRegistry.new()
	live_config.name="LiveConfigRegistry"
	live_config.add_to_group("live_config")
	add_child(live_config)
	var admin_auth:=AdminAuthorization.new()
	admin_auth.name="AdminAuthorization"
	add_child(admin_auth)
	var admin_modules := AdminModuleRegistry.new()
	admin_modules.name = "AdminModuleRegistry"
	add_child(admin_modules)
	var m160_catalog:=M160SystemCatalog.new()
	m160_catalog.name="M160SystemCatalog"
	add_child(m160_catalog)
	var m162_catalog:=M162SystemCatalog.new()
	m162_catalog.name="M162SystemCatalog"
	add_child(m162_catalog)
	var m163_catalog:=M163SystemDepthCatalog.new()
	m163_catalog.name="M163SystemDepthCatalog"
	add_child(m163_catalog)
	var m164_catalog:=M164NoCodeCatalog.new()
	m164_catalog.name="M164NoCodeCatalog"
	add_child(m164_catalog)
	var m165_catalog:=M165RuntimeDepthCatalog.new()
	m165_catalog.name="M165RuntimeDepthCatalog"
	add_child(m165_catalog)
	var m166_catalog:=M166ProductionDepthCatalog.new()
	m166_catalog.name="M166ProductionDepthCatalog"
	add_child(m166_catalog)
	var m169_catalog:=M169MobileMenuCatalog.new()
	m169_catalog.name="M169MobileMenuCatalog"
	add_child(m169_catalog)
	var m170_catalog:=M170MobileRuntimeCatalog.new()
	m170_catalog.name="M170MobileRuntimeCatalog"
	add_child(m170_catalog)
	var m171_catalog:=M171RuntimePresentationCatalog.new()
	m171_catalog.name="M171RuntimePresentationCatalog"
	add_child(m171_catalog)
	var m172_catalog:=M172RuntimeProgressionCatalog.new()
	m172_catalog.name="M172RuntimeProgressionCatalog"
	add_child(m172_catalog)
	var m173_catalog:=M173MenuProgressionCatalog.new()
	m173_catalog.name="M173MenuProgressionCatalog"
	var m174_catalog:=M174MenuPanelCatalog.new()
	m174_catalog.name="M174MenuPanelCatalog"
	add_child(m174_catalog)
	var m183_catalog:=M183CommandDeckCatalog.new()
	m183_catalog.name="M183CommandDeckCatalog"
	add_child(m183_catalog)
	var m184_catalog:=M184PanelRoutingCatalog.new()
	m184_catalog.name="M184PanelRoutingCatalog"
	add_child(m184_catalog)
	var m185_catalog:=M185MenuStatusCatalog.new()
	m185_catalog.name="M185MenuStatusCatalog"
	add_child(m185_catalog)
	var m186_catalog:=M186ObjectiveNavigationCatalog.new()
	m186_catalog.name="M186ObjectiveNavigationCatalog"
	add_child(m186_catalog)
	var m175_catalog:=M175FeedbackPresentationCatalog.new()
	m175_catalog.name="M175FeedbackPresentationCatalog"
	add_child(m175_catalog)
	var m176_catalog:=M176RuntimeFeedbackCatalog.new()
	m176_catalog.name="M176RuntimeFeedbackCatalog"
	add_child(m176_catalog)
	add_child(m173_catalog)
	var m168_catalog:=M168RuntimeAuditCatalog.new()
	m168_catalog.name="M168RuntimeAuditCatalog"
	add_child(m168_catalog)
	var m167_catalog:=M167UxContentCatalog.new()
	m167_catalog.name="M167UxContentCatalog"
	add_child(m167_catalog)
	var commerce_catalog:=M161CommerceCatalog.new()
	commerce_catalog.name="M161CommerceCatalog"
	add_child(commerce_catalog)
	var admin_commands:=M161AdminCommandRegistry.new()
	admin_commands.name="M161AdminCommandRegistry"
	add_child(admin_commands)
	var no_code_catalog:=M161NoCodeCapabilityCatalog.new()
	no_code_catalog.name="M161NoCodeCapabilityCatalog"
	add_child(no_code_catalog)
	var admin_content:=AdminContentRegistry.new()
	admin_content.name="AdminContentRegistry"
	add_child(admin_content)
	var p0_asset_swap := P0AssetSwapService.new()
	p0_asset_swap.name = "P0AssetSwapService"
	add_child(p0_asset_swap)
	var production_waves := ProductionWaveCatalog.new()
	production_waves.name = "ProductionWaveCatalog"
	add_child(production_waves)
	var w5_production := W5ProductionBatch.new()
	w5_production.name = "W5ProductionBatch"
	add_child(w5_production)
	var ship_production := ShipProductionArchitecture.new()
	ship_production.name = "ShipProductionArchitecture"
	add_child(ship_production)
	var companion_catalog := CompanionCatalog.new()
	companion_catalog.name = "CompanionCatalog"
	add_child(companion_catalog)
	var artifact_catalog := ArtifactCatalog.new()
	artifact_catalog.name = "ArtifactCatalog"
	add_child(artifact_catalog)
	var afk_catalog := AfkRewardCatalog.new()
	afk_catalog.name = "AfkRewardCatalog"
	add_child(afk_catalog)
	var p1_regional_assets := P1RegionalAssetCatalog.new()
	p1_regional_assets.name = "P1RegionalAssetCatalog"
	add_child(p1_regional_assets)
	var p1_regional_runtime := P1RegionalRuntimeCatalog.new()
	p1_regional_runtime.name = "P1RegionalRuntimeCatalog"
	add_child(p1_regional_runtime)
	var p1_visual_acceptance := P1RegionalVisualAcceptanceCatalog.new()
	p1_visual_acceptance.name = "P1RegionalVisualAcceptanceCatalog"
	add_child(p1_visual_acceptance)
	var p1_environment := P1RegionalEnvironmentController.new()
	p1_environment.name = "P1RegionalEnvironmentController"
	add_child(p1_environment)
	var content_snapshots := ContentSnapshotService.new()
	content_snapshots.name = "ContentSnapshotService"
	add_child(content_snapshots)
	var content_admin_gateway := ContentAdminGateway.new()
	content_admin_gateway.name = "ContentAdminGateway"
	add_child(content_admin_gateway)
	var admin_http_transport := AdminHttpTransport.new()
	admin_http_transport.name = "AdminHttpTransport"
	add_child(admin_http_transport)
	content_admin_gateway.configure(admin_http_transport, content_snapshots)
	var feedback := CombatFeedback.new()
	feedback.name = "CombatFeedback"
	add_child(feedback)
	if VisualQA.requested():
		get_tree().root.set_meta("reconstruction_test_mode", true)
		seed(120012)
	var platform_profile: PlatformProfile = PlatformProfileScript.new()
	platform_profile.name = "PlatformProfile"
	add_child(platform_profile)
	var game_state: GameState = GameStateScript.new()
	game_state.name = "GameState"
	add_child(game_state)
	var event_runtime: EventRuntime = EventRuntimeScript.new()
	event_runtime.name = "EventRuntime"
	add_child(event_runtime)
	var admin_runtime: AdminModeRuntime = AdminRuntimeScript.new()
	admin_runtime.name = "AdminModeRuntime"
	add_child(admin_runtime)
	MobileLodController.apply(get_tree())
	_build_environment()
	add_child(Factory.create_ocean())
	var player := _create_player()
	var services:=ServiceLocator.new()
	services.name="ServiceLocator"
	add_child(services)
	services.configure(player,game_state)
	var online_readiness := M252OnlineReadinessRuntime.new()
	online_readiness.name = "OnlineReadiness"
	online_readiness.configure(services)
	add_child(online_readiness)
	var world_session := M253WorldSessionRuntime.new()
	world_session.name = "WorldSessionReadiness"
	add_child(world_session)
	var mail_notifications := M254MailNotificationRuntime.new()
	mail_notifications.name = "MailNotificationReadiness"
	add_child(mail_notifications)
	var payment_commerce := M255PaymentCommerceRuntime.new()
	payment_commerce.name = "PaymentCommerceReadiness"
	add_child(payment_commerce)
	var telemetry_observability := M256TelemetryObservabilityRuntime.new()
	telemetry_observability.name = "TelemetryObservabilityReadiness"
	add_child(telemetry_observability)
	var release_operations := M257ReleaseOperationsRuntime.new()
	release_operations.name = "ReleaseOperationsReadiness"
	add_child(release_operations)
	var backup_recovery := M258BackupDisasterRecoveryRuntime.new()
	backup_recovery.name = "BackupDisasterRecoveryReadiness"
	add_child(backup_recovery)
	var security_operations := M259SecurityOperationsRuntime.new()
	security_operations.name = "SecurityOperationsReadiness"
	add_child(security_operations)
	var capacity_performance := M260CapacityPerformanceRuntime.new()
	capacity_performance.name = "CapacityPerformanceReadiness"
	add_child(capacity_performance)
	var crash_client_health := M261CrashClientHealthRuntime.new()
	crash_client_health.name = "CrashClientHealthReadiness"
	add_child(crash_client_health)
	var launch_readiness := M262LaunchReadinessRuntime.new()
	launch_readiness.name = "LaunchReadinessGate"
	add_child(launch_readiness)
	var online_alpha := M263OnlineAlphaRuntime.new()
	online_alpha.name = "OnlineAlphaReadiness"
	add_child(online_alpha)
	var auth_account_repository := M264AuthAccountRepositoryRuntime.new()
	auth_account_repository.name = "AuthAccountRepositoryReadiness"
	add_child(auth_account_repository)
	var player_profile_ownership := M265PlayerProfileOwnershipRuntime.new()
	player_profile_ownership.name = "PlayerProfileOwnershipReadiness"
	add_child(player_profile_ownership)
	var economy_inventory_transactions := M266EconomyInventoryTransactionRuntime.new()
	economy_inventory_transactions.name = "EconomyInventoryTransactionReadiness"
	add_child(economy_inventory_transactions)
	var authoritative_world_transport := M267AuthoritativeWorldTransportRuntime.new()
	authoritative_world_transport.name = "AuthoritativeWorldTransportReadiness"
	add_child(authoritative_world_transport)
	var authoritative_movement := M268AuthoritativeMovementRuntime.new()
	authoritative_movement.name = "AuthoritativeMovementReadiness"
	add_child(authoritative_movement)
	var authoritative_combat := M269AuthoritativeCombatRuntime.new()
	authoritative_combat.name = "AuthoritativeCombatReadiness"
	add_child(authoritative_combat)
	var authoritative_combat_state := M270AuthoritativeCombatStateRuntime.new()
	authoritative_combat_state.name = "AuthoritativeCombatStateReadiness"
	add_child(authoritative_combat_state)
	var targeting_relationship_authority := M271TargetingRelationshipAuthorityRuntime.new()
	targeting_relationship_authority.name = "TargetingRelationshipAuthorityReadiness"
	add_child(targeting_relationship_authority)
	var npc_monster_ai_combat_brain := M272NpcMonsterAICombatBrainRuntime.new()
	npc_monster_ai_combat_brain.name = "NpcMonsterAICombatBrainReadiness"
	add_child(npc_monster_ai_combat_brain)
	var authoritative_encounter_orchestration := M273AuthoritativeEncounterOrchestrationRuntime.new()
	authoritative_encounter_orchestration.name = "AuthoritativeEncounterOrchestrationReadiness"
	add_child(authoritative_encounter_orchestration)
	var authoritative_kill_credit_reward_persistence := M274AuthoritativeKillCreditRewardPersistenceRuntime.new()
	authoritative_kill_credit_reward_persistence.name = "AuthoritativeKillCreditRewardPersistenceReadiness"
	add_child(authoritative_kill_credit_reward_persistence)
	var authoritative_loot_distribution := M275AuthoritativeLootDistributionRuntime.new()
	authoritative_loot_distribution.name = "AuthoritativeLootDistributionReadiness"
	add_child(authoritative_loot_distribution)
	var authoritative_loot_roll_integrity := M276AuthoritativeLootRollIntegrityRuntime.new()
	authoritative_loot_roll_integrity.name = "AuthoritativeLootRollIntegrityReadiness"
	add_child(authoritative_loot_roll_integrity)
	var authoritative_reward_delivery := M277AuthoritativeRewardDeliveryRuntime.new()
	authoritative_reward_delivery.name = "AuthoritativeRewardDeliveryReadiness"
	add_child(authoritative_reward_delivery)
	var authoritative_reward_inbox := M278AuthoritativeRewardInboxRuntime.new()
	authoritative_reward_inbox.name = "AuthoritativeRewardInboxReadiness"
	add_child(authoritative_reward_inbox)
	var authoritative_reward_presentation := M279AuthoritativeRewardPresentationRuntime.new()
	authoritative_reward_presentation.name = "AuthoritativeRewardPresentationReadiness"
	add_child(authoritative_reward_presentation)
	var reward_visual_integration := M280RewardVisualIntegrationRuntime.new()
	reward_visual_integration.name = "RewardVisualIntegrationReadiness"
	add_child(reward_visual_integration)
	var combat_hud_convergence := M281CombatHudConvergenceRuntime.new()
	combat_hud_convergence.name = "CombatHudConvergenceReadiness"
	add_child(combat_hud_convergence)
	var combat_event_feedback := M282CombatEventFeedbackRuntime.new()
	combat_event_feedback.name = "CombatEventFeedbackReadiness"
	add_child(combat_event_feedback)
	var projectile_salvo_presentation := M283ProjectileSalvoPresentationRuntime.new()
	projectile_salvo_presentation.name = "ProjectileSalvoPresentationReadiness"
	add_child(projectile_salvo_presentation)
	var naval_combat_identity := M284NavalCombatIdentityRuntime.new()
	naval_combat_identity.name = "NavalCombatIdentityReadiness"
	add_child(naval_combat_identity)
	var ship_damage_defeat_presentation := M285ShipDamageDefeatPresentationRuntime.new()
	ship_damage_defeat_presentation.name = "ShipDamageDefeatPresentationReadiness"
	add_child(ship_damage_defeat_presentation)
	var ship_damage_escalation := M286ShipDamageEscalationRuntime.new()
	ship_damage_escalation.name = "ShipDamageEscalationReadiness"
	add_child(ship_damage_escalation)
	var ship_motion_identity := M287ShipMotionIdentityRuntime.new()
	ship_motion_identity.name = "ShipMotionIdentityReadiness"
	add_child(ship_motion_identity)
	var naval_contact_readability := M288NavalContactReadabilityRuntime.new()
	naval_contact_readability.name = "NavalContactReadabilityReadiness"
	add_child(naval_contact_readability)
	var playable_vertical_slice := M289PlayableVerticalSliceRuntime.new()
	playable_vertical_slice.name = "PlayableVerticalSliceReadiness"
	add_child(playable_vertical_slice)
	var first_sortie_integration := M290FirstSortieIntegrationRuntime.new()
	first_sortie_integration.name = "FirstSortieIntegration"
	add_child(first_sortie_integration)
	var companion_runtime := CompanionRuntime.new()
	companion_runtime.name = "CompanionRuntime"
	companion_runtime.configure(player)
	add_child(companion_runtime)
	var artifact_loadout := ArtifactLoadout.new()
	artifact_loadout.name = "ArtifactLoadout"
	add_child(artifact_loadout)
	var afk_rewards := AfkRewardService.new()
	afk_rewards.name = "AfkRewardService"
	add_child(afk_rewards)
	get_tree().root.set_meta("service_facades",{"locator":"ServiceLocator"})
	get_tree().root.set_meta("transport_adapter_status",services.status())
	_create_camera(player)
	var world_map: WorldMapSystem = WorldMapScript.new()
	world_map.name = "WorldMapSystem"
	world_map.player = player
	add_child(world_map)
	first_sortie_integration.configure(player, world_map, playable_vertical_slice)
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 20
	add_child(hud_layer)
	var hud: GameHud = HudScript.new()
	hud.name = "GameHUD"
	hud_layer.add_child(hud)
	var ship_extensions:=M159ShipExtensionVisuals.new()
	ship_extensions.name="M159ShipExtensionVisuals"
	player.add_child(ship_extensions)
	var progression_hub:=M160ProgressionHub.new()
	progression_hub.name="M160ProgressionHub"
	hud_layer.add_child(progression_hub)
	var meta_panel := MetaSystemsPanel.new()
	meta_panel.name = "MetaSystemsPanel"
	hud_layer.add_child(meta_panel)
	var admin_badge:=M159AdminBadge.new()
	admin_badge.name="M159AdminBadge"
	hud_layer.add_child(admin_badge)
	var admin_overlay: AdminOverlay = AdminOverlayScript.new()
	admin_overlay.name = "AdminOverlay"
	hud_layer.add_child(admin_overlay)
	var arsenal := ArsenalPanel.new()
	arsenal.name = "ArsenalPanel"
	arsenal.player = player
	hud_layer.add_child(arsenal)
	var journal := CaptainJournal.new()
	journal.name = "CaptainJournal"
	journal.player = player
	hud_layer.add_child(journal)
	game_state.bind(player, world_map)
	if VisualQA.requested():
		var qa := VisualQA.new()
		qa.name = "VisualQA"
		add_child(qa)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("245b70")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("829ba3")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	world_environment.add_to_group("regional_world_environment")
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("ffe8c2")
	sun.light_energy = 0.92
	sun.shadow_enabled = true
	sun.add_to_group("quality_directional_lights")
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	add_child(sun)


func _create_player() -> CharacterBody3D:
	var player := Factory.create_ship("PLAYER", Vector3(0.0, 0.55, 0.0), Color("1f536f"), true)
	player.set_meta("visual_profile", "clipper")
	_add_ship_modules(player, 1000.0, true)
	add_child(player)
	return player


func _add_ship_modules(ship: CharacterBody3D, max_health: float, player_controlled: bool, archetype: String = "raider") -> void:
	var health: ShipHealth = ShipHealthScript.new()
	health.name = "Health"
	health.max_health = max_health
	if player_controlled:
		health.max_shield = float(CombatSupportContracts.read().get("shield", {}).get("base_capacity", 0.0))
	health.respawn_position = ship.position
	ship.add_child(health)

	var weapons: ShipWeapons = ShipWeaponsScript.new()
	weapons.name = "Weapons"
	ship.add_child(weapons)

	if player_controlled:
		var targeting: TargetingSystem = TargetingScript.new()
		targeting.name = "Targeting"
		ship.add_child(targeting)
		var progression: PlayerProgression = ProgressionScript.new()
		progression.name = "Progression"
		ship.add_child(progression)
		var ship_roster: PlayerShipRoster = ShipRosterScript.new()
		ship_roster.name = "ShipRoster"
		ship.add_child(ship_roster)
		var inventory := PlayerInventory.new()
		inventory.name = "Inventory"
		ship.add_child(inventory)
		var missions: MissionSystem = MissionScript.new()
		missions.name = "Missions"
		ship.add_child(missions)
		var voyage := VoyageProgress.new()
		voyage.name = "Voyage"
		ship.add_child(voyage)
		var post_progress:=PostBeginnerProgress.new()
		post_progress.name="PostBeginnerProgress"
		ship.add_child(post_progress)
		var silver_bonus:=ExtendedBonusMapProgress.new()
		silver_bonus.name="SilverBonusMapProgress"
		silver_bonus.kind="silver"
		ship.add_child(silver_bonus)
		var gold_bonus:=GoldBonusMapProgress.new()
		gold_bonus.name="GoldBonusMapProgress"
		ship.add_child(gold_bonus)
		var build_spec:=BuildSpecialization.new()
		build_spec.name="BuildSpecialization"
		ship.add_child(build_spec)
		var corruption:=AbyssCorruption.new()
		corruption.name="AbyssCorruption"
		ship.add_child(corruption)
		var abyss_bonus:=AbyssBonusMapProgress.new()
		abyss_bonus.name="AbyssBonusMapProgress"
		ship.add_child(abyss_bonus)
		var legendary_bonus:=ExtendedBonusMapProgress.new()
		legendary_bonus.name="LegendaryBonusMapProgress"
		legendary_bonus.kind="legendary"
		ship.add_child(legendary_bonus)
		var legendary_forge:=LegendaryFragmentForge.new()
		legendary_forge.name="LegendaryFragmentForge"
		ship.add_child(legendary_forge)
		var world_boss_prep:=WorldBossPrep.new()
		world_boss_prep.name="WorldBossPrep"
		ship.add_child(world_boss_prep)
		var pirate_trial_runtime:=PirateTrialRuntime.new()
		pirate_trial_runtime.name="PirateTrialRuntime"
		ship.add_child(pirate_trial_runtime)
		var endgame_prestige:=EndgamePrestigeRotation.new()
		endgame_prestige.name="EndgamePrestigeRotation"
		ship.add_child(endgame_prestige)
		var dynamic_quests:=DynamicQuestRuntime.new()
		dynamic_quests.name="DynamicQuestRuntime"
		ship.add_child(dynamic_quests)
		var tracked_quest:=TrackedQuestRuntime.new()
		tracked_quest.name="TrackedQuestRuntime"
		ship.add_child(tracked_quest)
		var ancient_equipment:=AncientEquipment.new()
		ancient_equipment.name="AncientEquipment"
		ship.add_child(ancient_equipment)
		var player_input: PlayerShipInput = PlayerInputScript.new()
		player_input.name = "PlayerInput"
		ship.add_child(player_input)
	else:
		var ai: EnemyShipAI = EnemyAiScript.new()
		ai.name = "EnemyAI"
		ai.archetype = archetype
		ship.add_child(ai)


func _create_camera(player: Node3D) -> void:
	var camera: IsometricCameraRig = CameraRigScript.new()
	camera.name = "GameplayCamera"
	camera.target = player
	camera.current = true
	add_child(camera)

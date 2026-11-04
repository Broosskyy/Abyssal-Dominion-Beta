class_name ServiceLocator
extends Node
var profile:ProfileService
var inventory:InventoryService
var wallet:WalletService
var progression:ProgressionService
var entitlement:EntitlementService
var rewards:RewardBundleService
var content:ContentRuntimeService
var time:TrustedTimeService
var transport:TransportGateway
var auth:AuthGateway
var repository:RepositoryGateway
func configure(player:ShipMotor,state:GameState)->void:
	profile=ProfileService.new(player,state)
	inventory=InventoryService.new(player,state)
	wallet=WalletService.new(player,state)
	progression=ProgressionService.new(player,state)
	entitlement=EntitlementService.new(player,state)
	rewards=RewardBundleService.new(player,state)
	content=ContentRuntimeService.new(player,state)
	time=TrustedTimeService.new(player,state)
	rewards.configure(inventory,wallet,progression,entitlement)
	transport=TransportAdapterFactory.create(get_tree())
	var session:=get_tree().get_first_node_in_group("local_session") as LocalSession
	if EnvironmentContract.current_id(get_tree())=="LOCAL_DEVELOPMENT":
		auth=LocalAccountAdapter.new(session)
		repository=LocalGameStateRepository.new(state)
	else:
		auth=AuthGateway.new()
		repository=RepositoryGateway.new()
func status()->Dictionary:
	return {"environment":EnvironmentContract.current_id(get_tree()),
		"server_authoritative":transport!=null and transport.server_authoritative(),
		"configured":profile!=null and inventory!=null and wallet!=null and progression!=null and rewards!=null and content!=null and time!=null and auth!=null and repository!=null,
		"auth":auth.capabilities() if auth!=null else {"available":false,"mode":"missing"},
		"repository":repository.capabilities() if repository!=null else {"available":false,"mode":"missing"},
		"transport":transport.capabilities() if transport!=null else {"available":false,"mode":"missing"},
		"content_version":content.effective_version() if content!=null else "missing",
		"time_authority":time.authority() if time!=null else "missing"}
static func from(tree:SceneTree)->ServiceLocator:
	return tree.get_first_node_in_group("service_locator") as ServiceLocator if tree!=null else null
func _ready()->void:add_to_group("service_locator")

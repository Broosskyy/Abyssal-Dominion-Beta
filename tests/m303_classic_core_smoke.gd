extends SceneTree
## Run: godot --headless --path . --script res://tests/m303_classic_core_smoke.gd
## Executes ONLY the pure route contract. This does NOT certify visual/native QA.

const ROUTER = preload("res://scripts/classic/classic_route_planner.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_test_direct_route()
	_test_island_avoidance()
	_test_blocked_destination()
	_test_out_of_bounds()
	_test_multi_island()
	if failures.is_empty():
		print("M303.1 route planner: 5/5 smoke cases passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_direct_route() -> void:
	var path := ROUTER.plan(Vector2.ZERO, Vector2(25, 30), [])
	_check(path.size() == 1 and path[0].distance_to(Vector2(25, 30)) < 0.01, "Direct route should contain its destination")


func _test_island_avoidance() -> void:
	var shore: Array[Dictionary] = [{"position": Vector3.ZERO, "radius": 10.0}]
	var path := ROUTER.plan(Vector2(-35, 0), Vector2(35, 0), shore)
	_check(path.size() > 1, "Route crossing island must contain detour waypoints")
	if not path.is_empty():
		_check(path[path.size() - 1].distance_to(Vector2(35, 0)) < 0.01, "Detour should reach target")
		var previous := Vector2(-35, 0)
		for point in path:
			_check(ROUTER._clear_segment(previous, point, shore), "Island detour must not cross shore")
			previous = point


func _test_blocked_destination() -> void:
	var shore: Array[Dictionary] = [{"position": Vector3.ZERO, "radius": 10.0}]
	var path := ROUTER.plan(Vector2(-35, 0), Vector2(0, 0), shore)
	_check(path.is_empty(), "Target inside shore must be rejected")


func _test_out_of_bounds() -> void:
	var path := ROUTER.plan(Vector2.ZERO, Vector2(160, 0), [])
	_check(path.is_empty(), "Outside-of-map destination must be rejected")


func _test_multi_island() -> void:
	var shore: Array[Dictionary] = [
		{"position": Vector3(-12, 0, -4), "radius": 11.0},
		{"position": Vector3(15, 0, 6), "radius": 9.0}
	]
	var path := ROUTER.plan(Vector2(-50, -5), Vector2(45, 8), shore)
	_check(not path.is_empty(), "Multi-island route must be reachable")

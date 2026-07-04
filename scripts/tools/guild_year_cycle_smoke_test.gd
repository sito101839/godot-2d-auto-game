extends SceneTree

const BATTLE_SCENE := preload("res://battle/BattleScene.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BATTLE_SCENE.instantiate()
	root.add_child(battle)

	await process_frame

	var manager := battle.get_node_or_null("BattleManager")
	if manager == null:
		push_error("BattleManager was not found.")
		_fail(battle)
		return

	manager.set("save_path", "user://guild_year_cycle_smoke_test.json")

	manager.call("_train_guild", "drill")
	await process_frame
	manager.call("_train_guild", "endurance")
	await process_frame

	if int(manager.get("current_turn")) != 3:
		push_error("Expected turn 3 after two training actions.")
		_fail(battle)
		return

	if not await _run_battle(manager, "mission"):
		_fail(battle)
		return

	if int(manager.get("current_turn")) != 4:
		push_error("Expected turn 4 before tournament.")
		_fail(battle)
		return

	if not await _run_battle(manager, "tournament"):
		_fail(battle)
		return

	if int(manager.get("current_year")) != 2 or int(manager.get("current_turn")) != 1:
		push_error("Expected the first year to complete after tournament.")
		_fail(battle)
		return

	if int(manager.get("completed_years")) != 1:
		push_error("Expected completed_years to be 1.")
		_fail(battle)
		return

	if int(manager.get("total_battles")) != 2:
		push_error("Expected exactly two battles in the first cycle.")
		_fail(battle)
		return

	var saved_fame: int = int(manager.get("fame"))
	manager.call("save_game")
	await process_frame
	manager.set("fame", saved_fame + 999)
	manager.call("load_game")
	await process_frame

	if int(manager.get("fame")) != saved_fame:
		push_error("Expected load_game to restore fame from save data.")
		_fail(battle)
		return

	print("SMOKE_TEST_PASS guild_year_cycle year=%d turn=%d completed=%d battles=%d fame=%d" % [
		manager.get("current_year"),
		manager.get("current_turn"),
		manager.get("completed_years"),
		manager.get("total_battles"),
		manager.get("fame"),
	])
	battle.queue_free()
	await process_frame
	quit(0)


func _run_battle(manager: Node, expected_kind: String) -> bool:
	manager.call("start_battle")
	await process_frame

	if manager.get("current_battle_kind") != expected_kind:
		push_error("Expected battle kind %s, got %s." % [expected_kind, manager.get("current_battle_kind")])
		return false

	for _frame_index: int in 1800:
		await physics_frame
		if bool(manager.get("battle_finished")):
			manager.call("_show_prep_screen")
			await process_frame
			return true

	push_error("Battle did not finish within the year cycle smoke test frame budget.")
	return false


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

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

	manager.set("save_path", "user://guild_three_year_smoke_test.json")

	for _year_index: int in 3:
		manager.call("_train_guild", "drill")
		await process_frame
		manager.call("_train_guild", "endurance")
		await process_frame

		if not await _run_battle(manager, "mission"):
			_fail(battle)
			return
		if not await _run_battle(manager, "tournament"):
			_fail(battle)
			return

	if int(manager.get("completed_years")) != 3:
		push_error("Expected completed_years to be 3.")
		_fail(battle)
		return

	if int(manager.get("current_year")) != 4 or int(manager.get("current_turn")) != 1:
		push_error("Expected to enter year 4 turn 1 after three complete years.")
		_fail(battle)
		return

	if int(manager.get("total_battles")) != 6:
		push_error("Expected 6 battles after three complete years.")
		_fail(battle)
		return

	var roster: Array = manager.call("get_roster_snapshot")
	if roster.size() < 6:
		push_error("Expected roster to be refilled after graduations.")
		_fail(battle)
		return

	var saw_new_recruit: bool = false
	for member: Dictionary in roster:
		if int(member["years_in_guild"]) == 1:
			saw_new_recruit = true

	if not saw_new_recruit:
		push_error("Expected at least one new recruit after three years.")
		_fail(battle)
		return

	manager.call("save_game")
	await process_frame
	var saved_battles: int = int(manager.get("total_battles"))
	manager.set("total_battles", saved_battles + 100)
	manager.call("load_game")
	await process_frame

	if int(manager.get("total_battles")) != saved_battles:
		push_error("Expected save/load to restore total_battles after three years.")
		_fail(battle)
		return

	print("SMOKE_TEST_PASS guild_three_year_cycle year=%d completed=%d battles=%d roster=%d" % [
		manager.get("current_year"),
		manager.get("completed_years"),
		manager.get("total_battles"),
		roster.size(),
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

	push_error("Battle did not finish within the three-year smoke test frame budget.")
	return false


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

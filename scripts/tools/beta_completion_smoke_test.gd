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

	manager.set("save_path", "user://beta_completion_smoke_test.json")

	var initial_status: Dictionary = manager.call("get_beta_status")
	if int(initial_status["trait_count"]) < 6:
		push_error("Expected at least 6 traits.")
		_fail(battle)
		return
	if int(initial_status["mission_count"]) < 3:
		push_error("Expected at least 3 mission types.")
		_fail(battle)
		return

	manager.call("_cycle_mission")
	await process_frame
	if int(manager.get("current_mission_index")) != 1:
		push_error("Expected mission selection to cycle.")
		_fail(battle)
		return

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

	var status: Dictionary = manager.call("get_beta_status")
	if not bool(status["campaign_completed"]):
		push_error("Expected campaign_completed after three years.")
		_fail(battle)
		return
	if not str(status["final_report"]).contains("3年終了レポート"):
		push_error("Expected final report after three years.")
		_fail(battle)
		return
	if not str(status["last_result_summary"]).contains("MVP"):
		push_error("Expected battle result summary to include MVP.")
		_fail(battle)
		return
	if int(status["last_mvp_member_id"]) < 0:
		push_error("Expected a valid MVP member id.")
		_fail(battle)
		return
	if int(status["completed_years"]) != 3:
		push_error("Expected completed_years to be 3.")
		_fail(battle)
		return
	if int(status["total_battles"]) != 6:
		push_error("Expected total_battles to be 6.")
		_fail(battle)
		return

	var roster: Array = manager.call("get_roster_snapshot")
	var saw_trait: bool = false
	for member: Dictionary in roster:
		if member.has("trait_index"):
			saw_trait = true

	if not saw_trait:
		push_error("Expected roster members to have traits.")
		_fail(battle)
		return
	if int(status["total_mvp_count"]) <= 0:
		push_error("Expected guild history to retain MVP counts across generations.")
		_fail(battle)
		return

	manager.set("fame", 120)
	var rank_status: Dictionary = manager.call("get_beta_status")
	if str(rank_status["guild_rank"]) != "C":
		push_error("Expected guild rank C at fame 120, got %s." % rank_status["guild_rank"])
		_fail(battle)
		return

	print("SMOKE_TEST_PASS beta_completion years=%d battles=%d rank=%s report=%s" % [
		status["completed_years"],
		status["total_battles"],
		rank_status["guild_rank"],
		status["final_report"],
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

	push_error("Battle did not finish within the beta completion smoke test frame budget.")
	return false


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

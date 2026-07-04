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

	var result_label := battle.get_node_or_null("UI/ResultLabel") as Label
	if result_label == null:
		push_error("ResultLabel was not found.")
		_fail(battle)
		return

	var before: Array = manager.call("get_roster_snapshot")
	if before.size() < 3:
		push_error("Expected at least 3 guild members before battle.")
		_fail(battle)
		return

	manager.call("start_battle")
	await process_frame

	for _frame_index: int in 1800:
		await physics_frame
		if manager.get("battle_finished") and result_label.text != "":
			var after: Array = manager.call("get_roster_snapshot")
			if after.size() < 3:
				push_error("Expected at least 3 guild members after battle.")
				_fail(battle)
				return

			var first_before: Dictionary = before[0]
			var first_after: Dictionary = after[0]
			if int(first_after["battles"]) <= int(first_before["battles"]):
				push_error("Expected selected guild member battle count to increase.")
				_fail(battle)
				return

			if int(first_after["xp"]) <= int(first_before["xp"]) and int(first_after["level"]) <= int(first_before["level"]):
				push_error("Expected selected guild member to gain XP or level up.")
				_fail(battle)
				return

			if int(manager.get("current_turn")) != 2:
				push_error("Expected calendar to advance to turn 2 after one battle.")
				_fail(battle)
				return

			print("SMOKE_TEST_PASS guild_progression result=%s turn=%d xp=%d" % [
				result_label.text,
				manager.get("current_turn"),
				first_after["xp"],
			])
			battle.queue_free()
			await process_frame
			quit(0)
			return

	push_error("Battle did not finish within the guild progression smoke test frame budget.")
	_fail(battle)


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

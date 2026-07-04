extends SceneTree

const BATTLE_SCENE := preload("res://battle/BattleScene.tscn")
const SAMPLE_COUNT: int = 3


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var blue_wins: int = 0
	var red_wins: int = 0
	var total_frames: int = 0

	for sample_index: int in SAMPLE_COUNT:
		var battle := BATTLE_SCENE.instantiate()
		root.add_child(battle)
		await process_frame

		var manager := battle.get_node_or_null("BattleManager")
		var result_label := battle.get_node_or_null("UI/ResultLabel") as Label
		if manager == null or result_label == null:
			push_error("Required battle nodes were not found.")
			_fail_instance(battle)
			return

		manager.call("start_battle")
		await process_frame

		var finished: bool = false
		for frame_index: int in 1800:
			await physics_frame
			if bool(manager.get("battle_finished")) and result_label.text != "":
				total_frames += frame_index
				if result_label.text.contains("青チーム"):
					blue_wins += 1
				else:
					red_wins += 1
				finished = true
				break

		if not finished:
			push_error("Balance sample battle %d did not finish." % sample_index)
			_fail_instance(battle)
			return

		battle.queue_free()
		await process_frame

	if blue_wins + red_wins != SAMPLE_COUNT:
		push_error("Balance sample did not count every battle.")
		quit(1)
		return

	print("SMOKE_TEST_PASS balance_sample samples=%d blue=%d red=%d avg_frames=%d" % [
		SAMPLE_COUNT,
		blue_wins,
		red_wins,
		total_frames / SAMPLE_COUNT,
	])
	quit(0)


func _fail_instance(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

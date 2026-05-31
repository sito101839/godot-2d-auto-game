extends SceneTree

const BATTLE_SCENE := preload("res://battle/BattleScene.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BATTLE_SCENE.instantiate()
	root.add_child(battle)

	await process_frame

	var units_parent := battle.get_node_or_null("Units")
	if units_parent == null:
		push_error("Units node was not found.")
		_fail(battle)
		return

	if units_parent.get_child_count() != 6:
		push_error("Expected 6 units, found %d." % units_parent.get_child_count())
		_fail(battle)
		return

	var result_label := battle.get_node_or_null("UI/ResultLabel") as Label
	if result_label == null:
		push_error("ResultLabel was not found.")
		_fail(battle)
		return

	for frame_index: int in 900:
		await physics_frame
		if result_label.text != "":
			print("SMOKE_TEST_PASS battle_result %s frame=%d" % [result_label.text, frame_index])
			battle.queue_free()
			await process_frame
			quit(0)
			return

	push_error("Battle did not finish within the smoke test frame budget.")
	_fail(battle)


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

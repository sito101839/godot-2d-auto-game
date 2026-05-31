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

	if units_parent.get_child_count() != 0:
		push_error("Expected setup screen to start with 0 units, found %d." % units_parent.get_child_count())
		_fail(battle)
		return

	var prep_panel := battle.get_node_or_null("UI/PrepPanel") as Control
	if prep_panel == null or not prep_panel.visible:
		push_error("PrepPanel was not visible at startup.")
		_fail(battle)
		return

	var manager := battle.get_node_or_null("BattleManager")
	if manager == null:
		push_error("BattleManager was not found.")
		_fail(battle)
		return

	manager.call("start_battle")
	await process_frame

	if units_parent.get_child_count() != 6:
		push_error("Expected 6 units, found %d." % units_parent.get_child_count())
		_fail(battle)
		return

	var result_label := battle.get_node_or_null("UI/ResultLabel") as Label
	if result_label == null:
		push_error("ResultLabel was not found.")
		_fail(battle)
		return

	var saw_non_warrior: bool = false
	var saw_policy_variation: bool = false
	for child: Node in units_parent.get_children():
		if child.get("unit_type_name") != "Warrior":
			saw_non_warrior = true
		if child.get("target_policy") != 0:
			saw_policy_variation = true

	if not saw_non_warrior:
		push_error("Expected at least one non-warrior unit from setup defaults.")
		_fail(battle)
		return

	if not saw_policy_variation:
		push_error("Expected at least one non-nearest target policy from setup defaults.")
		_fail(battle)
		return

	for frame_index: int in 900:
		await physics_frame
		if result_label.text != "":
			var result_text: String = result_label.text
			manager.call("_show_prep_screen")
			await process_frame
			if not prep_panel.visible:
				push_error("PrepPanel was not visible after returning from battle.")
				_fail(battle)
				return
			if units_parent.get_child_count() != 0:
				push_error("Expected units to be cleared after returning to setup.")
				_fail(battle)
				return
			print("SMOKE_TEST_PASS battle_result %s frame=%d" % [result_text, frame_index])
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

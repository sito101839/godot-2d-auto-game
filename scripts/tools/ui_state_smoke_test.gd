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

	var start_button := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/StartButton") as Button
	if start_button == null:
		push_error("StartButton was not found.")
		_fail(battle)
		return

	if start_button.text != "任務へ出発":
		push_error("Expected mission start text at year start, got %s." % start_button.text)
		_fail(battle)
		return

	manager.call("_train_guild", "drill")
	await process_frame
	manager.call("_train_guild", "endurance")
	await process_frame
	manager.call("_train_guild", "tactics")
	await process_frame

	if start_button.text != "大会に出場":
		push_error("Expected tournament start text at year-end, got %s." % start_button.text)
		_fail(battle)
		return

	var config_rows := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	if config_rows == null:
		push_error("ConfigRows was not found under RosterScroll.")
		_fail(battle)
		return

	var disabled_training_buttons: int = 0
	for child: Node in config_rows.get_children():
		if child is HBoxContainer:
			for row_child: Node in child.get_children():
				if row_child is Button and row_child.text in ["攻撃訓練", "耐久訓練", "戦術訓練"] and row_child.disabled:
					disabled_training_buttons += 1

	if disabled_training_buttons != 3:
		push_error("Expected 3 disabled training buttons on tournament turn, got %d." % disabled_training_buttons)
		_fail(battle)
		return

	print("SMOKE_TEST_PASS ui_state tournament_text=%s disabled_training=%d" % [start_button.text, disabled_training_buttons])
	battle.queue_free()
	await process_frame
	quit(0)


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

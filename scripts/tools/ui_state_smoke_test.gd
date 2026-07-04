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

	var config_rows := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	if config_rows == null:
		push_error("ConfigRows was not found under RosterScroll.")
		_fail(battle)
		return

	var start_button := _find_latest_named(config_rows, "PrimaryActionButton") as Button
	if start_button == null or start_button.text != "任務へ出発":
		push_error("Expected mission start text at year start.")
		_fail(battle)
		return

	manager.call("_train_guild", "drill")
	await process_frame
	manager.call("_train_guild", "endurance")
	await process_frame
	manager.call("_train_guild", "tactics")
	await process_frame

	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	if config_rows == null:
		push_error("ConfigRows was not found under RosterScroll.")
		_fail(battle)
		return

	start_button = _find_latest_named(config_rows, "PrimaryActionButton") as Button
	if start_button == null or start_button.text != "大会に出場":
		push_error("Expected tournament start text at year-end.")
		_fail(battle)
		return

	var disabled_training_buttons: int = 0
	for button: Button in _collect_buttons(config_rows):
		if button.text in ["攻撃訓練", "耐久訓練", "戦術訓練"] and button.disabled:
			disabled_training_buttons += 1

	if disabled_training_buttons != 3:
		push_error("Expected 3 disabled training buttons on tournament turn, got %d." % disabled_training_buttons)
		_fail(battle)
		return

	print("SMOKE_TEST_PASS ui_state tournament_text=%s disabled_training=%d" % [start_button.text, disabled_training_buttons])
	battle.queue_free()
	await process_frame
	quit(0)


func _find_latest_named(node: Node, target_name: String) -> Node:
	var found: Node = null
	if node.name == target_name:
		found = node
	for child: Node in node.get_children():
		var child_found := _find_latest_named(child, target_name)
		if child_found != null:
			found = child_found
	return found


func _collect_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node as Button)
	for child: Node in node.get_children():
		buttons.append_array(_collect_buttons(child))
	return buttons


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

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

	var prep_content := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent")
	if prep_content == null:
		push_error("PrepContent was not found.")
		_fail(battle)
		return

	var priority_rows := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	if priority_rows == null:
		push_error("PriorityRows was not found.")
		_fail(battle)
		return

	var config_rows := battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	if config_rows == null:
		push_error("ConfigRows was not found.")
		_fail(battle)
		return

	if _find_latest_named(priority_rows, "NextActionPanel") == null:
		push_error("Expected NextActionPanel to explain the next action.")
		_fail(battle)
		return

	var guide_panel := _find_latest_named(config_rows, "FirstRunGuidePanel")
	if guide_panel == null or not _collect_label_text(guide_panel).contains("基本の流れ"):
		push_error("Expected first-run guide to explain the basic flow.")
		_fail(battle)
		return

	var action_panel := _find_latest_named(priority_rows, "ActionPanel")
	if action_panel == null:
		push_error("Expected ActionPanel to group player actions.")
		_fail(battle)
		return
	if _find_latest_named(config_rows, "ActionPanel") != null:
		push_error("ActionPanel should stay outside the scrollable roster area.")
		_fail(battle)
		return

	var primary_action_button := _find_latest_named(action_panel, "PrimaryActionButton") as Button
	if primary_action_button == null or primary_action_button.text != "任務へ出発":
		push_error("Expected primary action button for mission departure.")
		_fail(battle)
		return

	var action_text := _collect_label_text(action_panel)
	if not action_text.contains("育成メニュー") or not action_text.contains("システム"):
		push_error("Expected action panel to separate training and system actions.")
		_fail(battle)
		return

	if _find_latest_named(priority_rows, "ViewTabs") == null:
		push_error("Expected view tabs for screen navigation.")
		_fail(battle)
		return

	manager.call("_set_current_view", "formation")
	await process_frame
	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	var mission_panel := _find_latest_named(config_rows, "MissionSelectionPanel")
	if mission_panel == null:
		push_error("Expected MissionSelectionPanel on formation view.")
		_fail(battle)
		return

	var mission_buttons: Array[Button] = _collect_buttons(mission_panel)
	if mission_buttons.size() != 3:
		push_error("Expected 3 mission comparison buttons, got %d." % mission_buttons.size())
		_fail(battle)
		return

	if not mission_buttons[0].text.contains("選択中") or not mission_buttons[0].text.contains("経験"):
		push_error("Expected selected mission button to show selection and reward comparison.")
		_fail(battle)
		return

	manager.call("_set_current_view", "roster")
	await process_frame
	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	var initial_text := _collect_label_text(config_rows)
	if not initial_text.contains("出撃中:") or not initial_text.contains("役割目安:"):
		if _find_latest_named(config_rows, "MemberSummaryTable") == null or not initial_text.contains("役割目安"):
			push_error("Expected member summaries to show sortie status and role hints.")
			_fail(battle)
			return
	if not initial_text.contains("EXP") or not initial_text.contains("MVP"):
		push_error("Expected member summary table to show growth and achievement columns.")
		_fail(battle)
		return

	manager.call("_set_current_view", "formation")
	await process_frame
	manager.call("_select_mission", 1)
	await process_frame
	if int(manager.get("current_mission_index")) != 1:
		push_error("Expected mission index 1 after selecting the second mission.")
		_fail(battle)
		return

	priority_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	var next_action_panel := _find_latest_named(priority_rows, "NextActionPanel")
	var next_action_text := _collect_label_text(next_action_panel)
	if not next_action_text.contains("護衛任務"):
		push_error("Expected next action panel to reflect the selected mission, got: %s" % next_action_text)
		_fail(battle)
		return

	manager.call("_train_guild", "drill")
	await process_frame
	priority_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	var result_panel := _find_latest_named(config_rows, "ResultPanel")
	var result_text := _collect_label_text(result_panel)
	if not result_text.contains("Gold -10") or not result_text.contains("次のターン"):
		push_error("Expected result panel to show structured training details, got: %s" % result_text)
		_fail(battle)
		return

	manager.call("_train_guild", "endurance")
	await process_frame
	manager.call("_train_guild", "tactics")
	await process_frame

	priority_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	var tournament_action_panel := _find_latest_named(priority_rows, "ActionPanel")
	var tournament_primary_button := _find_latest_named(tournament_action_panel, "PrimaryActionButton") as Button
	if tournament_primary_button == null or tournament_primary_button.text != "大会に出場":
		push_error("Expected tournament primary action after three trainings.")
		_fail(battle)
		return

	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	priority_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	if _find_latest_named(config_rows, "MissionSelectionPanel") != null or _find_latest_named(priority_rows, "MissionSelectionPanel") != null:
		push_error("Mission selection should be hidden on tournament turns.")
		_fail(battle)
		return

	var disabled_training_buttons: int = 0
	for button: Button in _collect_buttons(prep_content):
		if button.text in ["攻撃訓練", "耐久訓練", "戦術訓練"] and button.disabled:
			disabled_training_buttons += 1

	if disabled_training_buttons != 3:
		push_error("Expected 3 disabled training buttons on tournament turn, got %d." % disabled_training_buttons)
		_fail(battle)
		return

	manager.set("campaign_completed", true)
	manager.set("final_report", "3年終了レポート: テスト")
	manager.call("_show_prep_screen")
	await process_frame
	priority_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/PriorityRows")
	config_rows = battle.get_node_or_null("UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows")
	var completed_button := _find_latest_named(priority_rows, "PrimaryActionButton") as Button
	if completed_button == null or completed_button.text != "3年終了" or not completed_button.disabled:
		push_error("Expected completed campaign to disable the primary action.")
		_fail(battle)
		return
	if _find_latest_named(config_rows, "MilestonePanel") == null:
		push_error("Expected milestone panel after campaign completion.")
		_fail(battle)
		return

	print("SMOKE_TEST_PASS ux_flow missions=%d disabled_training=%d" % [mission_buttons.size(), disabled_training_buttons])
	battle.queue_free()
	await process_frame
	quit(0)


func _collect_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node as Button)
	for child: Node in node.get_children():
		buttons.append_array(_collect_buttons(child))
	return buttons


func _find_latest_named(node: Node, target_name: String) -> Node:
	var found: Node = null
	if node.name == target_name:
		found = node
	for child: Node in node.get_children():
		var child_found := _find_latest_named(child, target_name)
		if child_found != null:
			found = child_found
	return found


func _collect_label_text(node: Node) -> String:
	if node == null:
		return ""

	var text := ""
	if node is Label:
		text += (node as Label).text
	for child: Node in node.get_children():
		text += "\n" + _collect_label_text(child)
	return text


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

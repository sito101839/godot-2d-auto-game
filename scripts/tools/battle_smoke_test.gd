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
	var saw_backline: bool = false
	var saw_flanker: bool = false
	var starting_hp_total: int = 0
	for child: Node in units_parent.get_children():
		if child.get("unit_type_name") != "Warrior":
			saw_non_warrior = true
		if child.get("target_policy") != 0:
			saw_policy_variation = true
		if child.get("formation_role") == 1:
			saw_backline = true
		if child.get("formation_role") == 2:
			saw_flanker = true
		starting_hp_total += child.get("hp")

	if not saw_non_warrior:
		push_error("Expected at least one non-warrior unit from setup defaults.")
		_fail(battle)
		return

	if not saw_policy_variation:
		push_error("Expected at least one non-nearest target policy from setup defaults.")
		_fail(battle)
		return

	if not saw_backline or not saw_flanker:
		push_error("Expected backline and flanker roles from setup defaults.")
		_fail(battle)
		return

	for _frame_index: int in 90:
		await physics_frame

	if not _backline_is_behind_frontline(units_parent, 0):
		push_error("Blue backline did not move behind its frontline center.")
		_fail(battle)
		return

	if not _backline_is_behind_frontline(units_parent, 1):
		push_error("Red backline did not move behind its frontline center.")
		_fail(battle)
		return

	for _frame_index: int in 120:
		await physics_frame

	if _has_unit_overlap(units_parent):
		push_error("Units overlapped after separation steering had time to settle.")
		_fail(battle)
		return

	var effects_node := battle.get_node_or_null("Effects")
	var saw_attack_effect: bool = false
	for frame_index: int in 1800:
		await physics_frame
		if effects_node != null and effects_node.get_child_count() > 0:
			saw_attack_effect = true
		if result_label.text != "":
			if not saw_attack_effect:
				push_error("Battle finished before any attack effect was observed.")
				_fail(battle)
				return
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

	var current_hp_total: int = 0
	var unit_snapshots: Array[String] = []
	for child: Node in units_parent.get_children():
		current_hp_total += child.get("hp")
		unit_snapshots.append(
			"%s team=%d role=%d pos=%s hp=%d"
			% [
				child.get("unit_type_name"),
				child.get("team_id"),
				child.get("formation_role"),
				child.get("global_position"),
				child.get("hp"),
			]
		)
	push_error(
		"Battle did not finish within the smoke test frame budget. effects=%s hp_start=%d hp_now=%d units=%d snapshots=%s"
		% [saw_attack_effect, starting_hp_total, current_hp_total, units_parent.get_child_count(), unit_snapshots]
	)
	_fail(battle)


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)


func _backline_is_behind_frontline(units_parent: Node, team_id: int) -> bool:
	var frontline_sum: float = 0.0
	var frontline_count: int = 0
	var backline_x: float = INF

	for child: Node in units_parent.get_children():
		if child.get("team_id") != team_id:
			continue
		if child.get("formation_role") == 0:
			frontline_sum += child.get("global_position").x
			frontline_count += 1
		elif child.get("formation_role") == 1:
			backline_x = child.get("global_position").x

	if frontline_count == 0 or backline_x == INF:
		return false

	var frontline_center_x: float = frontline_sum / float(frontline_count)
	if team_id == 0:
		return backline_x < frontline_center_x

	return backline_x > frontline_center_x


func _has_unit_overlap(units_parent: Node) -> bool:
	var units: Array[Node] = []
	for child: Node in units_parent.get_children():
		if not child.get("is_dead"):
			units.append(child)

	for first_index: int in units.size():
		for second_index: int in range(first_index + 1, units.size()):
			var first_position: Vector2 = units[first_index].get("global_position")
			var second_position: Vector2 = units[second_index].get("global_position")
			if first_position.distance_to(second_position) < 24.0:
				return true

	return false

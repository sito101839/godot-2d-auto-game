extends SceneTree

const UNIT_SCENE := preload("res://units/Unit.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var units_parent := Node2D.new()
	var effects_parent := Node2D.new()
	root.add_child(units_parent)
	root.add_child(effects_parent)

	var attacker := _spawn_unit(units_parent, effects_parent, 0, Vector2.ZERO, 1, 1, 100)
	attacker.set("attack_range", 120.0)

	var high_hp_enemy := _spawn_unit(units_parent, effects_parent, 1, Vector2(80.0, 0.0), 0, 0, 150)
	var low_hp_enemy := _spawn_unit(units_parent, effects_parent, 1, Vector2(280.0, 0.0), 0, 0, 10)

	await process_frame

	var selected := attacker.call("_find_target") as Node
	if selected != high_hp_enemy:
		push_error("Expected in-range high HP enemy to be selected before out-of-range low HP enemy.")
		_fail(units_parent, effects_parent)
		return

	high_hp_enemy.global_position = Vector2(180.0, 0.0)
	selected = attacker.call("_find_target") as Node
	if selected != low_hp_enemy:
		push_error("Expected low HP enemy to be selected when no enemies are in attack range.")
		_fail(units_parent, effects_parent)
		return

	units_parent.queue_free()
	effects_parent.queue_free()
	await process_frame
	print("SMOKE_TEST_PASS target_selection")
	quit(0)


func _spawn_unit(
	units_parent: Node2D,
	effects_parent: Node2D,
	team_id: int,
	spawn_position: Vector2,
	target_policy: int,
	formation_role: int,
	hp: int
) -> CharacterBody2D:
	var unit := UNIT_SCENE.instantiate() as CharacterBody2D
	units_parent.add_child(unit)
	unit.global_position = spawn_position
	unit.setup(
		team_id,
		Color.WHITE,
		"Test",
		target_policy,
		formation_role,
		hp,
		10,
		80.0,
		80.0,
		effects_parent
	)
	return unit


func _fail(units_parent: Node, effects_parent: Node) -> void:
	if is_instance_valid(units_parent):
		units_parent.queue_free()
	if is_instance_valid(effects_parent):
		effects_parent.queue_free()
	await process_frame
	quit(1)

extends Node

const UNIT_SCENE := preload("res://units/Unit.tscn")

const BLUE_TEAM_ID: int = 0
const RED_TEAM_ID: int = 1
const BLUE_COLOR: Color = Color(0.2, 0.45, 1.0)
const RED_COLOR: Color = Color(1.0, 0.2, 0.18)

@onready var units_parent: Node2D = $"../Units"
@onready var result_label: Label = $"../UI/ResultLabel"

var battle_finished: bool = false


func _ready() -> void:
	start_battle()


func _process(_delta: float) -> void:
	if battle_finished:
		return

	_check_battle_result()


func start_battle() -> void:
	battle_finished = false
	result_label.text = ""

	for child: Node in units_parent.get_children():
		child.queue_free()

	var blue_positions: Array[Vector2] = [
		Vector2(-250.0, -80.0),
		Vector2(-250.0, 0.0),
		Vector2(-250.0, 80.0),
	]
	var red_positions: Array[Vector2] = [
		Vector2(250.0, -80.0),
		Vector2(250.0, 0.0),
		Vector2(250.0, 80.0),
	]

	for spawn_position: Vector2 in blue_positions:
		_spawn_unit(BLUE_TEAM_ID, BLUE_COLOR, spawn_position)

	for spawn_position: Vector2 in red_positions:
		_spawn_unit(RED_TEAM_ID, RED_COLOR, spawn_position)


func _spawn_unit(team_id: int, color: Color, spawn_position: Vector2) -> void:
	var unit := UNIT_SCENE.instantiate() as CharacterBody2D
	units_parent.add_child(unit)
	unit.global_position = spawn_position
	unit.call("setup", team_id, color)
	unit.reset_physics_interpolation()


func _check_battle_result() -> void:
	var blue_alive: int = _count_alive_units(BLUE_TEAM_ID)
	var red_alive: int = _count_alive_units(RED_TEAM_ID)

	if blue_alive == 0:
		_finish_battle("Red Team Wins!")
	elif red_alive == 0:
		_finish_battle("Blue Team Wins!")


func _count_alive_units(team_id: int) -> int:
	var count: int = 0

	for node: Node in get_tree().get_nodes_in_group("units"):
		if node.get("team_id") == team_id and not node.get("is_dead"):
			count += 1

	return count


func _finish_battle(message: String) -> void:
	battle_finished = true
	result_label.text = message
	print("BATTLE_RESULT %s" % message)

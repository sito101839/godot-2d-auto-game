extends Node

const UNIT_SCENE := preload("res://units/Unit.tscn")

const BLUE_TEAM_ID: int = 0
const RED_TEAM_ID: int = 1
const BLUE_COLOR: Color = Color(0.2, 0.45, 1.0)
const RED_COLOR: Color = Color(1.0, 0.2, 0.18)

const UNIT_DEFINITIONS: Array[Dictionary] = [
	{
		"name": "Warrior",
		"hp": 150,
		"attack_power": 14,
		"attack_range": 55.0,
		"move_speed": 72.0,
	},
	{
		"name": "Archer",
		"hp": 85,
		"attack_power": 11,
		"attack_range": 155.0,
		"move_speed": 84.0,
	},
	{
		"name": "Rogue",
		"hp": 100,
		"attack_power": 18,
		"attack_range": 45.0,
		"move_speed": 118.0,
	},
]

const TARGET_POLICIES: Array[Dictionary] = [
	{"name": "Nearest", "value": 0},
	{"name": "Low HP", "value": 1},
	{"name": "High HP", "value": 2},
]

@onready var units_parent: Node2D = $"../Units"
@onready var result_label: Label = $"../UI/ResultLabel"
@onready var prep_panel: Control = $"../UI/PrepPanel"
@onready var config_rows: VBoxContainer = $"../UI/PrepPanel/MarginContainer/PrepContent/ConfigRows"
@onready var start_button: Button = $"../UI/PrepPanel/MarginContainer/PrepContent/StartButton"
@onready var return_button: Button = $"../UI/ReturnButton"

var battle_finished: bool = false
var blue_unit_choices: Array[int] = [0, 1, 2]
var red_unit_choices: Array[int] = [0, 1, 2]
var blue_target_choices: Array[int] = [0, 1, 2]
var red_target_choices: Array[int] = [0, 1, 2]
var unit_buttons: Array[Button] = []
var target_buttons: Array[Button] = []


func _ready() -> void:
	start_button.pressed.connect(start_battle)
	return_button.pressed.connect(_show_prep_screen)
	_build_prep_rows()
	_show_prep_screen()


func _process(_delta: float) -> void:
	if battle_finished or prep_panel.visible:
		return

	_check_battle_result()


func start_battle() -> void:
	battle_finished = false
	prep_panel.visible = false
	return_button.visible = false
	result_label.text = ""
	_clear_units()

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

	for index: int in blue_positions.size():
		_spawn_unit(
			BLUE_TEAM_ID,
			BLUE_COLOR,
			blue_positions[index],
			blue_unit_choices[index],
			blue_target_choices[index]
		)

	for index: int in red_positions.size():
		_spawn_unit(
			RED_TEAM_ID,
			RED_COLOR,
			red_positions[index],
			red_unit_choices[index],
			red_target_choices[index]
		)


func _show_prep_screen() -> void:
	battle_finished = true
	prep_panel.visible = true
	return_button.visible = false
	result_label.text = ""
	_clear_units()
	_refresh_prep_buttons()
	start_button.grab_focus()


func _build_prep_rows() -> void:
	for child: Node in config_rows.get_children():
		child.queue_free()

	unit_buttons.clear()
	target_buttons.clear()

	_add_team_header("Blue Team")
	for slot_index: int in 3:
		_add_config_row(BLUE_TEAM_ID, slot_index)

	_add_team_header("Red Team")
	for slot_index: int in 3:
		_add_config_row(RED_TEAM_ID, slot_index)

	_refresh_prep_buttons()


func _add_team_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	config_rows.add_child(label)


func _add_config_row(team_id: int, slot_index: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 38.0)
	config_rows.add_child(row)

	var slot_label := Label.new()
	slot_label.custom_minimum_size = Vector2(92.0, 0.0)
	slot_label.text = "%s %d" % ["Blue" if team_id == BLUE_TEAM_ID else "Red", slot_index + 1]
	row.add_child(slot_label)

	var unit_button := Button.new()
	unit_button.custom_minimum_size = Vector2(180.0, 0.0)
	unit_button.focus_mode = Control.FOCUS_ALL
	unit_button.pressed.connect(_cycle_unit_choice.bind(team_id, slot_index))
	row.add_child(unit_button)
	unit_buttons.append(unit_button)

	var target_button := Button.new()
	target_button.custom_minimum_size = Vector2(180.0, 0.0)
	target_button.focus_mode = Control.FOCUS_ALL
	target_button.pressed.connect(_cycle_target_choice.bind(team_id, slot_index))
	row.add_child(target_button)
	target_buttons.append(target_button)


func _cycle_unit_choice(team_id: int, slot_index: int) -> void:
	var choices: Array[int] = blue_unit_choices if team_id == BLUE_TEAM_ID else red_unit_choices
	choices[slot_index] = (choices[slot_index] + 1) % UNIT_DEFINITIONS.size()
	_refresh_prep_buttons()


func _cycle_target_choice(team_id: int, slot_index: int) -> void:
	var choices: Array[int] = blue_target_choices if team_id == BLUE_TEAM_ID else red_target_choices
	choices[slot_index] = (choices[slot_index] + 1) % TARGET_POLICIES.size()
	_refresh_prep_buttons()


func _refresh_prep_buttons() -> void:
	var button_index: int = 0

	for slot_index: int in 3:
		_update_config_buttons(button_index, blue_unit_choices[slot_index], blue_target_choices[slot_index])
		button_index += 1

	for slot_index: int in 3:
		_update_config_buttons(button_index, red_unit_choices[slot_index], red_target_choices[slot_index])
		button_index += 1


func _update_config_buttons(button_index: int, unit_index: int, target_index: int) -> void:
	if button_index >= unit_buttons.size() or button_index >= target_buttons.size():
		return

	var unit_data: Dictionary = UNIT_DEFINITIONS[unit_index]
	var target_data: Dictionary = TARGET_POLICIES[target_index]
	unit_buttons[button_index].text = "%s  HP:%d ATK:%d RNG:%d SPD:%d" % [
		unit_data["name"],
		unit_data["hp"],
		unit_data["attack_power"],
		int(unit_data["attack_range"]),
		int(unit_data["move_speed"]),
	]
	target_buttons[button_index].text = "Target: %s" % target_data["name"]


func _spawn_unit(
	team_id: int,
	color: Color,
	spawn_position: Vector2,
	unit_definition_index: int,
	target_policy_index: int
) -> void:
	var unit_data: Dictionary = UNIT_DEFINITIONS[unit_definition_index]
	var target_data: Dictionary = TARGET_POLICIES[target_policy_index]
	var unit := UNIT_SCENE.instantiate() as CharacterBody2D

	units_parent.add_child(unit)
	unit.global_position = spawn_position
	unit.call(
		"setup",
		team_id,
		color,
		unit_data["name"],
		target_data["value"],
		unit_data["hp"],
		unit_data["attack_power"],
		unit_data["attack_range"],
		unit_data["move_speed"]
	)
	unit.reset_physics_interpolation()


func _clear_units() -> void:
	for child: Node in units_parent.get_children():
		child.queue_free()


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
	return_button.visible = true
	print("BATTLE_RESULT %s" % message)

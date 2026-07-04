extends Node

const UNIT_SCENE := preload("res://units/Unit.tscn")

const BLUE_TEAM_ID: int = 0
const RED_TEAM_ID: int = 1
const BLUE_COLOR: Color = Color(0.2, 0.45, 1.0)
const RED_COLOR: Color = Color(1.0, 0.2, 0.18)
const MAX_ACTIVE_MEMBERS: int = 3
const TURNS_PER_YEAR: int = 4
const GRADUATION_YEARS: int = 3
const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://guild_save.json"

const UNIT_DEFINITIONS: Array[Dictionary] = [
	{
		"name": "Warrior",
		"display_name": "戦士",
		"hp": 150,
		"attack_power": 14,
		"attack_range": 55.0,
		"move_speed": 72.0,
		"growth": {"hp": 14, "attack_power": 2, "attack_range": 1.0, "move_speed": 1.0},
	},
	{
		"name": "Archer",
		"display_name": "弓使い",
		"hp": 85,
		"attack_power": 11,
		"attack_range": 155.0,
		"move_speed": 84.0,
		"growth": {"hp": 8, "attack_power": 2, "attack_range": 5.0, "move_speed": 2.0},
	},
	{
		"name": "Rogue",
		"display_name": "盗賊",
		"hp": 100,
		"attack_power": 18,
		"attack_range": 45.0,
		"move_speed": 118.0,
		"growth": {"hp": 9, "attack_power": 3, "attack_range": 1.0, "move_speed": 4.0},
	},
	{
		"name": "Mage",
		"display_name": "魔術師",
		"hp": 72,
		"attack_power": 22,
		"attack_range": 135.0,
		"move_speed": 70.0,
		"growth": {"hp": 6, "attack_power": 4, "attack_range": 4.0, "move_speed": 1.0},
	},
	{
		"name": "Cleric",
		"display_name": "神官",
		"hp": 105,
		"attack_power": 10,
		"attack_range": 120.0,
		"move_speed": 76.0,
		"growth": {"hp": 11, "attack_power": 1, "attack_range": 3.0, "move_speed": 1.0},
	},
]

const TARGET_POLICIES: Array[Dictionary] = [
	{"name": "Nearest", "display_name": "近い敵", "value": 0},
	{"name": "Low HP", "display_name": "低HP", "value": 1},
	{"name": "High HP", "display_name": "高HP", "value": 2},
]

const FORMATION_ROLES: Array[Dictionary] = [
	{"name": "Frontline", "display_name": "前衛", "value": 0},
	{"name": "Backline", "display_name": "後衛", "value": 1},
	{"name": "Flanker", "display_name": "遊撃", "value": 2},
]

const MEMBER_NAMES: Array[String] = [
	"アルマ",
	"ブラム",
	"シエル",
	"ドラン",
	"エリーゼ",
	"フェン",
	"ギード",
	"ヒルダ",
	"イリス",
	"ユノ",
]

@onready var units_parent: Node2D = $"../Units"
@onready var effects_parent: Node2D = $"../Effects"
@onready var result_label: Label = $"../UI/ResultLabel"
@onready var prep_panel: Control = $"../UI/PrepPanel"
@onready var config_rows: VBoxContainer = $"../UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows"
@onready var start_button: Button = $"../UI/PrepPanel/MarginContainer/PrepContent/StartButton"
@onready var return_button: Button = $"../UI/ReturnButton"

var battle_finished: bool = false
var guild_name: String = "暁の旅団"
var current_year: int = 1
var current_turn: int = 1
var fame: int = 0
var gold: int = 120
var completed_years: int = 0
var current_year_wins: int = 0
var current_year_losses: int = 0
var total_battles: int = 0
var tournament_wins: int = 0
var next_member_id: int = 1
var current_battle_kind: String = "mission"
var last_result_summary: String = "ようこそ、ギルドマスター。"
var save_path: String = SAVE_PATH
var guild_members: Array[Dictionary] = []
var selected_member_indices: Array[int] = [0, 1, 2]
var unit_buttons: Array[Button] = []
var target_buttons: Array[Button] = []
var role_buttons: Array[Button] = []


func _ready() -> void:
	start_button.pressed.connect(start_battle)
	return_button.pressed.connect(_show_prep_screen)
	_create_initial_roster()
	_show_prep_screen()


func _process(_delta: float) -> void:
	if battle_finished or prep_panel.visible:
		return

	_check_battle_result()


func start_battle() -> void:
	if guild_members.is_empty():
		return

	current_battle_kind = "tournament" if current_turn == TURNS_PER_YEAR else "mission"
	battle_finished = false
	prep_panel.visible = false
	return_button.visible = false
	result_label.text = ""
	_clear_units()
	_clear_effects()

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

	_normalize_selected_members()
	for index: int in MAX_ACTIVE_MEMBERS:
		var member: Dictionary = guild_members[selected_member_indices[index]]
		_spawn_member_unit(member, BLUE_TEAM_ID, BLUE_COLOR, blue_positions[index])

	var enemy_level: int = _get_enemy_level()
	for index: int in red_positions.size():
		var enemy: Dictionary = _create_enemy_member(index, enemy_level)
		_spawn_member_unit(enemy, RED_TEAM_ID, RED_COLOR, red_positions[index])


func _show_prep_screen() -> void:
	battle_finished = true
	prep_panel.visible = true
	return_button.visible = false
	result_label.text = ""
	_clear_units()
	_clear_effects()
	_build_prep_rows()
	start_button.text = "大会に出場" if current_turn == TURNS_PER_YEAR else "任務開始"
	start_button.grab_focus()


func _create_initial_roster() -> void:
	if not guild_members.is_empty():
		return

	for index: int in 6:
		guild_members.append(_create_guild_member(index % UNIT_DEFINITIONS.size(), index))


func _create_guild_member(class_index: int, seed_index: int) -> Dictionary:
	var class_data: Dictionary = UNIT_DEFINITIONS[class_index]
	var member_name: String = MEMBER_NAMES[(next_member_id - 1) % MEMBER_NAMES.size()]
	var member := {
		"id": next_member_id,
		"name": member_name,
		"class_index": class_index,
		"level": 1,
		"xp": 0,
		"years_in_guild": 1,
		"hp": class_data["hp"],
		"attack_power": class_data["attack_power"],
		"attack_range": class_data["attack_range"],
		"move_speed": class_data["move_speed"],
		"target_policy": seed_index % TARGET_POLICIES.size(),
		"formation_role": seed_index % FORMATION_ROLES.size(),
		"battles": 0,
		"wins": 0,
	}
	next_member_id += 1
	return member


func _build_prep_rows() -> void:
	for child: Node in config_rows.get_children():
		child.queue_free()

	unit_buttons.clear()
	target_buttons.clear()
	role_buttons.clear()
	_normalize_selected_members()

	_add_title("%s  %d年目 %dターン  名声 %d  所持金 %d" % [guild_name, current_year, current_turn, fame, gold])
	_add_note("成績: %d年目 %d勝%d敗  通算戦闘 %d  大会優勝 %d" % [
		current_year,
		current_year_wins,
		current_year_losses,
		total_battles,
		tournament_wins,
	])
	_add_note(last_result_summary)
	_add_section_header("出撃メンバー")
	for slot_index: int in MAX_ACTIVE_MEMBERS:
		_add_party_row(slot_index)

	_add_section_header("所属メンバー")
	for member_index: int in guild_members.size():
		_add_member_summary(member_index)

	_add_section_header("ギルド活動")
	_add_action_row()


func _add_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	config_rows.add_child(label)


func _add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0.0, 38.0)
	config_rows.add_child(label)


func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	config_rows.add_child(label)


func _add_party_row(slot_index: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 36.0)
	config_rows.add_child(row)

	var slot_label := Label.new()
	slot_label.custom_minimum_size = Vector2(72.0, 0.0)
	slot_label.text = "枠 %d" % (slot_index + 1)
	row.add_child(slot_label)

	var member_button := Button.new()
	member_button.custom_minimum_size = Vector2(250.0, 0.0)
	member_button.focus_mode = Control.FOCUS_ALL
	member_button.pressed.connect(_cycle_selected_member.bind(slot_index))
	row.add_child(member_button)
	unit_buttons.append(member_button)

	var target_button := Button.new()
	target_button.custom_minimum_size = Vector2(150.0, 0.0)
	target_button.focus_mode = Control.FOCUS_ALL
	target_button.pressed.connect(_cycle_target_choice.bind(slot_index))
	row.add_child(target_button)
	target_buttons.append(target_button)

	var role_button := Button.new()
	role_button.custom_minimum_size = Vector2(132.0, 0.0)
	role_button.focus_mode = Control.FOCUS_ALL
	role_button.pressed.connect(_cycle_role_choice.bind(slot_index))
	row.add_child(role_button)
	role_buttons.append(role_button)

	_refresh_party_row(slot_index)


func _add_member_summary(member_index: int) -> void:
	var member: Dictionary = guild_members[member_index]
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var label := Label.new()
	label.text = "%s  Lv%d %s  HP:%d 攻撃:%d 射程:%d 速度:%d  経験:%d/%d  在籍:%d年" % [
		member["name"],
		member["level"],
		class_data["display_name"],
		member["hp"],
		member["attack_power"],
		int(member["attack_range"]),
		int(member["move_speed"]),
		member["xp"],
		_get_xp_to_next(member),
		member["years_in_guild"],
	]
	config_rows.add_child(label)


func _add_action_row() -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 42.0)
	config_rows.add_child(row)
	var tournament_turn: bool = current_turn == TURNS_PER_YEAR

	var drill_button := Button.new()
	drill_button.text = "攻撃訓練"
	drill_button.custom_minimum_size = Vector2(160.0, 0.0)
	drill_button.focus_mode = Control.FOCUS_ALL
	drill_button.disabled = tournament_turn
	drill_button.pressed.connect(_train_guild.bind("drill"))
	row.add_child(drill_button)

	var endurance_button := Button.new()
	endurance_button.text = "耐久訓練"
	endurance_button.custom_minimum_size = Vector2(160.0, 0.0)
	endurance_button.focus_mode = Control.FOCUS_ALL
	endurance_button.disabled = tournament_turn
	endurance_button.pressed.connect(_train_guild.bind("endurance"))
	row.add_child(endurance_button)

	var tactics_button := Button.new()
	tactics_button.text = "戦術訓練"
	tactics_button.custom_minimum_size = Vector2(160.0, 0.0)
	tactics_button.focus_mode = Control.FOCUS_ALL
	tactics_button.disabled = tournament_turn
	tactics_button.pressed.connect(_train_guild.bind("tactics"))
	row.add_child(tactics_button)

	var save_button := Button.new()
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(110.0, 0.0)
	save_button.focus_mode = Control.FOCUS_ALL
	save_button.pressed.connect(save_game)
	row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "読込"
	load_button.custom_minimum_size = Vector2(110.0, 0.0)
	load_button.focus_mode = Control.FOCUS_ALL
	load_button.pressed.connect(load_game)
	row.add_child(load_button)


func _refresh_party_row(slot_index: int) -> void:
	if slot_index >= unit_buttons.size():
		return

	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var target_data: Dictionary = TARGET_POLICIES[member["target_policy"]]
	var role_data: Dictionary = FORMATION_ROLES[member["formation_role"]]
	unit_buttons[slot_index].text = "%s  Lv%d %s" % [member["name"], member["level"], class_data["display_name"]]
	target_buttons[slot_index].text = "狙い: %s" % target_data["display_name"]
	role_buttons[slot_index].text = "役割: %s" % role_data["display_name"]


func _cycle_selected_member(slot_index: int) -> void:
	if guild_members.size() <= 1:
		return

	var next_index: int = selected_member_indices[slot_index]
	for _attempt: int in guild_members.size():
		next_index = (next_index + 1) % guild_members.size()
		if not selected_member_indices.has(next_index):
			selected_member_indices[slot_index] = next_index
			break

	_build_prep_rows()


func _cycle_target_choice(slot_index: int) -> void:
	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	member["target_policy"] = (int(member["target_policy"]) + 1) % TARGET_POLICIES.size()
	_build_prep_rows()


func _cycle_role_choice(slot_index: int) -> void:
	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	member["formation_role"] = (int(member["formation_role"]) + 1) % FORMATION_ROLES.size()
	_build_prep_rows()


func _train_guild(training_type: String) -> void:
	for index: int in guild_members.size():
		var member: Dictionary = guild_members[index]
		match training_type:
			"endurance":
				member["hp"] = int(member["hp"]) + 4
				_award_member_xp(index, 8)
			"tactics":
				member["attack_range"] = float(member["attack_range"]) + 1.5
				member["move_speed"] = float(member["move_speed"]) + 0.5
				_award_member_xp(index, 8)
			_:
				member["attack_power"] = int(member["attack_power"]) + 1
				_award_member_xp(index, 8)

	gold = max(0, gold - 10)
	last_result_summary = "%sを行いました。全員が経験値を獲得しました。" % _get_training_display_name(training_type)
	_advance_calendar()
	_show_prep_screen()


func _get_training_display_name(training_type: String) -> String:
	match training_type:
		"endurance":
			return "耐久訓練"
		"tactics":
			return "戦術訓練"
		_:
			return "攻撃訓練"


func _spawn_member_unit(member: Dictionary, team_id: int, color: Color, spawn_position: Vector2) -> void:
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var unit := UNIT_SCENE.instantiate() as CharacterBody2D

	units_parent.add_child(unit)
	unit.global_position = spawn_position
	unit.call(
		"setup",
		team_id,
		color,
		class_data["name"],
		member["target_policy"],
		member["formation_role"],
		member["hp"],
		member["attack_power"],
		member["attack_range"],
		member["move_speed"],
		effects_parent,
		member["name"],
		member["level"],
		member.get("id", -1)
	)
	unit.reset_physics_interpolation()


func _create_enemy_member(slot_index: int, enemy_level: int) -> Dictionary:
	var class_index: int = (slot_index + current_year + current_turn) % UNIT_DEFINITIONS.size()
	var class_data: Dictionary = UNIT_DEFINITIONS[class_index]
	var scale: int = max(0, enemy_level - 1)
	return {
		"id": -100 - slot_index,
		"name": "ライバル%d" % (slot_index + 1),
		"class_index": class_index,
		"level": enemy_level,
		"hp": int(class_data["hp"]) + scale * 10,
		"attack_power": int(class_data["attack_power"]) + scale * 2,
		"attack_range": float(class_data["attack_range"]) + scale * 2.0,
		"move_speed": float(class_data["move_speed"]) + scale * 1.5,
		"target_policy": slot_index % TARGET_POLICIES.size(),
		"formation_role": slot_index % FORMATION_ROLES.size(),
	}


func _get_enemy_level() -> int:
	var level: int = current_year + int(floor(float(fame) / 30.0))
	if current_battle_kind == "tournament":
		level += 1
	return max(1, level)


func _clear_units() -> void:
	for child: Node in units_parent.get_children():
		child.queue_free()


func _clear_effects() -> void:
	for child: Node in effects_parent.get_children():
		child.queue_free()


func _check_battle_result() -> void:
	var blue_alive: int = _count_alive_units(BLUE_TEAM_ID)
	var red_alive: int = _count_alive_units(RED_TEAM_ID)

	if blue_alive == 0:
		_finish_battle("赤チーム勝利！", false)
	elif red_alive == 0:
		_finish_battle("青チーム勝利！", true)


func _count_alive_units(team_id: int) -> int:
	var count: int = 0

	for node: Node in get_tree().get_nodes_in_group("units"):
		if node.get("team_id") == team_id and not node.get("is_dead"):
			count += 1

	return count


func _finish_battle(message: String, blue_won: bool) -> void:
	battle_finished = true
	result_label.text = message
	return_button.visible = true
	_apply_battle_rewards(blue_won)
	print("BATTLE_RESULT %s" % message)


func _apply_battle_rewards(blue_won: bool) -> void:
	var base_xp: int = 36 if current_battle_kind == "tournament" else 24
	var win_xp: int = 18 if blue_won else 6
	var fame_gain: int = 12 if blue_won else 3
	var gold_gain: int = 35 if blue_won else 12
	if current_battle_kind == "tournament":
		fame_gain *= 2
		gold_gain *= 2
		if blue_won:
			tournament_wins += 1

	for member_index: int in selected_member_indices:
		if member_index < 0 or member_index >= guild_members.size():
			continue
		var member: Dictionary = guild_members[member_index]
		member["battles"] = int(member["battles"]) + 1
		if blue_won:
			member["wins"] = int(member["wins"]) + 1
		_award_member_xp(member_index, base_xp + win_xp)

	fame += fame_gain
	gold += gold_gain
	total_battles += 1
	if blue_won:
		current_year_wins += 1
	else:
		current_year_losses += 1
	last_result_summary = "%s完了。%s 名声 +%d、所持金 +%d。" % [
		"大会" if current_battle_kind == "tournament" else "任務",
		"勝利！" if blue_won else "敗北。",
		fame_gain,
		gold_gain,
	]
	_advance_calendar()


func _award_member_xp(member_index: int, amount: int) -> void:
	if member_index < 0 or member_index >= guild_members.size():
		return

	var member: Dictionary = guild_members[member_index]
	member["xp"] = int(member["xp"]) + amount
	while int(member["xp"]) >= _get_xp_to_next(member):
		member["xp"] = int(member["xp"]) - _get_xp_to_next(member)
		_level_up_member(member)


func _level_up_member(member: Dictionary) -> void:
	member["level"] = int(member["level"]) + 1
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var growth: Dictionary = class_data["growth"]
	member["hp"] = int(member["hp"]) + int(growth["hp"])
	member["attack_power"] = int(member["attack_power"]) + int(growth["attack_power"])
	member["attack_range"] = float(member["attack_range"]) + float(growth["attack_range"])
	member["move_speed"] = float(member["move_speed"]) + float(growth["move_speed"])


func _get_xp_to_next(member: Dictionary) -> int:
	return 40 + int(member["level"]) * 12


func _advance_calendar() -> void:
	current_turn += 1
	if current_turn <= TURNS_PER_YEAR:
		return

	var finished_year: int = current_year
	var wins: int = current_year_wins
	var losses: int = current_year_losses
	current_turn = 1
	current_year += 1
	completed_years += 1
	_process_year_end(finished_year, wins, losses)


func _process_year_end(finished_year: int, wins: int, losses: int) -> void:
	for member: Dictionary in guild_members:
		member["years_in_guild"] = int(member["years_in_guild"]) + 1

	var graduates: Array[String] = []
	for index: int in range(guild_members.size() - 1, -1, -1):
		var member: Dictionary = guild_members[index]
		if int(member["years_in_guild"]) > GRADUATION_YEARS:
			graduates.append(member["name"])
			guild_members.remove_at(index)

	while guild_members.size() < 6:
		guild_members.append(_create_guild_member((next_member_id - 1) % UNIT_DEFINITIONS.size(), next_member_id))

	_normalize_selected_members()
	last_result_summary += " %d年目は%d勝%d敗で終了。" % [finished_year, wins, losses]
	if not graduates.is_empty():
		last_result_summary += " 卒業: %s。新人が加入しました。" % "、".join(graduates)
	else:
		last_result_summary += " 新しい一年が始まります。"
	current_year_wins = 0
	current_year_losses = 0


func _normalize_selected_members() -> void:
	if guild_members.is_empty():
		selected_member_indices.clear()
		return

	while selected_member_indices.size() < MAX_ACTIVE_MEMBERS:
		selected_member_indices.append(0)

	for slot_index: int in MAX_ACTIVE_MEMBERS:
		if selected_member_indices[slot_index] < 0 or selected_member_indices[slot_index] >= guild_members.size():
			selected_member_indices[slot_index] = min(slot_index, guild_members.size() - 1)

	var used: Array[int] = []
	for slot_index: int in MAX_ACTIVE_MEMBERS:
		var selected_index: int = selected_member_indices[slot_index]
		if not used.has(selected_index):
			used.append(selected_index)
			continue

		for candidate_index: int in guild_members.size():
			if not used.has(candidate_index):
				selected_member_indices[slot_index] = candidate_index
				used.append(candidate_index)
				break


func get_roster_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for member: Dictionary in guild_members:
		snapshot.append(member.duplicate(true))
	return snapshot


func get_game_snapshot() -> Dictionary:
	return {
		"guild_name": guild_name,
		"current_year": current_year,
		"current_turn": current_turn,
		"fame": fame,
		"gold": gold,
		"completed_years": completed_years,
		"current_year_wins": current_year_wins,
		"current_year_losses": current_year_losses,
		"total_battles": total_battles,
		"tournament_wins": tournament_wins,
		"next_member_id": next_member_id,
		"last_result_summary": last_result_summary,
		"selected_member_indices": selected_member_indices.duplicate(),
		"guild_members": get_roster_snapshot(),
	}


func save_game() -> void:
	var payload: Dictionary = get_game_snapshot()
	payload["version"] = SAVE_VERSION

	var json_text: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % save_path)
		last_result_summary = "保存に失敗しました。"
		_show_prep_screen()
		return

	file.store_string(json_text)
	last_result_summary = "ギルドを保存しました。"
	_show_prep_screen()


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		last_result_summary = "セーブデータがありません。"
		_show_prep_screen()
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Could not read save file: %s" % save_path)
		last_result_summary = "読込に失敗しました。"
		_show_prep_screen()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file did not contain a dictionary.")
		last_result_summary = "読込に失敗しました。"
		_show_prep_screen()
		return

	_apply_save_data(parsed as Dictionary)
	last_result_summary = "ギルドを読み込みました。"
	_show_prep_screen()


func _apply_save_data(data: Dictionary) -> void:
	guild_name = str(data.get("guild_name", guild_name))
	current_year = int(data.get("current_year", 1))
	current_turn = int(data.get("current_turn", 1))
	fame = int(data.get("fame", 0))
	gold = int(data.get("gold", 120))
	completed_years = int(data.get("completed_years", 0))
	current_year_wins = int(data.get("current_year_wins", 0))
	current_year_losses = int(data.get("current_year_losses", 0))
	total_battles = int(data.get("total_battles", 0))
	tournament_wins = int(data.get("tournament_wins", 0))
	next_member_id = int(data.get("next_member_id", 1))
	selected_member_indices.clear()
	for value: Variant in data.get("selected_member_indices", [0, 1, 2]):
		selected_member_indices.append(int(value))

	guild_members.clear()
	for value: Variant in data.get("guild_members", []):
		if typeof(value) == TYPE_DICTIONARY:
			guild_members.append((value as Dictionary).duplicate(true))
	_normalize_selected_members()

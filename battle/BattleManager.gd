extends Node

const UNIT_SCENE := preload("res://units/Unit.tscn")
const GUILD_STATE := preload("res://battle/GuildState.gd")
const GUILD_SAVE_SERVICE := preload("res://battle/GuildSaveService.gd")

const BLUE_TEAM_ID: int = 0
const RED_TEAM_ID: int = 1
const BLUE_COLOR: Color = Color(0.2, 0.45, 1.0)
const RED_COLOR: Color = Color(1.0, 0.2, 0.18)
const MAX_ACTIVE_MEMBERS: int = 3
const TURNS_PER_YEAR: int = 4
const GRADUATION_YEARS: int = 3
const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://guild_save.json"
const CAMPAIGN_YEARS: int = 3

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

const TRAIT_DEFINITIONS: Array[Dictionary] = [
	{"name": "hard_worker", "display_name": "努力家", "xp_multiplier": 1.15},
	{"name": "genius", "display_name": "天才肌", "xp_multiplier": 1.30},
	{"name": "careful", "display_name": "慎重", "hp_bonus": 12, "attack_bonus": -1},
	{"name": "clutch", "display_name": "勝負師", "attack_bonus": 3},
	{"name": "swift", "display_name": "俊足", "speed_bonus": 14.0},
	{"name": "frail", "display_name": "虚弱", "hp_bonus": -18, "xp_multiplier": 1.20},
]

const MISSION_DEFINITIONS: Array[Dictionary] = [
	{"name": "hunt", "display_name": "討伐任務", "xp_multiplier": 1.25, "gold_multiplier": 1.00, "fame_multiplier": 1.00, "enemy_bonus": 0},
	{"name": "escort", "display_name": "護衛任務", "xp_multiplier": 1.00, "gold_multiplier": 1.45, "fame_multiplier": 0.90, "enemy_bonus": 0},
	{"name": "ruins", "display_name": "遺跡探索", "xp_multiplier": 1.10, "gold_multiplier": 1.10, "fame_multiplier": 1.45, "enemy_bonus": 1},
]

const GUILD_RANKS: Array[Dictionary] = [
	{"name": "E", "threshold": 0, "recruit_bonus": 0, "enemy_bonus": 0},
	{"name": "D", "threshold": 40, "recruit_bonus": 1, "enemy_bonus": 0},
	{"name": "C", "threshold": 100, "recruit_bonus": 2, "enemy_bonus": 1},
	{"name": "B", "threshold": 180, "recruit_bonus": 3, "enemy_bonus": 1},
	{"name": "A", "threshold": 300, "recruit_bonus": 4, "enemy_bonus": 2},
]

const VIEW_DEFINITIONS: Array[Dictionary] = [
	{"name": "overview", "display_name": "概要"},
	{"name": "formation", "display_name": "編成"},
	{"name": "roster", "display_name": "所属"},
	{"name": "reports", "display_name": "結果"},
]

const UI_BG: Color = Color(0.06, 0.075, 0.09)
const UI_PANEL: Color = Color(0.095, 0.115, 0.135)
const UI_PANEL_ALT: Color = Color(0.12, 0.145, 0.17)
const UI_BORDER: Color = Color(0.23, 0.29, 0.35)
const UI_ACCENT: Color = Color(0.24, 0.43, 0.62)
const UI_ACCENT_HOVER: Color = Color(0.30, 0.52, 0.73)
const UI_TEXT: Color = Color(0.90, 0.92, 0.94)
const UI_MUTED: Color = Color(0.64, 0.70, 0.76)

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
@onready var prep_background: ColorRect = $"../UI/PrepPanel/Background"
@onready var title_label: Label = $"../UI/PrepPanel/MarginContainer/PrepContent/TitleLabel"
@onready var priority_rows: VBoxContainer = $"../UI/PrepPanel/MarginContainer/PrepContent/PriorityRows"
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
var graduated_count: int = 0
var total_mvp_count: int = 0
var highest_level_ever: int = 1
var highest_level_member_name: String = ""
var next_member_id: int = 1
var current_battle_kind: String = "mission"
var current_mission_index: int = 0
var last_result_summary: String = "ようこそ、ギルドマスター。"
var last_result_details: Array[String] = ["まずは出撃メンバーと任務を確認し、訓練するか任務へ出発します。"]
var last_year_report: String = ""
var final_report: String = ""
var campaign_completed: bool = false
var save_path: String = SAVE_PATH
var guild_members: Array[Dictionary] = []
var selected_member_indices: Array[int] = [0, 1, 2]
var current_view: String = "overview"
var unit_buttons: Array[Button] = []
var target_buttons: Array[Button] = []
var role_buttons: Array[Button] = []
var view_buttons: Array[Button] = []
var primary_action_button: Button = null
var combat_stats: Dictionary = {}
var current_participant_indices: Array[int] = []
var last_mvp_member_id: int = -1


func _ready() -> void:
	start_button.pressed.connect(start_battle)
	return_button.pressed.connect(_show_prep_screen)
	_apply_static_ui_style()
	_create_initial_roster()
	_show_prep_screen()


func _process(_delta: float) -> void:
	if battle_finished or prep_panel.visible:
		return

	_check_battle_result()


func start_battle() -> void:
	if guild_members.is_empty() or campaign_completed:
		return

	current_battle_kind = "tournament" if current_turn == TURNS_PER_YEAR else "mission"
	current_participant_indices.clear()
	combat_stats.clear()
	last_mvp_member_id = -1
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
		current_participant_indices.append(selected_member_indices[index])
		_prepare_combat_stat(member)
		_spawn_member_unit(member, BLUE_TEAM_ID, BLUE_COLOR, blue_positions[index])

	var enemy_level: int = _get_enemy_level()
	for index: int in red_positions.size():
		var enemy: Dictionary = _create_enemy_member(index, enemy_level)
		_prepare_combat_stat(enemy)
		_spawn_member_unit(enemy, RED_TEAM_ID, RED_COLOR, red_positions[index])


func _show_prep_screen() -> void:
	battle_finished = true
	prep_panel.visible = true
	return_button.visible = false
	result_label.text = ""
	_clear_units()
	_clear_effects()
	start_button.text = "大会に出場" if current_turn == TURNS_PER_YEAR else "任務へ出発"
	start_button.visible = false
	_build_prep_rows()


func _create_initial_roster() -> void:
	if not guild_members.is_empty():
		return

	for index: int in 6:
		guild_members.append(_create_guild_member(index % UNIT_DEFINITIONS.size(), index))


func _create_guild_member(class_index: int, seed_index: int) -> Dictionary:
	var class_data: Dictionary = UNIT_DEFINITIONS[class_index]
	var member_name: String = MEMBER_NAMES[(next_member_id - 1) % MEMBER_NAMES.size()]
	var rank_bonus: int = _get_current_rank()["recruit_bonus"]
	var trait_index: int = (next_member_id + seed_index - 1) % TRAIT_DEFINITIONS.size()
	var member := {
		"id": next_member_id,
		"name": member_name,
		"class_index": class_index,
		"trait_index": trait_index,
		"level": 1,
		"xp": 0,
		"years_in_guild": 1,
		"hp": int(class_data["hp"]) + rank_bonus * 4,
		"attack_power": int(class_data["attack_power"]) + rank_bonus,
		"attack_range": class_data["attack_range"],
		"move_speed": float(class_data["move_speed"]) + float(rank_bonus),
		"target_policy": seed_index % TARGET_POLICIES.size(),
		"formation_role": seed_index % FORMATION_ROLES.size(),
		"battles": 0,
		"wins": 0,
		"mvp_count": 0,
		"total_damage_dealt": 0,
		"total_damage_taken": 0,
		"total_kos": 0,
	}
	_apply_trait_base_bonus(member)
	next_member_id += 1
	return member


func _build_prep_rows() -> void:
	for child: Node in priority_rows.get_children():
		child.free()
	for child: Node in config_rows.get_children():
		child.free()

	unit_buttons.clear()
	target_buttons.clear()
	role_buttons.clear()
	view_buttons.clear()
	primary_action_button = null
	_normalize_selected_members()
	_normalize_current_view()

	_add_status_panel()
	_add_next_action_panel()
	_add_action_row()
	_add_view_tabs()
	_add_current_view_content()
	if primary_action_button != null:
		primary_action_button.grab_focus()


func _add_status_panel() -> void:
	var rank_data: Dictionary = _get_current_rank()
	var label := Label.new()
	label.name = "StatusPanel"
	label.text = "%s / ランク%s / %d年目 %dターン / 名声 %d / Gold %d / 今年 %d勝%d敗 / 通算 %d戦 / 優勝 %d / 卒業 %d" % [
		guild_name,
		rank_data["name"],
		current_year,
		current_turn,
		fame,
		gold,
		current_year_wins,
		current_year_losses,
		total_battles,
		tournament_wins,
		graduated_count,
	]
	label.custom_minimum_size = Vector2(0.0, 24.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UI_TEXT)
	label.add_theme_font_size_override("font_size", 15)
	priority_rows.add_child(label)


func _normalize_current_view() -> void:
	for view: Dictionary in VIEW_DEFINITIONS:
		if current_view == str(view["name"]):
			return
	current_view = "overview"


func _add_view_tabs() -> void:
	var row := HBoxContainer.new()
	row.name = "ViewTabs"
	row.custom_minimum_size = Vector2(0.0, 38.0)
	priority_rows.add_child(row)

	for view: Dictionary in VIEW_DEFINITIONS:
		var active: bool = current_view == str(view["name"])
		var button := Button.new()
		button.name = "ViewTab_%s" % view["name"]
		button.custom_minimum_size = Vector2(120.0, 34.0)
		button.focus_mode = Control.FOCUS_ALL
		button.text = "■ %s" % view["display_name"] if active else str(view["display_name"])
		_apply_button_style(button, "tab", active)
		button.pressed.connect(_set_current_view.bind(str(view["name"])))
		row.add_child(button)
		view_buttons.append(button)


func _set_current_view(view_name: String) -> void:
	current_view = view_name
	_build_prep_rows()


func _add_current_view_content() -> void:
	match current_view:
		"formation":
			_add_formation_view()
		"roster":
			_add_roster_view()
		"reports":
			_add_reports_view()
		_:
			_add_overview_view()


func _add_overview_view() -> void:
	_add_overview_summary_panel()
	_add_year_progress_panel()
	if _should_show_first_run_guide():
		_add_first_run_guide_panel()
	else:
		_add_panel("概要", [
			"上部の主行動でゲームを進めます。詳しく調整したい時は、編成・所属・結果タブを切り替えます。",
			"編成: 出撃メンバー、作戦、任務を決めます。所属: メンバー能力を比較します。結果: 直近結果と節目レポートを確認します。",
		], "OverviewPanel")


func _add_overview_summary_panel() -> void:
	var panel := _create_panel("現在の状況", "OverviewSummaryPanel")
	var content := panel.find_child("Content", true, false) as VBoxContainer
	var grid := GridContainer.new()
	grid.name = "OverviewSummaryGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)

	var rank_data: Dictionary = _get_current_rank()
	_add_summary_card(grid, "年度", "%d年目 %d/%dターン" % [current_year, current_turn, TURNS_PER_YEAR])
	_add_summary_card(grid, "ランク", "%s / %s" % [rank_data["name"], _get_rank_progress_text()])
	_add_summary_card(grid, "資金", "Gold %d" % gold)
	_add_summary_card(grid, "今年", "%d勝%d敗" % [current_year_wins, current_year_losses])
	_add_summary_card(grid, "通算", "%d戦 / 優勝 %d" % [total_battles, tournament_wins])
	_add_summary_card(grid, "メンバー", "出撃 %d / 所属 %d" % [selected_member_indices.size(), guild_members.size()])
	_add_summary_card(grid, "次の任務", str(_get_current_mission()["display_name"]) if current_turn != TURNS_PER_YEAR else "年末大会")
	_add_summary_card(grid, "世代/育成", "卒業%d / %s" % [graduated_count, _get_growth_candidate_text()])


func _add_year_progress_panel() -> void:
	var panel := _create_panel("年間進行", "YearProgressPanel")
	var content := panel.find_child("Content", true, false) as VBoxContainer
	var row := HBoxContainer.new()
	row.name = "YearProgressSteps"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)

	for turn_index: int in TURNS_PER_YEAR:
		var turn_number: int = turn_index + 1
		var active: bool = turn_number == current_turn
		var completed: bool = turn_number < current_turn
		var step := PanelContainer.new()
		step.name = "YearProgressStep_%d" % turn_number
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.custom_minimum_size = Vector2(0.0, 42.0)
		step.add_theme_stylebox_override("panel", _make_year_step_style(active, completed))
		row.add_child(step)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 5)
		step.add_child(margin)

		var label := Label.new()
		label.text = "%dT %s" % [turn_number, "大会" if turn_number == TURNS_PER_YEAR else "任務/育成"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", UI_TEXT if active else UI_MUTED)
		margin.add_child(label)


func _add_formation_view() -> void:
	if current_turn != TURNS_PER_YEAR and not campaign_completed:
		_add_mission_selection_panel()
	_add_section_header("出撃メンバー")
	for slot_index: int in MAX_ACTIVE_MEMBERS:
		_add_party_row(slot_index)
	_add_selected_member_preview_panel()


func _add_roster_view() -> void:
	_add_section_header("所属メンバー")
	_add_member_summary_table()


func _add_reports_view() -> void:
	var has_report: bool = false
	if last_year_report != "" or final_report != "":
		_add_milestone_panel()
		has_report = true
	if last_result_summary != "":
		_add_result_panel()
		has_report = true
	if not has_report:
		_add_panel("結果", ["まだ結果はありません。任務、訓練、大会の後にここへ記録されます。"], "EmptyReportPanel")


func _should_show_first_run_guide() -> bool:
	return total_battles == 0 and completed_years == 0 and current_year == 1 and current_turn == 1


func _add_first_run_guide_panel() -> void:
	_add_panel("はじめに", [
		"このゲームは、ギルドメンバーを育成して任務や大会に送り出すオートバトル育成ゲームです。",
		"基本の流れ: 1. 任務を選ぶ  2. 出撃メンバーと作戦を見る  3. 訓練または任務へ出発  4. 結果を見て次のターンへ進む",
		"1年は4ターンです。4ターン目は年末大会になり、訓練ではなく大会へ出場します。",
	], "FirstRunGuidePanel")


func _add_next_action_panel() -> void:
	var label := Label.new()
	label.name = "NextActionPanel"
	if campaign_completed:
		label.text = "次: 3年の活動終了。結果タブで通算成績を確認します。"
	elif current_turn == TURNS_PER_YEAR:
		label.text = "次: 年末大会に出場。このターンは訓練不可 / 保存: 現在状態を保存"
	else:
		var mission: Dictionary = _get_current_mission()
		label.text = "次: %sへ出発、または訓練(Gold -10 / 全員EXP +8)。任務選択は編成タブ。" % mission["display_name"]
	label.custom_minimum_size = Vector2(0.0, 24.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", UI_TEXT)
	label.add_theme_font_size_override("font_size", 15)
	priority_rows.add_child(label)


func _add_milestone_panel() -> void:
	var lines: Array[String] = []
	if last_year_report != "":
		lines.append(last_year_report)
	if final_report != "":
		lines.append(final_report)
	_add_panel("節目レポート", lines, "MilestonePanel")


func _add_result_panel() -> void:
	_add_result_digest_panel()
	var lines: Array[String] = [last_result_summary]
	lines.append_array(last_result_details)
	_add_panel("直近の結果", lines, "ResultPanel")


func _add_result_digest_panel() -> void:
	var panel := _create_panel("結果サマリー", "ResultDigestPanel")
	var content := panel.find_child("Content", true, false) as VBoxContainer
	var grid := GridContainer.new()
	grid.name = "ResultDigestGrid"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)

	for card_data: Dictionary in _build_result_digest_cards():
		_add_summary_card(grid, str(card_data["title"]), str(card_data["value"]))


func _build_result_digest_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	cards.append({"title": "結果", "value": _get_result_outcome_text()})
	cards.append({"title": "報酬/コスト", "value": _get_result_reward_text()})
	cards.append({"title": "成長", "value": _get_result_growth_text()})
	cards.append({"title": "次", "value": _get_result_next_text()})
	return cards


func _get_result_outcome_text() -> String:
	if last_result_summary.contains("MVP"):
		return _shorten_result_segment(last_result_summary, 2)
	return last_result_summary


func _get_result_reward_text() -> String:
	for detail: String in last_result_details:
		if detail.contains("Gold"):
			return detail.split("/")[0].strip_edges()
	if last_result_summary.contains("名声") or last_result_summary.contains("Gold"):
		var segments := last_result_summary.split("/")
		var reward_segments: Array[String] = []
		for segment: String in segments:
			var trimmed: String = segment.strip_edges()
			if trimmed.contains("名声") or trimmed.contains("Gold") or trimmed.contains("ランク"):
				reward_segments.append(trimmed)
		if not reward_segments.is_empty():
			return " / ".join(reward_segments)
	return "変化なし"


func _get_result_growth_text() -> String:
	for detail: String in last_result_details:
		if detail.contains("全員") and detail.contains("経験"):
			return detail.split("/")[1].strip_edges() if detail.contains("/") else detail

	var member_count: int = 0
	var level_up_count: int = 0
	for detail: String in last_result_details:
		if detail.contains("経験+"):
			member_count += 1
			if _detail_has_level_up(detail):
				level_up_count += 1
	if member_count > 0:
		return "出撃%d人 / LvUP %d人" % [member_count, level_up_count]
	return "記録なし"


func _get_result_next_text() -> String:
	for detail: String in last_result_details:
		if detail.contains("次"):
			return detail
	if campaign_completed:
		return "3年終了。節目レポートを確認。"
	if current_turn == TURNS_PER_YEAR:
		return "年末大会に出場。"
	return "編成を確認して次の行動へ。"


func _shorten_result_segment(text: String, segment_count: int) -> String:
	var segments := text.split("/")
	var kept: Array[String] = []
	for index: int in min(segment_count, segments.size()):
		kept.append(str(segments[index]).strip_edges())
	return " / ".join(kept)


func _detail_has_level_up(detail: String) -> bool:
	var marker: int = detail.find("Lv")
	if marker == -1:
		return false
	var arrow: int = detail.find("→", marker)
	if arrow == -1:
		return false
	var before_text: String = detail.substr(marker + 2, arrow - marker - 2).strip_edges()
	var after_text := ""
	var cursor: int = arrow + 1
	while cursor < detail.length():
		var character: String = detail.substr(cursor, 1)
		if not character.is_valid_int():
			break
		after_text += character
		cursor += 1
	if before_text.is_valid_int() and after_text.is_valid_int():
		return int(after_text) > int(before_text)
	return false


func _add_mission_selection_panel() -> void:
	var panel := _create_panel("任務選択", "MissionSelectionPanel")
	var content := panel.find_child("Content", true, false) as VBoxContainer
	var hint := Label.new()
	hint.text = "伸ばしたい報酬を選んでから「任務へ出発」を押します。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", UI_MUTED)
	content.add_child(hint)

	var row := HBoxContainer.new()
	row.name = "MissionButtons"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	for index: int in MISSION_DEFINITIONS.size():
		var mission: Dictionary = MISSION_DEFINITIONS[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 72.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.text = _get_mission_button_text(index, mission)
		_apply_button_style(button, "secondary", index == current_mission_index)
		button.pressed.connect(_select_mission.bind(index))
		row.add_child(button)


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
	label.add_theme_color_override("font_color", UI_ACCENT_HOVER)
	config_rows.add_child(label)


func _create_panel(title: String, panel_name: String, parent: VBoxContainer = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(panel)
	var target_parent: VBoxContainer = config_rows if parent == null else parent
	target_parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", UI_ACCENT_HOVER)
	content.add_child(heading)
	return panel


func _add_panel(title: String, lines: Array[String], panel_name: String, parent: VBoxContainer = null) -> void:
	var panel := _create_panel(title, panel_name, parent)
	var content := panel.find_child("Content", true, false) as VBoxContainer
	for line: String in lines:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", UI_TEXT)
		label.add_theme_constant_override("line_spacing", 2)
		content.add_child(label)


func _add_summary_card(parent: GridContainer, title: String, value: String) -> void:
	var card := PanelContainer.new()
	card.name = "SummaryCard_%s" % title
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 54.0)
	card.add_theme_stylebox_override("panel", _make_style(UI_PANEL_ALT, UI_BORDER, 1, 3))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", UI_MUTED)
	column.add_child(title_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", UI_TEXT)
	column.add_child(value_label)


func _add_selected_member_preview_panel() -> void:
	var panel := _create_panel("出撃プレビュー", "SelectedMemberPreviewPanel")
	var content := panel.find_child("Content", true, false) as VBoxContainer
	var grid := GridContainer.new()
	grid.name = "SelectedMemberPreviewGrid"
	grid.columns = MAX_ACTIVE_MEMBERS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)

	for slot_index: int in MAX_ACTIVE_MEMBERS:
		if slot_index >= selected_member_indices.size():
			continue
		_add_selected_member_preview_card(grid, slot_index, selected_member_indices[slot_index])


func _add_selected_member_preview_card(parent: GridContainer, slot_index: int, member_index: int) -> void:
	var member: Dictionary = guild_members[member_index]
	_ensure_member_defaults(member)
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var trait_data: Dictionary = _get_member_trait(member)

	var card := PanelContainer.new()
	card.name = "SelectedMemberPreview_%d" % slot_index
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 58.0)
	card.add_theme_stylebox_override("panel", _make_style(UI_PANEL_ALT, UI_BORDER, 1, 3))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	var name_label := Label.new()
	name_label.text = "%d. %s Lv%d  %s/%s" % [
		slot_index + 1,
		member["name"],
		member["level"],
		class_data["display_name"],
		trait_data["display_name"],
	]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", UI_TEXT)
	column.add_child(name_label)

	var stat_label := Label.new()
	stat_label.text = "%s / HP %d 攻 %d 射 %d 速 %d / EXP %d/%d" % [
		_get_member_role_hint(member).replace("役割目安: ", ""),
		member["hp"],
		member["attack_power"],
		int(member["attack_range"]),
		int(member["move_speed"]),
		member["xp"],
		_get_xp_to_next(member),
	]
	stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat_label.add_theme_font_size_override("font_size", 13)
	stat_label.add_theme_color_override("font_color", UI_MUTED)
	column.add_child(stat_label)


func _apply_static_ui_style() -> void:
	prep_background.color = UI_BG
	title_label.add_theme_color_override("font_color", UI_TEXT)
	result_label.add_theme_color_override("font_color", UI_TEXT)


func _apply_panel_style(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _make_style(UI_PANEL, UI_BORDER, 1, 3))


func _apply_button_style(button: Button, kind: String, active: bool = false) -> void:
	var normal_color: Color = UI_PANEL_ALT
	var hover_color: Color = Color(0.17, 0.20, 0.24)
	var pressed_color: Color = Color(0.20, 0.25, 0.30)
	var border_color: Color = UI_BORDER

	match kind:
		"primary":
			normal_color = UI_ACCENT
			hover_color = UI_ACCENT_HOVER
			pressed_color = Color(0.20, 0.36, 0.52)
			border_color = Color(0.58, 0.74, 0.88)
		"tab":
			if active:
				normal_color = Color(0.18, 0.28, 0.38)
				hover_color = Color(0.21, 0.33, 0.45)
				pressed_color = Color(0.16, 0.25, 0.35)
				border_color = UI_ACCENT_HOVER
		"secondary":
			if active:
				normal_color = Color(0.18, 0.26, 0.32)
				hover_color = Color(0.22, 0.31, 0.38)
				pressed_color = Color(0.15, 0.22, 0.28)
				border_color = UI_ACCENT
		"system":
			normal_color = Color(0.13, 0.14, 0.16)
			hover_color = Color(0.18, 0.19, 0.21)
			pressed_color = Color(0.10, 0.12, 0.14)

	button.add_theme_stylebox_override("normal", _make_style(normal_color, border_color, 1, 3))
	button.add_theme_stylebox_override("hover", _make_style(hover_color, border_color, 1, 3))
	button.add_theme_stylebox_override("pressed", _make_style(pressed_color, border_color, 1, 3))
	button.add_theme_stylebox_override("focus", _make_style(Color(0, 0, 0, 0), UI_ACCENT_HOVER, 2, 3))
	button.add_theme_stylebox_override("disabled", _make_style(Color(0.09, 0.10, 0.11), Color(0.16, 0.17, 0.18), 1, 3))
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", UI_TEXT)
	button.add_theme_color_override("font_pressed_color", UI_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_MUTED)


func _make_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style


func _make_year_step_style(active: bool, completed: bool) -> StyleBoxFlat:
	if active:
		return _make_style(Color(0.18, 0.28, 0.38), UI_ACCENT_HOVER, 1, 3)
	if completed:
		return _make_style(Color(0.12, 0.18, 0.16), Color(0.28, 0.45, 0.36), 1, 3)
	return _make_style(UI_PANEL_ALT, UI_BORDER, 1, 3)


func _add_party_row(slot_index: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 36.0)
	config_rows.add_child(row)

	var slot_label := Label.new()
	slot_label.custom_minimum_size = Vector2(72.0, 0.0)
	slot_label.text = "枠 %d" % (slot_index + 1)
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_label.add_theme_color_override("font_color", UI_MUTED)
	row.add_child(slot_label)

	var member_button := Button.new()
	member_button.custom_minimum_size = Vector2(250.0, 0.0)
	member_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(member_button, "secondary")
	member_button.pressed.connect(_cycle_selected_member.bind(slot_index))
	row.add_child(member_button)
	unit_buttons.append(member_button)

	var target_button := Button.new()
	target_button.custom_minimum_size = Vector2(150.0, 0.0)
	target_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(target_button, "secondary")
	target_button.pressed.connect(_cycle_target_choice.bind(slot_index))
	row.add_child(target_button)
	target_buttons.append(target_button)

	var role_button := Button.new()
	role_button.custom_minimum_size = Vector2(132.0, 0.0)
	role_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(role_button, "secondary")
	role_button.pressed.connect(_cycle_role_choice.bind(slot_index))
	row.add_child(role_button)
	role_buttons.append(role_button)

	_refresh_party_row(slot_index)


func _add_member_summary(member_index: int) -> void:
	var member: Dictionary = guild_members[member_index]
	_ensure_member_defaults(member)
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var trait_data: Dictionary = _get_member_trait(member)
	var row := VBoxContainer.new()
	row.name = "MemberSummary_%d" % member_index
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	config_rows.add_child(row)

	var main_label := Label.new()
	main_label.text = "%s%s  Lv%d %s / %s  %s" % [
		"出撃中: " if selected_member_indices.has(member_index) else "控え: ",
		member["name"],
		member["level"],
		class_data["display_name"],
		trait_data["display_name"],
		_get_member_role_hint(member),
	]
	main_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(main_label)

	var stat_label := Label.new()
	stat_label.text = "   HP %d / 攻撃 %d / 射程 %d / 速度 %d / 経験 %d/%d / 在籍 %d年 / MVP %d" % [
		member["hp"],
		member["attack_power"],
		int(member["attack_range"]),
		int(member["move_speed"]),
		member["xp"],
		_get_xp_to_next(member),
		member["years_in_guild"],
		member.get("mvp_count", 0),
	]
	stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(stat_label)


func _add_member_summary_table() -> void:
	var table := GridContainer.new()
	table.name = "MemberSummaryTable"
	table.columns = 9
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("h_separation", 10)
	table.add_theme_constant_override("v_separation", 4)
	config_rows.add_child(table)

	for header: String in ["状態", "名前", "職/才能", "役割目安", "HP", "攻撃", "射程", "速度", "経験/実績"]:
		_add_table_cell(table, header, 15, 86.0)

	for member_index: int in guild_members.size():
		_add_member_summary_row(table, member_index)


func _add_member_summary_row(table: GridContainer, member_index: int) -> void:
	var member: Dictionary = guild_members[member_index]
	_ensure_member_defaults(member)
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var trait_data: Dictionary = _get_member_trait(member)

	_add_table_cell(table, "出撃中" if selected_member_indices.has(member_index) else "控え", 14, 72.0)
	_add_table_cell(table, "%s Lv%d" % [member["name"], member["level"]], 14, 110.0)
	_add_table_cell(table, "%s/%s" % [class_data["display_name"], trait_data["display_name"]], 14, 126.0)
	_add_table_cell(table, _get_member_role_hint(member).replace("役割目安: ", ""), 14, 120.0)
	_add_table_cell(table, str(member["hp"]), 14, 54.0)
	_add_table_cell(table, str(member["attack_power"]), 14, 54.0)
	_add_table_cell(table, str(int(member["attack_range"])), 14, 54.0)
	_add_table_cell(table, str(int(member["move_speed"])), 14, 54.0)
	_add_table_cell(table, "EXP %d/%d / MVP %d" % [
		member["xp"],
		_get_xp_to_next(member),
		member.get("mvp_count", 0),
	], 14, 140.0)


func _add_table_cell(table: GridContainer, text: String, font_size: int, min_width: float) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UI_MUTED if font_size >= 15 else UI_TEXT)
	table.add_child(label)


func _add_action_row() -> void:
	var row := HBoxContainer.new()
	row.name = "ActionPanel"
	row.custom_minimum_size = Vector2(0.0, 42.0)
	priority_rows.add_child(row)
	var tournament_turn: bool = current_turn == TURNS_PER_YEAR

	primary_action_button = Button.new()
	primary_action_button.name = "PrimaryActionButton"
	primary_action_button.text = _get_primary_action_text()
	primary_action_button.custom_minimum_size = Vector2(180.0, 40.0)
	primary_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_action_button.focus_mode = Control.FOCUS_ALL
	primary_action_button.disabled = campaign_completed
	_apply_button_style(primary_action_button, "primary")
	primary_action_button.pressed.connect(start_battle)
	row.add_child(primary_action_button)

	var training_label := Label.new()
	training_label.text = "育成:"
	training_label.custom_minimum_size = Vector2(48.0, 0.0)
	training_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	training_label.add_theme_color_override("font_color", UI_MUTED)
	row.add_child(training_label)

	var drill_button := Button.new()
	drill_button.text = "攻撃訓練"
	drill_button.custom_minimum_size = Vector2(120.0, 40.0)
	drill_button.focus_mode = Control.FOCUS_ALL
	drill_button.disabled = tournament_turn
	_apply_button_style(drill_button, "secondary")
	drill_button.pressed.connect(_train_guild.bind("drill"))
	row.add_child(drill_button)

	var endurance_button := Button.new()
	endurance_button.text = "耐久訓練"
	endurance_button.custom_minimum_size = Vector2(120.0, 40.0)
	endurance_button.focus_mode = Control.FOCUS_ALL
	endurance_button.disabled = tournament_turn
	_apply_button_style(endurance_button, "secondary")
	endurance_button.pressed.connect(_train_guild.bind("endurance"))
	row.add_child(endurance_button)

	var tactics_button := Button.new()
	tactics_button.text = "戦術訓練"
	tactics_button.custom_minimum_size = Vector2(120.0, 40.0)
	tactics_button.focus_mode = Control.FOCUS_ALL
	tactics_button.disabled = tournament_turn
	_apply_button_style(tactics_button, "secondary")
	tactics_button.pressed.connect(_train_guild.bind("tactics"))
	row.add_child(tactics_button)

	var system_label := Label.new()
	system_label.text = "保存:"
	system_label.custom_minimum_size = Vector2(48.0, 0.0)
	system_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	system_label.add_theme_color_override("font_color", UI_MUTED)
	row.add_child(system_label)

	var save_button := Button.new()
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(88.0, 40.0)
	save_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(save_button, "system")
	save_button.pressed.connect(save_game)
	row.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "読込"
	load_button.custom_minimum_size = Vector2(88.0, 40.0)
	load_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(load_button, "system")
	load_button.pressed.connect(load_game)
	row.add_child(load_button)


func _get_primary_action_text() -> String:
	if campaign_completed:
		return "3年終了"
	return "大会に出場" if current_turn == TURNS_PER_YEAR else "任務へ出発"


func _get_primary_action_hint(tournament_turn: bool) -> String:
	if campaign_completed:
		return "β版の3年サイクルは完了です。節目レポートでギルドの成果を確認できます。"
	if tournament_turn:
		return "編成と作戦を確認して年末大会へ進みます。"
	return "%sへ出発します。迷ったらまずここを押せばゲームが進みます。" % _get_current_mission()["display_name"]


func _refresh_party_row(slot_index: int) -> void:
	if slot_index >= unit_buttons.size():
		return

	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	_ensure_member_defaults(member)
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var trait_data: Dictionary = _get_member_trait(member)
	var target_data: Dictionary = TARGET_POLICIES[member["target_policy"]]
	var role_data: Dictionary = FORMATION_ROLES[member["formation_role"]]
	unit_buttons[slot_index].text = "変更: %s  Lv%d %s/%s" % [member["name"], member["level"], class_data["display_name"], trait_data["display_name"]]
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

	current_view = "formation"
	_build_prep_rows()


func _cycle_target_choice(slot_index: int) -> void:
	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	member["target_policy"] = (int(member["target_policy"]) + 1) % TARGET_POLICIES.size()
	current_view = "formation"
	_build_prep_rows()


func _cycle_role_choice(slot_index: int) -> void:
	var member: Dictionary = guild_members[selected_member_indices[slot_index]]
	member["formation_role"] = (int(member["formation_role"]) + 1) % FORMATION_ROLES.size()
	current_view = "formation"
	_build_prep_rows()


func _cycle_mission() -> void:
	current_mission_index = (current_mission_index + 1) % MISSION_DEFINITIONS.size()
	current_view = "formation"
	_build_prep_rows()


func _select_mission(mission_index: int) -> void:
	current_mission_index = clampi(mission_index, 0, MISSION_DEFINITIONS.size() - 1)
	current_view = "formation"
	_build_prep_rows()


func _get_mission_button_text(mission_index: int, mission: Dictionary) -> String:
	var marker: String = "選択中" if mission_index == current_mission_index else "選択"
	var danger: String = "標準" if int(mission["enemy_bonus"]) <= 0 else "高め"
	return "%s: %s\n経験 x%.2f / Gold x%.2f / 名声 x%.2f\n難度: %s" % [
		marker,
		mission["display_name"],
		mission["xp_multiplier"],
		mission["gold_multiplier"],
		mission["fame_multiplier"],
		danger,
	]


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
	last_result_summary = "%s完了: 全員が経験値を獲得" % _get_training_display_name(training_type)
	last_result_details = [
		"Gold -10 / 全員 経験 +8",
		"次のターンへ進みました。大会ターンでは訓練できません。",
	]
	current_view = "reports"
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


func _get_current_mission() -> Dictionary:
	if current_mission_index < 0 or current_mission_index >= MISSION_DEFINITIONS.size():
		current_mission_index = 0
	return MISSION_DEFINITIONS[current_mission_index]


func _get_current_rank() -> Dictionary:
	var current_rank: Dictionary = GUILD_RANKS[0]
	for rank: Dictionary in GUILD_RANKS:
		if fame >= int(rank["threshold"]):
			current_rank = rank
	return current_rank


func _get_rank_progress_text() -> String:
	for rank: Dictionary in GUILD_RANKS:
		var threshold: int = int(rank["threshold"])
		if fame < threshold:
			return "名声 %d / 次%sまで%d" % [fame, rank["name"], threshold - fame]
	return "名声 %d / 最高ランク" % fame


func _get_growth_candidate_text() -> String:
	if guild_members.is_empty():
		return "候補なし"

	var best_member: Dictionary = guild_members[0]
	var best_remaining: int = _get_xp_to_next(best_member) - int(best_member["xp"])
	for member: Dictionary in guild_members:
		var remaining: int = _get_xp_to_next(member) - int(member["xp"])
		if remaining < best_remaining:
			best_member = member
			best_remaining = remaining
	return "%s 次Lv%d" % [best_member["name"], max(0, best_remaining)]


func _get_member_trait(member: Dictionary) -> Dictionary:
	var trait_index: int = int(member.get("trait_index", 0))
	if trait_index < 0 or trait_index >= TRAIT_DEFINITIONS.size():
		trait_index = 0
	return TRAIT_DEFINITIONS[trait_index]


func _get_member_role_hint(member: Dictionary) -> String:
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	match str(class_data["name"]):
		"Warrior":
			return "役割目安: 前線で耐える"
		"Rogue":
			return "役割目安: 素早く削る"
		"Mage":
			return "役割目安: 後方火力"
		"Archer":
			return "役割目安: 遠距離支援"
		"Cleric":
			return "役割目安: 安定支援"
		_:
			return "役割目安: 汎用"


func _apply_trait_base_bonus(member: Dictionary) -> void:
	var trait_data: Dictionary = _get_member_trait(member)
	member["hp"] = max(1, int(member["hp"]) + int(trait_data.get("hp_bonus", 0)))
	member["attack_power"] = max(1, int(member["attack_power"]) + int(trait_data.get("attack_bonus", 0)))
	member["move_speed"] = max(20.0, float(member["move_speed"]) + float(trait_data.get("speed_bonus", 0.0)))


func _apply_trait_xp(member: Dictionary, base_amount: int) -> int:
	var trait_data: Dictionary = _get_member_trait(member)
	return max(1, int(round(float(base_amount) * float(trait_data.get("xp_multiplier", 1.0)))))


func _prepare_combat_stat(member: Dictionary) -> void:
	var member_id: int = int(member.get("id", -1))
	if member_id == -1:
		return

	combat_stats[member_id] = {
		"damage_dealt": 0,
		"damage_taken": 0,
		"kos": 0,
		"survived": false,
	}


func _mark_survivors() -> void:
	for node: Node in get_tree().get_nodes_in_group("units"):
		var member_id: int = int(node.get("member_id"))
		if combat_stats.has(member_id) and not bool(node.get("is_dead")):
			var stats: Dictionary = combat_stats[member_id]
			stats["survived"] = true


func _select_mvp_member_index() -> int:
	var selected_index: int = -1
	var best_score: int = -1

	for member_index: int in current_participant_indices:
		if member_index < 0 or member_index >= guild_members.size():
			continue

		var member: Dictionary = guild_members[member_index]
		var stats: Dictionary = combat_stats.get(member["id"], {})
		var score: int = int(stats.get("damage_dealt", 0)) + int(stats.get("kos", 0)) * 40
		if bool(stats.get("survived", false)):
			score += 20
		if selected_index == -1 or score > best_score:
			selected_index = member_index
			best_score = score

	return selected_index


func _apply_member_battle_stats(member: Dictionary) -> void:
	_ensure_member_defaults(member)
	var stats: Dictionary = combat_stats.get(member["id"], {})
	member["total_damage_dealt"] = int(member.get("total_damage_dealt", 0)) + int(stats.get("damage_dealt", 0))
	member["total_damage_taken"] = int(member.get("total_damage_taken", 0)) + int(stats.get("damage_taken", 0))
	member["total_kos"] = int(member.get("total_kos", 0)) + int(stats.get("kos", 0))


func _ensure_member_defaults(member: Dictionary) -> void:
	member["trait_index"] = int(member.get("trait_index", 0))
	member["mvp_count"] = int(member.get("mvp_count", 0))
	member["total_damage_dealt"] = int(member.get("total_damage_dealt", 0))
	member["total_damage_taken"] = int(member.get("total_damage_taken", 0))
	member["total_kos"] = int(member.get("total_kos", 0))
	member["battles"] = int(member.get("battles", 0))
	member["wins"] = int(member.get("wins", 0))


func _spawn_member_unit(member: Dictionary, team_id: int, color: Color, spawn_position: Vector2) -> void:
	_ensure_member_defaults(member)
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
		member.get("id", -1),
		self
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
	else:
		level += int(_get_current_mission()["enemy_bonus"])
	level += int(_get_current_rank()["enemy_bonus"])
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


func record_combat_hit(attacker_member_id: int, defender_member_id: int, damage: int, killed: bool) -> void:
	if combat_stats.has(attacker_member_id):
		var attacker_stats: Dictionary = combat_stats[attacker_member_id]
		attacker_stats["damage_dealt"] = int(attacker_stats["damage_dealt"]) + damage
		if killed:
			attacker_stats["kos"] = int(attacker_stats["kos"]) + 1

	if combat_stats.has(defender_member_id):
		var defender_stats: Dictionary = combat_stats[defender_member_id]
		defender_stats["damage_taken"] = int(defender_stats["damage_taken"]) + damage


func _apply_battle_rewards(blue_won: bool) -> void:
	_mark_survivors()
	var battle_report_lines: Array[String] = []
	var base_xp: int = 36 if current_battle_kind == "tournament" else 24
	var win_xp: int = 18 if blue_won else 6
	var fame_gain: int = 12 if blue_won else 3
	var gold_gain: int = 35 if blue_won else 12
	if current_battle_kind == "tournament":
		fame_gain *= 2
		gold_gain *= 2
		if blue_won:
			tournament_wins += 1
	else:
		var mission: Dictionary = _get_current_mission()
		base_xp = int(round(float(base_xp) * float(mission["xp_multiplier"])))
		fame_gain = int(round(float(fame_gain) * float(mission["fame_multiplier"])))
		gold_gain = int(round(float(gold_gain) * float(mission["gold_multiplier"])))

	var mvp_index: int = _select_mvp_member_index()
	var mvp_name: String = "なし"

	for member_index: int in current_participant_indices:
		if member_index < 0 or member_index >= guild_members.size():
			continue
		var member: Dictionary = guild_members[member_index]
		var before_level: int = int(member["level"])
		var earned_xp: int = _apply_trait_xp(member, base_xp + win_xp)
		member["battles"] = int(member["battles"]) + 1
		if blue_won:
			member["wins"] = int(member["wins"]) + 1
		_award_member_xp(member_index, earned_xp)
		_apply_member_battle_stats(member)
		var stats: Dictionary = combat_stats.get(member["id"], {})
		battle_report_lines.append("%s 経験+%d Lv%d→%d 与%d 被%d 撃破%d" % [
			member["name"],
			earned_xp,
			before_level,
			member["level"],
			stats.get("damage_dealt", 0),
			stats.get("damage_taken", 0),
			stats.get("kos", 0),
		])
		if member_index == mvp_index:
			member["mvp_count"] = int(member.get("mvp_count", 0)) + 1
			total_mvp_count += 1
			mvp_name = member["name"]
			last_mvp_member_id = int(member["id"])

	fame += fame_gain
	gold += gold_gain
	total_battles += 1
	if blue_won:
		current_year_wins += 1
	else:
		current_year_losses += 1
	var rank_text: String = _get_current_rank()["name"]
	last_result_summary = "%s完了: %s / MVP: %s / 名声 +%d / Gold +%d / ランク%s" % [
		"大会" if current_battle_kind == "tournament" else "任務",
		"勝利！" if blue_won else "敗北。",
		mvp_name,
		fame_gain,
		gold_gain,
		rank_text,
	]
	last_result_details = battle_report_lines.duplicate()
	current_view = "reports"
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
	if int(member["level"]) > highest_level_ever:
		highest_level_ever = int(member["level"])
		highest_level_member_name = str(member["name"])
	var class_data: Dictionary = UNIT_DEFINITIONS[member["class_index"]]
	var growth: Dictionary = class_data["growth"]
	var trait_data: Dictionary = _get_member_trait(member)
	member["hp"] = int(member["hp"]) + int(growth["hp"]) + int(trait_data.get("level_hp_bonus", 0))
	member["attack_power"] = int(member["attack_power"]) + int(growth["attack_power"]) + int(trait_data.get("level_attack_bonus", 0))
	member["attack_range"] = float(member["attack_range"]) + float(growth["attack_range"])
	member["move_speed"] = float(member["move_speed"]) + float(growth["move_speed"]) + float(trait_data.get("level_speed_bonus", 0.0))


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

	graduated_count += graduates.size()
	var recruited_names: Array[String] = []
	while guild_members.size() < 6:
		var recruit: Dictionary = _create_guild_member((next_member_id - 1) % UNIT_DEFINITIONS.size(), next_member_id)
		recruited_names.append(recruit["name"])
		guild_members.append(recruit)

	_normalize_selected_members()
	last_result_details.append("%d年目終了: %d勝%d敗" % [finished_year, wins, losses])
	if not graduates.is_empty():
		last_result_details.append("卒業: %s / 新人が加入しました。" % "、".join(graduates))
	else:
		last_result_details.append("新しい一年が始まります。")
	last_year_report = _build_year_report(finished_year, wins, losses, graduates, recruited_names)
	if completed_years >= CAMPAIGN_YEARS:
		campaign_completed = true
		final_report = _build_final_report()
	current_year_wins = 0
	current_year_losses = 0


func _build_year_report(finished_year: int, wins: int, losses: int, graduates: Array[String], recruited_names: Array[String]) -> String:
	var graduate_text: String = "なし" if graduates.is_empty() else "、".join(graduates)
	var recruit_text: String = "なし" if recruited_names.is_empty() else "、".join(recruited_names)
	return "年度末レポート: %d年目 %d勝%d敗 / ギルドランク%s / 卒業 %s / 新人 %s" % [
		finished_year,
		wins,
		losses,
		_get_current_rank()["name"],
		graduate_text,
		recruit_text,
	]


func _build_final_report() -> String:
	for member: Dictionary in guild_members:
		_ensure_member_defaults(member)
		if int(member["level"]) > highest_level_ever:
			highest_level_ever = int(member["level"])
			highest_level_member_name = str(member["name"])

	var top_member: String = "なし" if highest_level_member_name == "" else highest_level_member_name

	return "3年終了レポート: 通算戦闘 %d / 大会優勝 %d / 最高Lv %d(%s) / MVP回数 %d / 卒業生 %d / 最終ランク%s" % [
		total_battles,
		tournament_wins,
		highest_level_ever,
		top_member,
		total_mvp_count,
		graduated_count,
		_get_current_rank()["name"],
	]


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
		_ensure_member_defaults(member)
		snapshot.append(member.duplicate(true))
	return snapshot


func get_game_snapshot() -> Dictionary:
	return GUILD_STATE.build_snapshot(self, selected_member_indices, get_roster_snapshot())


func get_beta_status() -> Dictionary:
	return {
		"trait_count": TRAIT_DEFINITIONS.size(),
		"mission_count": MISSION_DEFINITIONS.size(),
		"guild_rank": _get_current_rank()["name"],
		"campaign_completed": campaign_completed,
		"final_report": final_report,
		"last_result_summary": last_result_summary,
		"last_year_report": last_year_report,
		"last_mvp_member_id": last_mvp_member_id,
		"completed_years": completed_years,
		"total_battles": total_battles,
		"tournament_wins": tournament_wins,
		"graduated_count": graduated_count,
		"total_mvp_count": total_mvp_count,
		"highest_level_ever": highest_level_ever,
		"highest_level_member_name": highest_level_member_name,
	}


func save_game() -> void:
	var payload: Dictionary = get_game_snapshot()
	payload["version"] = SAVE_VERSION

	var result: Dictionary = GUILD_SAVE_SERVICE.save_json(save_path, payload)
	if not bool(result["ok"]):
		push_error(result["error"])
		last_result_summary = "保存に失敗しました。"
		last_result_details = [str(result["error"])]
		current_view = "reports"
		_show_prep_screen()
		return

	last_result_summary = "ギルドを保存しました。"
	last_result_details = ["保存先: %s" % save_path]
	current_view = "reports"
	_show_prep_screen()


func load_game() -> void:
	var result: Dictionary = GUILD_SAVE_SERVICE.load_json(save_path)
	if not bool(result["ok"]):
		if str(result["error"]) != "No save file found.":
			push_error(result["error"])
		last_result_summary = "セーブデータがありません。" if str(result["error"]) == "No save file found." else "読込に失敗しました。"
		last_result_details = [str(result["error"])]
		current_view = "reports"
		_show_prep_screen()
		return

	_apply_save_data(result["data"])
	last_result_summary = "ギルドを読み込みました。"
	last_result_details = ["保存時点のギルド状況を復元しました。"]
	current_view = "reports"
	_show_prep_screen()


func _apply_save_data(data: Dictionary) -> void:
	GUILD_STATE.apply_scalar_data(self, data)
	selected_member_indices.clear()
	for value: Variant in data.get("selected_member_indices", [0, 1, 2]):
		selected_member_indices.append(int(value))

	guild_members.clear()
	for value: Variant in data.get("guild_members", []):
		if typeof(value) == TYPE_DICTIONARY:
			var member: Dictionary = (value as Dictionary).duplicate(true)
			_ensure_member_defaults(member)
			guild_members.append(member)
	_normalize_selected_members()

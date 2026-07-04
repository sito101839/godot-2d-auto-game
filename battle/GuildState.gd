class_name GuildState
extends RefCounted

const SCALAR_KEYS: Array[String] = [
	"guild_name",
	"current_year",
	"current_turn",
	"fame",
	"gold",
	"completed_years",
	"current_year_wins",
	"current_year_losses",
	"total_battles",
	"tournament_wins",
	"graduated_count",
	"total_mvp_count",
	"highest_level_ever",
	"highest_level_member_name",
	"next_member_id",
	"current_mission_index",
	"last_result_summary",
	"last_year_report",
	"final_report",
	"campaign_completed",
]


static func build_snapshot(owner: Node, selected_member_indices: Array[int], guild_members: Array[Dictionary]) -> Dictionary:
	var snapshot: Dictionary = {}
	for key: String in SCALAR_KEYS:
		snapshot[key] = owner.get(key)

	snapshot["selected_member_indices"] = selected_member_indices.duplicate()
	snapshot["guild_members"] = []
	for member: Dictionary in guild_members:
		snapshot["guild_members"].append(member.duplicate(true))

	return snapshot


static func apply_scalar_data(owner: Node, data: Dictionary) -> void:
	for key: String in SCALAR_KEYS:
		if data.has(key):
			owner.set(key, data[key])

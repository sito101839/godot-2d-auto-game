extends SceneTree

const BATTLE_SCENE := preload("res://battle/BattleScene.tscn")

const OUTPUT_DIR := "res://.godot/screenshots"
const VIEW_NAMES: Array[String] = ["overview", "formation", "roster", "reports"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var output_dir_abs := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir_abs)

	var battle := BATTLE_SCENE.instantiate()
	root.add_child(battle)
	await _wait_for_draw()

	var manager := battle.get_node_or_null("BattleManager")
	if manager == null:
		push_error("BattleManager was not found.")
		_fail(battle)
		return

	for view_name: String in VIEW_NAMES:
		manager.call("_set_current_view", view_name)
		await _wait_for_draw()
		var output_path := "%s/guild_hall_%s.png" % [OUTPUT_DIR, view_name]
		var result := _capture_viewport(output_path)
		if result != OK:
			push_error("Failed to save screenshot %s: %s" % [output_path, error_string(result)])
			_fail(battle)
			return
		print("SCREENSHOT_SAVED %s" % ProjectSettings.globalize_path(output_path))

	print("SMOKE_TEST_PASS capture_guild_hall_screenshot")
	battle.queue_free()
	await process_frame
	quit(0)


func _wait_for_draw() -> void:
	for _index: int in 8:
		await process_frame


func _capture_viewport(output_path: String) -> Error:
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return ERR_UNAVAILABLE
	return image.save_png(output_path)


func _fail(battle: Node) -> void:
	if is_instance_valid(battle):
		battle.queue_free()
	await process_frame
	quit(1)

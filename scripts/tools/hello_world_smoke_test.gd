extends SceneTree


func _init() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("Failed to load main scene.")
		quit(1)
		return

	var root := scene.instantiate()
	if root == null:
		push_error("Failed to instantiate main scene.")
		quit(1)
		return

	var label := root.get_node_or_null("CenterContainer/HelloLabel") as Label
	if label == null:
		push_error("HelloLabel was not found.")
		root.free()
		quit(1)
		return

	if label.text != "Hello, Godot!":
		push_error("Unexpected label text: %s" % label.text)
		root.free()
		quit(1)
		return

	root.free()
	print("SMOKE_TEST_PASS hello_world")
	quit(0)

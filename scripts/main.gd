extends Control

@onready var hello_label: Label = $CenterContainer/HelloLabel


func _ready() -> void:
	hello_label.text = "Hello, Godot!"
	print("HELLO_WORLD_READY")

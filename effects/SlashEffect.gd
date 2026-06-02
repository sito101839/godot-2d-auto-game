extends Area2D

@export var lifetime: float = 0.16

var team_id: int = -1
var damage: int = 0
var hit_units: Array[int] = []

@onready var visual: Polygon2D = $Visual


func setup(new_team_id: int, new_damage: int, direction: Vector2, color: Color) -> void:
	team_id = new_team_id
	damage = new_damage
	rotation = direction.angle()

	if is_node_ready():
		visual.color = color
	else:
		await ready
		visual.color = color


func _physics_process(delta: float) -> void:
	lifetime -= delta
	_apply_overlapping_hits()

	if lifetime <= 0.0:
		queue_free()


func _apply_overlapping_hits() -> void:
	for body: Node2D in get_overlapping_bodies():
		if not body.has_method("take_damage"):
			continue
		if body.get("is_dead") or body.get("team_id") == team_id:
			continue

		var unit_id: int = body.get_instance_id()
		if hit_units.has(unit_id):
			continue

		hit_units.append(unit_id)
		body.call("take_damage", damage)

extends Area2D

@export var speed: float = 360.0
@export var lifetime: float = 1.4

var team_id: int = -1
var damage: int = 0
var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null

@onready var visual: Polygon2D = $Visual


func setup(new_team_id: int, new_damage: int, new_direction: Vector2, color: Color, new_target: Node2D) -> void:
	team_id = new_team_id
	damage = new_damage
	direction = new_direction.normalized()
	target = new_target
	rotation = direction.angle()

	if is_node_ready():
		visual.color = color
	else:
		await ready
		visual.color = color


func _physics_process(delta: float) -> void:
	if is_instance_valid(target) and not target.get("is_dead"):
		direction = global_position.direction_to(target.global_position)
		rotation = direction.angle()
		if global_position.distance_to(target.global_position) <= speed * delta + 10.0:
			_apply_hit_to_target(target)
			return

	global_position += direction * speed * delta
	lifetime -= delta
	_apply_first_hit()

	if lifetime <= 0.0:
		queue_free()


func _apply_first_hit() -> void:
	for body: Node2D in get_overlapping_bodies():
		if not body.has_method("take_damage"):
			continue
		if body.get("is_dead") or body.get("team_id") == team_id:
			continue

		body.call("take_damage", damage)
		queue_free()
		return


func _apply_hit_to_target(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		queue_free()
		return
	if body.get("is_dead") or body.get("team_id") == team_id:
		queue_free()
		return

	body.call("take_damage", damage)
	queue_free()

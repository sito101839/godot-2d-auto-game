class_name Unit
extends CharacterBody2D

@export var team_id: int = 0
@export var max_hp: int = 100
@export var attack_power: int = 10
@export var attack_range: float = 80.0
@export var move_speed: float = 80.0
@export var attack_interval: float = 1.0

var hp: int
var target: Unit = null
var attack_cooldown: float = 0.0
var is_dead: bool = false

@onready var visual: Polygon2D = $Visual
@onready var hp_bar: ProgressBar = $HPBar


func _ready() -> void:
	add_to_group("units")
	hp = max_hp
	_update_hp_bar()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if target == null or not is_instance_valid(target) or target.is_dead:
		target = _find_nearest_enemy()

	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_target: float = global_position.distance_to(target.global_position)
	if distance_to_target > attack_range:
		var direction: Vector2 = global_position.direction_to(target.global_position)
		velocity = direction * move_speed
		move_and_slide()
		return

	velocity = Vector2.ZERO
	move_and_slide()
	_try_attack()


func setup(new_team_id: int, color: Color) -> void:
	team_id = new_team_id
	if is_node_ready():
		visual.color = color
	else:
		await ready
		visual.color = color


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	hp = max(0, hp - amount)
	_update_hp_bar()

	if hp <= 0:
		_die()


func _find_nearest_enemy() -> Unit:
	var nearest_enemy: Unit = null
	var nearest_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit == self:
			continue
		if unit.team_id == team_id or unit.is_dead:
			continue

		var distance: float = global_position.distance_to(unit.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = unit

	return nearest_enemy


func _try_attack() -> void:
	if attack_cooldown > 0.0:
		return
	if target == null or not is_instance_valid(target) or target.is_dead:
		return

	target.take_damage(attack_power)
	attack_cooldown = attack_interval


func _update_hp_bar() -> void:
	if hp_bar == null:
		return

	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _die() -> void:
	is_dead = true
	remove_from_group("units")
	queue_free()

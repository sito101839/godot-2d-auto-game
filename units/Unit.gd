class_name Unit
extends CharacterBody2D

enum TargetPolicy { NEAREST, LOW_HP, HIGH_HP }

@export var team_id: int = 0
@export var unit_type_name: String = "Warrior"
@export var target_policy: TargetPolicy = TargetPolicy.NEAREST
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
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	add_to_group("units")
	hp = max_hp
	_update_hp_bar()
	_update_name_label()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	target = _find_target()

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


func setup(
	new_team_id: int,
	color: Color,
	new_unit_type_name: String,
	new_target_policy: TargetPolicy,
	new_max_hp: int,
	new_attack_power: int,
	new_attack_range: float,
	new_move_speed: float
) -> void:
	team_id = new_team_id
	unit_type_name = new_unit_type_name
	target_policy = new_target_policy
	max_hp = new_max_hp
	attack_power = new_attack_power
	attack_range = new_attack_range
	move_speed = new_move_speed
	hp = max_hp

	if is_node_ready():
		visual.color = color
		_update_hp_bar()
		_update_name_label()
	else:
		await ready
		visual.color = color
		_update_hp_bar()
		_update_name_label()


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	hp = max(0, hp - amount)
	_update_hp_bar()

	if hp <= 0:
		_die()


func _find_target() -> Unit:
	var selected_enemy: Unit = null
	var best_distance: float = INF

	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit == self:
			continue
		if unit.team_id == team_id or unit.is_dead:
			continue

		if selected_enemy == null or _is_better_target(unit, selected_enemy, best_distance):
			selected_enemy = unit
			best_distance = global_position.distance_to(unit.global_position)

	return selected_enemy


func _is_better_target(candidate: Unit, current: Unit, current_distance: float) -> bool:
	match target_policy:
		TargetPolicy.LOW_HP:
			if candidate.hp != current.hp:
				return candidate.hp < current.hp
		TargetPolicy.HIGH_HP:
			if candidate.hp != current.hp:
				return candidate.hp > current.hp
		_:
			pass

	var candidate_distance: float = global_position.distance_to(candidate.global_position)
	return candidate_distance < current_distance


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


func _update_name_label() -> void:
	if name_label == null:
		return

	name_label.text = unit_type_name.substr(0, 1)


func _die() -> void:
	is_dead = true
	remove_from_group("units")
	queue_free()

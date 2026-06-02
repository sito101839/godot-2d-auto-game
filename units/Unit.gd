class_name Unit
extends CharacterBody2D

enum TargetPolicy { NEAREST, LOW_HP, HIGH_HP }
enum FormationRole { FRONTLINE, BACKLINE, FLANKER }

const RANGED_ATTACK_RANGE_THRESHOLD: float = 100.0
const BACKLINE_OFFSET: float = 70.0
const BACKLINE_TOLERANCE: float = 18.0
const SLASH_EFFECT_SCENE := preload("res://effects/SlashEffect.tscn")
const PROJECTILE_EFFECT_SCENE := preload("res://effects/ProjectileEffect.tscn")

@export var team_id: int = 0
@export var unit_type_name: String = "Warrior"
@export var target_policy: TargetPolicy = TargetPolicy.NEAREST
@export var formation_role: FormationRole = FormationRole.FRONTLINE
@export var max_hp: int = 100
@export var attack_power: int = 10
@export var attack_range: float = 80.0
@export var move_speed: float = 80.0
@export var attack_interval: float = 1.0

var hp: int
var target: Unit = null
var attack_cooldown: float = 0.0
var is_dead: bool = false
var effects_parent: Node2D = null

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
		var move_target: Vector2 = _get_move_target_position(target.global_position)
		var direction: Vector2 = global_position.direction_to(move_target)
		if global_position.distance_to(move_target) <= 2.0:
			direction = Vector2.ZERO
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
	new_formation_role: FormationRole,
	new_max_hp: int,
	new_attack_power: int,
	new_attack_range: float,
	new_move_speed: float,
	new_effects_parent: Node2D
) -> void:
	team_id = new_team_id
	unit_type_name = new_unit_type_name
	target_policy = new_target_policy
	formation_role = new_formation_role
	max_hp = new_max_hp
	attack_power = new_attack_power
	attack_range = new_attack_range
	move_speed = new_move_speed
	effects_parent = new_effects_parent
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


func _get_move_target_position(enemy_position: Vector2) -> Vector2:
	if formation_role != FormationRole.BACKLINE:
		return enemy_position

	var frontline_center: Vector2 = _get_frontline_center()
	if frontline_center == Vector2.INF:
		return enemy_position

	var direction_to_enemy: Vector2 = global_position.direction_to(enemy_position)
	var desired_position: Vector2 = global_position + direction_to_enemy * minf(move_speed, global_position.distance_to(enemy_position))
	desired_position = _keep_backline_behind_frontline(desired_position, frontline_center)

	var guard_x: float = _get_backline_guard_x(frontline_center)
	if absf(global_position.x - guard_x) <= BACKLINE_TOLERANCE:
		desired_position.x = global_position.x

	return desired_position


func _keep_backline_behind_frontline(candidate_position: Vector2, frontline_center: Vector2) -> Vector2:
	var guard_x: float = _get_backline_guard_x(frontline_center)

	if team_id == 0:
		candidate_position.x = minf(candidate_position.x, guard_x)
	else:
		candidate_position.x = maxf(candidate_position.x, guard_x)

	return candidate_position


func _get_backline_guard_x(frontline_center: Vector2) -> float:
	var rear_direction: float = -1.0 if team_id == 0 else 1.0
	return frontline_center.x + rear_direction * BACKLINE_OFFSET


func _get_frontline_center() -> Vector2:
	var sum := Vector2.ZERO
	var count: int = 0

	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit := node as Unit
		if unit == null or unit.is_dead:
			continue
		if unit.team_id != team_id or unit.formation_role != FormationRole.FRONTLINE:
			continue

		sum += unit.global_position
		count += 1

	if count == 0:
		return Vector2.INF

	return sum / float(count)


func _try_attack() -> void:
	if attack_cooldown > 0.0:
		return
	if target == null or not is_instance_valid(target) or target.is_dead:
		return

	_spawn_attack_effect()
	attack_cooldown = attack_interval


func _spawn_attack_effect() -> void:
	if effects_parent == null or not is_instance_valid(effects_parent):
		target.take_damage(attack_power)
		return

	var direction: Vector2 = global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	if attack_range >= RANGED_ATTACK_RANGE_THRESHOLD:
		_spawn_projectile_effect(direction)
	else:
		_spawn_slash_effect(direction)


func _spawn_slash_effect(direction: Vector2) -> void:
	var slash := SLASH_EFFECT_SCENE.instantiate() as Area2D
	effects_parent.add_child(slash)
	slash.global_position = global_position
	slash.call("setup", team_id, attack_power, direction, visual.color.lightened(0.35))


func _spawn_projectile_effect(direction: Vector2) -> void:
	var projectile := PROJECTILE_EFFECT_SCENE.instantiate() as Area2D
	effects_parent.add_child(projectile)
	projectile.global_position = global_position + direction * 24.0
	projectile.call("setup", team_id, attack_power, direction, visual.color.lightened(0.25), target)


func _update_hp_bar() -> void:
	if hp_bar == null:
		return

	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _update_name_label() -> void:
	if name_label == null:
		return

	var role_suffix: String = "F"
	match formation_role:
		FormationRole.BACKLINE:
			role_suffix = "B"
		FormationRole.FLANKER:
			role_suffix = "S"
		_:
			role_suffix = "F"

	name_label.text = "%s%s" % [unit_type_name.substr(0, 1), role_suffix]


func _die() -> void:
	is_dead = true
	remove_from_group("units")
	queue_free()

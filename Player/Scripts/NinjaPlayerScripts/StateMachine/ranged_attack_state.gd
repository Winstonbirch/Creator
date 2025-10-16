extends PlayerStateNinja

@export var attack_data: AttackData
@export var combat_component: CombatComponent

var attack_finished: bool = false
var projectile_spawned: bool = false

func enter() -> void:
	print("RangedAttackState entered")
	
	# SAFETY CHECKS
	if not attack_data:
		push_error("RangedAttackState: No attack_data assigned!")
		transitioned.emit("IdleState")
		return
	
	if not combat_component:
		push_error("RangedAttackState: No combat_component assigned!")
		transitioned.emit("IdleState")
		return
	
	attack_finished = false
	projectile_spawned = false
	
	# Lock in place or allow movement based on attack data
	if attack_data.movement_type == AttackData.MovementType.LOCKED:
		actor.velocity = Vector2.ZERO
	
	if animated_sprite:
		print("Playing animation: ", attack_data.animation_name)
		animated_sprite.play(attack_data.animation_name)
		if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
			animated_sprite.animation_finished.connect(_on_attack_animation_finished)
	
	# Spawn projectile
	print("Calling combat_component.start_attack()")
	combat_component.start_attack(attack_data)

func exit() -> void:
	if combat_component:
		combat_component.end_attack()
	
	if animated_sprite and animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)

func check_transitions() -> void:
	if attack_finished:
		if input_direction.length() > 0:
			transitioned.emit("WalkState")
		else:
			transitioned.emit("IdleState")

func physics_update(delta: float) -> void:
	if not attack_data:
		return
	
	# Allow slight movement or lock based on attack data
	match attack_data.movement_type:
		AttackData.MovementType.LOCKED:
			actor.velocity = Vector2.ZERO
		AttackData.MovementType.SLOW:
			actor.velocity.x = input_direction.x * 200.0 * attack_data.movement_speed_multiplier
		_:
			actor.velocity.x = input_direction.x * 200.0
	
	# Apply gravity if in air
	if not actor.is_on_floor():
		actor.velocity.y += 980.0 * delta
	
	actor.move_and_slide()

func _on_attack_animation_finished() -> void:
	print("Ranged attack animation finished")
	attack_finished = true
	check_transitions()

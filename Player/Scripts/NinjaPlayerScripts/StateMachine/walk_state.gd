extends PlayerStateNinja

@export var move_speed: float = 500.0

func enter() -> void:
	animated_sprite.play("Walking")

func check_transitions() -> void:
	if handle_jump_input() and GameMode.current_mode == GameMode.Mode.PLATFORMER:  # Only jump in platformer
		transitioned.emit("JumpState")
	elif handle_attack_input():
		transitioned.emit("AttackState")
	elif handle_ranged_attack_input():
		transitioned.emit("RangedAttackState")
	elif input_direction.length() == 0:
		transitioned.emit("IdleState")

func physics_update(delta: float) -> void:
	apply_gravity(delta)  
	
	actor.velocity.x = input_direction.x * move_speed
	
	# Top-down mode also uses Y velocity
	if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
		actor.velocity.y = input_direction.y * move_speed
	
	# Flip sprite based on direction
	if input_direction.x != 0:
		animated_sprite.flip_h = input_direction.x < 0
	
	actor.move_and_slide()

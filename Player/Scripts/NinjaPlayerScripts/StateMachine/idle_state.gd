extends PlayerStateNinja

func enter() -> void:
	if animated_sprite:
		animated_sprite.play("Idle")
	if actor:
		actor.velocity = Vector2.ZERO

func check_transitions() -> void:
	if handle_jump_input() and GameMode.current_mode == GameMode.Mode.PLATFORMER:  # Only jump in platformer
		transitioned.emit("JumpState")
	elif handle_ranged_attack_input():
		transitioned.emit("RangedAttackState")
	elif handle_attack_input():
		transitioned.emit("AttackState")
	elif input_direction.length() > 0:
		transitioned.emit("WalkState")

func physics_update(delta: float) -> void:
	apply_gravity(delta)  # Add this
	
	if actor:
		actor.velocity.x = 0
		if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
			actor.velocity.y = 0  # Stop Y movement in top-down
		actor.move_and_slide()

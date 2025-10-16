extends PlayerStateNinja

@export var jump_velocity: float = -400.0
@export var move_speed: float = 200.0

func enter() -> void:
	if animated_sprite:
		animated_sprite.play("jump")
	if actor:
		actor.velocity.y = jump_velocity

func check_transitions() -> void:
	if actor and actor.is_on_floor():
		if input_direction.length() > 0:
			transitioned.emit("WalkState")
		else:
			transitioned.emit("IdleState")

func physics_update(delta: float) -> void:
	apply_gravity(delta)  # Gravity already handled by apply_gravity
	
	if actor:
		actor.velocity.x = input_direction.x * move_speed
		
		if input_direction.x != 0 and animated_sprite:
			animated_sprite.flip_h = input_direction.x < 0
		
		actor.move_and_slide()

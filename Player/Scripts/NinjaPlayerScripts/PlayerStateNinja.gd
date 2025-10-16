extends BaseState
class_name PlayerStateNinja

@export var actor: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

var input_direction: Vector2

func handle_movement_input() -> void:
	if GameMode.current_mode == GameMode.Mode.TOP_DOWN:  # GameMode.Mode instead
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		input_direction = Vector2(
			Input.get_axis("move_left", "move_right"),
			0
		)

func apply_gravity(delta: float) -> void:
	GameMode.apply_gravity(actor, delta)
	GameMode.reset_vertical_velocity(actor)

# ... rest of methods

func handle_jump_input() -> bool:
	return Input.is_action_just_pressed("jump")

func handle_attack_input() -> bool:
	return Input.is_action_just_pressed("attack")

func handle_ranged_attack_input() -> bool:
	return Input.is_action_just_pressed("ranged_attack")

# Override in child states to define state-specific transition logic
func check_transitions() -> void:
	
	pass

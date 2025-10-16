extends Node
class_name PlayerInputController

@export var state_machine: StateMachine

func _physics_process(_delta: float) -> void:
	if state_machine and state_machine.current_state is PlayerStateNinja:
		var player_state = state_machine.current_state as PlayerStateNinja
		# Update input first
		player_state.handle_movement_input()
		# Then check transitions
		player_state.check_transitions()

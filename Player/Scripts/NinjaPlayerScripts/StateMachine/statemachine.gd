extends Node
class_name StateMachine

@export var initial_state: BaseState

var current_state: BaseState
var states: Dictionary = {}

func _ready() -> void:
	print("=== STATE MACHINE INITIALIZING ===")
	
	for child in get_children():
		if child is BaseState:
			states[child.name] = child
			child.transitioned.connect(_on_state_transitioned)
			print("Registered state: ", child.name)
		else:
			print("WARNING: Child '", child.name, "' is not a BaseState!")
	
	print("Total states registered: ", states.size())
	
	if initial_state:
		print("Initial state set to: ", initial_state.name)
		current_state = initial_state
		current_state.enter()
		print("Entered initial state: ", current_state.name)
	else:
		print("ERROR: No initial state assigned!")

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _on_state_transitioned(new_state_name: String) -> void:
	var new_state = states.get(new_state_name)
	
	if !new_state:
		print("ERROR: State '", new_state_name, "' not found!")
		return
	
	if new_state == current_state:
		print("WARNING: Already in state '", new_state_name, "'")
		return
	
	print("Transitioning: ", current_state.name, " → ", new_state_name)
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()

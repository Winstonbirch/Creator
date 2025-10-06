# ===========================
# Player.gd - Dual Mode Player Character (PLATFORMER + TOP-DOWN)
# ===========================
class_name Player
extends CharacterBody2D

# ===========================
# GAME MODE
# ===========================
enum GameMode {
	PLATFORMER,
	TOP_DOWN
}

@export var current_mode: GameMode = GameMode.PLATFORMER
@export var mode_switch_key: String = "switch_mode"  # J key (set up in Input Map)

# ===========================
# PLAYER SETTINGS (Easy to adjust in Inspector)
# ===========================
@export_group("Platformer Settings")
@export var platformer_move_speed: float = 300.0
@export var jump_strength: float = 400.0
@export var gravity_multiplier: float = 1.0
@export var max_fall_speed: float = 1000.0

@export_group("Top-Down Settings")
@export var topdown_move_speed: float = 200.0

# ===========================
# SIGNALS (Before everything else)
# ===========================
signal player_landed
signal player_jumped
signal player_started_moving
signal player_stopped_moving
signal mode_switched(new_mode: GameMode)

# ===========================
# COMPONENTS (Declared BEFORE functions that use them)
# ===========================
@onready var input_handler: Node = $PlayerInput
@onready var movement: Node = $PlayerMovement
@onready var visuals: Node = $PlayerVisuals
@onready var audio: Node = $PlayerAudio
@onready var camera_controller: Node = $PlayerCamera

# Transition system
var transition_scene: CanvasLayer = null
var is_switching_mode: bool = false

# ===========================
# INITIALIZATION (Setup everything)
# ===========================
func _ready():
	print("Player: Setting up character...")
	setup_components()
	setup_transition()
	apply_mode_settings()

func setup_transition():
	"""Set up the transition effect"""
	# Load the transition scene (not the script)
	var transition_packed = load("res://ModeTransition.tscn")
	transition_scene = transition_packed.instantiate()
	
	# Add to the scene tree at root level
	get_tree().root.add_child(transition_scene)
	
	# Connect signal
	transition_scene.transition_finished.connect(_on_transition_finished)

func setup_components():
	"""Connect our components together"""
	# Check if each component exists before trying to use it
	if input_handler:
		input_handler.setup(self)
	else:
		print("Player: Warning - PlayerInput component not found!")
	
	if movement:
		movement.setup(self)
	else:
		print("Player: Warning - PlayerMovement component not found!")
	
	if visuals:
		visuals.setup(self)
	else:
		print("Player: Warning - PlayerVisuals component not found!")
	
	if audio:
		audio.setup(self)
	else:
		print("Player: Warning - PlayerAudio component not found!")
	
	if camera_controller:
		camera_controller.setup(self)
	else:
		print("Player: Warning - PlayerCamera component not found!")
	
	print("Player: Component setup complete!")

# ===========================
# MAIN GAME LOOP (Godot calls these automatically)
# ===========================
func _physics_process(delta):
	"""Called every physics frame - handle movement"""
	# Check for mode switch input
	if Input.is_action_just_pressed(mode_switch_key) and not is_switching_mode:
		start_mode_switch()
	
	# Don't process movement during transition
	if is_switching_mode:
		return
	
	# Let each component do its job (with safety checks)
	if input_handler:
		input_handler.handle_input()
	
	if movement:
		movement.update_movement(delta)
	
	# Use Godot's built-in collision system
	move_and_slide()
	
	# Update visuals, audio, and camera based on what happened
	if visuals:
		visuals.update_visuals()
	
	if audio:
		audio.update_audio()
	
	if camera_controller:
		camera_controller.update_camera()

# ===========================
# MODE SWITCHING
# ===========================
func start_mode_switch():
	"""Begin the mode switch with transition"""
	if is_switching_mode:
		return
	
	is_switching_mode = true
	
	# Determine what mode we're switching to
	var target_mode = GameMode.TOP_DOWN if current_mode == GameMode.PLATFORMER else GameMode.PLATFORMER
	
	# Start the transition effect
	var switch_delay = transition_scene.start_transition(target_mode)
	
	# Schedule the actual mode switch for halfway through transition
	get_tree().create_timer(switch_delay).timeout.connect(_do_mode_switch)

func _do_mode_switch():
	"""Actually switch the mode (called during transition)"""
	switch_mode()

func _on_transition_finished():
	"""Called when transition animation completes"""
	is_switching_mode = false
	print("Player: Transition complete!")

func switch_mode():
	"""Toggle between platformer and top-down mode"""
	if current_mode == GameMode.PLATFORMER:
		current_mode = GameMode.TOP_DOWN
		print("Player: Switched to TOP-DOWN mode")
	else:
		current_mode = GameMode.PLATFORMER
		print("Player: Switched to PLATFORMER mode")
	
	apply_mode_settings()
	mode_switched.emit(current_mode)

func apply_mode_settings():
	"""Apply physics and collision settings based on current mode"""
	if current_mode == GameMode.TOP_DOWN:
		# In top-down mode, disable gravity
		velocity.y = 0
	# In platformer mode, gravity is handled by PlayerMovement

func is_platformer_mode() -> bool:
	"""Check if we're in platformer mode"""
	return current_mode == GameMode.PLATFORMER

func is_topdown_mode() -> bool:
	"""Check if we're in top-down mode"""
	return current_mode == GameMode.TOP_DOWN

# ===========================
# PUBLIC METHODS (Other scripts can call these)
# ===========================
func get_input_direction() -> Vector2:
	"""Get which direction player wants to move (Vector2 for both modes)"""
	if input_handler:
		return input_handler.get_move_direction()
	return Vector2.ZERO

func is_on_ground() -> bool:
	"""Check if player is touching the ground (platformer mode only)"""
	if is_platformer_mode():
		return is_on_floor()
	return false

func is_moving() -> bool:
	"""Check if player is moving"""
	if is_platformer_mode():
		return abs(velocity.x) > 10.0
	else:
		return velocity.length() > 10.0

func get_move_speed() -> float:
	"""Get how fast the player moves (depends on mode)"""
	if is_platformer_mode():
		return platformer_move_speed
	else:
		return topdown_move_speed

func get_jump_strength() -> float:
	"""Get how strong the player's jump is"""
	return jump_strength

# ===========================
# EVENT EMISSION (Components can listen to these)
# ===========================
func emit_landing_event():
	"""Tell everyone the player landed"""
	player_landed.emit()

func emit_jump_event():
	"""Tell everyone the player jumped"""
	player_jumped.emit()

func emit_movement_events():
	"""Tell everyone about movement changes"""
	if is_moving():
		player_started_moving.emit()
	else:
		player_stopped_moving.emit()

# ===========================
# Player.gd - Simple Modular Player Character
# ===========================
class_name Player
extends CharacterBody2D

# ===========================
# PLAYER SETTINGS (Easy to adjust in Inspector)
# ===========================
@export_group("Movement Settings")
@export var move_speed: float = 300.0
@export var jump_strength: float = 400.0

@export_group("Physics Settings")  
@export var gravity_multiplier: float = 1.0
@export var max_fall_speed: float = 1000.0

# ===========================
# SIGNALS (Before everything else)
# ===========================
signal player_landed
signal player_jumped
signal player_started_moving
signal player_stopped_moving

# ===========================
# COMPONENTS (Declared BEFORE functions that use them)
# ===========================
@onready var input_handler: Node = $PlayerInput
@onready var movement: Node = $PlayerMovement
@onready var visuals: Node = $PlayerVisuals
@onready var audio: Node = $PlayerAudio
@onready var camera_controller: Node = $PlayerCamera

# ===========================
# INITIALIZATION (Setup everything)
# ===========================
func _ready():
	print("Player: Setting up character...")
	_setup_components()

func _setup_components():
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
# PUBLIC METHODS (Other scripts can call these)
# ===========================
func get_input_direction() -> float:
	"""Get which direction player wants to move (-1, 0, or 1)"""
	if input_handler:
		return input_handler.get_move_direction()
	return 0.0

func is_on_ground() -> bool:
	"""Check if player is touching the ground"""
	return is_on_floor()

func is_moving() -> bool:
	"""Check if player is moving horizontally"""
	return abs(velocity.x) > 10.0

func get_move_speed() -> float:
	"""Get how fast the player moves"""
	return move_speed

func get_jump_strength() -> float:
	"""Get how strong the player's jump is"""
	return jump_strength

# ===========================
# EVENT EMISSION (Components can listen to these)
# ===========================
func _emit_landing_event():
	"""Tell everyone the player landed"""
	player_landed.emit()

func _emit_jump_event():
	"""Tell everyone the player jumped"""
	player_jumped.emit()

func _emit_movement_events():
	"""Tell everyone about movement changes"""
	if is_moving():
		player_started_moving.emit()
	else:
		player_stopped_moving.emit()

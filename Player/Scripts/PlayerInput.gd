# ===========================
# PlayerInput.gd - Handles all player input
# ===========================
class_name PlayerInput
extends Node

# ===========================
# WHAT THIS COMPONENT DOES:
# - Listens for keyboard/controller input
# - Tells other components what the player wants to do
# - Keeps input logic separate and organized
# ===========================

# Reference to our player
var player: Player

# Current input state
var move_direction: float = 0.0
var jump_pressed: bool = false
var jump_just_pressed: bool = false

# ===========================
# SETUP (Called by Player when game starts)
# ===========================
func setup(player_character: Player):
	"""Connect this component to the player"""
	player = player_character
	print("PlayerInput: Ready to handle input!")

# ===========================
# INPUT HANDLING (Called every frame by Player)
# ===========================
func handle_input():
	"""Check what buttons the player is pressing"""
	_update_movement_input()
	_update_jump_input()

func _update_movement_input():
	"""Check left/right movement"""
	# Use Godot's built-in input system
	move_direction = Input.get_axis("move_left", "move_right")
	
	# Note for beginners: 
	# - "move_left" and "move_right" are action names
	# - You set these up in Project Settings > Input Map
	# - get_axis() gives us -1 for left, +1 for right, 0 for nothing

func _update_jump_input():
	"""Check jump button"""
	jump_just_pressed = Input.is_action_just_pressed("jump")
	jump_pressed = Input.is_action_pressed("jump")
	
	# Note for beginners:
	# - is_action_just_pressed() = true only on the first frame button is pressed
	# - is_action_pressed() = true every frame while button is held down

# ===========================
# PUBLIC METHODS (Other components can ask for input info)
# ===========================
func get_move_direction() -> float:
	"""Get which direction player wants to move"""
	return move_direction

func wants_to_jump() -> bool:
	"""Check if player just pressed jump"""
	return jump_just_pressed

func is_holding_jump() -> bool:
	"""Check if player is holding jump button"""
	return jump_pressed

# ===========================
# DEBUG INFO (Helpful for beginners)
# ===========================
func get_debug_info() -> String:
	"""Get readable info about current input state"""
	var info = "Input Debug:\n"
	info += "Move Direction: " + str(move_direction) + "\n"
	info += "Jump Pressed: " + str(jump_just_pressed) + "\n"
	info += "Holding Jump: " + str(jump_pressed)
	return info

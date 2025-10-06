# ===========================
# PlayerInput.gd - Handles player input (DUAL MODE)
# ===========================
extends Node

var player: Player
var jump_pressed: bool = false

func setup(player_node: Player):
	"""Connect to the player"""
	player = player_node
	print("PlayerInput: Ready!")

func handle_input():
	"""Check what buttons the player is pressing"""
	# Check for jump input (only in platformer mode)
	if player.is_platformer_mode():
		if Input.is_action_just_pressed("ui_accept"):  # Usually spacebar/Enter
			jump_pressed = true
		else:
			jump_pressed = false

func get_move_direction() -> Vector2:
	"""Get the direction the player wants to move"""
	var direction = Vector2.ZERO
	
	if player.is_platformer_mode():
		# PLATFORMER MODE: Only horizontal movement
		direction.x = Input.get_axis("ui_left", "ui_right")
		direction.y = 0  # No vertical input in platformer
		
	else:
		# TOP-DOWN MODE: Full 2D movement
		direction.x = Input.get_axis("ui_left", "ui_right")
		direction.y = Input.get_axis("ui_up", "ui_down")
		
		# Normalize so diagonal movement isn't faster
		if direction.length() > 0:
			direction = direction.normalized()
	
	return direction

func wants_to_jump() -> bool:
	"""Check if player pressed jump (platformer mode only)"""
	return jump_pressed

# ===========================
# PlayerMovement.gd - Handles all player movement
# ===========================
class_name PlayerMovement
extends Node

# ===========================
# WHAT THIS COMPONENT DOES:
# - Takes input from PlayerInput
# - Calculates how the player should move
# - Applies gravity and physics
# - Keeps movement logic clean and separate
# ===========================

# Reference to our player
var player: Player

# Movement state tracking
var was_on_ground_last_frame: bool = false

# ===========================
# SETUP (Called by Player when game starts)
# ===========================
func setup(player_character: Player):
	"""Connect this component to the player"""
	player = player_character
	print("PlayerMovement: Ready to handle movement!")

# ===========================
# MOVEMENT UPDATE (Called every physics frame by Player)
# ===========================
func update_movement(delta: float):
	"""Calculate and apply all movement"""
	_apply_gravity(delta)
	_handle_horizontal_movement()
	_handle_jumping()
	_check_landing()

# ===========================
# GRAVITY (Makes player fall down)
# ===========================
func _apply_gravity(delta: float):
	"""Make the player fall down when not on ground"""
	# Only apply gravity if not on ground
	if not player.is_on_ground():
		# Use Godot's project gravity setting
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		gravity *= player.gravity_multiplier
		
		# Add gravity to downward velocity
		player.velocity.y += gravity * delta
		
		# Cap falling speed so player doesn't fall too fast
		player.velocity.y = min(player.velocity.y, player.max_fall_speed)

# ===========================
# HORIZONTAL MOVEMENT (Left and right)
# ===========================
func _handle_horizontal_movement():
	"""Move player left and right based on input"""
	var move_direction = player.get_input_direction()
	
	if move_direction != 0:
		# Player wants to move - set velocity directly for responsive controls
		player.velocity.x = move_direction * player.get_move_speed()
	else:
		# Player not pressing movement - stop smoothly
		player.velocity.x = move_toward(player.velocity.x, 0, player.get_move_speed())

# ===========================
# JUMPING (Going up)
# ===========================
func _handle_jumping():
	"""Handle jump logic"""
	# Check if player wants to jump - use direct Input check instead of component call
	var wants_to_jump = Input.is_action_just_pressed("jump")
	
	# Only jump if player wants to jump AND is on ground
	if wants_to_jump and player.is_on_ground():
		_perform_jump()

func _perform_jump():
	"""Make the player jump"""
	# Set upward velocity (negative Y is up in Godot)
	player.velocity.y = -player.get_jump_strength()
	
	# Tell everyone we jumped
	player._emit_jump_event()
	
	print("PlayerMovement: Player jumped!")

# ===========================
# LANDING DETECTION (When player hits ground)
# ===========================
func _check_landing():
	"""Check if player just landed on ground"""
	var is_on_ground_now = player.is_on_ground()
	
	# If we weren't on ground last frame, but are now = we just landed!
	if not was_on_ground_last_frame and is_on_ground_now:
		_handle_landing()
	
	# Remember ground state for next frame
	was_on_ground_last_frame = is_on_ground_now

func _handle_landing():
	"""Handle what happens when player lands"""
	# Tell everyone we landed
	player._emit_landing_event()
	
	print("PlayerMovement: Player landed!")

# ===========================
# UTILITY METHODS (Helpful info for other components)
# ===========================
func get_horizontal_speed() -> float:
	"""Get how fast player is moving horizontally"""
	return abs(player.velocity.x)

func get_vertical_speed() -> float:
	"""Get how fast player is moving vertically"""
	return player.velocity.y

func is_falling() -> bool:
	"""Check if player is falling down"""
	return player.velocity.y > 0 and not player.is_on_ground()

func is_rising() -> bool:
	"""Check if player is moving up (jumping)"""
	return player.velocity.y < 0

# ===========================
# DEBUG INFO (Helpful for beginners)
# ===========================
func get_debug_info() -> String:
	"""Get readable info about movement state"""
	var info = "Movement Debug:\n"
	info += "Velocity: " + str(player.velocity) + "\n"
	info += "On Ground: " + str(player.is_on_ground()) + "\n"
	info += "Horizontal Speed: " + str(get_horizontal_speed()) + "\n"
	info += "Is Falling: " + str(is_falling()) + "\n"
	info += "Is Rising: " + str(is_rising())
	return info

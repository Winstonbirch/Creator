# ===========================
# PlayerMovement.gd - Handles player movement (DUAL MODE)
# ===========================
extends Node

var player: Player
var was_on_ground: bool = false

func setup(player_node: Player):
	"""Connect to the player"""
	player = player_node
	print("PlayerMovement: Ready!")

func update_movement(delta):
	"""Update the player's velocity based on current mode"""
	if player.is_platformer_mode():
		update_platformer_movement(delta)
	else:
		update_topdown_movement(delta)
	
	# Emit movement events
	player.emit_movement_events()

# ===========================
# PLATFORMER MOVEMENT
# ===========================
func update_platformer_movement(delta):
	"""Handle platformer physics (gravity + jumping)"""
	var direction = player.get_input_direction()
	
	# Apply gravity
	if not player.is_on_ground():
		player.velocity.y += get_gravity() * delta
		# Cap falling speed
		if player.velocity.y > player.max_fall_speed:
			player.velocity.y = player.max_fall_speed
	
	# Handle jumping
	if player.input_handler.wants_to_jump() and player.is_on_ground():
		player.velocity.y = -player.get_jump_strength()
		player.emit_jump_event()
	
	# Horizontal movement
	if direction.x != 0:
		player.velocity.x = direction.x * player.get_move_speed()
	else:
		# Apply friction when not moving
		player.velocity.x = move_toward(player.velocity.x, 0, player.get_move_speed() * delta * 10)
	
	# Check for landing
	if player.is_on_ground() and not was_on_ground:
		player.emit_landing_event()
	
	was_on_ground = player.is_on_ground()

# ===========================
# TOP-DOWN MOVEMENT
# ===========================
func update_topdown_movement(_delta):
	"""Handle top-down physics (no gravity, 8-directional movement)"""
	var direction = player.get_input_direction()
	
	# Set velocity based on direction and speed
	player.velocity = direction * player.get_move_speed()
	
	# No gravity in top-down mode!

# ===========================
# HELPER FUNCTIONS
# ===========================
func get_gravity() -> float:
	"""Calculate gravity for platformer mode"""
	return 980.0 * player.gravity_multiplier

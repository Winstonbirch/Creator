# ===========================
# PlayerVisuals.gd - Handles how the player looks
# ===========================
class_name PlayerVisuals
extends Node

# ===========================
# WHAT THIS COMPONENT DOES:
# - Controls player sprite and animations
# - Makes player face the right direction
# - Changes appearance based on what player is doing
# - Keeps visual logic separate and organized
# ===========================

# Reference to our player
var player: Player

# Visual components (we'll find these automatically)
var sprite: Sprite2D
var animation_player: AnimationPlayer

# State tracking
var facing_direction: int = 1  # 1 = right, -1 = left
var last_animation: String = ""

# ===========================
# SETUP (Called by Player when game starts)
# ===========================
func setup(player_character: Player):
	"""Connect this component to the player and find visual parts"""
	player = player_character
	_find_visual_components()
	_connect_to_player_events()
	print("PlayerVisuals: Ready to handle visuals!")

func _find_visual_components():
	"""Automatically find the sprite and animation player"""
	# Look for Sprite2D anywhere in the player scene
	sprite = player.find_child("Sprite2D", true, false)
	if not sprite:
		print("PlayerVisuals: Warning - No Sprite2D found!")
	
	# Look for AnimationPlayer anywhere in the player scene
	animation_player = player.find_child("AnimationPlayer", true, false)
	if not animation_player:
		print("PlayerVisuals: Warning - No AnimationPlayer found!")

func _connect_to_player_events():
	"""Listen for things that happen to the player"""
	# Connect to player signals so we know when to change visuals
	player.player_landed.connect(_on_player_landed)
	player.player_jumped.connect(_on_player_jumped)

# ===========================
# VISUAL UPDATE (Called every frame by Player)
# ===========================
func update_visuals():
	"""Update how the player looks based on what they're doing"""
	_update_facing_direction()
	_update_animation()

# ===========================
# FACING DIRECTION (Make player face where they're moving)
# ===========================
func _update_facing_direction():
	"""Make player sprite face the direction they're moving"""
	var move_direction = player.get_input_direction()
	
	# Only change direction if player is actually trying to move
	if move_direction != 0:
		facing_direction = 1 if move_direction > 0 else -1
		_apply_facing_direction()

func _apply_facing_direction():
	"""Actually flip the sprite"""
	if sprite:
		# Flip sprite by changing scale
		# Positive scale = facing right, negative = facing left
		sprite.scale.x = abs(sprite.scale.x) * facing_direction

# ===========================
# ANIMATION SYSTEM (Change animations based on player state)
# ===========================
func _update_animation():
	"""Choose the right animation for what player is doing"""
	var new_animation = _determine_current_animation()
	
	# Only change animation if it's different from current one
	if new_animation != last_animation:
		_play_animation(new_animation)
		last_animation = new_animation

func _determine_current_animation() -> String:
	"""Figure out what animation should be playing"""
	# Check different states in order of priority
	
	if not player.is_on_ground():
		# Player is in the air
		if player.velocity.y > 0:  # Simple falling check
			return "fall"
		else:
			return "jump"
	
	elif player.is_moving():
		# Player is moving on ground
		return "walk"
	
	else:
		# Player is standing still
		return "idle"

func _play_animation(animation_name: String):
	"""Actually play the animation"""
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		print("PlayerVisuals: Playing animation - " + animation_name)
	else:
		if animation_player:
			print("PlayerVisuals: Animation '" + animation_name + "' not found!")

# ===========================
# EVENT HANDLERS (Respond to things that happen)
# ===========================
func _on_player_landed():
	"""Called when player lands on ground"""
	print("PlayerVisuals: Player landed - could add landing effects here!")
	# You could add things like:
	# - Dust cloud effect
	# - Screen shake
	# - Landing animation

func _on_player_jumped():
	"""Called when player jumps"""
	print("PlayerVisuals: Player jumped - could add jump effects here!")
	# You could add things like:
	# - Jump particle effect
	# - Squash and stretch animation

# ===========================
# UTILITY METHODS (Helpful for other systems)
# ===========================
func get_facing_direction() -> int:
	"""Get which direction player is facing (1 = right, -1 = left)"""
	return facing_direction

func is_facing_right() -> bool:
	"""Check if player is facing right"""
	return facing_direction > 0

func get_current_animation() -> String:
	"""Get name of currently playing animation"""
	return last_animation

# ===========================
# MANUAL VISUAL CONTROL (For special situations)
# ===========================
func force_animation(animation_name: String):
	"""Force a specific animation to play"""
	_play_animation(animation_name)
	last_animation = animation_name

func set_facing_direction(direction: int):
	"""Manually set which direction player faces"""
	facing_direction = 1 if direction > 0 else -1
	_apply_facing_direction()

# ===========================
# DEBUG INFO (Helpful for beginners)
# ===========================
func get_debug_info() -> String:
	"""Get readable info about visual state"""
	var info = "Visuals Debug:\n"
	info += "Facing Direction: " + str(facing_direction) + "\n"
	info += "Current Animation: " + str(last_animation) + "\n"
	info += "Has Sprite: " + str(sprite != null) + "\n"
	info += "Has AnimationPlayer: " + str(animation_player != null)
	return info

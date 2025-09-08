# ===========================
# PlayerCamera.gd - Camera that follows the player
# ===========================
class_name PlayerCamera
extends Node

# ===========================
# WHAT THIS COMPONENT DOES:
# - Makes camera follow the player smoothly
# - Keeps player centered on screen
# - Handles camera bounds and limits
# - Adds nice camera effects like screen shake
# - Keeps camera logic separate and organized
# ===========================

# Reference to our player
var player: Player

# Camera component (we'll find this automatically)
var camera: Camera2D

# ===========================
# CAMERA SETTINGS (Easy to adjust in Inspector)
# ===========================
@export_group("Follow Settings")
@export var follow_speed: float = 5.0  # How fast camera catches up to player
@export var follow_player: bool = true  # Whether to follow player at all
@export var smooth_movement: bool = true  # Smooth vs instant following

@export_group("Offset Settings")
@export var camera_offset: Vector2 = Vector2.ZERO  # Camera position offset
@export var look_ahead_distance: float = 100.0  # Look ahead when moving
@export var look_ahead_speed: float = 2.0  # How fast to look ahead

@export_group("Boundaries")
@export var use_boundaries: bool = false  # Limit where camera can go
@export var boundary_left: float = -1000.0
@export var boundary_right: float = 1000.0
@export var boundary_top: float = -1000.0
@export var boundary_bottom: float = 1000.0

@export_group("Screen Shake")
@export var shake_enabled: bool = true
@export var shake_intensity: float = 1.0

# Internal state
var base_position: Vector2
var look_ahead_offset: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO
var shake_timer: float = 0.0

# ===========================
# SETUP (Called by Player when game starts)
# ===========================
func setup(player_character: Player):
	"""Connect this component to the player and find camera"""
	player = player_character
	_find_camera_component()
	_setup_camera_properties()
	_connect_to_player_events()
	print("PlayerCamera: Ready to follow player!")

func _find_camera_component():
	"""Find the Camera2D node"""
	# Look for Camera2D anywhere in the player scene
	camera = player.find_child("Camera2D", true, false)
	
	if not camera:
		# If no camera found, create one automatically
		_create_default_camera()

func _create_default_camera():
	"""Create a basic camera if none exists"""
	camera = Camera2D.new()
	camera.name = "PlayerCamera2D"
	# Make this camera the current one
	camera.make_current()
	player.add_child(camera)
	print("PlayerCamera: Created default camera")

func _setup_camera_properties():
	"""Set up basic camera properties"""
	if camera:
		# Make sure this is the active camera
		camera.make_current()
		
		# Enable smoothing for nice movement
		camera.position_smoothing_enabled = smooth_movement
		camera.position_smoothing_speed = follow_speed
		
		# Set initial position
		base_position = player.global_position + camera_offset

func _connect_to_player_events():
	"""Listen for player events that might affect camera"""
	player.player_landed.connect(_on_player_landed)
	# We could add more events here for different camera effects

# ===========================
# CAMERA UPDATE (Called every frame by Player)
# ===========================
func update_camera():
	"""Update camera position and effects"""
	if not camera or not follow_player:
		return
	
	_update_base_position()
	_update_look_ahead()
	_update_screen_shake()
	_apply_camera_position()

# ===========================
# POSITION FOLLOWING (Make camera follow player)
# ===========================
func _update_base_position():
	"""Calculate where camera should be based on player position"""
	var target_position = player.global_position + camera_offset
	
	if smooth_movement:
		# Smooth following using Godot's built-in lerp
		var delta = 1.0/60.0  # Safe fallback
		base_position = base_position.lerp(target_position, follow_speed * delta)
	else:
		# Instant following
		base_position = target_position

# ===========================
# LOOK AHEAD (Camera looks ahead in movement direction)
# ===========================
func _update_look_ahead():
	"""Make camera look ahead in the direction player is moving"""
	if look_ahead_distance <= 0:
		look_ahead_offset = Vector2.ZERO
		return
	
	# Get player's movement direction
	var move_direction = player.get_input_direction()
	var target_look_ahead = Vector2(move_direction * look_ahead_distance, 0)
	
	# Smoothly move look ahead offset
	var delta = 1.0/60.0  # Safe fallback
	look_ahead_offset = look_ahead_offset.lerp(target_look_ahead, look_ahead_speed * delta)

# ===========================
# SCREEN SHAKE (Add juice to impacts)
# ===========================
func _update_screen_shake():
	"""Update screen shake effect"""
	if shake_timer > 0:
		var delta = 1.0/60.0  # Safe fallback
		shake_timer -= delta
		
		# Create random shake offset
		var shake_strength = shake_timer * shake_intensity
		shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		shake_offset = Vector2.ZERO

func start_screen_shake(duration: float, intensity: float = 1.0):
	"""Start a screen shake effect"""
	if not shake_enabled:
		return
	
	shake_timer = duration
	shake_intensity = intensity
	print("PlayerCamera: Screen shake started!")

# ===========================
# CAMERA BOUNDARIES (Keep camera within limits)
# ===========================
func _apply_boundaries(position: Vector2) -> Vector2:
	"""Keep camera within set boundaries"""
	if not use_boundaries:
		return position
	
	# Clamp camera position to boundaries
	position.x = clamp(position.x, boundary_left, boundary_right)
	position.y = clamp(position.y, boundary_top, boundary_bottom)
	
	return position

# ===========================
# FINAL POSITION CALCULATION (Put it all together)
# ===========================
func _apply_camera_position():
	"""Calculate final camera position with all effects"""
	# Start with base following position
	var final_position = base_position
	
	# Add look ahead offset
	final_position += look_ahead_offset
	
	# Add screen shake
	final_position += shake_offset
	
	# Apply boundaries
	final_position = _apply_boundaries(final_position)
	
	# Set camera position
	camera.global_position = final_position

# ===========================
# EVENT HANDLERS (Respond to player events)
# ===========================
func _on_player_landed():
	"""Add screen shake when player lands"""
	# Small shake when landing
	start_screen_shake(0.1, 5.0)

# ===========================
# MANUAL CAMERA CONTROL (For special situations)
# ===========================
func set_camera_target(target_position: Vector2, instant: bool = false):
	"""Manually move camera to a specific position"""
	if instant:
		base_position = target_position
		camera.global_position = target_position
	else:
		base_position = target_position

func focus_on_player(instant: bool = false):
	"""Make camera focus on player"""
	set_camera_target(player.global_position + camera_offset, instant)

func set_zoom(zoom_level: Vector2):
	"""Change camera zoom level"""
	if camera:
		camera.zoom = zoom_level

func get_camera_zoom() -> Vector2:
	"""Get current camera zoom"""
	if camera:
		return camera.zoom
	return Vector2.ONE

# ===========================
# CAMERA EFFECTS (Add visual polish)
# ===========================
func camera_punch(direction: Vector2, strength: float = 50.0):
	"""Quick camera movement in a direction"""
	base_position += direction.normalized() * strength

func start_camera_shake_on_input():
	"""Shake camera when player does specific actions"""
	# This could be called by other systems
	start_screen_shake(0.2, 10.0)

# ===========================
# SETTINGS CONTROL (Easy adjustments)
# ===========================
func set_follow_speed(speed: float):
	"""Change how fast camera follows player"""
	follow_speed = speed
	if camera:
		camera.position_smoothing_speed = speed

func set_smooth_movement(enabled: bool):
	"""Turn smooth camera movement on/off"""
	smooth_movement = enabled
	if camera:
		camera.position_smoothing_enabled = enabled

func set_camera_offset(offset: Vector2):
	"""Change camera position offset"""
	camera_offset = offset

func set_boundaries(left: float, right: float, top: float, bottom: float):
	"""Set camera movement boundaries"""
	boundary_left = left
	boundary_right = right
	boundary_top = top
	boundary_bottom = bottom
	use_boundaries = true

# ===========================
# DEBUG INFO (Helpful for beginners)
# ===========================
func get_debug_info() -> String:
	"""Get readable info about camera state"""
	var info = "Camera Debug:\n"
	info += "Has Camera: " + str(camera != null) + "\n"
	info += "Following Player: " + str(follow_player) + "\n"
	info += "Base Position: " + str(base_position) + "\n"
	info += "Look Ahead: " + str(look_ahead_offset) + "\n"
	info += "Shake Timer: " + str(shake_timer) + "\n"
	
	if camera:
		info += "Camera Position: " + str(camera.global_position) + "\n"
		info += "Camera Zoom: " + str(camera.zoom)
	
	return info

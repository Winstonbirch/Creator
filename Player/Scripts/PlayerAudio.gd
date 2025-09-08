# ===========================
# PlayerAudio.gd - Handles all player sounds
# ===========================
class_name PlayerAudio
extends Node

# ===========================
# WHAT THIS COMPONENT DOES:
# - Plays sound effects for player actions
# - Manages footstep sounds while walking
# - Keeps audio logic separate and organized
# - Makes it easy to add/change sounds
# ===========================

# Reference to our player
var player: Player

# Audio components (we'll find these automatically)
var audio_players: Array[AudioStreamPlayer2D] = []
var footstep_timer: Timer

# Sound settings
@export var footstep_interval: float = 0.4  # How often footsteps play
@export var jump_volume: float = 1.0
@export var land_volume: float = 0.8
@export var footstep_volume: float = 0.6

# State tracking
var is_playing_footsteps: bool = false

# ===========================
# SETUP (Called by Player when game starts)
# ===========================
func setup(player_character: Player):
	"""Connect this component to the player and setup audio"""
	player = player_character
	_find_audio_components()
	_setup_footstep_timer()
	_connect_to_player_events()
	print("PlayerAudio: Ready to handle audio!")

func _find_audio_components():
	"""Find all AudioStreamPlayer2D nodes for playing sounds"""
	# Get all AudioStreamPlayer2D children
	for child in player.get_children():
		if child is AudioStreamPlayer2D:
			audio_players.append(child)
	
	if audio_players.is_empty():
		print("PlayerAudio: Warning - No AudioStreamPlayer2D found!")
		# Create a basic one if none exist
		_create_default_audio_player()

func _create_default_audio_player():
	"""Create a basic audio player if none exist"""
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "DefaultAudioPlayer"
	player.add_child(audio_player)
	audio_players.append(audio_player)
	print("PlayerAudio: Created default audio player")

func _setup_footstep_timer():
	"""Create timer for footstep sounds"""
	footstep_timer = Timer.new()
	footstep_timer.name = "FootstepTimer"
	footstep_timer.wait_time = footstep_interval
	footstep_timer.one_shot = false  # Repeats automatically
	footstep_timer.timeout.connect(_play_footstep_sound)
	add_child(footstep_timer)

func _connect_to_player_events():
	"""Listen for player events to play appropriate sounds"""
	player.player_landed.connect(_on_player_landed)
	player.player_jumped.connect(_on_player_jumped)

# ===========================
# AUDIO UPDATE (Called every frame by Player)
# ===========================
func update_audio():
	"""Update audio based on what player is doing"""
	_update_footstep_sounds()

# ===========================
# FOOTSTEP SOUNDS (Play while walking)
# ===========================
func _update_footstep_sounds():
	"""Start or stop footstep sounds based on player movement"""
	var should_play_footsteps = player.is_moving() and player.is_on_ground()
	
	if should_play_footsteps and not is_playing_footsteps:
		_start_footstep_sounds()
	elif not should_play_footsteps and is_playing_footsteps:
		_stop_footstep_sounds()

func _start_footstep_sounds():
	"""Start playing footstep sounds"""
	is_playing_footsteps = true
	footstep_timer.start()
	print("PlayerAudio: Started footstep sounds")

func _stop_footstep_sounds():
	"""Stop playing footstep sounds"""
	is_playing_footsteps = false
	footstep_timer.stop()

func _play_footstep_sound():
	"""Play a single footstep sound"""
	# Note: You would load actual footstep sounds here
	# For now, we'll just indicate when it would play
	print("PlayerAudio: *footstep*")
	# Example of how to play a real sound:
	# _play_sound("footstep", footstep_volume)

# ===========================
# EVENT SOUND EFFECTS (Sounds for specific actions)
# ===========================
func _on_player_jumped():
	"""Play jump sound when player jumps"""
	print("PlayerAudio: *jump sound*")
	# Example: _play_sound("jump", jump_volume)

func _on_player_landed():
	"""Play landing sound when player hits ground"""
	print("PlayerAudio: *landing sound*")
	# Example: _play_sound("land", land_volume)

# ===========================
# SOUND PLAYING SYSTEM (Play specific sounds)
# ===========================
func _play_sound(sound_name: String, volume: float = 1.0):
	"""Play a specific sound effect"""
	# Find an available audio player
	var audio_player = _get_available_audio_player()
	if not audio_player:
		print("PlayerAudio: No available audio player!")
		return
	
	# Load and play the sound
	var sound_path = "res://audio/player/" + sound_name + ".ogg"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		audio_player.stream = sound
		audio_player.volume_db = linear_to_db(volume)
		audio_player.play()
	else:
		print("PlayerAudio: Sound file not found - " + sound_path)

func _get_available_audio_player() -> AudioStreamPlayer2D:
	"""Find an audio player that's not currently playing"""
	for audio_player in audio_players:
		if not audio_player.playing:
			return audio_player
	
	# If all are busy, use the first one anyway
	return audio_players[0] if not audio_players.is_empty() else null

# ===========================
# MANUAL SOUND CONTROL (For special situations)
# ===========================
func play_custom_sound(sound_name: String, volume: float = 1.0):
	"""Manually play any sound"""
	_play_sound(sound_name, volume)

func stop_all_sounds():
	"""Stop all currently playing sounds"""
	for audio_player in audio_players:
		audio_player.stop()
	_stop_footstep_sounds()

func set_footstep_speed(speed: float):
	"""Change how fast footsteps play"""
	footstep_interval = speed
	footstep_timer.wait_time = footstep_interval

# ===========================
# AUDIO SETTINGS (Easy to adjust)
# ===========================
func set_master_volume(volume: float):
	"""Change volume of all player sounds"""
	for audio_player in audio_players:
		audio_player.volume_db = linear_to_db(volume)

func set_jump_volume(volume: float):
	"""Change jump sound volume"""
	jump_volume = volume

func set_land_volume(volume: float):
	"""Change landing sound volume"""
	land_volume = volume

func set_footstep_volume(volume: float):
	"""Change footstep sound volume"""
	footstep_volume = volume

# ===========================
# DEBUG INFO (Helpful for beginners)
# ===========================
func get_debug_info() -> String:
	"""Get readable info about audio state"""
	var info = "Audio Debug:\n"
	info += "Audio Players: " + str(audio_players.size()) + "\n"
	info += "Playing Footsteps: " + str(is_playing_footsteps) + "\n"
	info += "Footstep Interval: " + str(footstep_interval) + "\n"
	
	var playing_count = 0
	for audio_player in audio_players:
		if audio_player.playing:
			playing_count += 1
	info += "Sounds Playing: " + str(playing_count)
	
	return info

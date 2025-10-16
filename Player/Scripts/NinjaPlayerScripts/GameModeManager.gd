extends Node

enum Mode { PLATFORMER, TOP_DOWN }  # Changed from GameMode to Mode

var current_mode: Mode = Mode.TOP_DOWN  # Use Mode instead
@export var gravity_strength: float = 980.0

var gravity_enabled: bool = true

func _ready() -> void:
	set_mode(current_mode)

func set_mode(mode: Mode) -> void:  # Use Mode
	current_mode = mode
	match mode:
		Mode.PLATFORMER:  # Use Mode
			gravity_enabled = true
			print("Switched to PLATFORMER mode")
		Mode.TOP_DOWN:  # Use Mode
			gravity_enabled = false
			print("Switched to TOP_DOWN mode")

func apply_gravity(actor: CharacterBody2D, delta: float) -> void:
	if gravity_enabled and actor and not actor.is_on_floor():
		actor.velocity.y += gravity_strength * delta

func reset_vertical_velocity(actor: CharacterBody2D) -> void:
	if not gravity_enabled and actor:
		actor.velocity.y = 0

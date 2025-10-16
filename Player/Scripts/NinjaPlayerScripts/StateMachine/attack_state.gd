extends PlayerStateNinja

@export var attack_data: AttackData
@export var combat_component: CombatComponent

var attack_finished: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2

func enter() -> void:
	attack_finished = false
	is_dashing = false
	
	if combat_component and attack_data:
		combat_component.start_attack(attack_data)
		combat_component.attack_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
	
	if animated_sprite and attack_data:
		animated_sprite.play(attack_data.animation_name)
		if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
			animated_sprite.animation_finished.connect(_on_attack_animation_finished)
	
	# Setup dash if it's a dash attack
	if attack_data.movement_type == AttackData.MovementType.DASH:
		is_dashing = true
		dash_timer = 0.0
		# Dash in the direction player is facing
		dash_direction = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT

func exit() -> void:
	if combat_component:
		combat_component.end_attack()
		if combat_component.attack_finished.is_connected(_on_attack_finished):
			combat_component.attack_finished.disconnect(_on_attack_finished)
	
	if animated_sprite and animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)

func update(delta: float) -> void:
	# Handle dash timing
	if is_dashing and attack_data:
		dash_timer += delta
		if dash_timer >= attack_data.dash_duration:
			is_dashing = false

func check_transitions() -> void:
	if attack_finished:
		# Check for combo input
		if attack_data.can_combo and handle_attack_input():
			if attack_data.next_attack:
				# Transition to next attack in combo
				transitioned.emit("ComboAttackState")  # Or swap attack_data
				return
		
		if input_direction.length() > 0:
			transitioned.emit("WalkState")
		else:
			transitioned.emit("IdleState")

func physics_update(delta: float) -> void:
	# Handle movement based on attack's movement type
	match attack_data.movement_type:
		AttackData.MovementType.LOCKED:
			actor.velocity = Vector2.ZERO
		
		AttackData.MovementType.SLOW:
			actor.velocity.x = input_direction.x * 200.0 * attack_data.movement_speed_multiplier
		
		AttackData.MovementType.DASH:
			if is_dashing:
				var dash_speed = attack_data.dash_distance / attack_data.dash_duration
				actor.velocity.x = dash_direction.x * dash_speed
			else:
				actor.velocity.x = 0
		
		AttackData.MovementType.NORMAL:
			actor.velocity.x = input_direction.x * 200.0
	
	# Apply gravity if not on floor (for platformers)
	if not actor.is_on_floor():
		actor.velocity.y += 980.0 * delta
	
	actor.move_and_slide()

func _on_attack_animation_finished() -> void:
	attack_finished = true
	check_transitions()

func _on_attack_finished() -> void:
	# Called by combat component
	pass

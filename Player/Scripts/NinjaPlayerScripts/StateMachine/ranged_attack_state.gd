extends PlayerStateNinja

@export var attack_data: AttackData
@export var combat_component: CombatComponent
@export var combo_component: ComboComponent

var attack_finished: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func enter() -> void:
	if not attack_data or not combat_component:
		transitioned.emit("IdleState")
		return
	
	attack_finished = false
	is_dashing = false
	dash_timer = 0.0
	
	# Start combo tracking if component exists
	if combo_component:
		combo_component.start_combo(attack_data)
	
	# Setup dash
	if attack_data.movement_type == AttackData.MovementType.DASH:
		is_dashing = true
		dash_direction = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
		if GameMode.current_mode == GameMode.Mode.TOP_DOWN and input_direction.length() > 0:
			dash_direction = input_direction.normalized()
	
	# Play animation and spawn projectile
	if animated_sprite:
		animated_sprite.play(attack_data.animation_name)
		if not animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
			animated_sprite.animation_finished.connect(_on_attack_animation_finished)
	
	combat_component.start_attack(attack_data)

func exit() -> void:
	if combat_component:
		combat_component.end_attack()
	
	if animated_sprite and animated_sprite.animation_finished.is_connected(_on_attack_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_animation_finished)

func update(delta: float) -> void:
	# Handle dash timing
	if is_dashing and attack_data and attack_data.dash_duration > 0:
		dash_timer += delta
		if dash_timer >= attack_data.dash_duration:
			is_dashing = false
	
	# Check for combo input (ComboComponent handles timing)
	if combo_component and attack_finished:
		var next_attack = combo_component.check_combo_input(handle_ranged_attack_input(), delta)
		if next_attack:
			# Continue combo with next attack
			attack_data = next_attack
			exit()
			enter()

func check_transitions() -> void:
	if attack_finished:
		# Don't transition if in combo window
		if combo_component and combo_component.is_in_combo():
			return
		
		# Normal transitions
		if input_direction.length() > 0:
			transitioned.emit("WalkState")
		else:
			transitioned.emit("IdleState")

func physics_update(delta: float) -> void:
	if not attack_data:
		return
	
	apply_gravity(delta)
	
	match attack_data.movement_type:
		AttackData.MovementType.LOCKED:
			actor.velocity.x = 0
			if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
				actor.velocity.y = 0
		
		AttackData.MovementType.SLOW:
			actor.velocity.x = input_direction.x * attack_data.movement_speed_multiplier * 200.0
			if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
				actor.velocity.y = input_direction.y * attack_data.movement_speed_multiplier * 200.0
		
		AttackData.MovementType.DASH:
			if is_dashing and attack_data.dash_duration > 0:
				var dash_speed = attack_data.dash_distance / attack_data.dash_duration
				actor.velocity.x = dash_direction.x * dash_speed
				if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
					actor.velocity.y = dash_direction.y * dash_speed
			else:
				actor.velocity.x = 0
				if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
					actor.velocity.y = 0
		
		AttackData.MovementType.NORMAL:
			actor.velocity.x = input_direction.x * 200.0
			if GameMode.current_mode == GameMode.Mode.TOP_DOWN:
				actor.velocity.y = input_direction.y * 200.0
	
	actor.move_and_slide()

func _on_attack_animation_finished() -> void:
	attack_finished = true
	
	# Notify combo component
	if combo_component:
		combo_component.attack_finished()
	
	check_transitions()

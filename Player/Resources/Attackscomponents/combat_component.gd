extends Node
class_name CombatComponent

signal attack_started(attack: AttackData)
signal attack_hit(target, damage)
signal attack_finished()

@export var attack_hitbox: Area2D
@export var actor: Node2D  # Reference to the character
@export var projectile_spawn_point: Marker2D  # Optional spawn point for projectiles

var current_attack: AttackData
var hit_targets: Array = []
var is_charging: bool = false
var charge_timer: float = 0.0

func _ready() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.area_entered.connect(_on_area_entered)
		attack_hitbox.body_entered.connect(_on_body_entered)

func start_attack(attack: AttackData) -> void:
	current_attack = attack
	hit_targets.clear()
	
	# Handle charge attacks
	if attack.charge_time > 0:
		is_charging = true
		charge_timer = 0.0
		return
	
	_execute_attack()

func _process(delta: float) -> void:
	if is_charging and current_attack:
		charge_timer += delta
		if charge_timer >= current_attack.charge_time:
			is_charging = false
			_execute_attack()

func _execute_attack() -> void:
	if not current_attack:
		return
	
	print("Executing attack: ", current_attack.attack_name if current_attack.attack_name else "unnamed")
	print("Is ranged: ", current_attack.is_ranged)
	print("Attack type: ", current_attack.attack_type)
	
	attack_started.emit(current_attack)
	
	# Prioritize is_ranged flag
	if current_attack.is_ranged or current_attack.attack_type == AttackData.AttackType.RANGED:
		_handle_ranged_attack()
		return
	
	match current_attack.attack_type:
		AttackData.AttackType.AOE:
			_handle_aoe_attack()
		_:
			_handle_melee_attack()

func _handle_melee_attack() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = true

func _handle_ranged_attack() -> void:
	print("=== _handle_ranged_attack called ===")
	
	if not current_attack.projectile_scene:
		push_error("No projectile scene assigned!")
		return
	
	if not actor:
		push_error("No actor assigned!")
		return
	
	print("Spawning projectile...")
	
	# Spawn projectile
	var projectile = current_attack.projectile_scene.instantiate()
	
	# Get spawn position
	var spawn_pos = actor.global_position
	var facing = 1
	
	# Get the AnimatedSprite2D node to determine facing
	var animated_sprite_node = actor.get_node_or_null("AnimatedSprite2D")
	if animated_sprite_node:
		facing = -1 if animated_sprite_node.flip_h else 1
	
	if projectile_spawn_point:
		spawn_pos = projectile_spawn_point.global_position
	else:
		spawn_pos += Vector2(current_attack.spawn_offset.x * facing, current_attack.spawn_offset.y)
	
	projectile.global_position = spawn_pos
	print("Projectile spawn position: ", spawn_pos)
	
	# Set direction
	var direction = Vector2.RIGHT * facing
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
		print("Direction set: ", direction)
	
	# Set speed
	if current_attack.projectile_speed > 0 and projectile.has_method("set_speed"):
		projectile.set_speed(current_attack.projectile_speed)
		print("Speed set: ", current_attack.projectile_speed)
	
	# Add to scene
	actor.get_parent().add_child(projectile)
	print("Projectile added to scene!")
	
	# Set lifetime
	if current_attack.projectile_lifetime > 0:
		await get_tree().create_timer(current_attack.projectile_lifetime).timeout
		if is_instance_valid(projectile):
			projectile.queue_free()

func _handle_aoe_attack() -> void:
	if not actor:
		return
	
	# Get all potential targets in range
	var space_state = actor.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = current_attack.aoe_radius
	query.shape = circle
	query.transform = Transform2D(0, actor.global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider != actor:  # Don't hit self
			_deal_damage_to(collider, current_attack.damage)

func end_attack() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = false
	hit_targets.clear()
	is_charging = false
	attack_finished.emit()

func _on_area_entered(area: Area2D) -> void:
	if not current_attack or area in hit_targets:
		return
	
	hit_targets.append(area)
	_deal_damage_to(area, current_attack.damage)

func _on_body_entered(body: Node2D) -> void:
	if not current_attack or body in hit_targets or body == actor:
		return
	
	hit_targets.append(body)
	_deal_damage_to(body, current_attack.damage)

func _deal_damage_to(target: Node, damage: int) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(damage)
	
	attack_hit.emit(target, damage)
	
	# Apply screen shake if needed
	if current_attack.screen_shake_intensity > 0:
		_apply_screen_shake()
	
	# Apply hit freeze
	if current_attack.hit_freeze_duration > 0:
		_apply_hit_freeze()

func _apply_screen_shake() -> void:
	# Emit signal for camera controller to handle
	pass

func _apply_hit_freeze() -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(current_attack.hit_freeze_duration, true, false, true).timeout
	Engine.time_scale = 1.0

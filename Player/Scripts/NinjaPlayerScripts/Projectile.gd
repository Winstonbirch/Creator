extends Area2D
class_name ProjectileBase

@export var projectile_data: ProjectileData

# Runtime variables
var direction: Vector2 = Vector2.RIGHT
var current_speed: float
var hits_remaining: int
var bounces_remaining: int
var lifetime_timer: float = 0.0
var homing_target: Node2D = null

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not projectile_data:
		push_error("Projectile has no ProjectileData assigned!")
		queue_free()
		return
	
	# Initialize from data
	current_speed = projectile_data.speed
	hits_remaining = projectile_data.pierce_count
	bounces_remaining = projectile_data.bounces
	
	# Apply visuals
	_apply_visuals()
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Find homing target if needed
	if projectile_data.homing:
		_find_homing_target()
	
	# Spawn trail if needed
	if projectile_data.spawn_trail and projectile_data.trail_scene:
		_spawn_trail()

func _apply_visuals() -> void:
	print("=== Projectile _apply_visuals START ===")
	
	print("Step 1: Checking animated_sprite...")
	if not animated_sprite:
		push_error("Projectile missing AnimatedSprite2D node!")
		return
	print("✓ AnimatedSprite2D exists")
	
	print("Step 2: Checking projectile_data...")
	if not projectile_data:
		push_error("No projectile_data assigned!")
		return
	print("✓ ProjectileData exists")
	
	print("Step 3: Animation name = '", projectile_data.animation_name, "'")
	
	# Play animation
	if projectile_data.animation_name != "":
		print("Step 4: Checking sprite_frames...")
		if animated_sprite.sprite_frames:
			print("✓ SpriteFrames assigned")
			print("Available animations: ", animated_sprite.sprite_frames.get_animation_names())
			
			if animated_sprite.sprite_frames.has_animation(projectile_data.animation_name):
				print("Step 5: Playing animation...")
				animated_sprite.play(projectile_data.animation_name)
				print("✓ Animation playing: ", projectile_data.animation_name)
			else:
				push_error("Animation '", projectile_data.animation_name, "' not found!")
		else:
			push_error("AnimatedSprite2D has no SpriteFrames assigned!")
	else:
		push_error("ProjectileData has no animation_name set!")
	
	print("Step 6: Applying scale, color, rotation...")
	scale = projectile_data.scale
	modulate = projectile_data.modulate_color
	if projectile_data.rotation_speed == 0:
		rotation = direction.angle()
	
	print("=== Projectile _apply_visuals COMPLETE ===")

func _physics_process(delta: float) -> void:
	# Update lifetime
	lifetime_timer += delta
	if lifetime_timer >= projectile_data.lifetime:
		_despawn()
		return
	
	# Homing behavior
	if projectile_data.homing and is_instance_valid(homing_target):
		var target_direction = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, projectile_data.homing_strength * delta / current_speed).normalized()
		if projectile_data.rotation_speed == 0:
			rotation = direction.angle()
	
	# Apply gravity
	if projectile_data.gravity_affected:
		direction.y += (projectile_data.gravity_strength / current_speed) * delta
		direction = direction.normalized()
		if projectile_data.rotation_speed == 0:
			rotation = direction.angle()
	
	# Rotation
	if projectile_data.rotation_speed != 0:
		rotation_degrees += projectile_data.rotation_speed * delta
	
	# Projectile Movement
	position += direction * current_speed * delta

func _on_area_entered(area: Area2D) -> void:
	_hit_target(area)

func _on_body_entered(body: Node2D) -> void:
	# Check if it's a wall (for bouncing)
	if body is TileMap or body.is_in_group("walls"):
		if bounces_remaining > 0:
			_bounce(body)
			return
	
	_hit_target(body)

func _hit_target(target: Node) -> void:
	# Don't hit the shooter
	if target == get_parent():
		return
	
	# Spawn hit effect
	if projectile_data.spawn_on_hit_effect and projectile_data.hit_effect_scene:
		var effect = projectile_data.hit_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	
	# Handle explosion
	if projectile_data.explodes_on_impact:
		_explode()
		return
	
	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(projectile_data.damage)
	elif target.get_parent() and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(projectile_data.damage)
	
	# Apply knockback
	if projectile_data.knockback_force > 0 and target.has_method("apply_knockback"):
		target.apply_knockback(direction * projectile_data.knockback_force)
	
	# Handle pierce
	if projectile_data.pierce_count > 0:
		hits_remaining -= 1
		if hits_remaining <= 0:
			_despawn()

func _bounce(wall: Node2D) -> void:
	direction.x *= -1
	bounces_remaining -= 1
	if projectile_data.rotation_speed == 0:
		rotation = direction.angle()

func _explode() -> void:
	# Get all entities in explosion radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = projectile_data.explosion_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var target = result.collider
		if target != self and target.has_method("take_damage"):
			target.take_damage(projectile_data.explosion_damage)
		elif target.get_parent() and target.get_parent().has_method("take_damage"):
			target.get_parent().take_damage(projectile_data.explosion_damage)
	
	_despawn()

func _despawn() -> void:
	# Spawn death effect
	if projectile_data.spawn_on_death_effect and projectile_data.death_effect_scene:
		var effect = projectile_data.death_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	
	queue_free()

func _find_homing_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_distance = projectile_data.homing_detection_radius
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				homing_target = enemy

func _spawn_trail() -> void:
	var trail = projectile_data.trail_scene.instantiate()
	add_child(trail)

# Public methods for CombatComponent
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	if projectile_data and projectile_data.rotation_speed == 0:
		rotation = direction.angle()

func set_damage(value: int) -> void:
	if projectile_data:
		projectile_data = projectile_data.duplicate()
		projectile_data.damage = value

func set_speed(value: float) -> void:
	if projectile_data:
		projectile_data = projectile_data.duplicate()
		projectile_data.speed = value
		current_speed = value

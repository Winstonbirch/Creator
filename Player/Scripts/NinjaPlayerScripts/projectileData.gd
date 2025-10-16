extends Resource
class_name ProjectileData

# Basic Info
@export var projectile_name: String = "Basic Projectile"

# Visuals (simplified for AnimatedSprite2D only)
@export_group("Visuals")
@export var animation_name: String = "default"
@export var scale: Vector2 = Vector2.ONE
@export var modulate_color: Color = Color.WHITE

# Physics & Movement
@export_group("Physics")
@export var speed: float = 500.0
@export var lifetime: float = 2.0
@export var gravity_affected: bool = false
@export var gravity_strength: float = 980.0
@export var rotation_speed: float = 0.0

# Combat
@export_group("Combat")
@export var damage: int = 10
@export var pierce_count: int = 1
@export var knockback_force: float = 200.0

# Special Behaviors
@export_group("Special")
@export var homing: bool = false
@export var homing_strength: float = 200.0
@export var homing_detection_radius: float = 300.0
@export var bounces: int = 0
@export var explodes_on_impact: bool = false
@export var explosion_radius: float = 50.0
@export var explosion_damage: int = 15

# Effects
@export_group("Effects")
@export var spawn_trail: bool = false
@export var trail_scene: PackedScene
@export var spawn_on_hit_effect: bool = false
@export var hit_effect_scene: PackedScene
@export var spawn_on_death_effect: bool = false
@export var death_effect_scene: PackedScene

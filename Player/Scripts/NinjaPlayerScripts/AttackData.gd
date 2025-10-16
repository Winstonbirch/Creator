extends Resource
class_name AttackData

enum AttackType { MELEE, RANGED, CHARGE, AOE }
enum MovementType { LOCKED, SLOW, DASH, NORMAL }

# Basic Info
@export var attack_name: String = "Basic Attack"
@export var attack_type: AttackType = AttackType.MELEE
@export var animation_name: String = "SlashAttack"

# Damage
@export var damage: int = 10
@export var knockback_force: float = 200.0

# Timing
@export var charge_time: float = 0.0  # How long to hold before attack
@export var startup_frames: int = 2  # Frames before hitbox activates
@export var active_frames: int = 3   # Frames hitbox stays active
@export var recovery_frames: int = 5  # Frames of cooldown after

# Movement During Attack
@export var movement_type: MovementType = MovementType.LOCKED
@export var movement_speed_multiplier: float = 0.0  # 0 = locked, 0.5 = half speed, 1.0 = full speed
@export var dash_distance: float = 0.0  # For dash attacks
@export var dash_duration: float = 0.0

# Ranged Projectile Settings
@export_group("Ranged Settings")
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene  # Drag your projectile scene here
@export var projectile_speed: float = 500.0
@export var projectile_lifetime: float = 2.0
@export var spawn_offset: Vector2 = Vector2(30, 0)  # Where projectile spawns relative to player

# AOE Settings
@export_group("AOE Settings")
@export var is_aoe: bool = false
@export var aoe_radius: float = 100.0
@export var aoe_duration: float = 0.5

# Combo Settings
@export_group("Combo Settings")
@export var can_combo: bool = false
@export var combo_window: float = 0.3  # Time window to input next attack
@export var next_attack: AttackData  # Link to next attack in combo chain

# Special Effects
@export_group("Effects")
@export var screen_shake_intensity: float = 0.0
@export var hit_freeze_duration: float = 0.0  # Frame freeze on hit
@export var spawn_particles: bool = false
@export var particle_scene: PackedScene

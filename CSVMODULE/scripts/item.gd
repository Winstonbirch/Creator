# ===========================
# Item.gd - Item Resource Class
# ===========================
class_name Item
extends Resource

# ===========================
# ITEM PROPERTIES (Using Godot's Export System)
# ===========================
@export_group("Basic Info")
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"

@export_group("Gameplay")
@export var item_type: String = ""
@export var max_stack: int = 1
@export var value: int = 0
@export var weight: float = 0.0

@export_group("Stats")
@export var damage: int = 0
@export var defense: int = 0
@export var durability: int = 0
@export var max_durability: int = 0

@export_group("Crafting")
@export var craftable: bool = false
@export var crafting_requirements: Array[String] = []
@export var crafting_result_count: int = 1

@export_group("Usage")
@export var consumable: bool = false
@export var use_effect: String = ""
@export var cooldown: float = 0.0

# ===========================
# INITIALIZATION (Using CSV Data)
# ===========================
func _init(data: Dictionary = {}):
	"""Initialize item from CSV data dictionary"""
	if not data.is_empty():
		load_from_data(data)

func load_from_data(data: Dictionary):
	"""Load item properties from dictionary (typically from CSV)"""
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	rarity = data.get("rarity", "common")
	item_type = data.get("type", "")
	max_stack = data.get("max_stack", 1)
	value = data.get("value", 0)
	weight = data.get("weight", 0.0)
	damage = data.get("damage", 0)
	defense = data.get("defense", 0)
	durability = data.get("durability", 0)
	max_durability = data.get("max_durability", 0)
	craftable = data.get("craftable", false)
	consumable = data.get("consumable", false)
	use_effect = data.get("use_effect", "")
	cooldown = data.get("cooldown", 0.0)
	crafting_result_count = data.get("crafting_result_count", 1)
	
	# Handle array data (crafting requirements)
	if data.has("crafting_requirements"):
		var req_data = data["crafting_requirements"]
		if req_data is Array:
			crafting_requirements = req_data
		elif req_data is String and req_data != "":
			crafting_requirements = req_data.split(",")
	
	# Load icon if path is provided
	var icon_path = data.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon = load(icon_path)

# ===========================
# ITEM FUNCTIONALITY (Using Godot's Built-in Systems)
# ===========================
func can_stack_with(other_item: Item) -> bool:
	"""Check if this item can stack with another item"""
	return other_item != null and other_item.id == id and max_stack > 1

func get_display_name() -> String:
	"""Get formatted display name with rarity"""
	match rarity.to_lower():
		"legendary":
			return "[color=orange]%s[/color]" % name
		"epic":
			return "[color=purple]%s[/color]" % name
		"rare":
			return "[color=blue]%s[/color]" % name
		"uncommon":
			return "[color=green]%s[/color]" % name
		_:
			return name

func get_tooltip_text() -> String:
	"""Generate tooltip text for UI"""
	var tooltip = "[b]%s[/b]\n" % get_display_name()
	tooltip += description + "\n\n"
	
	if damage > 0:
		tooltip += "Damage: %d\n" % damage
	if defense > 0:
		tooltip += "Defense: %d\n" % defense
	if durability > 0:
		tooltip += "Durability: %d/%d\n" % [durability, max_durability]
	
	tooltip += "Value: %d gold\n" % value
	tooltip += "Weight: %.1f kg" % weight
	
	return tooltip

func is_damaged() -> bool:
	"""Check if item is damaged"""
	return max_durability > 0 and durability < max_durability

func repair(amount: int = -1):
	"""Repair item (amount = -1 means full repair)"""
	if max_durability > 0:
		if amount == -1:
			durability = max_durability
		else:
			durability = min(max_durability, durability + amount)

func damage_item(amount: int):
	"""Damage the item"""
	if max_durability > 0:
		durability = max(0, durability - amount)

func is_broken() -> bool:
	"""Check if item is broken"""
	return max_durability > 0 and durability <= 0

# ===========================
# SERIALIZATION (Using Godot's Resource System)
# ===========================
func to_save_data() -> Dictionary:
	"""Convert item to save data dictionary"""
	return {
		"id": id,
		"durability": durability,
		"custom_data": {}  # For any instance-specific data
	}

func from_save_data(save_data: Dictionary, item_database: ItemDatabase):
	"""Load item from save data"""
	var base_item = item_database.get_item(save_data.get("id", ""))
	if base_item:
		# Copy base properties
		load_from_data(base_item.to_save_data())
		# Apply saved instance data
		durability = save_data.get("durability", durability)

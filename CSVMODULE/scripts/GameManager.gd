# ===========================
# GameManager.gd - Example Usage of CSV Data System
# ===========================
class_name GameManager
extends Node

# ===========================
# AUTOLOAD SINGLETON (Using Godot's Autoload System)
# ===========================

# Database and systems
var item_database: ItemDatabase
var player_inventory: Inventory
var crafting_system: CraftingSystem

# ===========================
# INITIALIZATION (Using Godot's Ready System)
# ===========================
func _ready():
	print("GameManager: Initializing game systems...")
	_initialize_database()
	_initialize_systems()
	_setup_test_scenario()

func _initialize_database():
	"""Initialize the item database from CSV files"""
	item_database = ItemDatabase.new()
	
	# Connect to database signals
	item_database.database_loaded.connect(_on_database_loaded)
	item_database.database_load_failed.connect(_on_database_load_failed)
	
	# Set CSV file paths (these should be in your project)
	item_database.items_csv_path = "res://data/items.csv"
	item_database.recipes_csv_path = "res://data/recipes.csv"
	item_database.loot_tables_csv_path = "res://data/loot_tables.csv"
	
	# Load the database
	if not item_database.load_database():
		push_error("GameManager: Failed to load item database!")

func _initialize_systems():
	"""Initialize game systems that depend on the database"""
	if not item_database or not item_database.is_database_loaded():
		push_error("GameManager: Cannot initialize systems without loaded database")
		return
	
	# Create player inventory
	player_inventory = Inventory.new(item_database, 30)
	
	# Connect to inventory signals
	player_inventory.item_added.connect(_on_item_added)
	player_inventory.item_removed.connect(_on_item_removed)
	player_inventory.inventory_full.connect(_on_inventory_full)
	
	# Create crafting system
	crafting_system = CraftingSystem.new(item_database, player_inventory)

# ===========================
# SIGNAL HANDLERS
# ===========================
func _on_database_loaded():
	"""Called when database is successfully loaded"""
	print("GameManager: Database loaded successfully!")
	print("Database stats: ", item_database.get_database_stats())
	
	# Validate database integrity
	var validation_issues = item_database.validate_database()
	if validation_issues.size() > 0:
		print("GameManager: Database validation issues found:")
		for issue in validation_issues:
			print("  - " + issue)

func _on_database_load_failed(error_message: String):
	"""Called when database loading fails"""
	push_error("GameManager: Database loading failed: " + error_message)

func _on_item_added(item: Item, quantity: int, slot_index: int):
	"""Called when item is added to inventory"""
	print("Added %d x %s to slot %d" % [quantity, item.name, slot_index])

func _on_item_removed(item: Item, quantity: int, slot_index: int):
	"""Called when item is removed from inventory"""
	if item:
		print("Removed %d x %s from slot %d" % [quantity, item.name, slot_index])

func _on_inventory_full():
	"""Called when inventory is full"""
	print("Inventory is full!")

# ===========================
# TEST SCENARIO (Demonstrates System Usage)
# ===========================
func _setup_test_scenario():
	"""Set up a test scenario to demonstrate the system"""
	if not item_database.is_database_loaded():
		return
	
	print("\n=== Running Test Scenario ===")
	
	# Test 1: Add some basic items to inventory
	_test_basic_inventory()
	
	# Test 2: Test item queries
	_test_item_queries()
	
	# Test 3: Test crafting system
	_test_crafting_system()
	
	# Test 4: Test loot generation
	_test_loot_generation()
	
	print("=== Test Scenario Complete ===\n")

func _test_basic_inventory():
	"""Test basic inventory operations"""
	print("\n--- Testing Basic Inventory ---")
	
	# Add some items
	var iron_sword = item_database.get_item("sword_iron")
	var health_potion = item_database.get_item("potion_health")
	var wood_plank = item_database.get_item("wood_plank")
	
	if iron_sword:
		player_inventory.add_item(iron_sword, 1)
	if health_potion:
		player_inventory.add_item(health_potion, 5)
	if wood_plank:
		player_inventory.add_item(wood_plank, 20)
	
	# Print inventory stats
	print("Inventory stats: ", player_inventory.get_inventory_stats())

func _test_item_queries():
	"""Test database query functions"""
	print("\n--- Testing Item Queries ---")
	
	# Search for items
	var weapon_items = item_database.get_items_by_type("weapon")
	print("Found %d weapons" % weapon_items.size())
	
	var rare_items = item_database.get_items_by_rarity("rare")
	print("Found %d rare items" % rare_items.size())
	
	var search_results = item_database.search_items("sword")
	print("Search for 'sword' found %d items" % search_results.size())
	
	# Check inventory contents
	print("Player has %d health potions" % player_inventory.get_item_count("potion_health"))
	print("Player has iron sword: %s" % player_inventory.has_item("sword_iron"))

func _test_crafting_system():
	"""Test crafting functionality"""
	print("\n--- Testing Crafting System ---")
	
	# Add crafting materials
	var iron_ingot = item_database.get_item("ingot_iron")
	if iron_ingot:
		player_inventory.add_item(iron_ingot, 5)
	
	# Get recipe for iron sword
	var recipe = item_database.get_recipe("sword_iron")
	if not recipe.is_empty():
		print("Iron sword recipe found: ", recipe)
		
		# Check if we can craft it
		var available_items = {}
		for item_data in player_inventory.get_all_items():
			available_items[item_data.item.id] = item_data.quantity
		
		var can_craft = item_database.can_craft("recipe_iron_sword", available_items)
		print("Can craft iron sword: %s" % can_craft)

func _test_loot_generation():
	"""Test loot table system"""
	print("\n--- Testing Loot Generation ---")
	
	# Generate loot from goblin
	var goblin_loot = item_database.generate_loot("goblin_common")
	print("Generated %d items from goblin loot table:" % goblin_loot.size())
	for item in goblin_loot:
		print("  - %s" % item.name)
	
	# Generate loot from chest
	var chest_loot = item_database.generate_loot("chest_wooden")
	print("Generated %d items from wooden chest:" % chest_loot.size())
	for item in chest_loot:
		print("  - %s" % item.name)

# ===========================
# PUBLIC API (For Game Usage)
# ===========================
func get_item_database() -> ItemDatabase:
	"""Get the item database instance"""
	return item_database

func get_player_inventory() -> Inventory:
	"""Get the player inventory instance"""
	return player_inventory

func create_item(item_id: String) -> Item:
	"""Create a new item instance"""
	if not item_database:
		return null
	return item_database.get_item(item_id)

func give_item_to_player(item_id: String, quantity: int = 1) -> bool:
	"""Give item to player inventory"""
	var item = create_item(item_id)
	if not item:
		return false
	
	var added = player_inventory.add_item(item, quantity)
	return added == quantity

func save_game_data() -> Dictionary:
	"""Save all game data"""
	return {
		"player_inventory": player_inventory.save_to_data(),
		"version": "1.0"
	}

func load_game_data(save_data: Dictionary) -> bool:
	"""Load game data from save"""
	if not item_database.is_database_loaded():
		push_error("GameManager: Cannot load game data without loaded database")
		return false
	
	if save_data.has("player_inventory"):
		return player_inventory.load_from_data(save_data.player_inventory)
	
	return false

# ===========================
# DEBUG COMMANDS (For Development)
# ===========================
func debug_give_item(item_id: String, quantity: int = 1):
	"""Debug command to give items"""
	give_item_to_player(item_id, quantity)

func debug_print_inventory():
	"""Debug command to print inventory"""
	player_inventory.print_inventory()

func debug_clear_inventory():
	"""Debug command to clear inventory"""
	player_inventory.clear_inventory()

func debug_reload_database():
	"""Debug command to reload database"""
	item_database.reload_database()

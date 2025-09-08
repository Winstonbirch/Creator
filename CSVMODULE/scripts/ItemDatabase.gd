# ===========================
# ItemDatabase.gd - Item Database Manager
# ===========================
class_name ItemDatabase
extends Resource

# ===========================
# SIGNALS (Using Godot's Signal System)
# ===========================
signal database_loaded
signal database_load_failed(error_message: String)

# ===========================
# DATABASE CONFIGURATION
# ===========================
@export_group("Database Files")
@export var items_csv_path: String = "res://data/items.csv"
@export var recipes_csv_path: String = "res://data/recipes.csv"
@export var loot_tables_csv_path: String = "res://data/loot_tables.csv"

@export_group("Settings")
@export var auto_load_on_ready: bool = true
@export var cache_items: bool = true

# ===========================
# INTERNAL DATA
# ===========================
var _items: Dictionary = {}  # id -> Item
var _recipes: Array[Dictionary] = []
var _loot_tables: Dictionary = {}
var _items_by_type: Dictionary = {}
var _is_loaded: bool = false

# ===========================
# INITIALIZATION (Using Godot's Resource System)
# ===========================
func _init():
	if auto_load_on_ready:
		load_database()

# ===========================
# DATABASE LOADING (Using CSVDataManager)
# ===========================
func load_database() -> bool:
	"""Load all database files"""
	var success = true
	
	# Load items
	if not _load_items():
		success = false
	
	# Load recipes
	if not _load_recipes():
		success = false
	
	# Load loot tables
	if not _load_loot_tables():
		success = false
	
	if success:
		_is_loaded = true
		_build_type_indices()
		database_loaded.emit()
		print("ItemDatabase: Successfully loaded database")
	else:
		database_load_failed.emit("Failed to load one or more database files")
		print("ItemDatabase: Failed to load database")
	
	return success

func _load_items() -> bool:
	"""Load items from CSV"""
	if not FileAccess.file_exists(items_csv_path):
		push_error("ItemDatabase: Items CSV file not found: " + items_csv_path)
		return false
	
	var items_data = CSVDataManager.load_csv_data(items_csv_path, "items")
	if items_data.is_empty():
		push_error("ItemDatabase: No items loaded from CSV")
		return false
	
	_items.clear()
	for item_data in items_data:
		var item = Item.new(item_data)
		if item.id != "":
			_items[item.id] = item
		else:
			push_warning("ItemDatabase: Item without ID found in CSV, skipping")
	
	print("ItemDatabase: Loaded %d items" % _items.size())
	return true

func _load_recipes() -> bool:
	"""Load crafting recipes from CSV"""
	if not FileAccess.file_exists(recipes_csv_path):
		push_warning("ItemDatabase: Recipes CSV file not found: " + recipes_csv_path)
		return true  # Optional file
	
	_recipes = CSVDataManager.load_csv_data(recipes_csv_path, "recipes")
	print("ItemDatabase: Loaded %d recipes" % _recipes.size())
	return true

func _load_loot_tables() -> bool:
	"""Load loot tables from CSV"""
	if not FileAccess.file_exists(loot_tables_csv_path):
		push_warning("ItemDatabase: Loot tables CSV file not found: " + loot_tables_csv_path)
		return true  # Optional file
	
	var loot_data = CSVDataManager.load_csv_data(loot_tables_csv_path, "loot_tables")
	_loot_tables.clear()
	
	for loot_entry in loot_data:
		var table_id = loot_entry.get("table_id", "")
		if table_id == "":
			continue
		
		if not _loot_tables.has(table_id):
			_loot_tables[table_id] = []
		
		_loot_tables[table_id].append(loot_entry)
	
	print("ItemDatabase: Loaded %d loot tables" % _loot_tables.size())
	return true

func _build_type_indices():
	"""Build indices for faster queries"""
	_items_by_type.clear()
	
	for item in _items.values():
		var item_type = item.item_type
		if item_type != "":
			if not _items_by_type.has(item_type):
				_items_by_type[item_type] = []
			_items_by_type[item_type].append(item)

# ===========================
# ITEM QUERIES (Using Godot's Built-in Collections)
# ===========================
func get_item(item_id: String) -> Item:
	"""Get item by ID"""
	return _items.get(item_id, null)

func get_items_by_type(item_type: String) -> Array[Item]:
	"""Get all items of a specific type"""
	return _items_by_type.get(item_type, [])

func get_items_by_rarity(rarity: String) -> Array[Item]:
	"""Get all items of a specific rarity"""
	var items: Array[Item] = []
	for item in _items.values():
		if item.rarity.to_lower() == rarity.to_lower():
			items.append(item)
	return items

func search_items(query: String) -> Array[Item]:
	"""Search items by name or description"""
	var results: Array[Item] = []
	var search_term = query.to_lower()
	
	for item in _items.values():
		if item.name.to_lower().contains(search_term) or item.description.to_lower().contains(search_term):
			results.append(item)
	
	return results

func get_craftable_items() -> Array[Item]:
	"""Get all craftable items"""
	var craftable: Array[Item] = []
	for item in _items.values():
		if item.craftable:
			craftable.append(item)
	return craftable

func get_all_items() -> Array[Item]:
	"""Get all items as array"""
	var items: Array[Item] = []
	for item in _items.values():
		items.append(item)
	return items

# ===========================
# CRAFTING SYSTEM (Using CSV Recipe Data)
# ===========================
func get_recipe(item_id: String) -> Dictionary:
	"""Get crafting recipe for an item"""
	for recipe in _recipes:
		if recipe.get("result_item_id") == item_id:
			return recipe
	return {}

func get_recipes_using_ingredient(ingredient_id: String) -> Array[Dictionary]:
	"""Get all recipes that use a specific ingredient"""
	var matching_recipes: Array[Dictionary] = []
	
	for recipe in _recipes:
		var ingredients = recipe.get("ingredients", "")
		if ingredients is String:
			ingredients = ingredients.split(",")
		
		if ingredient_id in ingredients:
			matching_recipes.append(recipe)
	
	return matching_recipes

func can_craft(recipe_id: String, available_items: Dictionary) -> bool:
	"""Check if recipe can be crafted with available items"""
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return false
	
	var ingredients = recipe.get("ingredients", "")
	var quantities = recipe.get("quantities", "")
	
	if ingredients is String:
		ingredients = ingredients.split(",")
	if quantities is String:
		quantities = quantities.split(",")
	
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var required_quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var available_quantity = available_items.get(ingredient_id, 0)
		
		if available_quantity < required_quantity:
			return false
	
	return true

func _get_recipe_by_id(recipe_id: String) -> Dictionary:
	"""Get recipe by its ID"""
	for recipe in _recipes:
		if recipe.get("id") == recipe_id:
			return recipe
	return {}

# ===========================
# LOOT SYSTEM (Using CSV Loot Tables)
# ===========================
func generate_loot(table_id: String, rng: RandomNumberGenerator = null) -> Array[Item]:
	"""Generate loot from a loot table"""
	if not _loot_tables.has(table_id):
		return []
	
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	var loot: Array[Item] = []
	var loot_table = _loot_tables[table_id]
	
	for entry in loot_table:
		var drop_chance = entry.get("drop_chance", 1.0)
		var item_id = entry.get("item_id", "")
		var min_quantity = entry.get("min_quantity", 1)
		var max_quantity = entry.get("max_quantity", 1)
		
		if rng.randf() <= drop_chance:
			var item = get_item(item_id)
			if item:
				var quantity = rng.randi_range(min_quantity, max_quantity)
				for i in range(quantity):
					loot.append(item)
	
	return loot

# ===========================
# DATABASE MANAGEMENT
# ===========================
func reload_database() -> bool:
	"""Reload database from CSV files"""
	CSVDataManager.clear_cache()
	return load_database()

func is_database_loaded() -> bool:
	"""Check if database is loaded"""
	return _is_loaded

func get_database_stats() -> Dictionary:
	"""Get database statistics"""
	return {
		"total_items": _items.size(),
		"total_recipes": _recipes.size(),
		"total_loot_tables": _loot_tables.size(),
		"item_types": _items_by_type.keys(),
		"is_loaded": _is_loaded
	}

# ===========================
# VALIDATION AND DEBUG
# ===========================
func validate_database() -> Array[String]:
	"""Validate database integrity and return list of issues"""
	var issues: Array[String] = []
	
	# Check for duplicate item IDs
	var seen_ids = {}
	for item_id in _items.keys():
		if seen_ids.has(item_id):
			issues.append("Duplicate item ID: " + item_id)
		seen_ids[item_id] = true
	
	# Check recipe references
	for recipe in _recipes:
		var result_id = recipe.get("result_item_id", "")
		if result_id != "" and not _items.has(result_id):
			issues.append("Recipe references non-existent item: " + result_id)
	
	# Check loot table references
	for table_id in _loot_tables:
		for entry in _loot_tables[table_id]:
			var item_id = entry.get("item_id", "")
			if item_id != "" and not _items.has(item_id):
				issues.append("Loot table '%s' references non-existent item: %s" % [table_id, item_id])
	
	return issues

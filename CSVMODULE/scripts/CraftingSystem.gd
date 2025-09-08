# ===========================
# CraftingSystem.gd - Simple Crafting System
# ===========================
class_name CraftingSystem
extends RefCounted

# ===========================
# SIGNALS (Using Godot's Signal System)
# ===========================
signal item_crafted(item: Item, quantity: int)
signal crafting_failed(recipe_id: String, reason: String)

# ===========================
# SYSTEM REFERENCES
# ===========================
var item_database: ItemDatabase
var inventory: Inventory

# ===========================
# INITIALIZATION
# ===========================
func _init(database: ItemDatabase, player_inventory: Inventory):
	item_database = database
	inventory = player_inventory

# ===========================
# CRAFTING OPERATIONS (Using CSV Recipe Data)
# ===========================
func craft_item(recipe_id: String) -> bool:
	"""Attempt to craft an item using a recipe"""
	if not item_database or not inventory:
		crafting_failed.emit(recipe_id, "System not initialized")
		return false
	
	# Get recipe
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		crafting_failed.emit(recipe_id, "Recipe not found")
		return false
	
	# Check if we have the required ingredients
	if not _has_required_ingredients(recipe):
		crafting_failed.emit(recipe_id, "Insufficient ingredients")
		return false
	
	# Consume ingredients
	if not _consume_ingredients(recipe):
		crafting_failed.emit(recipe_id, "Failed to consume ingredients")
		return false
	
	# Create result item
	var result_item_id = recipe.get("result_item_id", "")
	var result_item = item_database.get_item(result_item_id)
	if not result_item:
		crafting_failed.emit(recipe_id, "Result item not found in database")
		return false
	
	var result_quantity = recipe.get("crafting_result_count", 1)
	
	# Add result to inventory
	var added = inventory.add_item(result_item, result_quantity)
	if added < result_quantity:
		crafting_failed.emit(recipe_id, "Inventory full, could not add all items")
		return false
	
	item_crafted.emit(result_item, result_quantity)
	return true

func get_available_recipes() -> Array[Dictionary]:
	"""Get all recipes that can be crafted with current inventory"""
	var available_recipes: Array[Dictionary] = []
	var all_recipes = item_database._recipes
	
	for recipe in all_recipes:
		if _has_required_ingredients(recipe):
			available_recipes.append(recipe)
	
	return available_recipes

func get_recipe_requirements(recipe_id: String) -> Dictionary:
	"""Get detailed requirements for a recipe"""
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return {}
	
	var requirements = {
		"recipe_id": recipe_id,
		"result_item_id": recipe.get("result_item_id", ""),
		"result_quantity": recipe.get("crafting_result_count", 1),
		"crafting_time": recipe.get("crafting_time", 0.0),
		"required_tool": recipe.get("required_tool", ""),
		"skill_level": recipe.get("skill_level", 0),
		"ingredients": [],
		"can_craft": false
	}
	
	var ingredients = recipe.get("ingredients", "")
	var quantities = recipe.get("quantities", "")
	
	if ingredients is String:
		ingredients = ingredients.split(",")
	if quantities is String:
		quantities = quantities.split(",")
	
	var can_craft = true
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var required_quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var available_quantity = inventory.get_item_count(ingredient_id)
		var ingredient_item = item_database.get_item(ingredient_id)
		
		var ingredient_info = {
			"item_id": ingredient_id,
			"item_name": ingredient_item.name if ingredient_item else "Unknown",
			"required": required_quantity,
			"available": available_quantity,
			"sufficient": available_quantity >= required_quantity
		}
		
		requirements.ingredients.append(ingredient_info)
		
		if not ingredient_info.sufficient:
			can_craft = false
	
	requirements.can_craft = can_craft
	return requirements

# ===========================
# PRIVATE HELPER METHODS
# ===========================
func _get_recipe_by_id(recipe_id: String) -> Dictionary:
	"""Get recipe by its ID"""
	for recipe in item_database._recipes:
		if recipe.get("id") == recipe_id:
			return recipe
	return {}

func _has_required_ingredients(recipe: Dictionary) -> bool:
	"""Check if inventory has all required ingredients"""
	var ingredients = recipe.get("ingredients", "")
	var quantities = recipe.get("quantities", "")
	
	if ingredients is String:
		ingredients = ingredients.split(",")
	if quantities is String:
		quantities = quantities.split(",")
	
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var required_quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var available_quantity = inventory.get_item_count(ingredient_id)
		
		if available_quantity < required_quantity:
			return false
	
	return true

func _consume_ingredients(recipe: Dictionary) -> bool:
	"""Consume ingredients from inventory"""
	var ingredients = recipe.get("ingredients", "")
	var quantities = recipe.get("quantities", "")
	
	if ingredients is String:
		ingredients = ingredients.split(",")
	if quantities is String:
		quantities = quantities.split(",")
	
	# First pass: check if we can consume all ingredients
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var required_quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var available_quantity = inventory.get_item_count(ingredient_id)
		
		if available_quantity < required_quantity:
			return false
	
	# Second pass: actually consume the ingredients
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var required_quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var removed = inventory.remove_item(ingredient_id, required_quantity)
		
		if removed != required_quantity:
			push_error("CraftingSystem: Failed to remove expected quantity of " + ingredient_id)
			return false
	
	return true

# ===========================
# QUERY METHODS
# ===========================
func can_craft_recipe(recipe_id: String) -> bool:
	"""Check if a specific recipe can be crafted"""
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return false
	
	return _has_required_ingredients(recipe)

func get_recipes_for_item(item_id: String) -> Array[Dictionary]:
	"""Get all recipes that produce a specific item"""
	var recipes: Array[Dictionary] = []
	
	for recipe in item_database._recipes:
		if recipe.get("result_item_id") == item_id:
			recipes.append(recipe)
	
	return recipes

func get_recipes_using_ingredient(ingredient_id: String) -> Array[Dictionary]:
	"""Get all recipes that use a specific ingredient"""
	var recipes: Array[Dictionary] = []
	
	for recipe in item_database._recipes:
		var ingredients = recipe.get("ingredients", "")
		if ingredients is String:
			ingredients = ingredients.split(",")
		
		for ingredient in ingredients:
			if ingredient.strip_edges() == ingredient_id:
				recipes.append(recipe)
				break
	
	return recipes

# ===========================
# CRAFTING QUEUE SYSTEM (Optional Advanced Feature)
# ===========================
var crafting_queue: Array[Dictionary] = []
var current_craft: Dictionary = {}
var crafting_timer: float = 0.0

func queue_craft(recipe_id: String) -> bool:
	"""Add recipe to crafting queue"""
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return false
	
	if not _has_required_ingredients(recipe):
		return false
	
	# Reserve ingredients
	if not _consume_ingredients(recipe):
		return false
	
	var craft_job = {
		"recipe_id": recipe_id,
		"recipe": recipe,
		"start_time": Time.get_unix_time_from_system(),
		"duration": recipe.get("crafting_time", 0.0)
	}
	
	if current_craft.is_empty():
		current_craft = craft_job
		crafting_timer = craft_job.duration
	else:
		crafting_queue.append(craft_job)
	
	return true

func update_crafting(delta: float):
	"""Update crafting progress (call from _process)"""
	if current_craft.is_empty():
		return
	
	crafting_timer -= delta
	
	if crafting_timer <= 0.0:
		_complete_current_craft()
		_start_next_craft()

func _complete_current_craft():
	"""Complete the current crafting job"""
	if current_craft.is_empty():
		return
	
	var recipe = current_craft.recipe
	var result_item_id = recipe.get("result_item_id", "")
	var result_item = item_database.get_item(result_item_id)
	var result_quantity = recipe.get("crafting_result_count", 1)
	
	if result_item:
		inventory.add_item(result_item, result_quantity)
		item_crafted.emit(result_item, result_quantity)
	
	current_craft.clear()

func _start_next_craft():
	"""Start the next craft in queue"""
	if crafting_queue.is_empty():
		return
	
	current_craft = crafting_queue.pop_front()
	crafting_timer = current_craft.duration

func get_crafting_progress() -> float:
	"""Get current crafting progress (0.0 to 1.0)"""
	if current_craft.is_empty():
		return 0.0
	
	var total_time = current_craft.duration
	var elapsed_time = total_time - crafting_timer
	return elapsed_time / total_time if total_time > 0 else 1.0

func cancel_current_craft() -> bool:
	"""Cancel current crafting and refund ingredients"""
	if current_craft.is_empty():
		return false
	
	# Refund ingredients
	_refund_ingredients(current_craft.recipe)
	current_craft.clear()
	crafting_timer = 0.0
	
	# Start next craft if available
	_start_next_craft()
	return true

func _refund_ingredients(recipe: Dictionary):
	"""Refund ingredients back to inventory"""
	var ingredients = recipe.get("ingredients", "")
	var quantities = recipe.get("quantities", "")
	
	if ingredients is String:
		ingredients = ingredients.split(",")
	if quantities is String:
		quantities = quantities.split(",")
	
	for i in range(ingredients.size()):
		var ingredient_id = ingredients[i].strip_edges()
		var quantity = int(quantities[i].strip_edges()) if i < quantities.size() else 1
		var ingredient_item = item_database.get_item(ingredient_id)
		
		if ingredient_item:
			inventory.add_item(ingredient_item, quantity)

func clear_crafting_queue():
	"""Clear all crafting jobs and refund ingredients"""
	if not current_craft.is_empty():
		_refund_ingredients(current_craft.recipe)
		current_craft.clear()
	
	for craft_job in crafting_queue:
		_refund_ingredients(craft_job.recipe)
	
	crafting_queue.clear()
	crafting_timer = 0.0

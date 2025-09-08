# ===========================
# Inventory.gd - Inventory System
# ===========================
class_name Inventory
extends Resource

# ===========================
# SIGNALS (Using Godot's Signal System)
# ===========================
signal item_added(item: Item, quantity: int, slot_index: int)
signal item_removed(item: Item, quantity: int, slot_index: int)
signal item_moved(from_slot: int, to_slot: int)
signal inventory_full
signal slot_changed(slot_index: int, item: Item, quantity: int)

# ===========================
# INVENTORY STRUCTURE
# ===========================
@export var max_slots: int = 30
@export var allow_auto_sort: bool = true
@export var allow_stacking: bool = true

# Internal inventory data
var _slots: Array[InventorySlot] = []
var _item_database: ItemDatabase

# ===========================
# INVENTORY SLOT CLASS (Using Godot's Resource System)
# ===========================
class InventorySlot extends Resource:
	var item: Item = null
	var quantity: int = 0
	var slot_index: int = -1
	
	func _init(index: int = -1):
		slot_index = index
	
	func is_empty() -> bool:
		return item == null or quantity <= 0
	
	func can_add_item(new_item: Item, amount: int = 1) -> bool:
		if is_empty():
			return true
		if item.can_stack_with(new_item):
			return quantity + amount <= item.max_stack
		return false
	
	func add_item(new_item: Item, amount: int = 1) -> int:
		"""Add item to slot, returns amount actually added"""
		if is_empty():
			item = new_item
			quantity = min(amount, new_item.max_stack)
			return quantity
		elif item.can_stack_with(new_item):
			var space_available = item.max_stack - quantity
			var amount_to_add = min(amount, space_available)
			quantity += amount_to_add
			return amount_to_add
		return 0
	
	func remove_item(amount: int = 1) -> int:
		"""Remove item from slot, returns amount actually removed"""
		if is_empty():
			return 0
		
		var amount_to_remove = min(amount, quantity)
		quantity -= amount_to_remove
		
		if quantity <= 0:
			clear()
		
		return amount_to_remove
	
	func clear():
		"""Clear the slot"""
		item = null
		quantity = 0
	
	func get_save_data() -> Dictionary:
		"""Get slot save data"""
		if is_empty():
			return {}
		return {
			"item_id": item.id,
			"quantity": quantity,
			"item_data": item.to_save_data()
		}

# ===========================
# INITIALIZATION (Using Godot's Resource System)
# ===========================
func _init(database: ItemDatabase = null, slot_count: int = 30):
	_item_database = database
	max_slots = slot_count
	_initialize_slots()

func _initialize_slots():
	"""Initialize inventory slots"""
	_slots.clear()
	_slots.resize(max_slots)
	
	for i in range(max_slots):
		_slots[i] = InventorySlot.new(i)

func set_item_database(database: ItemDatabase):
	"""Set the item database reference"""
	_item_database = database

# ===========================
# ITEM MANAGEMENT (Using Godot's Array Methods)
# ===========================
func add_item(item: Item, quantity: int = 1) -> int:
	"""Add item to inventory, returns amount actually added"""
	if not item or quantity <= 0:
		return 0
	
	var remaining_quantity = quantity
	
	# First try to stack with existing items
	if allow_stacking and item.max_stack > 1:
		for slot in _slots:
			if not slot.is_empty() and slot.item.can_stack_with(item):
				var added = slot.add_item(item, remaining_quantity)
				remaining_quantity -= added
				slot_changed.emit(slot.slot_index, slot.item, slot.quantity)
				
				if remaining_quantity <= 0:
					break
	
	# Then try to add to empty slots
	if remaining_quantity > 0:
		for slot in _slots:
			if slot.is_empty():
				var added = slot.add_item(item, remaining_quantity)
				remaining_quantity -= added
				slot_changed.emit(slot.slot_index, slot.item, slot.quantity)
				item_added.emit(item, added, slot.slot_index)
				
				if remaining_quantity <= 0:
					break
	
	# If we couldn't add everything, inventory is full
	if remaining_quantity > 0:
		inventory_full.emit()
	
	return quantity - remaining_quantity

func remove_item(item_id: String, quantity: int = 1) -> int:
	"""Remove item from inventory by ID, returns amount actually removed"""
	var remaining_to_remove = quantity
	
	for slot in _slots:
		if not slot.is_empty() and slot.item.id == item_id:
			var removed = slot.remove_item(remaining_to_remove)
			remaining_to_remove -= removed
			slot_changed.emit(slot.slot_index, slot.item, slot.quantity)
			item_removed.emit(slot.item if not slot.is_empty() else null, removed, slot.slot_index)
			
			if remaining_to_remove <= 0:
				break
	
	return quantity - remaining_to_remove

func remove_item_from_slot(slot_index: int, quantity: int = 1) -> int:
	"""Remove item from specific slot"""
	if not _is_valid_slot_index(slot_index):
		return 0
	
	var slot = _slots[slot_index]
	if slot.is_empty():
		return 0
	
	var item_before = slot.item
	var removed = slot.remove_item(quantity)
	slot_changed.emit(slot_index, slot.item, slot.quantity)
	item_removed.emit(item_before, removed, slot_index)
	
	return removed

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Move item between slots"""
	if not _is_valid_slot_index(from_slot) or not _is_valid_slot_index(to_slot):
		return false
	
	if from_slot == to_slot:
		return true
	
	var from = _slots[from_slot]
	var to = _slots[to_slot]
	
	if from.is_empty():
		return false
	
	# If destination is empty, simple move
	if to.is_empty():
		to.item = from.item
		to.quantity = from.quantity
		from.clear()
		
		slot_changed.emit(from_slot, from.item, from.quantity)
		slot_changed.emit(to_slot, to.item, to.quantity)
		item_moved.emit(from_slot, to_slot)
		return true
	
	# If items can stack
	if allow_stacking and from.item.can_stack_with(to.item):
		var space_available = to.item.max_stack - to.quantity
		var amount_to_move = min(from.quantity, space_available)
		
		if amount_to_move > 0:
			to.quantity += amount_to_move
			from.remove_item(amount_to_move)
			
			slot_changed.emit(from_slot, from.item, from.quantity)
			slot_changed.emit(to_slot, to.item, to.quantity)
			item_moved.emit(from_slot, to_slot)
			return true
	
	# Otherwise swap items
	var temp_item = from.item
	var temp_quantity = from.quantity
	
	from.item = to.item
	from.quantity = to.quantity
	to.item = temp_item
	to.quantity = temp_quantity
	
	slot_changed.emit(from_slot, from.item, from.quantity)
	slot_changed.emit(to_slot, to.item, to.quantity)
	item_moved.emit(from_slot, to_slot)
	
	return true

# ===========================
# INVENTORY QUERIES (Using Godot's Built-in Methods)
# ===========================
func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if inventory contains item"""
	return get_item_count(item_id) >= quantity

func get_item_count(item_id: String) -> int:
	"""Get total count of specific item"""
	var total = 0
	for slot in _slots:
		if not slot.is_empty() and slot.item.id == item_id:
			total += slot.quantity
	return total

func get_items_by_type(item_type: String) -> Array[Dictionary]:
	"""Get all items of a specific type"""
	var items: Array[Dictionary] = []
	for slot in _slots:
		if not slot.is_empty() and slot.item.item_type == item_type:
			items.append({
				"item": slot.item,
				"quantity": slot.quantity,
				"slot_index": slot.slot_index
			})
	return items

func get_slot(index: int) -> InventorySlot:
	"""Get slot by index"""
	if _is_valid_slot_index(index):
		return _slots[index]
	return null

func get_first_empty_slot() -> int:
	"""Get index of first empty slot, returns -1 if none"""
	for i in range(_slots.size()):
		if _slots[i].is_empty():
			return i
	return -1

func get_empty_slot_count() -> int:
	"""Get number of empty slots"""
	var count = 0
	for slot in _slots:
		if slot.is_empty():
			count += 1
	return count

func is_full() -> bool:
	"""Check if inventory is full"""
	return get_empty_slot_count() == 0

func get_all_items() -> Array[Dictionary]:
	"""Get all items in inventory"""
	var items: Array[Dictionary] = []
	for slot in _slots:
		if not slot.is_empty():
			items.append({
				"item": slot.item,
				"quantity": slot.quantity,
				"slot_index": slot.slot_index
			})
	return items

# ===========================
# INVENTORY OPERATIONS
# ===========================
func sort_inventory():
	"""Sort inventory by item type and name"""
	if not allow_auto_sort:
		return
	
	# Collect all items
	var all_items: Array[Dictionary] = []
	for slot in _slots:
		if not slot.is_empty():
			all_items.append({
				"item": slot.item,
				"quantity": slot.quantity
			})
			slot.clear()
	
	# Sort items
	all_items.sort_custom(func(a, b): 
		if a.item.item_type != b.item.item_type:
			return a.item.item_type < b.item.item_type
		return a.item.name < b.item.name
	)
	
	# Re-add items
	for item_data in all_items:
		add_item(item_data.item, item_data.quantity)

func clear_inventory():
	"""Clear all items from inventory"""
	for slot in _slots:
		if not slot.is_empty():
			slot.clear()
			slot_changed.emit(slot.slot_index, null, 0)

func resize_inventory(new_size: int):
	"""Resize inventory (warning: may lose items if shrinking)"""
	if new_size < max_slots:
		# Check if we'll lose items
		for i in range(new_size, max_slots):
			if not _slots[i].is_empty():
				push_warning("Inventory resize will lose items in slot %d" % i)
	
	max_slots = new_size
	_slots.resize(new_size)
	
	# Initialize new slots if expanding
	for i in range(_slots.size()):
		if _slots[i] == null:
			_slots[i] = InventorySlot.new(i)

# ===========================
# SAVE/LOAD SYSTEM (Using Godot's Resource System)
# ===========================
func save_to_data() -> Dictionary:
	"""Save inventory to dictionary"""
	var save_data = {
		"max_slots": max_slots,
		"slots": []
	}
	
	for slot in _slots:
		save_data.slots.append(slot.get_save_data())
	
	return save_data

func load_from_data(save_data: Dictionary) -> bool:
	"""Load inventory from dictionary"""
	if not _item_database:
		push_error("Inventory: Cannot load without item database")
		return false
	
	max_slots = save_data.get("max_slots", 30)
	_initialize_slots()
	
	var slots_data = save_data.get("slots", [])
	for i in range(min(slots_data.size(), _slots.size())):
		var slot_data = slots_data[i]
		if slot_data.has("item_id"):
			var item_id = slot_data.get("item_id")
			var quantity = slot_data.get("quantity", 1)
			var item = _item_database.get_item(item_id)
			
			if item:
				# Create a copy of the item for this inventory instance
				var item_copy = Item.new()
				item_copy.load_from_data(item.to_save_data())
				
				# Load any instance-specific data
				var item_data = slot_data.get("item_data", {})
				if not item_data.is_empty():
					item_copy.from_save_data(item_data, _item_database)
				
				_slots[i].item = item_copy
				_slots[i].quantity = quantity
			else:
				push_warning("Inventory: Item not found in database: " + str(item_id))
	
	return true

# ===========================
# UTILITY METHODS
# ===========================
func _is_valid_slot_index(index: int) -> bool:
	"""Check if slot index is valid"""
	return index >= 0 and index < _slots.size()

func get_inventory_stats() -> Dictionary:
	"""Get inventory statistics"""
	var stats = {
		"total_slots": max_slots,
		"used_slots": 0,
		"empty_slots": 0,
		"total_items": 0,
		"unique_items": 0,
		"total_value": 0
	}
	
	var unique_items = {}
	
	for slot in _slots:
		if slot.is_empty():
			stats.empty_slots += 1
		else:
			stats.used_slots += 1
			stats.total_items += slot.quantity
			stats.total_value += slot.item.value * slot.quantity
			unique_items[slot.item.id] = true
	
	stats.unique_items = unique_items.size()
	return stats

# ===========================
# DEBUG METHODS
# ===========================
func print_inventory():
	"""Print inventory contents for debugging"""
	print("=== Inventory Contents ===")
	for i in range(_slots.size()):
		var slot = _slots[i]
		if not slot.is_empty():
			print("Slot %d: %s x%d" % [i, slot.item.name, slot.quantity])
	print("==========================")

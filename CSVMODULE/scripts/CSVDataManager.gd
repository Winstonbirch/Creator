# ===========================
# CSVDataManager.gd - CSV Data Management System
# ===========================
class_name CSVDataManager
extends RefCounted

# ===========================
# SIGNALS (Godot's Built-in Event System)
# ===========================
signal data_loaded(data_type: String, record_count: int)
signal data_loading_failed(data_type: String, error_message: String)

# ===========================
# CACHED DATA
# ===========================
static var _loaded_data: Dictionary = {}
static var _is_initialized: bool = false

# ===========================
# CORE CSV PARSING (Using Godot's FileAccess)
# ===========================
static func load_csv_data(file_path: String, data_type: String = "") -> Array[Dictionary]:
	"""Load CSV data using Godot's built-in FileAccess.get_csv_line()"""
	
	# Check if already loaded
	var cache_key = file_path
	if _loaded_data.has(cache_key):
		return _loaded_data[cache_key]
	
	var data: Array[Dictionary] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		var error_msg = "Failed to open CSV file: %s (Error: %s)" % [file_path, FileAccess.get_open_error()]
		push_error(error_msg)
		return data
	
	var headers: PackedStringArray = []
	var line_number = 0
	
	# Read file line by line using Godot's CSV parser
	while not file.eof_reached():
		var csv_line = file.get_csv_line()
		line_number += 1
		
		# Skip empty lines
		if csv_line.size() == 0 or (csv_line.size() == 1 and csv_line[0].strip_edges() == ""):
			continue
		
		# First non-empty line is headers
		if headers.is_empty():
			headers = csv_line
			# Clean headers
			for i in range(headers.size()):
				headers[i] = headers[i].strip_edges().to_lower()
			continue
		
		# Parse data rows
		var row_dict = _parse_csv_row(csv_line, headers, line_number)
		if not row_dict.is_empty():
			data.append(row_dict)
	
	file.close()
	
	# Cache the data
	_loaded_data[cache_key] = data
	
	print("CSVDataManager: Loaded %d records from %s" % [data.size(), file_path])
	return data

static func _parse_csv_row(csv_line: PackedStringArray, headers: PackedStringArray, line_number: int) -> Dictionary:
	"""Parse a single CSV row into a dictionary with type conversion"""
	var row_dict: Dictionary = {}
	
	# Handle rows with different column counts
	var max_columns = min(csv_line.size(), headers.size())
	
	for i in range(max_columns):
		var header = headers[i]
		var value = csv_line[i].strip_edges()
		
		# Convert to appropriate type
		row_dict[header] = _convert_value(value)
	
	# Add missing columns as null
	for i in range(max_columns, headers.size()):
		row_dict[headers[i]] = null
	
	return row_dict

static func _convert_value(value: String) -> Variant:
	"""Convert string values to appropriate types"""
	if value == "":
		return null
	
	# Boolean conversion
	var lower_value = value.to_lower()
	if lower_value in ["true", "yes", "1"]:
		return true
	elif lower_value in ["false", "no", "0"]:
		return false
	
	# Number conversion
	if value.is_valid_int():
		return value.to_int()
	elif value.is_valid_float():
		return value.to_float()
	
	# Array conversion (comma-separated values in quotes)
	if value.begins_with("[") and value.ends_with("]"):
		var array_content = value.substr(1, value.length() - 2)
		if array_content.strip_edges() == "":
			return []
		return array_content.split(",", false)
	
	# Return as string
	return value

# ===========================
# DATA QUERY SYSTEM (Using Godot's Built-in Array Methods)
# ===========================
static func query_data(data: Array[Dictionary], filters: Dictionary = {}) -> Array[Dictionary]:
	"""Query data with filters using Godot's built-in array methods"""
	if filters.is_empty():
		return data
	
	return data.filter(func(row): return _matches_filters(row, filters))

static func _matches_filters(row: Dictionary, filters: Dictionary) -> bool:
	"""Check if a row matches all filters"""
	for filter_key in filters:
		if not row.has(filter_key):
			return false
		
		var row_value = row[filter_key]
		var filter_value = filters[filter_key]
		
		# Handle different filter types
		if filter_value is Dictionary:
			if not _matches_complex_filter(row_value, filter_value):
				return false
		else:
			if row_value != filter_value:
				return false
	
	return true

static func _matches_complex_filter(value: Variant, filter: Dictionary) -> bool:
	"""Handle complex filters like ranges, contains, etc."""
	if filter.has("min") and value < filter["min"]:
		return false
	if filter.has("max") and value > filter["max"]:
		return false
	if filter.has("contains") and not str(value).to_lower().contains(str(filter["contains"]).to_lower()):
		return false
	if filter.has("in") and value not in filter["in"]:
		return false
	
	return true

static func find_by_id(data: Array[Dictionary], id_value: Variant, id_field: String = "id") -> Dictionary:
	"""Find a single record by ID"""
	for row in data:
		if row.get(id_field) == id_value:
			return row
	return {}

static func get_unique_values(data: Array[Dictionary], field: String) -> Array:
	"""Get unique values for a field"""
	var unique_values = []
	for row in data:
		var value = row.get(field)
		if value != null and value not in unique_values:
			unique_values.append(value)
	return unique_values

# ===========================
# CACHE MANAGEMENT
# ===========================
static func clear_cache():
	"""Clear all cached data"""
	_loaded_data.clear()

static func reload_data(file_path: String) -> Array[Dictionary]:
	"""Force reload data from file"""
	_loaded_data.erase(file_path)
	return load_csv_data(file_path)

static func get_cached_data_info() -> Dictionary:
	"""Get information about cached data"""
	var info = {}
	for file_path in _loaded_data:
		info[file_path] = _loaded_data[file_path].size()
	return info

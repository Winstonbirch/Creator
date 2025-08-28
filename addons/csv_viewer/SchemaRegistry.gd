extends Node

static func detect(headers: Array) -> Object:
	var dir = DirAccess.open("res://addons/csv_viewer/validators")
	if not dir:
		print("Failed to open validators directory")
		return null

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var path = "res://addons/csv_viewer/validators/" + file_name
			var validator = load(path).new()
			if validator.has_method("can_handle") and validator.can_handle(headers):
				return validator
		file_name = dir.get_next()
	dir.list_dir_end()

	return null

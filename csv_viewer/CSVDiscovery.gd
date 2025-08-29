class_name CSVDiscovery
extends Node

static func discover_csv_files(path: String = "res://csvfiles/") -> Array:
	var dir = DirAccess.open(path)
	if not dir:
		return []

	var csv_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".csv"):
			csv_files.append(path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	return csv_files

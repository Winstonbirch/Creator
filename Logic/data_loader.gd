class_name CsvLoader
extends Node

signal csv_loaded(path: String, data: Array)

func load_csv(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + path)
		return []

	var content = file.get_as_text()
	var lines = content.split("\n", false)
	var headers = lines[0].split(",", false)
	var data = []

	for i in range(1, lines.size()):
		var row = lines[i].split(",", false)
		if row.size() != headers.size():
			continue
		var entry = {}
		for j in range(headers.size()):
			entry[headers[j]] = row[j]
		data.append(entry)

	return data

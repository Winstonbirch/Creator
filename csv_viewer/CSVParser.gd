extends Node

func parse_csv(path: String) -> Array:
	var result = []
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return result

	var headers = []
	var is_first = true

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue

		var fields = line.split(",")
		

		if is_first:
			headers = fields
			is_first = false
			continue

		var row = {}
		for i in headers.size():
			row[headers[i]] = fields[i] if i < fields.size() else ""
		result.append(row)

	return result

func _ready():
	var csv_text := """id,name,score
1,Alice,90
2,Bob,85
3,Charlie,95"""

	var headers := []
	var rows := []

	var lines := csv_text.split("\n", false)
	if lines.size() > 0:
		headers = lines[0].split(",", false)

	for i in range(1, lines.size()):
		var values = lines[i].split(",", false)
		var row := {}
		for j in range(headers.size()):
			row[headers[j]] = j < values.size() ? values[j] : ""
		rows.append(row)

	print("Headers:", headers)
	print("Rows:")
	for row in rows:
		print(row)

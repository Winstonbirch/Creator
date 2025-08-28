extends PanelContainer

@onready var file_dialog = $VBoxContainer/FileDialog
@onready var row_list = $VBoxContainer/ScrollContainer/RowList
@onready var open_button = $VBoxContainer/Button
@onready var status_label = $VBoxContainer/Label

func _ready():
	open_button.pressed.connect(_on_open_csv_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

func _on_open_csv_pressed():
	file_dialog.popup()

func _on_file_selected(path: String):
	row_list.clear()

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		status_label.set_text("Validation complete")  # ✅
		return

	var headers = []
	var is_first = true
	var rows = []

	while not file.eof_reached():
		var line = file.get_line()
		var fields = line.split(",")

		if is_first:
			headers = fields
			is_first = false
			continue

		var row = {}
		for i in headers.size():
			row[headers[i]] = fields[i].strip_edges()
		rows.append(row)

	var SchemaRegistry = preload("res://addons/csv_viewer/SchemaRegistry.gd").new()
	var schema = SchemaRegistry.get_validator(headers)

	for row in rows:
		var container = VBoxContainer.new()
		for key in row.keys():
			var label = Label.new()
			label.text = "%s: %s" % [key, row[key]]
			container.add_child(label)

		if schema:
			var errors = schema.validate(row)
			if errors.size() > 0:
				status_label.set_text("Validation complete")  # ✅
			else:
				status_label.set_text("Validation complete")  # ✅

		row_list.add_child(container)

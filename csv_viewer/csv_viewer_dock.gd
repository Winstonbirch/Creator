extends PanelContainer

@onready var file_dialog = $VBoxContainer/FileDialog
@onready var row_list = $VBoxContainer/ScrollContainer/RowList
@onready var open_button = $VBoxContainer/Button
@onready var status_label = $VBoxContainer/Label

func _ready():
	open_button.pressed.connect(_on_open_csv_pressed)
	file_dialog.files_selected.connect(_on_files_selected)

func _on_open_csv_pressed():
	file_dialog.popup()

func _on_files_selected(paths: PackedStringArray):
	row_list.clear()
	var parser = preload("res://csv_viewer/CSVParser.gd").new()

	for path in paths:
		var rows = parser.parse_csv(path)
		var header = Label.new()
		header.text = "File: %s (%d rows)" % [path.get_file(), rows.size()]
		row_list.add_child(header)

		for row in rows:
			var container = VBoxContainer.new()
			for key in row.keys():
				var label = Label.new()
				label.text = "%s: %s" % [key, row[key]]
				container.add_child(label)
			row_list.add_child(container)

	status_label.text = "Loaded %d file(s)" % paths.size()

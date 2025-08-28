extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/csv_viewer/CSVViewerDock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	dock.init()

func _exit_tree():
	remove_control_from_docks(dock)
	dock.queue_free()

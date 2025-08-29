extends Node
const DataLoader = preload("res://Logic/data_loader.gd")

func _ready():
	var loader = DataLoader.new()
	var items = loader.load_csv("res://data/items.csv")
	for item in items:
		print(item["id"], " → ", item["name"])

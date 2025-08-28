extends Node

func can_handle(headers: Array) -> bool:
	return "recipe_id" in headers and "item_name" in headers

func validate(row: Dictionary) -> Array:
	var errors = []
	if row.has("ingredients") and row.has("ingredient_qty"):
		var ing = row["ingredients"].split(",")
		var qty = row["ingredient_qty"].split(",")
		if ing.size() != qty.size():
			errors.append("Ingredient count mismatch")
	if row.has("success_rate"):
		var rate = int(row["success_rate"])
		if rate < 0 or rate > 100:
			errors.append("Success rate must be between 0 and 100")
	return errors

extends Node

func can_handle(headers: Array) -> bool:
	return "id" in headers and "text" in headers and "choices" in headers

func validate(row: Dictionary) -> Array:
	var errors = []
	if row.has("choices") and row.has("next_ids"):
		var choices = row["choices"].split("|")
		var nexts = row["next_ids"].split("|")
		if choices.size() != nexts.size():
			errors.append("Choices and next_ids mismatch")
	if row.has("text") and row["text"].strip_edges() == "":
		errors.append("Dialogue text is empty")
	return errors

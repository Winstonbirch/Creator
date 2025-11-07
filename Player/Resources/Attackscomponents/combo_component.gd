extends Node
class_name ComboComponent

signal combo_advanced(attack_data: AttackData)
signal combo_reset()

var current_combo_chain: Array[AttackData] = []
var current_combo_index: int = 0
var combo_window_active: bool = false
var combo_timer: float = 0.0

func start_combo(initial_attack: AttackData) -> void:
	if initial_attack.can_combo and initial_attack.next_attack:
		current_combo_chain = _build_combo_chain(initial_attack)
		current_combo_index = 0
		combo_window_active = false
		print("Combo chain started: ", current_combo_chain.size(), " attacks")
	else:
		current_combo_chain.clear()
		current_combo_index = 0

func _build_combo_chain(start_attack: AttackData) -> Array[AttackData]:
	var chain: Array[AttackData] = [start_attack]
	var next = start_attack.next_attack
	
	while next:
		chain.append(next)
		if next.can_combo:
			next = next.next_attack
		else:
			break
	
	return chain

func attack_finished() -> void:
	if current_combo_chain.is_empty():
		return
	
	var current_attack = current_combo_chain[current_combo_index]
	
	if current_attack.can_combo and current_combo_index < current_combo_chain.size() - 1:
		combo_window_active = true
		combo_timer = 0.0
		print("Combo window open for ", current_attack.combo_window, "s")

func check_combo_input(input_pressed: bool, delta: float) -> AttackData:
	if not combo_window_active:
		return null
	
	combo_timer += delta
	
	# Combo window expired
	if combo_timer >= current_combo_chain[current_combo_index].combo_window:
		reset_combo()
		return null
	
	# Player pressed combo input
	if input_pressed:
		current_combo_index += 1
		combo_window_active = false
		
		if current_combo_index < current_combo_chain.size():
			var next_attack = current_combo_chain[current_combo_index]
			print("Combo continues: ", next_attack.attack_name)
			combo_advanced.emit(next_attack)
			return next_attack
		else:
			print("Combo chain complete!")
			reset_combo()
	
	return null

func reset_combo() -> void:
	current_combo_chain.clear()
	current_combo_index = 0
	combo_window_active = false
	combo_timer = 0.0
	combo_reset.emit()

func is_in_combo() -> bool:
	return not current_combo_chain.is_empty()

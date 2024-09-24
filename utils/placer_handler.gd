extends Node2D
class_name PlaceHandler

signal element_placed(global_position:Vector2)
signal element_removed(global_position:Vector2)
signal possible_element_place(global_position:Vector2)

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("place_element"):
		emit_signal("element_placed", get_global_mouse_position())
	
	if event.is_action_pressed("remove_element"):
		emit_signal("element_removed", get_global_mouse_position())
	

extends VehicleBase
class_name Vehicle

@export
var logic: VehicleLogic

var connected_rsu = null

signal accident

func _on_accident() -> void:
	var current_weight = astar.get_point_weight_scale(path[current_path_index])
	astar.set_point_weight_scale(path[current_path_index], current_weight+2.0)
	accident.emit()

func _on_no_accident() -> void:
	var current_weight = astar.get_point_weight_scale(path[current_path_index]) - 2
	if current_weight < 0:
		current_weight = 0
		
	astar.set_point_weight_scale(path[current_path_index], current_weight)

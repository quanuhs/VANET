extends Area2D
class_name NetworkArea

@export
var network_manager: NetworkManager = null

signal network_in_reach(network_manager:NetworkManager)
signal network_lost_reach(network_manager:NetworkManager)

#
func _physics_process(delta: float) -> void:
	#refresh_networks_in_area()
	network_manager.queue_redraw()

func refresh_networks_in_area():
	var areas = get_overlapping_areas()
	
	remove_disconnected(areas)
	search(areas)
	network_manager.queue_redraw()


func remove_disconnected(areas):
	for node in network_manager.connected_nodes:
		
		if not is_instance_valid(node):
			network_manager.disconnect_node(node)
			return
		
		var found = false
		
		for area in areas:
			var _new_node = area.network_manager
			
			if _new_node == network_manager:
				continue
			
			if _new_node == node:
				found = true
				break
	
		if not found:
			emit_signal("network_lost_reach", node)
			


func search(areas):
	for area in areas:
		var node = area.network_manager
		
		if node not in network_manager.connected_nodes:
			emit_signal("network_in_reach", node)


func _on_timer_timeout() -> void:
	refresh_networks_in_area()
	network_manager.queue_redraw()

func check_networks_in_reach():
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _on_area_entered(area: Area2D) -> void:
	if area.network_manager not in network_manager.connected_nodes:
		emit_signal("network_in_reach", area.network_manager)

func _on_area_exited(area: Area2D) -> void:
	if area.network_manager in network_manager.connected_nodes:
		await get_tree().physics_frame
		if not is_instance_valid(area):
			return
		if area not in get_overlapping_areas():
			emit_signal("network_lost_reach", area.network_manager)

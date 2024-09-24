extends BasePlaceNetworkUnit
class_name MEC


func _continue_ready():
	network_manager.message_received.connect(_on_message_recived)


func _physics_process(delta: float) -> void:
	refresh_rsus_in_area()


func refresh_rsus_in_area():
	var areas = get_overlapping_areas()
	
	remove_unreachable_rsus(areas)
	add_reachable_rsus(areas)
	queue_redraw()

func remove_unreachable_rsus(areas):
	for node in network_manager.connected_nodes:
		var found = false
		for area in areas:
			if area is RSU:
				var _new_node = area.network_manager
				if _new_node == node:
					found = true
					break
		
		if not found:
			network_manager.disconnect_node(node)


func add_reachable_rsus(areas):
	for area in areas:
		if area is RSU:
			network_manager.connect_to_node(area.network_manager, CONFIG["transmit_power_dbm"], "RSU")
			area.network_manager.connect_to_node(network_manager, area.CONFIG["transmit_power_dbm"], "MEC")


func _on_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	if to_node != self:
		return
	
	if message.payload.get("ASK_DATA"):
		var compute_seconds = randf_range(0.5, 1)
		var data_size = round(compute_seconds * 1024)
		await get_tree().create_timer(compute_seconds).timeout
		
		var memory_id = message.payload.get("memory_id")
		var index = message.payload.get("index")
		var original_node = message.payload.get("original_node")
		
		network_manager.send_message(from_node, Message.new(data_size, 
		{"RECIVE_DATA": true, "memory_id": memory_id, "index": index, "original_node": original_node}, 
		int(compute_seconds*2)))

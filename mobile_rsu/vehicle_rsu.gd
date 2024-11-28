extends VehicleBase
class_name VehicleRSU

@export
var memory: Memory
var connected_rsu: RSU = null

var initial_start = null
var initial_end = null


func after_ready():
	line_color = Color.TURQUOISE
	network_manager.change_radius_to_real()

func _process(delta: float) -> void:
	if connected_rsu == null and network_manager.has_connection_with_group("RSU"):
		var rsus = network_manager.groups.get("RSU")
		var closest = rsus[0]
		
		for rsu in rsus:
			if self.global_position.distance_to(closest.global_position) > self.global_position.distance_to(rsu.global_position):
				closest = rsu
			
		try_connecting_to_rsu(closest.get_parent())
	
	queue_redraw()


func _on_network_manager_message_received(to_node: Node, from_node: Node, message: Message) -> void:
	if from_node is Vehicle:
		handle_vehicle_message(from_node, message)
		return
	
	if from_node is RSU:
		handle_rsu_message(from_node, message)
		return


func _change_connected_rsu(new_rsu: RSU):
	if connected_rsu != null:
		var _network = network_manager.connected_nodes.get(connected_rsu.network_manager)
		
		if _network:
			network_manager.connected_nodes[connected_rsu.network_manager].erase("color")
	
	connected_rsu = new_rsu
	network_manager.connected_nodes[connected_rsu.network_manager]["color"] = Color.SPRING_GREEN


func try_connecting_to_rsu(node: RSU):
	network_manager.connect_to_node(node.network_manager, CONFIG_GLOBAL.CONFIG.get("vehicle").get("bandwidth"), "RSU")
	node.network_manager.connect_to_node(network_manager, CONFIG_GLOBAL.CONFIG.get("rsu").get("bandwidth"), "vehicle")
	
	if connected_rsu == null:
		_change_connected_rsu(node)
	
	elif node.network_manager.count_in_group("vehicle") * 1.2 < connected_rsu.network_manager.count_in_group("vehicle"):
		_change_connected_rsu(node)


func _on_network_area_network_in_reach(other_network_manager: NetworkManager) -> void:
	if other_network_manager.get_parent() is Vehicle and network_manager.has_connection_with_group("RSU"):
		#print(name)
		network_manager.send_message(other_network_manager.get_parent(), 
		Message.new(Message.generate_scene_unique_id(), 10, {"CONNECTED_TO_RSU": true, "amount": network_manager.count_in_group("vehicle")}, 1), false)


func _on_network_area_network_lost_reach(other_network_manager: NetworkManager) -> void:
	if other_network_manager.get_parent() is Vehicle:
		var vehicle = other_network_manager.get_parent()
		network_manager.send_message(vehicle, 
		Message.new(Message.generate_scene_unique_id(), 10, {"DISCONNECT_ME": true}, 1), false)
		vehicle.network_manager.disconnect_node(network_manager)
		network_manager.disconnect_node(vehicle.network_manager)


func handle_vehicle_message(vehicle: Vehicle, message: Message):
	if message.payload.get("ASK_DATA"):
		var memory_id = message.payload.get("memory_id")
		var info = memory.retrive(memory_id)
		
		if info:
			message.payload["RECIVE_DATA"] = true
			message.payload.erase("ASK_DATA")
			message.total_bits = info.get("size")
			message._packetize(4)
			network_manager.send_message(vehicle, message)
			
		else:
			if message.payload.get("original_node") == null:
				message.payload["original_node"] = vehicle
			
			network_manager.send_message_in_group("RSU", message)
		
		return


func handle_rsu_message(rsu: RSU, message: Message):
	if message.payload.get("RECIVE_DATA"):
#		Несем полезную информацию, обновляем память
		var memory_id = message.payload.get("memory_id")
		var size = message.total_bits
		var index = message.payload.get("index")
		var original_node = message.payload.get("original_node")
		memory.update(memory_id, size, {})
		
		var info = memory.retrive(memory_id)
		
		if original_node != null and original_node != self:
			network_manager.send_message(original_node, message)
		return
	
	if message.payload.get("CONNECTED_TO_RSU"):
		try_connecting_to_rsu(rsu)
		return
		##		ИСПРАВИТЬ НА NETWORK ЗАПРОС
		
	
	if message.payload.get("DISCONNECT_ME"):
		if connected_rsu == rsu:
			connected_rsu = null
		
		network_manager.disconnect_node(rsu.network_manager)
		return


func move_to_accident(node):
	var point_id = node.path[node.current_path_index]
	
	if point_id in path:
		return true
	
	var my_path = get_summed_path_weight(get_my_path_to_id(point_id))
	
	for mrsu in get_tree().get_nodes_in_group("vehicle_rsu"):
		var others_path = get_summed_path_weight(mrsu.get_my_path_to(point_id))
		
		if my_path > others_path:
			return false
		elif my_path == others_path:
			if self.global_position.distance_to(node.global_position) > mrsu.global_position.distance_to(node.global_position):
				return false
		
		change_route(point_id)
		return true

func move_to_node(node):
	change_route(astar.get_closest_point(node.global_position))

func get_my_path_to_node(node):
	return astar.get_id_path(path[current_path_index], astar.get_closest_point(node.global_position))


func get_my_path_to_id(point_id):
	return astar.get_id_path(path[current_path_index], point_id)


func get_summed_path_weight(path):
	var weight = 0
	
	for _id in path:
		weight += astar.get_point_weight_scale(_id)
	
	return weight
	

func _on_reached_end_of_route():
	if not CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_reactive"):
		change_route(path[0])
		#if astar.get_point_position(initial_end).distance_to(self.global_position) > astar.get_point_position(initial_start).distance_to(self.global_position):
			#change_route(initial_end)
		#else:
			#change_route(initial_start)
	else:
		change_route(randi_range(1, astar.get_point_count()))


func count_active():
	var counter = 0
	
	for network in network_manager.groups.get("vehicle", []):
		var vehicle = network.get_parent()
		
		if vehicle.connected_rsu == self:
			counter+= 1
	return counter

extends BasePlaceNetworkUnit
class_name RSU


var vehicles_in_range = []

signal vehicle_entered_range(vehicle: Vehicle)
signal vehicle_exited_range(vehicle: Vehicle)

@export
var memory: Memory


func _physics_process(delta: float) -> void:
	refresh_vehicles_in_area()

func refresh_vehicles_in_area():
	var areas = get_overlapping_areas()
	
	remove_unreachable_vehicles(areas)
	add_reachable_vehicle(areas)
	queue_redraw()

func remove_unreachable_vehicles(areas):
	for node in network_manager.connected_nodes:
		var vehicle = node.get_parent()
		if not vehicle is Vehicle:
			continue
		
		var found = false
		for area in areas:
			area = area.get_parent()
			
			if area is Vehicle:
				var _new_node = area.network_manager
				if _new_node == node:
					found = true
					break
		
		if not found:
			emit_signal("vehicle_exited_range", vehicle)
			network_manager.disconnect_node(node)


func add_reachable_vehicle(areas):
	for area in areas:
		var vehicle = area.get_parent()
		
		if vehicle is Vehicle:
			if vehicle.network_manager not in network_manager.connected_nodes:
				emit_signal("vehicle_entered_range", vehicle)
			
			network_manager.connect_to_node(vehicle.network_manager, CONFIG["transmit_power_dbm"], "RSU")


func _continue_ready():
	network_manager.message_received.connect(_on_message_recived)
	line_size = 1

func _on_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	if to_node != self:
		return
		
	#print(from_node, " => ", to_node, " | ", message.payload)
	
	if message.payload.get("ACCIDENT"):
		for v in vehicles_in_range:
			network_manager.send_message(v, Message.new(2048, {"CHANGE_ROUTE": true}, 5))
	
	
	if message.payload.get("ASK_DATA"):
		var memory_id = message.payload.get("memory_id")
		var info = memory.retrive(memory_id)
		var index = message.payload.get("index")
		if info:
			network_manager.send_message(from_node, Message.new(info.get("size"), {"REQUESTED_DATA": true, 
					"memory_id": memory_id, "index": index}, 3))
		else:
			message.total_bits += 128
			message.payload["original_node"] = from_node
			message._packetize(4)
			network_manager.send_message_in_group("MEC", message)
	
	
	if message.payload.get("RECIVE_DATA"):
		var memory_id = message.payload.get("memory_id")
		var size = message.total_bits
		var index = message.payload.get("index")
		var original_node = message.payload.get("original_node")
		memory.update(memory_id, {"size": size})
		
		var info = memory.retrive(memory_id)
		network_manager.send_message(original_node, Message.new(size, {"REQUESTED_DATA": true, 
		"memory_id": memory_id, "index": index}, 3))


func _on_vehicle_entered_range(vehicle: Vehicle) -> void:
	vehicles_in_range.append(vehicle)
	network_manager.connect_to_node(vehicle.network_manager, CONFIG["bandwidth"], "vehicle")
	network_manager.send_message(vehicle, Message.new(10, {"CONNECTED_TO_RSU": true}, 1))


func _on_vehicle_exited_range(vehicle: Vehicle) -> void:
	network_manager.send_message(vehicle, Message.new(10, {"DISCONNECT_FROM_RSU": true}, 1))
	network_manager.disconnect_node(vehicle.network_manager)
	vehicles_in_range.erase(vehicle)
	queue_redraw()

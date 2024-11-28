extends Node
class_name VehicleLogic


signal change_route
signal data_asked

@onready var timer: Timer = $Timer
@export var vehicle: Vehicle

var requested = {}

@export
var network_manager: NetworkManager

func _process(delta: float) -> void:
	if vehicle.connected_rsu == null:
		network_manager.area.check_networks_in_reach()


func _on_signal_handler_message_recived(to_node: Node, from_node: Node, message: Message) -> void:

	if message.payload.get("CONNECTED_TO_RSU"):
		try_connecting_to_rsu(from_node)
		##		ИСПРАВИТЬ НА NETWORK ЗАПРОС
	
	if message.payload.get("DISCONNECT_ME"):
		if vehicle.connected_rsu == from_node:
			_disconnect_rsu(from_node)
	
	if message.payload.get("CHANGE_ROUTE"):
		vehicle.change_route_keep()
	
	if message.payload.get("RECIVE_DATA"):
		recive_data(message.payload.get("memory_id"), message.payload.get("index"), Time.get_ticks_msec())
		


func _on_vehicle_accident() -> void:
	network_manager.send_message(vehicle.connected_rsu,  Message.new(Message.generate_scene_unique_id(), 10, {"ACCIDENT": true}, 1))


func recive_data(memory_id: int, index:int, time):
	
	if requested.get(memory_id):
		if len(requested[memory_id]["recived"]) <= index:
			return
		
		requested[memory_id]["recived"][index] = time


var ask_times = 0
var ask_wait_time = 0.0

func ask_data(times:int=0, wait_time:float=0):
		
	#print("ASK %s %s" % [times, wait_time])
	
	ask_times = times
	ask_wait_time = wait_time
	
	if not network_manager.has_connection_with_group("RSU"):
		if wait_time > 0.0:
			timer.start(wait_time)
			
		return
	
	var random_memory = randi_range(1, CONFIG_GLOBAL.CONFIG.get("global").get("queries", 100))
	
	if not requested.get(random_memory):
		requested[random_memory] = {"asked": [], "recived": [], "connected": []}
	
	requested[random_memory]["recived"].append(-1)
	requested[random_memory]["asked"].append(Time.get_ticks_msec())
	requested[random_memory]["connected"].append(vehicle.connected_rsu)
	
	network_manager.send_message(vehicle.connected_rsu, Message.new(Message.generate_scene_unique_id(), 10, {"ASK_DATA": true, "memory_id": random_memory, 
	"index": len(requested[random_memory]["asked"])-1}, 2))
	
	emit_signal("data_asked")
	
	ask_times -= 1
	
	if times <= 0:
		return

	else:
		if wait_time > 0.0:
			timer.start(wait_time)
			
func _on_timer_timeout() -> void:
	ask_data(ask_times, ask_wait_time)

func _change_connected_rsu(new_rsu):
	if not (new_rsu is RSU or new_rsu is VehicleRSU):
		push_error("ERROR")
		return
	
	if vehicle.connected_rsu != null:
		return
	
	
	network_manager.connect_to_node(new_rsu.network_manager, CONFIG_GLOBAL.CONFIG.get("vehicle").get("bandwidth"), "RSU")
	new_rsu.network_manager.connect_to_node(network_manager, CONFIG_GLOBAL.CONFIG.get("rsu").get("bandwidth"), "vehicle")
	
	
	vehicle.connected_rsu = new_rsu
	network_manager.connected_nodes[vehicle.connected_rsu.network_manager]["color"] = Color.ORANGE_RED

func try_connecting_to_rsu(node):
	if not (node is RSU or node is VehicleRSU):
		return


	await get_tree().physics_frame

	if vehicle.connected_rsu == null:
		_change_connected_rsu(node)
		return
	
	
	var in_case_rsu = node is RSU
	var in_case_mrsu = node is VehicleRSU and (node.count_active() <= vehicle.connected_rsu.count_active())
	var distance_current = vehicle.global_position.distance_to(vehicle.connected_rsu.global_position)
	var distance_try = vehicle.global_position.distance_to(node.global_position)
	
	if (in_case_rsu or in_case_mrsu) and (distance_current > distance_try):
		_disconnect_rsu(vehicle.connected_rsu)
		_change_connected_rsu(node)

func _on_vehicle_reached_end_of_route() -> void:
	vehicle.change_route(randi_range(0, 1000))

func _disconnect_rsu(node):
	if node == vehicle.connected_rsu:
		vehicle.connected_rsu = null
		
	network_manager.disconnect_node(node.network_manager)
	node.network_manager.disconnect_node(network_manager)

func _on_network_area_network_lost_reach(other_network_manager: NetworkManager) -> void:
	var parent = other_network_manager.get_parent()
	
	if parent is RSU:
		_disconnect_rsu(parent)



func _on_network_area_network_in_reach(other_network_manager: NetworkManager) -> void:
	var parent = other_network_manager.get_parent()
	
	if parent is RSU:
		try_connecting_to_rsu(parent)

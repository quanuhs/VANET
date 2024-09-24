extends Node
class_name VehicleLogic


signal change_route
signal data_asked

var network_manager: NetworkManager

func _ready() -> void:
	network_manager = get_parent()


func _on_signal_handler_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	#print(to_node, " | ", message.payload)
	
	if message.payload.get("CONNECTED_TO_RSU"):
		network_manager.connect_to_node(from_node.network_manager, 10e6, "RSU")
	
	if message.payload.get("DISCONNECT_FROM_RSU"):
		network_manager.disconnect_node(from_node.network_manager)
	
	if message.payload.get("CHANGE_ROUTE"):
		change_route.emit()
	
	if message.payload.get("REQUESTED_DATA"):
		recive_data(message.payload.get("memory_id"), message.payload.get("index"), Time.get_ticks_msec())
		


func _on_vehicle_accident() -> void:
	network_manager.send_message_in_group("RSU",  Message.new(10, {"ACCIDENT": true}, 1))

var requested = {}

func recive_data(memory_id: int, index:int, time):
	if requested.get(memory_id):
		requested[memory_id]["recived"][index] = time


func ask_data(times:int=0, wait_time:float=0.0):
		
	if not network_manager.has_connection_with_group("RSU"):
		return
	
	var random_memory = randi_range(1, 1000)
	
	if not requested.get(random_memory):
		requested[random_memory] = {"asked": [], "recived": []}
	
	requested[random_memory]["recived"].append(INF)
	requested[random_memory]["asked"].append(Time.get_ticks_msec())
	network_manager.send_message_in_group("RSU", Message.new(10, {"ASK_DATA": true, "memory_id": random_memory, 
	"index": len(requested[random_memory]["asked"])-1}, 2))
	
	emit_signal("data_asked")
	
	if times <= 0:
		return
	else:
		if wait_time > 0.0:
			await get_tree().create_timer(wait_time).timeout
		
		await ask_data(times-1)

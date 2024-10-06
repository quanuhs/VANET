#extends BasePlaceNetworkUnit
#class_name MEC
#
#@export
#var memory: Memory
#
#func _before_ready():
	#CONFIG = CONFIG_GLOBAL.CONFIG.get("mec", CONFIG)
#
#func _continue_ready():
	#network_manager.message_received.connect(_on_message_recived)
#
#
#func _on_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	#if to_node != self:
		#return
	#
	#if message.payload.get("ASK_DATA"):
		#
		#var memory_id = message.payload.get("memory_id")
		#var index = message.payload.get("index")
		#var original_node = message.payload.get("original_node")
		#
		#var compute_seconds = randf_range(0.5, 1)
		#var data_size = round(compute_seconds * CONFIG.get("min_computing_size", 8*1024) )
		#
		#print(data_size)
		#
		#if memory.retrive(memory_id) == null:
			#await get_tree().create_timer(compute_seconds).timeout
			#
			#if CONFIG.get("use_memory", true):
				#memory.put(memory_id, data_size, {})
				#
		#else:
			#compute_seconds = 0.5
			#data_size = memory.retrive(memory_id).get("size")
		#
		#network_manager.send_message(from_node, Message.new(data_size, 
		#{"RECIVE_DATA": true, "memory_id": memory_id, "index": index, "original_node": original_node}, 
		#int(compute_seconds*2)+2))
#
#
#func _on_network_area_network_in_reach(other_network_manager: NetworkManager) -> void:
	#if other_network_manager.get_parent() is RSU:
		#network_manager.connect_to_node(other_network_manager, CONFIG["bandwidth"], "RSU")
		#other_network_manager.connect_to_node(network_manager, CONFIG["bandwidth"], "MEC")
		#
		#
extends BasePlaceNetworkUnit
class_name MEC


@export
var memory: Memory

func _before_ready():
	CONFIG = CONFIG_GLOBAL.CONFIG.get("mec", CONFIG)

func _continue_ready():
	network_manager.message_received.connect(_on_message_recived)
	line_size = 10


func _on_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	if to_node != self:
		return
	
	if message.payload.get("ASK_DATA"):
		
		var memory_id = message.payload.get("memory_id")
		var index = message.payload.get("index")
		var resend = message.payload.get("resend")
		
		#var data_size = memory_id * 8*512
		#var compute_seconds = round(data_size/CONFIG.get("min_computing_size", 8*1024))
		var compute_seconds = randf_range(0.5, 1)
		var data_size = float(CONFIG_GLOBAL.CONFIG.get("global", {}).get("data_size_bits", 1024*8*2)) * compute_seconds
		
		
		if memory.retrive(memory_id) == null:
			await get_tree().create_timer(compute_seconds).timeout
			
			if CONFIG.get("use_memory", true):
				memory.put(memory_id, data_size, {})
				
		else:
			compute_seconds = 0.5
			data_size = memory.retrive(memory_id).get("size")
		
		var new_message = Message.new(Message.generate_scene_unique_id(), data_size, 
		{"RECIVE_DATA": true, "memory_id": memory_id, "index": index, "resend": resend}, min(round(data_size/1024)+1, 25))
	
		
		network_manager.send_message(from_node, new_message)


func connect_rsu(other_network_manager):
	if other_network_manager.get_parent() is RSU:
		other_network_manager.connect_to_node(network_manager, CONFIG["bandwidth"], "MEC")

func _on_network_area_network_in_reach(other_network_manager: NetworkManager) -> void:
	if other_network_manager.get_parent() is RSU:
		network_manager.connect_to_node(other_network_manager, CONFIG["bandwidth"], "RSU")
		connect_rsu(other_network_manager)

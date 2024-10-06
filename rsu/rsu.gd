extends BasePlaceNetworkUnit
class_name RSU


var vehicles_in_range = []

signal vehicle_entered_range(vehicle: Vehicle)
signal vehicle_exited_range(vehicle: Vehicle)


@export
var memory: Memory

@export
var cluster: Cluster

var cluster_amount: int = 3

var messages_from_cluster = {}

func _before_ready():
	CONFIG = CONFIG_GLOBAL.CONFIG.get("rsu", CONFIG)
	cluster.cluster_depth = CONFIG.get("depth", 1)
	cluster.use_cluster = CONFIG.get("cluster", true)

func _continue_ready():
	network_manager.message_received.connect(_on_message_recived)
	line_size = 2



func _on_message_recived(to_node: Node, from_node: Node, message: Message) -> void:
	if to_node != self:
		return
	
	#print(to_node, from_node, message.payload)
	
	if message.payload.get("ACCIDENT"):
			network_manager.send_message_in_group("vehicle", Message.new(Message.generate_scene_unique_id(), 2048, {"CHANGE_ROUTE": true}, 5))
			#network_manager.send_message_in_group("RSU", message)
			return
	
	if message.payload.get("ASK_DATA"):
		var memory_id = message.payload.get("memory_id")
		var info = memory.retrive(memory_id)
		
		if info:
			message.payload["RECIVE_DATA"] = true
			message.payload.erase("ASK_DATA")
			message.total_bits = info.get("size")
			message._packetize(4)
			network_manager.send_message(from_node, message)
			
		else:
			if message.payload.get("resend") == null:
				message.payload["resend"] = [from_node]
			ask_for_data(message)
		
		return
	
	if message.payload.get("RECIVE_DATA"):
#		Несем полезную информацию, обновляем память
		var memory_id = message.payload.get("memory_id")
		var size = message.total_bits
		var index = message.payload.get("index")
		var resend = message.payload.get("resend", [])
		memory.update(memory_id, size, {})
		
		var info = memory.retrive(memory_id)
		
		resend.erase(self)
		if len(resend) > 0:
			message.payload["resend"] = resend
			network_manager.send_message(resend[-1], message)



func ask_for_data(message: Message):
#	ЕСЛИ МЫ В КЛАСТЕРЕ, ХОТИМ ОТПРАВИТЬ ДАЛЬШЕ
	message.total_bits += 128
	message._packetize(4)
	
	if cluster.use_cluster:
		if network_manager.has_connection_with_group("MEC"):
			network_manager.send_message_in_group("MEC", message)
			return
						
		if cluster.ask_in_cluster(message):
			return
		
	network_manager.send_message_in_group("MEC", message)
	
func count_active():
	var counter = 0
	
	for network in network_manager.groups.get("vehicle", []):
		var vehicle = network.get_parent()
		
		if vehicle.connected_rsu == self:
			counter+= 1
	return counter

func _on_vehicle_entered_range(vehicle: VehicleBase) -> void:
	network_manager.send_message(vehicle, Message.new(Message.generate_scene_unique_id(), 10, {"CONNECTED_TO_RSU": true, "amount": network_manager.count_in_group("vehicle")}, 1))

func _on_vehicle_exited_range(vehicle: VehicleBase) -> void:
	network_manager.send_message(vehicle, Message.new(Message.generate_scene_unique_id(), 10, {"DISCONNECT_ME": true}, 1))
	vehicle.network_manager.disconnect_node(network_manager)
	network_manager.disconnect_node(vehicle.network_manager)

func refresh_connection_to_mec(visited_rsus = []):
	# Проверяем, если текущий RSU уже был посещен
	if network_manager in visited_rsus:
		return
	
	# Добавляем текущий RSU в список посещенных
	visited_rsus.append(network_manager)

	var anyone_has_connection = false
	
	# Проверяем подключение всех соседей к MEC
	for neighbor_rsu_network: NetworkManager in network_manager.groups.get("RSU", []):
		if neighbor_rsu_network != network_manager and neighbor_rsu_network.has_connection_with_group("MEC"):
			anyone_has_connection = true
			break
	
	# Если ни один из соседей не имеет подключения к MEC, мы подключаемся
	if not anyone_has_connection and not network_manager.has_connection_with_group("MEC"):
		# Подключаемся к ближайшему MEC
		for mec_network in network_manager.groups.get("MEC", []):
			network_manager.connect_to_node(mec_network, CONFIG["bandwidth"], "MEC")
			mec_network.connect_to_node(network_manager, CONFIG["bandwidth"], "MEC")
			break  # Подключаемся к первому доступному MEC
		
		# Говорим соседям пересобрать свои соединения
		for neighbor_rsu_network: NetworkManager in network_manager.groups.get("RSU", []):
			if neighbor_rsu_network != network_manager:
				var neighbor_rsu = neighbor_rsu_network.get_parent()
				await get_tree().physics_frame  # Ожидание физического кадра
				neighbor_rsu.refresh_connection_to_mec(visited_rsus)
	
	# Если есть хотя бы один сосед с подключением к MEC, мы отключаемся
	elif anyone_has_connection and network_manager.has_connection_with_group("MEC"):
		for mec_network in network_manager.groups.get("MEC", []):
			network_manager.disconnect_node(mec_network)
			mec_network.disconnect_node(network_manager)

func _on_network_area_network_in_reach(other_network_manager: NetworkManager) -> void:
	var parent = other_network_manager.get_parent()
	
	if other_network_manager in network_manager.connected_nodes:
		return
	
	if parent is VehicleBase:
		emit_signal("vehicle_entered_range", parent)
	
	if parent is RSU and cluster.use_cluster:
		if not (network_manager.count_in_group("RSU") <= cluster_amount and other_network_manager.count_in_group("RSU") <= cluster_amount):
			return
			
		network_manager.connect_to_node(other_network_manager, CONFIG["bandwidth"], "RSU")
		other_network_manager.connect_to_node(network_manager, CONFIG["bandwidth"], "RSU")
		
		await get_tree().physics_frame  # Ожидание физического кадра для синхронизации
		
		# Определяем "главного" RSU
		var my_connection_count = network_manager.connected_nodes.size()
		var other_connection_count = other_network_manager.connected_nodes.size()
		
		if my_connection_count < other_connection_count or (my_connection_count == other_connection_count and randi_range(0, 1) == 0):
			# Если текущий RSU имеет меньше подключений или случайно выбран
			refresh_connection_to_mec()
		else:
			# Другой RSU будет главным и выполнит refresh_connection_to_mec
			parent.refresh_connection_to_mec([])



			


func _on_network_area_network_lost_reach(other_network_manager: NetworkManager) -> void:
	var parent = other_network_manager.get_parent()
	
	if parent is VehicleBase:
		emit_signal("vehicle_exited_range", parent)
		
	if parent is MEC:
		refresh_connection_to_mec()

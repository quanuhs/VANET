extends Node2D
class_name NetworkManager

# Константы
const RETRY_LIMIT = 2  # Максимальное количество попыток повторной отправки сообщения
const FINAL_PACKET_TIMEOUT = 10.0  # Максимальное время ожидания финального пакета в секундах
const ACK_TIMEOUT = 20.0  # Время ожидания подтверждения (ACK) для сообщения в секундах

const ACK_SIZE = 10 # бит

# Сигналы для отправки и получения пакетов
signal packet_sent(to_node: Node, from_node: Node, packet: Packet)
signal packet_received(to_node: Node, from_node: Node, packet: Packet)
signal packet_lost(to_node: Node, from_node: Node, packet: Packet)
signal ack_received(to_node: Node, from_node: Node, message_id: String)
signal message_received(to_node: Node, from_node: Node, message: Message)
signal message_dropped(message_id: String, reason: String)

signal done_operation

@onready 
var collision_shape_2d: CollisionShape2D = $NetworkArea/CollisionShape2D

@export
var interference: Interference

var receiver_sensitivity_dbm: float = 0.0

var transmit_power_dbm: float
var frequency: float
var noise_figure: float
var path_loss_exponent: float = 2.0
var radius: float = 1.0

@export
var area: NetworkArea

@export
var device_area: DeviceArea

@export
var use_tcp: bool = true  # Переключатель для работы в режимах TCP (true) или UDP (false)

var connected_nodes = {}  # Словарь для хранения подключенных узлов и их скоростей передачи
var received_packets = {}  # Хранит полученные пакеты по message_id
var packets_queue = []
var pending_acks = {}  # Хранит ожидающие подтверждения (ACK) для сообщений
var retry_counts = {}  # Количество попыток повторной отправки для каждого сообщения
var final_packet_times = {}  # Время последнего принятого пакета для каждого сообщения
var groups = {}

func _init_(receiver_sensitivity_dbm, transmit_power_dbm, frequency, noise_figure) -> void:
	self.receiver_sensitivity_dbm = receiver_sensitivity_dbm
	self.transmit_power_dbm = transmit_power_dbm
	self.frequency = frequency
	self.noise_figure = noise_figure
	

func setup(receiver_sensitivity_dbm, transmit_power_dbm, frequency, noise_figure) -> void:
	self.receiver_sensitivity_dbm = receiver_sensitivity_dbm
	self.transmit_power_dbm = transmit_power_dbm
	self.frequency = frequency
	self.noise_figure = noise_figure
	
	change_radius_to_real()


func _draw() -> void:
	# Визуализируем сетевые подключения
	for node in connected_nodes:
		if not is_instance_valid(node):
			disconnect_node(node)
			continue
		
		draw_line(Vector2.ZERO, to_local(node.global_position)/2, connected_nodes[node].get("color", get_parent().line_color), get_parent().line_size)


func change_radius_to_real():
	var radi = interference.calculate_coverage_radius(self.transmit_power_dbm, self.receiver_sensitivity_dbm, self.frequency, false, 0)
	collision_shape_2d.shape.radius = self.radius
	print(radi, " ", self.frequency)
	set_radius(radi)
	

func set_radius(radius: float):
	self.radius = radius
	collision_shape_2d.shape.radius = self.radius

func set_device_radius(radius: float):
	device_area.set_radius(radius)
	

#func handle_packet_queue():
func handle_packet_queue():
	var current_time = Time.get_ticks_usec()
	var processed_packets = 0
	for packet_info in packets_queue:
		#if processed_packets >= packets_per_tick:
			#break
			
		if current_time >= packet_info["expected_delivery_time"]:
			_deliver_packet(packet_info)
			packets_queue.erase(packet_info)
			processed_packets += 1

	done_operation.emit()
	
	

func handle_ack():
	var current_time = Time.get_ticks_usec() 
	var messages_to_remove = []
	for message_id in pending_acks.keys():
		var ack_info = pending_acks[message_id]
		if current_time >= ack_info["timeout"]:
			# Проверка лимита повторных попыток
			if retry_counts.get(message_id, 0) >= RETRY_LIMIT:
				_drop_message(message_id, "Exceeded retry limit")
				messages_to_remove.append(message_id)
				continue

			# Повторная отправка сообщения при истечении таймаута
			var message = ack_info["message"]
			var to_network_manager = ack_info["to_network_manager"]
			#print_debug("ACK timeout reached for message %s. Resending..." % [message.message_id])
			send_message(to_network_manager.get_parent(), message)
			retry_counts[message_id] += 1  # Увеличиваем количество повторных попыток

			# Обновляем таймаут
			pending_acks[message_id]["timeout"] = current_time + int(ACK_TIMEOUT * 1e6)
	
	# Удаляем сообщения, превысившие лимит попыток
	for msg_id in messages_to_remove:
		pending_acks.erase(msg_id)
		retry_counts.erase(msg_id)

	done_operation.emit()


func handle_incoming():
	var current_time = Time.get_ticks_usec()
	handle_packet_queue()
	handle_ack()
	
	# Проверка времени ожидания финального пакета
	for message_id in final_packet_times.keys():
		if (current_time / 1e6) - final_packet_times[message_id] >= FINAL_PACKET_TIMEOUT:
			_drop_message(message_id, "Final packet timeout exceeded")
	
	get_tree().physics_frame

func _physics_process(delta):
	handle_incoming()

func count_in_group(group_name: String):
	var group = groups.get(group_name)
	
	if group:
		return len(group)
	else:
		return 0

func has_connection_with_group(group_name: String):
	return count_in_group(group_name) > 0

func connect_to_node(network_manager, bandwidth: float, group: String) -> void:
	if network_manager not in connected_nodes:
		if groups.get(group) == null:
			groups[group] = []
		
		groups[group].append(network_manager)
		
		connected_nodes[network_manager] = {"transmission_speed": bandwidth, "group": group}
		#print_debug("%s connected to %s with transmission_speed %f bps" % [get_parent().name, network_manager.get_parent().name, bandwidth])

func disconnect_node(network_manager) -> void:
	if network_manager in connected_nodes:
		groups[connected_nodes[network_manager]["group"]].erase(network_manager)
		connected_nodes.erase(network_manager)
		#print_debug("%s disconnected from %s" % [get_parent().name, network_manager.get_parent().name])

func is_network_manager_connected(network_manager):
	if network_manager == null:
		#print_debug("Error: %s does not have a NetworkManager" % [network_manager.get_parent().name])
		return false

	# Проверяем, подключен ли целевой узел
	if network_manager not in connected_nodes:
		#print_debug("Error: %s is not connected to %s" % [get_parent().name, network_manager.get_parent().name])
		return false
	return true
	

func send_message_in_group(group_name: String, message: Message) -> void:
	if groups.get(group_name) == null:
		return
	
	for to_network_manager in groups.get(group_name):
		await send_message(to_network_manager.get_parent(), message)

func send_message(to_node: Node, message: Message, tcp: bool = use_tcp) -> void:
	if to_node == null or message == null:
		return
	
	var from_node = get_parent()
	var to_network_manager = to_node.get_node("NetworkManager")
	
	var transmission_speed = get_parent().CONFIG.get("bandwidth", 10e3)
	
	if not is_network_manager_connected(to_network_manager):
		return
		
	transmission_speed = connected_nodes[to_network_manager].transmission_speed

	#print_debug("%s is starting to send message %s to %s (%s)" % [from_node.name, message.message_id, to_node.name, message.payload])

	for packet in message.packets:
		packet.sender_id = from_node.name
		# Отправляем каждый пакет отдельно
		#print_debug("%s is sending packet %d of message %s to %s" % [from_node.name, packet.sequence_number, packet.message_id, to_node.name])

		send_packet(to_network_manager, packet, transmission_speed)
	
	if tcp:
		# Добавляем сообщение в pending_acks после отправки всех пакетов
		#print(get_parent(), " ", len(pending_acks))
		
		pending_acks[message.message_id] = {
			"message": message,
			"to_network_manager": to_network_manager,
			"timeout": Time.get_ticks_usec() + int(ACK_TIMEOUT * 1e6)
		}
		retry_counts[message.message_id] = retry_counts.get(message.message_id, 0)
		

func _deliver_packet(packet_info: Dictionary):
	var to_network_manager = packet_info["to_node"].get_node("NetworkManager")
	var packet = packet_info["packet"]
	var from_node = packet_info["from_node"]
	var to_node = packet_info["to_node"]

	# Здесь передаем пакет в соответствующий узел
	to_network_manager.receive_packet(to_node, from_node, packet)
	#print_debug("Packet %d of message %s delivered from %s to %s" % [packet.sequence_number, packet.message_id, from_node.name, to_node.name])

func is_packet_lost(to_node: Node, from_node: Node, packet: Packet):
	# Рассчитываем уровень полученной мощности сигнала
	var node_network = from_node.network_manager
	var distance = global_position.distance_to(from_node.global_position) - 5
	#var my_power_dbm = interference.calculate_received_power(distance, self.transmit_power_dbm, self.frequency, self.noise_figure)
	
	var received_power_dbm = interference.calculate_received_power(distance, node_network.transmit_power_dbm, node_network.frequency, node_network.noise_figure)
													
	#print(distance, " ", transmit_power_dbm,  " ", frequency, " ",  noise_figure, " ",  path_loss_exponent)
	#print_debug("Calculated received power at %s: %f dBm" % [to_node.name, received_power_dbm])

	# Проверяем, превышает ли полученная мощность чувствительность приемника
	if received_power_dbm < receiver_sensitivity_dbm:
		#print_debug("Packet %d of message %s from %s to %s lost due to low signal power (%f dBm) / (%f dBm)" % [packet.sequence_number, packet.message_id, from_node.name, to_node.name, received_power_dbm, receiver_sensitivity_dbm])
		return true
	
	return false

func _handle_received_packet(from_node: Node, packet: Packet) -> void:
	var message_id = packet.message_id
	
	if message_id not in received_packets:
		received_packets[message_id] = []

	received_packets[message_id].append(packet)

	# Проверяем, получены ли все пакеты
	if len(received_packets[message_id]) == packet.total_packets:
		# Собираем сообщение
		var message = await _assemble_message(received_packets[message_id])
		emit_signal("message_received", get_parent(), from_node, message)

		# Отправка ACK только после получения всех пакетов сообщения
		if use_tcp:
			send_ack(from_node, message.message_id)
		
		# Очищаем данные о пакетах
		clear_message(message.message_id)
		

func send_ack(to_node: Node, message_id: String) -> void:
	var ack_packet = Packet.new(message_id, 0, 1, {"ACK": true}, ACK_SIZE, self.get_parent().name)
		
	# Отправляем ACK пакет напрямую без ожидания подтверждения
	var from_node = get_parent()
	var to_network_manager = to_node.get_node("NetworkManager")
	
	var transmission_speed = connected_nodes.get(to_network_manager, {}).get("transmission_speed", 10e3)
	send_packet(to_network_manager, ack_packet, transmission_speed)

func _assemble_message(packets: Array) -> Message:
	# Предполагаем, что payload одинаков во всех пакетах
	var total_bits = 0
	for packet in packets:
		total_bits += packet.size_bits
	var message = Message.new(packets[0].message_id, total_bits, packets[0].payload)
	return message

func _calculate_propagation_delay(distance: float) -> float:
	# Рассчитываем задержку распространения на основе расстояния и скорости распространения сигнала
	var propagation_speed = 3e8  # Скорость света в вакууме (м/с)
	var delay = distance / propagation_speed
	return delay

func _calculate_transmission_delay(packet_size_bits: int, transmission_speed: float) -> float:
	# Рассчитываем задержку передачи на основе размера пакета и скорости передачи (бит/с)
	var delay = packet_size_bits / transmission_speed
	return delay

# Метод для широковещательной отправки сообщения всем подключенным узлам
func broadcast_message(message: Message) -> void:
	var from_node = get_parent()
	for to_network_manager in connected_nodes.keys():
		await send_message(to_network_manager.get_parent(), message)

func send_packet(to_network_manager: Node, packet: Packet, transmission_speed: float) -> void:
	var from_node = get_parent()
	var to_node = to_network_manager.get_parent()
	
	# Рассчитываем задержки
	var distance = global_position.distance_to(to_network_manager.global_position)
	var propagation_delay = _calculate_propagation_delay(distance)
	var transmission_delay = _calculate_transmission_delay(packet.size_bits, transmission_speed)
	var total_delay = propagation_delay + transmission_delay
	
	# Рассчитываем ожидаемое время доставки
	var expected_delivery_time = Time.get_ticks_usec() + int(total_delay * 1e6)  # Переводим в микросекунды
	
	# Добавляем пакет в очередь
	to_network_manager.packets_queue.append({
		"packet": packet,
		"from_node": from_node,
		"to_node": to_node,
		"expected_delivery_time": expected_delivery_time
	})

	emit_signal("packet_sent", to_node, from_node, packet)
	
	# Если используем TCP и пакет является финальным, ожидаем подтверждение для всего сообщения
	# Удаляем эту часть, так как подтверждение теперь по сообщению, а не по пакету

func receive_packet(to_node: Node, from_node: Node, packet: Packet) -> void:
	if is_packet_lost(to_node, from_node, packet):
		emit_signal("packet_lost", to_node, from_node, packet)
		return
	
	#print_debug("Packet %d of message %s received by %s from %s" % [packet.sequence_number, packet.message_id, to_node.name, from_node.name])
	emit_signal("packet_received", to_node, from_node, packet)
	
	if packet.payload.get("ACK"):
		_recive_ack(to_node, from_node, packet)
		return
		
	_handle_received_packet(from_node, packet)
	
	if not use_tcp:
		if packet.is_final:
			final_packet_times[packet.message_id] = Time.get_ticks_usec() / 1e6
		elif packet.sequence_number != len(received_packets.get(packet.message_id, [])) + 1:
			_drop_message(packet.message_id, "Missing packet in UDP mode")
			return

func _drop_message(message_id: String, reason: String):
	#print_debug("%s] Message %s dropped due to: %s" % [get_parent().name, message_id, reason])
	
	emit_signal("message_dropped", message_id, reason)
	clear_message(message_id)

func clear_message(message_id: String):
	if message_id in received_packets:
		#for packet in received_packets.get(message_id, []):
			#retry_counts.erase(packet.sequence_number)
			#pending_acks.erase(packet.sequence_number)
			
		received_packets.erase(message_id)
		
	if message_id in final_packet_times:
		final_packet_times.erase(message_id)
#		Возможно ошибка

	if message_id in retry_counts:
		retry_counts.erase(message_id)
	if message_id in pending_acks:
		pending_acks.erase(message_id)


func _recive_ack(to_node: Node, from_node: Node, packet: Packet):
	#print_debug("Received ACK for message %s from %s to %s" % [packet.message_id, from_node.name, to_node.name])
	var message_id = packet.message_id
	emit_signal("ack_received", to_node, from_node, message_id)

	# Удаляем из ожидаемых ACK
	if message_id in pending_acks:
		pending_acks.erase(message_id)
		retry_counts.erase(message_id)

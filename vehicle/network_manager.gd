extends Node2D
class_name NetworkManager

# Константы
const RETRY_LIMIT = 3  # Максимальное количество попыток повторной отправки пакета
const FINAL_PACKET_TIMEOUT = 10.0  # Максимальное время ожидания финального пакета в секундах
const ACK_TIMEOUT = 5.0  # Время ожидания подтверждения (ACK) в секундах

const ACK_SIZE = 10 # бит

# Сигналы для отправки и получения пакетов
signal packet_sent(to_node: Node, from_node: Node, packet: Packet)
signal packet_received(to_node: Node, from_node: Node, packet: Packet)
signal packet_lost(to_node: Node, from_node: Node, packet: Packet)
signal ack_received(to_node: Node, from_node: Node, packet: Packet)
signal message_received(to_node: Node, from_node: Node, message: Message)
signal message_dropped(message_id: String, reason: String)

@export
var interference: Interference

var receiver_sensitivity_dbm: float = 0.0

var transmit_power_dbm: float

var frequency: float

var noise_figure: float

var path_loss_exponent: float = 2.0

@export
var use_tcp: bool = true  # Переключатель для работы в режимах TCP (true) или UDP (false)

var connected_nodes = {}  # Словарь для хранения подключенных узлов и их скоростей передачи
var received_packets = {}  # Хранит полученные пакеты по message_id
var packets_queue = []
var pending_acks = {}  # Хранит ожидаемые подтверждения (ACK) по packet_id
var retry_counts = {}  # Количество попыток повторной отправки для каждого packet_id
var final_packet_times = {}  # Время последнего принятого пакета для каждого сообщения
var groups = {}


func _init_(receiver_sensitivity_dbm, transmit_power_dbm, frequency, noise_figure, path_loss_exponent) -> void:
	self.receiver_sensitivity_dbm = receiver_sensitivity_dbm
	self.transmit_power_dbm = transmit_power_dbm
	self.frequency = frequency
	self.noise_figure = noise_figure
	self.path_loss_exponent = path_loss_exponent

func _ready() -> void:
	connect("message_received", _on_message_received)


func _process(delta):
	var current_time = Time.get_ticks_usec()  # Текущее время в микросекундах
	
	# Обрабатываем очередь пакетов
	for i in range(packets_queue.size()):
		var packet_info = packets_queue[i]
		
		# Проверяем, настало ли время для обработки пакета
		if current_time >= packet_info["expected_delivery_time"]:
			_deliver_packet(packet_info)
			packets_queue.remove_at(i)
			pending_acks.erase(packet_info.packet.sequence_number)
			break

	# Проверка истекших ожиданий ACK
	for packet_id in pending_acks.keys():
		var ack_info = pending_acks[packet_id]
		if current_time >= ack_info["timeout"]:
			# Проверка лимита повторных попыток
			if retry_counts[packet_id] >= RETRY_LIMIT:
				var message_id = ack_info["packet"].message_id
				_drop_message(message_id, "Exceeded retry limit")
				break

			# Повторная отправка пакета при истечении таймаута
			var packet = ack_info["packet"]
			var to_network_manager = ack_info["to_network_manager"]
			_print_debug("ACK timeout reached for packet %d of message %s. Resending..." % [packet.sequence_number, packet.message_id])
			await send_packet(to_network_manager, packet, ack_info["transmission_speed"])
			pending_acks.erase(packet_id)
			retry_counts[packet_id] += 1  # Увеличиваем количество повторных попыток

	# Проверка времени ожидания финального пакета
	for message_id in final_packet_times.keys():
		if (current_time / 1e6) - final_packet_times[message_id] >= FINAL_PACKET_TIMEOUT:
			_drop_message(message_id, "Final packet timeout exceeded")


func _print_debug(string:String):
	return
	print(string)


func has_connection_with_group(group_name: String):
	for _key in connected_nodes.keys():
		if connected_nodes[_key].group == group_name:
			return true
	
	return false

func connect_to_node(network_manager, transmission_speed: float, group: String) -> void:
	if network_manager not in connected_nodes:
		if groups.get(group) == null:
			groups[group] = []
		
		groups[group].append(network_manager)
		
		connected_nodes[network_manager] = {"transmission_speed": transmission_speed, "group": group}
		_print_debug("%s connected to %s with transmission_speed %f bps" % [get_parent().name, network_manager.get_parent().name, transmission_speed])

func disconnect_node(network_manager) -> void:
	if network_manager in connected_nodes:
		groups[connected_nodes[network_manager]["group"]].erase(network_manager)
		connected_nodes.erase(network_manager)
		_print_debug("%s disconnected from %s" % [get_parent().name, network_manager.get_parent().name])

func is_network_manager_connected(network_manager):
	if network_manager == null:
		_print_debug("Error: %s does not have a NetworkManager" % [network_manager.get_parent().name])
		return false

	# Проверяем, подключен ли целевой узел
	if network_manager not in connected_nodes:
		_print_debug("Error: %s is not connected to %s" % [get_parent().name, network_manager.get_parent().name])
		return false
	return true
	

func send_message_in_group(group_name: String, message: Message) -> void:
	if groups.get(group_name) == null:
		return
	
	for to_network_manager in groups.get(group_name):
		await send_message(to_network_manager.get_parent(), message)


func send_message(to_node: Node, message: Message) -> void:
	var from_node = get_parent()
	var to_network_manager = to_node.get_node("NetworkManager")
	
	if not is_network_manager_connected(to_network_manager):
		return

	var transmission_speed = connected_nodes[to_network_manager].transmission_speed

	_print_debug("%s is starting to send message %s to %s" % [from_node.name, message.message_id, to_node.name])

	for packet in message.packets:
		packet.sender_id = from_node.name
		# Отправляем каждый пакет отдельно
		_print_debug("%s is sending packet %d of message %s to %s" % [from_node.name, packet.sequence_number, packet.message_id, to_node.name])
		await send_packet(to_network_manager, packet, transmission_speed)



func _deliver_packet(packet_info: Dictionary):
	var to_network_manager = packet_info["to_node"].get_node("NetworkManager")
	var packet = packet_info["packet"]
	var from_node = packet_info["from_node"]
	var to_node = packet_info["to_node"]

	# Здесь передаем пакет в соответствующий узел
	to_network_manager.receive_packet(to_node, from_node, packet)
	_print_debug("Packet %d of message %s delivered from %s to %s" % 
		[packet.sequence_number, packet.message_id, from_node.name, to_node.name])


func is_packet_lost(to_node: Node, from_node: Node, packet: Packet):
	# Рассчитываем уровень полученной мощности сигнала
	
	var distance = global_position.distance_to(from_node.global_position)
	var received_power_dbm = interference.calculate_received_power(distance, transmit_power_dbm, frequency, 
													noise_figure, path_loss_exponent)

	#print(distance, " ", transmit_power_dbm,  " ", frequency, " ",  noise_figure, " ",  path_loss_exponent)
	_print_debug("Calculated received power at %s: %f dBm" % [to_node.name, received_power_dbm])

	# Проверяем, превышает ли полученная мощность чувствительность приемника
	if received_power_dbm < receiver_sensitivity_dbm:
		_print_debug("Packet %d of message %s from %s to %s lost due to low signal power (%f dBm)" %
			  [packet.sequence_number, packet.message_id, from_node.name, to_node.name, received_power_dbm])
		return true
	
	return false


func _handle_received_packet(from_node: Node, packet: Packet) -> void:
	var message_id = packet.message_id
	if message_id not in received_packets:
		received_packets[message_id] = []
		_print_debug("%s started receiving message %s" % [get_parent().name, message_id])

	received_packets[message_id].append(packet)
	_print_debug("%s has received %d/%d packets for message %s" % [get_parent().name, len(received_packets[message_id]), packet.total_packets, message_id])

	# Проверяем, получены ли все пакеты
	if len(received_packets[message_id]) == packet.total_packets:
		# Собираем сообщение
		var message = _assemble_message(received_packets[message_id])
		emit_signal("message_received", get_parent(), from_node, message)
		_print_debug("%s has assembled the full message %s from %s" % [get_parent().name, message_id, from_node.name])
		# Очищаем данные о пакетах
		received_packets.erase(message_id)

func _assemble_message(packets: Array) -> Message:
	# Предполагаем, что payload одинаков во всех пакетах
	var total_bits = 0
	for packet in packets:
		total_bits += packet.size_bits
	var message = Message.new(total_bits, packets[0].payload)
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
	packets_queue.append({
		"packet": packet,
		"from_node": from_node,
		"to_node": to_node,
		"expected_delivery_time": expected_delivery_time
	})
	_print_debug("Packet %d of message %s queued for delivery after %f seconds" % 
		[packet.sequence_number, packet.message_id, total_delay])

	emit_signal("packet_sent", to_node, from_node, packet)
	
	# Если TCP, ждем подтверждение (ACK)
	if use_tcp:
		var ack_timeout = expected_delivery_time + (ACK_TIMEOUT * 1e6)  # Устанавливаем таймаут на ожидание ACK
		pending_acks[packet.sequence_number] = {
			"packet": packet,
			"to_network_manager": to_network_manager,
			"timeout": ack_timeout,
			"transmission_speed": transmission_speed
		}
		retry_counts[packet.sequence_number] = 0  # Инициализируем счетчик повторных попыток

func receive_packet(to_node: Node, from_node: Node, packet: Packet) -> void:
	if is_packet_lost(to_node, from_node, packet):
		emit_signal("packet_lost", to_node, from_node, packet)
		return
	
	_print_debug("Packet %d of message %s received by %s from %s" % [packet.sequence_number, packet.message_id, to_node.name, from_node.name])
	emit_signal("packet_received", to_node, from_node, packet)
	_handle_received_packet(from_node, packet)
	
	# Если TCP, отправляем ACK
	if use_tcp:
		send_message(to_node, Message.new(ACK_SIZE, {"ACK": true, "packet": packet}, 1))
	else:
		# В режиме UDP проверяем потерю финального пакета
		if packet.is_final:
			final_packet_times[packet.message_id] = Time.get_ticks_usec() / 1e6
		elif packet.sequence_number != len(received_packets.get(packet.message_id, [])) + 1:
			_drop_message(packet.message_id, "Missing packet in UDP mode")
			return

func _drop_message(message_id: String, reason: String):
	print_debug("Message %s dropped due to: %s" % [message_id, reason])
	emit_signal("message_dropped", message_id, reason)
	if message_id in received_packets:
		received_packets.erase(message_id)
	if message_id in final_packet_times:
		final_packet_times.erase(message_id)
	retry_counts.clear()
	pending_acks.clear()

func _recive_ack(to_node: Node, from_node: Node, packet: Packet):
	_print_debug("Sending ACK for packet %d of message %s from %s to %s" % [packet.sequence_number, packet.message_id, to_node.name, from_node.name])
	emit_signal("ack_received", to_node, from_node, packet)

	# Удаляем из ожидаемых ACK
	if packet.sequence_number in pending_acks:
		from_node.pending_acks.erase(packet.sequence_number)
		from_node.retry_counts.erase(packet.sequence_number)
		

func _on_message_received(to_node: Node, from_node: Node, message: Message) -> void:
	if message.payload.get("ACK") and message.payload.get("packet"):
		_recive_ack(to_node, from_node, message.payload.get("packet"))

# Message.gd
extends Resource

class_name Message

var message_id: String
var total_bits: int
var payload: Dictionary
var packets: Array = []

func _init(total_bits: int, payload: Dictionary, total_packets:int = 3):
	self.message_id = _generate_message_id()
	self.total_bits = total_bits
	self.payload = payload
	_packetize(total_packets)

func _generate_message_id() -> String:
	return "MSG_" + str(Time.get_unix_time_from_system())

func _packetize(total_packets: int):
	packets = []
	
	var packet_size_bits = float(total_bits)/total_packets
	for i in range(total_packets):
		var packet = Packet.new(
			message_id,
			i,
			total_packets,
			payload,
			packet_size_bits,
			""  # sender_id будет установлен при отправке
		)
		packets.append(packet)

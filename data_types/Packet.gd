# Packet.gd
extends Resource

class_name Packet

var message_id: String
var sequence_number: int
var total_packets: int
var payload: Dictionary
var size_bits: int
var sender_id: String

func _init(message_id: String, sequence_number: int, total_packets: int, payload: Dictionary, size_bits: int, sender_id: String):
	self.message_id = message_id
	self.sequence_number = sequence_number
	self.total_packets = total_packets
	self.payload = payload
	self.size_bits = size_bits
	self.sender_id = sender_id

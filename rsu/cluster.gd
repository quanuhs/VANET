extends Node
class_name Cluster
# ПЕРЕПИСАТЬ, СДЕЛАТЬ БОЛЕЕ GENERIC!


@export
var use_cluster = true

@export
var cluster_depth = 1

@export
var network_manager:NetworkManager


func ask_in_cluster(message: Message):
	var depth = message.payload.get("depth", 0)
	
	if depth >= cluster_depth:
		return false
	
	message.payload["depth"] = depth + 1
	var networks = network_manager.groups.get("RSU", [])
	message.payload["resend"] = message.payload.get("resend", [])
	
	message.payload["resend"].append(get_parent())
	
	network_manager.send_message_in_group("RSU", message)
	return true

class_name RSU
extends Node2D



# Очередь из машин. Все машины, которые могут быть подключены
var queue = []

# Память устройства
var memory = []

# другие устйроства в кластере
var cluster = []

# Подключения
var connectors:Array = []
signal drop_connection(vehicle)

func _process(delta):
	check_for_connector()


func check_for_connector():
	for connector in connectors:
		if connector.is_free():
			connect_vehicle(get_queue_vehicle(), connector)


func get_queue_vehicle():
	return queue.pop_at(0)


func connect_vehicle(vehicle, connector:Connector):
	if vehicle == null:
		return false
	
	connector.vehicle = vehicle


func queue_add(vehicle):
	queue.append(vehicle)


func queue_remove(vehicle):
	queue.erase(vehicle)
	

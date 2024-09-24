extends Node
class_name Memory

var store = {}

signal found(memory_id: int)
signal not_found(memory_id: int)

func retrive(memory_id: int):
	var information = store.get(memory_id)
	if information == null:
		emit_signal("not_found", memory_id)
		return
	
	emit_signal("found", memory_id)
	print("REQUESTED")
	return information


func put(memory_id: int, information: Dictionary, date = Time.get_ticks_msec()):
	information["date"] = date
	store[memory_id] = information



func update(memory_id: int, information: Dictionary, date = Time.get_ticks_msec()):
	var old_information = store.get(memory_id)
	
	if old_information != null:
		if date < old_information["date"]:
			return
	
	put(memory_id, information, date)

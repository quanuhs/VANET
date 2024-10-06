extends Node
class_name Memory

var store = {}
var total_size = 0
const MAX_SIZE = 8*1024*1024*1024

signal found(memory_id: int)
signal not_found(memory_id: int)

func retrive(memory_id: int):
	var information = store.get(memory_id)
	if information == null:
		emit_signal("not_found", memory_id)
		return
	
	emit_signal("found", memory_id)
	return information


func put(memory_id: int, size:int, information: Dictionary, date = Time.get_ticks_msec()):
	total_size += size
	
	#if total_size > MAX_SIZE:
		#print("CLEANING")
		#var store_keys = store.keys()[0]
		#var _index = 0
		#while total_size > MAX_SIZE:
			#store.erase(store_keys[_index])
			#_index += 1
			
	information["date"] = date
	information["size"] = size
	store[memory_id] = information


func update(memory_id: int, size:int, information: Dictionary, date = Time.get_ticks_msec()):
	var old_information = store.get(memory_id)
	
	if old_information != null:
		if date < old_information["date"]:
			return
	
	put(memory_id, size, information, date)

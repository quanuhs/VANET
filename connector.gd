extends Node
class_name Connection



var connected_with: Connection = null
var vehicle = null

func is_busy():
	return vehicle != null
	
func is_free():
	return vehicle == null

func request(who, when):
	pass
	


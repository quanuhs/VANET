extends Node
class_name Connector


var connected_with: Connector = null

func is_busy():
	return true
	
func is_free():
	return true

func request(who, when):
	pass

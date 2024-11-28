extends Area2D
class_name DeviceArea

@export
var network_manager: NetworkManager

@export
var shape: CollisionShape2D

var radius = 1

func set_radius(radius):
	self.radius = radius
	shape.radius = radius

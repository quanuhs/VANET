extends Node2D

@export var vehicle: VehicleBase
@export var icon: Sprite2D


func _ready() -> void:
	icon.scale.x = 1/(icon.texture.get_width()/vehicle.vehicle_length)
	icon.scale.y = icon.scale.x


func _draw() -> void:
	draw_circle(Vector2.ZERO, vehicle.vehicle_length+vehicle.allowed_distance_to_next, Color.RED, false)
	draw_circle(Vector2.ZERO, vehicle.network_manager.radius, vehicle.line_color, false)
	

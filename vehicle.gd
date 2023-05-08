extends KinematicBody2D

var rng = RandomNumberGenerator.new()

var velocity = Vector2.ZERO
var target_position = Vector2.ZERO
var starting_position = Vector2.ZERO
var speed = 0
var path = []
var memory = []
var memory_indexes = []

var connected_rsu = null

var requested_index = 0
var total_requests = 0

signal destination_reached(body)
signal service_ended

onready var nav:Navigation2D = get_parent().get_navigation()


func export_data():
	return [str(get_instance_id()), str(speed), str(total_requests), str(memory_indexes.size()), str(starting_position.x), str(starting_position.y), str(target_position.x), str(target_position.y)]

func _draw():
	draw_circle(Vector2.ZERO, 10, Color(0.4, 0.4, 0.4, 0.5))


func _ready():
	rng.randomize()
	speed = rng.randfn(Global.vehicle_speed_mean, Global.vehicle_speed_deviation)
	memory.resize(Global.memory_amount)


func _physics_process(delta):
	if path.size() > 0:
		move_to_point()


func set_random_position(_objects:Array, _map:TileMap):
	position = _map.map_to_world(_objects[rng.randi_range(0, _objects.size()-1)])
	starting_position = position


func set_random_point(_objects:Array, _map:TileMap):
	target_position = _map.map_to_world(_objects[rng.randi_range(0, _objects.size()-1)])


func set_memory(memory_min, memory_max):
	total_requests = rng.randi_range(memory_min, memory_max-1)
	for i in range(total_requests):
		memory[i] = 1
	
	memory.shuffle()
	for i in range(memory.size()):
		if memory[i] == 1:
			memory_indexes.append(i)
	
	requested_index = memory_indexes[0]
	$Label.text = str(memory_indexes.size())


func recive_response():
	if requested_index != null:
		memory[requested_index] = 0
	
	$Label.text = str(memory_indexes.size())
	
	if not check_if_requests_empty():
		requested_index = memory_indexes.pop_at(0)


func send_request():
	if not check_if_requests_empty():
		return requested_index


func check_if_requests_empty():
	
	if requested_index == null:
		
		$CollisionShape2D.queue_free()
		
		if connected_rsu:
			connected_rsu.stop_service()
		
		yield(get_tree(), "idle_frame")
		change_color_status(2)
		return true
	
	return false



func stop_service(rsu):
	if connected_rsu == rsu:
		connected_rsu = null
	
	emit_signal("service_ended")


func change_color_status(status:int):
	var _color_list = [Color.white, Color.orange, Color.green]
	$Sprite.set_modulate(_color_list[status])




func move():
	get_point_path(target_position)


func move_to_point():
	if position.distance_to(path[0]) <= 8:
		path.remove(0)
		if path.size() == 0:
			emit_signal("destination_reached", self)
			if connected_rsu:
				connected_rsu.stop_service()
			queue_free()
	else:
		var direction = position.direction_to(path[0])
		velocity = direction * speed
		move_and_slide(velocity)


func get_point_path(target_position):
	path = nav.get_simple_path(position, target_position, false)

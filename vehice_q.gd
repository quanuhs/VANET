extends KinematicBody2D

var rng = RandomNumberGenerator.new()

var velocity = Vector2.ZERO
var target_position = Vector2.ZERO
var starting_position = Vector2.ZERO
var speed = 0
var path = []

var memory = []
var memory_indexes = []

var awaiting_response = false

var connected_rsu = null

var requested_index = 0
var total_requests = 0

signal destination_reached(body)
signal service_ended

onready var nav:Navigation2D = get_parent().get_navigation()


func export_data():
	return [str(get_instance_id()), str(speed), str(total_requests), str(memory_indexes.size())]

func _draw():
	draw_circle(Vector2.ZERO, 10, Color(0.4, 0.4, 0.4, 0.5))
	
	if connected_rsu:
		draw_line(Vector2.ZERO, connected_rsu.position - self.position, Color.red, 2.0)


func _init():
	rng.randomize()
	speed = rng.randfn(Global.vehicle_speed_mean, Global.vehicle_speed_deviation)
	memory.resize(Global.memory_amount)


var wait_request_time = OS.get_ticks_msec()
var will_recive_time = OS.get_ticks_msec()

func _process(delta):
	
	if awaiting_response:
		if will_recive_time - OS.get_ticks_msec() <= 0:
			_get_response()
	else:
		if wait_request_time - OS.get_ticks_msec() <= 0:
			wait_request_time = OS.get_ticks_msec() + Global.wait_request
			ask_rsu()
	
	update()


func _physics_process(delta):
	if path.size() > 0:
		move_to_point()


func ask_rsu():
	if connected_rsu == null:
		return
	
	connected_rsu.ask_data(self, requested_index)


func set_random_position(_objects:Array, _map:TileMap):
	position = _map.map_to_world(_objects[rng.randi_range(0, _objects.size()-1)])
	starting_position = position


func set_random_point(_objects:Array, _map:TileMap):
	target_position = _map.map_to_world(_objects[rng.randi_range(0, _objects.size()-1)])


func set_memory(memory_min, memory_max):
	total_requests = rng.randi_range(memory_min, memory_max)
	for i in range(total_requests):
		memory[i] = 1
	
	memory.shuffle()
	for i in range(memory.size()):
		if memory[i] == 1:
			memory_indexes.append(i)
	
	requested_index = memory_indexes.pop_at(0)
	$Label.text = str(memory_indexes.size())
	


func _get_response():
	
	awaiting_response = false
	
	if connected_rsu == null:
		return
	
	if requested_index != null:
		memory[requested_index] = 0
		
	connected_rsu.log_vehicle_data(self, true)
	$Label.text = str(memory_indexes.size())
	
	if not check_if_requests_empty():
		requested_index = memory_indexes.pop_at(0)
	

func recive_response(when):
	awaiting_response = true
	will_recive_time = when


func check_if_requests_empty():
	if requested_index == null or len(memory_indexes) == 0:
		
		$CollisionShape2D.queue_free()
		
		if connected_rsu:
			stop_service(connected_rsu)
			emit_signal("destination_reached", self)
			queue_free()
		
		return true
	
	return false


func start_service(rsu):
	if connected_rsu != rsu and connected_rsu != null:
		stop_service(connected_rsu)
		yield(self, "service_ended")
	
	connected_rsu = rsu


func stop_service(rsu):
	if connected_rsu == rsu:
		if awaiting_response:
			rsu.memory_time[requested_index] -= max(0, will_recive_time-OS.get_ticks_msec())
			connected_rsu.log_vehicle_data(self, false)
			
		connected_rsu = null
			
	if len(memory_indexes) == 0:
		change_color_status(2)
	
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
				stop_service(connected_rsu)
			queue_free()
	else:
		var direction = position.direction_to(path[0])
		velocity = direction * speed
		move_and_slide(velocity)


func get_point_path(target_position):
	path = nav.get_simple_path(position, target_position, false)

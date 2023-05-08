extends Area2D


enum status {wait_for_vehicle, recive_request, send_response, ask_server, ask_claster}

var current_stage = 0
var current_vehicle = null
var memory = []
var current_memory_index = 0

var claster = []
var claster_index = 0

var delivered_data = {}
var requested_data = {}


func _ready():
	for i in range(Global.memory_amount):
		memory.append(0)


func _draw():
	draw_circle(Vector2.ZERO, Global.RSU_radius, Color(0.2, 0.5, 0.5, 0.5))


func set_radius(radius):
	$CollisionShape2D.shape.radius = radius
	#$CollisionShape2D.shape.extents = Vector2.ONE * radius


func stop_service():
	current_stage = status.wait_for_vehicle
	$Timer.stop()
	
	var remember_vehicle = current_vehicle
	remember_vehicle.change_color_status(0)
	
	
	remember_vehicle.stop_service(self)
	yield(remember_vehicle, "service_ended")
	current_vehicle = null
	
	check_for_vehicles(remember_vehicle)


func check_for_vehicles(last_vehicle=null):
		
	for body in self.get_overlapping_bodies():
		if body.is_in_group("vehicle") and body != last_vehicle:
			if body.requested_index != null:
				set_current_vehicle(body)
				return



func get_vehicle_request():
	if current_vehicle == null:
		return
	
	current_memory_index = current_vehicle.send_request()
	
	if current_memory_index == null:
		return
		
	log_vehicle_data(false, true)
	
	if memory[current_memory_index] > 0:
		memory[current_memory_index] -= 1
		current_stage = status.send_response
		$Timer.start(Global.wait_response)
		return
	
	if Global.use_claster:
		current_stage = status.ask_claster
		if Global.wait_ask_claster > 0:
			$Timer.start(Global.wait_ask_claster)
		else:
			ask_claster()
	else:
		ask_server()


func ask_claster():
	if claster_index >= claster.size():
		claster_index = 0
		ask_server()
		return
	
	var claster_rsu = claster[claster_index]
	
	if claster_rsu.memory[current_memory_index] > 0:
		current_stage = status.send_response
		claster_index = 0
		$Timer.start(Global.wait_response)
		return
	else:
		claster_index += 1
		current_stage = status.ask_claster
		if Global.wait_ask_claster > 0:
			$Timer.start(Global.wait_ask_claster)
		else:
			ask_claster()


func log_vehicle_data(deliver:bool = false, request:bool = false):
	if current_vehicle == null:
		return
	
	var vehicle_id = current_vehicle.get_instance_id()
	
	if delivered_data.get(vehicle_id) == null:
		delivered_data[vehicle_id] = 0
		requested_data[vehicle_id] = 0
	
	if deliver:
		delivered_data[vehicle_id] += 1
	
	if request:
		requested_data[vehicle_id] += 1


func send_vehicle_response():
	log_vehicle_data(true)
	current_vehicle.recive_response()
	current_stage = status.recive_request
	$Timer.start(Global.wait_request)

func get_server_answer():
	memory[current_memory_index] = Global.time_to_live
	current_stage = status.send_response
	$Timer.start(Global.wait_response)


func ask_server():
	current_stage = status.ask_server
	$Timer.start(Global.wait_ask_server)


func check_stage():
	if current_stage == status.wait_for_vehicle:
		return

	if current_stage == status.recive_request:
		get_vehicle_request()
		
	elif current_stage == status.send_response:
		send_vehicle_response()
	
	elif current_stage == status.ask_server:
		get_server_answer()
	
	elif current_stage == status.ask_claster:
		ask_claster()


func _on_Timer_timeout():
	check_stage()


func set_current_vehicle(vehicle):
	current_vehicle = vehicle
	current_vehicle.change_color_status(1)
	current_stage = status.recive_request
	current_vehicle.connected_rsu = self
	$Timer.start(Global.wait_request)


func _on_RsuArea_body_entered(body):
	if current_vehicle == null:
		if body.is_in_group("vehicle"):
			set_current_vehicle(body)


func _on_RsuArea_body_exited(body):
	if current_vehicle == body:
		stop_service()

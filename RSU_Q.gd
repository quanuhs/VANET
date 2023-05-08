extends Area2D


enum status {wait_for_vehicle, recive_request, send_response, ask_server, ask_claster}


var memory = []

# Запрашивается по сети
var memory_request = []

var memory_time = []

var claster = []
var claster_index = 0

var delivered_data = {}
var requested_data = {}

var energy = {"vehicles": 0, "claster": 0, "server": 0, }
var time_used = {"vehicles": [], "claster": [], "server": [], }
var start_time = OS.get_ticks_msec()

func _ready():
	$Label.hide()
	
	for i in range(Global.memory_amount):
		memory.append(0)
		memory_time.append(start_time)
		time_used.vehicles.append(0)
		time_used.claster.append(0)
		time_used.server.append(0)
	

func _process(delta):
	#for i in range(len(memory)):
	#	add_memory_time(i, 0)
	
	$Label.text = ""
	for _time in memory_time:
		var _res = _time - OS.get_ticks_msec()
		if _res < 0:
			_res = 0
		$Label.text += str(_res) + " "

func export_data():
	return [get_instance_id(), energy.vehicles, energy.claster, energy.server, time_used.vehicles.max(), time_used.claster.max(), time_used.server.max()]

func sum_enegry():
	var _sum = 0
	for _key in energy:
		_sum += energy[_key]
	
	return _sum

func _draw():
	draw_circle(Vector2.ZERO, Global.RSU_radius, Color(0.2, 0.5, 0.5, 0.5))


func answer_to_vehicle(vehicle, memory_index):
	send_vehicle_response(vehicle, memory_time[memory_index])

func add_memory_time(memory_index, additional_time):
	if memory_time[memory_index] - OS.get_ticks_msec() <= 0:
		memory_time[memory_index] = OS.get_ticks_msec()
	
	memory_time[memory_index] += additional_time

func ask_data(vehicle, memory_index):
	
	# Проверяем на количество одновременных подключений
	var _count = 0
	for _time in memory_time:
		if _time - OS.get_ticks_msec() > 0:
			_count += 1
	
	if _count >= Global.RSU_max_connections:
		return false
	
	# Если на момент запроса, ячейка уже занята
	if memory_time[memory_index] - OS.get_ticks_msec() > 0:
		return false
	
	
	# Запрос разрешен
	energy.vehicles += Global.RSU_energy_vehicle
	
	# Если в ячейке есть данные
	if memory[memory_index] > 0:
		memory[memory_index] -= 1
		add_memory_time(memory_index, Global.wait_response)
		
		time_used.vehicles[memory_index] += Global.wait_response

		send_vehicle_response(vehicle, memory_time[memory_index])
		return true
		
	else:
		# В ячейке нет данных
		if Global.use_claster:
			ask_claster(memory_index)
		else:
			ask_server(memory_index)
		return false
	
func set_radius(radius):
	$CollisionShape2D.shape.radius = radius


func stop_service(vehicle):	
	vehicle.change_color_status(0)
	
	vehicle.stop_service(self)
	yield(vehicle, "service_ended")


func ask_claster(memory_index):
	
	if claster_index >= claster.size():
		claster_index = 0
		ask_server(memory_index)
		return
	
	# Тратим энергию на запрос по кластеру
	energy.claster += Global.RSU_energy_claster
	
	var claster_rsu = claster[claster_index]

	if claster_rsu.memory[memory_index] > 0:
		memory[memory_index] = claster_rsu.memory[memory_index]
		
		claster_rsu.memory[memory_index] -= 1
		claster_index = 0
		return
		
	else:
		claster_index += 1
		add_memory_time(memory_index, Global.wait_ask_claster)
		time_used.claster[memory_index] += Global.wait_ask_claster
		ask_claster(memory_index)


func log_vehicle_data(vehicle, deliver:bool = false, request:bool = false):
	var vehicle_id = vehicle.get_instance_id()
	
	if delivered_data.get(vehicle_id) == null:
		delivered_data[vehicle_id] = 0
		requested_data[vehicle_id] = 0
	
	if deliver:
		delivered_data[vehicle_id] += 1
	
	if request:
		requested_data[vehicle_id] += 1


func send_vehicle_response(vehicle, when):
	vehicle.recive_response(when)


func ask_server(memory_index):
	energy.server += Global.RSU_enegry_server

	add_memory_time(memory_index, Global.wait_ask_server)
	time_used.server[memory_index] += Global.wait_ask_server
	memory[memory_index] = Global.time_to_live


func set_current_vehicle(vehicle):
	vehicle.start_service(self)
	vehicle.change_color_status(1)


func _on_RsuArea_body_entered(body):
	if body.is_in_group("vehicle"):
		set_current_vehicle(body)


func _on_RsuArea_body_exited(body):
	if body.is_in_group("vehicle"):
		stop_service(body)


func _on_RsuArea_input_event(viewport, event, shape_idx):
	print(event)


func _on_TextureButton_pressed():
	$Label.visible = not $Label.visible

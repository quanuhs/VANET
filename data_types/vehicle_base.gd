extends PathFollow2D
class_name VehicleBase

# СКОРОСТЬ м/c
var speed_mps = 18.0 
# ДОПУСТИМОЕ РАССТОЯНИЕ ДО СЛЕД. ТРАНСПОРТА
var allowed_distance_to_next = 3.0

# ДЛИНА ТРАНСПОРТА
var vehicle_length = 6.25


@export
var CONFIG = {
	"frequency": 5.9e9,
	"bandwidth": 10e6,
	"transmit_power_dbm": 20,
	"noise_figure": 9.0,
	"receiver_sensitivity_dbm": -85.0,
	"path_loss_exponent": 1.0,
	"vehicle_length": 6.25,
	"speed_mps": 18.0,
	"allowed_distance_to_next": 3.0,
	"range_radius_m": 300
}

@export 
var network_manager: NetworkManager

var current_speed = 0.0
var is_stopped: bool = false

var current_path_index = 0

var last_path2d: Path2D = null
var next_path2d: Path2D = null

var is_stopping: bool = false

var path: PackedInt64Array
var builder: Builder

var pixel_per_meter = 1.0  # Set this value from Loader

var astar: AStar2D

var line_color = Color.BLUE
var line_size = 1


# Сигналы
signal line_switched(new_line: Path2D)
signal reached_end_of_route()
signal vehicle_stopped()
signal vehicle_resumed()
signal vehicle_progressed(progress: float)


func _ready() -> void:
	CONFIG = CONFIG_GLOBAL.CONFIG.get("vehicle", CONFIG)
	
	network_manager._init_(CONFIG["receiver_sensitivity_dbm"], 
	CONFIG["transmit_power_dbm"], CONFIG["frequency"], 
	CONFIG["noise_figure"], 
	CONFIG["path_loss_exponent"])

	
	
	speed_mps = randf_range(CONFIG["speed_mps"]-0.25, CONFIG["speed_mps"]+0.25)
	allowed_distance_to_next = CONFIG["allowed_distance_to_next"]
	vehicle_length = CONFIG["vehicle_length"]
	
	network_manager.set_radius(CONFIG["range_radius_m"])
	#reached_end_of_route.connect(_on_reached_end_of_route)
	
	after_ready()


func after_ready():
	pass

func restart():
	set_process(true)
	position = Vector2.ZERO
	progress = 0.0


func stop():
	is_stopped = true
	emit_signal("vehicle_stopped")

func start():
	is_stopped = false
	emit_signal("vehicle_resumed")

func _on_reached_end_of_route():
	change_route(randi_range(1, astar.get_point_count()))

func get_line(path_index):
	if len(path) <= path_index + 1:
		#emit_signal("reached_end_of_route")
		return null
		
	return builder.find_path(path[path_index], path[path_index + 1])

func move_to_next_point():
	var this_path = get_line(current_path_index)
	var next_path = get_line(current_path_index + 1)
	
	if this_path:
		current_path_index += 1
		switch_line(this_path)
		restart()
	else:
		emit_signal("reached_end_of_route")
	
	if next_path:
		next_path2d = next_path
	#else:
		#emit_signal("reached_end_of_route")

func get_allowed_distance_to_next():
	var total_vehicle_length = vehicle_length * pixel_per_meter
	return allowed_distance_to_next * pixel_per_meter + total_vehicle_length

func switch_line(new_line: Path2D) -> void:
	if last_path2d:
		last_path2d.remove_child(self)
		
	last_path2d = new_line

	if last_path2d:
		last_path2d.add_child(self)
		emit_signal("line_switched", new_line)

func get_forward_vehicle(vehicle_progess, path2d: Path2D):
	var forward_vehicle = null
	
	if path2d == null:
		return null
	
	for vehicle:VehicleBase in path2d.get_children():
		if vehicle == self:
			continue
		
		# If we are ahead of the vehicle, skip
		if vehicle_progess > vehicle.progress_ratio:
			continue
		
		# If we are behind the vehicle
		if forward_vehicle == null:
			forward_vehicle = vehicle
			continue
		
		if vehicle.progress_ratio < forward_vehicle.progress_ratio:
			forward_vehicle = vehicle
		
	return forward_vehicle


func _physics_process(delta):
	# Convert speed from meters per second to pixels per second
	
	var lerp_speed = speed_mps * pixel_per_meter
	is_stopping = is_stopped
	
	var next_vehicle = get_forward_vehicle(progress_ratio, self.last_path2d)
	
	if next_vehicle:
		if next_vehicle.last_path2d != self.last_path2d:
			next_vehicle = null
	
	var on_next_line = false
	if next_vehicle == null:
		next_vehicle = get_forward_vehicle(0.0, self.next_path2d)
		if next_vehicle:
			on_next_line = true

	if next_vehicle:
		# Calculate total allowed distance considering vehicle sizes
		var distance_to_next = +INF
		
		if on_next_line:
			distance_to_next = self.last_path2d.curve.get_baked_length() - progress + next_vehicle.progress
		else:
			distance_to_next = next_vehicle.progress - progress
		
		if distance_to_next < get_allowed_distance_to_next():
			is_stopping = true
		
		# In case of spawning at the same place, randomly speed up one of the cars
		if distance_to_next <= 1 and randi_range(0, 10) > 2:
			lerp_speed = speed_mps * pixel_per_meter
	
	if is_stopping:
		lerp_speed = 0.0
	
	current_speed = lerp(current_speed, lerp_speed, 0.1)
	progress += current_speed * delta
	
	emit_signal("vehicle_progressed", progress_ratio)
	
	await get_tree().physics_frame
	if progress_ratio >= 0.99 or progress >= self.last_path2d.curve.get_baked_length():
		move_to_next_point()


func _continue_process():
	pass

func change_route(to_path_id):
	if to_path_id == 0:
		if len(path) == 0:
			reached_end_of_route.emit()
		
		return
		
	if len(path) >= current_path_index + 1 and current_path_index - 1 >= 0:
		var current = path[current_path_index]
		path = astar.get_id_path(path[current_path_index], to_path_id)
		current_path_index = 0


func change_route_keep():
	if len(path) > 0:
		change_route(path[-1])

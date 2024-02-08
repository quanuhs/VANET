extends Node2D


onready var nav = $Navigation2D
onready var road_map = $Navigation2D/RoadMap
onready var rsu_map = $RsuMap

var optimal_requests = 0

var _saved_data = {}
var _total_requests = 0.0
var _total_loss = 0.0
var _vehicles_count = 0

signal done(from, total_requests, total_loss, saved_data, rsu_enegry_result)
signal save_me(city)

func _ready():
	randomize()
	$Draw.connect("save_me", self, "_on_changes_made")

func get_maps():
	return [[road_map, 2], [road_map, 1], [rsu_map, 0], [road_map, 0]]

func get_cursor_map():
	return $CurrentMap

func get_navigation():
	return nav

func start_simulation():
	$Draw.stop_draw(true)
	setup_rsus()
	build_heat()
	setup_vehicles()
	start_vehicles()

func stop_simulation():
	remove_vehicles()
	remove_rsus()
	remove_rsu_vehicles()
	
	_saved_data = {}
	refresh_data()
	rsu_delivered.clear()
	$Draw.stop_draw(false)

func refresh_data():
	_saved_data = {}
	_total_requests = 0.0
	_total_loss = 0.0
	_vehicles_count = 0

func remove_vehicles():
	for vehicle in get_tree().get_nodes_in_group("vehicle"):
		vehicle.queue_free()
	

func remove_rsu_vehicles():
	for vehicle in get_tree().get_nodes_in_group("vehicleRSU"):
		vehicle.queue_free()

func remove_rsus():
	for chiled in $RsuMap.get_children():
		chiled.queue_free()


func setup_rsus_stationary_cluster(rsus_areas):
	rsus_areas.shuffle()
	var rsus_distances = []
	var rsus_indexes = []
	
	for i in range(len(rsus_areas)):
		rsus_distances.append([])
		rsus_indexes.append([])
		
		for j in range(len(rsus_areas)):
			if i == j:
				continue
			
			rsus_distances[i].append(rsus_areas[i].position.distance_to(rsus_areas[j].position))
			rsus_indexes[i].append(rsus_areas[j])
	
	
		# sort and select
		for x in range(len(rsus_distances[i])-1):
			if rsus_distances[i][x] > rsus_distances[i][x+1]:
				var keep_dist = rsus_distances[i][x+1]
				var keep_index = rsus_indexes[i][x+1]
				rsus_distances[i][x+1] = rsus_distances[i][x]
				rsus_distances[i][x] = keep_dist
				rsus_indexes[i][x+1] = rsus_indexes[i][x]
				rsus_indexes[i][x] = keep_index
	
		var line_color = Color(rand_range(0.1, 1), rand_range(0.1,1), rand_range(0.1,1))
		for x in range(len(rsus_distances[i])):
			if len(rsus_areas[i].claster) >= Global.RSU_claster_amount:
				break
			
			if len(rsus_indexes[i][x].claster) >= Global.RSU_claster_amount:
				continue
			
			rsus_indexes[i][x].claster.append(rsus_areas[i])
			rsus_areas[i].claster.append(rsus_indexes[i][x])
			
			if i < x or true:
				var line = Line2D.new()
				line.add_point(rsus_areas[i].position)
				line.add_point(rsus_indexes[i][x].position)
				line.set_width(2)
				line.set_default_color(line_color)
				$RsuMap.add_child(line)
		
		rsu_map.add_child(rsus_areas[i])


func setup_rsus_stationary(rsus_areas):
	for rsu in rsus_areas:
		rsu_map.add_child(rsu)

	
func setup_rsu_vehicles(vehicle_rsus):
	var general_points = road_map.get_used_cells_by_id(0)
	var starting_points = road_map.get_used_cells_by_id(2)
	var ending_points = road_map.get_used_cells_by_id(1)
	
	starting_points.shuffle()
	ending_points.shuffle()
	
	var _targets = ending_points
	
	for i in range(len(_targets)):
		_targets[i] = road_map.map_to_world(_targets[i])
	
	
	for vehicle_rsu in vehicle_rsus:
		_targets.shuffle()
		vehicle_rsu.set_random_position(starting_points, road_map)
		
		vehicle_rsu.targets = _targets
		self.add_child(vehicle_rsu)
		vehicle_rsu.move()
		

func setup_rsus():
	var rsu_vehicle_node = load("res://vehicleRSU.tscn")
	var rsu_area_node = load("res://RsuArea.tscn")
	var rsus = rsu_map.get_used_cells_by_id(1)
	for rsu in rsus:
		rsu_map.set_cellv(rsu, 0)
	
	rsus += rsu_map.get_used_cells_by_id(0)
	
	optimal_requests = (Global.vehicle_memory_max * Global.vehicles_amount)/(max(rsus.size(), 1))
	
	var result = []
	
	
	for i in range(Global.vehicle_RSU_amount):
		var rsu_area = rsu_area_node.instance()
		rsu_area.set_radius(Global.RSU_radius)
		
		var rsu_vehicle = rsu_vehicle_node.instance()
		rsu_vehicle.add_child(rsu_area)
		result.append(rsu_vehicle)
	
	setup_rsu_vehicles(result)


	
	result = []
	var rsus_areas = []
	for rsu in rsus:
		var rsu_area = rsu_area_node.instance()
		rsu_area.set_radius(Global.RSU_radius)
		
		rsu_area.position = rsu_map.map_to_world(rsu) + rsu_map.cell_size/2
		result.append(rsu_area)
			

	if Global.use_claster:
		setup_rsus_stationary_cluster(result)
	else:
		setup_rsus_stationary(result)



func get_map_config():
	var result = []
	var all_maps = get_maps()
	for i in range(len(all_maps)):
		var _map = all_maps[i][0]
		var index = all_maps[i][1]
		result.append([index, []])
		result[i][1].append_array(_map.get_used_cells_by_id(index))
	
	return result
	

func load_map_config(data):
	var all_maps = get_maps()
	for _map in all_maps:
		_map[0].clear()
		
	for i in range(len(all_maps)):
		for j in range(len(data[i][1])):
			all_maps[i][0].set_cellv(data[i][1][j], data[i][0])

	
	

func setup_vehicles():
	var vehicle_node = load("res://vehicle.tscn")
	var starting_points = road_map.get_used_cells_by_id(2)
	var ending_points = road_map.get_used_cells_by_id(1)
	var total_requests = 0
	for i in range(Global.vehicles_amount):
		var vehicle = vehicle_node.instance()
		vehicle.connect("destination_reached", self, "_on_car_reached_point")
		vehicle.set_random_position(starting_points, road_map)
		vehicle.set_random_point(ending_points, road_map)
		total_requests += vehicle.set_memory(Global.vehicle_memory_min, Global.vehicle_memory_max)
		
		self.add_child(vehicle)

	Global.total_requests = total_requests

func start_vehicles():
	get_tree().call_group("vehicle", "move")


func _on_car_reached_point(vehicle):
	_total_requests += vehicle.total_requests
	_total_loss += vehicle.memory_indexes.size()

	_saved_data[vehicle.get_instance_id()] = vehicle.export_data()
	_vehicles_count += 1
	
	if _vehicles_count == Global.vehicles_amount:
		on_done()

func on_done():
	# Считаем общую энергозатрату
	var _rsu_delivered = {}
	var _rsu_enegry_result = {}
	for rsu in get_tree().get_nodes_in_group("rsu"):
		_rsu_enegry_result[rsu.get_instance_id()] = rsu.export_data()
		_rsu_delivered[rsu.position] = rsu.get_delivered()
	
	emit_signal("done", self, _total_requests, _total_loss, _saved_data, _rsu_enegry_result, _rsu_delivered)
	

var rsu_delivered = {}


func get_heat_value():
	
	return optimal_requests * Global.limit
	#return float(rsu_delivered.values().max())
	#var _sum = 0
	#for _d in rsu_delivered.values():
	#	_sum += _d
	
	#return _sum


func build_heat():
	var max_value = get_heat_value()

	for rsu in get_tree().get_nodes_in_group("rsu"):
		var rsu_deliv = rsu_delivered.get(rsu.position)
		#print(rsu_deliv, rsu.position)
		if rsu_deliv == null:
			continue
			
		rsu.heatup(float(rsu_deliv)/float(max_value))


func purge_rsus(optimized_heat):
	var max_value = get_heat_value()

	for coord in rsu_delivered:
		if rsu_delivered[coord]/float(max_value) >= optimized_heat:
			#print(coord, " ", rsu_delivered[coord]/float(max_value), " ", optimized_heat)
			continue

		rsu_map.set_cellv(rsu_map.world_to_map(Vector2(coord) - rsu_map.cell_size/2), 1)
		
	rsu_delivered.clear()

func _on_changes_made():
	emit_signal("save_me", self)



func _on_ViewportContainer_mouse_exited():
	$Camera2D.set_process_input(false)
	$Draw.allow_draw(false)



func _on_ViewportContainer_mouse_entered():
	$Camera2D.set_process_input(true)
	$Draw.allow_draw(true)


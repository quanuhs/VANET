extends Node2D
class_name VehicleSpawner

@export var builder: Builder
@export var loader: Loader


@export var vehicle_scene: PackedScene
@export var vehicle_rsu_scene: PackedScene

func _ready():
	set_process(true)
	
func spawn_vehicle(start_node_id, end_node_id) -> Vehicle:
	var vehicle: Vehicle = vehicle_scene.instantiate()
	
	var astar_paths:PackedInt64Array = loader.astar.get_id_path(start_node_id, end_node_id)
	vehicle.path = astar_paths
	vehicle.builder = builder
	vehicle.astar = loader.astar
	vehicle.pixel_per_meter = 1
	vehicle.move_to_next_point()
	
	return vehicle
	

func spawn_mrsu(start_node_id, end_node_id):
	print("SPAWN MRSU")
	var vehicle: VehicleRSU = vehicle_rsu_scene.instantiate()
	
	var astar_paths:PackedInt64Array = loader.astar.get_id_path(start_node_id, end_node_id)
	vehicle.initial_start = start_node_id
	vehicle.initial_end = end_node_id
	vehicle.path = astar_paths
	vehicle.builder = builder
	vehicle.astar = loader.astar
	vehicle.pixel_per_meter = 1
	vehicle.move_to_next_point()
	
	return vehicle
	
	
func wait(time):
	if get_tree():
		await get_tree().create_timer(time).timeout
	

signal done
func call_function(callable: Callable, args: Array = []):
	await callable.callv(args)
	done.emit()


func sequence_call(sequence):
	for element in sequence:
		if element is Callable:
			await call_function(element)
		else:
			await call_function(element[0], element[1])


func test_spawn():
	reroute_chaos()
	

func reroute_platoon():
	var start_node = 1
	var end_node = 500
	
	for j in range(1):
		for i in range(9):
			await get_tree().create_timer(1).timeout
			
			var vehicle = spawn_vehicle(start_node, end_node)
			var ask = [[wait, [randi_range(10, 120)]], [vehicle.logic.ask_data, [300, CONFIG_GLOBAL.CONFIG.get("query_seconds", 5)]]]
			
			var test = [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				
			for s in range(10):
				test += [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				
			sequence_call(test)

			#if (i+j+1) % 3 == 0:
				#var test = [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				#
				#for s in range(10):
					#test += [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				#
				#sequence_call(test)
			
			sequence_call(ask)
			
			if CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_every"):
				if (i+j+1) % int(CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_every", 1)) == 0:
					await get_tree().create_timer(1).timeout
					spawn_mrsu(start_node, end_node)

		await get_tree().create_timer(5).timeout
		
		

func reroute_chaos():
	var start_node = 1
	var end_node = 500
	
	var amount = 25
	var groups = 10
	
	for j in range(groups):
		for i in range(amount):
			await get_tree().physics_frame
			start_node = randi_range(1, loader.astar.get_point_count())
			end_node = randi_range(1, loader.astar.get_point_count())
			var vehicle = spawn_vehicle(start_node, end_node)
			vehicle.name = "Vehicle" + str(j*amount+i+1) + "#"
			
			
			var ask = [[wait, [5]], [vehicle.logic.ask_data, [300, CONFIG_GLOBAL.CONFIG.get("query_seconds", 1)]]]
			
			sequence_call(ask)
			
			if (i+j + 1) % 5 == 0:
				var test = [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				
				for s in range(10):
					test += [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
				
				sequence_call(test)
			
			if CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_every"):
				if (i+j+1) % int(CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_every", 1)) == 0:
					await get_tree().physics_frame
					spawn_mrsu(start_node, end_node)
				
				
		await get_tree().physics_frame
		await get_tree().physics_frame

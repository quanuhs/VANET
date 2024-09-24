extends Node2D
class_name VehicleSpawner

@export var builder: Builder
@export var loader: Loader


@export var vehicle_scene: PackedScene

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
	
	
func wait(time):
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
	reroute_platoon()
	

func reroute_platoon():
	var start_node = 1
	var end_node = 500
	
	
	for j in range(10):
		for i in range(10):
			await get_tree().create_timer(1).timeout
			
			var vehicle = spawn_vehicle(start_node, end_node)
			vehicle.speed_mps = randf_range(16, 20)
			var ask = [[wait, [5]], [vehicle.logic.ask_data, [100, 2.0]]]
			var test = [[wait, [randi_range(10, 15)]], vehicle.stop, vehicle._on_accident, [ wait, [randi_range(5, 10)] ], vehicle._on_no_accident, vehicle.start]
			
			if (i+j+1) % 3 == 0:
				sequence_call(ask)
				sequence_call(test)
				
		
		await get_tree().create_timer(5).timeout
		
		

func reroute_chaos():
	var start_node = 1
	var end_node = 500
	
	for j in range(10):
		for i in range(50):
			start_node = randi_range(1, 1500)
			end_node = start_node + randi_range(1, 1000)
			var vehicle = spawn_vehicle(start_node, end_node)
			vehicle.speed_mps = randf_range(16, 20)
			
			if (i+j) % 5 == 0:
				var test = [[wait, [randi_range(10, 120)]], vehicle.stop, vehicle._on_accident, [ wait, [10] ], vehicle._on_no_accident, vehicle.start]
				sequence_call(test)
		
		await get_tree().create_timer(0.25).timeout

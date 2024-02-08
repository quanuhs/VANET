extends Node
var speed_scale = 1.0

var RSU_max_connections = 2

var RSU_energy_vehicle = 1
var RSU_energy_claster = 1
var RSU_enegry_server = 1


var RSU_radius = 16
var RSU_claster_amount = 3
var vehicle_speed_mean = 15
var vehicle_speed_deviation = 1.0

var vehicle_RSU_amount = 0
var limit = 10

var total_requests = 1

var wait_request = 1
var wait_ask_server = 3500
var wait_response = 1
var wait_ask_claster = 1

var directory = OS.get_user_data_dir()

var memory_amount = 10
var vehicle_memory_min = 3
var vehicle_memory_max = 5

var time_to_live = 5
var vehicles_amount = 100

var csv_header_vehicles = ["VehicleId", "Speed", "TotalRequests", "UnsolvedRequests"]
var delim = "\t"
var csv_header_rsu = ["RsuID", "Vehicles", "Cluster", "Server", "VehiclesTime", "ClusterTime", "ServerTime"]

var use_claster = true

func get_method_used():
	if use_claster:
		return "cluster-" + str(RSU_claster_amount)
	else:
		return "non-cluster"


func get_data():
	return {
		"rsu_radius": RSU_radius,
		"rsu_claster_amount": RSU_claster_amount,
		"vehicle_speed_mean": vehicle_speed_mean,
		"vehicle_speed_deviation": vehicle_speed_deviation,
		"limit": limit,
		"wait_request": wait_request,
		"wait_ask_server": wait_ask_server,
		"wait_response": wait_response,
		"wait_ask_claster": wait_ask_claster,
		"directory": directory,
		"memory_amount": memory_amount,
		"vehicle_memory_min": vehicle_memory_min,
		"vehicle_memory_max": vehicle_memory_max,
		"time_to_live": time_to_live,
		"vehicles_amount": vehicles_amount,
		"rsu_max_connections": RSU_max_connections
	}

func load_data(data):
	RSU_radius = data["rsu_radius"]
	RSU_claster_amount = data["rsu_claster_amount"]
	RSU_radius = data["rsu_radius"]
	RSU_claster_amount = data["rsu_claster_amount"]
	vehicle_speed_mean = data["vehicle_speed_mean"]
	vehicle_speed_deviation = data["vehicle_speed_deviation"]
	limit = data["limit"]
	wait_request = data["wait_request"]
	wait_ask_server = data["wait_ask_server"]
	wait_response = data["wait_response"]
	wait_ask_claster = data["wait_ask_claster"]
	directory = data["directory"] 
	memory_amount=data["memory_amount"]  
	vehicle_memory_min=data["vehicle_memory_min"]
	vehicle_memory_max=data["vehicle_memory_max"] 
	time_to_live=data["time_to_live"]
	vehicles_amount=data["vehicles_amount"] 
	RSU_max_connections = data["rsu_max_connections"]

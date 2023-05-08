extends Panel


onready var line_vehicle_amount = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer1/LineEditVehicleAmount
onready var line_vehicle_speed = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer2/LineEditVehicleSpeed
onready var line_vehicle_speed_div = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer3/LineEditVehicleSpeedDiv
onready var line_rsu_radius = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer4/LineEditRsuRadius
onready var line_rsu_claster_amount = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer5/LineEditClasterAmount
onready var line_ttl = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer6/LineEditTTL
onready var line_memory_amount = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer7/LineEditMemoryAmount
onready var line_memory_min = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer8/LineEditMemoryMin
onready var line_memory_max = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer9/LineEditMemoryMax
onready var line_claster_delay = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer10/LineEditClasterDelay
onready var line_response_delay = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer11/LineEditResponseDelay
onready var line_request_delay = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer12/LineEditRequestDelay
onready var line_server_delay = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer13/LineEditServerDelay
onready var line_simulation_amount = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer14/LineEdiSimulationAmount
onready var line_connection_amount = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer15/LineEdiConnectionAmount
onready var line_enegry_claster = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer16/LineEditEnergyClaster
onready var line_enegry = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer17/LineEditEnergy
onready var line_energy_server = $ViewportContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer18/LineEditEnergyServer


func _ready():
	load_from_global()
	

func load_from_global():
	line_vehicle_amount.set_value((Global.vehicles_amount))
	line_vehicle_speed.set_value((Global.vehicle_speed_mean))
	line_vehicle_speed_div.set_value((Global.vehicle_speed_deviation))
	line_rsu_radius.set_value((Global.RSU_radius))
	line_rsu_claster_amount.set_value((Global.RSU_claster_amount))
	line_ttl.set_value((Global.time_to_live))
	line_memory_amount.set_value((Global.memory_amount))
	line_memory_min.set_value((Global.vehicle_memory_min))
	line_memory_max.set_value((Global.vehicle_memory_max))
	line_claster_delay.set_value((Global.wait_ask_claster))
	line_response_delay.set_value((Global.wait_response))
	line_request_delay.set_value((Global.wait_request))
	line_simulation_amount.set_value((Global.limit))
	line_server_delay.set_value(Global.wait_ask_server)
	line_connection_amount.set_value(Global.RSU_max_connections)
	line_enegry_claster.set_value(Global.RSU_energy_claster)
	line_enegry.set_value(Global.RSU_energy_vehicle)
	line_energy_server.set_value(Global.RSU_enegry_server)
	

func load_to_global():
	Global.vehicles_amount = line_vehicle_amount.last_value
	Global.vehicle_speed_mean = line_vehicle_speed.last_value
	Global.vehicle_speed_deviation = line_vehicle_speed_div.last_value
	Global.RSU_radius = line_rsu_radius.last_value
	Global.RSU_claster_amount = line_rsu_claster_amount.last_value
	Global.time_to_live = line_ttl.last_value
	Global.memory_amount = line_memory_amount.last_value
	Global.vehicle_memory_min = line_memory_min.last_value
	Global.vehicle_memory_max = line_memory_max.last_value
	Global.wait_ask_claster = line_claster_delay.last_value
	Global.wait_response = line_response_delay.last_value
	Global.wait_request = line_request_delay.last_value
	Global.limit = line_simulation_amount.last_value
	Global.wait_ask_server = line_server_delay.last_value
	Global.RSU_max_connections = line_connection_amount.last_value
	Global.RSU_energy_claster = line_enegry_claster.last_value
	Global.RSU_enegry_server = line_energy_server.last_value
	Global.RSU_energy_vehicle = line_enegry.last_value

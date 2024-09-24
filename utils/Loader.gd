extends Node2D
class_name Loader

@export var nodes_path: String
@export var edges_path: String

@export
var data_parser: DataParser

var astar = AStar2D.new()

signal path_found(path)
signal data_loaded


func load_data(nodes_path, edges_path):
	data_parser.load_data(nodes_path, edges_path)
	convert_lat_lon_to_pixels()
	build_astar_graph()
	emit_signal("data_loaded")

func convert_lat_lon_to_pixels():
	var min_lat = INF
	var max_lat = -INF
	var min_lon = INF
	var max_lon = -INF

	# Determine the bounding box of the coordinates
	for id in data_parser.nodes:
		var pos = data_parser.nodes[id].position
		min_lat = min(min_lat, pos.x)
		max_lat = max(max_lat, pos.x)
		min_lon = min(min_lon, pos.y)
		max_lon = max(max_lon, pos.y)

	var delta_lat = max_lat - min_lat
	var delta_lon = max_lon - min_lon
	
	# Calculate the real-world size of the map in meters
	var lat_meters = delta_lat * 111000.0  # 1 degree latitude ≈ 111 km
	var lon_meters = delta_lon * 111000.0 * cos(deg_to_rad((min_lat + max_lat) / 2.0))
	var map_real_width = lon_meters
	var map_real_height = lat_meters

	# Scale so that 1 meter = 1 pixel
	# The width of the map in pixels will be the same as the real-world width in meters
	var map_width = map_real_width
	var map_height = map_real_height

	# Calculate the center offset to center the map at (0, 0)
	var x_offset = -((min_lon + max_lon) / 2.0 - min_lon) * map_width / delta_lon
	var y_offset = -((min_lat + max_lat) / 2.0 - min_lat) * map_height / delta_lat

	# Convert lat/lon to pixels with 1m = 1px scale and apply centering offset
	for id in data_parser.nodes:
		var pos = data_parser.nodes[id].position
		var x = ((pos.y - min_lon) / delta_lon) * map_width + x_offset
		var y = ((pos.x - min_lat) / delta_lat) * map_height + y_offset
		
		data_parser.nodes[id].position = Vector2(x, -y)  # Invert y-axis for correct rendering

func build_astar_graph():
	astar.clear()  # Clear any existing data in AStar2D

	# Add nodes to the AStar2D
	for id in data_parser.nodes:
		var pos = data_parser.nodes[id].position
		astar.add_point(id, pos)

	# Add edges to the AStar2D
	for edge in data_parser.edges:
		if not astar.are_points_connected(edge.from, edge.to):
			astar.connect_points(edge.from, edge.to)
		
		if not astar.are_points_connected(edge.to, edge.from):
			astar.connect_points(edge.to, edge.from)


func find_path(start_id, goal_id):
	var path = astar.get_point_path(start_id, goal_id)
	emit_signal("path_found", path)
	return path

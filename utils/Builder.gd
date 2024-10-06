extends Node2D
class_name Builder

@export var node_radius = 3  # Radius of the node circle
@export var edge_color = Color.DIM_GRAY
@export var node_color = Color.RED

@export
var loader: Loader

@export
var roads: Node2D

var path2d_dict = {}  # Dictionary to store paths with from-to ids as keys

func _ready():
	loader.connect("data_loaded", build_paths)

func _draw():
	draw_edges()
	draw_nodes()

func draw_edges():
	for point_id in loader.astar.get_point_ids():
		var connections = loader.astar.get_point_connections(point_id)
		
		for connection in connections:
			var from_pos = loader.astar.get_point_position(point_id)
			var to_pos = loader.astar.get_point_position(connection)
			draw_line(from_pos, to_pos, edge_color, 10)

func draw_nodes():
	for id in loader.data_parser.nodes:
		var pos = loader.data_parser.nodes[id].position
		draw_circle(pos, node_radius, node_color)


func build_paths():
	for point_id in loader.astar.get_point_ids():
		var connections = loader.astar.get_point_connections(point_id)

		for connection in connections:
			create_path(point_id, connection)
	
	queue_redraw()
	loader.disconnect("data_loaded", build_paths)


func create_path(from_id, to_id):
	var path2d = Path2D.new()
	var curve = Curve2D.new()
	path2d.curve = curve
	
	var from_pos = loader.astar.get_point_position(from_id)
	var to_pos = loader.astar.get_point_position(to_id)

	curve.add_point(from_pos)
	curve.add_point(to_pos)
	
	roads.add_child(path2d)
	path2d_dict[str(from_id) + "-" + str(to_id)] = path2d


func find_path(from_id, to_id) -> Path2D:
	return path2d_dict.get(str(from_id) + "-" + str(to_id), null)

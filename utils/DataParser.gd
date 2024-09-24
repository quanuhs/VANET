extends Node2D
class_name DataParser

var nodes = {}
var edges = []
var node_tolerance = -0.0005

class RoadEdge:
	var from
	var to
	var cost

class RoadNode:
	var position
	var neighbors = []

	func _init(pos):
		position = pos

func load_data(nodes_path, edges_path):
	load_nodes(nodes_path)
	load_edges(edges_path)
	optimize_data()

func load_nodes(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.get_line()  # Skip header
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line == "":
				break
			var parts = line.split(",")
			var id = parts[0].to_int()
			var lat = parts[1].to_float()
			var lon = parts[2].to_float()
			nodes[id] = RoadNode.new(Vector2(lat, lon))
		file.close()

func load_edges(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.get_line()  # Skip header
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line == "":
				break
			var parts = line.split(",")
			var from_id = parts[0].to_int()
			var to_id = parts[1].to_int()
			var cost = parts[11].to_float()  # Length as cost
			var edge = RoadEdge.new()
			
			if not nodes.get(from_id):
				continue
				
			if not nodes.get(to_id):
				continue
			
			edge.from = from_id
			edge.to = to_id
			edge.cost = cost
			edges.append(edge)
			
			nodes[from_id].neighbors.append(edge)
			nodes[to_id].neighbors.append(edge)  # Ensure the neighbor is added to both nodes
		file.close()

func optimize_data():
	optimize_nodes()
	optimize_edges()

func optimize_nodes():
	var new_nodes = {}
	var id_map = {}
	var next_id = 1
	
	for id in nodes:
		var pos = nodes[id].position
		var found = false
		for new_id in new_nodes:
			var new_pos = new_nodes[new_id].position
			if pos.distance_to(new_pos) < node_tolerance:
				id_map[id] = new_id
				found = true
				break
		if not found:
			new_nodes[next_id] = RoadNode.new(pos)
			id_map[id] = next_id
			next_id += 1
	nodes = new_nodes

	# Update edges to reflect new node IDs
	for i in range(edges.size()):
		edges[i].from = id_map[edges[i].from]
		edges[i].to = id_map[edges[i].to]

func optimize_edges():
	var new_edges = []
	var edge_set = {}
	for edge in edges:
		var from_id = edge.from
		var to_id = edge.to
		
		if from_id > to_id:
			var temp = from_id
			from_id = to_id
			to_id = temp
			
		var edge_key = str(from_id) + "-" + str(to_id)
		
		if edge_key not in edge_set and from_id != to_id:
			edge_set[edge_key] = true
			new_edges.append(edge)
			
	edges = new_edges

extends Node2D
class_name Mapper

var nodes = {}
var edges = []
var node_tolerance = 0.0005

@export
var loader: Loader

signal data_optimized(nodes, edges)

class RoadEdge:
	var from
	var to
	var cost

class RoadNode:
	var position
	var neighbors = []
	var g = 0
	var h = 0
	var f = 0
	var parent = null

	func _init(pos):
		position = pos

func _ready():
	loader.data_loaded.connect(_on_data_loaded)

func _on_data_loaded(new_nodes, new_edges):
	print("HERE ")
	
	nodes = new_nodes
	edges = new_edges
	optimize_nodes()
	optimize_edges()
	build_graph()
	emit_signal("data_optimized", nodes, edges)

func optimize_nodes():
	var new_nodes = {}
	var id_map = {}
	var next_id = 1
	
	for id in nodes:
		var pos = nodes[id]
		var found = false
		for new_id in new_nodes:
			var new_pos = new_nodes[new_id]
			if pos.distance_to(new_pos) < node_tolerance:
				id_map[id] = new_id
				found = true
				break
		if not found:
			new_nodes[next_id] = pos
			id_map[id] = next_id
			next_id += 1
	nodes = new_nodes

	# Update edges to reflect new node IDs
	for i in range(edges.size()):
		edges[i][0] = id_map[edges[i][0]]
		edges[i][1] = id_map[edges[i][1]]

func optimize_edges():
	var new_edges = []
	var edge_set = {}
	for edge in edges:
		var from_id = edge[0]
		var to_id = edge[1]
		if from_id > to_id:
			var temp = from_id
			from_id = to_id
			to_id = temp
		var edge_key = str(from_id) + "-" + str(to_id)
		if edge_key not in edge_set:
			edge_set[edge_key] = true
			new_edges.append(edge)
	edges = new_edges

func build_graph():
	for id in nodes:
		add_road_node(id, nodes[id])
	for edge in edges:
		add_road_edge(edge[0], edge[1], edge[2])

func add_road_node(id, position):
	nodes[id] = RoadNode.new(position)

func add_road_edge(from_id, to_id, cost):
	var edge = RoadEdge.new()
	edge.from = from_id
	edge.to = to_id
	edge.cost = cost
	edges.append(edge)
	nodes[from_id].neighbors.append(edge)

func heuristic(node1, node2):
	return node1.position.distance_to(node2.position)

func a_star(start_id, goal_id):
	var open_set = []
	var closed_set = []
	var start_node = nodes[start_id]
	var goal_node = nodes[goal_id]
	open_set.append(start_node)

	while open_set.size() > 0:
		var current = get_lowest_f_score_node(open_set)
		open_set.erase(current)

		if current == goal_node:
			return reconstruct_path(current)

		closed_set.append(current)

		for edge in current.neighbors:
			var neighbor = nodes[edge.to]
			if neighbor in closed_set:
				continue

			var tentative_g = current.g + edge.cost
			if neighbor not in open_set:
				open_set.append(neighbor)
			elif tentative_g >= neighbor.g:
				continue

			neighbor.parent = current
			neighbor.g = tentative_g
			neighbor.h = heuristic(neighbor, goal_node)
			neighbor.f = neighbor.g + neighbor.h

	return []

func get_lowest_f_score_node(open_set):
	var lowest_f_score_node = open_set[0]
	for node in open_set:
		if node.f < lowest_f_score_node.f:
			lowest_f_score_node = node
	return lowest_f_score_node

func reconstruct_path(current):
	var path = []
	while current:
		path.append(current)
		current = current.parent
	path.reverse()
	return path

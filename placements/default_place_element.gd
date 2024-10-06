extends Node
class_name DefaultPlaceElement

@export
var place_handler: PlaceHandler

@export
var tree: Tree

var tree_header = null

@export
var node_name: String

@export
var placement_node: Node2D

@export
var place_node: Resource

var placed = []
var selected: bool = false

func select():
	selected = true

func deselect():
	selected = false
	

func _ready() -> void:
	place_handler.connect("element_placed", self.place_selected)
	place_handler.connect("element_removed", self.remove)
	_after_ready()
	
	
func _after_ready():
	pass


func place_selected(global_position: Vector2):
	if not selected:
		return
	
	place(global_position)

func place(global_position: Vector2):
	var _node = place_node.instantiate()
	_node.name = node_name + str(len(placed)+1)
	_node.global_position = global_position
	placement_node.add_child(_node)
	placed.append(_node)
	add_node_to_tree(_node)


func remove(global_position: Vector2):
	if not selected:
		return
	
	for _node in placed:
		pass


func add_node_to_tree(node):
	if len(placed) == 1:
		var root = tree.get_root()
		tree_header = tree.create_item(root)
		tree_header.set_text(0, node_name)
	
	var new_item = tree.create_item(tree_header)
	new_item.set_metadata(0, node)
	new_item.set_text(0, node.name)

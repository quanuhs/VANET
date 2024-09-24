extends OptionButton

@export
var place_handler: PlaceHandler

var ids = {}
var last_selected_node: DefaultPlaceElement = null

func _ready() -> void:
	var id = 1000
	for child in place_handler.get_children():
		if child is DefaultPlaceElement:
			ids[id] = child
			add_item(child.node_name, id)
			id += 1
			


func _on_item_selected(index: int) -> void:
	if last_selected_node:
		last_selected_node.deselect()
	
	last_selected_node = ids.get(get_item_id(index))
	
	if last_selected_node:
		last_selected_node.select()

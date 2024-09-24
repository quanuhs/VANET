extends Tree

func _on_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	select_item(item, column, selected)

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_delete"):
		remove_items()


func remove_items():
	var selected_item:= get_next_selected(null)
	while selected_item:
		remove_item(selected_item)
		selected_item = get_next_selected(selected_item)


func remove_item(item: TreeItem):
	if item == null:
		return
	
	var item_metadata = item.get_metadata(get_selected_column())
		
	if item_metadata == null:
		return
	
	item_metadata.queue_free()
	item.free()


func select_item(item: TreeItem, column: int, selected: bool):
	var item_metadata = item.get_metadata(column)
	
	if item_metadata == null:
		return
	
	item_metadata.set_select(selected)

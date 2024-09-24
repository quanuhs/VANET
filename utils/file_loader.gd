extends Control

@onready var file_dialog: FileDialog = $"../../FileDialog"


var path_to = {"nodes": null, "edges": null, "rsus": null}

@onready var loader: Loader = $"../../Window/World/Logic/Loader"
@onready var window: Window = $"../../Window"
@onready var after_load_container: HBoxContainer = $"../Panel/Panel/HBoxContainer/AfterLoadContainer"
@onready var tree: Tree = $"../Panel/MarginContainer/HBoxContainer/VBoxContainer/Panel/Tree"


func _ready() -> void:
	var root = tree.create_item()


func _on_button_load_pressed() -> void:
	file_dialog.popup()


func _on_file_dialog_dir_selected(dir: String) -> void:
	var nodes_path = dir + "/nodes.csv"
	var edges_path = dir + "/edges.csv"
	
	path_to["nodes"] = nodes_path
	path_to["edges"] = edges_path
	
	await loader.load_data(nodes_path, edges_path)
	after_load_container.show()
	window.show()

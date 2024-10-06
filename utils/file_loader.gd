extends Control

@onready var file_dialog: FileDialog = $"../../FileDialog"


var path_to = {"nodes": null, "edges": null, "rsus": null}

@onready var loader: Loader = $"../../Window/World/Logic/Loader"
@onready var window: Window = $"../../Window"
@onready var after_load_container: HBoxContainer = $"../Panel/Panel/HBoxContainer/AfterLoadContainer"

@onready var place_rsu: DefaultPlaceElement = $"../../Window/World/PlacerHandler/PlaceRSU"
@onready var place_mec: DefaultPlaceElement = $"../../Window/World/PlacerHandler/PlaceMEC"
@onready var rich_text_label: RichTextLabel = $"../Panel/MarginContainer/HBoxContainer/VBoxContainer2/Panel/MarginContainer/VBoxContainer/RichTextLabel"



func _on_button_load_pressed() -> void:
	file_dialog.popup()

func load_placements(dir: String):
#		ПЕРЕДЕЛАТЬ ЗАГРУЗКУ!
	var file = FileAccess.open(dir, FileAccess.READ)
	
	if not file:
		print("ERROR")
		return
	
	var json_string = JSON.parse_string(file.get_as_text())
	file.close()
	
	var rsus = json_string.get("rsu_positions")
	var mecs = json_string.get("mec_positions")
				
	
	place_rsu.placed = []
	place_mec.placed = []
	
	if rsus:
		for rsu in rsus:
			if rsu.get("position"):
				place_rsu.place(str_to_var("Vector2"+rsu.get("position")))
	
	if mecs:
		for mec in mecs:
			if mec.get("position"):
				place_mec.place(str_to_var("Vector2"+mec.get("position")))
				

signal done
func load_settings(dir: String):
	var file = FileAccess.open(dir, FileAccess.READ)
	
	if not file:
		print("ERROR")
		return
		
		
	var json_string = JSON.parse_string(file.get_as_text())
	file.close()
	
	CONFIG_GLOBAL.CONFIG = json_string
	done.emit()
	

func load_experiment(dir):
	var file = FileAccess.open(dir, FileAccess.READ)
	
	if not file:
		print("ERROR")
		return false
		
		
	var json_string = JSON.parse_string(file.get_as_text())
	file.close()
	return true


func _on_file_dialog_dir_selected(dir: String) -> void:
	
	await load_settings(dir.path_join("settings.json"))
	rich_text_label.text = str(CONFIG_GLOBAL.CONFIG)
	
	var paths = CONFIG_GLOBAL.CONFIG.get("paths", {})
	
	var nodes_path:String = paths.get("nodes", dir)
	var edges_path:String = paths.get("edges", dir)
	var positions:String = paths.get("positions", dir)

	edges_path = edges_path.path_join("edges.csv")
	positions = positions.path_join("positions.json")
	nodes_path = nodes_path.path_join("nodes.csv")
	
	path_to["nodes"] = nodes_path
	path_to["edges"] = edges_path
	
	await loader.load_data(nodes_path, edges_path)
	load_placements(positions)
	
	after_load_container.show()


func _on_button_map_pressed() -> void:
	window.visible = !window.visible

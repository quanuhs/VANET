extends Control


onready var city_tscn = load("res://City.tscn")
onready var city = $HSplitContainer/Panel/ViewportContainer/Viewport/City


var _count = 0

var total_requests = 0
var total_loss = 0



func start_simulation(use_claster:bool):
	_count = 0
	
	Global.use_claster = use_claster
	print("Amount of iterations: ", Global.limit)
	print("Method used: ", Global.get_method_used())
	generate_city()


func _ready():
	city.connect("done", self, "_on_City_done")
	$FileDialog.current_path = Global.directory



func finish_simulation():
	_count = 0
	city.stop_simulation()
	change_button_vis(true)
	
func generate_city():
	print("Iteration (", _count+1, "/", Global.limit, ") started.")
	city.start_simulation()


func save_to_file(filename, header, data:Dictionary):
	var file = File.new()
	var file_path = Global.directory+"/"+filename+".csv"
	
	file.open(file_path, File.WRITE)
	file.store_csv_line(header, Global.delim)
	for _key in data:
		file.store_csv_line(data[_key], Global.delim)

	file.close()
	return file_path


func mean(_array:Array):
	var _result = 0.0
	print(_array)
	
	for i in range(_array.size()):
		_result += _array[i]
	
	return _result/_array.size()


func _on_City_done(from, _total_requests, _total_loss, _data, _rsu_energy):
	
	total_requests += _total_requests
	total_loss += _total_loss
	
	var filename = "vehicles_"+Global.get_method_used()
	
	filename += "_"+str(OS.get_unix_time())
	
	var _saved_file_name = save_to_file(filename, Global.csv_header_vehicles, _data)
	filename = "RSU_"+filename
	var _saved_rsu_data = save_to_file(filename, Global.csv_header_rsu, _rsu_energy)
	from.stop_simulation()
	
	print(_saved_rsu_data, " saved data")
	print(_saved_file_name, " finished and saved.")
	
	_count += 1
	if Global.limit - _count > 0:
		generate_city()
	else:
		finish_simulation()
	

func _on_City_save(_city):
	var packed_scene = PackedScene.new()
	#packed_scene.pack(_city)
	#ResourceSaver.save("res://map.tscn", packed_scene)
	#city = packed_scene

func save_config(path):
	var file = File.new()
	
	file.open(path, File.WRITE)
	var data = Global.get_data()
	data["map"] = city.get_map_config()
	
	file.store_var(data, true)

	file.close()

func load_config(path):
	var file = File.new()
	
	file.open(path, File.READ)
	var data = file.get_var(true)
	file.close()
	Global.load_data(data)
	city.load_map_config(data["map"])

	$HSplitContainer/PanelSettings.load_from_global()

	

func _on_chooseFolder_pressed():
	$FileDialog.set_current_dir(Global.directory)
	$FileDialog.popup_centered()


func _on_FileDialog_dir_selected(dir):
	Global.directory=dir


func change_button_vis(can_see):
	$HSplitContainer/PanelSettings/ViewportContainer/ScrollContainer/VBoxContainer/VBoxContainer/ButtonCancel.visible = not can_see
	$HSplitContainer/PanelSettings/ViewportContainer/ScrollContainer/VBoxContainer/VBoxContainer/ButtonStart.visible = can_see

func _on_ButtonCancel_pressed():
	finish_simulation()
	change_button_vis(true)


func _on_FileDialogSettings_file_selected(path):
	if $FileDialogSettings.mode == FileDialog.MODE_SAVE_FILE:
		save_config(path)
	else:
		load_config(path)



func _on_loadSettings_pressed():
	$FileDialogSettings.mode = FileDialog.MODE_OPEN_FILE
	$FileDialogSettings.popup_centered()


func _on_saveSettings_pressed():
	$FileDialogSettings.mode = FileDialog.MODE_SAVE_FILE
	$FileDialogSettings.popup_centered()
	


onready var claster_amount = $HSplitContainer/PanelSettings.line_rsu_claster_amount
func _on_ButtonStart_pressed():
	start_simulation(int(claster_amount.text) > 0)
	change_button_vis(false)

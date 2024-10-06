extends Control

@onready var button_load: Button = $Panel/Panel/HBoxContainer/ButtonLoad
@onready var button_start: Button = $Panel/Panel/HBoxContainer/AfterLoadContainer/ButtonStart
@onready var button_change_placement: OptionButton = $Panel/Panel/HBoxContainer/AfterLoadContainer/ButtonChangePlacement
@onready var button_stop: Button = $Panel/Panel/HBoxContainer/AfterLoadContainer/ButtonStop
@onready var file_loader: Control = $FileLoader
@onready var loader: Loader = $"../Window/World/Logic/Loader"

@onready var timer_dispatch: Timer = $"../Window/World/mRSU_dispatch/Timer"

@onready var label_prob: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer2/Panel/MarginContainer/VBoxContainer/HBoxContainer/Label2
@onready var timer: Timer = $Timer



var selected_dir = ""
var loss = []



func _ready() -> void:
	if FileAccess.file_exists(selected_dir.path_join("settings.json")):
		reload_model()
	

func _on_file_dialog_dir_selected(dir: String) -> void:
	selected_dir = dir.replace("\\", "/")


func _on_button_start_pressed() -> void:
	timer.start()
	button_start.hide()
	button_stop.show()
	
	if CONFIG_GLOBAL.CONFIG.get("global").get("mrcu_reactive"):
		timer_dispatch.start(10)
	
	await get_tree().create_timer(60*5).timeout
	timer_dispatch.stop()
	save_to_json(get_data())
	print(calculate_loss(get_data()))
	
	await get_tree().physics_frame
	get_tree().quit()
	#get_tree().reload_current_scene()


func reload_model():
	#for mec in get_tree().get_nodes_in_group("mec"):
		#mec.queue_free()
	#
	#for rsu in get_tree().get_nodes_in_group("rsu"):
		#rsu.queue_free()
	#
	#for vehicle in get_tree().get_nodes_in_group("vehicle"):
		#vehicle.queue_free()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	file_loader._on_file_dialog_dir_selected(selected_dir)
	button_start.pressed.emit()
	


func save_positions_to_json():
	var rsus = get_tree().get_nodes_in_group("rsu")
	var mecs = get_tree().get_nodes_in_group("mec")

	var data = {
		"rsu_positions": [],
		"mec_positions": []
	}

	# Сбор позиций узлов RSU
	for rsu in rsus:
		if rsu is Node3D:
			data["rsu_positions"].append({
				"name": rsu.name,
				"position": rsu.global_transform.origin
			})
		elif rsu is Node2D:
			data["rsu_positions"].append({
				"name": rsu.name,
				"position": rsu.global_position
			})

	# Сбор позиций узлов MEC
	for mec in mecs:
		if mec is Node3D:
			data["mec_positions"].append({
				"name": mec.name,
				"position": mec.global_transform.origin
			})
		elif mec is Node2D:
			data["mec_positions"].append({
				"name": mec.name,
				"position": mec.global_position
			})


	var dir_path = CONFIG_GLOBAL.CONFIG.get("paths", {}).get("save", selected_dir)
	var file = FileAccess.open(dir_path.path_join("positions.json"), FileAccess.ModeFlags.WRITE)
	if file == null:
		print("Не удалось открыть файл для записи")
		return

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()

	print("Позиции сохранены в файл positions.json")



func _on_button_stop_pressed() -> void:
	save_to_json(get_data())
	
func get_data():
	var vehicles = get_tree().get_nodes_in_group("vehicle")
	var data = []
	for vehicle in vehicles:
		data.append(vehicle.logic.requested)
	
	return data
	
func calculate_loss(data):
	# Инициализируем счетчики сообщений
	var total_messages = 0
	var lost_messages = 0

	# Итерация по структуре JSON для подсчета значений 'inf'
	for item in data:
		if item is Dictionary:
			for key in item:
				var value = item[key]
				if value.has("asked") and value.has("recived"):
					total_messages += value["recived"].size()
					lost_messages += value["recived"].count(-1)

	# Вычисляем процент потерянных сообщений
	var lost_percentage = 0
	if total_messages > 0:
		lost_percentage = (float(lost_messages) / total_messages) * 100

	#print("Процент потерянных сообщений: ", lost_percentage)
	return lost_percentage

func save_to_json(data):
	var _time = str(Time.get_datetime_string_from_system()).replace(":","_")
	var _str_loss = "%3.f"%calculate_loss(data)
	_str_loss.replace(".", "_")
	
	
	var dir_path = CONFIG_GLOBAL.CONFIG.get("paths", {}).get("save", selected_dir)
	var dir = DirAccess.open(dir_path)
	var folder = CONFIG_GLOBAL.CONFIG.get("global", {}).get("folder")
	
	if folder:
		dir.make_dir_recursive(folder)
		dir.change_dir(folder)
		
	print(dir)
	
	loss.append([Time.get_ticks_msec(), calculate_loss(data)])
	var result = {"loss": loss, "data": data}
	
	var path = dir.get_current_dir(true).path_join("%s__%s__%s.json" % ([randi(), _time, _str_loss]))
	var file = FileAccess.open(path, FileAccess.ModeFlags.WRITE_READ)

	var json_string = JSON.stringify(result)
	file.store_string(json_string)
	file.close()


func _on_timer_timeout() -> void:
	var _loss = calculate_loss(get_data())
	loss.append([Time.get_ticks_msec(), _loss])
	label_prob.text = "%.3f" % _loss


func _on_button_save_pressed() -> void:
	save_positions_to_json()

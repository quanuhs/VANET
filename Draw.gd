extends Node2D

onready var current = $CurrentMap
onready var current_max_cells = get_maps().size()

onready var tile_id = 0
onready var last_cell_pos = Vector2.ZERO
onready var current_cell_id = 0

var draw_allowed = true
var draw_stopped = false

signal save_me

func stop_draw(val:bool):
	if val == true:
		allow_draw(not val)
		
	draw_stopped = val

func allow_draw(val:bool):
	if draw_stopped:
		return
	
	$CurrentMap.visible = val
	draw_allowed = val

func _process(delta):
	if not draw_allowed:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	
	if mouse_pos.x < 0 or mouse_pos.y < 0:
		return
	
	var new_cell_pos = current.world_to_map(get_local_mouse_position())
	
	var map = get_map()
	
	if last_cell_pos != new_cell_pos:
		current.set_cellv(last_cell_pos, -1)
		last_cell_pos = new_cell_pos
	
	
	if Input.is_action_just_pressed("ui_left"):
		current_cell_id -= 1
		
		if current_cell_id == -1:
			current_cell_id = current_max_cells-1
	
	if Input.is_action_just_pressed("ui_right"):
		current_cell_id += 1
		
		if current_cell_id == current_max_cells:
			current_cell_id = 0
	
	current.set_cellv(new_cell_pos, current_cell_id)


	if Input.is_action_pressed("left_click"):
		map[0].set_cellv(map[0].world_to_map(get_local_mouse_position()), map[1])
		emit_signal("save_me")
	
	if Input.is_action_pressed("right_click"):
		map[0].set_cellv(map[0].world_to_map(get_local_mouse_position()), -1)
		emit_signal("save_me")

func get_maps():
	return get_parent().get_maps()

func get_map():
	return get_parent().get_maps()[current_cell_id]

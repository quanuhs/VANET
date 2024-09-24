extends Camera2D

@export var zoom_speed = 0.1
@export var move_speed = 500.0

func _ready():
	# Enable custom zoom mode
	set_process_input(true)


var move_vector = Vector2.ZERO

func _input(event):
	
	if event is InputEventMouseButton:
		# Zoom in
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.is_pressed():
			zoom *= (1 + zoom_speed)
		
		# Zoom out
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.is_pressed():
			zoom *= (1 - zoom_speed)
	
	
	move_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move_vector = move_vector.normalized()
	
	

#
## Update movement in _process
func _process(delta):
	
	if move_vector != Vector2.ZERO:
		move_vector = move_vector.normalized()
		# Adjust move speed by dividing by zoom to keep it constant
		global_position += move_vector * (move_speed / zoom.x) * delta

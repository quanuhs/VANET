extends LineEdit
class_name LineValidator

export var min_value : float = 0
export var max_value : float = -1
export var is_float : bool = true

onready var last_value = min_value
onready var last_text = str(last_value)

var parent = null

func _ready():
	connect("text_changed", self, "_on_text_change")
	connect("text_entered", self, "_on_text_change")
	
	parent = get_tree().get_nodes_in_group("panel_settings")[0]
	
	text = str(last_value)
	if is_float:
		placeholder_text = "float"
	else:
		placeholder_text = "integer"
	
	var _text_max = str(max_value)
	if max_value < min_value:
		_text_max = "inf"
		
	placeholder_text += " (from " + str(min_value) + " to " + _text_max + ")"
	
	

func validate_text(new_text:String):
	var value = last_value
	
	
	if is_float:
		if not new_text.is_valid_float():
			return false
		
		value = float(new_text)
		
	
	if not is_float:
		if not new_text.is_valid_integer():
			return false
		
		value = int(new_text)
	
	var remember_max = max_value
	
	if max_value < min_value:
		
		max_value = value + 1
	
	if min_value <= value and value <= max_value:
		
		max_value = remember_max
		last_value = value
		return true
	else:
		max_value = remember_max
		return false


func _on_text_change(new_text:String):
	
	var valid = validate_text(new_text)
	
	if not valid:
		modulate = Color.red
	else:
		modulate = Color.white
		parent.load_to_global()
		
func set_value(value):
	last_value = value
	text = str(value)
	

extends Area2D
class_name BasePlaceNetworkUnit

enum {DEFAULT_COLOR, HOVER_COLOR}

@export_category("Colors")
@export_subgroup("Primary colors")
@export
var default_color: Color = Color.DARK_BLUE

@export
var hover_color: Color = Color.ORANGE

@export_subgroup("Radius colors")
@export
var radius_default_color: Color = Color.BLUE

@export
var radius_hover_color: Color = Color.YELLOW

var line_size = 4

@export_category("Config")
@export
var CONFIG = {
	"frequency": 5.9e9,
	"bandwidth": 10e6,
	"transmit_power_dbm": 20,
	"noise_figure": 9.0,
	"receiver_sensitivity_dbm": -85.0,
	"path_loss_exponent": 2.0,
	"range_radius_m": 5000.0
}

@export 
var network_manager: NetworkManager

@onready
var COLORS = {DEFAULT_COLOR: default_color, HOVER_COLOR: hover_color}

@onready
var RADIUS_COLORS = {DEFAULT_COLOR: radius_default_color, HOVER_COLOR: radius_hover_color}

var COLOR_INDEX = DEFAULT_COLOR


func _ready():
	set_process(true)
	
	var circle_shape = $Coverage.shape
	$Label.text = str(name)
	circle_shape.radius = CONFIG["range_radius_m"]
	network_manager._init_(CONFIG["receiver_sensitivity_dbm"], 
	CONFIG["transmit_power_dbm"], CONFIG["frequency"], 
	CONFIG["noise_figure"], 
	CONFIG["path_loss_exponent"])

	_continue_ready()

func _continue_ready():
	pass
	

func _draw() -> void:
	draw_circle(Vector2.ZERO, CONFIG["range_radius_m"], RADIUS_COLORS[COLOR_INDEX], false)
	draw_circle(Vector2.ZERO, 15, COLORS[COLOR_INDEX])

	# Визуализируем линии к транспортным средствам
	for node in network_manager.connected_nodes:
		draw_line(Vector2.ZERO, to_local(node.global_position), COLORS[COLOR_INDEX], line_size)
		draw_circle(to_local(node.global_position), line_size/2, COLORS[COLOR_INDEX])


# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ И ОТРИСОВКА
func set_select(selected: bool):
	if selected:
		COLOR_INDEX = HOVER_COLOR
	else:
		COLOR_INDEX = DEFAULT_COLOR
	queue_redraw()

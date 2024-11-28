extends Node2D
class_name BasePlaceNetworkUnit

enum {DEFAULT_COLOR, HOVER_COLOR}

@export
var network_manager: NetworkManager

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


@onready
var COLORS = {DEFAULT_COLOR: default_color, HOVER_COLOR: hover_color}

@onready
var RADIUS_COLORS = {DEFAULT_COLOR: radius_default_color, HOVER_COLOR: radius_hover_color}

var COLOR_INDEX = DEFAULT_COLOR
var line_color = Color(randf(), randf(), randf())

func _physics_process(delta: float) -> void:
	queue_redraw()


func _ready():
	set_process(true)
	_before_ready()
	$Label.text = str(name)
	
	network_manager.setup(CONFIG["receiver_sensitivity_dbm"], 
	CONFIG["transmit_power_dbm"], CONFIG["frequency"], 
	CONFIG["noise_figure"])
	
	if CONFIG.get('range_radius_m'):
		network_manager.set_radius(CONFIG["range_radius_m"])
	

	_continue_ready()


func _before_ready():
	pass

func _continue_ready():
	pass
	

func _draw() -> void:
	draw_circle(Vector2.ZERO, network_manager.radius, line_color, false)
	draw_circle(Vector2.ZERO, 15, line_color)


# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ И ОТРИСОВКА
func set_select(selected: bool):
	if selected:
		COLOR_INDEX = HOVER_COLOR
	else:
		COLOR_INDEX = DEFAULT_COLOR
	queue_redraw()

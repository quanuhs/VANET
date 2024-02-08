extends KinematicBody2D


var rng = RandomNumberGenerator.new()
var speed = 0
var path = []

var targets = []
var target_index = 0
var starting_position = Vector2.ZERO
var velocity = Vector2.ZERO


onready var nav:Navigation2D = get_parent().get_navigation()


func _init():
	rng.randomize()
	speed = rng.randfn(Global.vehicle_speed_mean, Global.vehicle_speed_deviation)


func _physics_process(delta):
	if path.size() > 0:
		move_to_point()

func set_random_position(_objects:Array, _map:TileMap):
	starting_position = _objects[rng.randi_range(0, _objects.size()-1)]
	
	if _map:
		starting_position = _map.map_to_world(starting_position)
	
	position = starting_position

func get_target_position():
	return targets[target_index]

func change_target_position():
	target_index = (target_index + 1) % len(targets)

func move():
	get_point_path(get_target_position())

func move_to_point():
	if position.distance_to(path[0]) <= 3:
		path.remove(0)
		if path.size() == 0:
			change_target_position()
			move()
	else:
		var direction = position.direction_to(path[0])
		velocity = direction * speed
		move_and_slide(velocity)
		

func get_point_path(target_position):
	path = nav.get_simple_path(position, target_position, false)

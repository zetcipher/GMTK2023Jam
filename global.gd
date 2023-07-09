extends Node

var screen_scale = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size = Vector2i(640,360) * screen_scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("incr_scale"):
		screen_scale += 1
		if screen_scale > 6: screen_scale = 6
		get_window().size = Vector2i(640,360) * screen_scale
	if Input.is_action_just_pressed("decr_scale"):
		screen_scale -= 1
		if screen_scale < 1: screen_scale = 1
		get_window().size = Vector2i(640,360) * screen_scale

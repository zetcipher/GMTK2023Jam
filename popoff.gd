extends Label

var type := 0

var time := 0.0
var velocity := Vector2.ZERO

func _ready():
	if type == 0:
		modulate = Color(1.0, 1.0, 1.0)
		velocity.y = -256
	else:
		modulate = Color(0.0, 1.0, 0.3)

func _process(delta):
	if time > 0.0:
		if type == 0:
			velocity.y += 16
		if type == 1:
			velocity.y = -16
		position += velocity * delta
	if time > 1.0:
		queue_free()
	
	time += delta

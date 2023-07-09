extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if $Title.visible:
			$Title.hide()
			$Info.show()
		else:
			get_tree().change_scene_to_file("res://battle_scene.tscn")
	if Input.is_action_just_pressed("ui_cancel"):
		$Title.show()
		$Info.hide()

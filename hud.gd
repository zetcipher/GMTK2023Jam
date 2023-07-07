extends Control

var hero_names : Array[String] = ["PumpyClumpy", "ZingyZonger", "YoMama", "D.N."]

var heroHP : Array[int] = [500, 500, 500, 500]
var heroMHP : Array[int] = [500, 500, 500, 500]

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		for i in range(4):
			heroHP[i] = randi_range(0, 500)
		update_heroes()

func update_heroes():
	var idx := 0
	for child in $Heroes.get_children():
		var label := child.get_node("HP") as Label
		var bar := child.get_node("ProgressBar") as TextureProgressBar
		var hname := child.get_node("Name") as Label
		
		hname.text = hero_names[idx]
		label.text = str(heroHP[idx], "/", heroMHP[idx])
		bar.max_value = heroMHP[idx]
		bar.value = heroHP[idx]
		idx += 1

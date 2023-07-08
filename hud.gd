class_name HUD extends Control

var hero_names : Array[String] = ["PumpyClumpy", "ZingyZonger", "YoMama", "D.N."]

var heroHP : Array[int] = [500, 500, 500, 500]
var heroMHP : Array[int] = [500, 500, 500, 500]

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		for i in range(4):
			heroHP[i] = randi_range(0, 500)
		update_heroes()

func set_names(names: Array[String]):
	hero_names = names

func set_mhp(mhp: Array[int]):
	heroMHP = mhp

func set_hp(hp: Array[int]):
	heroHP = hp

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
		if get_percentage(heroHP[idx], heroMHP[idx]) < 0.25: label.modulate = Color(1.0, 0.0, 0.0)
		elif get_percentage(heroHP[idx], heroMHP[idx]) < 0.5: label.modulate = Color(1.0, 1.0, 0.0)
		else: label.modulate = Color(1.0, 1.0, 1.0)
		idx += 1


func get_percentage(a: int, b: int) -> float:
	return float(a) / float(b)

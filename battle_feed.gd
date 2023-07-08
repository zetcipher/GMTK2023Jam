class_name BattleFeed extends Control

var lines : Array[String] = ["", "", "", ""]

func _ready():
	pass

func clear_lines():
	lines = ["", "", "", ""]
	update_text()

func add_line(text : String):
	lines.pop_front()
	lines.append(text)
	print(text)
	update_text()

func update_text():
	$RichTextLabel.text = lines[0] + "\n" + lines[1] + "\n" + lines[2] + "\n" + lines[3]

class_name Interface extends Control

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

var active := true

var cursor_idx := Vector2i.ZERO
var max_idx := Vector2i.ZERO

var pages : Array[String] = []
var inactive_pages : Array[int] = []
var skill_names : Array[String] = ["Strike", "Shoot", "Magic", "Defend", "Heal  One", "Team  Heal", "Buff  ATK", "Buff  EVA"]
var action_names : Array[String] = ["Do  Nothing", "Hero  Hijack", "Flee  Battle"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not active: return
	
	if Input.is_action_just_pressed("ui_left"): move_cursor(Vector2i.LEFT)
	if Input.is_action_just_pressed("ui_right"): move_cursor(Vector2i.RIGHT)
	if Input.is_action_just_pressed("ui_up"): move_cursor(Vector2i.UP)
	if Input.is_action_just_pressed("ui_down"): move_cursor(Vector2i.DOWN)


func move_cursor(dir: Vector2i):
	cursor_idx += dir
	if cursor_idx.x < 0: cursor_idx.x = max_idx.x
	if cursor_idx.x > max_idx.x: cursor_idx.x = 0
	if cursor_idx.y < 0 and cursor_idx.x == max_idx.x: cursor_idx.y = max_idx.y - 1
	if cursor_idx.y < 0: cursor_idx.y = max_idx.y
	if cursor_idx.y > max_idx.y: cursor_idx.y = 0
	if cursor_idx.y > 2 and cursor_idx.x == max_idx.x: cursor_idx.y = 0
	update_cursor()

func update_cursor():
	for child in get_children():
		var cursor := child.get_node("MenuBox/Cursor") as TextureRect
		cursor.position.y = 7 + (cursor_idx.y * 16)
		if child.name.ends_with(str(cursor_idx.x)): child.position.y = 264
		else: child.position.y = 336


func init_pages(actors: Array[Actor]):
	pages.resize(actors.size())
	for i in range(actors.size()):
		setup_page(i, actors[i])
	setup_last()
	max_idx = Vector2i(pages.size() - 1, 3)
	

func setup_page(idx: int, actor: Actor):
	pages[idx] = actor.char_name
	get_node(str("Char", idx, "/NamePlate/Text")).text = pages[idx]
	for i in range(4):
		if not get_node(str("Char", idx, "/MenuBox/Item", i)) is Label: continue
		var label := get_node(str("Char", idx, "/MenuBox/Item", i)) as Label
		label.text = skill_names[actor.set_skills[i]]

func setup_last():
	pages.append("Other")
	var last_idx = pages.size() - 1
	get_node(str("Char", last_idx, "/NamePlate/Text")).text = pages[last_idx]
	for i in range(4):
		if not get_node(str("Char", last_idx, "/MenuBox/Item", i)) is Label: continue
		var label := get_node(str("Char", last_idx, "/MenuBox/Item", i)) as Label
		if i < 3:
			label.text = action_names[i]
		else:
			label.text = ""

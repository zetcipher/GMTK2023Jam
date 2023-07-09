class_name Interface extends Control

signal action_requested(actor_idx: int, skill_slot: int, target_idx: int, hero: bool)
signal set_target_cursor(actor_idx: int, hero: bool)

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

var active := true

var selecting_target := false
var heroes := 1
var monsters := 1

var cursor_idx := Vector2i.ZERO
var max_idx := Vector2i.ZERO

var target_idx := 0
var target_heroes := true

var pages : Array[String] = []
var char0_skills : Array[Skills] = []
var char1_skills : Array[Skills] = []
var char2_skills : Array[Skills] = []
var locked_skills : Array[int] = [-1, -1, -1, -1]
var skill_names : Array[String] = ["Strike", "Shoot", "Lightning", "Defend", "Heal  One", "Team  Heal", "Buff  ATK", "Buff  EVA"]
var action_names : Array[String] = ["Do  Nothing", "Hero  Hijack", "Flee  Battle"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not active: return
	
	if not selecting_target:
		if Input.is_action_just_pressed("ui_left"): move_cursor(Vector2i.LEFT)
		if Input.is_action_just_pressed("ui_right"): move_cursor(Vector2i.RIGHT)
		if Input.is_action_just_pressed("ui_up"): move_cursor(Vector2i.UP)
		if Input.is_action_just_pressed("ui_down"): move_cursor(Vector2i.DOWN)
	
		if Input.is_action_just_pressed("ui_accept"):
			if cursor_idx.x == max_idx.x:
				match cursor_idx.y:
					1: emit_signal("action_requested", -2, -1, -1, false)
					_:
						emit_signal("action_requested", -1, -1, -1, false)
				return
			
			if locked_skills[cursor_idx.x] == cursor_idx.y:
				return
			
			var skill := get_skill() as Skills
			
			match skill:
				Skills.DEFEND, Skills.HEAL_ALL:
					emit_signal("action_requested", cursor_idx.x, cursor_idx.y, cursor_idx.x, false)
					return
				Skills.HEAL_ONE, Skills.BUFF_ATK, Skills.BUFF_EVA:
					selecting_target = true
					target_heroes = false
					emit_signal("set_target_cursor", target_idx, target_heroes)
					return
				_:
					selecting_target = true
					target_heroes = true
					emit_signal("set_target_cursor", target_idx, target_heroes)
					return
	
	if selecting_target:
		if Input.is_action_just_pressed("ui_up"): move_target_cursor(true)
		if Input.is_action_just_pressed("ui_down"): move_target_cursor(false)
		
		if Input.is_action_just_pressed("ui_cancel"):
			selecting_target = false
			target_idx = 0
			emit_signal("set_target_cursor", -1, false)
			return
		
		if Input.is_action_just_pressed("ui_accept"):
			emit_signal("set_target_cursor", -1, false)
			emit_signal("action_requested", cursor_idx.x, cursor_idx.y, target_idx, target_heroes)
			target_idx = 0
			return
	

func move_target_cursor(up: bool):
	if up: target_idx -= 1
	else: target_idx += 1
	if target_idx < 0:
		if target_heroes: target_idx = heroes - 1
		else: target_idx = monsters - 1
	elif target_heroes and target_idx > heroes - 1: target_idx = 0
	elif not target_heroes and target_idx > monsters - 1: target_idx = 0
	
	emit_signal("set_target_cursor", target_idx, target_heroes)

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
		if cursor_idx.y == locked_skills[cursor_idx.x]: cursor.modulate = Color(1.0, 0.0, 0.0)
		else: cursor.modulate = Color(1.0, 1.0, 1.0)

func get_skill() -> Skills:
	var skillset : Array[Skills] = get(str("char",cursor_idx.x,"_skills"))
	return skillset[cursor_idx.y]

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
	set(str("char",idx,"_skills"), actor.set_skills)

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

func remove_page(idx: int): # this is a horrible way to do this, but this is a game jam time crunch moment
	get_node(str("Char",idx)).name = "Dead"
	var i := 0
	for child in get_children():
		if child.name == "Dead": continue
		child.name = "Char" + str(i)
		i += 1
	get_node("Dead").queue_free()

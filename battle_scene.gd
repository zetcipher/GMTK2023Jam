extends Control

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

var turn := 0
var cycles := 0
var wait_time := 0.0
var acting := false

@export var main_party : Array[Actor]
@export var enemy_party : Array[Actor]

var actors : Array[Actor]
var actors_ordered : Array[Actor]

@onready var hud := $HUD as HUD
@onready var feed := $BattleFeed as BattleFeed
@onready var menu := $Interface as Interface

# Called when the node enters the scene tree for the first time.
func _ready():
	$TargetCursor.play("default")
	menu.heroes = main_party.size()
	menu.monsters = enemy_party.size()
	menu.connect("set_target_cursor", Callable(self, "set_target_cursor"))
	menu.connect("action_requested", Callable(self, "override_action"))
	
	#$MainParty/Actor.ATK = 999 # testing
	
	randomize()
	update_hud()
	sort_actors()
	construct_turn(true)
	
	menu.init_pages(enemy_party)
	menu.update_cursor()
	
	acting = false


func _process(delta):
	if wait_time <= 0.0 and acting:
		if turn > actors.size(): 
			turn = 0
			cycles += 1
			conclude_turn()
			acting = false
			menu.cursor_idx = Vector2i.ZERO
			menu.update_cursor()
			menu.selecting_target = false
			menu.active = true
		else: wait_time = 0.25
		if turn == actors.size(): check_who_died()
		if turn < actors.size() and acting: 
			execute_action(actors_ordered[turn], actors_ordered[turn].target)
		turn += 1
	if Input.is_action_just_pressed("ui_accept"): wait_time = 0.0
	
	if acting: 
		feed.show()
		menu.hide()
		menu.active = false
	else: 
		feed.hide()
		menu.show()

func construct_turn(completely_random := false):
	determine_actions(completely_random)
	if randi() % 2 == 0: do_smart_monster_actions(randi_range(1, 5))
	
	for i in range(enemy_party.size()):
		var actor : Actor = enemy_party[i]
		menu.locked_skills[i] = actor.last_action
	for actor in actors: 
		actor.target = determine_target(actor)
		actor.set_tgt_icon(actor.target.sprite_set, !actor.target.monster)

func check_who_died():
	for actor in main_party:
		if actor.HP <= 0: 
			feed.add_line(str("[color=", actor.name_color.to_html(), "]", actor.char_name, "[/color]", " has fallen..."))
			actor.set_anim("dead")
			main_party.erase(actor)
			actors.erase(actor)
			menu.heroes = main_party.size()
			menu.monsters = enemy_party.size()
	for actor in enemy_party:
		if actor.HP <= 0: 
			feed.add_line(str("[color=", actor.name_color.to_html(), "]", actor.char_name, "[/color]", " has been felled!"))
			menu.remove_page(enemy_party.find(actor))
			menu.max_idx.x -= 1
			enemy_party.erase(actor)
			actors.erase(actor)
			actor.hide()
			menu.heroes = main_party.size()
			menu.monsters = enemy_party.size()
			

func conclude_turn():
	feed.clear_lines()
	construct_turn()


func set_target_cursor(act_idx: int, hero: bool):
	if act_idx < 0: 
		$TargetCursor.position = Vector2(-64, -64)
		return
	
	var actor : Actor
	if hero: actor = main_party[act_idx]
	else: actor = enemy_party[act_idx]
	$TargetCursor.position = actor.position
	


func override_action(a_idx: int, slot_idx: int, tgt_idx: int, tgt_is_hero: bool):
	if a_idx == -1:
		start_turn()
		return
	if a_idx == -2:
		menu.locked_skills[menu.monsters] = 1
		var msg := randi_range(0, 3)
		match msg:
			1: feed.add_line("Someone whispered into the ears of the heroes!")
			2: feed.add_line("The heroes might actually have a chance!")
			3: feed.add_line("You don't have much confidence in them, do you?")
			_: feed.add_line("The heroes are getting their act together this turn!")
		do_smart_hero_actions()
		return
	
	var actor : Actor = enemy_party[a_idx]
	actor.next_action = slot_idx
	if tgt_is_hero: actor.target = main_party[tgt_idx]
	else: actor.target = enemy_party[tgt_idx]
	actor.set_icon(actor.set_skills[slot_idx])
	actor.set_tgt_icon(actor.target.sprite_set, !actor.target.monster)
	start_turn()


func start_turn():
	sort_actors_by_defending()
	menu.active = false
	acting = true


func get_party_HP_percentage(heroes: bool) -> float:
	var total_MHP := 1
	var total_HP := 1
	if heroes:
		for actor in main_party: 
			total_HP += actor.HP
			total_MHP += actor.MHP
	else:
		for actor in enemy_party: 
			total_HP += actor.HP
			total_MHP += actor.MHP
	
	return float(total_HP) / float(total_MHP)


func determine_actions(ignore_logic: bool):
	for actor in actors:
		if (actor.char_name == "Delta" and get_party_HP_percentage(true) < 0.75) or (actor.char_name == "Knight" and get_party_HP_percentage(false) < 0.75):
			actor.next_action = 2
			while actor.next_action == actor.last_action:
				actor.next_action = randi_range(1, 2)
		else:
			while actor.next_action == actor.last_action:
				actor.next_action = randi_range(0, actor.set_skills.size() - 1)
			if ignore_logic: actor.next_action = randi_range(0, actor.set_skills.size() - 1)
		actor.set_icon(actor.set_skills[actor.next_action])
		actor.icon_vis(true)

func determine_target(actor: Actor) -> Actor:
	var skill := actor.set_skills[actor.next_action] as Skills
	var is_hero := true
	if enemy_party.has(actor): is_hero = false
	var target : Actor
	if skill == Skills.DEFEND or skill == Skills.HEAL_ALL: target = actor
	elif (is_hero and skill < 4) or (not is_hero and skill > 3): target = enemy_party.pick_random() 
	elif (not is_hero and skill < 4) or (is_hero and skill > 3): target = main_party.pick_random() 
	else: target = actors.pick_random() #failsafe
	
	return target


func do_smart_monster_actions(teamwork := 3):
	for actor in enemy_party:
		if get_party_HP_percentage(false) < 0.75:
			if actor.char_name == "Bird":
				if actor.last_action == 3: 
					actor.next_action = 2
					actor.target = find_lowest_hp_actor(false)
				else: 
					actor.next_action = 3
					actor.target = actor
			if actor.char_name == "Knight":
				if actor.last_action == 2:
					actor.next_action = 1
					actor.target = find_lowest_hp_actor(false)
				else:
					actor.next_action = 2
					actor.target = actor
		else:
			if actor.char_name == "Bird":
				if actor.last_action == 1: 
					actor.next_action = 0
					if randi() % teamwork == 0: actor.target = find_lowest_hp_actor(true)
					else: actor.target = main_party.pick_random()
				else: 
					actor.next_action = 1
					if randi() % teamwork == 0: actor.target = find_lowest_hp_actor(true)
					else: actor.target = main_party.pick_random()
			if actor.char_name == "Knight":
				if actor.last_action == 2:
					actor.next_action = 0
					if randi() % teamwork == 0: actor.target = find_lowest_hp_actor(true)
					else: actor.target = main_party.pick_random()
				else:
					actor.next_action = 2
					actor.target = actor
		if actor.char_name == "Minotaur":
			actor.next_action = 1
			while actor.next_action == actor.last_action: actor.next_action = randi_range(0,2)
			if actor.next_action == 2:
				if enemy_party[0].name == "Knight": actor.target = enemy_party[0]
				elif enemy_party[1].name == "Knight": actor.target = enemy_party[1]
				else: actor.target = actor
			else: 
				if randi() % teamwork == 0: actor.target = find_lowest_hp_actor(true)
				else: actor.target = main_party.pick_random()


func do_smart_hero_actions():
	# if only healer is left, alternate between dealing damage and healing
	if main_party.size() == 1 and main_party[0].char_name == "Delta":
		var actor := main_party[0]
		if actor.last_action == 0: 
			actor.next_action = 1
			actor.target = actor
		else: 
			actor.next_action == 0
			actor.target = find_lowest_hp_actor(false)
		actor.set_icon(actor.set_skills[actor.next_action])
		actor.set_tgt_icon(actor.target.sprite_set, !actor.target.monster)
	else:
		for actor in main_party:
			if actor.char_name == "Delta":
				if get_party_HP_percentage(true) < 0.75:
					if actor.last_action == 1:
						actor.next_action == 2
						actor.target = actor
					else:
						actor.next_action == 1
						actor.target = find_lowest_hp_actor(true)
				else:
					if actor.last_action == 0:
						actor.next_action = 3
						actor.target = actor
					else:
						actor.next_action = 0
						actor.target = find_lowest_hp_actor(false)
				actor.set_icon(actor.set_skills[actor.next_action])
				actor.set_tgt_icon(actor.target.sprite_set, !actor.target.monster)
			else:
				if actor.last_action != 0:
					actor.next_action = 0
				elif actor.last_action != 1:
					actor.next_action = 1
				actor.target = find_lowest_hp_actor(false)
				actor.set_icon(actor.set_skills[actor.next_action])
				actor.set_tgt_icon(actor.target.sprite_set, !actor.target.monster)
	start_turn()



func find_lowest_hp_actor(hero_side: bool) -> Actor:
	var a : Actor
	var lowest_hp := 999
	
	if not hero_side:
		for actor in enemy_party:
			if actor.HP < lowest_hp:
				lowest_hp = actor.HP
				a = actor
	else:
		for actor in main_party:
			if actor.HP < lowest_hp:
				lowest_hp = actor.HP
				a = actor
	
	return a


func execute_action(actor: Actor, target: Actor):
	var action := actor.set_skills[actor.next_action] as Skills
	var damage := 0
	var def_mult := 1
	if target.set_skills[target.next_action] == Skills.DEFEND: def_mult = 3
	match action:
		Skills.GUN:
			damage = calc_damage(actor.ATK, target.DEF * def_mult, 0)
		Skills.MAGIC:
			damage = calc_damage(actor.MAT, target.MDF * def_mult, 2)
		Skills.DEFEND: 
			pass # doesn't need a function
		Skills.HEAL_ONE:
			damage = calc_damage(actor.MAT * 1.5, target.DEF, 3)
		Skills.HEAL_ALL:
			damage = calc_damage(actor.MAT, target.DEF, 3)
		Skills.BUFF_ATK:
			pass # BUFF FUNCTION
		Skills.BUFF_EVA:
			pass # BUFF FUNCTION
		_:
			damage = calc_damage(actor.ATK, target.DEF * def_mult, 0)
	send_line_to_feed(actor, target, action, damage)
	actor.last_action = actor.next_action
	if action != Skills.HEAL_ALL and action != Skills.DEFEND:
		target.change_hp(-damage)
		if action != Skills.HEAL_ONE:
			create_popoff(target.position, damage, 0)
		else:
			create_popoff(target.position, damage, 1)
	elif action != Skills.DEFEND:
		if main_party.has(actor):
			for p in main_party: 
				p.change_hp(damage)
				create_popoff(p.position, damage, 1)
		else:
			for p in enemy_party: 
				p.change_hp(damage)
				create_popoff(p.position, damage, 1)
	

func create_popoff(pos: Vector2, dmg: int, type := 0):
	var popoff := preload("res://popoff.tscn").instantiate()
	popoff.position = pos
	popoff.text = str(dmg)
	popoff.type = type
	add_child(popoff)
	

func calc_damage(atk: int, def: int, type := 0) -> int:
	var dmg: int = 0
	if type == 2: 
		dmg = atk - def # magic
		if dmg < 1: dmg = 1
	if type == 3: dmg = atk # healing
	else: 
		dmg = atk * 2 - def
		if dmg < 1: dmg = 1
	
	dmg *= randf_range(0.9, 1.1)
	
	return dmg


func send_line_to_feed(actor: Actor, target: Actor, action: Skills, damage := 0):
	var act_str := str("[color=", actor.name_color.to_html(false), "]", actor.char_name, "[/color]")
	var tgt_str := str("[color=", target.name_color.to_html(false), "]", target.char_name, "[/color]")
	
	match action:
		Skills.GUN:
			feed.add_line(str(act_str, " shot at ", tgt_str, " for [b]", damage, "[/b] damage!"))
		Skills.MAGIC:
			feed.add_line(str(act_str, " cast lightning at ", tgt_str, " for [b]", damage, "[/b] damage!"))
		Skills.DEFEND: 
			feed.add_line(str(act_str, " is defending..."))
		Skills.HEAL_ONE:
			feed.add_line(str(act_str, " healed ", tgt_str, " for [b]", damage, "[/b] HP!"))
		Skills.HEAL_ALL:
			feed.add_line(str(act_str, " healed their party for [b]", damage, "[/b] HP!"))
		Skills.BUFF_ATK:
			feed.add_line(str(act_str, " gave a strength buff to ", tgt_str, "!"))
		Skills.BUFF_EVA:
			feed.add_line(str(act_str, " gave an evasion buff to ", tgt_str, "!"))
		_:
			feed.add_line(str(act_str, " struck ", tgt_str, " for [b]", damage, "[/b] damage!"))
	


func sort_actors(): # This function sorts actors by speed, highest first, lowest last.
	actors = main_party + enemy_party
	var fastest_actors : Array[Actor] = []
	var speeds : Array[int]
	for actor in actors:
		speeds.append(actor.SPD)
	speeds.sort()
	speeds.reverse()
	for i in range(speeds.size()):
		for actor in actors:
			if actor.SPD == speeds[i] and not fastest_actors.has(actor):
				fastest_actors.append(actor)
				break
#	print(actors)
#	print(speeds)
#	print(fastest_actors)
	actors = fastest_actors

func sort_actors_by_defending():
	actors_ordered = []
	for actor in actors:
		if actor.set_skills[actor.next_action] == 3:
			actors_ordered.append(actor)
	for actor in actors:
		if actor.set_skills[actor.next_action] != 3:
			actors_ordered.append(actor)
#	print(actors)
#	print(actors_ordered)


func update_hud():
	hud.set_hp([main_party[0].HP, main_party[1].HP, main_party[2].HP, main_party[3].HP])
	hud.set_mhp([main_party[0].MHP, main_party[1].MHP, main_party[2].MHP, main_party[3].MHP])
	hud.set_names([main_party[0].char_name, main_party[1].char_name, main_party[2].char_name, main_party[3].char_name])
	hud.update_heroes()

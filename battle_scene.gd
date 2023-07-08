extends Control

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

var turn := 0
var wait_time := 0.0
var acting := false

@export var main_party : Array[Actor]
@export var enemy_party : Array[Actor]

var actors : Array[Actor]
var defenders : Array[Actor]

@onready var hud := $HUD as HUD
@onready var feed := $BattleFeed as BattleFeed

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size *= 3
	
	feed.clear_lines()
	#feed.hide()
	update_hud()
	sort_actors()
	determine_actions()
	
	acting = false


func _process(delta):
	if wait_time <= 0.0:
		if turn == 0:
			for actor in main_party:
				if actor.HP <= 0: 
					feed.add_line(str("[color=", actor.name_color.to_html(), "]", actor.char_name, "[/color]", " has fallen..."))
					actor.set_anim("dead")
					main_party.erase(actor)
					actors.erase(actor)
			for actor in enemy_party:
				if actor.HP <= 0: 
					feed.add_line(str("[color=", actor.name_color.to_html(), "]", actor.char_name, "[/color]", " has been felled!"))
					main_party.erase(actor)
					actors.erase(actor)
			determine_actions()
			
			
			for actor in actors: actor.target = determine_target(actor)
		
		execute_action(actors[turn], actors[turn].target)
		turn += 1
		if turn > actors.size() - 1: turn = 0
		wait_time = 0.25
	if Input.is_action_just_pressed("ui_accept"): wait_time = 0.0
	pass


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


func determine_actions():
	for actor in actors:
		if (actor.char_name == "Delta" and get_party_HP_percentage(true) < 0.75) or (actor.char_name == "Knight" and get_party_HP_percentage(false) < 0.75):
			actor.next_action = 2
			while actor.next_action == actor.last_action:
				actor.next_action = randi_range(1, 2)
		else:
			while actor.next_action == actor.last_action:
				actor.next_action = randi_range(0, actor.set_skills.size() - 1)
		actor.set_icon(actor.set_skills[actor.next_action])
		actor.icon_vis(true)

func determine_target(actor: Actor) -> Actor:
	var skill := actor.set_skills[actor.next_action] as Skills
	var is_hero := true
	if enemy_party.has(actor): is_hero = false
	var target : Actor
	if (is_hero and skill < 4) or (not is_hero and skill > 3): target = enemy_party.pick_random() 
	elif (not is_hero and skill < 4) or (is_hero and skill > 3): target = main_party.pick_random() 
	else: target = actors.pick_random() #failsafe
	
	return target

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
	if action != Skills.HEAL_ALL:
		target.change_hp(-damage)
	else:
		if main_party.has(actor):
			for p in main_party: p.change_hp(-damage)
		else:
			for p in enemy_party: p.change_hp(-damage)


func calc_damage(atk: int, def: int, type := 0) -> int:
	var dmg: int = 0
	if type == 2: 
		dmg = atk - def # magic
		if dmg < 1: dmg = 1
	if type == 3: dmg = -atk
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
			feed.add_line(str(act_str, " cast a spell at ", tgt_str, " for [b]", damage, "[/b] damage!"))
		Skills.DEFEND: 
			feed.add_line(str(act_str, " is defending..."))
		Skills.HEAL_ONE:
			feed.add_line(str(act_str, " healed ", tgt_str, " for [b]", -damage, "[/b] HP!"))
		Skills.HEAL_ALL:
			feed.add_line(str(act_str, " healed their party for [b]", -damage, "[/b] HP!"))
		Skills.BUFF_ATK:
			feed.add_line(str(act_str, " gave a strength buff to ", tgt_str, "!"))
		Skills.BUFF_EVA:
			feed.add_line(str(act_str, " gave an evasion buff to ", tgt_str, "!"))
		_:
			feed.add_line(str(act_str, " struck ", tgt_str, " for [b]", damage, "[/b] damage!"))
	


func sort_actors(): # This function sorts actors by speed, highest first, lowest last.
	actors = main_party + enemy_party
	var fastest_actors : Array[Actor]
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
	


func update_hud():
	hud.set_hp([main_party[0].HP, main_party[1].HP, main_party[2].HP, main_party[3].HP])
	hud.set_mhp([main_party[0].MHP, main_party[1].MHP, main_party[2].MHP, main_party[3].MHP])
	hud.set_names([main_party[0].char_name, main_party[1].char_name, main_party[2].char_name, main_party[3].char_name])
	hud.update_heroes()

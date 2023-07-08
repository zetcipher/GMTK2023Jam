extends Control

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

var turn := 0
var acting := false

@export var main_party : Array[Actor]
@export var enemy_party : Array[Actor]

var actors : Array[Actor]

@onready var hud := $HUD as HUD
@onready var feed := $BattleFeed as BattleFeed

# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().size *= 3
	
	feed.clear_lines()
	#feed.hide()
	update_hud()
	sort_actors()
	
	acting = true


func _process(delta):
	if turn == 0:
		determine_actions()
	execute_action(actors[turn], actors.pick_random())
	turn += 1
	if turn > actors.size() - 1: turn = 0


func determine_actions():
	for actor in actors:
		actor.next_action = randi_range(0, 2)

func execute_action(actor: Actor, target: Actor):
	var action := actor.set_skills[actor.next_action] as Skills
	var damage := 0
	match action:
		Skills.GUN:
			damage = calc_damage(actor.ATK, target.DEF, 0)
		Skills.MAGIC:
			damage = calc_damage(actor.MAT, target.DEF, 2)
		Skills.DEFEND: 
			pass # doesn't need a function
		Skills.HEAL_ONE:
			damage = calc_damage(-actor.MAT * 1.5, target.DEF, 2)
		Skills.HEAL_ALL:
			damage = calc_damage(-actor.MAT, target.DEF, 2)
		Skills.BUFF_ATK:
			pass # BUFF FUNCTION
		Skills.BUFF_EVA:
			pass # BUFF FUNCTION
		_:
			damage = calc_damage(actor.ATK, target.DEF, 0)
	send_line_to_feed(actor, target, action, damage)


func calc_damage(atk: int, def: int, type := 0) -> int:
	var dmg: int = 0
	if type == 2: dmg = atk # magic
	else: dmg = atk * 2 - def
	
	return dmg


func send_line_to_feed(actor: Actor, target: Actor, action: Skills, damage := 0):
	var act_str := str("[color=", actor.name_color, "]", actor.char_name, "[/color]")
	var tgt_str := str("[color=", target.name_color, "]", target.char_name, "[/color]")
	
	match action:
		Skills.GUN:
			feed.add_line(str(act_str, " shot at ", tgt_str, " for ", damage, "damage!"))
		Skills.MAGIC:
			feed.add_line(str(act_str, " cast a spell at ", tgt_str, " for ", damage, "damage!"))
		Skills.DEFEND: 
			feed.add_line(str(act_str, " is defending..."))
		Skills.HEAL_ONE:
			feed.add_line(str(act_str, " healed ", tgt_str, " for ", damage, "HP!"))
		Skills.HEAL_ALL:
			feed.add_line(str(act_str, " healed their party for ", damage, "HP!"))
		Skills.BUFF_ATK:
			feed.add_line(str(act_str, " gave a strength buff to ", tgt_str, "!"))
		Skills.BUFF_EVA:
			feed.add_line(str(act_str, " gave an evasion buff to ", tgt_str, "!"))
		_:
			feed.add_line(str(act_str, " struck ", tgt_str, " for ", damage, "damage!"))
	


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

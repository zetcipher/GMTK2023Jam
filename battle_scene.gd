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
	feed.hide()
	update_hud()
	sort_actors()
	
	acting = true


func _process(delta):
	pass #TODO: make actors do shit


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

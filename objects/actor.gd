class_name Actor extends Node2D

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

@export var char_name := "John Dokapon"
@export var name_color := Color("AFA")
@export var monster := false
@export var sprite_set := 0

@export var MHP := 100
@export var ATK := 10
@export var DEF := 10
@export var MAT := 10
@export var MDF := 10
@export var SPD := 10
@export var EVA := 0.0

var HP := 100

@export var set_skills : Array[Skills] = [Skills.MELEE, Skills.BUFF_ATK, Skills.DEFEND]

func set_sprites():
	if not monster:
		match sprite_set:
			1: $CharSprite.texture = preload("res://svb_future1.png")
			2: $CharSprite.texture = preload("res://svb_future2.png")
			3: $CharSprite.texture = preload("res://svb_future3.png")
			4: $CharSprite.texture = preload("res://svb_future4.png")
			_: $CharSprite.texture = preload("res://4_5.png")
	
	if monster:
		match sprite_set:
			1: $MonSprite.animation = "knight"
			2: $MonSprite.animation = "minotaur"
			_: $MonSprite.animation = "bird"

func change_hp(amount: int):
	HP += amount
	if HP > MHP: HP = MHP
	if HP < 0: HP = 0

func set_anim(anim_name: String):
	$CharAnimator.play(anim_name)

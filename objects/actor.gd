class_name Actor extends Node2D

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

@export var char_name := "John Dokapon"
@export var name_color := Color("AFA")
@export var monster := false
@export var sprite_set := 0
@export var face_right := false
@export var cant_be_targeted := false

@export var MHP := 100
@export var ATK := 10
@export var DEF := 10
@export var MAT := 10
@export var MDF := 10
@export var SPD := 10
@export var EVA := 0.0

var HP := 999999

@export var set_skills : Array[Skills] = [Skills.MELEE, Skills.BUFF_ATK, Skills.DEFEND]
var next_action := 0
var last_action := -1
var target : Actor

func _ready():
	set_sprites()
	if face_right:
		$CharSprite.flip_h = true
		$MonSprite.flip_h = true
		$Skill.position.x -= 12
		$hpbar.position.x += 16
	else:
		$CharSprite.flip_h = false
		$MonSprite.flip_h = false
		$Skill.position.x += 12
		$hpbar.position.x -= 24
	
	if not monster:
		set_anim("idle")
		$MonSprite.hide()
		$CharSprite.show()
	else:
		$MonSprite.show()
		$CharSprite.hide()
		$MonSprite.play()
	change_hp(0)

func icon_vis(on: bool):
	$Skill.visible = on

func set_icon(skill: int):
	$Skill.frame = skill

func set_sprites():
	if not monster:
		match sprite_set:
			1: 
				$CharSprite.texture = preload("res://svb_future1.png")
				$hpbar/name.frame = 0
			2: 
				$CharSprite.texture = preload("res://svb_future2.png")
				$hpbar/name.frame = 1
			3: 
				$CharSprite.texture = preload("res://svb_future3.png")
				$hpbar/name.frame = 2
			4: 
				$CharSprite.texture = preload("res://svb_future4.png")
				$hpbar/name.frame = 3
			_: 
				$CharSprite.texture = preload("res://4_5.png")
				$hpbar/name.frame = 7
				$hpbar.hide()
	
	if monster:
		match sprite_set:
			1: 
				$MonSprite.animation = "knight"
				$hpbar/name.frame = 5
			2: 
				$MonSprite.animation = "minotaur"
				$hpbar/name.frame = 6
			_: 
				$MonSprite.animation = "bird"
				$hpbar/name.frame = 4

func change_hp(amount: int):
	HP += amount
	if HP > MHP: HP = MHP
	if HP < 0: HP = 0
	$hpbar.max_value = MHP
	$hpbar.value = HP
	$hpbar/HP.text = str(HP, "/", MHP)
	if get_hp_percentage() < 0.25: $hpbar/HP.modulate = Color(1.0, 0.0, 0.0)
	elif get_hp_percentage() < 0.5: $hpbar/HP.modulate = Color(1.0, 1.0, 0.0)
	else: $hpbar/HP.modulate = Color(1.0, 1.0, 1.0)

func get_hp_percentage() -> float:
	return float(HP) / float(MHP)

func set_anim(anim_name: String):
	$CharAnimator.play(anim_name)

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

var atk_buff_timer := 0
var eva_buff_timer := 0

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
		$Skill/Target.position.x -= 18
		$hpbar.position.x += 16
		$hpbar/atkbuff.position.x += 28
		$hpbar/evabuff.position.x += 28
	else:
		$CharSprite.flip_h = false
		$MonSprite.flip_h = false
		$Skill.position.x += 12
		$Skill/Target.position.x += 18
		$hpbar.position.x -= 24
		$hpbar/atkbuff.position.x -= 28
		$hpbar/evabuff.position.x -= 28
	
	if not monster:
		set_anim("idle")
		$MonSprite.hide()
		$CharSprite.show()
	else:
		$MonSprite.show()
		$CharSprite.hide()
		$MonSprite.play()
	change_hp(0)

func _process(_delta):
	if atk_buff_timer: $hpbar/atkbuff.show()
	else: $hpbar/atkbuff.hide()
	if eva_buff_timer: $hpbar/evabuff.show()
	else: $hpbar/evabuff.hide()

func get_true_ATK() -> int:
	var a = ATK
	if atk_buff_timer: a *= 2
	return a

func get_true_MAT() -> int:
	var a = MAT
	if atk_buff_timer: a *= 2
	return a

func get_true_EVA() -> float:
	var a = EVA
	if eva_buff_timer: a = 0.75
	return a

func should_dodge() -> bool:
	if randf_range(0.0, 1.0) >= get_true_EVA(): return false
	else: return true

func icon_vis(on: bool):
	$Skill.visible = on

func set_icon(skill: int):
	$Skill.frame = skill

func set_tgt_icon(act_sprite: int, hero: bool):
	if hero: $Skill/Target.frame = act_sprite - 1
	else: $Skill/Target.frame = act_sprite + 4

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

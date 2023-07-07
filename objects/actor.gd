class_name Actor extends Node2D

enum Skills {MELEE, GUN, MAGIC, DEFEND, HEAL_ONE, HEAL_ALL, BUFF_ATK, BUFF_EVA}

@export var char_name := "John Dokapon"
@export var name_color := Color("AFA")
@export var monster := false

@export var MHP := 100
@export var ATK := 10
@export var DEF := 10
@export var MAT := 10
@export var MDF := 10
@export var SPD := 10
@export var EVA := 0.0

var HP := 100

@export var set_skills : Array[Skills] = [Skills.MELEE, Skills.BUFF_ATK, Skills.DEFEND]

extends Node2D


export (PackedScene) var character_1
export (PackedScene) var character_2
export var damageList = []


# Called when the node enters the scene tree for the first time.
func _ready():
	damageList.append(0)
	damageList.append(0)
	assign_characters()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func assign_characters():
	$Combat.character_1 = character_1
	$Combat.character_2 = character_2


func update_characters(damage_1, damage_2):
	damageList[0] = damage_1
	damageList[1] = damage_2

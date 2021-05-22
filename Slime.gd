extends Node2D


signal end_turn

export var level = 3
var actor_type = "mob"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func select_target(targets):
	var min_value = targets[0].attacked_this_turn
	var selected_target = targets[0]
	for target in targets:
		if target.attacked_this_turn < min_value:
			min_value = target.attacked_this_turn
			selected_target = target
	selected_target.attacked_this_turn += 1
	return selected_target

func die():
	queue_free()

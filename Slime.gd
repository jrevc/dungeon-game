extends Node2D


signal end_turn

var level = 3
var actor_type = "mob"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func take_damage():
	queue_free()

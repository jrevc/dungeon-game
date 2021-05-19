extends Node2D


signal end_turn

var level = 1
var damage_type
var armor_bonus = 2
var shield_bonus = 1
var max_hp
var current_hp
var wealth
var actor_type = "character"


# Called when the node enters the scene tree for the first time.
func _ready():
	max_hp = 6 + level
	current_hp = max_hp
	damage_type = "crushing"
	update_life_display()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _input(_event):
	if Input.is_action_just_pressed("ui_select"):
		attack()

# ATTACKING

func attack():
	var roll = randi() % 6 + 1
	var level_bonus = level
	var total = roll + level_bonus
	var attack_roll = { "Total": total, "Roll": roll, "LevelBonus": level_bonus, "Type": damage_type }
	animate_attack()
	return attack_roll


func animate_attack():
	yield(get_tree().create_timer(1.0), "timeout") # Attack animation here?
	emit_signal("end_turn")


# DEFENDING

func defend():
	var roll = randi() % 6 + 1
	var passive_defense = roll + armor_bonus
	var active_defense = passive_defense + shield_bonus
	var defense_roll = { "Roll": roll, "Passive": passive_defense, "Active": active_defense }
	animate_defense()
	return defense_roll


func animate_defense():
	yield(get_tree().create_timer(1.0), "timeout")
	emit_signal("end_turn")

# TAKING DAMAGE

func update_life_display():
	$Life.text = str(current_hp) + " / " + str(max_hp)


func take_damage(damage = 1):
	current_hp -= damage
	update_life_display()


func die():
	queue_free()

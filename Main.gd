extends Node2D


signal report_turn
signal complete_turn

# Character variables
var active_character
var active_mob
export (PackedScene) var Slime
var current_mob_level
var enemies = []
var enemy_slots = [ Vector2(120, 140), Vector2(180, 140), Vector2(240, 140), Vector2(120, 200), Vector2(180, 200), Vector2(240, 200) ]

# Turn-based combat variables
export var turn_order = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	# Listeners
	$UI/BtnAttack.connect("pressed", self, "_on_Attack")
	$UI/BtnDefend.connect("pressed", self, "_on_Defend")
	
	# Start combat!
	start_combat()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func start_combat():
	yield(spawn_monster(3, Slime), "completed")
	yield(populate_queue(), "completed")
	next_turn(0)


func spawn_monster(count, monster):
	yield(get_tree(), "idle_frame")
	for i in range(count):
		var mob = monster.instance()
		mob.name += str(i + 1)
		var randomPosIndex = randi() % enemy_slots.size()
		print("Monster position index: " + str(randomPosIndex))
		var position = enemy_slots[randomPosIndex]
		enemy_slots.remove(randomPosIndex)
		add_child(mob)
		enemies.append(mob)
		mob.position = position
		if i == 0:
			current_mob_level = mob.level


func populate_queue():
	yield(get_tree(), "idle_frame")
	for character in get_tree().get_nodes_in_group("characters"):
		turn_order.append(character)
	for mob in get_tree().get_nodes_in_group("mobs"):
		turn_order.append(mob)
	pass


# ATTACK RESOLUTION

func _on_Attack():
	$UI/BtnAttack.disabled = true
	var attack_results = active_character.attack()
	resolve_player_attack(attack_results)


func resolve_player_attack(attack_results):
	yield(self, "report_turn")
	$UI.log_message(active_character.name + " attacks (" + str(attack_results["Total"]) + ")!")
	print("Attack roll: " + str(attack_results))
	var mobs_to_kill = attack_results["Total"] / current_mob_level
	
	# If overkill, adjust number
	if mobs_to_kill > enemies.size():
		mobs_to_kill = enemies.size()
		
	kill_mobs(mobs_to_kill)


func kill_mobs(mobs_to_kill):
	for i in range(mobs_to_kill - 1, -1, -1):
		var dead_mob = enemies[i]
		enemies.remove(i)
		dead_mob.die()
		turn_order.erase(dead_mob)
	yield(get_tree().create_timer(0.5), "timeout") # Dying animation here?
	
	# Report mobs killed
	if mobs_to_kill <= 0:
		$UI.log_message("No monsters killed!")
	if mobs_to_kill > 1:
		$UI.log_message(str(mobs_to_kill) + " monsters killed!")
	else:
		$UI.log_message(str(mobs_to_kill) + " monster killed!")
	emit_signal("complete_turn")


# DEFENSE RESOLUTION

func _on_Defend():
	$UI/BtnDefend.disabled = true
	var defend_results = active_character.defend()
	resolve_player_defend(defend_results, active_mob)


func resolve_player_defend(defend_results, attacker):
	yield(self, "report_turn")
	$UI.log_message("Attacked by " + attacker.name + "! " + active_character.name + " defends (" + str(defend_results["Active"]) + ")!")
	print("Defense roll: " + str(defend_results))
	yield(get_tree().create_timer(0.5), "timeout") # Defense animation here?
	if defend_results["Active"] > current_mob_level:
		$UI.log_message(active_character.name + " defends successfully!")
	else:
		$UI.log_message(active_character.name + " takes damage!")
		active_character.take_damage()
	emit_signal("complete_turn")


# TURN MANAGEMENT

func next_turn(turn_index):
	print("--- NEW TURN ---")
	var current_actor = turn_order[turn_index]
	
	# Change state of game depending on active character
	if current_actor.actor_type == "character":
		$UI/BtnAttack.disabled = false
		active_character = current_actor
		print("Active character: " + active_character.name)
	elif current_actor.actor_type == "mob":
		$UI/BtnDefend.disabled = false
		active_mob = current_actor
	print("Waiting for player action...")
	
	# Wait for active character to finish their presentation/animation
	yield(active_character, "end_turn")
	
	# Signal the end of this turn and report the outcome
	emit_signal("report_turn")
	yield(self, "complete_turn")
	
	# Start a new turn
	var next_index = (turn_index + 1) % turn_order.size()
	print("Moving to next actor (" + str(next_index) + ")...")
	next_turn(next_index)

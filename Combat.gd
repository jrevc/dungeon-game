extends Node2D


signal report_turn
signal complete_turn
signal assign_existing_damage

var rng = RandomNumberGenerator.new()

# Character variables
var active_character
var active_mob
export (PackedScene) var chosen_mob
var character_1
var character_2
var current_mob_level
var characters = []
var enemies = []
var enemy_positions = []

# Turn-based combat variables
export var turn_order = []


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	enemy_positions = $MobSpawnPoints.get_children()
	enemy_positions.shuffle()
	
	# Listeners
	$UI/BtnAttack.connect("pressed", self, "_on_Attack")
	$UI/BtnDefend.connect("pressed", self, "_on_Defend")
	$UI/BtnNextBattle.connect("pressed", self, "_on_NextBattle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_NextBattle():
	$UI/BtnNextBattle.hide()
	start_combat()


func start_combat():
	yield(spawn_characters(), "completed")
	var monster_count = 0
	var spawn_dice = 1
	for i in spawn_dice:
		monster_count += rng.randi_range(1, 6)
	yield(spawn_monster(monster_count, chosen_mob), "completed")
	yield(populate_queue(), "completed")
	for i in 2:
		characters[i].take_damage(get_parent().damageList[i])
	next_turn(0)


func end_combat():
	turn_order.clear()
	
	# Hide pointer
	$Pointer/Container.position = Vector2(0, 0)
	
	# Update parent node
	get_parent().update_characters(characters[0].max_hp -
		characters[0].current_hp, characters[1].max_hp -
		characters[1].current_hp)
	
	# Forget about characters in combat
	characters[0].queue_free()
	characters[1].queue_free()
	characters.clear()
	$UI/BtnNextBattle.show()


func spawn_characters():
	yield(get_tree(), "idle_frame")
	for i in 2:
		var character_to_spawn
		if i == 0:
			character_to_spawn = character_1
		else:
			character_to_spawn = character_2
		var new_character = character_to_spawn.instance()
		characters.append(new_character)
		new_character.position = $CharacterSpawnPoints.get_child(i).global_position
		add_child(new_character)


func spawn_monster(count, monster):
	yield(get_tree(), "idle_frame")
	for i in range(count):
		var mob = monster.instance()
		mob.name += " " + str(i + 1)
#		var spawn_point = $SpawnPoints.get_child(i)
		var position = enemy_positions[i].global_position
		add_child(mob)
		enemies.append(mob)
		mob.position = position + Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
		mob.scale.x = rng.randi_range(0, 1) * 2 - 1
		if i == 0:
			current_mob_level = mob.level
		arrange_monsters()


func arrange_monsters():
	enemies.sort_custom(self, "sort_enemies")
	for mob in enemies:
#		print("Moving " + mob.name + " up!")
		mob.raise()


static func sort_enemies(a, b):
	return a.position.y < b.position.y


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
	print("Attack roll: " + str(attack_results))
	var mobs_to_kill = floor(attack_results["Total"] / current_mob_level)
	
	if attack_results["Roll"] <= 1:
		# If rolled a 1, automatically miss
		mobs_to_kill = 0
		$UI.log_message(active_character.name + " fumbles and misses!")
	elif attack_results["Roll"] >= 6:
		# If rolled a 6, keep rolling and adding
		# until the next roll is not a 6
		var new_total = exploding_roll(attack_results["Total"])
		mobs_to_kill = floor(new_total / current_mob_level)
		var difference = new_total - attack_results["Total"]
		$UI.log_message(active_character.name + " attacks mightily (" +
			str(attack_results["Total"]) + " + " + str(difference) + ")!")
	else:
		$UI.log_message(active_character.name + " attacks (" +
			str(attack_results["Total"]) + ")!")
	
	# If overkill, adjust number
	if mobs_to_kill > enemies.size():
		mobs_to_kill = enemies.size()
		
	kill_mobs(mobs_to_kill)


func exploding_roll(orig_total):
	var explode = true
	while explode:
		var new_roll = rng.randi_range(1, 6)
		orig_total += new_roll
		if new_roll < 6:
			explode = false
	return orig_total


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
	elif mobs_to_kill > 1:
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
	if defend_results["Roll"] <= 1:
		$UI.log_message(active_character.name + " fumbles and takes damage!")
		active_character.take_damage()
	elif defend_results["Roll"] >= 6 || defend_results["Active"] > current_mob_level:
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
		# Build a list of targets
		var targets = []
		for actor in turn_order:
			if actor.actor_type == "character":
				targets.append(actor)
		active_character = active_mob.select_target(targets)
	print("Waiting for player action...")
	
	# Move pointer
	$Pointer/Container.position = current_actor.position - Vector2(0, current_actor.texture.get_size().y / 2)
	$Pointer/Container.raise()
	
	# Move camera
	$CombatCamera.targetPosition = active_character.position + Vector2(0, 10)
	
	# Wait for active character to finish their presentation/animation
	yield(active_character, "end_turn")
	
	# Signal the end of this turn and report the outcome
	emit_signal("report_turn")
	yield(self, "complete_turn")
	
	# Start a new turn
	var next_index = (turn_index + 1) % turn_order.size()
	print("Moving to next actor (" + str(next_index) + ")...")
	
	if enemies.size() <= 0:
		end_combat()
	else:
		next_turn(next_index)

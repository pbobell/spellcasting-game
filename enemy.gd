extends CharacterBody3D


var abilityDictionary: Dictionary[String, PackedScene] = {
	g.ABILITY_ABSORB: preload("res://abilities/absorb.tscn"),
	g.ABILITY_BLAST: preload("res://abilities/blast.tscn"),
	g.ABILITY_BLOCK: preload("res://abilities/block.tscn"),
	g.ABILITY_CHARGE: preload("res://abilities/charge.tscn"),
	g.ABILITY_FOCUS: preload("res://abilities/focus.tscn"),
	g.ABILITY_HEAL: preload("res://abilities/heal.tscn"),
	g.ABILITY_PULL: preload("res://abilities/pull.tscn"),
	g.ABILITY_PUSH: preload("res://abilities/push.tscn"),
	g.ABILITY_REFLECT: preload("res://abilities/reflect.tscn"),
	g.ABILITY_RESTORE: preload("res://abilities/restore.tscn")
}

var priority: Dictionary[String, float] = {
	g.ABILITY_ABSORB: 0,
	g.ABILITY_BLAST: 0,
	g.ABILITY_BLOCK: 0,
	g.ABILITY_CHARGE: 0,
	g.ABILITY_FOCUS: 0,
	g.ABILITY_HEAL: 0,
	g.ABILITY_PULL: 0,
	g.ABILITY_PUSH: 0,
	g.ABILITY_REFLECT: 0,
	g.ABILITY_RESTORE: 0
}

enum THINK_MODES {
	DEFAULT,
	AGGRESSIVE,
	DEFENSIVE,
	PASSIVE,
}

@export var think_mode: THINK_MODES = THINK_MODES.DEFAULT

const RES_DIR = "res://abilities"
var abilities: Dictionary

var stopped: bool = false

func game_over():
	stopped = true
	animation_queue = []
	$orc/AnimationPlayer.stop()

@export var health_max: int = 10
@export var mana_max: int = 10

var health: int = health_max :
	set(value):
		health = value
		if get_node_or_null("HealthBar"):
			$HealthBar.mesh.material.set_shader_parameter("health", float(health) / health_max)

var mana: int = mana_max :
	set(value):
		mana = value
		if get_node_or_null("ManaBar"):
			$ManaBar.value = value

var dead: bool = false

## Position adjustment for spells to appear in front of body
@export var pos_adjustment: Vector3 = Vector3(0, 1, -4)
## Position adjustment for calculations involving the player (target)'s center.
@export var player_center_adjustment: Vector3 = Vector3(2, 10, 0)
## Additional position adjustment for heal spell due to model center
@export var heal_adjustment: Vector3 = Vector3(0, 0, 2)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var active_block: Node = null

var npc_aggression = randi_range(5, 15)
var npc_preservation = 20 - npc_aggression

var ANIMATIONS = {
	"punch": ["AnimationLibrary_Godot_Standard/Punch_Enter",
			  "AnimationLibrary_Godot_Standard/Punch_Jab"],
	"hit": ["AnimationLibrary_Godot_Standard/Hit_Chest"],
	"headshot": ["AnimationLibrary_Godot_Standard/Hit_Head"],
	"jump": ["AnimationLibrary_Godot_Standard/Jump_Start",
			 "AnimationLibrary_Godot_Standard/Jump"],
	"cast_shoot_full": ["AnimationLibrary_Godot_Standard/Spell_Simple_Enter",
						"AnimationLibrary_Godot_Standard/Spell_Simple_Shoot",
						"AnimationLibrary_Godot_Standard/Spell_Simple_Exit"]
}

const animation_idle = "AnimationLibrary_Godot_Standard/Idle"
const animation_death = "AnimationLibrary_Godot_Standard/Death01"

## Default animation to return to when queue is empty.
@export var default_animation = animation_idle
var last_animation = false
var finished_animating = false

## Animations to play before returning to default.
var animation_queue = []

func _ready() -> void:
	print("Aggression: ", npc_aggression, ", Preservation: ", npc_preservation)
	health = health_max
	play_default_animation()
	_load_abilities()

func _load_abilities() -> void:
	for f in DirAccess.get_files_at("res://abilities"):
		if not f.ends_with("tres"):
			continue
		f = RES_DIR.path_join(f)
		var data = ResourceLoader.load(f)
		var ability = Ability.from_data(data)
		abilities[ability.name] = ability

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func play_default_animation() -> void:
	$orc/AnimationPlayer.play(default_animation)

func play_queue(new_queue = null) -> void:
	if new_queue != null:
		animation_queue = new_queue.duplicate()
	if len(animation_queue) == 0:
		if not finished_animating:
			if last_animation:
				finished_animating = true
			play_default_animation()
		return
	var animation = animation_queue.pop_front()
	$orc/AnimationPlayer.play(animation)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dpad_up"):
		play_queue(ANIMATIONS["jump"])
	if event.is_action_pressed("dpad_right"):
		play_queue(ANIMATIONS["punch"])
	if event.is_action_pressed("dpad_down"):
		default_animation = animation_death
		last_animation = true
		play_queue([])

func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if state == STATES.RECOVERING and len(animation_queue) == 0:
		state = STATES.IDLE
	play_queue()

func kill() -> void:
	dead = true
	collision_layer = 0
	default_animation = animation_death
	last_animation = true
	play_queue([])
	await get_tree().create_timer(3).timeout
	$HealthBar.hide()

func damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		kill()

func heal(amount: int) -> void:
	health = min(health + amount, health_max)

func hit_with_blast(blast: Node3D) -> void:
	play_queue(ANIMATIONS["hit"])
	damage(blast.power)

func cast_ability(ability: String) -> void:
	state = STATES.RECOVERING
	var casted = abilityDictionary[ability].instantiate()
	casted.cast(abilities[ability],
		global_position + pos_adjustment,
		0,
		self,
		get_player())

var casting = null

func _on_shoot_timer_timeout() -> void:
	start_cast_reach(g.ABILITY_BLAST)

func start_cast_reach(ability: String) -> void:
	state = STATES.ACTING
	play_queue(ANIMATIONS["cast_shoot_full"])
	casting = ability
	$CastDelay.start(0.53)

func _on_cast_delay_timeout() -> void:
	if casting:
		cast_ability(casting)
		casting = null
		
func activateBlock(block: Node) -> void:
	if active_block:
		active_block.reset()
		block.queue_free()
	else:
		block.rotation.y = PI
		active_block = block

func getOriginCollisionLayer() -> int:
	return g.COLLISION_LAYER.ENEMY
	
func getTargetCollisionLayer() -> int:
	return g.COLLISION_LAYER.PLAYER

enum STATES {
	IDLE,
	ACTING,
	RECOVERING,
}
var state: STATES = STATES.IDLE

## Main NPC logic function, called every frame.
func think() -> void:
	if dead:
		return

	if state == STATES.ACTING or state == STATES.RECOVERING:
		return

	match think_mode:
		THINK_MODES.DEFAULT, THINK_MODES.AGGRESSIVE:
			var player_damage_percent = 1 - float(get_player().health)/get_player().health_max
			var npc_damage_percent = 1 - (float(health)/health_max)

			if npc_preservation * npc_damage_percent > npc_aggression * player_damage_percent:
				if npc_damage_percent > 0.25:
					start_cast_reach(g.ABILITY_HEAL)
				else:
					start_cast_reach(g.ABILITY_BLOCK)
			else:
				start_cast_reach(g.ABILITY_BLAST)
		THINK_MODES.DEFENSIVE:
			var player_damage_percent = 1 - float(get_player().health)/get_player().health_max
			var npc_damage_percent = 1 - (float(health)/health_max)

			if npc_preservation * npc_damage_percent > npc_aggression * player_damage_percent:
				if npc_damage_percent > 0.25:
					start_cast_reach(g.ABILITY_HEAL)
				else:
					start_cast_reach(g.ABILITY_BLOCK)
		THINK_MODES.PASSIVE:
			return
		_:
			push_warning("Unimplemented thinking mode ", think_mode)

func check_for_player_blasts() -> Node3D:
	for node in get_tree().get_nodes_in_group("blasts"):
		if node.caster == get_player():
			return node
	return null

func new_think() -> void:
	if dead:
		return

	if state == STATES.ACTING or state == STATES.RECOVERING:
		return
	
	# Setup variables
	var player_damage_percent = 1 - float(get_player().health)/get_player().health_max
	var distance_to_player = abs(global_position.z - get_player().global_position.z)
	var is_player_blast_flying = null
	if check_for_player_blasts():
		is_player_blast_flying = 1
	var npc_damage_percent = 1 - (float(health)/health_max)
	var npc_mana_percent = 1 - (float(mana)/mana_max)
	var npc_block_damage_percent = 0
	if active_block:
		npc_block_damage_percent = 1 - (float(active_block.power/active_block.max_power))
	var yearn = npc_preservation * npc_damage_percent - npc_aggression * player_damage_percent
	#var other_hand_ability = 'Figure this out'
	
	#Priority updates
	priority[g.ABILITY_ABSORB]  += roundi(yearn * npc_mana_percent)
	if active_block:
		priority[g.ABILITY_BLAST] += yearn * active_block.power
	priority[g.ABILITY_BLOCK] += roundi(yearn * npc_block_damage_percent)
	#if other_hand_ability.name == g.ABILITY_BLAST or other_hand_ability.name == g.ABILITY_HEAL:
		#priority[g.ABILITY_CHARGE] += 20
	#if other_hand_ability.cast_time > '3s':
		#priority[g.ABILITY_FOCUS] += 20
	#else:
		#priority[g.ABILITY_FOCUS] -= 20
	priority[g.ABILITY_HEAL] += roundi(yearn * npc_damage_percent)
	priority[g.ABILITY_PULL] -= roundi(yearn * distance_to_player)
	priority[g.ABILITY_PUSH] += yearn * distance_to_player
	if is_player_blast_flying:
		priority[g.ABILITY_REFLECT] += 20
	else:
		priority[g.ABILITY_REFLECT] = 0
	priority[g.ABILITY_RESTORE] += roundi(1 / npc_mana_percent)
	
	var max_priority = priority.values().max()
	var next_ability = g.ABILITY_BLAST
	for ability in priority:
		if priority[ability] == max_priority:
			next_ability = ability
	priority[next_ability] = 0
	
	start_cast_reach(next_ability)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if stopped:
		return
	new_think()

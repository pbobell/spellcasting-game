extends CharacterBody3D

var Blast: PackedScene = preload("res://abilities/blast.tscn")

const RES_DIR = "res://abilities"
var abilities: Dictionary

@export var health_max: int = 10
var health: int = health_max :
	set(value):
		health = value
		if get_node_or_null("HealthBar"):
			$HealthBar.mesh.material.set_shader_parameter("health", float(health) / health_max)

@export var pos_adjustment: Vector3 = Vector3(-1.5, 5, -4)
@export var player_center_adjustment: Vector3 = Vector3(0, 0, -3)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var active_block: Array[Node] = [null, null]

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
	for f in ["Blast.tres", "Block.tres", "Heal.tres"]:
		f = RES_DIR.path_join(f)
		var data = ResourceLoader.load(f)
		var ability = Ability.from_data(data)
		abilities[ability.name] = ability

func get_player() -> Node:
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
	play_queue()

func kill() -> void:
	collision_layer = 4
	collision_mask = 4
	default_animation = animation_death
	last_animation = true
	play_queue([])
	await get_tree().create_timer(3).timeout
	$HealthBar.hide()

func damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		kill()

func hit_with_spell(ability: Node3D) -> void:
	if ability.name == "Blast":
		play_queue(ANIMATIONS["hit"])
		damage(3)

func cast_blast() -> void:
	var casted = Blast.instantiate()
	casted.cast(abilities["Blast"],
				get_parent(),
				global_position + pos_adjustment,
				get_player().global_position - player_center_adjustment,
				self)

var casting = null

func _on_shoot_timer_timeout() -> void:
	play_queue(ANIMATIONS["cast_shoot_full"])
	casting = cast_blast
	$CastDelay.start(0.53)


func _on_cast_delay_timeout() -> void:
	if casting:
		casting.call()
		casting = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player_damage_percent = 1 - (get_player().health)/get_player().health_max
	var npc_damage_percent = 1 - (health/health_max)
	
	if npc_preservation * npc_damage_percent > npc_aggression * player_damage_percent:
		if active_block[g.SIDES.LEFT] == null:
			#cast Block
			pass
		if npc_damage_percent < 0.75:
			#cast Heal
			pass
	else:
		#cast Blast
		pass

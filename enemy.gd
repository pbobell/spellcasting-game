extends CharacterBody3D

@export var health_max: int = 10
var health: int = health_max :
	set(value):
		health = value
		if get_node_or_null("HealthBar"):
			$HealthBar.mesh.material.set_shader_parameter("health", float(health) / health_max)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var ANIMATIONS = {
	"punch": ["AnimationLibrary_Godot_Standard/Punch_Enter",
			  "AnimationLibrary_Godot_Standard/Punch_Jab"],
	"hit": ["AnimationLibrary_Godot_Standard/Hit_Chest"],
	"headshot": ["AnimationLibrary_Godot_Standard/Hit_Head"],
	"jump": ["AnimationLibrary_Godot_Standard/Jump_Start",
			 "AnimationLibrary_Godot_Standard/Jump"]
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
	health = health_max
	play_default_animation()

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

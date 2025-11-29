extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _ready() -> void:
#	var universal = AnimationLibrary.new()
#	universal.add_animation("idle", preload("res://assets/animations/idle.res"))
#	universal.add_animation("punch_jab", preload("res://assets/animations/punch_jab.res"))
#	$Orc/AnimationPlayer.add_animation_library("universal", universal)
	$orc/AnimationPlayer.play("AnimationLibrary_Godot_Standard/Idle")
	pass

func play_animation():
	$orc/AnimationPlayer.play("AnimationLibrary_Godot_Standard/Punch_Jab")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		play_animation()

func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	$orc/AnimationPlayer.play("AnimationLibrary_Godot_Standard/Idle")

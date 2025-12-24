extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	# Escape or menu button to quit.
	if event.is_action_pressed("ui_cancel"):
		g.quit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_player_camera_effect(effect: int) -> void:
	match effect:
		g.CAMERA_EFFECTS.FLASH:
			$Camera3D.attributes.exposure_multiplier = 4
			var tween = get_tree().create_tween()
			tween.tween_property($Camera3D.attributes, "exposure_multiplier", 1, .25)
		_:
			push_warning("Unimplemented camera effect ", effect)

func _on_player_game_over() -> void:
	$Player.dead = true
	$Enemy.game_over()
	print("Game over!")

extends Control

@export var game: PackedScene = preload("res://main.tscn")

func _ready() -> void:
	g.menu_launcher = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

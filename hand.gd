extends Node3D

@export var max_health: int = 10
var health: int = max_health :
	set(value):
		health = value
		$hand.health = health

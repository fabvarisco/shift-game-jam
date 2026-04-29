extends Node3D
class_name EntityCombat

@export var stats: EntityStats:
	set(value):
		stats = value
		if is_node_ready():
			_apply_stats()

@onready var sprite: AnimatedSprite3D = $Sprite

func _ready() -> void:
	_apply_stats()


func _apply_stats() -> void:
	if stats == null:
		return
	if stats.sprite != null:
		sprite.sprite_frames = stats.sprite
		sprite.play()

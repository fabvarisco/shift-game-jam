extends Node3D
class_name EntityCombat

signal selected(entity: EntityCombat)

@export var stats: EntityStats:
	set(value):
		stats = value
		if is_node_ready():
			_apply_stats()

var is_player: bool = false

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var area: Area3D = $Area3D

func _ready() -> void:
	_apply_stats()
	area.input_event.connect(_on_area_input_event)

func _apply_stats() -> void:
	if stats == null:
		return
	if stats.sprite != null:
		sprite.sprite_frames = stats.sprite
		sprite.play()

func _on_area_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and is_player:
		selected.emit(self)

func set_selected(value: bool) -> void:
	sprite.modulate = Color(1.4, 1.4, 0.6) if value else Color.WHITE

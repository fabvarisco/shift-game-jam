extends Node3D
class_name EntityCombat

signal selected(entity: EntityCombat)

@export var stats: Resource:
	set(value):
		stats = value
		if is_node_ready():
			_apply_stats()

var is_player: bool = false
var combat_state: CombatState = null
var acted: bool = false
var _is_selected: bool = false

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var area: Area3D = $Area3D

func _ready() -> void:
	_apply_stats()
	area.input_event.connect(_on_area_input_event)

func _apply_stats() -> void:
	if stats == null:
		return
	var frames: SpriteFrames = stats.get("sprite")
	if frames != null:
		sprite.sprite_frames = frames
		sprite.play()

func initialize_combat() -> void:
	if stats is EntityCharacter:
		combat_state = CombatState.from_character(stats as EntityCharacter)
	elif stats is EnemyEntity:
		combat_state = CombatState.from_enemy(stats as EnemyEntity)

func get_display_name() -> String:
	return stats.get("name") if stats else "?"

func _on_area_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and is_player:
		selected.emit(self)

func set_selected(value: bool) -> void:
	_is_selected = value
	if value:
		sprite.modulate = Color(1.4, 1.4, 0.6)
	else:
		sprite.modulate = Color(0.7, 0.7, 0.7) if acted else Color.WHITE

func set_acted(value: bool) -> void:
	acted = value
	if not _is_selected:
		sprite.modulate = Color(0.7, 0.7, 0.7) if acted else Color.WHITE

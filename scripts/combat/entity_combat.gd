extends Node3D
class_name EntityCombat

signal selected(entity: EntityCombat)
signal trait_exhausted(entity: EntityCombat, slot: String)

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

func is_defeated() -> bool:
	if combat_state == null:
		return false
	if stats is EnemyEntity:
		var threshold := (stats as EnemyEntity).get_traits_to_exhaust()
		return combat_state.exhausted_count() >= threshold
	return combat_state.is_core_exhausted()

func shift_trait_down(slot: String) -> bool:
	if combat_state == null:
		return false
	var exhausted := combat_state.shift_down(slot)
	if exhausted:
		trait_exhausted.emit(self, slot)
		apply_ko(slot)
	return exhausted

func apply_ko(slot: String) -> void:
	sprite.modulate = Color(0.25, 0.25, 0.35)
	if has_node("KOLabel"):
		return
	var lbl := Label3D.new()
	lbl.name = "KOLabel"
	lbl.text = "KO – %s" % slot
	lbl.position = Vector3(0.0, 0.6, 0.0)
	lbl.font_size = 48
	lbl.modulate = Color(1.0, 0.2, 0.2)
	add_child(lbl)

func set_acted(value: bool) -> void:
	acted = value
	if not _is_selected:
		sprite.modulate = Color(0.7, 0.7, 0.7) if acted else Color.WHITE

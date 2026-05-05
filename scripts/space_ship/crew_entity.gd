extends Node3D
class_name CrewEntity

signal interacted(entity: CrewEntity)

@export var data: EntityCharacter:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var label: Label3D = $Label
@onready var area: Area3D = $Area3D

var _chunk_center: Vector3 = Vector3.ZERO
var _half_width: float = 3.0
var _tween: Tween

func _ready() -> void:
	_apply_data()
	area.input_event.connect(_on_area_input)

func _apply_data() -> void:
	if data == null:
		return
	if data.sprite != null:
		sprite.sprite_frames = data.sprite
		sprite.play()
	label.text = data.name

func get_display_name() -> String:
	return data.name if data else "?"

func assign_to_chunk(chunk_center: Vector3, half_width: float) -> void:
	_chunk_center = chunk_center
	_half_width = half_width
	position = chunk_center
	_pick_next_position()

func _pick_next_position() -> void:
	var target := Vector3(
		_chunk_center.x + randf_range(-_half_width, _half_width),
		_chunk_center.y,
		_chunk_center.z
	)

	var dx := target.x - position.x
	if not is_zero_approx(dx):
		sprite.scale.x = signf(dx) * absf(sprite.scale.x)

	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var duration := clampf(position.distance_to(target) / 2.0, 0.5, 5.0)
	_tween.tween_property(self, "position", target, duration)
	_tween.tween_callback(_on_arrived)

func _on_arrived() -> void:
	await get_tree().create_timer(randf_range(1.0, 3.5)).timeout
	_pick_next_position()

func _on_area_input(_camera, event: InputEvent, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
			and (event as InputEventMouseButton).pressed:
		interacted.emit(self)

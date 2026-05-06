class_name CrewEntity
extends CharacterBody3D

signal interacted(entity: CrewEntity)
signal task_destination_reached()

enum State { IDLE, ON_TASK }

@export var data: EntityCharacter:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()

@export var move_speed: float = 2.0
## How far crew wanders in depth (Z axis) relative to chunk center
@export var z_wander_range: float = 1.5
## Disable for flat ship floors that don't need gravity simulation
@export var use_gravity: bool = false
@export var gravity_strength: float = 9.8

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var label: Label3D = $Label
@onready var area: Area3D = $Area3D

var _nav_agent: NavigationAgent3D
var _chunk_center: Vector3 = Vector3.ZERO
var _half_width: float = 3.0
var _state: State = State.IDLE
var _moving: bool = false

func _ready() -> void:
	_setup_navigation()
	_apply_data()
	area.input_event.connect(_on_area_input)

func _setup_navigation() -> void:
	if has_node("NavigationAgent3D"):
		_nav_agent = $NavigationAgent3D
	else:
		_nav_agent = NavigationAgent3D.new()
		_nav_agent.name = "NavigationAgent3D"
		add_child(_nav_agent)

	_nav_agent.path_desired_distance = 0.3
	_nav_agent.target_desired_distance = 0.5
	_nav_agent.navigation_finished.connect(_on_navigation_finished)

func _physics_process(delta: float) -> void:
	if use_gravity and not is_on_floor():
		velocity.y -= gravity_strength * delta

	if _moving and not _nav_agent.is_navigation_finished():
		var next_pos: Vector3 = _nav_agent.get_next_path_position()
		var dir: Vector3 = next_pos - global_position
		dir.y = 0.0
		var dist := dir.length()
		if dist > 0.05:
			dir = dir / dist
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			if not is_zero_approx(dir.x):
				sprite.scale.x = signf(dir.x) * absf(sprite.scale.x)
			_set_anim("walk")
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			_set_anim("idle")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_set_anim("idle")

	move_and_slide()

# ── Public API ─────────────────────────────────────────────────────────────────

## Send crew to a specific world position for a task. Pauses idle wandering.
## Emits task_destination_reached when the crew arrives.
func go_to_task(target: Vector3) -> void:
	_state = State.ON_TASK
	_navigate(target)

## Call after a task finishes to resume idle wandering.
func return_to_idle() -> void:
	_state = State.IDLE
	_pick_next_wander_target()

func stop() -> void:
	_moving = false
	velocity = Vector3.ZERO

func is_idle() -> bool:
	return _state == State.IDLE

# ── Wander (IDLE state) ────────────────────────────────────────────────────────

func assign_to_chunk(chunk_center: Vector3, half_width: float) -> void:
	_chunk_center = chunk_center
	_half_width = half_width
	global_position = chunk_center
	# Wait one frame so NavigationServer syncs before the first path request
	await get_tree().process_frame
	_pick_next_wander_target()

func _pick_next_wander_target() -> void:
	var target := Vector3(
		_chunk_center.x + randf_range(-_half_width, _half_width),
		_chunk_center.y,
		_chunk_center.z + randf_range(-z_wander_range, z_wander_range)
	)
	_navigate(target)

func _schedule_next_wander() -> void:
	await get_tree().create_timer(randf_range(1.0, 3.5)).timeout
	if is_inside_tree() and _state == State.IDLE:
		_pick_next_wander_target()

# ── Navigation internals ───────────────────────────────────────────────────────

func _navigate(target: Vector3) -> void:
	_moving = true
	_nav_agent.set_target_position(target)

func _on_navigation_finished() -> void:
	_moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	match _state:
		State.IDLE:
			_schedule_next_wander()
		State.ON_TASK:
			task_destination_reached.emit()

# ── Helpers ────────────────────────────────────────────────────────────────────

func _set_anim(anim: String) -> void:
	if sprite.sprite_frames == null:
		return
	if sprite.animation == anim:
		return
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
	elif anim == "walk" and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")

func _apply_data() -> void:
	if data == null:
		return
	if data.sprite != null:
		sprite.sprite_frames = data.sprite
		sprite.play()
	label.text = data.name

func get_display_name() -> String:
	return data.name if data else "?"

func _on_area_input(_camera, event: InputEvent, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT \
			and (event as InputEventMouseButton).pressed:
		interacted.emit(self)

class_name CrewEntity
extends CharacterBody3D

signal interacted(entity: CrewEntity)

@export var data: EntityCharacter:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()

@export var move_speed: float = 2.0
## Disable for flat ship floors that don't need gravity simulation
@export var use_gravity: bool = false
@export var gravity_strength: float = 9.8

@onready var sprite: AnimatedSprite3D = $Sprite
@onready var label: Label3D = $Label
@onready var area: Area3D = $Area3D

var _nav_agent: NavigationAgent3D
var _chunk_center: Vector3 = Vector3.ZERO
var _half_width: float = 3.0
var _wandering: bool = false

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
	_nav_agent.avoidance_enabled = true
	_nav_agent.navigation_finished.connect(_on_navigation_finished)
	_nav_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if use_gravity and not is_on_floor():
		velocity.y -= gravity_strength * delta

	if _wandering and not _nav_agent.is_navigation_finished():
		var next_pos: Vector3 = _nav_agent.get_next_path_position()
		var dir: Vector3 = next_pos - global_position
		dir.y = 0.0
		dir = dir.normalized()

		if not is_zero_approx(dir.x):
			sprite.scale.x = signf(dir.x) * absf(sprite.scale.x)

		_nav_agent.set_velocity(dir * move_speed)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

# ── Public navigation API ──────────────────────────────────────────────────────

## Move toward an arbitrary world-space position via the navigation mesh.
## Requires a NavigationRegion3D with a baked mesh in the scene tree.
func navigate_to(target: Vector3) -> void:
	_wandering = true
	_nav_agent.set_target_position(target)

func stop_navigation() -> void:
	_wandering = false
	velocity = Vector3.ZERO

# ── Wander behaviour ───────────────────────────────────────────────────────────

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
		_chunk_center.z
	)
	navigate_to(target)

func _on_navigation_finished() -> void:
	_wandering = false
	velocity.x = 0.0
	velocity.z = 0.0
	_schedule_next_wander()

func _schedule_next_wander() -> void:
	await get_tree().create_timer(randf_range(1.0, 3.5)).timeout
	if is_inside_tree():
		_pick_next_wander_target()

# ── Helpers ────────────────────────────────────────────────────────────────────

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

extends Node3D

@export var grid_columns: int = 4
@export var grid_rows: int = 4
## Horizontal spacing matches room width (~8 cells)
@export var chunk_spacing_x: float = 8.0
## Vertical spacing matches floor height (~4 cells)
@export var chunk_spacing_y: float = 4.0
@export var chunk_scenes: Array[PackedScene] = []

@export_group("Crew")
@export var crew_scene: PackedScene
@export var initial_crew: Array[EntityCharacter] = []
## Z offset to place crew inside the room (room depth is ~6 units in -Z)
@export var crew_depth_offset: float = 3.0
@export_group("")

@onready var global_camera: Camera3D = $GlobalCamera

var _cameras: Array[Camera3D] = []
var _current_idx: int = 0
var _chunk_positions: Array[Vector3] = []

func _ready() -> void:
	_spawn_chunks()
	_spawn_crew()
	_setup_global_camera()
	_activate_camera(0)

func _spawn_chunks() -> void:
	if chunk_scenes.is_empty():
		return
	for row in range(grid_rows):
		for col in range(grid_columns):
			var scene_idx := (row * grid_columns + col) % chunk_scenes.size()
			var chunk := chunk_scenes[scene_idx].instantiate()
			add_child(chunk)
			var pos := Vector3(col * chunk_spacing_x, -row * chunk_spacing_y, 0.0)
			chunk.position = pos
			_chunk_positions.append(pos)
			var cam := _find_camera(chunk)
			if cam:
				_cameras.append(cam)

func _spawn_crew() -> void:
	if crew_scene == null or initial_crew.is_empty():
		return
	for i in initial_crew.size():
		var member: Node3D = crew_scene.instantiate()
		add_child(member)
		member.set("data", initial_crew[i])
		var chunk_pos := _chunk_positions[i % _chunk_positions.size()]
		# Floor tiles are 1x1x1 centered at Y=0, so top face is at Y=+0.5
		var crew_pos := Vector3(chunk_pos.x, chunk_pos.y + 0.8, chunk_pos.z - crew_depth_offset)
		member.call("assign_to_chunk", crew_pos, chunk_spacing_x * 0.4)

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var result := _find_camera(child)
		if result:
			return result
	return null

func _setup_global_camera() -> void:
	var total_width: float = (grid_columns - 1) * chunk_spacing_x
	var total_height: float = (grid_rows - 1) * chunk_spacing_y
	var center_x: float = total_width / 2.0
	# Rooms extend upward from chunk_pos.y, so shift center up by half a room height
	var center_y: float = -total_height / 2.0 + chunk_spacing_y * 0.5
	var distance: float = maxf(total_width, total_height) * 0.45 + 3.0
	global_camera.position = Vector3(center_x, center_y, distance)
	global_camera.look_at(Vector3(center_x, center_y, 0.0))
	global_camera.fov = 90.0
	_cameras.insert(0, global_camera)

func _activate_camera(idx: int) -> void:
	for cam in _cameras:
		cam.current = false
	_cameras[idx].current = true
	_current_idx = idx

func _input(event: InputEvent) -> void:
	if _cameras.size() < 2:
		return
	if event.is_action_pressed("ui_focus_next"):
		var next := (_current_idx + 1) % _cameras.size()
		if next == 0:
			next = 1
		_activate_camera(next)
	elif event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_SPACE:
			_activate_camera(0)

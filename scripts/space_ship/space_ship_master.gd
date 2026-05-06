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
var _crew_entities: Array[CrewEntity] = []
var _nav_region: NavigationRegion3D

# HUD nodes (built in code to avoid .tscn dependency)
var _hud: CanvasLayer
var _phase_label: Label
var _turn_label: Label
var _end_turn_btn: Button
var _roster_toggle_btn: Button
var _crew_roster: CrewRosterPanel
var _crew_action_panel: CrewActionPanel
var _encounter_panel: PanelContainer
var _encounter_title: Label
var _encounter_desc: Label
var _encounter_actions_box: VBoxContainer

func _ready() -> void:
	_setup_navmesh()
	_spawn_chunks()
	_setup_global_camera()
	_activate_camera(0)
	_build_hud()
	_connect_game_state()
	# Bake async; crew spawns once the mesh is ready so paths work immediately
	_nav_region.bake_finished.connect(_on_navmesh_baked, CONNECT_ONE_SHOT)
	_nav_region.bake_navigation_mesh(true)

func _on_navmesh_baked() -> void:
	_spawn_crew()
	_crew_roster.populate(_crew_entities)
	if GameState.current_phase == GameState.Phase.ENCOUNTER_PHASE:
		call_deferred("_continue_encounter_queue")

func _continue_encounter_queue() -> void:
	GameState.acknowledge_encounter()

func _setup_navmesh() -> void:
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "NavigationRegion"
	add_child(_nav_region)

	var nav_mesh := NavigationMesh.new()

	# Match crew capsule dimensions (radius 0.15, height 0.7) with clearance
	nav_mesh.agent_radius = 0.2
	nav_mesh.agent_height = 0.8
	nav_mesh.agent_max_climb = 0.25
	nav_mesh.agent_max_slope = 30.0  # only flat surfaces; ignores walls

	# Cell resolution — smaller = more precise but slower to bake
	nav_mesh.cell_size = 0.2
	nav_mesh.cell_height = 0.1

	# GridMap geometry is only captured via MESH_INSTANCES, not STATIC_COLLIDERS.
	# PARSED_GEOMETRY_STATIC_COLLIDERS does not pick up GridMap tiles in Godot 4.
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	# GROUPS_WITH_CHILDREN scans children of every node in the group "navmesh_source".
	# Each spawned chunk is added to that group in _spawn_chunks(), so the GridMap
	# inside each chunk is included in the bake.
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = &"navmesh_source"

	_nav_region.navigation_mesh = nav_mesh

# ── HUD ────────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(root)

	_phase_label = Label.new()
	_phase_label.position = Vector2(10, 10)
	_phase_label.add_theme_font_size_override("font_size", 20)
	root.add_child(_phase_label)

	_turn_label = Label.new()
	_turn_label.position = Vector2(10, 38)
	root.add_child(_turn_label)

	_end_turn_btn = Button.new()
	_end_turn_btn.text = "Encerrar Turno"
	_end_turn_btn.custom_minimum_size = Vector2(160, 40)
	_end_turn_btn.set_anchor(SIDE_RIGHT, 1.0)
	_end_turn_btn.set_anchor(SIDE_LEFT, 1.0)
	_end_turn_btn.set_anchor(SIDE_TOP, 1.0)
	_end_turn_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_end_turn_btn.position = Vector2(-170, -50)
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	root.add_child(_end_turn_btn)

	# Roster toggle button — top right
	_roster_toggle_btn = Button.new()
	_roster_toggle_btn.text = "Tripulação ▾"
	_roster_toggle_btn.custom_minimum_size = Vector2(130, 32)
	_roster_toggle_btn.set_anchor(SIDE_LEFT, 1.0)
	_roster_toggle_btn.set_anchor(SIDE_RIGHT, 1.0)
	_roster_toggle_btn.position = Vector2(-140, 10)
	_roster_toggle_btn.pressed.connect(_on_roster_toggle)
	root.add_child(_roster_toggle_btn)

	# Crew roster panel — top right, below toggle button
	_crew_roster = CrewRosterPanel.new()
	_crew_roster.set_anchor(SIDE_LEFT, 1.0)
	_crew_roster.set_anchor(SIDE_RIGHT, 1.0)
	_crew_roster.position = Vector2(-540, 50)
	_crew_roster.visible = false
	root.add_child(_crew_roster)

	_crew_action_panel = CrewActionPanel.new()
	_crew_action_panel.set_anchor(SIDE_LEFT, 0.5)
	_crew_action_panel.set_anchor(SIDE_RIGHT, 0.5)
	_crew_action_panel.set_anchor(SIDE_TOP, 0.5)
	_crew_action_panel.set_anchor(SIDE_BOTTOM, 0.5)
	_crew_action_panel.position = Vector2(-140, -100)
	_crew_action_panel.visible = false
	_crew_action_panel.action_taken.connect(_on_crew_action_taken)
	root.add_child(_crew_action_panel)

	_encounter_panel = PanelContainer.new()
	_encounter_panel.set_anchor(SIDE_LEFT, 0.5)
	_encounter_panel.set_anchor(SIDE_RIGHT, 0.5)
	_encounter_panel.set_anchor(SIDE_TOP, 0.5)
	_encounter_panel.set_anchor(SIDE_BOTTOM, 0.5)
	_encounter_panel.position = Vector2(-200, -120)
	_encounter_panel.custom_minimum_size = Vector2(400, 240)
	_encounter_panel.visible = false
	root.add_child(_encounter_panel)

	var enc_vbox := VBoxContainer.new()
	_encounter_panel.add_child(enc_vbox)

	_encounter_title = Label.new()
	_encounter_title.add_theme_font_size_override("font_size", 18)
	enc_vbox.add_child(_encounter_title)

	_encounter_desc = Label.new()
	_encounter_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enc_vbox.add_child(_encounter_desc)

	enc_vbox.add_child(HSeparator.new())

	_encounter_actions_box = VBoxContainer.new()
	enc_vbox.add_child(_encounter_actions_box)

	_crew_roster.crew_selected.connect(_on_roster_crew_selected)

	_update_phase_hud(GameState.current_phase)
	_update_turn_hud(GameState.turn_number)

func _on_roster_toggle() -> void:
	_crew_roster.visible = not _crew_roster.visible
	if not _crew_roster.visible:
		_restore_all_crew_sprites()

func _on_roster_crew_selected(_crew: CrewEntity) -> void:
	pass  # highlight is handled inside CrewRosterPanel directly on the sprite

func _connect_game_state() -> void:
	GameState.phase_changed.connect(_update_phase_hud)
	GameState.turn_started.connect(_update_turn_hud)
	GameState.encounter_started.connect(_on_encounter_started)

func _update_phase_hud(phase: int) -> void:
	match phase:
		GameState.Phase.PLAYER_PHASE:
			_phase_label.text = "TURNO DO JOGADOR"
			_end_turn_btn.visible = true
			_restore_all_crew_sprites()
		GameState.Phase.ENCOUNTER_PHASE:
			_phase_label.text = "ENCONTRO"
			_end_turn_btn.visible = false

func _update_turn_hud(turn: int) -> void:
	_turn_label.text = "Turno %d" % turn

# ── Player Phase ───────────────────────────────────────────────────────────────

func _on_end_turn_pressed() -> void:
	if GameState.current_phase != GameState.Phase.PLAYER_PHASE:
		return
	GameState.end_player_turn()

func _on_crew_interacted(crew: CrewEntity) -> void:
	if GameState.current_phase != GameState.Phase.PLAYER_PHASE:
		return
	if GameState.has_crew_acted(crew):
		return
	_crew_action_panel.show_for(crew)

func _on_crew_action_taken(crew: CrewEntity, action: String, trait_name: String) -> void:
	GameState.record_crew_action(crew)
	_dim_crew_sprite(crew)
	match action:
		"rest":
			_show_inline_result(crew.data.name, "Descanso", "O tripulante descansou e recupera energia.")
		"trait":
			_resolve_crew_trait_action(crew, trait_name)

func _resolve_crew_trait_action(crew: CrewEntity, trait_name: String) -> void:
	var td: TraitData = crew.data.focus_traits.get(trait_name, null)
	if td == null:
		return
	var faces: Array = System.DICES[td.die]
	var roll_val: int = faces.pick_random() if not faces.is_empty() else 0
	var result := System.resolve([roll_val], [td.die])
	_show_inline_result(
		crew.data.name,
		trait_name,
		"Rolou %d → %s" % [roll_val, _result_label(result)]
	)

func _dim_crew_sprite(crew: CrewEntity) -> void:
	var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.8)

func _restore_all_crew_sprites() -> void:
	for crew: CrewEntity in _crew_entities:
		var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
		if sprite:
			sprite.modulate = Color(0.5, 0.5, 0.8) if GameState.has_crew_acted(crew) else Color.WHITE

# ── Encounter Phase ────────────────────────────────────────────────────────────

func _on_encounter_started(event: EncounterEvent) -> void:
	match event.type:
		EncounterEvent.EventType.COMBAT:
			_start_combat_encounter(event)
		EncounterEvent.EventType.HAZARD, EncounterEvent.EventType.SOCIAL:
			_show_noncombat_encounter(event)

func _start_combat_encounter(event: EncounterEvent) -> void:
	var enemies: Array[EnemyEntity] = []
	for e in event.enemy_party:
		if e is EnemyEntity:
			enemies.append(e as EnemyEntity)
	World.start_combat(enemies)

func _show_noncombat_encounter(event: EncounterEvent) -> void:
	_clear_encounter_actions()
	_encounter_title.text = event.title
	_encounter_desc.text = event.description
	_encounter_panel.visible = true

	var label := Label.new()
	label.text = "Escolha um tripulante para responder:"
	_encounter_actions_box.add_child(label)

	for crew: CrewEntity in _crew_entities:
		var btn := Button.new()
		btn.text = crew.data.name if crew.data else "?"
		var c: CrewEntity = crew
		var e: EncounterEvent = event
		btn.pressed.connect(func(): _resolve_noncombat(e, c))
		_encounter_actions_box.add_child(btn)

	var skip_btn := Button.new()
	skip_btn.text = "Ignorar (falha automática)"
	var ev: EncounterEvent = event
	skip_btn.pressed.connect(func(): _resolve_noncombat(ev, null))
	_encounter_actions_box.add_child(skip_btn)

func _resolve_noncombat(event: EncounterEvent, crew: CrewEntity) -> void:
	_clear_encounter_actions()

	var result := System.Results.FAILURE
	var roll_val := 0
	var crew_name := "Ninguém"

	if crew != null and crew.data != null:
		crew_name = crew.data.name
		var td: TraitData = _get_challenge_trait(crew.data, event.challenge_trait)
		if td != null and td.die != System.Dice.EXHAUSTED:
			var faces: Array = System.DICES[td.die]
			roll_val = faces.pick_random() if not faces.is_empty() else 0
			result = System.resolve([roll_val], [td.die])

	_encounter_desc.text = "%s\n\n%s rolou %d → %s" % [
		event.description, crew_name, roll_val, _result_label(result)
	]

	var btn := Button.new()
	btn.text = "Continuar"
	btn.pressed.connect(func():
		_encounter_panel.visible = false
		GameState.acknowledge_encounter()
	)
	_encounter_actions_box.add_child(btn)

func _show_inline_result(actor: String, action: String, outcome: String) -> void:
	_clear_encounter_actions()
	_encounter_title.text = "%s → %s" % [actor, action]
	_encounter_desc.text = outcome
	_encounter_panel.visible = true

	var btn := Button.new()
	btn.text = "OK"
	btn.pressed.connect(func(): _encounter_panel.visible = false)
	_encounter_actions_box.add_child(btn)

func _clear_encounter_actions() -> void:
	for child in _encounter_actions_box.get_children():
		child.queue_free()

# ── Helpers ────────────────────────────────────────────────────────────────────

func _get_challenge_trait(character: EntityCharacter, trait_name: String) -> TraitData:
	match trait_name:
		"mind": return character.mind
		"body": return character.body
		"soul": return character.soul
		_: return character.focus_traits.get(trait_name, null)

func _result_label(result: System.Results) -> String:
	match result:
		System.Results.CRITICAL_SUCCESS: return "SUCESSO CRÍTICO"
		System.Results.SUCCESS:          return "SUCESSO"
		System.Results.MITIGATED_SUCCESS: return "SUCESSO MITIGADO"
		System.Results.FAILURE:          return "FALHA"
		System.Results.CRITICAL_FAILURE: return "FALHA CRÍTICA"
	return "?"

# ── Spawn ──────────────────────────────────────────────────────────────────────

func _spawn_chunks() -> void:
	if chunk_scenes.is_empty():
		return
	for row in range(grid_rows):
		for col in range(grid_columns):
			var scene_idx := (row * grid_columns + col) % chunk_scenes.size()
			var chunk := chunk_scenes[scene_idx].instantiate()
			add_child(chunk)
			chunk.add_to_group("navmesh_source")
			var pos := Vector3(col * chunk_spacing_x, -row * chunk_spacing_y, 0.0)
			chunk.position = pos
			_chunk_positions.append(pos)
			var cam := _find_camera(chunk)
			if cam:
				_cameras.append(cam)

func _spawn_crew() -> void:
	if crew_scene == null or initial_crew.is_empty():
		return
	Player.player_party = initial_crew
	for i in initial_crew.size():
		var member: CrewEntity = crew_scene.instantiate() as CrewEntity
		add_child(member)
		member.set("data", initial_crew[i])
		var chunk_pos := _chunk_positions[i % _chunk_positions.size()]
		var crew_pos := Vector3(chunk_pos.x, chunk_pos.y + 0.8, chunk_pos.z - crew_depth_offset)
		member.call("assign_to_chunk", crew_pos, chunk_spacing_x * 0.4)
		member.interacted.connect(_on_crew_interacted)
		_crew_entities.append(member)

# ── Camera ─────────────────────────────────────────────────────────────────────

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

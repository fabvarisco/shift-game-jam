extends Node3D

enum TurnPhase { PLAYER_TURN, ENEMY_TURN }
enum InvasionState { IDLE, SELECT_ACTION, MOVING, SELECT_TARGET }
enum TargetingType { MELEE_ENEMY, RANGED_ENEMY, ALLY, SELF }

const MELEE_RANGE := 2.5

const KEYWORD_TARGETING: Dictionary = {
	"strike":    0, # MELEE_ENEMY
	"slash":     0,
	"crush":     0,
	"push":      0,
	"intercept": 0,
	"blast":     1, # RANGED_ENEMY
	"enchant":   1,
	"decipher":  1,
	"identify":  1,
	"quick":     1,
	"heal":      2, # ALLY
	"bless":     2,
	"ward":      2,
	"cleanse":   2,
	"protect":   2,
	"endure":    3, # SELF
	"block":     3,
}

@export var grid_columns: int = 3
@export var grid_rows: int = 2
@export var chunk_spacing_x: float = 8.0
@export var chunk_spacing_y: float = 4.0
@export var chunk_scenes: Array[PackedScene] = []

@export_group("Crew")
@export var crew_scene: PackedScene
@export var crew_depth_offset: float = 3.0
@export_group("")

@onready var global_camera: Camera3D = $GlobalCamera

var _cameras: Array[Camera3D] = []
var _current_idx: int = 0
var _chunk_positions: Array[Vector3] = []
var _grid_maps: Array[GridMap] = []
var _nav_region: NavigationRegion3D

# Highlight
var _highlight: MeshInstance3D
var _highlight_mat: StandardMaterial3D
var _has_hover: bool = false
var _hovered_world_pos: Vector3 = Vector3.ZERO

# Turn system
var _turn_phase: TurnPhase = TurnPhase.PLAYER_TURN
var _state: InvasionState = InvasionState.IDLE
var _player_units: Array[CrewEntity] = []
var _enemy_units: Array[Node3D] = []
var _selected: CrewEntity = null
var _acted: Dictionary = {}
var _enemy_turn_running: bool = false

# HUD
var _hud: CanvasLayer
var _hud_root: Control
var _phase_label: Label
var _selection_label: Label
var _result_label: Label
var _pass_btn: Button

# Crew roster panel
var _crew_panel: PanelContainer
var _crew_btns: Array[Button] = []

const DICE_LABEL: Dictionary = {0: "D4", 1: "D6", 2: "D8", 3: "D10", 4: "D12", 5: "[X]"}

# Action panel
var _action_panel: PanelContainer
var _action_name_label: Label
var _move_btn: Button
var _traits_hbox: HBoxContainer
var _target_section: VBoxContainer
var _enemy_targets_hbox: HBoxContainer
var _cancel_action_btn: Button
var _pending_trait_name: String = ""
var _pending_trait: TraitData = null
var _pending_targeting_type: TargetingType = TargetingType.RANGED_ENEMY
var _enemy_traits_exhausted: Dictionary = {}

func _ready() -> void:
	_setup_navmesh()
	_spawn_chunks()
	_setup_global_camera()
	_activate_camera(0)
	_setup_highlight()
	_build_hud()
	_spawn_enemies()
	_nav_region.bake_finished.connect(_on_navmesh_baked, CONNECT_ONE_SHOT)
	_nav_region.bake_navigation_mesh(true)

func _on_navmesh_baked() -> void:
	_spawn_players()
	_build_crew_roster()
	_start_player_turn()

# ── NavMesh ────────────────────────────────────────────────────────────────────

func _setup_navmesh() -> void:
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "NavigationRegion"
	add_child(_nav_region)
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.2
	nav_mesh.agent_height = 0.8
	nav_mesh.agent_max_climb = 0.25
	nav_mesh.agent_max_slope = 30.0
	nav_mesh.cell_size = 0.2
	nav_mesh.cell_height = 0.1
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = &"navmesh_source"
	_nav_region.navigation_mesh = nav_mesh

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
			var gm := _find_grid_map(chunk)
			if gm:
				_grid_maps.append(gm)
			var cam := _find_camera(chunk)
			if cam:
				_cameras.append(cam)

func _spawn_players() -> void:
	if crew_scene == null or Player.player_party.is_empty() or _chunk_positions.is_empty():
		return
	var chunk0 := _chunk_positions[0]
	var count := Player.player_party.size()
	for i in range(count):
		var member := crew_scene.instantiate() as CrewEntity
		add_child(member)
		member.data = Player.player_party[i]
		var x_offset := (float(i) - float(count - 1) * 0.5) * 1.5
		var pos := Vector3(chunk0.x + chunk_spacing_x * 0.5 + x_offset, chunk0.y + 0.8, chunk0.z - crew_depth_offset)
		member.place_stationary(pos)
		member.interacted.connect(_on_crew_selected.bind(member))
		_player_units.append(member)

func _spawn_enemies() -> void:
	var party := World.pending_enemy_party
	if party.is_empty() or _chunk_positions.is_empty():
		return
	var right_col := grid_columns - 1
	var host_chunks: Array[int] = []
	for row in range(grid_rows):
		var idx := row * grid_columns + right_col
		if idx < _chunk_positions.size():
			host_chunks.append(idx)
	for i in range(party.size()):
		if host_chunks.is_empty():
			break
		var cidx := host_chunks[i % host_chunks.size()]
		var cpos := _chunk_positions[cidx]
		var slot := floori(float(i) / float(host_chunks.size()))
		var x_offset := (float(slot) - 0.5) * 2.0
		var spawn := Vector3(cpos.x + chunk_spacing_x * 0.5 + x_offset, cpos.y + 0.8, cpos.z - crew_depth_offset)
		var pawn := _make_enemy_pawn(party[i])
		add_child(pawn)
		pawn.global_position = spawn
		pawn.set_meta("enemy_data", party[i])
		_enemy_units.append(pawn)

func _make_enemy_pawn(enemy: EnemyEntity) -> Node3D:
	var root := Node3D.new()
	if enemy.sprite != null:
		var sprite := AnimatedSprite3D.new()
		sprite.sprite_frames = enemy.sprite
		sprite.pixel_size = 0.012
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.scale = Vector3(2.0, 2.0, 2.0)
		sprite.position = Vector3(0.0, 0.5, 0.0)
		sprite.play()
		root.add_child(sprite)
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.7, 0.1)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.15, 0.15)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box.surface_set_material(0, mat)
		mi.mesh = box
		mi.position = Vector3(0.0, 0.5, 0.0)
		root.add_child(mi)
	var label := Label3D.new()
	label.text = enemy.name
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 0.6, 0.6, 0.9)
	label.position = Vector3(0.0, 1.3, 0.0)
	label.font_size = 20
	label.outline_size = 6
	root.add_child(label)
	return root

# ── Turn System ────────────────────────────────────────────────────────────────

func _start_player_turn() -> void:
	_turn_phase = TurnPhase.PLAYER_TURN
	_state = InvasionState.IDLE
	_acted.clear()
	_selected = null
	_restore_unit_tints()
	_phase_label.text = "TURNO DO JOGADOR"
	_pass_btn.visible = true
	_selection_label.text = "Selecione um tripulante"
	_hide_action_panel()
	_refresh_crew_roster()

func _on_crew_selected(crew: CrewEntity) -> void:
	if _turn_phase != TurnPhase.PLAYER_TURN or _enemy_turn_running:
		return
	var idx := _player_units.find(crew)
	if idx >= 0:
		_on_crew_btn_pressed(idx)

func _on_crew_btn_pressed(idx: int) -> void:
	if _turn_phase != TurnPhase.PLAYER_TURN or _enemy_turn_running:
		return
	var crew := _player_units[idx]
	if _acted.get(crew.get_instance_id(), false):
		return
	_selected = crew
	_state = InvasionState.SELECT_ACTION
	_restore_unit_tints()
	_tint_selected(crew)
	_show_action_panel_for(crew)
	_refresh_crew_roster()
	_selection_label.text = crew.data.name if crew.data else "?"

func _on_move_btn_pressed() -> void:
	if _selected == null:
		return
	_state = InvasionState.MOVING
	_move_btn.disabled = true
	_selection_label.text = "Clique para mover %s" % (_selected.data.name if _selected.data else "?")

func _on_cancel_action_pressed() -> void:
	_restore_unit_tints()
	_hide_action_panel()
	_refresh_crew_roster()
	_selection_label.text = "Selecione um tripulante"

func _on_tile_clicked() -> void:
	if _state != InvasionState.MOVING or _selected == null or not _has_hover:
		return
	var target := Vector3(_hovered_world_pos.x, _selected.global_position.y, _hovered_world_pos.z)
	_selected.go_to_task(target)
	_acted[_selected.get_instance_id()] = true
	_tint_acted(_selected)
	_hide_action_panel()
	_refresh_crew_roster()
	_selected = null
	_state = InvasionState.IDLE
	_selection_label.text = "Selecione um tripulante"
	if _acted.size() >= _player_units.size():
		_begin_enemy_turn()

func _on_pass_turn() -> void:
	if _turn_phase != TurnPhase.PLAYER_TURN or _enemy_turn_running:
		return
	_begin_enemy_turn()

func _begin_enemy_turn() -> void:
	_turn_phase = TurnPhase.ENEMY_TURN
	_state = InvasionState.IDLE
	_selected = null
	_hide_action_panel()
	_pass_btn.visible = false
	_phase_label.text = "TURNO INIMIGO"
	_selection_label.text = ""
	_enemy_turn_running = true
	_run_enemy_turn()

func _run_enemy_turn() -> void:
	var step_delay := 0.7
	for i in range(_enemy_units.size()):
		var enemy := _enemy_units[i]
		var nearest := _nearest_player(enemy.global_position)
		if nearest == null:
			continue
		var dist := enemy.global_position.distance_to(nearest.global_position)
		var move_range := 2.5
		if dist > 1.0:
			var dir := (nearest.global_position - enemy.global_position).normalized()
			dir.y = 0.0
			var step := minf(move_range, dist - 0.9)
			var new_pos := enemy.global_position + dir * step
			new_pos.y = enemy.global_position.y
			var tw := create_tween()
			tw.tween_property(enemy, "global_position", new_pos, 0.45)
			await get_tree().create_timer(step_delay).timeout
		if enemy.global_position.distance_to(nearest.global_position) < 1.8:
			_enemy_attack(enemy, nearest)
			await get_tree().create_timer(step_delay).timeout
	_enemy_turn_running = false
	_start_player_turn()

func _enemy_attack(enemy: Node3D, target: CrewEntity) -> void:
	var data: EnemyEntity = enemy.get_meta("enemy_data") as EnemyEntity
	if data == null:
		return
	var die := data.attitude.die
	var faces: Array = System.DICES[die]
	var roll_val: int = faces.pick_random() if not faces.is_empty() else 0
	var result := System.resolve([roll_val], [die])
	var suffix := ""
	match result:
		System.Results.CRITICAL_SUCCESS, System.Results.SUCCESS, System.Results.MITIGATED_SUCCESS:
			if target.data:
				target.data.take_damage("body")
			suffix = " 💥"
		_:
			pass
	_show_result("%s ataca %s → %d → %s%s" % [
		data.name,
		target.data.name if target.data else "?",
		roll_val,
		_result_label_text(result),
		suffix
	])

func _nearest_player(from: Vector3) -> CrewEntity:
	var nearest: CrewEntity = null
	var min_dist := INF
	for crew in _player_units:
		if not is_instance_valid(crew):
			continue
		var d := crew.global_position.distance_to(from)
		if d < min_dist:
			min_dist = d
			nearest = crew
	return nearest

# ── Visual Helpers ─────────────────────────────────────────────────────────────

func _tint_selected(crew: CrewEntity) -> void:
	var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
	if sprite:
		sprite.modulate = Color(0.4, 1.0, 0.4)

func _tint_acted(crew: CrewEntity) -> void:
	var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.8)

func _restore_unit_tints() -> void:
	for crew in _player_units:
		var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
		if sprite:
			sprite.modulate = Color(0.5, 0.5, 0.8) if _acted.get(crew.get_instance_id(), false) else Color.WHITE

func _show_result(text: String) -> void:
	_result_label.text = text
	_result_label.visible = true
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		_result_label.visible = false

func _result_label_text(result: System.Results) -> String:
	match result:
		System.Results.CRITICAL_SUCCESS: return "SUCESSO CRÍTICO"
		System.Results.SUCCESS:          return "SUCESSO"
		System.Results.MITIGATED_SUCCESS: return "SUCESSO MITIGADO"
		System.Results.FAILURE:          return "FALHA"
		System.Results.CRITICAL_FAILURE: return "FALHA CRÍTICA"
	return "?"

# ── Camera ─────────────────────────────────────────────────────────────────────

func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var result := _find_camera(child)
		if result:
			return result
	return null

func _find_grid_map(node: Node) -> GridMap:
	if node is GridMap:
		return node as GridMap
	for child in node.get_children():
		var result := _find_grid_map(child)
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
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_tile_clicked()
		return

	if not (event is InputEventKey) or not (event as InputEventKey).pressed:
		return
	if _cameras.size() < 2:
		return
	if event.is_action_pressed("ui_focus_next"):
		var next := (_current_idx + 1) % _cameras.size()
		_activate_camera(1 if next == 0 else next)
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE:
			_activate_camera(0)
		KEY_ESCAPE:
			World.end_invasion()

# ── HUD ────────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(root)
	_hud_root = root

	_phase_label = Label.new()
	_phase_label.position = Vector2(10, 10)
	_phase_label.add_theme_font_size_override("font_size", 20)
	root.add_child(_phase_label)

	_selection_label = Label.new()
	_selection_label.position = Vector2(10, 38)
	root.add_child(_selection_label)

	var hint := Label.new()
	hint.text = "Tab: sala  |  Space: visão geral"
	hint.position = Vector2(10, 58)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	root.add_child(hint)

	_result_label = Label.new()
	_result_label.set_anchor(SIDE_LEFT, 0.5)
	_result_label.set_anchor(SIDE_RIGHT, 0.5)
	_result_label.set_anchor(SIDE_TOP, 0.5)
	_result_label.set_anchor(SIDE_BOTTOM, 0.5)
	_result_label.position = Vector2(-200, -40)
	_result_label.add_theme_font_size_override("font_size", 18)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_result_label.visible = false
	root.add_child(_result_label)

	_pass_btn = Button.new()
	_pass_btn.text = "Passar Turno"
	_pass_btn.custom_minimum_size = Vector2(140, 40)
	_pass_btn.set_anchor(SIDE_RIGHT, 1.0)
	_pass_btn.set_anchor(SIDE_LEFT, 1.0)
	_pass_btn.set_anchor(SIDE_TOP, 1.0)
	_pass_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_pass_btn.position = Vector2(-150, -100)
	_pass_btn.pressed.connect(_on_pass_turn)
	root.add_child(_pass_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Retirar"
	exit_btn.custom_minimum_size = Vector2(120, 40)
	exit_btn.set_anchor(SIDE_RIGHT, 1.0)
	exit_btn.set_anchor(SIDE_LEFT, 1.0)
	exit_btn.set_anchor(SIDE_TOP, 1.0)
	exit_btn.set_anchor(SIDE_BOTTOM, 1.0)
	exit_btn.position = Vector2(-130, -50)
	exit_btn.pressed.connect(World.end_invasion)
	root.add_child(exit_btn)

	_build_action_panel_ui(root)

func _build_crew_roster() -> void:
	if _crew_panel != null:
		_crew_panel.queue_free()
	_crew_btns.clear()

	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT, 0.0)
	panel.set_anchor(SIDE_TOP, 0.0)
	panel.position = Vector2(10, 80)
	panel.custom_minimum_size = Vector2(160, 0)
	_hud_root.add_child(panel)
	_crew_panel = panel

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "TRIPULAÇÃO"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title)

	for i in range(_player_units.size()):
		var crew := _player_units[i]
		var btn := Button.new()
		btn.text = crew.data.name if crew.data else "Crew %d" % i
		btn.custom_minimum_size = Vector2(140, 36)
		btn.pressed.connect(_on_crew_btn_pressed.bind(i))
		vbox.add_child(btn)
		_crew_btns.append(btn)

func _build_action_panel_ui(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT, 0.5)
	panel.set_anchor(SIDE_RIGHT, 0.5)
	panel.set_anchor(SIDE_TOP, 1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.position = Vector2(-180, -90)
	panel.custom_minimum_size = Vector2(360, 70)
	panel.visible = false
	root.add_child(panel)
	_action_panel = panel

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_action_name_label = Label.new()
	_action_name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_action_name_label)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	_move_btn = Button.new()
	_move_btn.text = "Mover"
	_move_btn.custom_minimum_size = Vector2(80, 32)
	_move_btn.pressed.connect(_on_move_btn_pressed)
	hbox.add_child(_move_btn)

	_traits_hbox = HBoxContainer.new()
	_traits_hbox.add_theme_constant_override("separation", 6)
	hbox.add_child(_traits_hbox)

	_cancel_action_btn = Button.new()
	_cancel_action_btn.text = "Cancelar"
	_cancel_action_btn.custom_minimum_size = Vector2(80, 32)
	_cancel_action_btn.pressed.connect(_on_cancel_action_pressed)
	hbox.add_child(_cancel_action_btn)

	_target_section = VBoxContainer.new()
	_target_section.visible = false
	vbox.add_child(_target_section)

	var target_lbl := Label.new()
	target_lbl.text = "Selecione o alvo:"
	target_lbl.add_theme_font_size_override("font_size", 12)
	_target_section.add_child(target_lbl)

	_enemy_targets_hbox = HBoxContainer.new()
	_enemy_targets_hbox.add_theme_constant_override("separation", 6)
	_target_section.add_child(_enemy_targets_hbox)

func _refresh_crew_roster() -> void:
	for i in range(_crew_btns.size()):
		if i >= _player_units.size():
			break
		var crew := _player_units[i]
		var btn := _crew_btns[i]
		var acted: bool = _acted.get(crew.get_instance_id(), false)
		if acted:
			btn.modulate = Color(0.5, 0.5, 0.5)
			btn.disabled = true
		elif _selected == crew:
			btn.modulate = Color(0.4, 1.0, 0.4)
			btn.disabled = false
		else:
			btn.modulate = Color.WHITE
			btn.disabled = false

func _show_action_panel_for(crew: CrewEntity) -> void:
	var display := crew.data.name if crew.data else "?"
	if crew.data:
		var class_str := ""
		if crew.data.crew_class == EntityCharacter.CrewClass.GENERALIST:
			class_str = "Generalista"
		elif crew.data.crew_class == EntityCharacter.CrewClass.ENGINEER:
			class_str = "Engenheiro"
		elif crew.data.crew_class == EntityCharacter.CrewClass.COMBAT_SPECIALIST:
			class_str = "Combatente"
		elif crew.data.crew_class == EntityCharacter.CrewClass.MEDIC:
			class_str = "Médico"
		elif crew.data.crew_class == EntityCharacter.CrewClass.PILOT:
			class_str = "Piloto"
		if class_str != "":
			display += " — " + class_str
	_action_name_label.text = display
	_move_btn.disabled = false
	_target_section.visible = false
	_populate_trait_buttons(crew)
	_action_panel.visible = true

func _populate_trait_buttons(crew: CrewEntity) -> void:
	for child in _traits_hbox.get_children():
		child.queue_free()
	if crew.data == null:
		return
	for trait_name: String in crew.data.focus_traits:
		var td: TraitData = crew.data.focus_traits[trait_name]
		if td.context != System.Context.COMBAT:
			continue
		var btn := Button.new()
		var die_str: String = DICE_LABEL.get(int(td.die), "?")
		btn.text = "%s [%s]" % [trait_name, die_str]
		btn.disabled = td.die == System.Dice.EXHAUSTED
		var tn := trait_name
		btn.pressed.connect(_on_trait_btn_pressed.bind(tn, td))
		_traits_hbox.add_child(btn)

func _get_targeting_type(td: TraitData) -> TargetingType:
	for kw: String in td.keywords:
		var val = KEYWORD_TARGETING.get(kw.to_lower(), -1)
		if val >= 0:
			return val as TargetingType
	return TargetingType.RANGED_ENEMY

func _get_valid_enemy_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(_enemy_units.size()):
		var enemy := _enemy_units[i]
		if not is_instance_valid(enemy):
			continue
		if _pending_targeting_type == TargetingType.MELEE_ENEMY:
			if _selected == null or _selected.global_position.distance_to(enemy.global_position) > MELEE_RANGE:
				continue
		result.append(i)
	return result

func _get_valid_ally_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(_player_units.size()):
		if is_instance_valid(_player_units[i]):
			result.append(i)
	return result

func _on_trait_btn_pressed(trait_name: String, td: TraitData) -> void:
	_pending_trait_name = trait_name
	_pending_trait = td
	_pending_targeting_type = _get_targeting_type(td)
	if _pending_targeting_type == TargetingType.SELF:
		_execute_self_action()
		return
	_state = InvasionState.SELECT_TARGET
	_show_target_section()
	_selection_label.text = "Selecione o alvo para %s" % trait_name

func _execute_self_action() -> void:
	if _selected == null or _pending_trait == null:
		return
	var die := _pending_trait.die
	var faces: Array = System.DICES[die]
	var roll_val: int = faces.pick_random() if not faces.is_empty() else 0
	var result := System.resolve([roll_val], [die])
	_show_result("%s usa %s → %d → %s" % [
		_selected.data.name if _selected.data else "?",
		_pending_trait_name,
		roll_val,
		_result_label_text(result)
	])
	_acted[_selected.get_instance_id()] = true
	_tint_acted(_selected)
	_pending_trait = null
	_pending_trait_name = ""
	_selected = null
	_state = InvasionState.IDLE
	_hide_action_panel()
	_refresh_crew_roster()
	_selection_label.text = "Selecione um tripulante"
	if _acted.size() >= _player_units.size():
		_begin_enemy_turn()

func _show_target_section() -> void:
	for child in _enemy_targets_hbox.get_children():
		child.queue_free()

	if _pending_targeting_type == TargetingType.ALLY:
		_target_section.get_child(0).set("text", "Selecione o aliado:")
		for i in _get_valid_ally_indices():
			var crew := _player_units[i]
			var btn := Button.new()
			btn.text = crew.data.name if crew.data else "Crew %d" % i
			btn.custom_minimum_size = Vector2(100, 32)
			btn.pressed.connect(_on_ally_target_pressed.bind(i))
			_enemy_targets_hbox.add_child(btn)
	else:
		var valid_enemies := _get_valid_enemy_indices()
		if _pending_targeting_type == TargetingType.MELEE_ENEMY:
			_target_section.get_child(0).set("text", "Alvos próximos:")
		else:
			_target_section.get_child(0).set("text", "Selecione o alvo:")
		if valid_enemies.is_empty():
			var lbl := Label.new()
			lbl.text = "Nenhum inimigo próximo"
			lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
			_enemy_targets_hbox.add_child(lbl)
		else:
			for i in valid_enemies:
				var enemy := _enemy_units[i]
				var data: EnemyEntity = enemy.get_meta("enemy_data") as EnemyEntity
				var btn := Button.new()
				btn.text = data.name if data else "Inimigo %d" % i
				btn.custom_minimum_size = Vector2(100, 32)
				btn.pressed.connect(_on_enemy_target_pressed.bind(i))
				_enemy_targets_hbox.add_child(btn)
	_target_section.visible = true

func _damage_enemy(enemy: Node3D) -> void:
	var id := enemy.get_instance_id()
	var hits: int = _enemy_traits_exhausted.get(id, 0) + 1
	_enemy_traits_exhausted[id] = hits
	var data: EnemyEntity = enemy.get_meta("enemy_data") as EnemyEntity
	if data and hits >= data.get_traits_to_exhaust():
		_defeat_enemy(enemy)

func _defeat_enemy(enemy: Node3D) -> void:
	var idx := _enemy_units.find(enemy)
	if idx >= 0:
		_enemy_units.remove_at(idx)
	_enemy_traits_exhausted.erase(enemy.get_instance_id())
	enemy.queue_free()
	if _enemy_units.is_empty():
		_show_result("Todos os inimigos derrotados! Invasão concluída.")
		await get_tree().create_timer(2.5).timeout
		World.end_invasion()

func _on_enemy_target_pressed(idx: int) -> void:
	if _selected == null or _pending_trait == null:
		return
	var attacker_name := _selected.data.name if _selected.data else "?"
	var die := _pending_trait.die
	var faces: Array = System.DICES[die]
	var roll_val: int = faces.pick_random() if not faces.is_empty() else 0
	var result := System.resolve([roll_val], [die])
	var enemy := _enemy_units[idx]
	var enemy_data: EnemyEntity = enemy.get_meta("enemy_data") as EnemyEntity
	var enemy_name := enemy_data.name if enemy_data else "Inimigo"
	var suffix := ""
	match result:
		System.Results.CRITICAL_SUCCESS, System.Results.SUCCESS:
			_damage_enemy(enemy)
			suffix = " 💥"
		System.Results.MITIGATED_SUCCESS:
			_damage_enemy(enemy)
			_selected.data.take_damage("body")
			suffix = " 💥 (%s ferido)" % attacker_name
		System.Results.CRITICAL_FAILURE:
			_selected.data.take_damage("body")
			suffix = " (%s ferido)" % attacker_name
		_:
			pass
	_show_result("%s usa %s em %s → %d → %s%s" % [
		attacker_name, _pending_trait_name, enemy_name,
		roll_val, _result_label_text(result), suffix
	])
	_acted[_selected.get_instance_id()] = true
	_tint_acted(_selected)
	_pending_trait = null
	_pending_trait_name = ""
	_selected = null
	_state = InvasionState.IDLE
	_hide_action_panel()
	_refresh_crew_roster()
	_selection_label.text = "Selecione um tripulante"
	if _acted.size() >= _player_units.size():
		_begin_enemy_turn()

func _on_ally_target_pressed(idx: int) -> void:
	if _selected == null or _pending_trait == null:
		return
	var target_crew := _player_units[idx]
	var die := _pending_trait.die
	var faces: Array = System.DICES[die]
	var roll_val: int = faces.pick_random() if not faces.is_empty() else 0
	var result := System.resolve([roll_val], [die])
	var target_name := target_crew.data.name if target_crew.data else "aliado"
	_show_result("%s usa %s em %s → %d → %s" % [
		_selected.data.name if _selected.data else "?",
		_pending_trait_name,
		target_name,
		roll_val,
		_result_label_text(result)
	])
	_acted[_selected.get_instance_id()] = true
	_tint_acted(_selected)
	_pending_trait = null
	_pending_trait_name = ""
	_selected = null
	_state = InvasionState.IDLE
	_hide_action_panel()
	_refresh_crew_roster()
	_selection_label.text = "Selecione um tripulante"
	if _acted.size() >= _player_units.size():
		_begin_enemy_turn()

func _hide_action_panel() -> void:
	_action_panel.visible = false
	_target_section.visible = false
	_pending_trait = null
	_pending_trait_name = ""

# ── Hover Highlight ────────────────────────────────────────────────────────────

func _setup_highlight() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.92, 0.06, 0.92)
	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.5)
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.surface_set_material(0, _highlight_mat)
	_highlight = MeshInstance3D.new()
	_highlight.mesh = mesh
	_highlight.visible = false
	add_child(_highlight)

func _process(_delta: float) -> void:
	_update_hover()
	if _state == InvasionState.MOVING and _has_hover:
		_highlight_mat.albedo_color = Color(0.2, 1.0, 0.2, 0.55)
	else:
		_highlight_mat.albedo_color = Color(0.2, 0.8, 1.0, 0.5)

func _update_hover() -> void:
	if _current_idx == 0 or _current_idx > _grid_maps.size():
		_highlight.visible = false
		_has_hover = false
		return

	var active_cam := _cameras[_current_idx]
	var active_gm := _grid_maps[_current_idx - 1]
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := active_cam.project_ray_origin(mouse_pos)
	var direction := active_cam.project_ray_normal(mouse_pos)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 60.0)
	var hit := space.intersect_ray(query)

	if hit.is_empty() or (hit.normal as Vector3).y < 0.5:
		_highlight.visible = false
		_has_hover = false
		return

	var local_hit := active_gm.to_local(hit.position - hit.normal * 0.02)
	var cell := active_gm.local_to_map(local_hit)
	if active_gm.get_cell_item(cell) >= 0:
		var cell_world := active_gm.to_global(active_gm.map_to_local(cell))
		_highlight.global_position = cell_world + Vector3(0.0, 0.53, 0.0)
		_hovered_world_pos = cell_world
		_has_hover = true
		_highlight.visible = true
	else:
		_highlight.visible = false
		_has_hover = false

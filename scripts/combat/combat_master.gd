extends Node3D

signal entity_selected(entity: EntityCombat)

const ENTITY_SCENE: PackedScene = preload("res://scenes/combat/entity_combat.tscn")
const PARTY_SPACING := 0.6

@onready var player_party_node: Node3D = $PlayerParty
@onready var enemy_party_node: Node3D = $EnemyParty
@onready var turn_manager: CombatTurnManager = $TurnManager
@onready var combat_ui: CanvasLayer = $CombatUI

var combat_order: Array[EntityCombat] = []
var player_entities: Array[EntityCombat] = []
var enemy_entities: Array[EntityCombat] = []
var selected_entity: EntityCombat = null

func _ready() -> void:
	_spawn_party(Player.player_party, player_party_node, +1.0)
	_spawn_party(World.pending_enemy_party, enemy_party_node, -1.0)
	World.pending_enemy_party = []
	_register_existing(player_party_node, true)
	_register_existing(enemy_party_node, false)

	for entity in combat_order:
		entity.initialize_combat()

	turn_manager.players = player_entities
	turn_manager.enemies = enemy_entities
	turn_manager.phase_changed.connect(combat_ui._on_phase_changed)
	turn_manager.round_started.connect(_on_round_started)
	turn_manager.enemy_action_ready.connect(_on_enemy_action_ready)
	turn_manager.log_message.connect(combat_ui._on_log_message)
	turn_manager.combat_ended.connect(combat_ui._on_combat_ended)
	combat_ui.action_confirmed.connect(_on_action_confirmed)
	combat_ui.result_dismissed.connect(_on_result_dismissed)
	combat_ui.enemy_result_dismissed.connect(_on_enemy_result_dismissed)
	combat_ui.connect_to_master(self)

	turn_manager.start()

func _register_existing(parent: Node3D, is_player_side: bool) -> void:
	for child in parent.get_children():
		if child is EntityCombat and child not in combat_order:
			combat_order.append(child)
			if is_player_side:
				child.is_player = true
				child.selected.connect(_on_entity_selected)
				player_entities.append(child)
			else:
				enemy_entities.append(child)

func _spawn_party(party: Array, parent: Node3D, side: float) -> void:
	for i in party.size():
		var entity: EntityCombat = ENTITY_SCENE.instantiate()
		entity.stats = party[i]
		entity.position = Vector3(side * 0.5, 0, (i - (party.size() - 1) / 2.0) * PARTY_SPACING)
		parent.add_child(entity)
		combat_order.append(entity)
		if parent == player_party_node:
			entity.is_player = true
			entity.selected.connect(_on_entity_selected)
			player_entities.append(entity)
		else:
			enemy_entities.append(entity)

func _input(event: InputEvent) -> void:
	if event is InputEventKey \
			and event.keycode == KEY_TAB \
			and event.pressed \
			and not event.echo:
		if turn_manager.current_phase != CombatTurnManager.Phase.PLAYER_TURN:
			return
		var unacted := _get_unacted_players()
		if unacted.is_empty():
			return
		var idx := unacted.find(selected_entity)
		var next_idx := (idx + 1) % unacted.size()
		_select_entity(unacted[next_idx])
		combat_ui.show_action_panel_for(unacted[next_idx], _get_alive_enemies())

func _select_entity(entity: EntityCombat) -> void:
	if selected_entity:
		selected_entity.set_selected(false)
	selected_entity = entity
	entity.set_selected(true)
	entity_selected.emit(entity)

func _on_entity_selected(entity: EntityCombat) -> void:
	if turn_manager.current_phase != CombatTurnManager.Phase.PLAYER_TURN:
		return
	if entity.acted:
		return
	_select_entity(entity)
	combat_ui.show_action_panel_for(entity, _get_alive_enemies())

func _on_round_started(_round: int) -> void:
	for p in player_entities:
		p.set_acted(false)
	var unacted := _get_unacted_players()
	if unacted.is_empty():
		return
	_select_entity(unacted[0])
	combat_ui.show_action_panel_for(unacted[0], _get_alive_enemies())

func _on_enemy_action_ready(attacker_name: String, target: EntityCombat, result_data: Dictionary, hit_trait: String) -> void:
	combat_ui.show_enemy_result(attacker_name, target, result_data, hit_trait)

func _on_enemy_result_dismissed(target: EntityCombat, result_data: Dictionary, hit_trait: String) -> void:
	turn_manager.acknowledge_enemy_action(target, result_data, hit_trait)

func _on_action_confirmed(actor: EntityCombat, target: EntityCombat, core_trait: String, focus_trait: String, target_trait: String) -> void:
	var result_data := ActionResolver.roll_action(actor.combat_state, core_trait, focus_trait)
	combat_ui.show_action_result(result_data, actor, target, target_trait)

func _on_result_dismissed(result_data: Dictionary, actor: EntityCombat, target: EntityCombat, target_trait: String) -> void:
	actor.set_acted(true)
	turn_manager.player_acted(actor, result_data, target, target_trait)
	combat_ui.refresh_traits(actor)
	if turn_manager.current_phase == CombatTurnManager.Phase.PLAYER_TURN:
		var unacted := _get_unacted_players()
		if not unacted.is_empty():
			_select_entity(unacted[0])
			combat_ui.show_action_panel_for(unacted[0], _get_alive_enemies())

func _get_unacted_players() -> Array[EntityCombat]:
	var result: Array[EntityCombat] = []
	for p in player_entities:
		if not p.acted and (p.combat_state == null or not p.combat_state.is_core_exhausted()):
			result.append(p)
	return result

func _get_alive_enemies() -> Array[EntityCombat]:
	var result: Array[EntityCombat] = []
	for e in enemy_entities:
		if e.combat_state == null or not e.combat_state.is_core_exhausted():
			result.append(e)
	return result

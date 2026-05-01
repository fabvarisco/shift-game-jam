extends Node3D

signal entity_selected(entity: EntityCombat)

const ENTITY_SCENE: PackedScene = preload("res://assets/placeholder/sprites/entity_combat.tscn")
const PARTY_SPACING := 0.6

@onready var player_party_node: Node3D = $PlayerParty
@onready var enemy_party_node: Node3D = $EnemyParty

var combat_order: Array[EntityCombat] = []
var player_entities: Array[EntityCombat] = []
var selected_entity: EntityCombat = null

func _ready() -> void:
	_spawn_party(Player.player_party, player_party_node, +1.0)
	_spawn_party(World.pending_enemy_party, enemy_party_node, -1.0)
	World.pending_enemy_party = []
	_register_existing(player_party_node, true)
	_register_existing(enemy_party_node, false)
	$CombatUI.connect_to_master(self)
	if not player_entities.is_empty():
		_select_entity(player_entities[0])

func _register_existing(parent: Node3D, is_player_side: bool) -> void:
	for child in parent.get_children():
		if child is EntityCombat and child not in combat_order:
			combat_order.append(child)
			if is_player_side:
				child.is_player = true
				child.selected.connect(_on_entity_selected)
				player_entities.append(child)

func _spawn_party(party: Array[EntityStats], parent: Node3D, side: float) -> void:
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

func _input(event: InputEvent) -> void:
	if event is InputEventKey \
			and event.keycode == KEY_TAB \
			and event.pressed \
			and not event.echo:
		if player_entities.is_empty():
			return
		var idx := (player_entities.find(selected_entity) + 1) % player_entities.size()
		_select_entity(player_entities[idx])

func _select_entity(entity: EntityCombat) -> void:
	if selected_entity:
		selected_entity.set_selected(false)
	selected_entity = entity
	entity.set_selected(true)
	entity_selected.emit(entity)

func _on_entity_selected(entity: EntityCombat) -> void:
	_select_entity(entity)

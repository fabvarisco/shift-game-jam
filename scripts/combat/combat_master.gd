extends Node3D

const ENTITY_SCENE: PackedScene = preload("res://assets/placeholder/sprites/entity_combat.tscn")
const PARTY_SPACING := 0.6

@onready var player_party_node: Node3D = $PlayerParty
@onready var enemy_party_node: Node3D = $EnemyParty

var combat_order: Array[EntityCombat] = []

func _ready() -> void:
	_spawn_party(Player.player_party, player_party_node, +1.0)
	_spawn_party(World.pending_enemy_party, enemy_party_node, -1.0)
	World.pending_enemy_party = []


func _spawn_party(party: Array[EntityStats], parent: Node3D, side: float) -> void:
	for i in party.size():
		var entity: EntityCombat = ENTITY_SCENE.instantiate()
		entity.stats = party[i]
		entity.position = Vector3(side * 0.5, 0, (i - (party.size() - 1) / 2.0) * PARTY_SPACING)
		parent.add_child(entity)
		combat_order.append(entity)

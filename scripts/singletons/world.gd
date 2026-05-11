extends Node

const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat_master.tscn")
const SHIP_SCENE_PATH: String = "res://scenes/space_ship/space_ship_master.tscn"
const INVASION_SCENE_PATH: String = "res://scenes/space_ship/invasion_master.tscn"

var pending_enemy_party: Array[EnemyEntity] = []
var _return_scene_path: String = ""

func start_combat(enemy_party: Array[EnemyEntity], return_to: String = SHIP_SCENE_PATH) -> void:
	pending_enemy_party = enemy_party
	_return_scene_path = return_to
	get_tree().change_scene_to_packed(COMBAT_SCENE)

func return_from_combat() -> void:
	get_tree().change_scene_to_file(_return_scene_path)

func start_invasion(enemy_party: Array[EnemyEntity]) -> void:
	pending_enemy_party = enemy_party
	get_tree().change_scene_to_file(INVASION_SCENE_PATH)

func end_invasion() -> void:
	get_tree().change_scene_to_file(SHIP_SCENE_PATH)

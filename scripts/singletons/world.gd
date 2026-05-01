extends Node

const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat_master.tscn")

var pending_enemy_party: Array[EntityStats] = []

func start_combat(enemy_party: Array[EntityStats]) -> void:
	pending_enemy_party = enemy_party
	get_tree().change_scene_to_packed(COMBAT_SCENE)

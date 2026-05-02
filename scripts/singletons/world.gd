extends Node

const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat_master.tscn")

var pending_enemy_party: Array[EntityCharacter] = []

func start_combat(enemy_party: Array[EntityCharacter]) -> void:
	pending_enemy_party = enemy_party
	get_tree().change_scene_to_packed(COMBAT_SCENE)

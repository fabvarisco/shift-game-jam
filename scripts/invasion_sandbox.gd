extends Node

const WARRIOR: EntityCharacter = preload("res://resources/characters/character_warrior.tres")
const MAGE: EntityCharacter = preload("res://resources/characters/character_mage.tres")
const PRIEST: EntityCharacter = preload("res://resources/characters/character_priest.tres")
const GRUNT: EnemyEntity = preload("res://resources/characters/enemy_grunt.tres")
const GUARD: EnemyEntity = preload("res://resources/characters/enemy_guard.tres")

func _ready() -> void:
	Player.player_party = [WARRIOR, MAGE, PRIEST]
	var enemies: Array[EnemyEntity] = [GRUNT, GUARD]
	World.start_invasion.call_deferred(enemies)

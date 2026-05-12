extends Node

const DEFAULT_CREW_PATHS: Array[String] = [
	"res://resources/characters/character_warrior.tres",
	"res://resources/characters/character_mage.tres",
	"res://resources/characters/character_priest.tres",
]

var player_party: Array[EntityCharacter] = []
var player_last_pos := Vector3()

func reset_party() -> void:
	player_party.clear()
	player_last_pos = Vector3.ZERO
	for path in DEFAULT_CREW_PATHS:
		var template: EntityCharacter = load(path)
		if template:
			player_party.append(template.duplicate(true) as EntityCharacter)

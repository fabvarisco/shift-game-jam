extends Node

var _turns: int = 0
var _kills: int = 0
var _lost: Array[String] = []
var _crew_names: Array[String] = []
var _active: bool = false

func begin_run(crew: Array[EntityCharacter]) -> void:
	_turns = 0
	_kills = 0
	_lost = []
	_crew_names = []
	_active = true
	for m in crew:
		_crew_names.append(m.name)

func record_turn() -> void:
	if _active:
		_turns += 1

func record_kill() -> void:
	if _active:
		_kills += 1

func record_character_lost(char_name: String) -> void:
	if _active:
		_lost.append(char_name)

func end_run(victory: bool) -> void:
	if not _active:
		return
	SaveManager.save_run({
		"timestamp":        int(Time.get_unix_time_from_system()),
		"turns":            _turns,
		"crew_names":       _crew_names.duplicate(),
		"enemies_defeated": _kills,
		"characters_lost":  _lost.duplicate(),
		"victory":          victory,
	})
	_active = false

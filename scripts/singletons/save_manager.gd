extends Node

const SAVE_PATH := "user://game_data.cfg"

var _cfg := ConfigFile.new()

func _ready() -> void:
	_cfg.load(SAVE_PATH)

func save_settings(master: float, music: float, sfx: float, fullscreen: bool) -> void:
	_cfg.set_value("settings", "master_volume", master)
	_cfg.set_value("settings", "music_volume",  music)
	_cfg.set_value("settings", "sfx_volume",    sfx)
	_cfg.set_value("settings", "fullscreen",    fullscreen)
	_cfg.save(SAVE_PATH)

func load_settings() -> Dictionary:
	return {
		"master_volume": _cfg.get_value("settings", "master_volume", 1.0),
		"music_volume":  _cfg.get_value("settings", "music_volume",  1.0),
		"sfx_volume":    _cfg.get_value("settings", "sfx_volume",    1.0),
		"fullscreen":    _cfg.get_value("settings", "fullscreen",    false),
	}

func save_run(run_data: Dictionary) -> void:
	var history := get_run_history()
	history.append(run_data)
	_cfg.set_value("history", "runs", JSON.stringify(history))
	_cfg.save(SAVE_PATH)

func get_run_history() -> Array:
	var raw: String = _cfg.get_value("history", "runs", "[]")
	var parsed = JSON.parse_string(raw)
	return parsed if parsed is Array else []

func get_credits() -> int:
	return int(_cfg.get_value("meta", "total_credits", 0))

func add_credits(amount: int) -> void:
	_cfg.set_value("meta", "total_credits", get_credits() + amount)
	_cfg.save(SAVE_PATH)

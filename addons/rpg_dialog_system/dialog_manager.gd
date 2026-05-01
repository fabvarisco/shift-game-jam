extends Node

signal dialog_started
signal dialog_ended
signal entry_changed(entry: Dictionary)

var is_active: bool = false
var _entries: Array = []
var _index: int = 0


func start_dialog(json_path: String) -> void:
	_entries = _load_json(json_path)
	if _entries.is_empty():
		return
	_index = 0
	is_active = true
	dialog_started.emit()
	entry_changed.emit(_entries[0])


func advance() -> void:
	_index += 1
	if _index >= _entries.size():
		is_active = false
		dialog_ended.emit()
		return
	entry_changed.emit(_entries[_index])


func go_back() -> void:
	if _index <= 0:
		return
	_index -= 1
	entry_changed.emit(_entries[_index])


func skip_dialog() -> void:
	is_active = false
	dialog_ended.emit()


func _load_json(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogManager: cannot open '%s'" % path)
		return []
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("DialogManager: parse error in '%s'" % path)
		return []
	var data = json.get_data()
	if not data.has("entries") or not data["entries"] is Array:
		push_error("DialogManager: missing 'entries' array in '%s'" % path)
		return []
	return data["entries"]

extends Node

enum Phase { PLAYER_PHASE, ENCOUNTER_PHASE }

signal phase_changed(phase: Phase)
signal turn_started(turn: int)
signal encounter_started(event: EncounterEvent)
signal all_encounters_resolved()

var current_phase: Phase = Phase.PLAYER_PHASE
var turn_number: int = 1
var encounter_queue: Array = []
var _crew_acted: Dictionary = {}

func _ready() -> void:
	call_deferred("_emit_initial_state")

func _emit_initial_state() -> void:
	phase_changed.emit(current_phase)
	turn_started.emit(turn_number)

func record_crew_action(crew: Node) -> void:
	_crew_acted[crew.get_instance_id()] = true

func has_crew_acted(crew: Node) -> bool:
	return _crew_acted.get(crew.get_instance_id(), false)

func end_player_turn() -> void:
	_set_phase(Phase.ENCOUNTER_PHASE)
	encounter_queue = EncounterTable.roll(1, 2)
	_process_next_encounter()

func acknowledge_encounter() -> void:
	_process_next_encounter()

func _process_next_encounter() -> void:
	if encounter_queue.is_empty():
		_start_new_player_turn()
		return
	var event: EncounterEvent = encounter_queue.pop_front()
	encounter_started.emit(event)

func _start_new_player_turn() -> void:
	turn_number += 1
	_crew_acted.clear()
	all_encounters_resolved.emit()
	RunTracker.record_turn()
	_set_phase(Phase.PLAYER_PHASE)
	turn_started.emit(turn_number)

func reset() -> void:
	turn_number = 1
	_crew_acted.clear()
	encounter_queue.clear()
	_set_phase(Phase.PLAYER_PHASE)

func _set_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)

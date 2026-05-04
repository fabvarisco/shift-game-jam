class_name CombatTurnManager
extends Node

enum Phase { PLAYER_TURN, ENEMY_TURN, COMBAT_END }

signal phase_changed(phase: Phase)
signal round_started(round: int)
signal enemy_action_ready(attacker_name: String, target: EntityCombat, result_data: Dictionary, hit_trait: String)
signal log_message(text: String)
signal combat_ended(player_won: bool)

var players: Array[EntityCombat] = []
var enemies: Array[EntityCombat] = []

var current_phase: Phase = Phase.PLAYER_TURN
var _round: int = 0
var _acted_this_round: Array[EntityCombat] = []
var _enemy_queue: Array[EntityCombat] = []

func start() -> void:
	_round = 0
	_begin_round()

func _begin_round() -> void:
	_round += 1
	_acted_this_round.clear()
	log_message.emit("=== Round %d ===" % _round)
	_set_phase(Phase.PLAYER_TURN)
	round_started.emit(_round)

func player_acted(actor: EntityCombat, result_data: Dictionary, target: EntityCombat, target_trait: String) -> void:
	var result: System.Results = result_data["result"]
	var actor_name := actor.get_display_name()
	var rolls: Array = result_data["rolls"]
	var roll_str := " + ".join(rolls.map(func(r): return str(r)))

	match result:
		System.Results.CRITICAL_SUCCESS:
			log_message.emit("🌟 %s: CRITICAL SUCCESS! [%s]" % [actor_name, roll_str])
			_shift_target_trait_down(target, target_trait, true)
		System.Results.SUCCESS:
			log_message.emit("✅ %s: SUCCESS [%s]" % [actor_name, roll_str])
			_shift_target_trait_down(target, target_trait, false)
		System.Results.MITIGATED_SUCCESS:
			var shifted: String = result_data.get("shifted_attacker_trait", "")
			log_message.emit("⚡ %s: MITIGATED SUCCESS [%s] — %s desceu" % [actor_name, roll_str, shifted])
			_shift_target_trait_down(target, target_trait, false)
		System.Results.FAILURE:
			log_message.emit("❌ %s: FAILURE [%s]" % [actor_name, roll_str])
		System.Results.CRITICAL_FAILURE:
			var shifted: String = result_data.get("shifted_attacker_trait", "")
			log_message.emit("💀 %s: CRITICAL FAILURE [%s] — %s desceu" % [actor_name, roll_str, shifted])

	if _check_enemy_defeated(target) and current_phase == Phase.COMBAT_END:
		return

	if actor not in _acted_this_round:
		_acted_this_round.append(actor)

	var alive := players.filter(func(p): return not _is_player_defeated(p))
	if alive.all(func(p): return p in _acted_this_round):
		_begin_enemy_turn()

func _begin_enemy_turn() -> void:
	_set_phase(Phase.ENEMY_TURN)
	_enemy_queue = enemies.filter(func(e): return not _is_enemy_defeated(e))
	_process_next_enemy()

func _process_next_enemy() -> void:
	if _enemy_queue.is_empty():
		_begin_round()
		return

	var enemy := _enemy_queue.pop_front() as EntityCombat
	if enemy == null or enemy.combat_state == null:
		_process_next_enemy()
		return

	var enemy_name := enemy.get_display_name()
	var available := enemy.combat_state.get_available()
	if available.size() < 2:
		log_message.emit("%s não tem traits suficientes para agir." % enemy_name)
		_process_next_enemy()
		return

	var alive := players.filter(func(p): return not _is_player_defeated(p))
	if alive.is_empty():
		_set_phase(Phase.COMBAT_END)
		combat_ended.emit(false)
		return

	available.shuffle()
	var result_data := ActionResolver.roll_action(enemy.combat_state, available[0], available[1])
	var res: System.Results = result_data["result"]
	var target_player: EntityCombat = alive.pick_random()
	var hit_trait := ""
	match res:
		System.Results.CRITICAL_SUCCESS, System.Results.SUCCESS, System.Results.MITIGATED_SUCCESS:
			hit_trait = target_player.combat_state.get_strongest_available()

	enemy_action_ready.emit(enemy_name, target_player, result_data, hit_trait)

func acknowledge_enemy_action(target: EntityCombat, result_data: Dictionary, hit_trait: String) -> void:
	var res: System.Results = result_data["result"]
	match res:
		System.Results.CRITICAL_SUCCESS, System.Results.SUCCESS, System.Results.MITIGATED_SUCCESS:
			if hit_trait != "":
				target.combat_state.shift_down(hit_trait)
				log_message.emit("  → %s: %s desceu" % [target.get_display_name(), hit_trait])
				if _check_player_defeated(target) and current_phase == Phase.COMBAT_END:
					return
		_:
			log_message.emit("  → Ataque falhou")
	_process_next_enemy()

func _shift_target_trait_down(target: EntityCombat, trait_name: String, double_shift: bool) -> void:
	if target.combat_state == null:
		return
	if trait_name == "":
		trait_name = target.combat_state.get_strongest_available()
	if trait_name == "":
		return
	target.combat_state.shift_down(trait_name)
	log_message.emit("  → %s: %s desceu" % [target.get_display_name(), trait_name])
	if double_shift:
		var trait2 := target.combat_state.get_strongest_available()
		if trait2 != "":
			target.combat_state.shift_down(trait2)
			log_message.emit("  → %s: %s também desceu (bônus crítico)" % [target.get_display_name(), trait2])

func _check_enemy_defeated(enemy: EntityCombat) -> bool:
	if not _is_enemy_defeated(enemy):
		return false
	log_message.emit("🏆 %s foi derrotado!" % enemy.get_display_name())
	enemy.set_visible(false)
	if enemies.all(func(e): return _is_enemy_defeated(e)):
		_set_phase(Phase.COMBAT_END)
		combat_ended.emit(true)
	return true

func _check_player_defeated(player: EntityCombat) -> bool:
	if not _is_player_defeated(player):
		return false
	log_message.emit("💀 %s foi derrotado!" % player.get_display_name())
	if players.all(func(p): return _is_player_defeated(p)):
		_set_phase(Phase.COMBAT_END)
		combat_ended.emit(false)
	return true

func _is_enemy_defeated(enemy: EntityCombat) -> bool:
	return enemy.is_defeated()

func _is_player_defeated(player: EntityCombat) -> bool:
	return player.is_defeated()

func _set_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)

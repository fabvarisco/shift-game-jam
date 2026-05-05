extends CanvasLayer

signal action_confirmed(actor: EntityCombat, target: EntityCombat, core_trait: String, focus_trait: String, target_trait: String)
signal result_dismissed(action_result: Dictionary, actor: EntityCombat, target: EntityCombat, target_trait: String)
signal enemy_result_dismissed(target: EntityCombat, result_data: Dictionary, hit_trait: String)

const DICE_LABEL: Dictionary = {0: "D4", 1: "D6", 2: "D8", 3: "D10", 4: "D12", 5: "[X]"}
const PHASE_LABEL: Dictionary = {
	CombatTurnManager.Phase.PLAYER_TURN: "Player Turn",
	CombatTurnManager.Phase.ENEMY_TURN:  "Enemy Turn",
	CombatTurnManager.Phase.COMBAT_END:  "Combat Over",
}
const RESULT_TITLE: Dictionary = {
	System.Results.CRITICAL_SUCCESS:  "CRITICAL SUCCESS",
	System.Results.SUCCESS:           "SUCCESS",
	System.Results.MITIGATED_SUCCESS: "MITIGATED SUCCESS",
	System.Results.FAILURE:           "FAILURE",
	System.Results.CRITICAL_FAILURE:  "CRITICAL FAILURE",
}

@onready var core_box: VBoxContainer    = $Control/TraitsControl/TraitsPanel/HBoxContainer/CoreTraitsBox
@onready var focus_box: VBoxContainer   = $Control/TraitsControl/TraitsPanel/HBoxContainer/FocusTraitsBox
@onready var phase_label: Label         = $Control/PhaseLabel
@onready var action_panel: PanelContainer = $Control/ActionPanel
@onready var core_btn_box: HBoxContainer  = $Control/ActionPanel/VBox/CoreTraitButtons
@onready var focus_btn_box: HBoxContainer = $Control/ActionPanel/VBox/FocusTraitButtons
@onready var target_btn_box: HBoxContainer = $Control/ActionPanel/VBox/TargetButtons
@onready var enemy_trait_label: Label      = $Control/ActionPanel/VBox/EnemyTraitLabel
@onready var enemy_trait_btn_box: HBoxContainer = $Control/ActionPanel/VBox/EnemyTraitButtons
@onready var confirm_btn: Button          = $Control/ActionPanel/VBox/ConfirmButton
@onready var log_label: Label             = $Control/LogPanel/ScrollContainer/LogLabel
@onready var result_panel: PanelContainer = $Control/ResultPanel
@onready var result_title: Label          = $Control/ResultPanel/VBox/ResultTitle
@onready var result_rolls: Label          = $Control/ResultPanel/VBox/ResultRolls
@onready var result_outcome: Label        = $Control/ResultPanel/VBox/ResultOutcome
@onready var result_continue_btn: Button  = $Control/ResultPanel/VBox/ResultContinue

var _current_actor: EntityCombat = null
var _selected_core: String = ""
var _selected_focus: String = ""
var _selected_target: EntityCombat = null
var _selected_target_trait: String = ""
var _result_continue_callback: Callable
var _highlighted_enemy: EntityCombat = null

func _ready() -> void:
	confirm_btn.pressed.connect(_on_confirm_pressed)
	if result_continue_btn:
		result_continue_btn.pressed.connect(func():
			if _result_continue_callback.is_valid():
				_result_continue_callback.call()
		)
	if enemy_trait_label:
		enemy_trait_label.visible = false
	if enemy_trait_btn_box:
		enemy_trait_btn_box.visible = false

func connect_to_master(master: Node) -> void:
	master.entity_selected.connect(_on_entity_selected)

# ── Trait display ─────────────────────────────────────────────────────────────

func _on_entity_selected(entity: EntityCombat) -> void:
	_update_traits(entity)

func refresh_traits(entity: EntityCombat) -> void:
	_update_traits(entity)

func _update_traits(entity: EntityCombat) -> void:
	_clear(core_box)
	_clear(focus_box)
	if entity.stats == null:
		return

	_add_title(core_box, entity.get_display_name())
	var state := entity.combat_state

	if entity.stats is EntityCharacter:
		var ch := entity.stats as EntityCharacter
		_add_trait_row_live(core_box, "Mind", ch.mind, state)
		_add_trait_row_live(core_box, "Body", ch.body, state)
		_add_trait_row_live(core_box, "Soul", ch.soul, state)
		_add_title(focus_box, "Focus Traits")
		for k: String in ch.focus_traits:
			_add_trait_row_live(focus_box, k, ch.focus_traits[k], state)
	elif entity.stats is EnemyEntity:
		var en := entity.stats as EnemyEntity
		_add_trait_row_live(core_box, "Attitude", en.attitude, state)
		_add_title(focus_box, "Traits")
		for k: String in en.focus_traits:
			_add_trait_row_live(focus_box, k, en.focus_traits[k], state)

func _add_trait_row_live(box: VBoxContainer, label_name: String, data: TraitData, state: CombatState) -> void:
	var lbl := Label.new()
	var live_die: System.Dice = state.dice_state.get(label_name, data.die) if state else data.die
	var die: String = DICE_LABEL.get(live_die, "?")
	var kw: String = ", ".join(data.keywords) if not data.keywords.is_empty() else "—"
	var db: String = " (%s)" % ", ".join(data.drawbacks) if not data.drawbacks.is_empty() else ""
	lbl.text = "[%s] %s  %s%s" % [die, label_name, kw, db]
	if live_die == System.Dice.EXHAUSTED:
		lbl.modulate = Color(0.5, 0.5, 0.5)
	box.add_child(lbl)

# ── Action Panel ──────────────────────────────────────────────────────────────

func show_action_panel_for(actor: EntityCombat, enemies: Array) -> void:
	_clear_enemy_highlight()
	_current_actor = actor
	_selected_core = ""
	_selected_focus = ""
	_selected_target = null
	_selected_target_trait = ""
	_update_traits(actor)
	_build_action_panel(actor, enemies)
	action_panel.visible = true
	confirm_btn.disabled = true

func hide_action_panel() -> void:
	action_panel.visible = false

func _build_action_panel(actor: EntityCombat, enemies: Array) -> void:
	_clear(core_btn_box)
	_clear(focus_btn_box)
	_clear(target_btn_box)
	if enemy_trait_btn_box:
		_clear(enemy_trait_btn_box)
		enemy_trait_btn_box.visible = false
	if enemy_trait_label:
		enemy_trait_label.visible = false

	if actor.combat_state == null:
		return

	var btn_group := ButtonGroup.new()
	for trait_name in actor.combat_state.get_core_traits():
		var btn := Button.new()
		btn.text = "%s [%s]" % [trait_name, DICE_LABEL.get(actor.combat_state.dice_state[trait_name], "?")]
		btn.button_group = btn_group
		btn.toggle_mode = true
		btn.pressed.connect(func(): _on_core_selected(trait_name))
		core_btn_box.add_child(btn)

	for trait_name in actor.combat_state.get_focus_traits():
		var btn := Button.new()
		btn.text = "%s [%s]" % [trait_name, DICE_LABEL.get(actor.combat_state.dice_state[trait_name], "?")]
		btn.toggle_mode = true
		btn.pressed.connect(func(): _on_focus_selected(trait_name, btn))
		focus_btn_box.add_child(btn)

	for enemy in enemies:
		if enemy is EntityCombat:
			var btn := Button.new()
			btn.text = enemy.get_display_name()
			btn.pressed.connect(func(): _on_target_selected(enemy))
			target_btn_box.add_child(btn)

func _on_core_selected(trait_name: String) -> void:
	_selected_core = trait_name
	_update_confirm()

func _on_focus_selected(trait_name: String, btn: Button) -> void:
	if _selected_focus == trait_name:
		_selected_focus = ""
		btn.button_pressed = false
	else:
		_selected_focus = trait_name

func _clear_enemy_highlight() -> void:
	if _highlighted_enemy:
		_highlighted_enemy.set_selected(false)
		_highlighted_enemy = null

func _on_target_selected(target: EntityCombat) -> void:
	_clear_enemy_highlight()
	target.set_selected(true)
	_highlighted_enemy = target
	_selected_target = target
	_selected_target_trait = ""
	if not enemy_trait_btn_box or not enemy_trait_label:
		_update_confirm()
		return
	_clear(enemy_trait_btn_box)
	enemy_trait_label.visible = true
	enemy_trait_btn_box.visible = true
	var btn_group := ButtonGroup.new()
	for trait_name in target.combat_state.get_available():
		var btn := Button.new()
		btn.text = "%s [%s]" % [trait_name, DICE_LABEL.get(target.combat_state.dice_state[trait_name], "?")]
		btn.button_group = btn_group
		btn.toggle_mode = true
		btn.pressed.connect(func(): _on_target_trait_selected(trait_name))
		enemy_trait_btn_box.add_child(btn)
	_update_confirm()

func _on_target_trait_selected(trait_name: String) -> void:
	_selected_target_trait = trait_name
	_update_confirm()

func _update_confirm() -> void:
	var need_trait := enemy_trait_btn_box != null
	confirm_btn.disabled = _selected_core == "" or _selected_target == null or (need_trait and _selected_target_trait == "")

func _on_confirm_pressed() -> void:
	if _current_actor == null or _selected_core == "" or _selected_target == null:
		return
	_clear_enemy_highlight()
	action_panel.visible = false
	action_confirmed.emit(_current_actor, _selected_target, _selected_core, _selected_focus, _selected_target_trait)

# ── Result Panel ──────────────────────────────────────────────────────────────

func _show_result_panel(title: String, rolls_text: String, outcome_text: String, on_continue: Callable) -> void:
	result_title.text = title
	result_rolls.text = rolls_text
	result_outcome.text = outcome_text
	_result_continue_callback = on_continue
	result_panel.visible = true

func show_action_result(result_data: Dictionary, actor: EntityCombat, target: EntityCombat, target_trait: String) -> void:
	var rolls: Array = result_data["rolls"]
	var roll_parts: PackedStringArray = []
	for r in rolls:
		roll_parts.append(str(r))
	var roll_str: String = " + ".join(roll_parts)
	var trait_names: Array = result_data.get("trait_names", [])
	var dice_used: Array = result_data.get("dice_used", [])
	var dice_labels: PackedStringArray = []
	for i in trait_names.size():
		var die_idx: int = dice_used[i] if i < dice_used.size() else -1
		var die_label: String = DICE_LABEL.get(die_idx, "?")
		dice_labels.append("%s [%s]" % [trait_names[i], die_label])

	var title: String = RESULT_TITLE.get(result_data["result"], "?")
	var rolls_text: String = "Rolled: %s   (%s)" % [roll_str, "  +  ".join(dice_labels)]

	var outcome_lines: PackedStringArray = []
	match result_data["result"]:
		System.Results.CRITICAL_SUCCESS:
			outcome_lines.append("%s → %s shifted down (x2)" % [target.get_display_name(), target_trait])
		System.Results.SUCCESS:
			outcome_lines.append("%s → %s shifted down" % [target.get_display_name(), target_trait])
		System.Results.MITIGATED_SUCCESS:
			outcome_lines.append("%s → %s shifted down" % [target.get_display_name(), target_trait])
			var shifted: String = result_data.get("shifted_attacker_trait", "")
			if shifted != "":
				outcome_lines.append("%s → %s also shifted (cost)" % [actor.get_display_name(), shifted])
		System.Results.FAILURE:
			outcome_lines.append("No effect.")
		System.Results.CRITICAL_FAILURE:
			var shifted: String = result_data.get("shifted_attacker_trait", "")
			if shifted != "":
				outcome_lines.append("%s → %s shifted down" % [actor.get_display_name(), shifted])
			else:
				outcome_lines.append("Failed badly — no damage dealt.")

	_show_result_panel(title, rolls_text, "\n".join(outcome_lines), func():
		result_panel.visible = false
		result_dismissed.emit(result_data, actor, target, target_trait)
	)

func show_enemy_result(attacker_name: String, target: EntityCombat, result_data: Dictionary, hit_trait: String) -> void:
	var rolls: Array = result_data["rolls"]
	var roll_parts: PackedStringArray = []
	for r in rolls:
		roll_parts.append(str(r))
	var roll_str: String = " + ".join(roll_parts)
	var trait_names: Array = result_data.get("trait_names", [])
	var dice_used: Array = result_data.get("dice_used", [])
	var dice_labels: PackedStringArray = []
	for i in trait_names.size():
		var die_idx: int = dice_used[i] if i < dice_used.size() else -1
		var die_label: String = DICE_LABEL.get(die_idx, "?")
		dice_labels.append("%s [%s]" % [trait_names[i], die_label])

	var res_label: String = RESULT_TITLE.get(result_data["result"], "?")
	var title: String = "%s — %s" % [attacker_name, res_label]
	var rolls_text: String = "Rolled: %s   (%s)" % [roll_str, "  +  ".join(dice_labels)]

	var outcome_lines: PackedStringArray = []
	match result_data["result"]:
		System.Results.CRITICAL_SUCCESS, System.Results.SUCCESS, System.Results.MITIGATED_SUCCESS:
			if hit_trait != "":
				outcome_lines.append("%s → %s shifted down" % [target.get_display_name(), hit_trait])
			else:
				outcome_lines.append("Hit but no trait to target.")
		System.Results.FAILURE, System.Results.CRITICAL_FAILURE:
			outcome_lines.append("Attack failed.")

	_show_result_panel(title, rolls_text, "\n".join(outcome_lines), func():
		result_panel.visible = false
		enemy_result_dismissed.emit(target, result_data, hit_trait)
	)

# ── Phase / Log ───────────────────────────────────────────────────────────────

func _on_phase_changed(phase: CombatTurnManager.Phase) -> void:
	phase_label.text = PHASE_LABEL.get(phase, "")
	if phase != CombatTurnManager.Phase.PLAYER_TURN:
		_clear_enemy_highlight()
		action_panel.visible = false

func _on_log_message(text: String) -> void:
	var lines := log_label.text.split("\n")
	lines.append(text)
	if lines.size() > 30:
		lines = lines.slice(lines.size() - 30)
	log_label.text = "\n".join(lines)

func _on_combat_ended(player_won: bool) -> void:
	action_panel.visible = false
	phase_label.text = "VITÓRIA!" if player_won else "DERROTA..."
	_on_log_message("=== %s ===" % phase_label.text)
	var outcome := "A batalha terminou. A tripulação retorna à nave." if player_won \
		else "A tripulação foi derrotada. Retornando à nave..."
	_show_result_panel(
		"VITÓRIA!" if player_won else "DERROTA",
		"",
		outcome,
		func():
			result_panel.visible = false
			World.return_from_combat()
	)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _clear(box: Container) -> void:
	for child in box.get_children():
		child.queue_free()

func _add_title(box: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text.to_upper()
	box.add_child(lbl)

extends Control

@onready var _start_btn:    Button = $VBoxContainer/ButtonsContainer/StartButton
@onready var _shop_btn:     Button = $VBoxContainer/ButtonsContainer/ShopButton
@onready var _credits_btn:  Button = $VBoxContainer/ButtonsContainer/CreditsButton
@onready var _settings_btn: Button = $VBoxContainer/ButtonsContainer/SettingsButton
@onready var _history_btn:  Button = $VBoxContainer/ButtonsContainer/HistoryButton
@onready var _quit_btn:     Button = $VBoxContainer/ButtonsContainer/QuitButton

var _settings_overlay: ColorRect
var _credits_overlay: ColorRect
var _history_overlay: ColorRect
var _history_content: VBoxContainer

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton

func _ready() -> void:
	_apply_saved_settings()
	_shop_btn.text = "Loja  [%d créditos]" % SaveManager.get_credits()
	_shop_btn.disabled = true
	_build_settings_modal()
	_build_credits_modal()
	_build_history_modal()
	_start_btn.pressed.connect(_on_start_pressed)
	_credits_btn.pressed.connect(func(): _credits_overlay.visible = true)
	_settings_btn.pressed.connect(func(): _settings_overlay.visible = true)
	_history_btn.pressed.connect(_on_history_pressed)
	_quit_btn.pressed.connect(get_tree().quit)

func _on_start_pressed() -> void:
	World.start_game()

# ── Settings ───────────────────────────────────────────────────────────────────

func _apply_saved_settings() -> void:
	var s := SaveManager.load_settings()
	AudioServer.set_bus_volume_db(0, linear_to_db(s["master_volume"]))
	if AudioServer.get_bus_count() > 1:
		AudioServer.set_bus_volume_db(1, linear_to_db(s["music_volume"]))
	if AudioServer.get_bus_count() > 2:
		AudioServer.set_bus_volume_db(2, linear_to_db(s["sfx_volume"]))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if s["fullscreen"] \
				else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _build_settings_modal() -> void:
	var s := SaveManager.load_settings()
	var result := _make_modal("Configurações")
	_settings_overlay = result[0]
	var content: VBoxContainer = result[1]

	content.add_child(_section_label("Áudio"))
	_master_slider = _add_slider(content, "Master", s["master_volume"])
	_master_slider.value_changed.connect(func(v): AudioServer.set_bus_volume_db(0, linear_to_db(v)))
	_music_slider = _add_slider(content, "Música", s["music_volume"])
	_music_slider.value_changed.connect(func(v): if AudioServer.get_bus_count() > 1: AudioServer.set_bus_volume_db(1, linear_to_db(v)))
	_sfx_slider = _add_slider(content, "SFX", s["sfx_volume"])
	_sfx_slider.value_changed.connect(func(v): if AudioServer.get_bus_count() > 2: AudioServer.set_bus_volume_db(2, linear_to_db(v)))

	content.add_child(HSeparator.new())
	content.add_child(_section_label("Vídeo"))

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Tela Cheia"
	_fullscreen_check.button_pressed = s["fullscreen"]
	_fullscreen_check.toggled.connect(func(on): DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	content.add_child(_fullscreen_check)
	content.add_child(HSeparator.new())

	var save_btn := Button.new()
	save_btn.text = "Salvar e Fechar"
	save_btn.pressed.connect(_on_settings_save)
	content.add_child(save_btn)

func _on_settings_save() -> void:
	SaveManager.save_settings(
		_master_slider.value,
		_music_slider.value,
		_sfx_slider.value,
		_fullscreen_check.button_pressed
	)
	_settings_overlay.visible = false

# ── Credits ────────────────────────────────────────────────────────────────────

func _build_credits_modal() -> void:
	var result := _make_modal("Créditos")
	_credits_overlay = result[0]
	var content: VBoxContainer = result[1]

	var lbl := Label.new()
	lbl.text = "Desenvolvido para Game Jam\n\n[Nome do Time]"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(lbl)

	content.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(func(): _credits_overlay.visible = false)
	content.add_child(close_btn)

# ── History ────────────────────────────────────────────────────────────────────

func _build_history_modal() -> void:
	var result := _make_modal("Histórico de Runs")
	_history_overlay = result[0]
	_history_content = result[1]

func _on_history_pressed() -> void:
	_populate_history()
	_history_overlay.visible = true

func _populate_history() -> void:
	for child in _history_content.get_children():
		child.queue_free()

	var history := SaveManager.get_run_history()
	if history.is_empty():
		var lbl := Label.new()
		lbl.text = "Nenhuma run completada ainda."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_history_content.add_child(lbl)
	else:
		for run in history:
			_history_content.add_child(_make_run_entry(run))
			_history_content.add_child(HSeparator.new())

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(func(): _history_overlay.visible = false)
	_history_content.add_child(close_btn)

func _make_run_entry(run: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	var ts: int = int(run.get("timestamp", 0))
	var ts_str: String = Time.get_datetime_string_from_unix_time(ts) if ts > 0 else "—"
	var victory: bool = run.get("victory", false)

	var header := Label.new()
	header.text = "%s  —  %s" % [ts_str, "VITÓRIA" if victory else "DERROTA"]
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if victory else Color(1.0, 0.45, 0.45))
	box.add_child(header)

	var crew: Array = run.get("crew_names", [])
	var detail := Label.new()
	detail.text = "Turnos: %d  |  Inimigos: %d  |  Tripulação: %s" % [
		int(run.get("turns", 0)),
		int(run.get("enemies_defeated", 0)),
		", ".join(crew) if not crew.is_empty() else "—",
	]
	box.add_child(detail)

	var lost: Array = run.get("characters_lost", [])
	if not lost.is_empty():
		var lost_lbl := Label.new()
		lost_lbl.text = "Perdidos: %s" % ", ".join(lost)
		lost_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		box.add_child(lost_lbl)

	return box

# ── Modal helper ───────────────────────────────────────────────────────────────

func _make_modal(title: String) -> Array:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(title_lbl)
	outer.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	return [overlay, content]

func _add_slider(parent: VBoxContainer, label_text: String, initial: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(70, 0)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	parent.add_child(row)
	return slider

func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	return lbl

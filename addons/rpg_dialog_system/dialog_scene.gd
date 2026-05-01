extends CanvasLayer

@onready var large_sprite: TextureRect = $Root/LargeSprite
@onready var dialog_box: PanelContainer = $Root/DialogBox
@onready var name_label: Label = $Root/DialogBox/MarginContainer/VBoxContainer/NameLabel
@onready var face_sprite: TextureRect = $Root/DialogBox/MarginContainer/VBoxContainer/HBoxContainer/FaceSprite
@onready var dialog_text: RichTextLabel = $Root/DialogBox/MarginContainer/VBoxContainer/HBoxContainer/DialogText
@onready var back_btn: Button = $Root/DialogBox/MarginContainer/VBoxContainer/ButtonsRow/BackButton
@onready var next_btn: Button = $Root/DialogBox/MarginContainer/VBoxContainer/ButtonsRow/NextButton
@onready var skip_btn: Button = $Root/DialogBox/MarginContainer/VBoxContainer/ButtonsRow/SkipButton
@onready var typewriter_timer: Timer = $TypewriterTimer

var _is_typing: bool = false
var dialog_file = "res://addons/rpg_dialog_system/dialogs/example.json"


func _ready() -> void:
	dialog_box.visible = false
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.dialog_ended.connect(_on_dialog_ended)
	DialogManager.entry_changed.connect(_on_entry_changed)
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	next_btn.pressed.connect(_on_next_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	# Remove or gate this call when integrating into your game
	DialogManager.start_dialog(dialog_file)


func _input(event: InputEvent) -> void:
	if not DialogManager.is_active:
		return
	if event.is_action_pressed("ui_accept"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()


func _on_dialog_started() -> void:
	dialog_box.visible = true


func _on_dialog_ended() -> void:
	dialog_box.visible = false
	large_sprite.visible = false
	typewriter_timer.stop()


func _on_entry_changed(entry: Dictionary) -> void:
	back_btn.disabled = DialogManager._index <= 0
	_apply_entry(entry)


func _on_next_pressed() -> void:
	if _is_typing:
		_skip_typewriter()
	else:
		DialogManager.advance()


func _on_back_pressed() -> void:
	DialogManager.go_back()


func _on_skip_pressed() -> void:
	DialogManager.skip_dialog()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and DialogManager.is_active:
		_apply_entry(DialogManager._entries[DialogManager._index])


func _apply_entry(entry: Dictionary) -> void:
	var has_name: bool = entry.get("name", "") != ""
	name_label.visible = has_name
	name_label.text = tr(entry.get("name", "") as String)

	var face_path: String = entry.get("face_sprite", "")
	if face_path != "":
		face_sprite.texture = load(face_path)
		face_sprite.modulate.a = 1.0
	else:
		face_sprite.texture = null
		face_sprite.modulate.a = 0.0

	var large_path: String = entry.get("large_sprite", "")
	large_sprite.visible = large_path != ""
	if large_path != "":
		var tex: Texture2D = load(large_path)
		large_sprite.texture = tex
		if tex != null:
			large_sprite.size = tex.get_size()
		if entry.has("large_sprite_position"):
			var lp: Array = entry["large_sprite_position"]
			large_sprite.position = Vector2(float(lp[0]), float(lp[1]))

	_set_dialog_position(entry.get("position", "bottom"))

	dialog_text.text = tr(entry.get("text", ""))
	dialog_text.visible_characters = 0
	next_btn.text = "Next →"
	_is_typing = true
	typewriter_timer.start()


func _set_dialog_position(pos: String) -> void:
	match pos:
		"top":
			dialog_box.anchor_left = 0.0
			dialog_box.anchor_top = 0.0
			dialog_box.anchor_right = 1.0
			dialog_box.anchor_bottom = 0.0
			dialog_box.offset_left = 0.0
			dialog_box.offset_top = 10.0
			dialog_box.offset_right = 0.0
			dialog_box.offset_bottom = 150.0
			dialog_box.grow_vertical = 1
		"center":
			dialog_box.anchor_left = 0.0
			dialog_box.anchor_top = 0.5
			dialog_box.anchor_right = 1.0
			dialog_box.anchor_bottom = 0.5
			dialog_box.offset_left = 0.0
			dialog_box.offset_top = -75.0
			dialog_box.offset_right = 0.0
			dialog_box.offset_bottom = 75.0
			dialog_box.grow_vertical = 2
		_:  # bottom (default)
			dialog_box.anchor_left = 0.0
			dialog_box.anchor_top = 1.0
			dialog_box.anchor_right = 1.0
			dialog_box.anchor_bottom = 1.0
			dialog_box.offset_left = 0.0
			dialog_box.offset_top = -150.0
			dialog_box.offset_right = 0.0
			dialog_box.offset_bottom = 0.0
			dialog_box.grow_vertical = 0


func _on_typewriter_tick() -> void:
	dialog_text.visible_characters += 1
	if dialog_text.visible_characters >= dialog_text.get_total_character_count():
		_finish_typewriter()


func _skip_typewriter() -> void:
	dialog_text.visible_characters = -1
	_finish_typewriter()


func _finish_typewriter() -> void:
	typewriter_timer.stop()
	_is_typing = false
	next_btn.text = "Next →  ▼"

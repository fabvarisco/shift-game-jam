class_name CrewRosterPanel
extends PanelContainer

signal crew_selected(crew: CrewEntity)

const DICE_LABEL: Dictionary = {0: "D4", 1: "D6", 2: "D8", 3: "D10", 4: "D12", 5: "[X]"}
const CLASS_LABEL: Dictionary = {
	EntityCharacter.CrewClass.GENERALIST:        "Generalista",
	EntityCharacter.CrewClass.ENGINEER:          "Engenheiro",
	EntityCharacter.CrewClass.COMBAT_SPECIALIST: "Especialista de Combate",
	EntityCharacter.CrewClass.MEDIC:             "Médico",
	EntityCharacter.CrewClass.PILOT:             "Piloto",
}
const COLOR_SELECTED := Color(1.4, 1.4, 0.5)
const COLOR_NORMAL   := Color.WHITE

var _list_box: VBoxContainer
var _detail_box: VBoxContainer
var _selected_crew: CrewEntity = null
var _btn_group: ButtonGroup

func _ready() -> void:
	custom_minimum_size = Vector2(520, 320)
	_btn_group = ButtonGroup.new()

	var hbox := HBoxContainer.new()
	add_child(hbox)

	# Left — crew list
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(170, 0)
	hbox.add_child(list_panel)

	var list_vbox := VBoxContainer.new()
	list_panel.add_child(list_vbox)

	var list_title := Label.new()
	list_title.text = "TRIPULAÇÃO"
	list_title.add_theme_font_size_override("font_size", 13)
	list_vbox.add_child(list_title)
	list_vbox.add_child(HSeparator.new())

	_list_box = VBoxContainer.new()
	list_vbox.add_child(_list_box)

	# Right — detail view
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(scroll)

	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail_box)

	var placeholder := Label.new()
	placeholder.text = "Selecione um tripulante."
	placeholder.modulate = Color(0.6, 0.6, 0.6)
	_detail_box.add_child(placeholder)

func populate(crew_entities: Array[CrewEntity]) -> void:
	for child in _list_box.get_children():
		child.queue_free()
	_selected_crew = null

	for entity in crew_entities:
		if entity.data == null:
			continue
		var character: EntityCharacter = entity.data
		var btn := Button.new()
		btn.text = "%s\n%s" % [character.name, CLASS_LABEL.get(character.crew_class, "?")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		btn.button_group = _btn_group
		var e := entity
		btn.pressed.connect(func(): _on_crew_btn_pressed(e))
		_list_box.add_child(btn)

func _on_crew_btn_pressed(crew: CrewEntity) -> void:
	# Restore previous highlight
	if _selected_crew != null and is_instance_valid(_selected_crew):
		_set_crew_highlight(_selected_crew, false)

	_selected_crew = crew
	_set_crew_highlight(crew, true)
	_show_detail(crew.data)
	crew_selected.emit(crew)

func _set_crew_highlight(crew: CrewEntity, active: bool) -> void:
	var sprite := crew.get_node_or_null("Sprite") as AnimatedSprite3D
	if sprite:
		sprite.modulate = COLOR_SELECTED if active else COLOR_NORMAL

func _show_detail(character: EntityCharacter) -> void:
	for child in _detail_box.get_children():
		child.queue_free()

	var name_lbl := Label.new()
	name_lbl.text = character.name
	name_lbl.add_theme_font_size_override("font_size", 16)
	_detail_box.add_child(name_lbl)

	var class_lbl := Label.new()
	class_lbl.text = CLASS_LABEL.get(character.crew_class, "Generalista")
	class_lbl.modulate = Color(0.7, 0.85, 1.0)
	_detail_box.add_child(class_lbl)

	_detail_box.add_child(HSeparator.new())

	var core_title := Label.new()
	core_title.text = "CORE TRAITS"
	_detail_box.add_child(core_title)
	_add_trait_row("Mind", character.mind)
	_add_trait_row("Body", character.body)
	_add_trait_row("Soul", character.soul)

	if not character.focus_traits.is_empty():
		_detail_box.add_child(HSeparator.new())
		var focus_title := Label.new()
		focus_title.text = "FOCUS TRAITS"
		_detail_box.add_child(focus_title)
		for trait_name: String in character.focus_traits:
			_add_trait_row(trait_name, character.focus_traits[trait_name])

func _add_trait_row(trait_name: String, td: TraitData) -> void:
	var lbl := Label.new()
	var die_str: String = DICE_LABEL.get(int(td.die), "?")
	var kw := ", ".join(td.keywords) if not td.keywords.is_empty() else ""
	var db := "  (%s)" % ", ".join(td.drawbacks) if not td.drawbacks.is_empty() else ""
	lbl.text = "[%s]  %s   %s%s" % [die_str, trait_name, kw, db]
	if td.die == System.Dice.EXHAUSTED:
		lbl.modulate = Color(0.45, 0.45, 0.45)
	_detail_box.add_child(lbl)

extends CanvasLayer

const DICE_LABEL: Dictionary = {0: "D4", 1: "D6", 2: "D8", 3: "D10", 4: "D12", 5: "[X]"}

@onready var core_box: VBoxContainer = $Control/TraitsControl/TraitsPanel/HBoxContainer/CoreTraitsBox
@onready var focus_box: VBoxContainer = $Control/TraitsControl/TraitsPanel/HBoxContainer/FocusTraitsBox

func connect_to_master(master: Node) -> void:
	master.entity_selected.connect(_on_entity_selected)

func _on_entity_selected(entity: EntityCombat) -> void:
	_update_traits(entity.stats)

func _update_traits(stats: EntityCharacter) -> void:
	_clear(core_box)
	_clear(focus_box)

	_add_title(core_box, stats.name)
	_add_trait_row(core_box, "Mind", stats.mind)
	_add_trait_row(core_box, "Body", stats.body)
	_add_trait_row(core_box, "Soul", stats.soul)

	_add_title(focus_box, "Focus Traits")
	for trait_name: String in stats.focus_traits:
		_add_trait_row(focus_box, trait_name, stats.focus_traits[trait_name])

func _clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		child.queue_free()

func _add_title(box: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text.to_upper()
	box.add_child(lbl)

func _add_trait_row(box: VBoxContainer, label_name: String, data: TraitData) -> void:
	var lbl := Label.new()
	var die: String = DICE_LABEL.get(data.die, "?")
	var kw: String = ", ".join(data.keywords) if not data.keywords.is_empty() else "—"
	var db: String = " (%s)" % ", ".join(data.drawbacks) if not data.drawbacks.is_empty() else ""
	lbl.text = "[%s] %s  %s%s" % [die, label_name, kw, db]
	box.add_child(lbl)

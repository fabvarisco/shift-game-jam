class_name CrewActionPanel
extends PanelContainer

signal action_taken(crew: CrewEntity, action: String, trait_name: String)
signal cancelled()

const DICE_LABEL: Dictionary = {0: "D4", 1: "D6", 2: "D8", 3: "D10", 4: "D12", 5: "[X]"}

var _crew: CrewEntity = null
var _vbox: VBoxContainer

func _ready() -> void:
	custom_minimum_size = Vector2(280, 160)
	_vbox = VBoxContainer.new()
	add_child(_vbox)

func show_for(crew: CrewEntity) -> void:
	_crew = crew
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in _vbox.get_children():
		child.queue_free()

	if _crew == null or _crew.data == null:
		return

	var title := Label.new()
	title.text = "Ação: %s" % _crew.data.name
	_vbox.add_child(title)

	var world_traits: Dictionary = {}
	for trait_name: String in _crew.data.focus_traits:
		var td: TraitData = _crew.data.focus_traits[trait_name]
		if td.context == System.Context.WORLD:
			world_traits[trait_name] = td

	if not world_traits.is_empty():
		var header := Label.new()
		header.text = "Focus Traits (Mundo):"
		_vbox.add_child(header)
		for trait_name: String in world_traits:
			var td: TraitData = world_traits[trait_name]
			var btn := Button.new()
			var die_str: String = DICE_LABEL.get(int(td.die), "?")
			btn.text = "%s [%s]" % [trait_name, die_str]
			if td.die == System.Dice.EXHAUSTED:
				btn.disabled = true
			var tn := trait_name
			btn.pressed.connect(func(): _on_trait_selected(tn))
			_vbox.add_child(btn)

	_vbox.add_child(HSeparator.new())

	var rest_btn := Button.new()
	rest_btn.text = "Descansar (recuperar trait)"
	rest_btn.pressed.connect(_on_rest_selected)
	_vbox.add_child(rest_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.pressed.connect(func(): visible = false; cancelled.emit())
	_vbox.add_child(cancel_btn)

func _on_trait_selected(trait_name: String) -> void:
	visible = false
	action_taken.emit(_crew, "trait", trait_name)

func _on_rest_selected() -> void:
	visible = false
	action_taken.emit(_crew, "rest", "")

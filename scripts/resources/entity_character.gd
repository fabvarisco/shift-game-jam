class_name EntityCharacter
extends Resource

signal trait_exhausted(slot: String, trait_data: TraitData)

enum CrewClass { GENERALIST, ENGINEER, COMBAT_SPECIALIST, MEDIC, PILOT }

@export var name: String
@export var sprite: SpriteFrames
@export var crew_class: CrewClass = CrewClass.GENERALIST

@export_group("Core Traits")
@export var mind: TraitData = TraitData.new():
	set(value):
		_rewire(mind, value, "mind")
		mind = value
@export var body: TraitData = TraitData.new():
	set(value):
		_rewire(body, value, "body")
		body = value
@export var soul: TraitData = TraitData.new():
	set(value):
		_rewire(soul, value, "soul")
		soul = value
@export_group("")

@export var focus_traits: Dictionary[String, TraitData] = {}
@export var traits: Dictionary[String, TraitData] = {}

func take_damage(slot: String = "body") -> void:
	var td := get_trait(slot)
	if td:
		td.shift_down()

func get_trait(slot: String) -> TraitData:
	match slot:
		"mind": return mind
		"body": return body
		"soul": return soul
		_:
			if focus_traits.has(slot):
				return focus_traits[slot]
			return traits.get(slot, null)

func _rewire(old: TraitData, new_trait: TraitData, slot: String) -> void:
	if old != null and old.exhausted.is_connected(_on_trait_exhausted):
		old.exhausted.disconnect(_on_trait_exhausted)
	if new_trait != null:
		new_trait.exhausted.connect(_on_trait_exhausted.bind(slot))

func _on_trait_exhausted(td: TraitData, slot: String) -> void:
	trait_exhausted.emit(slot, td)

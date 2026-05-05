class_name EntityCharacter
extends Resource

enum CrewClass { GENERALIST, ENGINEER, COMBAT_SPECIALIST, MEDIC, PILOT }

@export var name: String
@export var sprite: SpriteFrames
@export var crew_class: CrewClass = CrewClass.GENERALIST

@export_group("Core Traits")
@export var mind: TraitData = TraitData.new()
@export var body: TraitData = TraitData.new()
@export var soul: TraitData = TraitData.new()
@export_group("")

@export var focus_traits: Dictionary[String, TraitData] = {}
@export var traits: Dictionary[String, TraitData] = {}

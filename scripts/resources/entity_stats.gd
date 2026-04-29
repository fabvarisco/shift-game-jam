class_name EntityStats
extends Resource

@export var name: String
@export var sprite: SpriteFrames

@export_group("Core Traits")
@export var mental: TraitData = TraitData.new()
@export var body: TraitData = TraitData.new()
@export var soul: TraitData = TraitData.new()
@export_group("")

@export var focus_traits: Dictionary[String, TraitData] = {}
@export var traits: Dictionary[String, TraitData] = {}

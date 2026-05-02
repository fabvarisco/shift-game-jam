class_name EnemyEntity
extends Resource

enum SpecialTrait {
	NONE,
	ARMORED,           ## +1 Trait to exhaust for defeat; die D8
	HEAVILY_ARMORED,   ## +2 Traits to exhaust; must be exhausted first; die D6
	SMALL_GROUP,       ## +1 action/turn, +1 Trait to exhaust; die D6
	LARGE_GROUP,       ## +2 actions/turn, +2 Traits to exhaust; die D8
}

@export var name: String
@export var sprite: SpriteFrames

@export_group("Combat Stats")
@export_range(1, 5) var power: int = 1
@export_range(1, 4) var scale: int = 1

@export_group("Traits")
@export var attitude: TraitData = TraitData.new()
@export var focus_traits: Dictionary[String, TraitData] = {}

@export_group("Special Traits")
@export var special_traits: Array[SpecialTrait] = []

## Actions the adversary can take per Adversary Phase
func get_actions_per_turn() -> int:
	var extra := 0
	for st: SpecialTrait in special_traits:
		match st:
			SpecialTrait.SMALL_GROUP: extra += 1
			SpecialTrait.LARGE_GROUP: extra += 2
	return power + extra

## Number of Traits that must be Exhausted to defeat this adversary
func get_traits_to_exhaust() -> int:
	var extra := 0
	for st: SpecialTrait in special_traits:
		match st:
			SpecialTrait.ARMORED:         extra += 1
			SpecialTrait.HEAVILY_ARMORED: extra += 2
			SpecialTrait.SMALL_GROUP:     extra += 1
			SpecialTrait.LARGE_GROUP:     extra += 2
	return power + extra

## Whether Heavily Armored trait must be exhausted before any other trait
func requires_heavily_armored_first() -> bool:
	return SpecialTrait.HEAVILY_ARMORED in special_traits

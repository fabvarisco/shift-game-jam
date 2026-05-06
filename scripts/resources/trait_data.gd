class_name TraitData
extends Resource

signal die_changed(trait_data: TraitData, new_die: System.Dice)
signal exhausted(trait_data: TraitData)

@export var context: System.Context = System.Context.COMBAT
@export var drawbacks: Array[String] = []
@export var keywords: Array[String] = []
@export var description: String
@export var die: System.Dice = System.Dice.D4:
	set(value):
		die = value
		die_changed.emit(self, value)
		if value == System.Dice.EXHAUSTED:
			exhausted.emit(self)

func shift_down() -> void:
	die = System.shift_down(die)

func is_exhausted() -> bool:
	return die == System.Dice.EXHAUSTED

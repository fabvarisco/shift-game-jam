extends Node
class_name System

enum Dice { D4, D6, D8, D10, D12, EXHAUSTED }

const DICES: Dictionary = {
    Dice.D4:       [1,2,3,4],
    Dice.D6:       [1,2,3,4,5,6],
    Dice.D8:       [1,2,3,4,5,6,7,8],
    Dice.D10:      [1,2,3,4,5,6,7,8,9,10],
    Dice.D12:      [1,2,3,4,5,6,7,8,9,10,11,12],
    Dice.EXHAUSTED:[0]
}

func get_dice(dice: Dice) -> Array[int]:
    return DICES.get(dice, [])

func roll(dice: Dice) -> int:
    var faces: Array[int] = get_dice(dice)
    return faces.pick_random()
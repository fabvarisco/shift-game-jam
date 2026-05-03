extends Node
class_name System

enum Dice { D4, D6, D8, D10, D12, EXHAUSTED }
enum Results { CRITICAL_SUCCESS, FAILURE, SUCCESS, CRITICAL_FAILURE, MITIGATED_SUCCESS }
enum Context { COMBAT, WORLD }


const DICES: Dictionary = {
    Dice.D4:       [1,2,3,4],
    Dice.D6:       [1,2,3,4,5,6],
    Dice.D8:       [1,2,3,4,5,6,7,8],
    Dice.D10:      [1,2,3,4,5,6,7,8,9,10],
    Dice.D12:      [1,2,3,4,5,6,7,8,9,10,11,12],
    Dice.EXHAUSTED:[0]
}

const RESULTS: Dictionary ={
    Results.CRITICAL_SUCCESS: "CRITICAL_SUCCESS",
    Results.SUCCESS: "SUCCESS",
    Results.FAILURE: "FAILURE",
    Results.CRITICAL_FAILURE: "CRITICAL_FAILURE",
    Results.MITIGATED_SUCCESS: "MITIGATED_SUCCESS"
}


func get_dice(dice: Dice) -> Array[int]:
    return DICES.get(dice, [])

func roll(dice: Dice) -> int:
    var faces: Array[int] = get_dice(dice)
    return faces.pick_random()

static func shift_down(dice: Dice) -> Dice:
    return mini(dice + 1, Dice.EXHAUSTED) as Dice

static func resolve(rolls: Array[int], dice_used: Array[Dice]) -> Results:
    var has_low := false
    var has_max := false
    for i in rolls.size():
        if rolls[i] == 1:
            return Results.CRITICAL_SUCCESS
        if rolls[i] <= 3:
            has_low = true
        var faces: Array = DICES[dice_used[i]]
        if rolls[i] == faces.max():
            has_max = true
    if has_low and not has_max:
        return Results.SUCCESS
    if has_low and has_max:
        return Results.MITIGATED_SUCCESS
    if not has_low and has_max:
        return Results.CRITICAL_FAILURE
    return Results.FAILURE
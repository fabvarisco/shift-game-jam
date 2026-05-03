class_name CombatState
extends RefCounted

var dice_state: Dictionary = {}  # String -> System.Dice

static func from_character(ch: EntityCharacter) -> CombatState:
	var s := CombatState.new()
	s.dice_state["Mind"] = ch.mind.die
	s.dice_state["Body"] = ch.body.die
	s.dice_state["Soul"] = ch.soul.die
	for k: String in ch.focus_traits:
		if ch.focus_traits[k].context == System.Context.COMBAT:
			s.dice_state[k] = ch.focus_traits[k].die
	return s

static func from_enemy(e: EnemyEntity) -> CombatState:
	var s := CombatState.new()
	s.dice_state["Attitude"] = e.attitude.die
	for k: String in e.focus_traits:
		if e.focus_traits[k].context == System.Context.COMBAT:
			s.dice_state[k] = e.focus_traits[k].die
	return s

func shift_down(trait_name: String) -> bool:
	if not dice_state.has(trait_name):
		return false
	dice_state[trait_name] = System.shift_down(dice_state[trait_name])
	return dice_state[trait_name] == System.Dice.EXHAUSTED

func get_available() -> Array[String]:
	var result: Array[String] = []
	for k: String in dice_state:
		if dice_state[k] != System.Dice.EXHAUSTED:
			result.append(k)
	return result

func get_core_traits() -> Array[String]:
	var cores := ["Mind", "Body", "Soul"]
	var result: Array[String] = []
	for c in cores:
		if dice_state.has(c) and dice_state[c] != System.Dice.EXHAUSTED:
			result.append(c)
	return result

func get_focus_traits() -> Array[String]:
	var cores := ["Mind", "Body", "Soul", "Attitude"]
	var result: Array[String] = []
	for k: String in dice_state:
		if k not in cores and dice_state[k] != System.Dice.EXHAUSTED:
			result.append(k)
	return result

func exhausted_count() -> int:
	var count := 0
	for k: String in dice_state:
		if dice_state[k] == System.Dice.EXHAUSTED:
			count += 1
	return count

func is_core_exhausted() -> bool:
	for c in ["Mind", "Body", "Soul", "Attitude"]:
		if dice_state.has(c) and dice_state[c] == System.Dice.EXHAUSTED:
			return true
	return false

func get_strongest_available() -> String:
	var best := ""
	var best_val := -1
	for k: String in dice_state:
		var v: int = dice_state[k]
		if v != System.Dice.EXHAUSTED and v > best_val:
			best_val = v
			best = k
	return best

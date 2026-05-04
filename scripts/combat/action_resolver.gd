class_name ActionResolver

static func roll_action(
	attacker_state: CombatState,
	core_trait: String,
	focus_trait: String
) -> Dictionary:
	var dice_used: Array[System.Dice] = []
	var trait_names: Array[String] = []

	dice_used.append(attacker_state.dice_state.get(core_trait, System.Dice.EXHAUSTED))
	trait_names.append(core_trait)

	if focus_trait != "" and attacker_state.dice_state.has(focus_trait):
		dice_used.append(attacker_state.dice_state.get(focus_trait, System.Dice.EXHAUSTED))
		trait_names.append(focus_trait)

	var rolls: Array[int] = []
	for d in dice_used:
		var faces: Array = System.DICES[d]
		rolls.append(faces.pick_random() if not faces.is_empty() else 0)

	var result: System.Results = System.resolve(rolls, dice_used)
	var shifted_trait := ""

	match result:
		System.Results.MITIGATED_SUCCESS:
			for i in rolls.size():
				var faces: Array = System.DICES[dice_used[i]]
				if rolls[i] == faces.max():
					attacker_state.shift_down(trait_names[i])
					shifted_trait = trait_names[i]
					break
		System.Results.CRITICAL_FAILURE:
			attacker_state.shift_down(core_trait)
			shifted_trait = core_trait

	return {
		"result": result,
		"rolls": rolls,
		"dice_used": dice_used,
		"trait_names": trait_names,
		"shifted_attacker_trait": shifted_trait,
	}

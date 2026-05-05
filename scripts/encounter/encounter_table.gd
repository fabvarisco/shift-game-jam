class_name EncounterTable
extends RefCounted

static func roll(min_events: int = 1, max_events: int = 2) -> Array:
	var table := _build_table()
	if table.is_empty():
		return []
	var count := randi_range(min_events, max_events)
	var total_weight := 0
	for e: EncounterEvent in table:
		total_weight += e.weight
	var result: Array = []
	for _i in count:
		var r := randi() % total_weight
		var cumulative := 0
		for e: EncounterEvent in table:
			cumulative += e.weight
			if r < cumulative:
				result.append(e)
				break
	return result

static func _build_table() -> Array[EncounterEvent]:
	var table: Array[EncounterEvent] = []

	var e1 := EncounterEvent.new()
	e1.type = EncounterEvent.EventType.COMBAT
	e1.title = "Ataque Inimigo"
	e1.description = "Um esquadrão inimigo abre fogo na nave!"
	e1.weight = 30
	var ep1: Array = [load("res://resources/characters/enemy_grunt.tres")]
	e1.enemy_party = ep1
	table.append(e1)

	var e2 := EncounterEvent.new()
	e2.type = EncounterEvent.EventType.COMBAT
	e2.title = "Patrulha Inimiga"
	e2.description = "Uma patrulha de guardas bloqueia o caminho!"
	e2.weight = 20
	var ep2: Array = [load("res://resources/characters/enemy_guard.tres")]
	e2.enemy_party = ep2
	table.append(e2)

	var e3 := EncounterEvent.new()
	e3.type = EncounterEvent.EventType.HAZARD
	e3.title = "Chuva de Meteoros"
	e3.description = "Fragmentos de rocha espacial atingem o casco da nave!"
	e3.weight = 25
	e3.difficulty = 2
	e3.challenge_trait = "body"
	table.append(e3)

	var e4 := EncounterEvent.new()
	e4.type = EncounterEvent.EventType.HAZARD
	e4.title = "Falha de Sistema"
	e4.description = "Os sistemas da nave entram em colapso. O engenheiro precisa agir!"
	e4.weight = 15
	e4.difficulty = 1
	e4.challenge_trait = "mind"
	table.append(e4)

	var e5 := EncounterEvent.new()
	e5.type = EncounterEvent.EventType.SOCIAL
	e5.title = "Contato Mercenário"
	e5.description = "Um mercenário entra em contato oferecendo serviços... por um preço."
	e5.weight = 10
	e5.difficulty = 1
	e5.challenge_trait = "mind"
	table.append(e5)

	return table

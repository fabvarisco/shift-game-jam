class_name EncounterEvent
extends Resource

enum EventType { COMBAT, HAZARD, SOCIAL }

@export var type: EventType = EventType.HAZARD
@export var title: String = ""
@export var description: String = ""
@export var difficulty: int = 1
@export var weight: int = 10
@export var enemy_party: Array = []
@export var challenge_trait: String = "body"

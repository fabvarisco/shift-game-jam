extends Node3D

const DialogScene = preload("res://addons/rpg_dialog_system/dialog_scene.tscn")

func _ready() -> void:
	var dialog = DialogScene.instantiate()
	dialog.dialog_file = "res://addons/rpg_dialog_system/dialogs/example.json"
	add_child(dialog)
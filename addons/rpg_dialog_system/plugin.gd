@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("DialogManager", "res://addons/rpg_dialog_system/dialog_manager.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("DialogManager")

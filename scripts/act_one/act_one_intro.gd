extends Node3D

const DialogScene = preload("res://addons/rpg_dialog_system/dialog_scene.tscn")

@onready var animation_player = $AnimationPlayer


var dialog

func _ready() -> void:
	_start_cutscene()


func _start_cutscene() -> void:
	dialog = DialogScene.instantiate()
	dialog.dialog_file = "res://addons/rpg_dialog_system/dialogs/example.json"
	add_child(dialog)


func fade_out_canvas() -> void:
	animation_player.play("fade_out")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if _anim_name == "fade_out":
		animation_player.play("camera_start")
	if _anim_name == "camera_start":
		animation_player.play("vera_wakeup")
	if _anim_name == "vera_wakeup":
		#call vera wakeup dialog
		#when vera wakeup dialog end play wren_get_arm
		pass
	if _anim_name == "wren_get_arm":
		#call wren_get_arm dialog
		#when dialog end play wren_run 
		pass
	if _anim_name == "wren_run":
		#call vera angry dialog
		#and then end the cutscene and start gameplay
		pass

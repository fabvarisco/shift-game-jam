extends Node3D

const DialogScene = preload("res://addons/rpg_dialog_system/dialog_scene.tscn")

@onready var animation_player = $AnimationPlayer

var _dialog_instance: Node = null

func _ready() -> void:
	animation_player.play("fade_out")

func _show_dialog(path: String, on_end: Callable) -> void:
	if _dialog_instance:
		_dialog_instance.queue_free()
	_dialog_instance = DialogScene.instantiate()
	_dialog_instance.dialog_file = path
	add_child(_dialog_instance)
	DialogManager.dialog_ended.connect(on_end, CONNECT_ONE_SHOT)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if _anim_name == "fade_out":
		animation_player.play("camera_start")
	elif _anim_name == "camera_start":
		animation_player.play("vera_wakeup")
	elif _anim_name == "vera_wakeup":
		_show_dialog("res://dialogs/act_one/vera_wakeup.json", func():
			animation_player.play("wren_get_arm")
		)
	elif _anim_name == "wren_get_arm":
		_show_dialog("res://dialogs/act_one/wren_get_arm.json", func():
			animation_player.play("wren_run")
		)
	elif _anim_name == "wren_run":
		_show_dialog("res://dialogs/act_one/vera_angry.json", func():
			pass  # TODO: transição para gameplay quando cena estiver pronta
		)

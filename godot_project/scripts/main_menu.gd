extends Control

@onready var start_button = $StartButton
@onready var settings_button = $SettingsButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

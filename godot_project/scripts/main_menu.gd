extends Control

@onready var background: ColorRect = $Background
@onready var title: Label = $Title
@onready var start_button: Button = $StartButton
@onready var settings_button: Button = $SettingsButton
@onready var star_icon: TextureRect = $StarIcon

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	start_button.mouse_entered.connect(func(): _animate_button_hover(start_button, true))
	start_button.mouse_exited.connect(func(): _animate_button_hover(start_button, false))
	settings_button.mouse_entered.connect(func(): _animate_button_hover(settings_button, true))
	settings_button.mouse_exited.connect(func(): _animate_button_hover(settings_button, false))
	ThemeManager.theme_changed.connect(_apply_theme)
	_apply_theme(ThemeManager.current_theme)
	_play_intro()

func _apply_theme(_theme_id: String) -> void:
	var palette: Dictionary = ThemeManager.get_palette()
	background.color = palette["background"]
	title.add_theme_color_override("font_color", palette["text"])
	start_button.add_theme_color_override("font_color", palette["text"])
	settings_button.add_theme_color_override("font_color", palette["text"])
	star_icon.modulate = palette["accent"] if ThemeManager.current_theme == ThemeManager.THEME_MEDICAL else Color.WHITE

func _play_intro() -> void:
	title.modulate.a = 0.0
	start_button.modulate.a = 0.0
	settings_button.modulate.a = 0.0
	star_icon.modulate.a = 0.0
	star_icon.rotation = -0.25

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 0.5)
	tween.tween_property(star_icon, "modulate:a", 1.0, 0.7)
	tween.tween_property(star_icon, "rotation", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.4).set_delay(0.2)
	tween.tween_property(settings_button, "modulate:a", 1.0, 0.4).set_delay(0.32)

func _animate_button_hover(button: Button, hovered: bool) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.06, 1.06) if hovered else Vector2.ONE, 0.12)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

extends Control

const THEME_ORDER := ["classic", "medical_chart"]

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var panel: PanelContainer = $Card
@onready var volume_label: Label = $Card/VBoxContainer/Padding/VolumeLabel
@onready var theme_option: OptionButton = $Card/VBoxContainer/ThemeRow/ThemeOption
@onready var theme_description: Label = $Card/VBoxContainer/ThemeDescription
@onready var back_button: Button = $BackButton
@onready var accent_line: ColorRect = $AccentLine
@onready var hatch_overlay: ColorRect = $EtchingOverlay

var _is_syncing_option := false

func _ready() -> void:
	theme_option.focus_mode = Control.FOCUS_NONE
	_populate_theme_options()
	ThemeManager.theme_changed.connect(_apply_theme)
	theme_option.item_selected.connect(_on_theme_selected)
	back_button.mouse_entered.connect(_on_back_hovered)
	back_button.mouse_exited.connect(_on_back_unhovered)
	_apply_theme(ThemeManager.current_theme)
	_play_intro_animation()

func _populate_theme_options() -> void:
	theme_option.clear()
	var labels: Dictionary = ThemeManager.get_theme_labels()
	for theme_id in THEME_ORDER:
		if labels.has(theme_id):
			theme_option.add_item(labels[theme_id])
			theme_option.set_item_metadata(theme_option.item_count - 1, theme_id)
	_select_theme_option(ThemeManager.current_theme)

func _select_theme_option(theme_id: String) -> void:
	_is_syncing_option = true
	for i in range(theme_option.item_count):
		if str(theme_option.get_item_metadata(i)) == theme_id:
			theme_option.select(i)
			break
	_is_syncing_option = false

func _on_theme_selected(index: int) -> void:
	if _is_syncing_option:
		return
	var selected_theme = str(theme_option.get_item_metadata(index))
	ThemeManager.set_theme(selected_theme)

func _apply_theme(theme_id: String) -> void:
	_select_theme_option(theme_id)
	var palette: Dictionary = ThemeManager.get_palette()
	background.color = palette["background"]
	accent_line.color = palette["line"]
	title_label.add_theme_color_override("font_color", palette["text"])
	subtitle_label.add_theme_color_override("font_color", palette["muted_text"])
	volume_label.add_theme_color_override("font_color", palette["text"])
	theme_description.add_theme_color_override("font_color", palette["muted_text"])
	back_button.add_theme_color_override("font_color", palette["text"])

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = palette["surface"]
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = palette["line"]
	panel.add_theme_stylebox_override("panel", panel_style)

	if theme_id == ThemeManager.THEME_MEDICAL:
		theme_description.text = "Clinical sketch style with restrained red annotations and instructional spacing."
		hatch_overlay.visible = true
	else:
		theme_description.text = "Original high-contrast style."
		hatch_overlay.visible = false

func _play_intro_animation() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	panel.modulate.a = 0.0
	back_button.modulate.a = 0.0
	panel.position.y += 24.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.45)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.55).set_delay(0.1)
	tween.tween_property(panel, "modulate:a", 1.0, 0.55).set_delay(0.15)
	tween.tween_property(panel, "position:y", panel.position.y - 24.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.15)
	tween.tween_property(back_button, "modulate:a", 1.0, 0.5).set_delay(0.25)

func _on_back_hovered() -> void:
	var tween = create_tween()
	tween.tween_property(back_button, "scale", Vector2(1.04, 1.04), 0.15)

func _on_back_unhovered() -> void:
	var tween = create_tween()
	tween.tween_property(back_button, "scale", Vector2.ONE, 0.15)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

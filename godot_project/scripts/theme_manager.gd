extends Node

signal theme_changed(theme_id: String)

const SAVE_PATH := "user://settings.cfg"
const SECTION := "display"
const KEY_THEME := "theme"

const THEME_CLASSIC := "classic"
const THEME_MEDICAL := "medical_chart"

const THEME_LABELS := {
	THEME_CLASSIC: "Classic Monochrome",
	THEME_MEDICAL: "Medical Chart / Anatomical Etching"
}

const PALETTES := {
	THEME_CLASSIC: {
		"background": Color(1, 1, 1, 1),
		"surface": Color(1, 1, 1, 1),
		"line": Color(0, 0, 0, 1),
		"text": Color(0, 0, 0, 1),
		"muted_text": Color(0.15, 0.15, 0.15, 1),
		"accent": Color(0.17, 0.03, 0.03, 1),
		"blood": Color(0.4, 0.01, 0.01, 1)
	},
	THEME_MEDICAL: {
		"background": Color("f8f5ef"),
		"surface": Color("fffdf8"),
		"line": Color("312f2c"),
		"text": Color("1f1c19"),
		"muted_text": Color("625d56"),
		"accent": Color("871f1f"),
		"blood": Color("8f1218")
	}
}

var current_theme: String = THEME_CLASSIC

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		var saved_theme = str(config.get_value(SECTION, KEY_THEME, THEME_CLASSIC))
		if PALETTES.has(saved_theme):
			current_theme = saved_theme

func set_theme(theme_id: String) -> void:
	if not PALETTES.has(theme_id):
		return
	if current_theme == theme_id:
		return
	current_theme = theme_id
	_save_settings()
	theme_changed.emit(current_theme)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, KEY_THEME, current_theme)
	config.save(SAVE_PATH)

func get_palette() -> Dictionary:
	return PALETTES.get(current_theme, PALETTES[THEME_CLASSIC])

func get_theme_labels() -> Dictionary:
	return THEME_LABELS

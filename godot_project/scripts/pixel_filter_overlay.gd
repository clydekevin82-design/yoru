extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	ThemeManager.theme_changed.connect(_apply_theme)
	_apply_theme(ThemeManager.current_theme)

func _apply_theme(_theme_id: String) -> void:
	var mat := rect.material as ShaderMaterial
	if mat == null:
		return
	if ThemeManager.is_medical():
		mat.set_shader_parameter("sketch_strength", 0.92)
		mat.set_shader_parameter("pixel_size", 1.0)
		mat.set_shader_parameter("ink_color", Color("2a2521"))
		mat.set_shader_parameter("paper_tint", Color("f8f5ef"))
	else:
		mat.set_shader_parameter("sketch_strength", 0.0)
		mat.set_shader_parameter("pixel_size", 2.0)
		mat.set_shader_parameter("ink_color", Color("2a2521"))
		mat.set_shader_parameter("paper_tint", Color.WHITE)

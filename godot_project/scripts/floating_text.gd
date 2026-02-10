extends Label

func _ready():
	# Setup animation
	var tween = create_tween().set_parallel(true)
	
	# Float up - increased distance for 1080p (100 -> 200)
	tween.tween_property(self, "position", position - Vector2(0, 200), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# Scale up slightly on spawn
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Destroy after animation
	tween.chain().tween_callback(queue_free)

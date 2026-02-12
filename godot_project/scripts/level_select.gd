extends Control

# UI References
@onready var entity = $HBox/LeftColumn/EntityContainer/Entity
@onready var score_label = $HBox/LeftColumn/ScoreLabel
@onready var cps_label = $HBox/LeftColumn/CPSLabel
@onready var news_label = $HBox/CenterColumn/HeaderContainer/NewsPanel/NewsLabel
@onready var visuals_container = $HBox/CenterColumn/ScrollContainer/VisualsContainer
@onready var store_container = $HBox/RightColumn/StoreList/StoreContainer
@onready var click_particles = $ClickParticles
@onready var buffs_container = $DashboardPanel/VBox/BuffsContainer
@onready var dashboard_panel = $DashboardPanel
@onready var blood_fill = $HBox/LeftColumn/BloodFill
@onready var camera = $Camera2D

# Game State
var essence: float = 0.0
var cps: float = 0.0
var total_clicks: int = 0
const BLOOD_FILL_CAP = 90000.0

# Visuals
var shake_intensity: float = 0.0

var achievements = {
	"first_click": false,
	"first_buy": false,
	"dedicated_clicker": false, # 1000 clicks
	"carpometacarpal_boss": false, # 10000 clicks
	"hoarder": false, # Buy 10 of an item
	"architect_of_doom": false # Buy 50 items total
}
const SAVE_PATH = "user://save_game.dat"

# Behavior Tracking
var click_timestamps: Array[float] = []
var spam_warned: bool = false
var last_click_time: float = 0.0
var stopped_clicking_warned: bool = false
var random_message_timer: float = 0.0

const SPAM_THRESHOLD_CPS = 8.0
const STOP_IDLE_TIME = 2.0

# Reactive Messages
const RANDOM_MESSAGES = [
	"Ignore It",
	"Keep Clicking",
	"It’s Fine",
	"Don’t Look Away",
	"It Sees You",
	"Don't Stop",
	"Feeding Time",
	"Just Ignore The Noise"
]
const SPAM_MESSAGE = "You don’t have to keep doing that."
const STOP_MESSAGE = "…why did you stop?"

# Item Definitions
# Item Definitions
var items = {
	"cursed_finger": {
		"name": "Cursed Finger",
		"base_cost": 15,
		"base_cps": 0.5,
		"desc": "It twitches on its own.",
		"count": 0
	},
	"ritual_dagger": {
		"name": "Ritual Dagger",
		"base_cost": 100,
		"base_cps": 2.0,
		"desc": "Sharpened on bone.",
		"count": 0
	},
	"blood_vial": {
		"name": "Blood Vial",
		"base_cost": 500,
		"base_cps": 8.0,
		"desc": "Iron rich.",
		"count": 0
	},
	"lost_soul": {
		"name": "Lost Soul",
		"base_cost": 2000,
		"base_cps": 25.0,
		"desc": "It whispers secrets.",
		"count": 0
	},
	"sacrificial_lamb": {
		"name": "Sacrificial Lamb",
		"base_cost": 8000,
		"base_cps": 80.0,
		"desc": "A necessary loss.",
		"count": 0
	},
	"haunted_mirror": {
		"name": "Haunted Mirror",
		"base_cost": 40000,
		"base_cps": 250.0,
		"desc": "Don't look too long.",
		"count": 0
	},
	"demon_contract": {
		"name": "Demon Contract",
		"base_cost": 200000,
		"base_cps": 1000.0,
		"desc": "Signed in blood.",
		"count": 0
	},
	"hell_gate": {
		"name": "Hell Gate",
		"base_cost": 1500000,
		"base_cps": 5000.0,
		"desc": "It's getting warm.",
		"count": 0
	},
	"shattered_reality": {
		"name": "Shattered Reality",
		"base_cost": 20000000,
		"base_cps": 35000.0,
		"desc": "Physics is a suggestion.",
		"count": 0
	},
	"eldritch_god": {
		"name": "Eldritch God",
		"base_cost": 500000000,
		"base_cps": 200000.0,
		"desc": "It watches you.",
		"count": 0
	}
}

# News Ticker Content
var news_strings = [
	"Local man stares into abyss, abyss blinks.",
	"Strange hum reported from city sewers.",
	"Cookie sales plummet, essence trading rises.",
	"Grandma says 'it's too dark in here'.",
	"Scientists baffled by sudden loss of color.",
	"The blob demands more clicks.",
	"Remember to hydrate with void juice."
]

const FloatingTextScript = preload("res://scripts/floating_text.gd")

func _ready():
	_load_game()
	_update_ui()
	_populate_store()
	_start_news_ticker()
	
	# Animate entity entrance
	entity.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(entity, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _process(delta):
	# Passive Income
	if cps > 0:
		essence += cps * delta
		_update_ui()
	
	_handle_behavior(delta)
	
	# Shake Decay
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, delta * 10.0)
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	
	# Debug: Add essence
	if Input.is_physical_key_pressed(KEY_M):
		essence += 100000 * delta
		_update_ui()


func _handle_behavior(delta):
	var time = Time.get_ticks_msec() / 1000.0
	
	# Clean up old timestamps (older than 1 sec)
	while click_timestamps.size() > 0 and time - click_timestamps[0] > 1.0:
		click_timestamps.pop_front()
	
	var current_player_cps = click_timestamps.size()
	
	# Check Spamming
	if current_player_cps > SPAM_THRESHOLD_CPS:
		if not spam_warned:
			_spawn_popup_message(SPAM_MESSAGE, _get_random_screen_pos())
			spam_warned = true
			stopped_clicking_warned = false
	elif current_player_cps < 2:
		spam_warned = false
	
	# Check Stopping
	if not stopped_clicking_warned and spam_warned:
		if time - last_click_time > STOP_IDLE_TIME:
			_spawn_popup_message(STOP_MESSAGE, _get_random_screen_pos())
			stopped_clicking_warned = true
			spam_warned = false
			
	# Random Messages
	random_message_timer += delta
	if random_message_timer > 10.0:
		if randf() < 0.3:
			_spawn_popup_message(RANDOM_MESSAGES.pick_random(), _get_random_screen_pos(), true)
		random_message_timer = 0.0

func _get_random_screen_pos():
	var screen_size = get_viewport_rect().size
	return Vector2(randf_range(200, screen_size.x - 200), randf_range(200, screen_size.y - 200))

func _spawn_popup_message(text, pos, is_subtle = false):
	var label = Label.new()
	label.text = text
	label.theme_type_variation = "HeaderLarge"
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_size_override("font_size", 32 if is_subtle else 48)
	
	add_child(label)
	label.global_position = pos
	
	# Animation
	label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.0 if is_subtle else 0.5)
	tween.tween_interval(2.0 if is_subtle else 3.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _update_ui():
	# Update Labels
	score_label.text = "%d ESSENCE" % int(essence)
	cps_label.text = "per second: %.1f" % cps
	
	# Update Blood Fill
	if blood_fill:
		var fill_ratio = clamp(essence / BLOOD_FILL_CAP, 0.0, 1.0)
		blood_fill.target_fill_percent = fill_ratio
		
		# Update max height dynamically in case of resize (or do it in _process, but this is fine for now)
		# The entity is inside EntityContainer which is centered.
		# Lets ensure we know where the bottom of the entity is relative to the BloodFill control.
		# EntityContainer is centered, Entity is inside it.
		# We want the fluid to stop at the bottom of the entity.
		
		# Use global coordinates to be safe
		var entity_bottom_y = entity.global_position.y + entity.size.y * entity.scale.y
		var col_bottom_y = blood_fill.global_position.y + blood_fill.size.y
		
		# Distance from bottom of screen (fluid bottom) to bottom of entity.
		var max_h = col_bottom_y - entity_bottom_y
		blood_fill.max_height_pixels = max_h

	
	# Update Store Buttons
	# Update Store Buttons
	for child in store_container.get_children():
		if child is Button:
			var item_id = child.get_meta("item_id")
			var cost = _get_item_cost(item_id)
			child.disabled = essence < cost
			child.text = "%s - %d" % [items[item_id]["name"], cost]
			
			# Unlock Logic
			if not child.visible:
				if essence >= items[item_id]["base_cost"] * 0.6: # Reveal at 60% of base cost
					child.visible = true
					_shake_screen(2.0)
					_spawn_popup_message("New Item Unlocked", _get_random_screen_pos(), true)

func _shake_screen(intensity):
	shake_intensity = max(shake_intensity, intensity)

func _get_item_cost(item_id):
	var item = items[item_id]
	return int(item["base_cost"] * pow(1.15, item["count"]))

func _populate_store():
	for child in store_container.get_children():
		child.queue_free()
	for item_id in items:
		var btn = Button.new()
		btn.text = items[item_id]["name"]
		btn.tooltip_text = items[item_id]["desc"] + "\n+" + str(items[item_id]["base_cps"]) + " cps"
		btn.set_meta("item_id", item_id)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_buy_item.bind(item_id))
		btn.custom_minimum_size = Vector2(0, 70)
		btn.add_theme_font_size_override("font_size", 24)
		btn.visible = false # Hidden by default
		store_container.add_child(btn)

func _on_buy_item(item_id):
	var cost = _get_item_cost(item_id)
	if essence >= cost:
		essence -= cost
		items[item_id]["count"] += 1
		cps += items[item_id]["base_cps"]
		_update_ui()
		_add_visual_icon(item_id)
		_check_achievements()
		_trigger_achievement("first_buy")

func _click_entity():
	essence += 1
	total_clicks += 1
	_update_ui()
	_check_achievements()
	_trigger_achievement("first_click")
	
	# Time
	var time = Time.get_ticks_msec() / 1000.0
	click_timestamps.append(time)
	last_click_time = time
	
	# Visuals
	var tween = create_tween()
	tween.tween_property(entity, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(entity, "scale", Vector2(1.0, 1.0), 0.1)
	
	_spawn_floating_text("+1", get_global_mouse_position())
	click_particles.global_position = get_global_mouse_position()
	click_particles.emitting = true

func _on_entity_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_entity()

# Achievements & Tiles
func _trigger_achievement(id):
	if not achievements.has(id) or achievements[id]:
		return
	achievements[id] = true
	_spawn_achievement_tile(id)
	_spawn_popup_message("Unlocked: " + id.replace("_", " ").capitalize(), _get_random_screen_pos(), true)

func _spawn_achievement_tile(id):
	var tile = ColorRect.new()
	tile.custom_minimum_size = Vector2(40, 40)
	tile.color = Color(0, 0, 0, 1) # Black tile
	tile.tooltip_text = "Achievement: " + id.replace("_", " ").capitalize()
	buffs_container.add_child(tile)
	
	# Animation
	tile.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(tile, "modulate:a", 1.0, 1.0)

func _check_achievements():
	# Click achievements
	if total_clicks >= 1000: _trigger_achievement("dedicated_clicker")
	if total_clicks >= 10000: _trigger_achievement("carpometacarpal_boss")
	
	# Item achievements
	var total_items = 0
	for id in items:
		var count = items[id]["count"]
		total_items += count
		if count >= 10: _trigger_achievement("hoarder")
	
	if total_items >= 50: _trigger_achievement("architect_of_doom")
	
# Store Logic & Visuals
func _add_visual_icon(item_id):
	var row = visuals_container.get_node_or_null("Row_" + item_id)
	if not row:
		row = HBoxContainer.new()
		row.name = "Row_" + item_id
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		visuals_container.add_child(row)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.color = Color(0, 0, 0, 0.8)
	row.add_child(icon)

# --- Standard UI stuff ---
func _spawn_floating_text(text_value, pos):
	var label = Label.new()
	label.text = text_value
	label.theme_type_variation = "HeaderLarge"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.set_script(FloatingTextScript)
	add_child(label)
	label.global_position = pos

func _start_news_ticker():
	_cycle_news()
	var timer = Timer.new()
	timer.wait_time = 8.0
	timer.autostart = true
	timer.timeout.connect(_cycle_news)
	add_child(timer)

func _cycle_news():
	var text = news_strings.pick_random()
	news_label.text = ""
	var tween = create_tween()
	tween.tween_property(news_label, "text", text, 2.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(func(): pass )

# --- Top Menu Buttons ---
func _on_dashboard_pressed():
	dashboard_panel.visible = !dashboard_panel.visible

func _on_dashboard_close_pressed():
	dashboard_panel.visible = false

func _on_save_pressed():
	_save_game()
	_spawn_popup_message("Game Saved", _get_random_screen_pos(), true)

func _on_export_pressed():
	var save_dict = _create_save_dict()
	DisplayServer.clipboard_set(JSON.stringify(save_dict))
	_spawn_popup_message("Save copied to clipboard", _get_random_screen_pos(), true)

func _on_support_pressed():
	OS.shell_open("https://www.buymeacoffee.com/bokiiedev")
	_spawn_popup_message("Opening Browser...", _get_random_screen_pos(), true)

# --- Save System ---
func _create_save_dict():
	return {
		"essence": essence,
		"total_clicks": total_clicks,
		"items": items,
		"achievements": achievements
	}

func _save_game():
	var save_game = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(_create_save_dict())
	save_game.store_line(json_string)

func _load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var save_game = FileAccess.open(SAVE_PATH, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			continue
		var node_data = json.get_data()
		
		# Restore Data
		if node_data.has("essence"): essence = node_data["essence"]
		if node_data.has("total_clicks"): total_clicks = int(node_data["total_clicks"])
		if node_data.has("achievements"):
			achievements = node_data["achievements"]
			# Restore tiles
			for ach in achievements:
				if achievements[ach]:
					_spawn_achievement_tile(ach)
					
		if node_data.has("items"):
			# Merge item counts carefully
			var saved_items = node_data["items"]
			for k in saved_items:
				if items.has(k):
					items[k]["count"] = saved_items[k]["count"]
			
			# Recalculate CPS and Visuals
			cps = 0.0
			for k in items:
				cps += items[k]["base_cps"] * items[k]["count"]
				# Restore visuals
				for i in range(items[k]["count"]):
					_add_visual_icon(k)

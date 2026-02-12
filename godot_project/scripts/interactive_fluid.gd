extends Control

@export var color: Color = Color("8a0303")
@export var tension: float = 0.025
@export var dampening: float = 0.025
@export var spread: float = 0.25

var target_fill_percent: float = 0.0
var max_height_pixels: float = 100.0

# Spring simulation
var springs: Array[float] = [] # Vertical offset from baseline
var spring_velocities: Array[float] = []
var num_springs: int = 100
var spread_iterations: int = 8

func _ready():
	_initialize_springs()

func _initialize_springs():
	springs.resize(num_springs)
	spring_velocities.resize(num_springs)
	springs.fill(0.0)
	spring_velocities.fill(0.0)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta):
	_update_springs(delta)
	queue_redraw()

func _update_springs(_delta):
	# Hooke's Law
	for i in range(num_springs):
		var x = springs[i] # Displacement
		var loss = - dampening * spring_velocities[i]
		var force = - tension * x + loss
		spring_velocities[i] += force
		springs[i] += spring_velocities[i]
	
	# Neighbor Spread
	var left_deltas = []
	var right_deltas = []
	left_deltas.resize(num_springs)
	right_deltas.resize(num_springs)

	for j in range(spread_iterations):
		for i in range(num_springs):
			if i > 0:
				left_deltas[i] = spread * (springs[i] - springs[i - 1])
				spring_velocities[i - 1] += left_deltas[i]
			if i < num_springs - 1:
				right_deltas[i] = spread * (springs[i] - springs[i + 1])
				spring_velocities[i + 1] += right_deltas[i]
		
		for i in range(num_springs):
			if i > 0:
				springs[i - 1] += left_deltas[i]
			if i < num_springs - 1:
				springs[i + 1] += right_deltas[i]

func _draw():
	if size.x == 0 or size.y == 0:
		return
		
	var points = PackedVector2Array()
	var current_height = size.y - (target_fill_percent * max_height_pixels)
	
	# Bottom Right
	points.append(Vector2(size.x, size.y))
	# Bottom Left
	points.append(Vector2(0, size.y))
	
	# Surface Points
	for i in range(num_springs):
		var x_pos = (float(i) / (num_springs - 1)) * size.x
		var y_pos = current_height + springs[i]
		points.append(Vector2(x_pos, y_pos))
		
	draw_colored_polygon(points, color)

func splash(index_ratio: float, velocity: float):
	if index_ratio < 0 or index_ratio > 1: return
	var index = int(index_ratio * (num_springs - 1))
	index = clamp(index, 0, num_springs - 1)
	spring_velocities[index] += velocity

func _gui_input(event):
	if event is InputEventMouseMotion:
		# Calculate speed of mouse movement to determine splash
		var speed = event.velocity.length()
		if speed > 100:
			var local_pos = event.position
			var current_height = size.y - (target_fill_percent * max_height_pixels)
			
			# Check if mouse is near the surface
			if abs(local_pos.y - current_height) < 50:
				var index_ratio = local_pos.x / size.x
				# Vel based on direction of movement vs surface normal (simplified)
				var splash_force = clamp(event.velocity.y * 0.1, -100, 100)
				splash(index_ratio, splash_force)

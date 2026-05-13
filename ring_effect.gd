extends Node2D

# green
@export var ring_color: Color = Color(0.4, 1.0, 0.4, 1)
# how fast grows
@export var duration: float = 0.5
@export var ring_thickness: float = 10

var radius: float = 0

func _ready():
	var tween = create_tween()  
	# grow 0.5 sec
	tween.tween_property(self, "radius", Global.ring_effect_max_radius, duration)
	# fade 0.5 sec
	tween.tween_property(self, "modulate:a", 0, duration) 
	tween.finished.connect(queue_free) 

func _process(_delta):
	queue_redraw()

func _draw():
	draw_ring(Vector2.ZERO, radius, radius - ring_thickness, ring_color)

func draw_ring(center: Vector2, outer_radius: float, inner_radius: float, color: Color):
	var points = 64 
	var angle_step = TAU / points
	var outer_points = PackedVector2Array()
	var inner_points = PackedVector2Array()

	for i in range(points + 1):
		var angle = i * angle_step
		outer_points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
		inner_points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)

	for i in range(points):
		draw_line(outer_points[i], outer_points[i + 1], color, 3)
		draw_line(inner_points[i], inner_points[i + 1], color, 3)

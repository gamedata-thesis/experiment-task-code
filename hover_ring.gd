extends Node2D
# transparent white
@export var ring_color: Color = Color(1, 1, 1, 0.7)
@export var radius: float = 250 
@export var ring_thickness: float = 10

func _ready():
	queue_redraw()  

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

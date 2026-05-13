extends CanvasLayer 

@export var duration: float = 1.0

var flash_color: Color = Color(1, 0.2, 0.2, 1)  # red

@onready var top_rect = $TopTextureRect
@onready var bottom_rect = $BottomTextureRect
@onready var left_rect = $LeftTextureRect
@onready var right_rect = $RightTextureRect

func _ready():
	update_flash_size()
	set_gradient_color(top_rect)
	set_gradient_color(bottom_rect)
	set_gradient_color(left_rect)
	set_gradient_color(right_rect)

	# create tween
	var tween = create_tween()
	tween.set_parallel(true)

	# fading
	tween.tween_property(top_rect, "modulate:a", 0, duration)
	tween.tween_property(bottom_rect, "modulate:a", 0, duration)
	tween.tween_property(left_rect, "modulate:a", 0, duration)
	tween.tween_property(right_rect, "modulate:a", 0, duration)

	tween.finished.connect(queue_free)

func set_flash_color(color: Color):
	flash_color = color
	await self.ready
	set_gradient_color(top_rect)
	set_gradient_color(bottom_rect)
	set_gradient_color(left_rect)
	set_gradient_color(right_rect)


func set_gradient_color(texture_rect: TextureRect):
	if not texture_rect or not texture_rect.texture:
		return
	
	var gradient_texture = texture_rect.texture as GradientTexture2D
	if not gradient_texture:
		return

	var gradient = gradient_texture.gradient
	if gradient:
		gradient.set_color(0, flash_color)
		gradient.set_color(1, Color(flash_color.r, flash_color.g, flash_color.b, 0))


func update_flash_size():
	var screen_size = get_viewport().get_visible_rect().size
	var thickness_h = ceil(screen_size.y * Global.screen_flash_size)
	var thickness_w = ceil(screen_size.x * Global.screen_flash_size)

	# set size and positions
	top_rect.set_size(Vector2(screen_size.x, thickness_h))
	top_rect.set_position(Vector2(0, 0))

	bottom_rect.set_size(Vector2(screen_size.x, thickness_h))
	bottom_rect.set_position(Vector2(0, screen_size.y - thickness_h))

	left_rect.set_size(Vector2(thickness_w, screen_size.y))
	left_rect.set_position(Vector2(0, 0))

	right_rect.set_size(Vector2(thickness_w, screen_size.y))
	right_rect.set_position(Vector2(screen_size.x - thickness_w, 0))

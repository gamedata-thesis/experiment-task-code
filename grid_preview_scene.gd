extends Node2D


# HOX!! this file is not used in final version of the game

const COLUMNS = 4
const ROWS = 3
var cell_size: Vector2
var grid_positions: Array = []

var animal_scene = preload("res://animal.tscn")
var grid_node: Node2D

var ring_scene = preload("res://ring_effect.tscn")
var screen_flash_scene = preload("res://screen_flash_effect.tscn")

var go_textures = [
	load("res://objects/electric_blue_diamond.png")
]

var nogo_textures = [
	load("res://objects/neon_pink_diamond.png"),
	load("res://objects/neon_orange_diamond.png")
]

var grid_state: Array = []


var texture_to_meta = {
	"res://objects/electric_blue_diamond.png": false,
	"res://objects/neon_pink_diamond.png": true,
	"res://objects/neon_orange_diamond.png": true
}

func _ready():

	Global.logging_enabled = false
	
	grid_state = []
	for i in range(COLUMNS * ROWS):
		grid_state.append(true) 
	
	setup_grid()
	spawn_all_animals()

func setup_grid():
	var screen_size = get_viewport_rect().size
	var cell_width = screen_size.x / 9.0
	cell_size = Vector2(cell_width, cell_width)

	grid_node = $GridNode

	create_grid_positions()
	position_grid_center()

func create_grid_positions():
	grid_positions.clear()

	for y in range(ROWS):
		for x in range(COLUMNS):
			var pos = Vector2(
				x * cell_size.x + cell_size.x / 2,
				y * cell_size.y + cell_size.y / 2
			)
			grid_positions.append(pos)

func position_grid_center():
	var screen_size = get_viewport_rect().size
	var grid_size = Vector2(COLUMNS, ROWS) * cell_size
	var y_percent = 0.4
	grid_node.position = Vector2(
		screen_size.x / 2 - grid_size.x / 2,
		screen_size.y * y_percent - grid_size.y / 2
	)


func spawn_all_animals():
	for i in grid_positions.size():
		spawn_animal_at_index(i)

func spawn_animal_at_index(index: int):
	var pos = grid_positions[index]
	var animal = animal_scene.instantiate()

	var is_now_go = grid_state[index]  
	var chosen_texture
	var is_nogo

	if is_now_go:
		chosen_texture = go_textures.pick_random()
		is_nogo = false
	else:
		chosen_texture = nogo_textures.pick_random()
		is_nogo = true

	animal.texture = chosen_texture
	animal.set_meta("is_nogo", is_nogo)

	# Skaalaus
	var tex_size = animal.texture.get_size()
	var scale_factor = cell_size / tex_size
	var min_scale = min(scale_factor.x, scale_factor.y)
	animal.scale = Vector2(min_scale, min_scale)

	animal.position = pos
	grid_node.add_child(animal)

	# Signaali
	animal.animal_clicked.connect(func(clicked_animal, clicked_is_nogo, click_position, _reaction_time):
		create_ring(click_position, clicked_is_nogo)
		create_screen_flash(clicked_is_nogo)

		if clicked_animal.is_inside_tree():
			clicked_animal.queue_free()

		grid_state[index] = !grid_state[index]

		await get_tree().create_timer(2.0).timeout
		spawn_animal_at_index(index)
	)


func create_ring(click_position: Vector2, is_nogo: bool):
	if not ring_scene:
		return
	var ring_instance = ring_scene.instantiate()
	ring_instance.global_position = click_position
	if is_nogo:
		ring_instance.ring_color = Color(1, 0, 1, 1)  # magenta
	else:
		ring_instance.ring_color = Color(0.5, 1, 0.5, 1)  # vihreä
	add_child(ring_instance)

func create_screen_flash(is_nogo: bool):
	if not screen_flash_scene:
		return
	var flash_instance = screen_flash_scene.instantiate()
	if is_nogo:
		flash_instance.set_flash_color(Color(1, 0, 1, 1))  # magenta
	else:
		flash_instance.set_flash_color(Color(0.5, 1, 0.5, 1))  # vihreä
	add_child(flash_instance)


func _on_menu_button_pressed():
	Global.logging_enabled = true
	get_tree().change_scene_to_file("res://landing_page.tscn")

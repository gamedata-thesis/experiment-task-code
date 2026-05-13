extends Node2D

# Buttons
@onready var start_button = $"CanvasLayer/MainUI/StartButton"
@onready var return_menu_button = $"CanvasLayer/MainUI/ReturnMenuButton"

# Labels
@onready var score_label = $"CanvasLayer/MainUI/ScoreLabel"

var stim_timer : Timer

var fraction_strings = {
	0.1: "1/10",
	0.125: "1/8",
	0.16666666666666666: "1/6",
	0.25: "1/4",
	0.5: "1/2"
}

# preload effects and object scene
var ring_scene = preload("res://ring_effect.tscn")  
var animal_scene = preload("res://animal.tscn") 

var screen_flash_scene = preload("res://screen_flash_effect.tscn")

# These are set in game menu
var object_count # how many objects is showed per round
var round_count # how many rounds
var spawn_interval # time before next object
var object_time_visible # how long object is visible if not clicked

var game_started = false 
var shown_animals = 0 # tracks how many animals is shown
var game_start_time = 0  # millisekunneissa
var results = []  # saving all results here
var total_correct_choices = 0 



# for averages
var correct_reaction_times = []
var incorrect_reaction_times = []

# lists for mistakes and success percentages
var omission_rates = []
var commission_rates = []
var success_rates = []


const COLUMNS = 4
const ROWS = 3
var cell_size: Vector2
var grid_node: Node2D
var grid_positions: Array = []
var available_positions: Array = []

var object_queue: Array = []

var spawn_plan: Array = []

var animal_scenes = {
	"go": [
		{"color": "blue", "texture": "res://objects/electric_blue_diamond.png", "is_nogo": false}
	],
	"no_go": [
		{"color": "pink", "texture": "res://objects/neon_pink_diamond.png", "is_nogo": true}
	]
}



func _ready():
	object_count = Global.go_nogo_object_count
	round_count = 1
	spawn_interval = Global.spawn_interval
	object_time_visible = Global.object_time_visible
	score_label.visible = false
	return_menu_button.visible = false

	setup_grid()
	start_button.pressed.connect(start_game)

func start_game():
	# timestamp to file for example "2025-03-27T16:29:29"
	var raw = Time.get_datetime_string_from_system()  
	Global.start_timestamp = raw.replace(":", "-").replace("T", "_")

	#UI
	start_button.visible = false
	
	game_started = true
	# reset globals
	Global.shown_objects = 0 
	Global.score = 0
	Global.game_start_time = Time.get_ticks_msec()
	Global.current_round = 1 
	Global.omission_mistake = 0
	Global.commission_mistake = 0
	Global.correct_choices = 0
	
	spawn_plan.clear()

	var total_positions = grid_positions.size()      
	object_count = Global.go_nogo_object_count  

	# Go/NoGo-amounts
	var go_count = int(ceil(float(object_count) / 2.0))
	var nogo_count = object_count - go_count

	# how many times each place of the grid is repeated (e.g. 2 if 24 objects and 12 squares)
	var repeats = int(ceil(float(object_count) / total_positions))

	# create go list
	var go_list: Array = []
	for r in range(repeats):
		for i in range(total_positions):
			go_list.append({"position_index": i, "type": "go"})

	# create nogo list
	var nogo_list: Array = []
	for r in range(repeats):
		for i in range(total_positions):
			nogo_list.append({"position_index": i, "type": "no_go"})

	# suffling randomly and cut extras of
	go_list.shuffle()
	nogo_list.shuffle()
	go_list = go_list.slice(0, go_count)
	nogo_list = nogo_list.slice(0, nogo_count)

	# combine lists and final suffle
	var combined = go_list + nogo_list
	combined.shuffle()
	spawn_plan = combined


	
	# set timer for object spawning
	stim_timer = Timer.new()
	stim_timer.wait_time = spawn_interval
	stim_timer.one_shot = false
	stim_timer.timeout.connect(show_next_object)
	add_child(stim_timer)
	stim_timer.start()
	

func start_timer():
	if not game_started:
		return
	
	if Global.shown_objects >= object_count:
		end_round()
		return
	
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = true
	timer.timeout.connect(show_next_object)
	add_child(timer) 
	timer.start()

func create_screen_flash(is_nogo : bool):
	if Global.feedback_mode != "border_flash":
		return
		
	if not screen_flash_scene:
		return
	
	var screen_flash_instance = screen_flash_scene.instantiate()
	if is_nogo:
		screen_flash_instance.set_flash_color(Color(1, 0, 1, 1))  # red
	else:
		screen_flash_instance.set_flash_color(Color(0.4, 1.0, 0.4, 1))  # green
	add_child(screen_flash_instance)

func create_ring(click_position: Vector2, is_nogo: bool):
	if Global.feedback_mode != "expanding_ring":
		return
	if not ring_scene:
		return

	var ring_instance = ring_scene.instantiate()
	ring_instance.global_position = click_position
	if is_nogo:
		ring_instance.ring_color = Color(1, 0, 1, 1)  # red
	else:
		ring_instance.ring_color = Color(0.4, 1.0, 0.4, 1)  # green
	add_child(ring_instance)


func setup_grid():
	var screen_size = get_viewport_rect().size
	var cell_width = screen_size.x / 10.0
	cell_size = Vector2(cell_width, cell_width)

	grid_node = Node2D.new()
	add_child(grid_node)

	create_grid_positions()
	position_grid_center()
	


func test_fill_grid_with_random():
	for pos in grid_positions:
		var animal = animal_scene.instantiate()

		# random type
		var chosen_animal = ["go", "no_go"].pick_random()
		var animal_data = animal_scenes[chosen_animal]
		
		animal.texture = load(animal_data["texture"])
		animal.set_meta("is_nogo", animal_data["is_nogo"])

		# scale object
		var tex_size = animal.texture.get_size()
		var scale_factor = cell_size / tex_size
		var min_scale = min(scale_factor.x, scale_factor.y)
		animal.scale = Vector2(min_scale, min_scale)

		animal.position = pos
		grid_node.add_child(animal)

func create_grid_positions():
	grid_positions.clear()

	for y in range(ROWS):
		for x in range(COLUMNS):
			var pos = Vector2(
				x * cell_size.x + cell_size.x / 2,
				y * cell_size.y + cell_size.y / 2
			)
			grid_positions.append(pos)

	available_positions = grid_positions.duplicate()

func position_grid_center():
	var screen_size = get_viewport_rect().size
	var grid_size = Vector2(COLUMNS, ROWS) * cell_size

	var y_percent = 0.4
	grid_node.position = Vector2(
		screen_size.x / 2 - grid_size.x / 2,
		screen_size.y * y_percent - grid_size.y / 2
	)



func show_next_object():
	if Global.shown_objects >= object_count:
		if stim_timer and stim_timer.is_inside_tree():
			stim_timer.stop()
		end_round()
		return

	Global.shown_objects += 1

	# take next object and place from spwan_plan list
	var next = spawn_plan.pop_front()
	var chosen_animal = next["type"]
	var position_index = next["position_index"]
	var spawn_pos = grid_positions[position_index]
	var options = animal_scenes[chosen_animal]
	var animal_data = options[randi() % options.size()]


	var new_animal = animal_scene.instantiate()
	new_animal.texture = load(animal_data["texture"])
	new_animal.set_meta("is_nogo", animal_data["is_nogo"])

	if animal_data["is_nogo"]:
		Global.task_type = "NoGo"
	else:
		Global.task_type = "Go"

	new_animal.position = spawn_pos
	grid_node.add_child(new_animal)

	# scale
	var tex_size = new_animal.texture.get_size()
	var scale_factor = cell_size / tex_size
	var min_scale = min(scale_factor.x, scale_factor.y)
	new_animal.scale = Vector2(min_scale, min_scale)

	new_animal.animal_clicked.connect(_on_animal_clicked)

	Global.object_visible = true
	# saving creation time for misclick
	Global.last_object_appear_time_msec = Time.get_ticks_msec()

	Global.position_index = position_index

	var appear_line = "%s;%s;%d;SHAPE_APPEAR;%.3f;%d;%s;%d;%d;N/A" % [
		Global.get_timestamp_string_global(),
		Global.player_name,
		Global.shown_objects,
		Global.get_game_time_in_seconds(),
		Global.score,
		Global.task_type,
		Global.position_index,
		0
	]
	Global.write_csv_line(appear_line)

	# only if nogo autoremove
	if new_animal.get_meta("is_nogo", false):
		var animal_ref = weakref(new_animal)

		var removal_timer = Timer.new()
		removal_timer.wait_time = object_time_visible
		removal_timer.one_shot = true
		removal_timer.timeout.connect(func():
			var real_animal = animal_ref.get_ref()
			if real_animal and real_animal.is_inside_tree():
				if real_animal.get("is_processed") == true:
					return
				real_animal.set("is_processed", true)

				var entry = {
					"round_id": Global.round_count - round_count + 1,
					"object_id": Global.shown_objects,
					"reaction_time": null,
					"correct_choice": true,  
					"was_nogo": true
				}

				Global.change_score(1)
				handle_animal_done(entry)
				

				var disappear_line = "%s;%s;%d;SHAPE_DISAPPEAR;%.3f;%d;%s;%d;%d;Correct response" % [
					Global.get_timestamp_string_global(),
					Global.player_name,
					Global.shown_objects,
					Global.get_game_time_in_seconds(),
					Global.score,
					Global.task_type,
					Global.position_index,
					0
				]
				Global.write_csv_line(disappear_line)
				Global.object_visible = false
				real_animal.queue_free()
		)
		add_child(removal_timer)
		removal_timer.start()
	else:
		# if go object
		var animal_ref = weakref(new_animal)

		var removal_timer = Timer.new()
		removal_timer.wait_time = object_time_visible
		removal_timer.one_shot = true
		removal_timer.timeout.connect(func():
			var real_animal = animal_ref.get_ref()
			if real_animal and real_animal.is_inside_tree():
				if real_animal.get("is_processed") == true:
					return
				real_animal.set("is_processed", true)
				
				var entry = {
					"round_id": Global.round_count - round_count + 1,
					"object_id": Global.shown_objects,
					"reaction_time": null,
					"correct_choice": false, 
					"was_nogo": false
				}
				# Omission
				Global.change_score(-1)
				handle_animal_done(entry)
				Global.omission_mistake += 1
				
				var omission_line = "%s;%s;%d;SHAPE_DISAPPEAR;%.3f;%d;%s;%d;%d;Omission error" % [
					Global.get_timestamp_string_global(),
					Global.player_name,
					Global.shown_objects,
					Global.get_game_time_in_seconds(),
					Global.score,
					Global.task_type,
					Global.position_index,
					0
					]
				Global.write_csv_line(omission_line)

				Global.object_visible = false
				real_animal.queue_free()
		)
		add_child(removal_timer)
		removal_timer.start()



# When object is clicked
func _on_animal_clicked(animal, is_nogo, click_position, reaction_time):
	if animal and animal.is_inside_tree():
		# is_nogo sets color of the effect
		create_ring(click_position, is_nogo) 
		create_screen_flash(is_nogo) 
		
	# save result data in dict
	var entry = {
		"round_id": Global.round_count - round_count +1,   
		"object_id": Global.shown_objects, 
		"reaction_time": reaction_time,
		"correct_choice": !is_nogo, 
		"was_nogo": is_nogo
	}
	
	handle_animal_done(entry)
	

func handle_animal_done(entry: Dictionary):
	# save resukt
	results.append(entry)
	
	if entry["correct_choice"]:
		Global.correct_choices += 1
	if Global.show_UI_score == 1:
		await get_tree().create_timer(1.0).timeout



func _input(event):
	if not game_started:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# check if object was clicked
		var clicked_any = false
		for child in grid_node.get_children():
			if child is Sprite2D and child.has_method("is_pixel_opaque"):
				var local_pos = child.to_local(event.position)
				if child.is_pixel_opaque(local_pos):
					clicked_any = true
					break

		if not clicked_any and Global.object_visible:
			# MISS click!
			var rt_ms := 0
			if Global.last_object_appear_time_msec > 0:
				rt_ms = Time.get_ticks_msec() - Global.last_object_appear_time_msec

			if Global.logging_enabled:
				var mis_click_line = "%s;%s;%d;MISCLICK;%.3f;%d;%s;%d;%d;N/A" % [
					Global.get_timestamp_string_global(),
					Global.player_name,
					Global.shown_objects,
					Global.get_game_time_in_seconds(),
					Global.score,
					Global.task_type,  # task_type, unidentifyed when no object
					Global.position_index,      # position_index, not exist
					rt_ms
				]
				Global.write_csv_line(mis_click_line)


func end_round():
	# timer so the last click is read correctly
	await get_tree().create_timer(0.5).timeout
	# lcalculate rates
	var round_omission_rate = calculate_rates(Global.omission_mistake, object_count)
	var round_commission_rate = calculate_rates(Global.commission_mistake, object_count)
	var round_success_rate = calculate_rates(Global.correct_choices, object_count)
	
	# save values to list
	omission_rates.append(round_omission_rate)
	commission_rates.append(round_commission_rate)
	success_rates.append(round_success_rate)
	
	total_correct_choices += Global.correct_choices

	end_game()

func end_game():
	await get_tree().create_timer(1).timeout
	var total_objects = object_count * round_count

	write_stats_csv_file()

	var commission_errors = 0
	var omission_errors = 0
	correct_reaction_times.clear()
	incorrect_reaction_times.clear()

	for result in results:
		if result["reaction_time"] != null:
			if result["correct_choice"]:
				correct_reaction_times.append(result["reaction_time"])
			else:
				incorrect_reaction_times.append(result["reaction_time"])

			if result["was_nogo"] and result["reaction_time"] != null:
				commission_errors += 1
		else:
			if not result["was_nogo"]:
				omission_errors += 1

	var avg_correct = calculate_average(correct_reaction_times)
	var avg_incorrect = calculate_average(incorrect_reaction_times)
	var fastest = get_fastest_reaction_time(correct_reaction_times)
	var slowest = get_slowest_reaction_time(correct_reaction_times)

	var total = object_count * round_count
	var accuracy_percent = total_correct_choices * 100.0 / total
	var commission_percent = commission_errors * 100.0 / total
	var omission_percent = omission_errors * 100.0 / total

	var visual_effects := []
	if Global.screen_flash_size > 0.0:
		visual_effects.append("Screen Border Flash")
	if Global.ring_effect_max_radius > 0.0:
		visual_effects.append("Expanding Ring")
		
	var visual_effects_text = String(", ").join(visual_effects) if visual_effects.size() > 0 else "None"

	write_info_txt_file(
		avg_correct,
		avg_incorrect,
		fastest,
		slowest,
		visual_effects_text,
		commission_errors,
		omission_errors,
		total_correct_choices,
		object_count,
		round_count,
		accuracy_percent,
		commission_percent,
		omission_percent
	)

	score_label.text = "Well played!
	\n\n Your average reaction time was: %.2f ms
	\n Fastest reaction: %d ms" % [avg_correct, fastest]
	score_label.visible = true
	return_menu_button.visible = true
	

	for result in results:
		if result["reaction_time"] != null:
			if result["correct_choice"]:
				correct_reaction_times.append(result["reaction_time"])
			else:
				incorrect_reaction_times.append(result["reaction_time"])
	

func get_fastest_reaction_time(times: Array) -> float:
	if times.is_empty():
		return 0.0
	return times.min()

func get_slowest_reaction_time(times: Array) -> float:
	if times.is_empty():
		return 0.0
	return times.max()

func calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	return sum / values.size()

func calculate_rates(mistakes_or_choices: int, total_objects: int) -> float:
	if total_objects == 0:
		return 0.0 
	
	return float(mistakes_or_choices) / float(total_objects)


func write_stats_csv_file():
	var filename = "%s_%s_rates.csv" % [Global.player_name, Global.start_timestamp]
	var base_dir = Global.get_results_folder()
	var path = base_dir.path_join(filename)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	# Header row
	file.store_line("OmissionRate ; CommisionRate ; SuccessRate")

	var avg_omission = calculate_average(omission_rates)
	var avg_commission = calculate_average(commission_rates)
	var avg_success = calculate_average(success_rates)
	file.store_line("%.4f ; %.4f ; %.4f" % [avg_omission, avg_commission, avg_success])
	file.close()

func write_info_txt_file(
	avg_correct: float,
	avg_incorrect: float,
	fastest: float,
	slowest: float,
	visual_effects_text: String,
	commission_errors: int,
	omission_errors: int,
	total_correct_choices_param: int,
	object_count_param: int,
	round_count_param: int,
	accuracy_percent: float,
	commission_percent: float,
	omission_percent: float
):

	var filename = "%s_%s_info.txt" % [Global.player_name, Global.start_timestamp]
	var base_dir = Global.get_results_folder()
	var path = base_dir.path_join(filename)
	var file = FileAccess.open(path, FileAccess.WRITE)


	# --- SESSION INFO ---
	file.store_line("== Game Session ==")
	file.store_line("Date: " + Global.start_timestamp.replace("_", " "))
	file.store_line("Mode: Go & NoGo")
	file.store_line("Player Name: " + Global.player_name)
	file.store_line("Player ID: " + Global.player_id)
	file.store_line("")

	# --- SETTINGS ---
	file.store_line("== Game Settings ==")
	file.store_line("Visual Feedback: " + Global.feedback_mode)

	if Global.feedback_mode == "border_flash":
		file.store_line(" - Border Flash Size: %s (relative to screen)" % fraction_strings.get(Global.screen_flash_size, str(Global.screen_flash_size)))
		file.store_line(" - Expanding Ring Radius: -")

	elif Global.feedback_mode == "expanding_ring":
		file.store_line(" - Border Flash Size: -")
		file.store_line(" - Expanding Ring Radius: %d px" % Global.ring_effect_max_radius)

	else: # esim. "control"
		file.store_line(" - Border Flash Size: -")
		file.store_line(" - Expanding Ring Radius: -")

	file.store_line("Spawn Interval: %.1f sec" % Global.spawn_interval)
	file.store_line("Object Visible Time (Go & NoGo): %.1f sec" % Global.object_time_visible)
	file.store_line("Total Objects: %d" % (object_count_param * round_count_param))
	file.store_line("")

	# --- REACTION TIMES ---
	file.store_line("== Reaction Times ==")
	file.store_line("Average (Correct): %.2f ms" % avg_correct)
	file.store_line("Average (Incorrect): %.2f ms" % avg_incorrect)
	file.store_line("Fastest: %d ms" % fastest)
	file.store_line("Slowest: %d ms" % slowest)
	file.store_line("")

	# --- SUMMARY ---
	file.store_line("== Performance Summary ==")
	file.store_line("Correct Choices: %d / %d" % [total_correct_choices_param, (object_count_param * round_count_param)])
	file.store_line("Success Rate: %.1f%%" % accuracy_percent)
	file.store_line("Commission Errors (Clicked NoGo): %d (%.1f%%)" % [commission_errors, commission_percent])
	file.store_line("Omission Errors (Missed Go): %d (%.1f%%)" % [omission_errors, omission_percent])
	file.store_line("")

	# --- NOTES ---
	file.store_line("== Notes ==")
	file.store_line("- Only clicks on Go-objects are considered correct.")
	file.store_line("- Clicking a NoGo-object is a commission error.")
	file.store_line("- Not clicking a Go-object is an omission error.")

	file.close()



func _on_return_menu_button_pressed():
	get_tree().change_scene_to_file("res://landing_page.tscn")

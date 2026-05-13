extends Control

@onready var object_count_slider = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/ObjectCountSlider"
@onready var object_count_label = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/ObjectCountLabel"

@onready var round_count_slider = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/RoundCountSlider"
@onready var round_count_label = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/RoundCountLabel"

@onready var spawn_interval_slider = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/SpawnIntervalSlider
@onready var spawn_interval_label = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/SpawnIntervalLabel

@onready var object_time_slider = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/ObjectTimeVisibleSlider
@onready var object_time_label = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/ObjectTimeVisibleLabel

# Player name and id
@onready var player_name_line_edit = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer2/PlayerNameLineEdit"
@onready var player_id_line_edit = $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer2/PlayerIdLineEdit"

@onready var feedback_type_option_button = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer2/FeedbackTypeOptionButton

@onready var go_only_object_amount_option_button = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer/GoOnlyObjectAmountOptionButton
@onready var go_no_go_object_amount_option_button = $CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer2/GoNoGoObjectAmountOptionButton



func _ready():
	# set globals for player info
	player_name_line_edit.text = Global.player_name
	player_id_line_edit.text = Global.player_id
	
	# reset globals
	Global.show_UI_score = 0
	Global.screen_flash_size = 1.0 / 8.0
	Global.ring_effect_max_radius = 200.0
	
	#pupdate labels
	update_object_count(object_count_slider.value)
	update_round_count(round_count_slider.value)
	update_spawn_interval(spawn_interval_slider.value)
	update_object_time(object_time_slider.value)
	
	#connects label to values
	object_count_slider.value_changed.connect(update_object_count)
	round_count_slider.value_changed.connect(update_round_count)
	spawn_interval_slider.value_changed.connect(update_spawn_interval)
	object_time_slider.value_changed.connect(update_object_time)
	
	# update feedback method
	match Global.feedback_mode:
		"control":
			feedback_type_option_button.select(0)
		"border_flash":
			feedback_type_option_button.select(1)
		"expanding_ring":
			feedback_type_option_button.select(2)
		_:
			feedback_type_option_button.select(0) # fallback
	
	# return to default values
	Global.go_only_object_count = 12
	Global.go_nogo_object_count = 24


	# Go-Only: 0=6, 1=12, 2=18, 3=24, 4=30
	go_only_object_amount_option_button.select(1)  # 12 kpl

	# Go-NoGo: 0=6, 1=12, 2=18, 3=24, 4=30
	go_no_go_object_amount_option_button.select(3)  # 24 kpl



func update_object_count(value):
	object_count_label.text = "Objects Per Round: " + str(value)
	Global.object_count = value

func update_round_count(value):
	round_count_label.text ="Amount of Rounds: " + str(value)
	Global.round_count = value

func update_spawn_interval(value):
	spawn_interval_label.text = "Time Between Objects: " + str(value) + " sec"
	Global.spawn_interval = value

func update_object_time(value):
	object_time_label.text = "Visible Time per Object: " + str(value) + " sec"
	Global.object_time_visible = value

func _on_save_continue_button_pressed():
	# saves player info if modified, otherwise go with globa
	if player_name_line_edit.text.strip_edges() != "":
		Global.player_name = player_name_line_edit.text

	if player_id_line_edit.text.strip_edges() != "":
		Global.player_id = player_id_line_edit.text
		
	get_tree().change_scene_to_file("res://main_scene.tscn")


func _on_exit_game_button_pressed():
	get_tree().quit()


func _on_feedback_type_option_button_item_selected(index):
	match index:
		0: Global.feedback_mode = "control"
		1: Global.feedback_mode = "border_flash"
		2: Global.feedback_mode = "expanding_ring"
		_: Global.feedback_mode = "control"

func _on_flash_size_option_button_item_selected(index):
	match index:
		0: Global.screen_flash_size = 1.0 / 7.0
		1: Global.screen_flash_size = 1.0 / 8.0
		2: Global.screen_flash_size = 1.0 / 6.0
		3: Global.screen_flash_size = 1.0 / 4.0
		4: Global.screen_flash_size = 1.0 / 2.0
		5: Global.screen_flash_size = 0.0
		_: Global.screen_flash_size = 1.0 / 8.0


func _on_click_ring_option_button_item_selected(index):
	match index:
		0: Global.ring_effect_max_radius = 100.0
		1: Global.ring_effect_max_radius = 150.0
		2: Global.ring_effect_max_radius = 200.0
		3: Global.ring_effect_max_radius = 250.0
		4: Global.ring_effect_max_radius = 300.0
		5: Global.ring_effect_max_radius = 0.0



func _on_show_score_option_button_item_selected(index):
	match index:
		0: Global.show_UI_score = 0
		1: Global.show_UI_score = 1


func _on_save_continue_button_2_pressed():
	# saves player info if modified, otherwise go with globa
	if player_name_line_edit.text.strip_edges() != "":
		Global.player_name = player_name_line_edit.text

	if player_id_line_edit.text.strip_edges() != "":
		Global.player_id = player_id_line_edit.text
		
	get_tree().change_scene_to_file("res://main_scene_nogo.tscn")


func _on_training_area_button_pressed():
	get_tree().change_scene_to_file("res://grid_preview_scene.tscn")



func _on_go_only_object_amount_option_button_item_selected(index):
	match index:
		0: Global.go_only_object_count = 6
		1: Global.go_only_object_count = 12
		2: Global.go_only_object_count = 18
		3: Global.go_only_object_count = 24
		4: Global.go_only_object_count = 30
		
	pass # Replace with function body.


func _on_go_no_go_object_amount_option_button_item_selected(index):
	match index:
		0: Global.go_nogo_object_count = 6
		1: Global.go_nogo_object_count = 12
		2: Global.go_nogo_object_count = 18
		3: Global.go_nogo_object_count = 24
		4: Global.go_nogo_object_count = 30
	pass # Replace with function body.

extends Node


# player settings
var player_name = "Guest" 
var player_id = "P001" 
var logging_enabled = true

# feedback settings
var feedback_mode: String = "control"
var screen_flash_size: float = 1.0 / 7
var ring_effect_max_radius: float = 200


# object settings
var go_only_object_count := 12
var go_nogo_object_count := 24
var object_count = 12 
var round_count = 1
var spawn_interval = 3.5 
var object_time_visible = 2.5 

# runtime session state
var object_visible = false
var last_object_appear_time_msec: int = 0
var show_UI_score = 0 
var shown_objects = 0 
var score = 0 
var current_round = 1 
var game_start_time = 0 
var task_type = "Go" 
var position_index = -1 
var correct_choices = 0

# mistakes
var omission_mistake = 0
var commission_mistake = 0

# for files
var start_timestamp = ""

# returns game time in seconds
func get_game_time_in_seconds() -> float:
	return (Time.get_ticks_msec() - game_start_time) / 1000.0

# adjusting the score, dosen't allow negative values for score
func change_score(value: int):
	score += value
	if score < 0:
		score = 0

func get_results_folder() -> String:
	var base_dir = ""
	if OS.has_feature("editor"):
		#  run in editor -> user:// ( app_userdata)
		base_dir = "user://"
	else:
		# Exported game -> Documents/GoNoGoData
		var docs_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		base_dir = docs_dir.path_join("GoNoGoData")
		# make folder if isn't yet
		DirAccess.make_dir_recursive_absolute(base_dir)
	return base_dir


# helper fuction for timestamp
func get_timestamp_string_global() -> String:
	var now = Time.get_datetime_dict_from_system()
	var ms = Time.get_ticks_msec() % 1000 
	return "%04d.%02d.%02d,%02d:%02d:%02d:%03d" % [
		now["year"], now["month"], now["day"],
		now["hour"], now["minute"], now["second"], ms
	]

#func for saving in csv format
func write_csv_line(line: String):
	if start_timestamp == "":
		start_timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")


	var filename = "%s_%s_events.csv" % [Global.player_name, Global.start_timestamp]
	var base_dir = get_results_folder()
	var path = base_dir.path_join(filename)
	var file: FileAccess

	if not FileAccess.file_exists(path):
		# create file and add header row
		file = FileAccess.open(path, FileAccess.WRITE)
		file.store_line("TimeStamp;PlayerName;ObjectNumber;EventType;GameTime;Score;TaskType;GridIndex;ResponseTime;Outcome")
	else:
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		file.seek_end()

	file.store_line(line)
	file.close()

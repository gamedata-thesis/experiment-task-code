extends Sprite2D

signal animal_clicked(animal, is_wrong, click_position, reaction_time)

# initialize time
var start_time = 0

var hover_ring: Node2D = null
var border_glow: Node = null

# saveflag to determine if cliked
var clicked = false
var is_processed = false


func _ready():
	start_time = Time.get_ticks_msec()

func _input(event):
	if event is InputEventMouseMotion:
		if clicked or is_processed:
			return

		var local_mouse_pos = get_local_mouse_position()
		var is_hovering = is_pixel_opaque(local_mouse_pos)

		if is_hovering:
			match Global.feedback_mode:
				"expanding_ring":
					#Hover-ring at cursor
					if hover_ring == null:
						hover_ring = preload("res://hover_ring.tscn").instantiate()
						get_tree().current_scene.add_child(hover_ring)
					hover_ring.global_position = get_global_mouse_position()
				"border_flash":
					# Border glow
					if border_glow == null:
						border_glow = preload("res://hover_border_glow.tscn").instantiate()
						get_tree().current_scene.add_child(border_glow)
				"control":
					# no hover effect
					pass
				
		else:
			# if not hovering, disable effects
			if hover_ring:
				hover_ring.queue_free()
				hover_ring = null

			if border_glow:
				border_glow.queue_free()
				border_glow = null

			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# remove hover
			if hover_ring:
				hover_ring.queue_free()
				hover_ring = null
			if border_glow:
				border_glow.queue_free()
				border_glow = null
				
			# prevent double-clicks
			if clicked or is_processed:
				return
				
			if is_pixel_opaque(get_local_mouse_position()):
				clicked = true 
				is_processed = true
				
				# calculate reaction time
				var reaction_time = Time.get_ticks_msec() - start_time
				var is_nogo = get_meta("is_nogo", false)
				
				if is_nogo:
					Global.change_score(-1)
					Global.commission_mistake += 1
				else:
					Global.change_score(1)
					
				animal_clicked.emit(self, is_nogo, event.position, reaction_time)
				

				if Global.logging_enabled:
					var click_status = ""
					if is_nogo:
						click_status = "Commission error"
					else:
						click_status = "Correct response"
						
					var click_line = "%s;%s;%d;CLICK;%.3f;%d;%s;%d;%d;%s" % [
						Global.get_timestamp_string_global(),
						Global.player_name,
						Global.shown_objects,
						Global.get_game_time_in_seconds(),
						Global.score,
						Global.task_type,
						Global.position_index,
						reaction_time,
						click_status
					]
					Global.write_csv_line(click_line)

				# Fading with tween-effect
				var tween = create_tween()
				tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
				
				# await animation
				await tween.finished
				Global.object_visible = false
				# remove object
				queue_free()
				
func _exit_tree():
	if hover_ring:
		hover_ring.queue_free()
		hover_ring = null
	if border_glow:
		border_glow.queue_free()
		border_glow = null

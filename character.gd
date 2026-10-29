
extends Node2D

@onready var body_animation: AnimatedSprite2D = $body
@onready var eyes_animation: AnimatedSprite2D = $eyes
@onready var effect_star: AnimatedSprite2D = $effects/star
@onready var effect_zzz: AnimatedSprite2D = $effects/zzz

var is_dragging := false
var is_moving := false
var is_sleeping := false
var is_annoyed := false
var is_looking := false

var drag_offset := Vector2i.ZERO
var press_position := Vector2i.ZERO

var clicks := 0

var blink_timer: Timer
var click_timer: Timer
var expression_timer: Timer
var sleep_timer: Timer
var look_timer: Timer

var eyes_home_position: Vector2

func _ready() -> void:
	effect_star.hide()
	effect_zzz.hide()

	body_animation.play("idle_1")
	eyes_animation.play("eye_open")

	# Random blinking
	blink_timer = Timer.new()
	blink_timer.one_shot = true
	add_child(blink_timer)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	random_blink()

	# Click counter reset
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.wait_time = 1.0
	add_child(click_timer)
	click_timer.timeout.connect(_on_click_timer_timeout)

	# Expression reset
	expression_timer = Timer.new()
	expression_timer.one_shot = true
	add_child(expression_timer)
	expression_timer.timeout.connect(_on_expression_timer_timeout)

	# Sleep timer
	sleep_timer = Timer.new()
	sleep_timer.one_shot = true
	sleep_timer.wait_time = 15.0
	add_child(sleep_timer)
	sleep_timer.timeout.connect(_on_sleep_timer_timeout)
	sleep_timer.start()
	
	look_timer = Timer.new()
	look_timer.one_shot = true	
	add_child(look_timer)
	look_timer.timeout.connect(_on_look_timer_timeout)
	
	look_timer.start(randf_range(2.0,5.0))
	
	eyes_home_position = eyes_animation.position


func random_blink() -> void:
	blink_timer.start(randf_range(2.0, 5.0))


func _on_blink_timer_timeout() -> void:
	if not is_dragging and not is_sleeping:
		if eyes_animation.animation == "eye_open":
			eyes_animation.play("eye_close")
			await get_tree().create_timer(0.12).timeout

			if not is_dragging and not is_sleeping:
				eyes_animation.play("eye_open")

	random_blink()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			# Wake up if sleeping
			if is_sleeping:
				is_sleeping = false
				effect_zzz.stop()
				effect_zzz.hide()
				eyes_animation.play("eye_inawe")

			sleep_timer.start()

			is_dragging = true
			is_moving = false
			is_annoyed = false

			press_position = DisplayServer.mouse_get_position()
			drag_offset = (
				press_position
				- DisplayServer.window_get_position()
			)

			clicks += 1
			click_timer.start()

			if clicks > 5:
				is_annoyed = true
				eyes_animation.play("eye_annoyed")
				expression_timer.start(2.0)
			else:
				eyes_animation.play("eye_happy")
				expression_timer.start(1.0)

		else:
			# Mouse released
			is_dragging = false

			if is_moving:
				eyes_animation.play("eye_annoyed")
				expression_timer.start(2.0)
			elif not is_annoyed:
				play_happy_star()

			is_moving = false

	elif event is InputEventMouseMotion and is_dragging:
		var mouse_pos := DisplayServer.mouse_get_position()

		# Detect actual dragging
		if mouse_pos.distance_to(press_position) > 3:
			if not is_moving:
				is_moving = true
				expression_timer.stop()
				eyes_animation.play("eye_inawe")

		if is_moving:
			DisplayServer.window_set_position(mouse_pos - drag_offset)


func _on_click_timer_timeout() -> void:
	clicks = 0


func _on_expression_timer_timeout() -> void:
	if not is_dragging and not is_sleeping:
		eyes_animation.play("eye_open")


func _on_sleep_timer_timeout() -> void:
	if not is_dragging:
		is_sleeping = true
		eyes_animation.play("eye_sleepy")

		await get_tree().create_timer(0.5).timeout

		if is_sleeping and not is_dragging:
			effect_zzz.show()
			effect_zzz.play("zzz")


func play_happy_star() -> void:
	effect_star.show()
	effect_star.play("star_fade_in")

	await get_tree().create_timer(0.5).timeout

	if is_dragging:
		effect_star.hide()
		return

	effect_star.play("star_fade_out")

	await get_tree().create_timer(0.5).timeout

	effect_star.hide()

func _on_look_timer_timeout() -> void:
	if not is_dragging and not is_sleeping:
		var offset_x: float = randf_range(-0.2, 0.2)
		var target_position: Vector2 = eyes_home_position + Vector2(offset_x, 0.0)

		var tween := create_tween()
		tween.tween_property(eyes_animation, "position", target_position, 0.2)
		tween.tween_interval(randf_range(0.5, 1.5))
		tween.tween_property(eyes_animation, "position", eyes_home_position, 0.2)

	look_timer.start(randf_range(2.0, 5.0))

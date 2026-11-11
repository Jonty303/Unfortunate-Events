extends SceneTree
## Run after importing: godot --headless --path . --script tests/touch_smoke.gd
const Overlay = preload("res://touch_controls.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run_tests() -> void:
	var ui := Overlay.new()
	ui.save_preferences = false
	root.add_child(ui)
	ui.touch_capable = false
	ui.touch_seen = false
	ui.set_mode(Overlay.TouchMode.AUTO)
	check(not ui.controls_visible(), "Auto hides controls without touch capability")
	ui.touch_capable = true
	check(ui.controls_visible(), "Auto shows controls on a touch-capable device")
	ui.set_mode(Overlay.TouchMode.OFF)
	check(not ui.controls_visible(), "Off overrides touch detection")
	ui.set_mode(Overlay.TouchMode.ON)
	check(ui.controls_visible(), "On forces controls visible")
	check(ui.press_pointer(0, ui.STICK_CENTRE), "First finger claims joystick")
	ui.drag_pointer(0, ui.STICK_CENTRE + Vector2(86, 0))
	check(ui.movement.is_equal_approx(Vector2.RIGHT), "Joystick gives full right movement")
	ui.press_pointer(1, ui.FIRE_CENTRE)
	ui.press_pointer(2, ui.ROCKET_CENTRE)
	check(ui.fire_held and ui.rocket_held, "Both weapons can be held together")
	check(ui.movement.x > 0.99, "Weapons do not steal the movement finger")
	ui.release_pointer(1)
	check(not ui.fire_held and ui.rocket_held, "Cannon release preserves rocket hold")
	check(ui.movement.x > 0.99, "Weapon release preserves movement")
	ui.drag_pointer(0, ui.STICK_CENTRE + Vector2(1000, -1000))
	check(is_equal_approx(ui.movement.length(), 1.0), "Diagonal movement is clamped")
	ui.drag_pointer(0, ui.STICK_CENTRE + Vector2(3, 0))
	check(ui.movement == Vector2.ZERO, "Joystick dead zone suppresses drift")
	ui.release_pointer(0)
	check(ui.movement == Vector2.ZERO and ui.rocket_held, "Movement release leaves rocket held")
	ui.drag_pointer(2, Vector2.ZERO)
	check(not ui.rocket_held, "Dragging off rocket releases firing")
	ui.drag_pointer(2, ui.ROCKET_CENTRE)
	check(ui.rocket_held, "Returning to rocket resumes firing")
	ui.press_pointer(3, ui.STICK_CENTRE + Vector2(70, 0))
	ui.press_pointer(4, ui.STICK_CENTRE)
	ui.release_pointer(4)
	check(ui.movement.x > 0.5, "Second movement finger does not steal the stick")
	ui.set_game_paused(true)
	check(ui.movement == Vector2.ZERO and not ui.rocket_held and ui.captures.is_empty(), "Pause releases every input")
	ui.set_game_paused(false)
	ui.press_pointer(5, ui.FIRE_CENTRE)
	var cancelled := InputEventScreenTouch.new()
	cancelled.index = 5
	cancelled.canceled = true
	cancelled.pressed = false
	ui._input(cancelled)
	check(not ui.fire_held, "Touch cancellation releases fire")
	ui.press_pointer(6, ui.FIRE_CENTRE)
	ui.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not ui.fire_held, "Focus loss releases fire")
	ui.press_pointer(7, ui.FIRE_CENTRE)
	ui.set_mode(Overlay.TouchMode.OFF)
	check(not ui.fire_held and ui.captures.is_empty(), "Hiding controls releases held inputs")
	ui.set_mode(Overlay.TouchMode.ON)
	ui.press_pointer(-1, ui.MODE_RECT.get_center())
	check(ui.blocks_mouse_fire(), "Selector click is owned by UI, not the cannon")
	ui.release_pointer(-1)
	ui.free()

	# Integration: the real scene, common cooldowns and pause/reset behaviour.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(Overlay.TouchMode.ON)
	game.touch_controls.press_pointer(10, game.touch_controls.FIRE_CENTRE)
	game._process(0.01)
	check(game.rounds.size() == 1, "Touch fires through the real cannon path")
	game._process(0.01)
	check(game.rounds.size() == 1, "Touch fire respects the common cannon cooldown")
	game.touch_controls.press_pointer(11, game.touch_controls.ROCKET_CENTRE)
	game._process(0.01)
	check(game.rounds.size() == 2, "Rocket and cannon can operate together")
	game.toggle_pause()
	var saved_travel: float = game.travel
	game._process(0.05)
	check(is_equal_approx(game.travel, saved_travel), "Pause stops world motion")
	check(not game.touch_controls.fire_held, "Pause clears touch fire in the game")
	game.reset_test()
	check(game.rounds.is_empty() and not game.paused, "Restart clears projectiles and pause")
	game.free()
	if failures.is_empty():
		print("TOUCH TESTS PASSED: %d checks" % checks)
		quit(0)
	else:
		print("TOUCH TESTS FAILED: %d / %d" % [failures.size(), checks])
		quit(1)

extends SceneTree
## Tuning regressions use actual input events, including multi-touch without mouse emulation.
const Tuning = preload("res://debug_tuning.gd")
const Game = preload("res://visual_test.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func touch(index: int, at: Vector2, down: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = down
	event.canceled = canceled
	root.push_input(event, true)

func tap(index: int, at: Vector2) -> void:
	touch(index, at, true)
	touch(index, at, false)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = InputEventKey.new()
	event.physical_keycode = code
	root.push_input(event, true)

func run_tests() -> void:
	var values := Tuning.defaults()
	check(values.size() == 19, "All 19 controls have defaults")
	check(is_equal_approx(values["player_scale"], 0.75), "Default ship remains 75 percent")
	check(is_equal_approx(values["object_scale"], 0.85), "World objects remain 85 percent")
	for spec in Tuning.SPECS:
		var dirty := values.duplicate()
		dirty[spec["key"]] = "invalid"
		check(Tuning.sanitise(dirty)[spec["key"]] == spec["default"], "Reject wrong type: " + spec["key"])
		if typeof(spec["default"]) != TYPE_BOOL:
			dirty[spec["key"]] = -INF
			check(Tuning.sanitise(dirty)[spec["key"]] == spec["default"], "Reject nonfinite: " + spec["key"])
			dirty[spec["key"]] = 999999.0
			check(Tuning.sanitise(dirty)[spec["key"]] == spec["max"], "Clamp high: " + spec["key"])
			dirty[spec["key"]] = -999999.0
			check(Tuning.sanitise(dirty)[spec["key"]] == spec["min"], "Clamp low: " + spec["key"])
	var path := "user://tuning_test_only.cfg"
	check(Tuning.save_profile(values, path) == OK, "Save a bounded local preset")
	check(Tuning.load_profile(path)["values"] == Tuning.sanitise(values), "Saved preset roundtrips")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(Tuning.load_profile(path)["error"] != OK, "Missing profile is reported, not silently applied")
	var future := ConfigFile.new()
	future.set_value("meta", "version", 999)
	future.save(path)
	check(Tuning.load_profile(path)["error"] == ERR_INVALID_DATA, "Unsupported profile version rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var game: Game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sfx.set_muted(true)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(1)
	game.tuning_ui.profile_path = path
	var panel = game.tuning_ui
	await process_frame
	# push_input uses the logical 1920x1080 viewport coordinates used by browser touch.
	touch(1, game.touch_controls.STICK_CENTRE + Vector2(60, 0), true)
	touch(2, game.touch_controls.FIRE_CENTRE, true)
	check(game.touch_controls.fire_held and game.touch_controls.movement.x > 0, "Start with two active gameplay fingers")
	tap(3, panel.LAUNCH.get_center())
	check(panel.panel_open and game.paused, "Touch tuning button opens and pauses")
	check(not game.touch_controls.fire_held and game.touch_controls.movement == Vector2.ZERO, "Opening clears held gameplay fingers")
	check(not game.touch_controls.is_processing_input(), "Gameplay touch input suspended while tuning")
	var before := game.mission_time
	game._process(0.2)
	check(game.mission_time == before, "Opening really stops the simulation")
	tap(4, game.touch_controls.FIRE_CENTRE)
	check(not game.touch_controls.fire_held and game.rounds.is_empty(), "Touches outside modal never fire")
	panel.group = 0
	touch(5, panel.slider_rect(0).position + Vector2(0, 30), true)
	check(is_equal_approx(panel.draft["player_scale"], 0.4), "Slider touch reaches minimum")
	var drag := InputEventScreenDrag.new()
	drag.index = 5
	drag.position = panel.slider_rect(0).end + Vector2(200, 0)
	root.push_input(drag, true)
	check(is_equal_approx(panel.draft["player_scale"], 1.0), "Captured slider clamps outside its track")
	touch(6, panel.slider_rect(0).position + Vector2(40, 20), true)
	check(is_equal_approx(panel.draft["player_scale"], 1.0), "Second finger cannot steal a slider")
	touch(5, Vector2(1800, 850), false)
	touch(6, Vector2(500, 850), false)
	check(is_equal_approx(game.player_scale, 0.75), "Slider draft does not alter the active game")
	tap(7, panel.decrement_rect(0).get_center())
	check(is_equal_approx(panel.draft["player_scale"], 0.99), "Minus button is touch-operable")
	var old_group: int = panel.group
	touch(8, Vector2(600, 267), true)
	touch(8, Vector2(600, 267), false, true)
	check(panel.group == old_group, "Canceled touch does not activate a tab")
	tap(9, panel.footer_rect(3).get_center())
	check(not panel.panel_open and not game.paused and game.player_scale == 0.75, "Cancel discards edits and restores running state")
	check(game.touch_controls.is_processing_input(), "Touch controls are restored")

	game.paused = true
	key(KEY_F4)
	check(panel.panel_open, "F4 opens settings")
	key(KEY_ESCAPE)
	check(not panel.panel_open and game.paused, "Escape preserves an already paused game")
	game.paused = false
	panel.open_panel(game.current_tuning())
	panel.draft["player_scale"] = 0.6
	panel.draft["player_speed"] = 600.0
	panel.draft["scroll_speed"] = 200.0
	panel.draft["cannon_rate"] = 10.0
	panel.draft["cannon_speed"] = 1000.0
	panel.draft["cannon_damage"] = 2.0
	panel.draft["rocket_reload"] = 1.2
	panel.draft["rocket_speed"] = 900.0
	panel.draft["rocket_gravity"] = 500.0
	panel.draft["blast_radius"] = 150.0
	panel.activate("footer:1")
	check(Tuning.load_profile(path)["values"]["player_scale"] == 0.6, "Save stages the edited preset")
	panel.draft["player_scale"] = 0.9
	panel.activate("footer:2")
	check(panel.draft["player_scale"] == 0.6, "Load restores saved values into the draft")
	game.mission_time = 10
	tap(10, panel.footer_rect(5).get_center())
	check(not panel.panel_open and not game.paused and game.mission_time == 10, "Apply/return preserves encounter progress")
	check(is_equal_approx(game.player_scale, 0.6) and is_equal_approx(game.object_scale, 0.85), "Ship tuning remains independent of ground object scale")
	check(game.touch_controls.STICK_RADIUS == 86.0, "UI size unaffected by tuning")
	game.fire_cannon()
	check(is_equal_approx(game.cannon_cooldown, 0.1), "Shots per second converts to correct interval")
	check(is_equal_approx(game.rounds[0]["v"].x, 1200.0), "Cannon speed includes configured camera travel")
	check(game.rounds[0]["damage"] == 2, "Cannon damage is configurable")
	game.fire_cannon()
	check(game.rounds.size() == 1, "Tuning does not bypass fire-rate cap")
	game.rounds.clear()
	game.fire_missile()
	check(is_equal_approx(game.missile_cooldown, 1.2), "Rocket reload applied")
	check(is_equal_approx(game.rounds[0]["cruise"], 1100), "Rocket speed uses its configured value")
	game.update_rounds(0.05)
	check(is_equal_approx(game.rounds[0]["v"].y, 95), "Rocket acceleration is configurable")

	values = Tuning.defaults()
	values["invincible"] = true
	values["enemy_fire"] = false
	values["projectile_size"] = 1.5
	game.apply_tuning(values)
	game.reset_test()
	var hp: int = game.hull
	game.damage_player(2, game.player)
	check(game.hull == hp, "Invulnerable helper blocks damage")
	var enemy: Dictionary = game.director.spawn("tank", 1000, game.GROUND)
	game.director.shoot(game, enemy)
	check(game.rounds.is_empty(), "Enemy fire switch disables new hostile shots")
	game.rounds.append({"friendly":false})
	game.apply_tuning(values)
	check(game.rounds.is_empty(), "Disabling fire removes existing hostile rounds")
	values["enemy_fire"] = true
	values["enemy_shot_speed"] = 0.5
	values["warning_time"] = 2.0
	values["enemy_reload"] = 2.0
	game.apply_tuning(values)
	game.director.shoot(game, enemy)
	check(is_equal_approx(game.rounds[0]["v"].length(), 220), "Enemy shot speed multiplier applied")
	enemy["state"] = "aim"
	enemy["timer"] = 0.0
	game.director.advance_ground(game, enemy, true, 0.01)
	check(is_equal_approx(enemy["timer"], 1.5), "Warning duration multiplier applied")
	enemy["state"] = "warn"
	enemy["timer"] = 0.0
	game.director.advance_ground(game, enemy, true, 0.01)
	check(is_equal_approx(enemy["timer"], 5.6), "Reload duration multiplier applied")
	var hitbox: Rect2 = game.player_box()
	values["projectile_size"] = 0.5
	game.apply_tuning(values)
	check(game.player_box() == hitbox, "Visibility tuning does not alter hitboxes")
	values = Tuning.defaults()
	values["simulation_speed"] = 0.5
	game.apply_tuning(values)
	game.reset_test()
	game._process(0.1)
	check(is_equal_approx(game.mission_time, 0.05), "Slow motion scales the encounter clock")
	check(is_equal_approx(game.travel, 7.25), "Slow motion also scales world travel")
	game.tuning_ui.open_panel(game.current_tuning())
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.tuning_ui.close_panel(false)
	check(game.paused, "Focus loss during tuning cannot resume the game unexpectedly")
	panel.open_panel(game.current_tuning())
	panel.activate("footer:0")
	panel.activate("footer:4")
	check(not game.paused and game.mission_time == 0, "Apply/restart begins a fresh encounter")
	check(is_equal_approx(game.player_scale, 0.75) and game.tuning_values["simulation_speed"] == 1.0, "Defaults restores original balance")
	check(Tuning.load_profile(path)["values"]["player_scale"] == 0.6, "Defaults does not silently overwrite saved preset")
	# Held physical fire must not leak through the return/apply action.
	game.rounds.clear()
	game.cannon_cooldown = 0
	var held := InputEventKey.new()
	held.physical_keycode = KEY_Z
	held.keycode = KEY_Z
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	game.step_combat(0.01)
	check(game.rounds.is_empty(), "Held fire is suppressed after returning from tuning")
	held = InputEventKey.new()
	held.physical_keycode = KEY_Z
	held.keycode = KEY_Z
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	game.step_combat(0.01)
	check(not game.block_weapon_input, "Physical release clears weapon suppression")
	held = InputEventKey.new()
	held.physical_keycode = KEY_Z
	held.keycode = KEY_Z
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	game.step_combat(0.01)
	check(game.rounds.size() == 1, "Fresh fire press works after tuning")
	held = InputEventKey.new()
	held.physical_keycode = KEY_Z
	held.keycode = KEY_Z
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	# Resized native viewport events are transformed into the same authored canvas.
	for dimensions in [Vector2i(1024, 768), Vector2i(1280, 720)]:
		root.size = dimensions
		await process_frame
		var converted := InputEventScreenTouch.new()
		converted.index = 90
		converted.position = root.get_final_transform() * panel.LAUNCH.get_center()
		converted.pressed = true
		root.push_input(converted, false)
		converted = converted.duplicate()
		converted.pressed = false
		root.push_input(converted, false)
		check(panel.panel_open, "Scaled viewport opens tuning at %s" % dimensions)
		panel.close_panel(false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.free()
	if failures.is_empty():
		print("TUNING TESTS PASSED: %d checks" % checks)
		quit(0)
	else:
		print("TUNING TESTS FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)

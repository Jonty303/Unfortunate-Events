extends SceneTree
## 01C: independent player scale, attack state machines, wreckage, sound and full encounter.
const Game = preload("res://visual_test.gd")
const Art = preload("res://enemy_art.gd")
const Director = preload("res://enemy_director.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_tests")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run_tests() -> void:
	var game: Game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(1)
	check(is_equal_approx(game.player_scale, 0.75), "Default shuttle is 75 percent")
	check(is_equal_approx(game.object_scale, 0.85), "World object scale stays at 85 percent")
	var reference := game.director.spawn("tank", 950, game.GROUND)
	var ground_box := game.target_box(reference)
	var touch_radius: float = game.touch_controls.FIRE_RADIUS
	for i in 3:
		game.cycle_scale()
		check(game.target_box(reference).is_equal_approx(ground_box), "Player scale never changes tank collision geometry")
		check(game.touch_controls.FIRE_RADIUS == touch_radius, "Player scale never changes touch hit areas")
		check(game.ship.scale.is_equal_approx(Vector2.ONE * game.player_scale), "Attachments inherit selected player scale")
	check(game.sfx.voices.size() == 8 and game.sfx.sounds.size() == 6, "Sound pool and effects are bounded")
	game.toggle_sound()
	check(game.sfx.muted, "Touch-accessible sound switch mutes")
	game.toggle_sound()
	check(not game.sfx.muted and game.sfx.unlocked, "Sound can be explicitly re-enabled")
	game.sfx.set_muted(true)  # Fast simulation does not mix real-time audio.

	# A staged tank rotates, locks, warns, fires once, recoils and reloads.
	game.reset_test()
	game.targets.assign([game.director.spawn("tank", 1250, game.GROUND)])
	game.director.cursor = Director.SCHEDULE.size()
	var tank: Dictionary = game.targets[0]
	for i in 12: game.director.advance(game, 0.05)
	check(game.rounds.is_empty(), "Tank cannot fire before aim and warning")
	for i in 12: game.director.advance(game, 0.05)
	check(tank["state"] == "warn", "Tank settles into warning state")
	var locked_angle: float = tank["aim"]
	game.player.y = 160
	game.director.advance(game, 0.1)
	check(is_equal_approx(tank["aim"], locked_angle), "Tank aim locks before firing so warning can be dodged")
	var expected_muzzle := Art.muzzle_world(tank, game.GROUND, game.object_scale)
	for i in 15: game.director.advance(game, 0.05)
	check(game.rounds.size() == 1, "Tank fires one shell per cycle")
	check(game.rounds[0]["p"].distance_to(expected_muzzle) < 0.01, "Tank shell comes from physical barrel tip")
	check(game.rounds[0]["v"].normalized().is_equal_approx(Vector2.RIGHT.rotated(locked_angle)), "Tank barrel and shell direction agree")
	check(tank["state"] == "reload", "Tank reload follows shot")
	var shots := game.rounds.size()
	for i in 20: game.director.advance(game, 0.05)
	check(game.rounds.size() == shots, "Tank cannot fire during reload")

	game.reset_test()
	game.targets.assign([game.director.spawn("launcher", 1400, game.GROUND)])
	game.director.cursor = Director.SCHEDULE.size()
	var launcher: Dictionary = game.targets[0]
	for i in 40: game.director.advance(game, 0.05)
	check(game.rounds.is_empty(), "Launcher rail rise and warning precede launch")
	var raised: float = launcher["aim"]
	var rocket_origin := Art.muzzle_world(launcher, game.GROUND, game.object_scale)
	for i in 8: game.director.advance(game, 0.05)
	check(game.rounds.size() == 1, "Launcher releases one missile")
	check(not launcher["loaded"] and launcher["state"] == "reload", "Rail becomes empty during reload")
	check(game.rounds[0]["p"].distance_to(rocket_origin) < 0.01, "Missile launches from rendered rail tip")
	check(game.rounds[0].get("enemy_rocket", false), "Hostile missile has its own trajectory, not player drop logic")
	var trajectory: Vector2 = game.rounds[0]["v"]
	game.previous_player_world = game.player
	game.update_rounds(0.2)
	check(game.rounds[0]["v"].is_equal_approx(trajectory), "Enemy missile stays unguided after player moves")
	for i in 10: game.director.advance(game, 0.05)
	check(absf(launcher["aim"] + PI) < absf(raised + PI), "Empty launcher rail lowers to reload")
	for i in 85: game.director.advance(game, 0.05)
	check(launcher["loaded"], "Reload replaces visible missile")

	# No offscreen attacks, rear attacks or stale warning after re-entry.
	for kind in ["tank", "launcher"]:
		game.reset_test()
		game.director.cursor = Director.SCHEDULE.size()
		game.targets.assign([game.director.spawn(kind, game.W + 400, game.GROUND)])
		for i in 100: game.director.advance(game, 0.05)
		check(game.rounds.is_empty(), "Offscreen %s never fires" % kind)
		game.targets[0]["x"] = game.player.x - 100
		for i in 100: game.director.advance(game, 0.05)
		check(game.rounds.is_empty(), "Passed %s cannot shoot from behind" % kind)
		game.targets[0]["x"] = 1300
		game.targets[0]["state"] = "warn"
		game.targets[0]["timer"] = 0.01
		game.player.x = 1200
		game.director.advance(game, 0.05)
		check(game.targets[0]["state"] == "wait" and game.rounds.is_empty(), "Close %s cancels attack warning" % kind)
		game.player.x = 365
		game.director.advance(game, 0.05)
		check(game.rounds.is_empty(), "Re-entry into %s firing window cannot surprise-fire" % kind)

	game.reset_test()
	game.targets.assign([game.director.spawn("interceptor", 1330, 440)])
	game.director.cursor = Director.SCHEDULE.size()
	var aircraft: Dictionary = game.targets[0]
	for i in 25: game.director.advance(game, 0.05)
	check(game.rounds.is_empty(), "Air opponent has entry settle and telegraph")
	for i in 25: game.director.advance(game, 0.05)
	check(game.rounds.size() == 3, "Air opponent fires readable three-shot burst")
	for shot in game.rounds:
		check(shot["v"].is_equal_approx(Vector2(-460, 0)), "Interceptor rounds fly straight, never homing")
		check(absf(shot["p"].y - (440 + 18 * game.object_scale)) < 0.01, "Interceptor rounds leave its mounted muzzle")
	game.damage_target(aircraft, 2, Vector2(aircraft["x"], 440))
	check(aircraft["dead"] and game.chunks.size() == 3, "Aircraft breaks into three recognisable cosmetic pieces")
	var count := game.rounds.size()
	for i in 80: game.director.advance(game, 0.05)
	check(game.rounds.size() == count, "Destroyed enemy never fires again")

	game.reset_test()
	var wreck := game.director.spawn("tank", 850, game.GROUND)
	game.targets.assign([wreck])
	game.damage_target(wreck, 3, game.target_box(wreck).get_center())
	check(wreck["dead"] and game.kills == 1, "Kill leaves a dead world-anchored object, not a deletion")
	var wreck_x: float = wreck["x"]
	game.update_atmospherics(1.0)
	game.update_chunks(1.0)
	check(wreck["x"] == wreck_x and wreck["dead_age"] == 1.0, "Wreck stays at original world position")
	check(not game.smoke.is_empty(), "Recently destroyed ground vehicle produces lingering smoke")
	game.damage_target(wreck, 30, Vector2.ZERO)
	check(game.kills == 1, "Wreck cannot be killed twice or inflate score")
	for i in 15: game.spawn_chunks(wreck)
	check(game.chunks.size() <= 48, "Debris is capped")
	var hull: int = game.hull
	game.update_chunks(0.2)
	check(game.hull == hull, "Cosmetic debris never causes invisible gameplay damage")
	var chunk_position: Vector2 = game.chunks[0]["p"]
	var wreck_age: float = wreck["dead_age"]
	game.toggle_pause()
	game._process(0.2)
	check(game.chunks[0]["p"].is_equal_approx(chunk_position) and wreck["dead_age"] == wreck_age, "Pause freezes wrecks and fragments")
	game.reset_test()
	check(game.chunks.is_empty() and game.director.cursor == 0 and not game.complete, "Restart resets debris, schedule and completion")

	# Full deterministic sequence with invulnerability only for this endurance check.
	var peak_rounds := 0
	var peak_targets := 0
	for i in 1925:
		game.invulnerable = 10.0
		game._process(1.0 / 30.0)
		peak_rounds = maxi(peak_rounds, game.rounds.size())
		peak_targets = maxi(peak_targets, game.targets.size())
	check(game.director.cursor == Director.SCHEDULE.size(), "All authored encounter events are visited")
	check(game.complete and not game.destroyed, "Encounter reaches explicit completion")
	check(game.rounds.is_empty() and game.touch_controls.game_paused, "Completion clears threats and held controls")
	check(peak_rounds <= 128 and peak_targets <= 9, "Full encounter remains within actor/projectile budget")
	var travel_before := game.travel
	game._process(0.2)
	check(game.travel == travel_before, "Completion freezes route, not an endless empty level")
	game.fire_cannon()
	game.fire_missile()
	check(game.rounds.is_empty(), "Cannot fire after completion")
	var restart := InputEventJoypadButton.new()
	restart.button_index = JOY_BUTTON_Y
	restart.pressed = true
	game._unhandled_input(restart)
	check(not game.complete and game.mission_time == 0 and game.hull == 5, "Controller restarts completed encounter")
	game.free()
	if failures.is_empty():
		print("ENCOUNTER TESTS PASSED: %d checks" % checks)
		quit(0)
	else:
		print("ENCOUNTER TESTS FAILED: %d / %d" % [failures.size(), checks])
		quit(1)

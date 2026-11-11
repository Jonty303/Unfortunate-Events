extends SceneTree
## Real-engine review captures, not composited concept art.
const Game = preload("res://visual_test.gd")
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game: Game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(1)
	game.sfx.set_muted(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
	for factor in [0.75, 0.85]:
		game.player_scale = factor
		game.reset_test()
		game.travel = 650.0
		game.mission_time = 45.0
		game.targets.assign([
			game.director.spawn("tank", 1420, game.GROUND),
			game.director.spawn("launcher", 2250, game.GROUND),
			game.director.spawn("facility", 1900, game.GROUND),
			game.director.spawn("interceptor", 1710, 420)
		])
		game.targets[0].merge({"aim": -2.55, "state": "warn", "warning": 0.7}, true)
		game.targets[1].merge({"aim": -2.4, "state": "warn", "warning": 0.5}, true)
		game.targets[3].merge({"state": "warn", "warning": 0.6}, true)
		game.player = Vector2(360, 570)
		game.ship.advance(0.1, Vector2(0.2, -0.3), true)
		game.sync_ship()
		game.fire_cannon()
		game.update_rounds(0.13)
		game._process(0.0)
		if not await save_frame("01c-combat-%d" % roundi(factor * 100)): return
	game.player = Vector2(365, 9999)
	game.ship.rotation = 0.0
	game.clamp_player()
	game.debug_layers = true
	game.rounds.clear()
	game.cannon_cooldown = 0
	game.fire_cannon()
	game.update_rounds(0.09)
	game._process(0)
	if not await save_frame("01c-strafe"): return
	game.debug_layers = false
	game.player = Vector2(365, 450)
	game.sync_ship()
	for obj in game.targets:
		if obj["kind"] != "launcher": game.damage_target(obj, 99, game.target_box(obj).get_center())
	game.update_atmospherics(0.20)
	game.update_chunks(0.25)
	game._process(0)
	if not await save_frame("01c-wreckage"): return
	game.free()
	print("RENDER CAPTURES PASSED: 4 real engine frames")
	quit(0)

func save_frame(name: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://build/previews/" + name + ".png") != OK:
		push_error("Capture failed " + name)
		quit(1)
		return false
	return true

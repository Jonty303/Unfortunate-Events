extends SceneTree
## Real Compatibility-renderer captures for review; run under Xvfb in CI.
const Game = preload("res://visual_test.gd")
const Overlay = preload("res://touch_controls.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game: Game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(Overlay.TouchMode.ON)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/previews"))
	for factor in [0.85, 1.0, 0.75]:
		game.object_scale = factor
		game.reset_test()
		game.travel = 650.0
		game.mission_time = 6.0
		game.player = Vector2(365, 9999)
		game.ship.advance(0.1, Vector2.ZERO, true)
		game.clamp_player()
		game.previous_player_world = game.player + Vector2(game.travel, 0)
		game.debug_layers = true
		game.fire_cannon()
		game.update_rounds(0.07)
		game._process(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var filename := "res://build/previews/01b-strafe-%d.png" % roundi(factor * 100)
		if root.get_texture().get_image().save_png(filename) != OK:
			push_error("Could not save " + filename)
			quit(1)
			return
	game.object_scale = 0.85
	game.reset_test()
	game.travel = 650.0
	game.player = Vector2(365, 530)
	game.ship.advance(0.1, Vector2(0.5, -0.5), true)
	game.sync_ship()
	game.debug_layers = false
	game.fire_cannon()
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://build/previews/01b-cruise-85.png") != OK:
		quit(1)
		return
	game.free()
	print("RENDER CAPTURES PASSED: 4 real engine frames")
	quit(0)

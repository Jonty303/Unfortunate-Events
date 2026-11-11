extends SceneTree
## 01B regression gates: hit paths, scale, hardpoints, rockets, health and restart.
const Geometry = preload("res://combat_geometry.gd")
const Game = preload("res://visual_test.gd")
const Overlay = preload("res://touch_controls.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func dummy(kind: String, x: float, hp: int = 3) -> Dictionary:
	return {"kind": kind, "x": x, "hp": hp, "dead": false}

func bullet(at: Vector2, velocity: Vector2, friendly: bool = true) -> Dictionary:
	return {"p": at, "v": velocity, "friendly": friendly, "missile": false, "damage": 1, "age": 0.0}

func run_tests() -> void:
	var box := Rect2(100, 20, 50, 40)
	check(is_equal_approx(Geometry.segment_fraction(Vector2(0, 40), Vector2(200, 40), box), 0.5), "Swept hit finds entry even with endpoint beyond target")
	check(Geometry.segment_fraction(Vector2(0, 0), Vector2(200, 0), box) == -1, "Parallel segment misses")
	check(Geometry.segment_fraction(Vector2(120, 40), Vector2(120, 40), box) == 0, "Stationary shot inside box hits")
	check(Geometry.segment_fraction(Vector2.ZERO, Vector2.ZERO, box) == -1, "Stationary shot outside misses")
	check(is_equal_approx(Geometry.segment_fraction(Vector2(200, 40), Vector2.ZERO, box), 0.25), "Reverse diagonal sweep finds entry")
	check(is_equal_approx(Geometry.distance_to_box(Vector2(120, 70), box), 10.0), "Blast uses nearest surface not target centre")
	check(Geometry.blast_damage(0) == 3, "Direct blast has full damage")
	check(Geometry.blast_damage(50) == 2, "Near miss has falloff damage")
	check(Geometry.blast_damage(90) == 1, "Edge splash has reduced damage")
	check(Geometry.blast_damage(100) == 0, "Outside blast radius takes no damage")

	var game: Game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.touch_controls.save_preferences = false
	game.touch_controls.set_mode(Overlay.TouchMode.ON)
	check(is_equal_approx(game.object_scale, 0.85), "Default actors use 85 percent scale")
	var original_touch: Vector2 = game.touch_controls.STICK_CENTRE
	for factor in [1.0, 0.85, 0.75]:
		game.object_scale = factor
		game.reset_test()
		game.player.y = 9999
		game.clamp_player()
		check(game.player.y + game.ship.relative_bounds().end.y <= game.GROUND - 9.99, "Visual underside clears ground at scale %s" % factor)
		for kind in ["tank", "launcher"]:
			game.targets.assign([dummy(kind, 850.0)])
			var target: Rect2 = game.target_box(game.targets[0])
			var muzzle: Vector2 = game.ship.muzzle_point()
			check(muzzle.y > target.position.y and muzzle.y < target.end.y, "Lowest cannon line can hit %s at %s" % [kind, factor])
			game.rounds.clear()
			game.cannon_cooldown = 0
			game.fire_cannon()
			check(game.rounds[0]["p"].is_equal_approx(game.ship.muzzle_point() + Vector2(game.travel, 0)), "Projectile originates at real muzzle")
			game.update_rounds(0.6)
			check(game.targets[0]["hp"] == 2 and game.rounds.is_empty(), "Fast shot hits ground vehicle exactly once")
			check(is_equal_approx(game.target_art_box(game.targets[0]).end.y, game.GROUND), "Rescaled tracks stay on road")
		check(game.touch_controls.STICK_CENTRE == original_touch, "Scaling actors leaves touch UI unchanged")
		for angle in [-0.025, 0.025]:
			game.ship.rotation = angle
			game.player.y = 9999
			game.clamp_player()
			check(game.player.y + game.ship.relative_bounds().end.y <= game.GROUND - 9.99, "Banking remains above ground")
			game.cannon_cooldown = 0
			game.rounds.clear()
			game.fire_cannon()
			var relative_velocity: Vector2 = game.rounds[0]["v"] - Vector2(game.BASE_SCROLL * game.speed_options[game.speed_index], 0)
			check(relative_velocity.normalized().is_equal_approx(game.ship.muzzle_direction()), "Muzzle and projectile heading agree after banking/scaling")

	game.object_scale = 0.85
	game.reset_test()
	game.targets.assign([dummy("tank", 900), dummy("tank", 700)])
	var y: float = game.target_box(game.targets[1]).get_center().y
	game.rounds.append(bullet(Vector2(500, y), Vector2(2500, 0)))
	game.update_rounds(0.3)
	check(game.targets[1]["hp"] == 2 and game.targets[0]["hp"] == 3, "Nearest target wins regardless of array order")

	game.reset_test()
	game.targets.assign([dummy("tank", 800), dummy("tank", 1450)])
	var surface: Rect2 = game.target_box(game.targets[0])
	game.detonate(Vector2(surface.position.x - 50, game.GROUND))
	check(game.targets[0]["hp"] == 1, "Ground near-miss damages adjacent tank")
	check(game.targets[1]["hp"] == 3, "Blast does not damage distant objects")
	game.targets.assign([dummy("facility", 800, 7)])
	surface = game.target_box(game.targets[0])
	game.rounds.clear()
	game.rounds.append({"p": surface.get_center() - Vector2(500, 0), "v": Vector2(2000, 0), "friendly": true, "missile": true, "damage": 3, "age": 0.2, "trail": 0.0})
	game.update_rounds(0.3)
	check(game.targets[0]["hp"] == 4, "Rocket direct hit applies damage once, not direct plus splash")

	game.reset_test()
	game.fire_missile()
	check(game.rounds[0]["p"].is_equal_approx(game.ship.rocket_point()), "Rocket releases from the belly rail")
	game.update_rounds(0.05)
	check(game.rounds[0]["age"] < 0.12 and game.rounds[0]["v"].x < 400, "Rocket drops clear before ignition")
	game.update_rounds(0.08)
	check(game.rounds[0]["v"].x > 700 and game.rounds[0]["v"].y > 172, "Rocket ignites into unguided downward arc")

	game.reset_test()
	game.previous_player_world = game.player
	game.rounds.append(bullet(game.player + Vector2(300, 0), Vector2(-3000, 0), false))
	game.update_rounds(0.2)
	check(game.hull == 4, "Swept hostile shot reduces real hull")
	game.damage_player(1, game.player)
	check(game.hull == 4, "Short invulnerability prevents stacked contact damage")
	game.invulnerable = 0
	game.damage_player(4, game.player)
	check(game.destroyed and game.hull == 0 and not game.ship.visible, "Zero hull destroys ship")
	check(not game.touch_controls.fire_held and game.touch_controls.game_paused, "Death releases touch input")
	game.fire_cannon()
	check(game.rounds.is_empty(), "Destroyed ship cannot fire")
	game.reset_test()
	check(game.hull == 5 and not game.destroyed and game.ship.visible and not game.paused, "Restart restores hull and ship")

	# Relative motion: a stationary hostile round is hit by the moving player.
	game.previous_player_world = game.player - Vector2(300, 0)
	game.rounds.append(bullet(game.player - Vector2(150, 0), Vector2.ZERO, false))
	game.update_rounds(0.01)
	check(game.hull == 4, "Relative sweep detects player crossing a projectile")
	game.reset_test()
	game.player.y = 9999
	game.clamp_player()
	game.targets.assign([dummy("tank", game.player.x + 280)])
	game.touch_controls.press_pointer(30, game.touch_controls.STICK_CENTRE + Vector2(86, 0))
	game._process(0.25)
	game._process(0.25)
	check(game.hull < 5, "Hull contact with ground targets causes damage")
	game.reset_test()
	game.touch_controls.press_pointer(31, game.touch_controls.FIRE_CENTRE)
	game._process(0.25)
	check(game.rounds.size() == 2, "Cannon cadence is maintained through bounded frame-drop substeps")
	var travel_before := game.travel
	var engine_before: float = game.ship.engine_time
	game.toggle_pause()
	game._process(0.1)
	check(is_equal_approx(game.travel, travel_before) and is_equal_approx(game.ship.engine_time, engine_before), "Pause freezes world and attached engine FX")
	game.reset_test()
	game.ship.advance(0.1, Vector2.LEFT, true)
	check(game.ship.thrust >= 1, "Backward screen movement retains cruise exhaust")
	game.cycle_scale()
	check(is_equal_approx(game.object_scale, 0.75) and game.travel == 0 and game.hull == 5, "Scale comparison restarts identical encounter")
	game.free()
	if failures.is_empty():
		print("COMBAT TESTS PASSED: %d checks" % checks)
		quit(0)
	else:
		print("COMBAT TESTS FAILED: %d / %d" % [failures.size(), checks])
		quit(1)

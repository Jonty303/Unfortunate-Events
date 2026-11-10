extends SceneTree
var game: Node
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error("FAIL: " + message)
		failures += 1
	checks += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.state == "title", "title screen")
	game.start()
	var press := InputEventKey.new()
	press.physical_keycode = KEY_Z
	press.pressed = true
	for i in range(25): game._input(press)
	check(game.shots.size() == 25, "25 cannon presses within one frame yield 25 shots")
	press.echo = true
	game._input(press)
	check(game.shots.size() == 25, "OS key repeat is ignored")
	game.paused = true
	game.fire_cannon()
	check(game.shots.size() == 25, "pause blocks weapons")
	game.start()
	game.spawn_enemy("fighter", Vector2(200, 155))
	game.fire_cannon()
	for i in range(10): game.step(1.0 / 60, Vector2.ZERO)
	check(game.enemies[0].hp == 1, "swept cannon collision damages fighter")
	game.start()
	game.elapsed = 45
	game.next_event = game.events.size()
	game.player = Vector2(90, 302)
	game.spawn_enemy("tank", Vector2(180, 308))
	game.fire_missile()
	game.fire_missile()
	check(game.shots.size() == 1, "missile reload")
	for i in range(30): game.step(1.0 / 60, Vector2.ZERO)
	check(game.kills == 1 and game.enemies.is_empty(), "forward missile destroys ground tank")
	game.start()
	game.hurt()
	game.hurt()
	check(game.hull == 4, "temporary protection prevents stacked damage")
	for i in range(4):
		game.invulnerable = 0
		game.hurt()
	check(game.state == "destroyed", "destruction screen")
	game.start()
	check(game.hull == 5 and game.elapsed == 0 and game.shots.is_empty(), "restart resets sortie")
	game.step(1, Vector2(-1, -1))
	check(game.player.x >= 20 and game.player.y >= 42, "movement bounds")
	game.start()
	var saw_tank := false
	var saw_launcher := false
	var saw_enemy_shot := false
	for i in range(4801):
		game.invulnerable = 100 # Only the test pilot is protected; gameplay is unchanged.
		game.step(1.0 / 60, Vector2.ZERO)
		for enemy in game.enemies:
			saw_tank = saw_tank or enemy.kind == "tank"
			saw_launcher = saw_launcher or enemy.kind == "launcher"
		for shot in game.shots:
			saw_enemy_shot = saw_enemy_shot or not shot.friendly
	check(saw_tank and saw_launcher and saw_enemy_shot, "full schedule spawns ground units and enemy fire")
	check(game.state == "complete", "80-second end loop")
	check(is_equal_approx(game.ground_y(), 318), "terrain transition completes")
	game.start()
	game.elapsed = 45
	game.player.y = 320
	game.step(1.0 / 60, Vector2.ZERO)
	check(game.hull == 4 and game.player.y == 310, "terrain collision")
	game.start()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	for i in range(20): game._input(pad)
	check(game.shots.size() == 20, "joypad cannon presses are uncapped")
	pad.button_index = JOY_BUTTON_START
	game._input(pad)
	check(game.paused, "joypad pause")
	game._input(pad)
	check(not game.paused, "joypad resume")
	game.start()
	game.pickups.append({"p": game.player, "kind": "C"})
	game.step(1.0 / 60, Vector2.ZERO)
	check(game.cannon_level == 2 and game.pickups.is_empty(), "capsule collection")
	game.fire_cannon()
	check(game.shots.size() == 2, "twin cannon")
	game.shots.clear()
	game.collect_pickup("C")
	game.collect_pickup("C")
	game.fire_cannon()
	check(game.cannon_level == 3 and game.shots.size() == 3 and game.shots[1].v.y < 0 and game.shots[2].v.y > 0, "capped three-way cannon")
	game.shots.clear()
	game.collect_pickup("M")
	pad.button_index = JOY_BUTTON_B
	game._input(pad)
	check(game.shots.size() == 2 and game.shots[0].v.y == 0 and game.shots[1].v.y == 0, "joypad twin unguided missiles")
	game.shots.clear()
	game.missile_wait = 0
	game.collect_pickup("M")
	game.collect_pickup("M")
	game.fire_missile()
	check(game.missile_level == 3 and game.shots[0].damage == 6 and game.shots[1].damage == 6 and game.missile_wait < 0.3, "heavy missiles and faster reload")
	game.start()
	check(game.cannon_level == 1 and game.missile_level == 1 and game.pickups.is_empty(), "restart clears upgrades")
	check(game.sounds.size() == 8 and game.sounds.cannon.data.size() > 1000, "generated sound effects")
	print("Connected joypads: ", Input.get_connected_joypads())
	print("RESULT: %d gameplay checks, %d failures" % [checks, failures])
	game._exit_tree()
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

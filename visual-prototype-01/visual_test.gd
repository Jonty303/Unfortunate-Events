extends Node2D
## Isolated Visual Prototype 01. Art-quality and layered rendering test, NOT a new game iteration.
## 1920x1080 authored space; consistent world coordinates for road targets and projectiles.
const W := 1920.0
const H := 1080.0
const GROUND := 823.0
const BASE_SCROLL := 145.0
const PLAYER_SPEED := 445.0
const CANNON_PERIOD := 0.13
const MISSILE_PERIOD := 0.78
const Layer = preload("res://parallax_layer.gd")
const TouchOverlay = preload("res://touch_controls.gd")
const SHIP = preload("res://art/06_antique_shuttle.png")
const TANK = preload("res://art/07_tank.png")
const LAUNCHER = preload("res://art/08_launcher.png")
const FACILITY = preload("res://art/09_facility.png")
const HANGAR = preload("res://art/10_hangar.png")
const SKY = preload("res://art/01_atmosphere.png")
const RIDGES = preload("res://art/02_far_mountains.png")
const VALLEY = preload("res://art/03_mid_valley.png")
const NEAR_FOREST = preload("res://art/03b_near_forest.png")
const ROAD = preload("res://art/04_road.png")
const ROCKS = preload("res://art/05_near_rocks.png")
const CYAN := Color(0.35, 0.88, 1.0)
const ORANGE := Color(1.0, 0.63, 0.28)
var travel := 0.0
var player := Vector2(365, 440)
var cannon_cooldown := 0.0
var missile_cooldown := 0.0
var enemy_cooldown := 2.3
var mission_time := 0.0
var paused := false
var debug_layers := false
var speed_index := 0
var speed_options := [1.0, 0.5, 2.0]
var planes: Array[Node2D] = []
var targets: Array[Dictionary] = []
var rounds: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var label_status: Label
var label_help: Label
var label_debug: Label
var rng := RandomNumberGenerator.new()
var touch_controls: TouchOverlay

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rng.seed = 71426
	add_plane(SKY, 0.025, 0, -100)
	add_plane(RIDGES, 0.18, 78, -90)
	add_plane(VALLEY, 0.44, 320, -80)
	add_plane(NEAR_FOREST, 0.72, 525, -75)
	add_plane(ROAD, 1.0, 790, -70)
	add_plane(ROCKS, 1.17, 888, 50)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	label_status = make_label(hud, Vector2(30, 19), 24, Color("d4ebf1"))
	label_help = make_label(hud, Vector2(32, 1041), 20, Color(0.86, 0.91, 0.95, 0.9))
	label_debug = make_label(hud, Vector2(1430, 26), 20, CYAN)
	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 20
	add_child(touch_layer)
	touch_controls = TouchOverlay.new()
	touch_layer.add_child(touch_controls)
	touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_controls.pause_requested.connect(toggle_pause)
	touch_controls.restart_requested.connect(reset_test)
	touch_controls.debug_requested.connect(toggle_debug)
	touch_controls.speed_requested.connect(cycle_speed)
	reset_test()

func add_plane(texture: Texture2D, fraction: float, y: float, z: int) -> void:
	var plane := Layer.new()
	add_child(plane)
	plane.configure(texture, fraction, y, z)
	planes.append(plane)

func make_label(parent: Node, at: Vector2, size: int, tint: Color) -> Label:
	var ui := Label.new()
	ui.position = at
	ui.add_theme_font_size_override("font_size", size)
	ui.add_theme_color_override("font_color", tint)
	ui.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.07, 0.9))
	ui.add_theme_constant_override("shadow_offset_x", 2)
	ui.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(ui)
	return ui

func reset_test() -> void:
	travel = 0.0
	mission_time = 0.0
	player = Vector2(365, 440)
	cannon_cooldown = 0.0
	missile_cooldown = 0.0
	enemy_cooldown = 2.3
	paused = false
	if is_instance_valid(touch_controls):
		touch_controls.release_all()
		touch_controls.set_game_paused(false)
	rounds.clear()
	particles.clear()
	targets = [
		{"kind": "hangar", "x": -270.0, "hp": 99, "dead": false},
		{"kind": "tank", "x": 1450.0, "hp": 3, "dead": false},
		{"kind": "facility", "x": 2130.0, "hp": 7, "dead": false},
		{"kind": "launcher", "x": 3200.0, "hp": 3, "dead": false},
		{"kind": "tank", "x": 4070.0, "hp": 3, "dead": false},
		{"kind": "facility", "x": 4910.0, "hp": 7, "dead": false}
	]
	update_labels()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_P, KEY_ESCAPE:
				toggle_pause()
			KEY_R:
				reset_test()
			KEY_F1:
				toggle_debug()
			KEY_F2:
				cycle_speed()
			KEY_T:
				touch_controls.cycle_mode()

func toggle_pause() -> void:
	paused = not paused
	touch_controls.set_game_paused(paused)

func toggle_debug() -> void:
	debug_layers = not debug_layers

func cycle_speed() -> void:
	speed_index = (speed_index + 1) % speed_options.size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(touch_controls):
			paused = true
			touch_controls.set_game_paused(true)
			touch_controls.release_all()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			toggle_pause()
		elif event.button_index == JOY_BUTTON_Y and paused:
			reset_test()

func control_axis() -> Vector2:
	var axis := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	for device in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.19:
			axis += stick.limit_length()
		axis += Vector2(
			float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)),
			float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP))
		)
	axis += touch_controls.movement
	return axis.limit_length()

func pad_pressed(button: int) -> bool:
	for device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device, button):
			return true
	return false

func _process(delta: float) -> void:
	if not paused:
		var d := minf(delta, 0.05)
		mission_time += d
		travel += BASE_SCROLL * speed_options[speed_index] * d
		player += control_axis() * PLAYER_SPEED * d
		player.x = clampf(player.x, 135, W - 260)
		player.y = clampf(player.y, 150, GROUND - 135)
		cannon_cooldown = maxf(0.0, cannon_cooldown - d)
		missile_cooldown = maxf(0.0, missile_cooldown - d)
		var mouse_allowed: bool = not touch_controls.blocks_mouse_fire()
		if (Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_SPACE) or (mouse_allowed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) or pad_pressed(JOY_BUTTON_A) or touch_controls.fire_held) and cannon_cooldown <= 0:
			fire_cannon()
		if (Input.is_key_pressed(KEY_X) or (mouse_allowed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or pad_pressed(JOY_BUTTON_B) or pad_pressed(JOY_BUTTON_RIGHT_SHOULDER) or touch_controls.rocket_held) and missile_cooldown <= 0:
			fire_missile()
		enemy_cooldown -= d
		if enemy_cooldown <= 0:
			enemy_cooldown = 2.35
			for obj in targets:
				if obj["dead"] or obj["kind"] not in ["tank", "launcher"]:
					continue
				var sx: float = obj["x"] - travel
				if sx > 320 and sx < W - 50:
					rounds.append({"p": Vector2(obj["x"] - 32, GROUND - 67), "v": Vector2(-430, -90), "friendly": false, "missile": false, "damage": 1})
					break
		update_rounds(d)
		update_particles(d)
	for plane in planes:
		plane.set_travel(travel)
	update_labels()
	queue_redraw()

func fire_cannon() -> void:
	cannon_cooldown = CANNON_PERIOD
	rounds.append({"p": Vector2(travel + player.x + 105, player.y - 8), "v": Vector2(1250, 0), "friendly": true, "missile": false, "damage": 1})
	spawn_sparks(Vector2(travel + player.x + 103, player.y - 8), CYAN, 3)

func fire_missile() -> void:
	missile_cooldown = MISSILE_PERIOD
	rounds.append({"p": Vector2(travel + player.x + 12, player.y + 37), "v": Vector2(675, 172), "friendly": true, "missile": true, "damage": 3})

func target_box(obj: Dictionary) -> Rect2:
	var x: float = obj["x"]
	match obj["kind"]:
		"tank": return Rect2(x - 110, GROUND - 91, 205, 92)
		"launcher": return Rect2(x - 118, GROUND - 127, 223, 132)
		"facility": return Rect2(x - 195, GROUND - 284, 365, 284)
	return Rect2(x - 350, GROUND - 500, 700, 500)

func update_rounds(d: float) -> void:
	for i in range(rounds.size() - 1, -1, -1):
		var shot := rounds[i]
		var velocity: Vector2 = shot["v"]
		if shot["missile"]:
			velocity.y += 380.0 * d
		shot["v"] = velocity
		shot["p"] = shot["p"] + velocity * d
		var pos: Vector2 = shot["p"]
		var struck := false
		if shot["friendly"]:
			for obj in targets:
				if obj["dead"] or obj["kind"] == "hangar":
					continue
				if target_box(obj).grow(8).has_point(pos):
					obj["hp"] = obj["hp"] - shot["damage"]
					spawn_sparks(pos, ORANGE, 15 if shot["missile"] else 6)
					if obj["hp"] <= 0:
						obj["dead"] = true
						spawn_sparks(Vector2(obj["x"], GROUND - 90), ORANGE, 65)
					struck = true
					break
			if pos.y >= GROUND:
				spawn_sparks(Vector2(pos.x, GROUND), ORANGE, 12)
				struck = true
		else:
			var relative := pos - Vector2(travel + player.x, player.y)
			if absf(relative.x) < 90 and absf(relative.y) < 40:
				spawn_sparks(pos, ORANGE, 8)
				struck = true
		if struck or pos.x < travel - 120 or pos.x > travel + W + 150 or pos.y > H + 50:
			rounds.remove_at(i)

func spawn_sparks(pos: Vector2, tint: Color, count: int) -> void:
	for j in range(count):
		var speed := rng.randf_range(48.0, 380.0)
		var a := rng.randf_range(0.0, TAU)
		particles.append({"p": pos, "v": Vector2.RIGHT.rotated(a) * speed, "life": rng.randf_range(0.23, 1.05), "color": tint})
	if particles.size() > 500:
		particles = particles.slice(particles.size() - 500)

func update_particles(d: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] = particles[i]["life"] - d
		var velocity: Vector2 = particles[i]["v"]
		velocity.y += 300.0 * d
		particles[i]["v"] = velocity
		particles[i]["p"] = particles[i]["p"] + velocity * d
		if particles[i]["life"] <= 0:
			particles.remove_at(i)

func render_target(obj: Dictionary) -> void:
	if obj["dead"]:
		return
	var sx: float = obj["x"] - travel
	if sx < -800 or sx > W + 800:
		return
	match obj["kind"]:
		"hangar":
			draw_texture_rect(HANGAR, Rect2(sx - 60, GROUND - 532, 720, 540), false)
		"tank":
			draw_texture_rect(TANK, Rect2(sx - 122, GROUND - 108, 240, 108), false)
		"launcher":
			draw_texture_rect(LAUNCHER, Rect2(sx - 127, GROUND - 160, 254, 160), false)
		"facility":
			draw_texture_rect(FACILITY, Rect2(sx - 208, GROUND - 289, 410, 289), false)

func render_round(shot: Dictionary) -> void:
	var tip: Vector2 = shot["p"] - Vector2(travel, 0)
	var vel: Vector2 = shot["v"]
	if shot["missile"]:
		var direction := vel.normalized()
		var tail := tip - direction * 64
		draw_line(tail, tip, Color(1.0, 0.39, 0.08, 0.14), 27)
		draw_line(tail, tip, Color(1.0, 0.72, 0.19, 0.8), 7)
		draw_colored_polygon(PackedVector2Array([tip + direction * 23, tip + Vector2(-13, -8), tip - direction * 22, tip + Vector2(-13, 8)]), Color("e6e8df"))
	elif shot["friendly"]:
		draw_line(tip - Vector2(80, 0), tip, Color(0.1, 0.7, 1.0, 0.19), 21)
		draw_line(tip - Vector2(62, 0), tip, Color(0.17, 0.76, 1.0, 0.65), 8)
		draw_line(tip - Vector2(39, 0), tip, Color("e9feff"), 3)
		draw_circle(tip, 7, Color("f0feff"))
	else:
		draw_line(tip - vel.normalized() * 45, tip, Color(1.0, 0.18, 0.12, 0.3), 14)
		draw_line(tip - vel.normalized() * 29, tip, Color("ff7254"), 5)
		draw_circle(tip, 5, Color("ffddaa"))

func _draw() -> void:
	for obj in targets:
		render_target(obj)
	# Muzzle/engine glow is behind the shuttle, but after world targets.
	var rear := player - Vector2(113, -8)
	draw_line(rear, rear - Vector2(75 + sin(mission_time * 37) * 11, 0), Color(0.13, 0.75, 1.0, 0.25), 27)
	draw_line(rear, rear - Vector2(55 + sin(mission_time * 42) * 10, 0), Color(0.6, 0.94, 1.0, 0.95), 7)
	draw_texture_rect(SHIP, Rect2(player - Vector2(120, 68), Vector2(238, 137)), false)
	for shot in rounds:
		render_round(shot)
	for debris in particles:
		var alpha: float = clampf(debris["life"], 0.0, 1.0)
		var tint: Color = debris["color"]
		tint.a = alpha
		draw_circle(debris["p"] - Vector2(travel, 0), 2.4 + alpha * 3, tint)
	if debug_layers:
		draw_line(Vector2(0, GROUND), Vector2(W, GROUND), Color(1.0, 0.9, 0.25, 0.65), 2)
		draw_rect(Rect2(112, 82, W - 224, GROUND - 82), Color(CYAN, 0.22), false, 2)
		for obj in targets:
			if not obj["dead"] and obj["kind"] != "hangar":
				var box := target_box(obj)
				box.position.x -= travel
				draw_rect(box, Color(1.0, 0.85, 0.18, 0.8), false, 2)

func update_labels() -> void:
	label_status.text = "UNFORTUNATE EVENTS   /   VISUAL PROTOTYPE 01    |    HULL 5    |    MISSILE %s    |    %02ds" % ["READY" if missile_cooldown <= 0 else "RELOADING", int(mission_time)]
	label_help.text = "WASD / STICK  MOVE     Z / SPACE / A  CANNON     X / B  ROCKET     P  PAUSE     R  RESET     F1  LAYERS     F2  SCROLL" + ("     [PAUSED]" if paused else "")
	label_status.text += "   [PAUSED]" if paused else ""
	label_help.visible = not touch_controls.controls_visible()
	label_help.text += "    T TOUCH"
	label_debug.position = Vector2(1205, 95)
	label_debug.visible = debug_layers
	if debug_layers:
		label_debug.text = "WORLD %.0f  |  SCROLL %.1fx\nSKY 2.5%%  /  RIDGES 18%%\nVALLEY 44%%  /  ROAD 100%%\nFOREGROUND 117%%" % [travel, speed_options[speed_index]]

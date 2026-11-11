extends Node2D
## Visual Prototype 01B: scale, mounted weapons, ground combat and hull feedback.
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
const Shuttle = preload("res://player_ship.tscn")
const ShipPresentation = preload("res://player_ship.gd")
const Geometry = preload("res://combat_geometry.gd")
const SCALE_OPTIONS := [1.0, 0.85, 0.75]
const MAX_HULL := 5
const BLAST_RADIUS := 100.0
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
var ship: ShipPresentation
var scale_index := 1
var object_scale := 0.85
var hull := MAX_HULL
var invulnerable := 0.0
var destroyed := false
var kills := 0
var target_cursor := 0
var smoke_timer := 0.0
var blasts: Array[Dictionary] = []
var smoke: Array[Dictionary] = []
var scale_button: Button
var previous_player_world := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rng.seed = 71426
	add_plane(SKY, 0.025, 0, -100)
	add_plane(RIDGES, 0.18, 78, -90)
	add_plane(VALLEY, 0.44, 320, -80)
	add_plane(NEAR_FOREST, 0.72, 525, -75)
	add_plane(ROAD, 1.0, 790, -70)
	add_plane(ROCKS, 1.17, 888, 50)
	ship = Shuttle.instantiate()
	add_child(ship)
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
	scale_button = Button.new()
	scale_button.position = Vector2(1220, 190)
	scale_button.size = Vector2(236, 60)
	scale_button.focus_mode = Control.FOCUS_NONE
	scale_button.add_theme_font_size_override("font_size", 23)
	scale_button.pressed.connect(cycle_scale)
	hud.add_child(scale_button)
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
	destroyed = false
	hull = MAX_HULL
	invulnerable = 0.0
	kills = 0
	target_cursor = 0
	smoke_timer = 0.0
	blasts.clear()
	smoke.clear()
	rng.seed = 71426
	ship.reset_visuals()
	ship.scale = Vector2.ONE * object_scale
	ship.position = player
	previous_player_world = player
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
			KEY_F3:
				cycle_scale()
			KEY_T:
				touch_controls.cycle_mode()

func toggle_pause() -> void:
	if destroyed:
		return
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
	# Native Control buttons need an explicit touch path because mouse emulation
	# is disabled to prevent a joystick finger also firing the cannon.
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		if debug_layers and scale_button.get_global_rect().has_point(event.position):
			cycle_scale()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			toggle_pause()
		elif event.button_index == JOY_BUTTON_Y and (paused or destroyed):
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

func cycle_scale() -> void:
	scale_index = (scale_index + 1) % SCALE_OPTIONS.size()
	object_scale = SCALE_OPTIONS[scale_index]
	# A/B comparison restarts the identical encounter; this is not a camera zoom.
	reset_test()

func sync_ship() -> void:
	ship.position = player
	ship.scale = Vector2.ONE * object_scale
	ship.visible = not destroyed

func clamp_player() -> void:
	var bounds: Rect2 = ship.relative_bounds()
	player.x = clampf(player.x, 24.0 - bounds.position.x, W - 28.0 - bounds.end.x)
	player.y = clampf(player.y, 116.0 - bounds.position.y, GROUND - 10.0 - bounds.end.y)
	sync_ship()

func player_box() -> Rect2:
	var box: Rect2 = ship.local_hit_box()
	box.position += Vector2(travel + player.x, player.y)
	return box

func _process(delta: float) -> void:
	if not paused:
		# Bounded substeps keep arcs and cooldowns consistent through ordinary frame drops.
		var remaining := minf(delta, 0.25)
		while remaining > 0.000001:
			var dt := minf(remaining, 1.0 / 120.0)
			if not destroyed:
				step_combat(dt)
			update_particles(dt)
			update_atmospherics(dt)
			remaining -= dt
	for plane in planes:
		plane.set_travel(travel)
	update_labels()
	queue_redraw()

func step_combat(dt: float) -> void:
	previous_player_world = Vector2(travel + player.x, player.y)
	mission_time += dt
	travel += BASE_SCROLL * speed_options[speed_index] * dt
	var axis := control_axis()
	player += axis * PLAYER_SPEED * dt
	invulnerable = maxf(0.0, invulnerable - dt)
	cannon_cooldown = maxf(0.0, cannon_cooldown - dt)
	missile_cooldown = maxf(0.0, missile_cooldown - dt)
	ship.advance(dt, axis, missile_cooldown <= 0)
	clamp_player()
	var mouse_allowed: bool = not touch_controls.blocks_mouse_fire()
	if scale_button.visible and scale_button.get_global_rect().has_point(get_global_mouse_position()):
		mouse_allowed = false
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_SPACE) or (mouse_allowed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) or pad_pressed(JOY_BUTTON_A) or touch_controls.fire_held:
		fire_cannon()
	if Input.is_key_pressed(KEY_X) or (mouse_allowed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or pad_pressed(JOY_BUTTON_B) or pad_pressed(JOY_BUTTON_RIGHT_SHOULDER) or touch_controls.rocket_held:
		fire_missile()
	enemy_cooldown -= dt
	if enemy_cooldown <= 0:
		enemy_cooldown = 2.35
		fire_enemy()
	update_rounds(dt)
	# Swept hull contact prevents flying through a smaller building during a long frame.
	if not destroyed:
		var half: Vector2 = ship.local_hit_box().size * 0.5
		var centre: Vector2 = ship.local_hit_box().get_center()
		for obj in targets:
			if obj["dead"] or obj["kind"] == "hangar":
				continue
			var box := target_box(obj)
			box = Rect2(box.position - half, box.size + half * 2.0)
			if Geometry.segment_fraction(previous_player_world + centre, Vector2(travel + player.x, player.y) + centre, box) >= 0:
				damage_player(1, Vector2(travel + player.x, player.y))
				break
	if hull <= 2 and not destroyed:
		smoke_timer -= dt
		if smoke_timer <= 0:
			smoke_timer = 0.12
			add_smoke(ship.engine_lower.global_position + Vector2(travel, 0), Vector2(-45, -25), 1.0, 9.0)

func fire_cannon() -> void:
	if paused or destroyed or cannon_cooldown > 0 or rounds.size() >= 128:
		return
	cannon_cooldown = CANNON_PERIOD
	ship.fire()
	var origin: Vector2 = ship.muzzle_point() + Vector2(travel, 0)
	var velocity: Vector2 = ship.muzzle_direction() * 1250.0 + Vector2(BASE_SCROLL * speed_options[speed_index], 0)
	rounds.append({"p": origin, "v": velocity, "friendly": true, "missile": false, "damage": 1, "age": 0.0})

func fire_missile() -> void:
	if paused or destroyed or missile_cooldown > 0 or rounds.size() >= 128:
		return
	missile_cooldown = MISSILE_PERIOD
	ship.rocket_ready = false
	var scrolling: float = BASE_SCROLL * speed_options[speed_index]
	rounds.append({"p": ship.rocket_point() + Vector2(travel, 0), "v": Vector2(scrolling + 150.0, 70), "cruise": scrolling + 675.0, "friendly": true, "missile": true, "damage": 3, "age": 0.0, "trail": 0.0})

func fire_enemy() -> void:
	if rounds.size() >= 128:
		return
	for offset in range(targets.size()):
		var index := (target_cursor + offset) % targets.size()
		var obj := targets[index]
		if obj["dead"] or obj["kind"] not in ["tank", "launcher"]:
			continue
		var sx: float = obj["x"] - travel
		if sx < player.x + 270 or sx > W - 60:
			continue
		var origin := Vector2(obj["x"], GROUND) + Vector2(-35, -67) * object_scale
		var velocity := (Vector2(travel + player.x, player.y) - origin).normalized() * 440.0
		rounds.append({"p": origin, "v": velocity, "friendly": false, "missile": false, "damage": 1, "age": 0.0})
		spawn_sparks(origin, ORANGE, 3)
		target_cursor = (index + 1) % targets.size()
		break

func target_box(obj: Dictionary) -> Rect2:
	var local_box := Rect2(-350, -500, 700, 500)
	match obj["kind"]:
		"tank": local_box = Rect2(-110, -91, 205, 91)
		"launcher": local_box = Rect2(-118, -127, 223, 127)
		"facility": local_box = Rect2(-195, -284, 365, 284)
	return Rect2(Vector2(obj["x"], GROUND) + local_box.position * object_scale, local_box.size * object_scale)

func target_art_box(obj: Dictionary) -> Rect2:
	var local_box := Rect2(-60, -540, 720, 540)
	match obj["kind"]:
		"tank": local_box = Rect2(-122, -108, 240, 108)
		"launcher": local_box = Rect2(-127, -160, 254, 160)
		"facility": local_box = Rect2(-208, -289, 410, 289)
	return Rect2(Vector2(obj["x"] - travel, GROUND) + local_box.position * object_scale, local_box.size * object_scale)

func update_rounds(dt: float) -> void:
	for i in range(rounds.size() - 1, -1, -1):
		var shot := rounds[i]
		var start: Vector2 = shot["p"]
		var velocity: Vector2 = shot["v"]
		var old_age: float = shot.get("age", 0.0)
		shot["age"] = old_age + dt
		if shot["missile"]:
			# Drop from the rail first, then ignite: deliberately unguided.
			if old_age < 0.12 and shot["age"] >= 0.12:
				velocity.x = shot.get("cruise", 820.0)
				velocity.y = maxf(velocity.y, 172.0)
			velocity.y += 380.0 * dt
			shot["trail"] = float(shot.get("trail", 0.0)) - dt
			if shot["age"] >= 0.12 and shot["trail"] <= 0:
				shot["trail"] = 0.04
				add_smoke(start, Vector2(-12, -8), 0.42, 3.0)
		shot["v"] = velocity
		var finish := start + velocity * dt
		var earliest := 2.0
		var target_index := -1
		var radius := 4.0 if shot["missile"] else 3.0
		if shot["friendly"]:
			for j in range(targets.size()):
				var obj := targets[j]
				if obj["dead"] or obj["kind"] == "hangar":
					continue
				var t: float = Geometry.segment_fraction(start, finish, target_box(obj).grow(radius))
				if t >= 0 and t < earliest:
					earliest = t
					target_index = j
		elif not destroyed:
			# Relative motion sweep accounts for the player's movement as well as the bullet.
			var t: float = Geometry.segment_fraction(start - previous_player_world, finish - Vector2(travel + player.x, player.y), ship.local_hit_box().grow(radius))
			if t >= 0:
				earliest = t
				target_index = -2
		if finish.y >= GROUND and finish.y > start.y:
			var ground_t := clampf((GROUND - start.y) / (finish.y - start.y), 0.0, 1.0)
			if ground_t < earliest:
				earliest = ground_t
				target_index = -1
		var struck := earliest <= 1.0
		shot["p"] = start.lerp(finish, earliest) if struck else finish
		if struck:
			var impact: Vector2 = shot["p"]
			if shot["friendly"] and shot["missile"]:
				detonate(impact)
			elif target_index >= 0:
				damage_target(targets[target_index], int(shot["damage"]), impact)
			elif target_index == -2:
				damage_player(int(shot["damage"]), impact)
			else:
				spawn_sparks(impact, ORANGE, 6)
		if struck or shot["age"] > 5.0 or finish.x < travel - 150 or finish.x > travel + W + 200 or finish.y > H + 50 or finish.y < -100:
			rounds.remove_at(i)

func damage_target(obj: Dictionary, damage: int, at: Vector2) -> void:
	if obj["dead"] or damage <= 0:
		return
	obj["hp"] = maxi(0, int(obj["hp"]) - damage)
	obj["flash"] = 0.12
	spawn_sparks(at, ORANGE, 8)
	if obj["hp"] == 0:
		obj["dead"] = true
		kills += 1
		var centre := target_box(obj).get_center()
		spawn_sparks(centre, ORANGE, 42)
		blasts.append({"p": centre, "age": 0.0, "radius": 48.0 * object_scale})
		add_smoke(centre, Vector2(0, -26), 1.25, 20.0)

func detonate(at: Vector2) -> void:
	# One blast application per target; do not double-count direct + splash damage.
	for obj in targets:
		if obj["dead"] or obj["kind"] == "hangar":
			continue
		var distance: float = Geometry.distance_to_box(at, target_box(obj))
		damage_target(obj, Geometry.blast_damage(distance, BLAST_RADIUS), at)
	spawn_sparks(at, ORANGE, 24)
	blasts.append({"p": at, "age": 0.0, "radius": BLAST_RADIUS})
	add_smoke(at, Vector2(0, -35), 0.8, 13.0)
	if blasts.size() > 32:
		blasts = blasts.slice(blasts.size() - 32)

func damage_player(amount: int, at: Vector2) -> void:
	if destroyed or invulnerable > 0 or amount <= 0:
		return
	hull = maxi(0, hull - amount)
	invulnerable = 0.85
	ship.hit()
	spawn_sparks(at, Color("d8c7a3"), 12)
	if hull == 0:
		destroyed = true
		ship.visible = false
		touch_controls.set_game_paused(true)
		touch_controls.release_all()
		spawn_sparks(Vector2(travel + player.x, player.y), ORANGE, 60)
		blasts.append({"p": Vector2(travel + player.x, player.y), "age": 0.0, "radius": 90.0})

func add_smoke(at: Vector2, velocity: Vector2, lifetime: float, radius: float) -> void:
	smoke.append({"p": at, "v": velocity, "life": lifetime, "total": lifetime, "radius": radius})
	if smoke.size() > 64:
		smoke.remove_at(0)

func update_atmospherics(dt: float) -> void:
	for i in range(smoke.size() - 1, -1, -1):
		var puff := smoke[i]
		puff["life"] -= dt
		puff["p"] += puff["v"] * dt
		if puff["life"] <= 0:
			smoke.remove_at(i)
	for i in range(blasts.size() - 1, -1, -1):
		blasts[i]["age"] += dt
		if blasts[i]["age"] >= 0.3:
			blasts.remove_at(i)
	for obj in targets:
		obj["flash"] = maxf(0.0, float(obj.get("flash", 0.0)) - dt)

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
	var rect := target_art_box(obj)
	if rect.end.x < -40 or rect.position.x > W + 40:
		return
	if obj["dead"]:
		# Small persistent wreck silhouette marks the destroyed object's world anchor.
		draw_rect(Rect2(rect.position.x, GROUND - 9.0 * object_scale, rect.size.x, 9.0 * object_scale), Color("343c3c"))
		return
	var texture: Texture2D = HANGAR
	match obj["kind"]:
		"tank": texture = TANK
		"launcher": texture = LAUNCHER
		"facility": texture = FACILITY
	draw_texture_rect(texture, rect, false, Color(1.0, 0.65, 0.40) if float(obj.get("flash", 0.0)) > 0 else Color.WHITE)

func render_round(shot: Dictionary) -> void:
	var tip: Vector2 = shot["p"] - Vector2(travel, 0)
	var vel: Vector2 = shot["v"]
	if shot["missile"]:
		var direction := vel.normalized()
		var normal := direction.orthogonal()
		if float(shot.get("age", 0.0)) >= 0.12:
			draw_line(tip - direction * 62, tip - direction * 19, Color(1.0, 0.39, 0.08, 0.18), 18, true)
			draw_line(tip - direction * 49, tip - direction * 19, Color(1.0, 0.79, 0.42, 0.9), 5, true)
		draw_colored_polygon(PackedVector2Array([tip + direction * 23, tip + direction * 9 + normal * 5, tip - direction * 22 + normal * 5, tip - direction * 22 - normal * 5, tip + direction * 9 - normal * 5]), Color("e6e8df"))
		draw_line(tip - normal * 5, tip + normal * 5, Color("a65035"), 5)
	elif shot["friendly"]:
		var direction := vel.normalized()
		draw_line(tip - direction * 80, tip, Color(0.1, 0.7, 1.0, 0.19), 21, true)
		draw_line(tip - direction * 62, tip, Color(0.17, 0.76, 1.0, 0.65), 8, true)
		draw_line(tip - direction * 39, tip, Color("e9feff"), 3, true)
		draw_circle(tip, 7, Color("f0feff"))
	else:
		draw_line(tip - vel.normalized() * 45, tip, Color(1.0, 0.18, 0.12, 0.3), 14)
		draw_line(tip - vel.normalized() * 29, tip, Color("ff7254"), 5)
		draw_circle(tip, 5, Color("ffddaa"))

func _draw() -> void:
	for obj in targets:
		render_target(obj)
	for puff in smoke:
		var alpha: float = puff["life"] / puff["total"]
		draw_circle(puff["p"] - Vector2(travel, 0), puff["radius"] + (1.0 - alpha) * 13, Color(0.30, 0.34, 0.38, alpha * 0.23))
	for blast in blasts:
		var progress: float = blast["age"] / 0.3
		var at: Vector2 = blast["p"] - Vector2(travel, 0)
		draw_circle(at, blast["radius"] * (0.25 + progress * 0.75), Color(1.0, 0.40, 0.08, (1.0 - progress) * 0.13))
		draw_circle(at, (1.0 - progress) * 22.0, Color(1.0, 0.86, 0.52, (1.0 - progress) * 0.85))
	for shot in rounds:
		render_round(shot)
	for debris in particles:
		var alpha: float = clampf(debris["life"], 0.0, 1.0)
		var tint: Color = debris["color"]
		tint.a = alpha
		draw_circle(debris["p"] - Vector2(travel, 0), 2.4 + alpha * 3, tint)
	if debug_layers:
		draw_line(Vector2(0, GROUND), Vector2(W, GROUND), Color(1.0, 0.9, 0.25, 0.65), 2)
		draw_rect(Rect2(24, 116, W - 52, GROUND - 126), Color(CYAN, 0.22), false, 2)
		var ship_box := player_box()
		ship_box.position.x -= travel
		draw_rect(ship_box, Color(CYAN, 0.7), false, 2)
		draw_circle(ship.muzzle_point(), 5, Color("ffffff"))
		draw_line(ship.muzzle_point(), ship.muzzle_point() + ship.muzzle_direction() * 420, Color(CYAN, 0.35), 1.0)
		for obj in targets:
			if not obj["dead"] and obj["kind"] != "hangar":
				var box := target_box(obj)
				box.position.x -= travel
				draw_rect(box, Color(1.0, 0.85, 0.18, 0.8), false, 2)

func update_labels() -> void:
	label_status.text = "UNFORTUNATE EVENTS  /  01B    |    HULL %d/%d    |    ROCKET %s    |    TARGETS %d/5" % [hull, MAX_HULL, "READY" if missile_cooldown <= 0 else "RELOAD", kills]
	if destroyed:
		label_status.text = "HULL LOST  /  TAP RESTART OR PRESS R TO RETRY THE SAME ENCOUNTER"
	elif paused:
		label_status.text += "    [PAUSED]"
	label_help.text = "WASD / STICK MOVE    Z / A FIRE    X / B ROCKET    P PAUSE    R RESTART    F1 DEBUG    F2 SPEED    F3 SCALE    T TOUCH"
	label_help.visible = not touch_controls.controls_visible()
	label_debug.position = Vector2(1205, 95)
	label_debug.visible = debug_layers
	scale_button.visible = debug_layers
	scale_button.text = "SCALE %d%% / RESTART" % roundi(object_scale * 100.0)
	if debug_layers:
		label_debug.text = "WORLD %.0f | SCROLL %.1fx | SCALE %d%%\nHITBOXES + MUZZLE LINE | ROCKET SPLASH 100\nART/UI/PROJECTILE SIZES ARE INDEPENDENT" % [travel, speed_options[speed_index], roundi(object_scale * 100)]

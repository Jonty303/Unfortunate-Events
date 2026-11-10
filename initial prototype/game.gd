extends Node2D
## A single, deliberately small sortie. All artwork is original integer pixel geometry.
const SIZE := Vector2(640, 360)
const DURATION := 80.0
const LAND_START := 32.0
const SCROLL := 68.0
const CYAN := Color("78e8ef")
const PAPER := Color("e4f0ed")
const ORANGE := Color("ffb35c")
var player := Vector2(90, 165)
var hull := 5
var invulnerable := 0.0
var elapsed := 0.0
var state := "title"
var paused := false
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var events: Array[Dictionary] = []
var next_event := 0
var kills := 0
var missile_wait := 0.0
var font: Font
var art: Dictionary = {}
var stars: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var capture := false
var cannon_level := 1
var missile_level := 1
var pickups: Array[Dictionary] = []
var next_pickup := 6.0
var pickup_number := 0
var notice := ""
var notice_time := 0.0
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var muted := false

func make_sounds() -> void:
	# Original synthesized 16-bit mono effects; no external audio assets.
	var specs := {"cannon": [0.08, 1350.0, 260.0, 0.0], "missile": [0.25, 240.0, 65.0, 0.45], "hit": [0.12, 180.0, 50.0, 0.6], "boom": [0.38, 100.0, 25.0, 0.8], "pickup": [0.35, 450.0, 1500.0, 0.0], "launch": [0.4, 220.0, 880.0, 0.0], "atmosphere": [0.7, 700.0, 180.0, 0.12], "complete": [0.7, 440.0, 1320.0, 0.0]}
	var audio_rng := RandomNumberGenerator.new()
	audio_rng.seed = 81
	for key in specs:
		var spec: Array = specs[key]
		var count := int(spec[0] * 22050)
		var data := PackedByteArray()
		data.resize(count * 2)
		var phase := 0.0
		for i in range(count):
			var t := float(i) / count
			phase += lerpf(spec[1], spec[2], t) / 22050.0
			var wave := sin(phase * TAU) * 0.7 + (1.0 if fmod(phase, 1.0) < 0.5 else -1.0) * 0.3
			wave = lerpf(wave, audio_rng.randf_range(-1, 1), spec[3])
			var envelope := minf(t * 70, 1.0) * pow(1.0 - t, 1.6)
			data.encode_s16(i * 2, int(wave * envelope * 16000))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = data
		sounds[key] = stream
	for i in range(16):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14
		add_child(voice)
		voices.append(voice)

func sound_effect(key: String) -> void:
	if muted or voices.is_empty(): return
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = sounds[key]
	voice.play()

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()

func pad_direction() -> Vector2:
	var result := Vector2.ZERO
	for device in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			result += stick.normalized() * clampf((stick.length() - 0.2) / 0.8, 0, 1)
		result += Vector2(float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)), float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)))
	return result.limit_length()

func collect_pickup(kind: String) -> void:
	if kind == "C":
		cannon_level = mini(3, cannon_level + 1)
		notice = "CANNON %d / %s" % [cannon_level, "TWIN" if cannon_level == 2 else "THREE-WAY"]
	else:
		missile_level = mini(3, missile_level + 1)
		notice = "MISSILE %d / %s" % [missile_level, "TWIN LAUNCH" if missile_level == 2 else "HEAVY + FAST RELOAD"]
	notice_time = 2.5
	burst(player, CYAN, 16)
	sound_effect("pickup")

func _ready() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 61724
	for i in range(95):
		stars.append(Vector3(rng.randf_range(0, 640), rng.randf_range(28, 325), rng.randf_range(0.2, 1.0)))
	make_art()
	make_sounds()
	make_schedule()
	if "--preview-land" in OS.get_cmdline_user_args():
		start()
		elapsed = 47.0
		while next_event < events.size() and events[next_event].time < elapsed:
			next_event += 1
		spawn_enemy("tank", Vector2(400, 308))
		spawn_enemy("launcher", Vector2(550, 306))
		spawn_enemy("fighter", Vector2(430, 125))
		capture = true
	if "--preview-space" in OS.get_cmdline_user_args():
		start()
		elapsed = 12.0
		capture = true

func make_art() -> void:
	var palette := {"w": PAPER, "c": CYAN, "b": Color("3c7198"), "d": Color("20334f"), "o": ORANGE, "r": Color("dc6272"), "g": Color("7caa89"), "s": Color("526779")}
	var patterns := {
		"player": ["....bb..........", "...bwwb.........", "..bbwwwb........", "ddwwwwwwcccc....", "ddwwwwwwwwwwwww.", "..bbwwwb........", "...bwwb.........", "....bb.........."],
		"fighter": ["......rr...", "....rrddr..", "..rrwwdddrr", "rroowwddddd", "..rrwwdddrr", "....rrddr..", "......rr..."],
		"tank": ["........gggg....", ".....gggggggg...", "ggggggggddggg...", "....gggggggggg..", "..ssssssssssss..", "..sdsdsdsdsdds.."],
		"launcher": ["....oo..oo....", "....gg..gg....", "....gg..gg....", "...gggggggg...", "..ggggddgggg..", ".ssssssssssss.", ".sdsdsdsdsdds."],
		"missile": ["..wwo...", "wwwwwwwo", "..wwo..."]}
	for key in patterns:
		var rows: Array = patterns[key]
		var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for y in range(rows.size()):
			for x in range(rows[y].length()):
				var pixel: String = rows[y][x]
				if palette.has(pixel):
					img.set_pixel(x, y, palette[pixel])
		art[key] = ImageTexture.create_from_image(img)

func make_schedule() -> void:
	events.clear()
	for wave in range(7):
		for member in range(4):
			events.append({"time": 3.0 + wave * 4.0 + member * 0.45, "kind": "fighter", "y": 80.0 + (wave % 4) * 45.0})
	for wave in range(8):
		events.append({"time": 38.0 + wave * 4.5, "kind": "tank" if wave % 2 == 0 else "launcher", "y": 308.0})
		for member in range(3):
			events.append({"time": 39.0 + wave * 4.5 + member * 0.55, "kind": "fighter", "y": 90.0 + (wave % 3) * 50.0})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)

func start() -> void:
	player = Vector2(90, 165)
	hull = 5
	invulnerable = 0.0
	elapsed = 0.0
	missile_wait = 0.0
	next_event = 0
	kills = 0
	cannon_level = 1
	missile_level = 1
	pickups.clear()
	next_pickup = 6.0
	pickup_number = 0
	notice_time = 0
	paused = false
	enemies.clear()
	shots.clear()
	sparks.clear()
	state = "playing"
	sound_effect("launch")
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Events, rather than is_action_just_pressed, preserve multiple presses in one frame.
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER:
				if state != "playing": start()
			KEY_R:
				start()
			KEY_ESCAPE, KEY_P:
				if state == "playing": paused = not paused
			KEY_Z, KEY_SPACE:
				fire_cannon()
			KEY_X:
				fire_missile()
			KEY_M:
				muted = not muted
				if muted:
					for voice in voices: voice.stop()
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A:
				if state != "playing": start()
				else: fire_cannon()
			JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER:
				fire_missile()
			JOY_BUTTON_START:
				if state != "playing": start()
				else: paused = not paused
			JOY_BUTTON_Y:
				if state != "playing" or paused: start()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: fire_cannon()
		if event.button_index == MOUSE_BUTTON_RIGHT: fire_missile()
	queue_redraw()

func fire_cannon() -> void:
	if state == "playing" and not paused:
		shots.append({"p": player + Vector2(17, 0), "v": Vector2(510, 0), "friendly": true, "damage": 1, "missile": false})
		if cannon_level == 2:
			shots[-1].p.y -= 4
			shots.append({"p": player + Vector2(17, 4), "v": Vector2(510, 0), "friendly": true, "damage": 1, "missile": false})
		elif cannon_level == 3:
			for slope in [-0.15, 0.15]:
				shots.append({"p": player + Vector2(17, 0), "v": Vector2(510, 510 * slope), "friendly": true, "damage": 1, "missile": false})
		sound_effect("cannon")

func fire_missile() -> void:
	if state == "playing" and not paused and missile_wait <= 0.0:
		shots.append({"p": player + Vector2(13, 6), "v": Vector2(285, 0), "friendly": true, "damage": 4, "missile": true})
		missile_wait = 0.45
		if missile_level >= 2:
			shots.append({"p": player + Vector2(13, -6), "v": Vector2(285, 0), "friendly": true, "damage": 4 if missile_level == 2 else 6, "missile": true})
		if missile_level == 3:
			shots[-2].damage = 6
			missile_wait = 0.28
		sound_effect("missile")

func spawn_enemy(kind: String, pos: Vector2) -> void:
	enemies.append({"kind": kind, "p": pos, "base_y": pos.y, "age": 0.0, "hp": 2 if kind == "fighter" else 4, "fire": 1.3, "flash": 0.0})

func _physics_process(delta: float) -> void:
	if state == "playing" and not paused:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		step(delta, direction + pad_direction())
	queue_redraw()
	if capture:
		capture = false
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://preview.png")
		_exit_tree()
		await get_tree().create_timer(0.15).timeout
		get_tree().quit()

func step(delta: float, direction: Vector2) -> void:
	var previous_time := elapsed
	elapsed += delta
	if previous_time < LAND_START and elapsed >= LAND_START: sound_effect("atmosphere")
	notice_time = maxf(0, notice_time - delta)
	if elapsed >= next_pickup and elapsed < 72:
		pickups.append({"p": Vector2(655, clampf(player.y, 70, 270)), "kind": "C" if pickup_number % 2 == 0 else "M"})
		pickup_number += 1
		next_pickup += 8.0
	for i in range(pickups.size() - 1, -1, -1):
		pickups[i].p.x -= 85 * delta
		if player.distance_to(pickups[i].p) < 23:
			collect_pickup(pickups[i].kind)
			pickups.remove_at(i)
		elif pickups[i].p.x < -20:
			pickups.remove_at(i)
	missile_wait = maxf(0, missile_wait - delta)
	invulnerable = maxf(0, invulnerable - delta)
	player += direction.limit_length() * 205.0 * delta
	player.x = clampf(player.x, 20, 614)
	player.y = clampf(player.y, 42, 330)
	var ground := ground_y()
	if ground < 360 and player.y + 7 > ground:
		player.y = ground - 8
		hurt()
	while next_event < events.size() and elapsed >= events[next_event].time:
		var ev: Dictionary = events[next_event]
		spawn_enemy(ev.kind, Vector2(665, ev.y))
		next_event += 1
	for e in enemies:
		e.age += delta
		e.flash = maxf(0, e.flash - delta)
		e.p.x -= (94.0 if e.kind == "fighter" else SCROLL) * delta
		if e.kind == "fighter": e.p.y = e.base_y + sin(e.age * 2.8) * 22.0
		e.fire -= delta
		if e.fire <= 0 and e.p.x < 620 and e.p.x > player.x + 35:
			var launch: Vector2 = e.p + Vector2(-10, -8 if e.kind != "fighter" else 0)
			var velocity: Vector2 = (player - launch).normalized() * (125.0 if e.kind == "launcher" else 105.0)
			shots.append({"p": launch, "v": velocity, "friendly": false, "damage": 1, "missile": e.kind == "launcher"})
			e.fire = 2.0 if e.kind == "launcher" else 2.8
		if enemy_box(e).intersects(Rect2(player - Vector2(10, 5), Vector2(20, 10))):
			hurt()
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var previous: Vector2 = s.p
		s.p += s.v * delta
		var spent := false
		if s.friendly:
			for e in enemies:
				if e.hp <= 0: continue
				# Swept segment avoids tunnelling even at low frame rates.
				if segment_hits(previous, s.p, enemy_box(e).grow(3 if s.missile else 1)):
					e.hp -= s.damage
					e.flash = 0.12
					burst(s.p, ORANGE, 8 if s.missile else 3)
					spent = true
					break
		else:
			if segment_hits(previous, s.p, Rect2(player - Vector2(10, 5), Vector2(20, 10)).grow(2)):
				hurt()
				spent = true
		if spent or s.p.x < -30 or s.p.x > 680 or s.p.y < 28 or s.p.y > ground:
			shots.remove_at(i)
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			burst(enemies[i].p, ORANGE, 18)
			kills += 1
			sound_effect("boom")
			enemies.remove_at(i)
		elif enemies[i].p.x < -35:
			enemies.remove_at(i)
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].p += sparks[i].v * delta
		sparks[i].life -= delta
		if sparks[i].life <= 0: sparks.remove_at(i)
	if elapsed >= DURATION and state == "playing":
		state = "complete"
		sound_effect("complete")

func ground_y() -> float:
	return lerpf(390, 318, clampf((elapsed - LAND_START) / 5.0, 0, 1))

func enemy_box(e: Dictionary) -> Rect2:
	var half := Vector2(10, 7) if e.kind == "fighter" else Vector2(15, 10)
	return Rect2(e.p - half, half * 2)

func segment_hits(a: Vector2, b: Vector2, box: Rect2) -> bool:
	if box.has_point(a) or box.has_point(b): return true
	var lo := 0.0
	var hi := 1.0
	var diff := b - a
	for axis in range(2):
		if absf(diff[axis]) < 0.00001:
			if a[axis] < box.position[axis] or a[axis] > box.end[axis]: return false
		else:
			var near: float = (box.position[axis] - a[axis]) / diff[axis]
			var far: float = (box.end[axis] - a[axis]) / diff[axis]
			lo = maxf(lo, minf(near, far))
			hi = minf(hi, maxf(near, far))
			if lo > hi: return false
	return true

func hurt() -> void:
	if invulnerable > 0 or state != "playing": return
	hull -= 1
	sound_effect("hit")
	invulnerable = 1.4
	burst(player, CYAN, 12)
	if hull <= 0:
		state = "destroyed"
		sound_effect("boom")
		burst(player, ORANGE, 30)

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		sparks.append({"p": pos, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25, 100), "life": rng.randf_range(0.15, 0.5), "color": color})

func sprite(kind: String, pos: Vector2, tint: Color = Color.WHITE) -> void:
	var tex: Texture2D = art[kind]
	draw_texture_rect(tex, Rect2((pos - tex.get_size()).round(), tex.get_size() * 2), false, tint)

func label_at(words: String, pos: Vector2, size: int = 12, color: Color = PAPER) -> void:
	draw_string(font, pos, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	var land := clampf((elapsed - LAND_START) / 6.0, 0, 1)
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("080e20").lerp(Color("233348"), land))
	for star in stars:
		var p := Vector2(fposmod(star.x - elapsed * (15 + star.z * 40), 640), star.y)
		draw_rect(Rect2(p.round(), Vector2.ONE * (2 if star.z > 0.85 else 1)), Color(0.55, 0.75, 0.85, (1 - land * 0.7) * star.z))
	# Distant pixel moon and atmospheric bands.
	draw_rect(Rect2(478 - elapsed * 1.8, 55, 42, 4), Color("596778"))
	draw_rect(Rect2(472 - elapsed * 1.8, 59, 54, 30), Color("596778"))
	draw_rect(Rect2(478 - elapsed * 1.8, 89, 42, 4), Color("596778"))
	draw_rect(Rect2(480 - elapsed * 1.8, 64, 16, 8), Color("465467"))
	if land > 0:
		for layer in range(2):
			var offset := fposmod(elapsed * (13 + layer * 14), 80)
			for i in range(10):
				var h := 22 + ((i * 37 + layer * 17) % 55)
				draw_rect(Rect2(i * 80 - offset, 318 - h * land, 82, h * land), Color("2a4454") if layer == 0 else Color("33515c"))
		var gy := ground_y()
		draw_rect(Rect2(0, gy, 640, 80), Color("172d35"))
		draw_rect(Rect2(0, gy, 640, 3), Color("89a38c"))
		for i in range(18):
			draw_rect(Rect2(i * 40 - fposmod(elapsed * SCROLL, 40), gy + 8, 21, 3), Color("39545a"))
	for item in pickups:
		var pos: Vector2 = item.p.round()
		var color := CYAN if item.kind == "C" else ORANGE
		draw_rect(Rect2(pos - Vector2(10, 10), Vector2(20, 20)), Color("0c1728"))
		draw_rect(Rect2(pos - Vector2(10, 10), Vector2(20, 20)), color, false, 2)
		label_at(item.kind, pos + Vector2(-5, 5), 14, color)
	for e in enemies:
		sprite(e.kind, e.p, Color(3, 3, 3) if e.flash > 0 else Color.WHITE)
	for s in shots:
		if s.friendly and s.missile:
			sprite("missile", s.p)
			draw_rect(Rect2(s.p - Vector2(14, 1), Vector2(6, 2)), ORANGE)
		else:
			draw_rect(Rect2(s.p.round() - Vector2(3, 1), Vector2(7 if s.friendly else 4, 2 if s.friendly else 4)), CYAN if s.friendly else ORANGE)
	if state != "destroyed" and (invulnerable <= 0 or int(invulnerable * 18) % 2 == 0):
		draw_rect(Rect2(player.round() - Vector2(23, 3), Vector2(8 + int(elapsed * 25) % 6, 6)), ORANGE)
		sprite("player", player)
	for p in sparks:
		draw_rect(Rect2(p.p.round(), Vector2(2, 2)), p.color)
	draw_rect(Rect2(0, 0, 640, 29), Color("0c1728"))
	label_at("UNFORTUNATE EVENTS", Vector2(12, 19), 13, CYAN)
	label_at("HULL", Vector2(215, 18), 10)
	for i in range(5):
		draw_rect(Rect2(248 + i * 11, 10, 8, 10), CYAN if i < hull else Color("334052"))
	label_at("MISSILE " + ("READY" if missile_wait <= 0 else "RELOAD"), Vector2(320, 18), 10, ORANGE)
	label_at("SPACE" if elapsed < LAND_START else "OVERLAND", Vector2(448, 18), 10)
	label_at("%02d / 80" % mini(int(elapsed), 80), Vector2(560, 18), 10)
	draw_rect(Rect2(0, 28, 640 * minf(elapsed / DURATION, 1), 1), CYAN)
	label_at("CANNON %d   MISSILE %d" % [cannon_level, missile_level], Vector2(12, 43), 10, CYAN)
	if notice_time > 0:
		label_at(notice, Vector2(180, 77), 12, CYAN)
	if state == "playing" and elapsed > 32 and elapsed < 37:
		label_at("ENTERING LOW ATMOSPHERE", Vector2(219, 57), 12, ORANGE)
	if state == "playing" and elapsed < 3:
		label_at("KEEP MOVING. TAP TO FIRE.", Vector2(226, 280), 12, CYAN)
	if state != "playing" or paused:
		draw_rect(Rect2(55, 91, 530, 186), Color("0c1728"))
		draw_rect(Rect2(55, 91, 3, 186), CYAN)
		var title := "UNFORTUNATE EVENTS"
		var subtitle := "A SMALL SHIP. A VERY BAD ROUTE."
		if state == "destroyed":
			title = "SHIP LOST"
			subtitle = "HULL BREACHED / %d HOSTILES DESTROYED" % kills
		elif state == "complete":
			title = "CLEAR OF THE FRONT"
			subtitle = "SORTIE COMPLETE / %d HOSTILES DESTROYED" % kills
		elif paused:
			title = "PAUSED"
			subtitle = "P OR ESC TO RESUME"
		label_at(title, Vector2(80, 128), 25, CYAN)
		label_at(subtitle, Vector2(81, 152), 12, ORANGE)
		label_at("WASD / ARROWS / LEFT STICK / D-PAD   MOVE", Vector2(81, 180))
		label_at("Z / SPACE / LMB / PAD A   TAP CANNON", Vector2(81, 199))
		label_at("X / RMB / PAD B OR RB    MISSILE", Vector2(81, 218))
		label_at("COLLECT C / M CAPSULES TO UPGRADE WEAPONS", Vector2(81, 237), 11, ORANGE)
		label_at("ENTER / PAD A TO LAUNCH" if state == "title" else "R / PAD Y TO RESTART", Vector2(81, 261), 13, CYAN)
	label_at("P / ESC / START  PAUSE    R  RESTART    M  SOUND " + ("OFF" if muted else "ON"), Vector2(12, 352), 10, Color("9babba"))

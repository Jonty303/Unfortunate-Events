extends Node2D
## A single, deliberately small sortie.
const START_SPEED := 130.0
const SPEED_INCREMENT := 22.0
const MAX_SPEED_BOOSTS := 3
const ROCKET_LAUNCH := Vector2(225, 82)
const ROCKET_DROP := 110.0
const SPEED_GREEN := Color("99dfaa")
const PICKUP_ORDER := ["S", "C", "M", "F"]
const TANK_PIVOT := Vector2(-7, -1)
const RAIL_PIVOT := Vector2(3, 2)
const RAIL_LOAD := Vector2(5, -5)
const TANK_RELOAD := 2.8
const SAM_RELOAD := 2.0
const FLIGHT := {
	"shuttle_bank": preload("res://assets/hd/shuttle_bank.webp"),
	"fighter": preload("res://assets/hd/fighter.webp"),
	"tank": preload("res://assets/hd/tank.webp"),
	"launcher": preload("res://assets/hd/launcher.webp"),
	"tank_barrel": preload("res://assets/hd/tank_barrel.webp"),
	"launch_rail": preload("res://assets/hd/launch_rail.webp"),
	"sam": preload("res://assets/hd/sam.webp"),
	"tank_shell": preload("res://assets/hd/tank_shell.webp"),
	"fighter_pulse": preload("res://assets/hd/fighter_pulse.webp"),
	"cannon_round": preload("res://assets/hd/cannon_round.webp"),
	"rocket": preload("res://assets/hd/rocket.webp"),
	"heavy_rocket": preload("res://assets/hd/heavy_rocket.webp"),
	"main_drive": preload("res://assets/hd/main_drive.webp"),
	"rocket_drive": preload("res://assets/hd/rocket_drive.webp"),
	"muzzle_flash": preload("res://assets/hd/muzzle_flash.webp"),
	"small_explosion": preload("res://assets/hd/small_explosion.webp"),
	"exhaust": preload("res://assets/hd/exhaust.webp"),
	"impact": preload("res://assets/hd/impact.webp"),
	"debris_cloud": preload("res://assets/hd/debris_cloud.webp"),
	"military": preload("res://assets/hd/military.webp"),
	"civilian": preload("res://assets/hd/civilian.webp"),
}
const SPRITE_SIZE := {
	"shuttle_bank": Vector2(46, 24),
	"fighter": Vector2(39, 18),
	"tank": Vector2(39, 15),
	"launcher": Vector2(39, 15),
	"tank_barrel": Vector2(18, 6),
	"launch_rail": Vector2(19, 8),
	"sam": Vector2(18, 7),
	"tank_shell": Vector2(15, 7),
	"fighter_pulse": Vector2(16, 8),
	"cannon_round": Vector2(18, 7),
	"rocket": Vector2(17, 7),
	"heavy_rocket": Vector2(20, 8),
	"main_drive": Vector2(17, 7),
	"rocket_drive": Vector2(11, 5),
	"muzzle_flash": Vector2(13, 8),
	"small_explosion": Vector2(32, 32),
	"exhaust": Vector2(10, 5),
	"impact": Vector2(14, 14),
	"debris_cloud": Vector2(32, 32),
	"military": Vector2(45, 31),
	"civilian": Vector2(45, 31),
}
# Horizontal strips use equal-width cells. Rates are in frames per second.
const FRAME_COUNTS := {"shuttle_bank": 5, "main_drive": 6, "rocket_drive": 4, "muzzle_flash": 4, "impact": 6, "small_explosion": 9, "debris_cloud": 9}
const EFFECT_FPS := {"muzzle_flash": 48.0, "impact": 28.0, "small_explosion": 22.0, "debris_cloud": 14.0}
const PROPERTY_SPEED := 49.0
const BLAST_RADIUS := 38.0
const LAND_ART := {
 "mountains": preload("res://assets/terrain/mountains.webp"),
 "woods": preload("res://assets/terrain/woods.webp"),
 "property": preload("res://assets/terrain/property.webp"),
 "road": preload("res://assets/terrain/road.webp"),
}
var fragments: Array[Dictionary] = []
var scars: Array[Dictionary] = []
const BACKDROPS := {
	"hangar": preload("res://assets/backdrops/hangar.svg"),
	"overland": preload("res://assets/backdrops/overland.svg"),
	"orbit": preload("res://assets/backdrops/orbit.svg"),
}
const POWERUP_SHEET := preload("res://assets/backdrops/powerups.png")
const SIZE := Vector2(640, 360)
const OUTPUT_SIZE := Vector2(1280, 720)
const CANNON_INTERVAL := 0.18
const MISSILE_POWER_COST := 35.0
const MISSILE_POWER_REGEN := 12.0
const DURATION := 80.0
const LAND_START := 8.0
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
var structures: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var events: Array[Dictionary] = []
var next_event := 0
var kills := 0
var score := 0
var speed_boosts := 0
var effects: Array[Dictionary] = []
var missile_wait := 0.0
var cannon_wait := 0.0
var missile_power := 100.0
var font: Font
var bank := 0.0
var stars: Array[Vector3] = []
var rng := RandomNumberGenerator.new()
var capture := false
var cannon_level := 1
var cannon_rate_level := 1
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
	if kind == "S":
		speed_boosts = mini(MAX_SPEED_BOOSTS, speed_boosts + 1)
		notice = "DRIVE +%d / %d PX/S" % [speed_boosts, int(START_SPEED + SPEED_INCREMENT * speed_boosts)]
	elif kind == "C":
		cannon_level = mini(3, cannon_level + 1)
		notice = "CANNON %d / %s" % [cannon_level, "TWIN" if cannon_level == 2 else "THREE-WAY"]
	elif kind == "F":
		cannon_rate_level = mini(3, cannon_rate_level + 1)
		notice = "FIRE RATE %d / 3" % cannon_rate_level
	else:
		missile_level = mini(3, missile_level + 1)
		notice = "ROCKET %d / %s" % [missile_level, "TWIN LAUNCH" if missile_level == 2 else "HEAVY + FAST RELOAD"]
	notice_time = 2.5
	burst(player, CYAN, 16)
	sound_effect("pickup")

func _ready() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rng.seed = 61724
	for i in range(95):
		stars.append(Vector3(rng.randf_range(0, 640), rng.randf_range(28, 325), rng.randf_range(0.2, 1.0)))
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

func make_schedule() -> void:
	events.clear()
	for wave in range(7):
		for member in range(4):
			events.append({"time": 3.0 + wave * 4.0 + member * 0.45, "kind": "fighter", "y": 80.0 + (wave % 4) * 45.0})
	for wave in range(8):
		events.append({"time": 12.0 + wave * 6.5, "kind": "tank" if wave % 2 == 0 else "launcher", "y": 308.0})
		events.append({"time": 15.0 + wave * 5.8, "kind": "building_military" if wave % 2 == 0 else "building_civilian", "y": 318.0})
		for member in range(3):
			events.append({"time": 13.0 + wave * 6.5 + member * 0.55, "kind": "fighter", "y": 90.0 + (wave % 3) * 50.0})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.time < b.time)

func start() -> void:
	player = Vector2(90, 165)
	bank = 0.0
	hull = 5
	invulnerable = 0.0
	elapsed = 0.0
	missile_wait = 0.0
	cannon_wait = 0.0
	missile_power = 100.0
	next_event = 0
	kills = 0
	score = 0
	cannon_level = 1
	cannon_rate_level = 1
	missile_level = 1
	speed_boosts = 0
	effects.clear()
	pickups.clear()
	next_pickup = 6.0
	pickup_number = 0
	notice_time = 0
	paused = false
	notice = "MIND: ENGINES RECONFIGURING. WE CANNOT LEAVE ORBIT YET."
	notice_time = 4.0
	fragments.clear()
	scars.clear()
	enemies.clear()
	structures.clear()
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
	if state == "playing" and not paused and cannon_wait <= 0.0:
		cannon_wait = cannon_fire_interval()
		if cannon_level == 2:
			flight_effect("muzzle_flash", Vector2(20, -1))
			flight_effect("muzzle_flash", Vector2(20, 7))
		else:
			flight_effect("muzzle_flash", Vector2(20, 3))
		shots.append({"p": player + Vector2(17, 3), "v": Vector2(510, 0), "friendly": true, "damage": 1, "missile": false})
		if cannon_level == 2:
			shots[-1].p.y -= 4
			shots.append({"p": player + Vector2(17, 7), "v": Vector2(510, 0), "friendly": true, "damage": 1, "missile": false})
		elif cannon_level == 3:
			for slope in [-0.15, 0.15]:
				shots.append({"p": player + Vector2(17, 3), "v": Vector2(510, 510 * slope), "friendly": true, "damage": 1, "missile": false})
		sound_effect("cannon")

func cannon_fire_interval() -> float:
	return maxf(0.09, CANNON_INTERVAL - float(cannon_rate_level - 1) * 0.035)

func fire_missile() -> void:
	if state == "playing" and not paused and missile_wait <= 0.0 and missile_power >= MISSILE_POWER_COST:
		missile_power -= MISSILE_POWER_COST
		shots.append({"p": player + Vector2(2, 6), "v": ROCKET_LAUNCH, "friendly": true, "damage": 4, "missile": true})
		missile_wait = 0.45
		if missile_level >= 2:
			shots.append({"p": player + Vector2(9, 4), "v": ROCKET_LAUNCH, "friendly": true, "damage": 4 if missile_level == 2 else 6, "missile": true})
		if missile_level == 3:
			shots[-2].damage = 6
			missile_wait = 0.28
		sound_effect("missile")

func flight_effect(kind: String, pos: Vector2) -> void:
	effects.append({"kind": kind, "p": pos, "age": 0.0})

func advance_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var fx := effects[i]
		fx.age += delta
		if fx.age * EFFECT_FPS[fx.kind] >= FRAME_COUNTS[fx.kind]:
			effects.remove_at(i)

func spawn_enemy(kind: String, pos: Vector2) -> void:
	if kind.begins_with("building_"):
		structures.append({"kind": kind.trim_prefix("building_"), "p": Vector2(pos.x, ground_y()), "hp": 3 if kind.ends_with("military") else 2, "flash": 0.0})
		return
	enemies.append({"kind": kind, "p": pos, "base_y": pos.y, "age": 0.0, "hp": 2 if kind == "fighter" else 4, "fire": 1.3, "flash": 0.0, "elevation": 0.0, "fired_ago": 10.0})

func _physics_process(delta: float) -> void:
	if state == "playing" and not paused:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		step(delta, direction + pad_direction())
	queue_redraw()
	if state == "destroyed" and not effects.is_empty():
		advance_effects(delta)
	if capture:
		capture = false
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://preview.png")
		_exit_tree()
		await get_tree().create_timer(0.15).timeout
		get_tree().quit()

func step(delta: float, direction: Vector2) -> void:
	advance_effects(delta)
	var previous_time := elapsed
	elapsed += delta
	if previous_time < LAND_START and elapsed >= LAND_START: sound_effect("atmosphere")
	notice_time = maxf(0, notice_time - delta)
	if elapsed >= next_pickup and elapsed < 72:
		pickups.append({"p": Vector2(655, clampf(player.y, 70, 270)), "kind": PICKUP_ORDER[pickup_number % PICKUP_ORDER.size()]})
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
	cannon_wait = maxf(0, cannon_wait - delta)
	missile_power = minf(100.0, missile_power + MISSILE_POWER_REGEN * delta)
	var cannon_held := Input.is_physical_key_pressed(KEY_Z) or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for device in Input.get_connected_joypads():
		cannon_held = cannon_held or Input.is_joy_button_pressed(device, JOY_BUTTON_A)
	if cannon_held and cannon_wait <= 0.0:
		fire_cannon()
	invulnerable = maxf(0, invulnerable - delta)
	var speed := START_SPEED + SPEED_INCREMENT * speed_boosts
	var old_y := player.y
	player += direction.limit_length() * speed * delta
	player.x = clampf(player.x, 23, SIZE.x - 23)
	player.y = clampf(player.y, 67, SIZE.y - 12)
	var ground := ground_y()
	if ground < 360 and player.y + 12 > ground:
		player.y = ground - 12
		hurt()
	if delta > 0:
		var vertical_motion := clampf((player.y - old_y) / (speed * delta), -1.0, 1.0)
		bank = move_toward(bank, vertical_motion, 7.0 * delta)
	while next_event < events.size() and elapsed >= events[next_event].time:
		var ev: Dictionary = events[next_event]
		spawn_enemy(ev.kind, Vector2(665, ev.y))
		next_event += 1
	for building in structures:
		building.p.x -= PROPERTY_SPEED * delta
		building.p.y = ground_y() - 20
		building.flash = maxf(0.0, building.flash - delta)
	for e in enemies:
		e.age += delta
		e.flash = maxf(0, e.flash - delta)
		e.p.x -= (94.0 if e.kind == "fighter" else SCROLL) * delta
		if e.kind == "fighter": e.p.y = e.base_y + sin(e.age * 2.8) * 22.0
		if e.kind != "fighter": e.p.y = ground - (9.5 if e.kind == "tank" else 10.5)
		update_enemy_weapon(e, delta)
		if enemy_box(e).intersects(Rect2(player - Vector2(10, 5), Vector2(20, 10))):
			hurt()
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var previous: Vector2 = s.p
		if s.friendly and s.missile:
			s.p += s.v * delta + Vector2.DOWN * 0.5 * ROCKET_DROP * delta * delta
			s.v.y += ROCKET_DROP * delta
		else:
			s.p += s.v * delta
		var spent := false
		if s.friendly:
			for building in structures:
				if building.hp <= 0: continue
				var building_box := Rect2(building.p + Vector2(-22, -31), Vector2(44, 31))
				if segment_hits(previous, s.p, building_box.grow(3 if s.missile else 1)):
					if s.missile:
						blast(s.p, s.damage)
					else:
						building.hp -= s.damage
					building.flash = 0.12
					spent = true
					break
			if spent:
				shots.remove_at(i)
				continue
			for e in enemies:
				if e.hp <= 0: continue
				# Swept segment avoids tunnelling even at low frame rates.
				if segment_hits(previous, s.p, enemy_box(e).grow(3 if s.missile else 1)):
					if s.missile:
						blast(s.p, s.damage)
					else:
						e.hp -= s.damage
					e.flash = 0.12
					if e.hp > 0:
						flight_effect("small_explosion" if s.missile else "impact", e.p)
					spent = true
					break
		else:
			if segment_hits(previous, s.p, Rect2(player - Vector2(10, 5), Vector2(20, 10)).grow(2)):
				hurt()
				spent = true
		if not spent and s.friendly and s.missile and ground < SIZE.y and s.p.y >= ground:
			var fraction := clampf((ground - previous.y) / maxf(0.001, s.p.y - previous.y), 0, 1)
			var impact := previous.lerp(s.p, fraction)
			blast(impact, s.damage)
			spent = true
		if spent or s.p.x < -30 or s.p.x > 680 or s.p.y < 28 or s.p.y > ground:
			shots.remove_at(i)
	step_fragments(delta)
	for i in range(structures.size() - 1, -1, -1):
		if structures[i].hp <= 0:
			structure_destroyed(structures[i])
		if structures[i].hp <= 0 or structures[i].p.x < -40:
			structures.remove_at(i)
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			flight_effect("debris_cloud", enemies[i].p)
			flight_effect("small_explosion", enemies[i].p)
			shed_fragments(enemies[i].kind, enemies[i].p)
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

# Ground weapons use local +X down the barrel and +Y below the mount.
func weapon_transform(origin: Vector2, forward: Vector2) -> Transform2D:
	return Transform2D(forward, Vector2(forward.y, -forward.x), origin)

func mount_point(e: Dictionary, local: Vector2) -> Vector2:
	var pivot := TANK_PIVOT if e.kind == "tank" else RAIL_PIVOT
	return weapon_transform(e.p + pivot, Vector2.LEFT.rotated(e.elevation)) * local

func update_enemy_weapon(e: Dictionary, delta: float) -> void:
	e.fire -= delta
	e.fired_ago += delta
	var can_fire: bool = e.p.x < 620 and e.p.x > player.x + 35
	if e.kind == "fighter":
		if can_fire and e.fire <= 0:
			var nose: Vector2 = e.p + Vector2(-13, 0)
			fire_hostile(e, nose, (player - nose).normalized() * 105.0, "fighter_pulse")
		return
	var pivot := mount_point(e, Vector2.ZERO)
	var aim := atan2(pivot.y - player.y, maxf(1.0, pivot.x - player.x))
	var target := aim
	if e.kind == "launcher" and e.fire > 0.8:
		target = 0.10 # Lower the spent rail for the next round.
	# Hold the firing pose briefly during the kick, then resume tracking.
	if e.fired_ago > 0.09:
		e.elevation = move_toward(e.elevation, target, 2.8 * delta)
	if not can_fire or e.fire > 0 or absf(e.elevation - aim) > 0.04:
		return
	var axis := Vector2.LEFT.rotated(e.elevation)
	if e.kind == "tank":
		fire_hostile(e, mount_point(e, Vector2(15, 0)), axis * 105.0, "tank_shell")
	else:
		fire_hostile(e, mount_point(e, RAIL_LOAD), axis * 125.0, "sam")

func fire_hostile(e: Dictionary, origin: Vector2, velocity: Vector2, kind: String) -> void:
	shots.append({"p": origin, "v": velocity, "friendly": false, "damage": 1, "missile": kind == "sam", "sprite": kind})
	e.fire = SAM_RELOAD if kind == "sam" else TANK_RELOAD
	e.fired_ago = 0.0

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

func building_bounds(b: Dictionary) -> Rect2:
	return Rect2(b.p - Vector2(22, 31), Vector2(44, 31))

func blast(at: Vector2, damage: int) -> void:
	flight_effect("small_explosion", at)
	for b in structures:
		var box := building_bounds(b)
		if at.distance_to(at.clamp(box.position, box.end)) <= BLAST_RADIUS:
			b.hp -= damage
			b.flash = 0.12
	for e in enemies:
		var box := enemy_box(e)
		if at.distance_to(at.clamp(box.position, box.end)) <= BLAST_RADIUS:
			e.hp -= damage
			e.flash = 0.12
	for lane in ["property", "road"]:
		var y := ground_y() - (20 if lane == "property" else 0)
		if absf(at.y - y) <= BLAST_RADIUS:
			scars.append({"x":at.x, "lane":lane})
			flight_effect("debris_cloud", Vector2(at.x, y))

func shed_fragments(kind: String, at: Vector2) -> void:
	var tex: Texture2D = FLIGHT[kind]
	for n in range(6):
		if fragments.size() >= 96: break
		var chip := Vector2(12, 9)
		var origin := Vector2(tex.get_width(), tex.get_height()) * Vector2(rng.randf_range(0.32,0.62),rng.randf_range(0.40,0.55))
		fragments.append({"p":at,"v":Vector2(rng.randf_range(-145,130),rng.randf_range(-210,-70)), "life":1.8, "texture":tex, "region":Rect2(origin,chip), "spin":rng.randf_range(-7,7)})

func step_fragments(delta: float) -> void:
	for j in range(scars.size()-1,-1,-1):
		scars[j].x -= (PROPERTY_SPEED if scars[j].lane == "property" else SCROLL) * delta
		if scars[j].x < -20: scars.remove_at(j)
	for j in range(fragments.size()-1,-1,-1):
		var f := fragments[j]
		var previous: Vector2 = f.p
		f.v.y += 185 * delta
		f.p += f.v * delta
		f.life -= delta
		var hit := false
		for b in structures:
			if b.hp > 0 and segment_hits(previous, f.p, building_bounds(b)):
				b.hp -= 1
				b.flash = 0.12
				hit = true
				break
		if not hit:
			for e in enemies:
				if e.hp > 0 and segment_hits(previous, f.p, enemy_box(e)):
					e.hp -= 1
					e.flash = 0.12
					hit = true
					break
		if not hit and segment_hits(previous, f.p, Rect2(player-Vector2(10,5),Vector2(20,10))):
			hurt()
			hit = true
		if hit: flight_effect("impact", f.p)
		if hit or f.life <= 0 or f.p.y > ground_y(): fragments.remove_at(j)

func structure_destroyed(building: Dictionary) -> void:
	shed_fragments(building.kind, building.p - Vector2(0, 16))
	flight_effect("debris_cloud", building.p + Vector2(0, -18))
	flight_effect("small_explosion", building.p + Vector2(0, -18))
	if building.kind == "military":
		score += 100
		missile_power = minf(100.0, missile_power + 20.0)
		notice = "MILITARY SITE DESTROYED  +100 / POWER SALVAGED"
	else:
		notice = "PILOT: THAT WAS CIVILIAN.  MIND: IT WAS IN THE WAY."
	notice_time = 3.0
	sound_effect("boom")

func hurt() -> void:
	if invulnerable > 0 or state != "playing": return
	hull -= 1
	sound_effect("hit")
	invulnerable = 1.4
	flight_effect("debris_cloud", player + Vector2(4, 0))
	if hull <= 0:
		state = "destroyed"
		sound_effect("boom")
		flight_effect("debris_cloud", player)
		flight_effect("small_explosion", player)

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		sparks.append({"p": pos, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25, 100), "life": rng.randf_range(0.15, 0.5), "color": color})

func draw_structure(building: Dictionary) -> void:
	var p: Vector2 = building.p.round()
	var tint := Color("ffcc89") if building.flash > 0 else Color.WHITE
	flight_sprite(building.kind, p - Vector2(0, 15.5), 0, tint)

func draw_enemy(e: Dictionary) -> void:
	var tint := Color(3, 3, 3) if e.flash > 0 else Color.WHITE
	if e.kind == "fighter":
		draw_set_transform(e.p.round(), 0, Vector2(-1, 1))
		var tail := 15 + int(e.age * 16) % 3
		for y in [-2, 2]:
			flight_sprite("exhaust", Vector2(-tail, y))
		draw_set_transform(Vector2.ZERO)
		flight_sprite("fighter", e.p, 0, tint)
		return
	var is_tank: bool = e.kind == "tank"
	flight_sprite(e.kind, e.p + Vector2.DOWN * (2 if is_tank else 3), 0, tint)
	draw_set_transform_matrix(weapon_transform(mount_point(e, Vector2.ZERO).round(), Vector2.LEFT.rotated(e.elevation)))
	if is_tank:
		var recoil := roundf(3.0 * maxf(0, 1.0 - e.fired_ago / 0.20))
		flight_sprite("tank_barrel", Vector2(7 - recoil, 0), 0, tint)
		if e.fired_ago < 0.07:
			flight_sprite("muzzle_flash", Vector2(17 - recoil, 0), int(e.fired_ago * 48), Color(1, 0.75, 0.46))
	else:
		flight_sprite("launch_rail", Vector2(3, -1), 0, tint)
		if e.fired_ago >= 0.7:
			var feed := clampf((e.fired_ago - 0.7) / 0.22, 0.0, 1.0)
			flight_sprite("sam", RAIL_LOAD + Vector2(-3, 2) * (1 - feed), 0, tint)
	draw_set_transform(Vector2.ZERO)

func flight_sprite(kind: String, pos: Vector2, frame: int = 0, tint: Color = Color.WHITE) -> void:
	var tex: Texture2D = FLIGHT[kind]
	var cells: int = FRAME_COUNTS.get(kind, 1)
	# Gameplay sprites were authored for the original small viewport. Give them
	# deliberate screen presence in the larger 1280 x 720 presentation.
	var source_size := Vector2(tex.get_width() / cells, tex.get_height())
	var draw_size: Vector2 = SPRITE_SIZE[kind]
	draw_texture_rect_region(tex, Rect2((pos - draw_size * 0.5).round(), draw_size),
			Rect2(Vector2(frame % cells * source_size.x, 0), source_size), tint)

func draw_powerup(kind: String, pos: Vector2) -> void:
	var index := ["S", "C", "M", "F"].find(kind)
	if index < 0:
		return
	var cell := Vector2(POWERUP_SHEET.get_width() / 2.0, POWERUP_SHEET.get_height() / 2.0)
	var source := Rect2(Vector2((index % 2) * cell.x, floori(float(index) / 2.0) * cell.y), cell)
	var size := Vector2(38, 38)

	draw_texture_rect_region(POWERUP_SHEET, Rect2(pos - size * 0.5, size), source)

func label_at(words: String, pos: Vector2, size: int = 12, color: Color = PAPER) -> void:
	draw_string(font, pos, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func hud_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)

func hud_label(words: String, pos: Vector2, size: int = 12, color: Color = PAPER) -> void:
	draw_string(font, pos, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func strip(kind: String, y: float, height: float, width: float, speed: float) -> void:
	var distance := elapsed * speed
	var tile := floori(distance / width)
	var x := -fposmod(distance, width)
	while x < SIZE.x:
		var rect := Rect2(x, y, width + 0.25, height)
		if tile % 2 == 1:
			rect.position.x += rect.size.x
			rect.size.x *= -1
		draw_texture_rect(LAND_ART[kind], rect, false)
		tile += 1
		x += width

func _draw() -> void:
	var phase: String = "hangar" if elapsed < 7.0 else ("overland" if elapsed < 68.0 else "orbit")
	if phase == "overland":
		strip("mountains", 0, 320, 850, 5.0)
		strip("woods", ground_y()-104, 100, 650, 23.0)
		strip("property", ground_y()-20, 62, 520, PROPERTY_SPEED)
		strip("road", ground_y(), 65, 380, SCROLL)
		for mark in scars:
			var at := Vector2(mark.x, ground_y() + (2 if mark.lane == "road" else -18))
			draw_line(at-Vector2(9,0), at+Vector2(9,0), Color("46372f"), 3, true)
	else:
		var backdrop: Texture2D = BACKDROPS[phase]
		var offset := fposmod(elapsed * 18.0, 1280.0)
		draw_texture_rect_region(backdrop, Rect2(Vector2.ZERO, SIZE), Rect2(Vector2(offset,0), OUTPUT_SIZE))
	for item in pickups:
		draw_powerup(item.kind, item.p.round())
	for building in structures:
		draw_structure(building)
	for e in enemies:
		draw_enemy(e)
	for shot in shots:
		draw_set_transform(shot.p.round(), shot.v.angle())
		if not shot.missile:
			var colour := Color("76faff") if shot.friendly else Color("ff668c")
			draw_line(Vector2(-11,0), Vector2(4,0), Color("31273d"), 5, true)
			draw_line(Vector2(-11,0), Vector2(4,0), colour, 3, true)
		if shot.friendly and shot.missile:
			flight_sprite("rocket_drive", Vector2(-11, 0), int(elapsed * 20))
			flight_sprite("heavy_rocket" if shot.damage > 4 else "rocket", Vector2.ZERO)
		elif shot.friendly:
			flight_sprite("cannon_round", Vector2.ZERO)
		else:
			draw_set_transform_matrix(weapon_transform(shot.p.round(), shot.v.normalized()))
			if shot.missile:
				flight_sprite("exhaust", Vector2(-9 - int(elapsed * 20) % 3, 0))
			flight_sprite(shot.sprite, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	if state != "destroyed":
		var cycle := int(elapsed * (14 + speed_boosts * 3))
		flight_sprite("main_drive", player + Vector2(-20, -1), cycle)
		flight_sprite("main_drive", player + Vector2(-20, 2), cycle + 2)
		flight_sprite("shuttle_bank", player, roundi(bank * 2) + 2, Color.WHITE)
	for f in fragments:
		draw_set_transform(f.p, f.spin * f.life)
		draw_texture_rect_region(f.texture, Rect2(-3,-2,6,4), f.region)
		draw_set_transform(Vector2.ZERO)
	for fx in effects:
		var pos: Vector2 = fx.p
		if fx.kind == "muzzle_flash":
			if state == "destroyed": continue
			pos += player
		flight_sprite(fx.kind, pos, int(fx.age * EFFECT_FPS[fx.kind]))
	for p in sparks:
		draw_rect(Rect2(p.p.round(), Vector2(2, 2)), p.color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, 0, SIZE.x, 55), Color("0c1728"))
	hud_label("UNFORTUNATE EVENTS", Vector2(12, 19), 13, CYAN)
	if paused:
		hud_label("PAUSED", Vector2(161, 18), 10, ORANGE)
	hud_label("HULL", Vector2(215, 18), 10)
	hud_label("SCORE %06d" % score, Vector2(470, 43), 10, CYAN)
	for i in range(5):
		hud_rect(Rect2(248 + i * 11, 10, 8, 10), CYAN if i < hull else Color("334052"))
	hud_label("MISSILE PWR", Vector2(315, 18), 10, ORANGE)
	hud_rect(Rect2(383, 11, 42, 8), Color("334052"))
	hud_rect(Rect2(383, 11, 42 * missile_power / 100.0, 8), ORANGE)
	hud_label("SPACE" if elapsed < LAND_START else "OVERLAND", Vector2(435, 18), 10)
	hud_label("%02d / 80" % mini(int(elapsed), 80), Vector2(560, 18), 10)
	hud_rect(Rect2(0, 28, 640 * minf(elapsed / DURATION, 1), 1), CYAN)
	hud_label("PATTERN %d   RATE %d   ROCKET %d   DRIVE +%d" % [cannon_level, cannon_rate_level, missile_level, speed_boosts], Vector2(12, 43), 10, CYAN)
	if notice_time > 0:
		hud_label(notice, Vector2(180, 77), 12, CYAN)
	if state == "playing" and elapsed > 32 and elapsed < 37:
		hud_label("ENTERING LOW ATMOSPHERE", Vector2(219, 57), 12, ORANGE)
	if state == "playing" and elapsed < 3:
		hud_label("ENGINES RECONFIGURING. HOLD TO FIRE.", Vector2(188, 280), 12, CYAN)
	if state != "playing":
		hud_rect(Rect2(55, 91, 530, 186), Color("0c1728"))
		hud_rect(Rect2(55, 91, 3, 186), CYAN)
		var title := "UNFORTUNATE EVENTS"
		var subtitle := "A SMALL SHIP. A VERY BAD ROUTE."
		if state == "destroyed":
			title = "SHIP LOST"
			subtitle = "HULL BREACHED / %d HOSTILES DESTROYED" % kills
		elif state == "complete":
			title = "CLEAR OF THE FRONT"
			subtitle = "SORTIE COMPLETE / %d HOSTILES DESTROYED" % kills
		hud_label(title, Vector2(80, 128), 25, CYAN)
		hud_label(subtitle, Vector2(81, 152), 12, ORANGE)
		hud_label("WASD / ARROWS / LEFT STICK / D-PAD   MOVE", Vector2(81, 180))
		hud_label("HOLD Z / SPACE / LMB / PAD A   CANNON", Vector2(81, 199))
		hud_label("X / RMB / PAD B OR RB    POWERED GROUND MISSILES", Vector2(81, 218))
		hud_label("S SPEED   C PATTERN   F FIRE RATE   M MISSILE", Vector2(81, 237), 11, ORANGE)
		hud_label("ENTER / PAD A TO LAUNCH" if state == "title" else "R / PAD Y TO RESTART", Vector2(81, 261), 13, CYAN)
	var pause_action := "RESUME" if paused else "PAUSE"
	hud_label("P / ESC / START  %s    R  RESTART    M  SOUND %s" % [pause_action, "OFF" if muted else "ON"], Vector2(12, 346), 10, Color("9babba"))

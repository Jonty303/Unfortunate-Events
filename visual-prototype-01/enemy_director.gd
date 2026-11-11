extends RefCounted
## Reproducible 64-second encounter; enemy logic emits shots but never owns input.
const Art = preload("res://enemy_art.gd")
const DURATION := 64.0
const SCHEDULE := [
	{"at": 2.0, "kind": "interceptor", "y": 440.0},
	{"at": 16.0, "kind": "tank"},
	{"at": 22.0, "kind": "launcher"},
	{"at": 38.0, "kind": "tank"},
	{"at": 39.0, "kind": "interceptor", "y": 340.0},
	{"at": 43.0, "kind": "facility"},
	{"at": 46.0, "kind": "launcher"},
	{"at": 49.0, "kind": "interceptor", "y": 550.0}
]
var cursor := 0

func reset() -> void:
	cursor = 0

func phase(clock: float) -> String:
	if clock < 2: return "DEPARTURE"
	if clock < 12: return "AIR CONTACT"
	if clock < 16: return "CLEAR AIR"
	if clock < 34: return "GROUND DEFENCES"
	if clock < 38: return "REGROUP"
	if clock < DURATION: return "COMBINED ATTACK"
	return "ENCOUNTER COMPLETE"

func spawn(kind: String, x: float, y: float) -> Dictionary:
	return {"kind": kind, "x": x, "y": y, "hp": 2 if kind == "interceptor" else (7 if kind == "facility" else 3), "dead": false,
		"state": "enter" if kind == "interceptor" else "wait", "timer": 0.0, "age": 0.0, "aim": -PI + 0.08,
		"warning": 0.0, "loaded": true, "recoil": 0.0, "muzzle_flash": 0.0, "burst": 0, "cycles": 0}

func advance(game: Node2D, dt: float) -> void:
	while cursor < SCHEDULE.size() and game.mission_time >= SCHEDULE[cursor]["at"]:
		var entry: Dictionary = SCHEDULE[cursor]
		game.targets.append(spawn(entry["kind"], game.travel + game.W + 140, float(entry.get("y", game.GROUND))))
		cursor += 1
	for obj in game.targets:
		obj["prev_x"] = obj["x"]
		obj["prev_y"] = obj.get("y", game.GROUND)
		if obj["dead"] or obj["kind"] not in ["tank", "launcher", "interceptor"]:
			continue
		obj["age"] = float(obj.get("age", 0)) + dt
		obj["timer"] = maxf(0, float(obj.get("timer", 0)) - dt)
		obj["muzzle_flash"] = maxf(0, float(obj.get("muzzle_flash", 0)) - dt)
		obj["recoil"] = move_toward(float(obj.get("recoil", 0)), 0, 35 * dt)
		var sx: float = obj["x"] - game.travel
		var safe: bool = sx > game.player.x + 280 and sx < game.W - 130
		if obj["kind"] == "interceptor":
			advance_air(game, obj, sx, safe, dt)
		else:
			advance_ground(game, obj, safe, dt)
	# Passed wrecks/aircraft are not retained indefinitely; no visible popping.
	for i in range(game.targets.size() - 1, -1, -1):
		if game.targets[i]["x"] < game.travel - 850:
			game.targets.remove_at(i)

func advance_ground(game: Node2D, obj: Dictionary, safe: bool, dt: float) -> void:
	var kind: String = obj["kind"]
	var state: String = obj.get("state", "wait")
	if not safe:
		obj["warning"] = 0.0
		# Re-entering the firing window must restart a full telegraph, never surprise-fire.
		if state in ["aim", "warn"]:
			obj["state"] = "wait"
			obj["timer"] = 0.4
		return
	var base: Vector2 = Art.anchor(obj, game.GROUND) + Art.pivot(kind) * game.object_scale
	var target: Vector2 = Vector2(game.travel + game.player.x, game.player.y)
	var desired: float = (target - base).angle()
	if desired > 0: desired = -PI
	desired = clampf(desired, -PI + 0.03, -1.85)
	if state == "wait" and obj["timer"] <= 0:
		obj["state"] = "aim"
		obj["timer"] = 1.0 if kind == "tank" else 1.35
		obj["loaded"] = true
	elif state == "aim":
		obj["aim"] = rotate_toward(float(obj["aim"]), desired, dt * 1.6)
		if obj["timer"] <= 0:
			obj["state"] = "warn"
			obj["timer"] = 0.75
	elif state == "warn":
		obj["warning"] = 1.0 - float(obj["timer"]) / 0.75
		if obj["timer"] <= 0:
			shoot(game, obj)
			obj["state"] = "reload"
			obj["timer"] = 2.8 if kind == "tank" else 3.8
			obj["warning"] = 0.0
	elif state == "reload":
		if kind == "launcher":
			obj["aim"] = rotate_toward(float(obj["aim"]), -PI + 0.08, dt * 0.9)
		if obj["timer"] <= 0:
			obj["state"] = "wait"
			obj["loaded"] = true

func advance_air(game: Node2D, obj: Dictionary, sx: float, safe: bool, dt: float) -> void:
	var state: String = obj.get("state", "enter")
	var scroll: float = game.BASE_SCROLL * game.speed_options[game.speed_index]
	obj["x"] += scroll * dt
	if float(obj["age"]) > 10.0:
		obj["state"] = "exit"
		state = "exit"
	if state == "enter":
		obj["x"] -= 285.0 * dt
		if sx <= 1330:
			obj["state"] = "settle"
			obj["timer"] = 0.8
	elif state == "exit":
		obj["x"] -= 420 * dt
		obj["warning"] = 0.0
	elif not safe:
		obj["warning"] = 0.0
		obj["state"] = "settle"
		obj["timer"] = 0.8
	elif state == "settle" and obj["timer"] <= 0:
		obj["state"] = "warn"
		obj["timer"] = 0.8
	elif state == "warn":
		obj["warning"] = 1.0 - float(obj["timer"]) / 0.8
		if obj["timer"] <= 0:
			obj["state"] = "burst"
			obj["burst"] = 3
			obj["warning"] = 0.0
	elif state == "burst" and obj["timer"] <= 0:
		shoot(game, obj)
		obj["burst"] -= 1
		obj["timer"] = 0.22
		if obj["burst"] <= 0:
			obj["state"] = "reload"
			obj["timer"] = 1.6
	elif state == "reload" and obj["timer"] <= 0:
		obj["state"] = "settle"
		obj["timer"] = 0.3

func shoot(game: Node2D, obj: Dictionary) -> void:
	if game.rounds.size() >= 128 or obj["dead"]: return
	var origin := Art.muzzle_world(obj, game.GROUND, game.object_scale)
	var kind: String = obj["kind"]
	var missile := kind == "launcher"
	var direction := Vector2.LEFT if kind == "interceptor" else Vector2.RIGHT.rotated(float(obj["aim"]))
	var speed := 460.0 if kind == "interceptor" else (370.0 if missile else 440.0)
	game.rounds.append({"p": origin, "v": direction * speed, "friendly": false, "missile": missile, "damage": 1,
		"age": 0.0, "trail": 0.0, "enemy_rocket": missile, "source": kind})
	obj["muzzle_flash"] = 0.09
	obj["recoil"] = 7.0
	obj["loaded"] = not missile
	game.sfx.play_effect("rocket" if missile else "enemy")

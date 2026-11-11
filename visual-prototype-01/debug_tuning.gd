extends RefCounted
## Bounded prototype tuning. Never modifies project defaults or the repository.
const PROFILE_PATH := "user://visual_tuning_v1.cfg"
const VERSION := 1
const GROUPS := ["FLIGHT", "CANNON", "ROCKETS", "OPPOSITION", "INSPECTION"]
const SPECS := [
	{"key":"player_scale", "group":0, "label":"Ship size", "unit":"%", "min":0.40, "max":1.0, "step":0.01, "default":0.75, "hint":"Hull, hitbox and weapon mounts together; not a camera zoom."},
	{"key":"player_speed", "group":0, "label":"Movement speed", "unit":"px/s", "min":150.0, "max":900.0, "step":5.0, "default":445.0, "hint":"How quickly the ship moves within the screen."},
	{"key":"scroll_speed", "group":0, "label":"World scrolling", "unit":"px/s", "min":60.0, "max":350.0, "step":5.0, "default":145.0, "hint":"Scenery travel only. Encounter times remain unchanged."},
	{"key":"simulation_speed", "group":0, "label":"Simulation speed", "unit":"x", "min":0.25, "max":1.5, "step":0.05, "default":1.0, "hint":"Slow motion: changes motion, weapons, effects and encounter time together."},
	{"key":"cannon_rate", "group":1, "label":"Cannon fire rate", "unit":"shots/s", "min":1.0, "max":20.0, "step":0.1, "default":7.6923076923, "hint":"Held fire and rapid tapping share this cap."},
	{"key":"cannon_speed", "group":1, "label":"Cannon shot speed", "unit":"px/s", "min":400.0, "max":2200.0, "step":25.0, "default":1250.0, "hint":"Forward speed relative to the scrolling view; new shots only."},
	{"key":"cannon_damage", "group":1, "label":"Cannon damage", "unit":"HP", "min":1.0, "max":5.0, "step":1.0, "default":1.0, "hint":"Damage per new cannon round."},
	{"key":"projectile_size", "group":1, "label":"Projectile visibility", "unit":"%", "min":0.5, "max":1.5, "step":0.05, "default":1.0, "hint":"Core, glow and trail size only. Collision radii do not change."},
	{"key":"rocket_reload", "group":2, "label":"Rocket reload", "unit":"s", "min":0.25, "max":2.0, "step":0.01, "default":0.78, "hint":"Minimum interval between rocket releases."},
	{"key":"rocket_speed", "group":2, "label":"Rocket forward speed", "unit":"px/s", "min":250.0, "max":1200.0, "step":25.0, "default":675.0, "hint":"Post-ignition speed relative to the view; new rockets only."},
	{"key":"rocket_gravity", "group":2, "label":"Rocket drop acceleration", "unit":"px/s2", "min":100.0, "max":800.0, "step":25.0, "default":380.0, "hint":"Downward acceleration. No guidance or automatic targeting."},
	{"key":"blast_radius", "group":2, "label":"Rocket blast radius", "unit":"px", "min":30.0, "max":180.0, "step":5.0, "default":100.0, "hint":"Splash radius, with the existing damage falloff."},
	{"key":"object_scale", "group":3, "label":"Enemy / building size", "unit":"%", "min":0.60, "max":1.0, "step":0.01, "default":0.85, "hint":"Independent of player size; tracks and buildings remain ground-anchored."},
	{"key":"enemy_shot_speed", "group":3, "label":"Enemy projectile speed", "unit":"x", "min":0.5, "max":1.5, "step":0.05, "default":1.0, "hint":"Multiplier for new enemy shells, bursts and missiles."},
	{"key":"enemy_reload", "group":3, "label":"Enemy reload duration", "unit":"x", "min":0.5, "max":2.0, "step":0.05, "default":1.0, "hint":"Higher values give more time between attacks. Burst spacing is unchanged."},
	{"key":"warning_time", "group":3, "label":"Enemy warning duration", "unit":"x", "min":0.5, "max":2.0, "step":0.05, "default":1.0, "hint":"Higher values give more reaction time before each attack."},
	{"key":"invincible", "group":4, "label":"Invulnerable player", "default":false, "hint":"Ignore incoming damage and contact damage while inspecting."},
	{"key":"enemy_fire", "group":4, "label":"Enemy weapons enabled", "default":true, "hint":"Disable to inspect movement; applying also removes existing hostile shots."},
	{"key":"hitboxes", "group":4, "label":"Hitboxes and muzzle line", "default":false, "hint":"Show collision geometry and the cannon alignment guide."}
]

static func defaults() -> Dictionary:
	var result := {}
	for spec in SPECS:
		result[spec["key"]] = spec["default"]
	return result

static func sanitise(values: Dictionary) -> Dictionary:
	var result := defaults()
	for spec in SPECS:
		var key: String = spec["key"]
		var value: Variant = values.get(key, spec["default"])
		if typeof(spec["default"]) == TYPE_BOOL:
			if typeof(value) == TYPE_BOOL: result[key] = value
		elif typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)):
			result[key] = clampf(float(value), float(spec["min"]), float(spec["max"]))
	return result

static func rows(group: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in SPECS:
		if spec["group"] == group: result.append(spec)
	return result

static func format_value(spec: Dictionary, value: Variant) -> String:
	if typeof(value) == TYPE_BOOL: return "ON" if value else "OFF"
	var number := float(value)
	match spec["unit"]:
		"%": return "%d%%" % roundi(number * 100.0)
		"x": return "%.2fx" % number
		"s": return "%.2f s" % number
		"shots/s": return "%.2f /s" % number
	return "%d %s" % [roundi(number), spec["unit"]]

static func save_profile(values: Dictionary, path: String = PROFILE_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", VERSION)
	var safe := sanitise(values)
	for key in safe:
		config.set_value("tuning", key, safe[key])
	return config.save(path)

static func load_profile(path: String = PROFILE_PATH) -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK: return {"error":error, "values":{}}
	if config.get_value("meta", "version", -1) != VERSION:
		return {"error":ERR_INVALID_DATA, "values":{}}
	var values := {}
	for spec in SPECS:
		values[spec["key"]] = config.get_value("tuning", spec["key"], spec["default"])
	return {"error":OK, "values":sanitise(values)}

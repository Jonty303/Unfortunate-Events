extends RefCounted
## Layered, alpha-clean mechanical study assets. Weapon geometry is shared with simulation.
const TextureLibrary = preload("res://enemy_texture_library.gd")
static var TANK_BODY: Texture2D = TextureLibrary.tank_body()
static var TURRET: Texture2D = TextureLibrary.tank_turret()
const BARREL = preload("res://art/enemies/tank_barrel.svg")
static var LAUNCHER_BODY: Texture2D = TextureLibrary.launcher_body()
const RAIL = preload("res://art/enemies/launch_rail.svg")
const SAM = preload("res://art/enemies/sam.svg")
const AIRCRAFT = preload("res://art/enemies/interceptor.png")
const AMBER := Color("ffc776")

static func anchor(obj: Dictionary, ground: float) -> Vector2:
	return Vector2(obj["x"], float(obj.get("y", ground)))

static func pivot(kind: String) -> Vector2:
	return Vector2(-43, -82) if kind == "tank" else Vector2(26, -64)

static func muzzle_local(obj: Dictionary) -> Vector2:
	if obj["kind"] == "interceptor":
		return Vector2(-114, 18)
	var angle: float = obj.get("aim", -PI)
	var extension := Vector2(82.0 - float(obj.get("recoil", 0)), 0) if obj["kind"] == "tank" else Vector2(99, -25)
	return pivot(obj["kind"]) + extension.rotated(angle)

static func muzzle_world(obj: Dictionary, ground: float, factor: float) -> Vector2:
	return anchor(obj, ground) + muzzle_local(obj) * factor

static func draw(canvas: Node2D, obj: Dictionary, ground: float, travel: float, factor: float, clock: float) -> void:
	var at := anchor(obj, ground) - Vector2(travel, 0)
	var dead: bool = obj["dead"]
	var tint := Color("4d5153") if dead else (Color(1.0, 0.72, 0.48) if float(obj.get("flash", 0)) > 0 else Color.WHITE)
	canvas.draw_set_transform(at, 0, Vector2.ONE * factor)
	match obj["kind"]:
		"tank":
			canvas.draw_texture_rect(TANK_BODY, Rect2(-122, -66, 240, 66), false, tint)
			canvas.draw_texture_rect(TURRET, Rect2(-60, -104 if not dead else -72, 125, 48 if not dead else 30), false, tint)
			var angle: float = obj.get("aim", -PI)
			var base := pivot("tank") if not dead else Vector2(-43, -52)
			canvas.draw_set_transform(at + base * factor, angle if not dead else -2.9, Vector2.ONE * factor)
			canvas.draw_texture_rect(BARREL, Rect2(-float(obj.get("recoil", 0)), -16, 86, 32), false, tint)
		"launcher":
			canvas.draw_texture_rect(LAUNCHER_BODY, Rect2(-127, -65, 254, 65), false, tint)
			canvas.draw_line(Vector2(25, -35), Vector2(26, -64), Color("64767a") * tint, 13, true)
			var angle: float = obj.get("aim", -PI + 0.08)
			canvas.draw_set_transform(at + pivot("launcher") * factor, angle if not dead else -0.25, Vector2.ONE * factor)
			canvas.draw_texture_rect(RAIL, Rect2(0, -24, 100, 48), false, tint)
			if not dead and bool(obj.get("loaded", true)):
				canvas.draw_texture_rect(SAM, Rect2(4, -42, 96, 34), false, tint)
		"interceptor":
			if not dead:
				var flicker := 0.93 + 0.07 * sin(clock * 43.0)
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(79, 9), Vector2(79 + 42 * flicker, 17), Vector2(79, 25)]), Color(1.0, 0.33, 0.14, 0.4))
				canvas.draw_line(Vector2(80, 17), Vector2(80 + 24 * flicker, 17), Color("ffcf88"), 5, true)
				canvas.draw_texture_rect(AIRCRAFT, Rect2(-105, -44, 210, 89), false, tint)
				canvas.draw_line(Vector2(-89, 18), Vector2(-114, 18), Color("25323b"), 5, true)
				canvas.draw_line(Vector2(-89, 16), Vector2(-113, 16), Color("b7b9ad"), 1.5, true)
	canvas.draw_set_transform(at, 0, Vector2.ONE * factor)
	if dead:
		# Low, bounded fire: the wreck stays in the world until scrolled out of view.
		var age: float = obj.get("dead_age", 0)
		if age < 7.0 and obj["kind"] != "interceptor":
			var fade := clampf((7.0 - age) / 3.0, 0.0, 1.0)
			var height := 20.0 + 7.0 * sin(clock * 15.0 + float(obj["x"]))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-12, -38), Vector2(-5, -38-height), Vector2(3, -47), Vector2(13, -64), Vector2(20, -38)]), Color(1.0, 0.38, 0.09, 0.65 * fade))
	else:
		var warning: float = obj.get("warning", 0)
		var muzzle := muzzle_local(obj)
		if warning > 0:
			canvas.draw_circle(muzzle, 11.0 + warning * 5.0, Color(1.0, 0.37, 0.10, 0.12 + warning * 0.08))
			canvas.draw_circle(muzzle, 3.5, AMBER)
		if float(obj.get("muzzle_flash", 0)) > 0:
			var dir := Vector2.LEFT if obj["kind"] == "interceptor" else Vector2.RIGHT.rotated(float(obj.get("aim", -PI)))
			var normal := dir.orthogonal()
			canvas.draw_colored_polygon(PackedVector2Array([muzzle + normal * 9, muzzle + dir * 34, muzzle - normal * 9]), Color(1.0, 0.65, 0.25, 0.8))
			canvas.draw_line(muzzle, muzzle + dir * 19, Color("fff4d4"), 4, true)
	canvas.draw_set_transform(Vector2.ZERO)

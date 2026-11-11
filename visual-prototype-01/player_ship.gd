extends Node2D
## Reusable presentation and hardpoints. Simulation owns world motion and damage.
const HULL = preload("res://art/06_antique_shuttle.png")
const ART_RECT := Rect2(-120, -68, 238, 137)
const VISIBLE_BOUNDS := Rect2(-120, -68, 252, 142)
const HIT_BOX := Rect2(-85, -28, 177, 68)
const CYAN := Color(0.35, 0.88, 1.0)
@onready var barrel: Node2D = $Cannon/Barrel
@onready var muzzle: Marker2D = $Cannon/Barrel/Muzzle
@onready var rocket_rail: Marker2D = $RocketRail
@onready var engine_upper: Marker2D = $EngineUpper
@onready var engine_lower: Marker2D = $EngineLower
var recoil := 0.0
var muzzle_time := 0.0
var engine_time := 0.0
var thrust := 1.0
var manoeuvre := Vector2.ZERO
var hit_time := 0.0
var rocket_ready := true

func reset_visuals() -> void:
	recoil = 0.0
	muzzle_time = 0.0
	hit_time = 0.0
	rotation = 0.0
	barrel.position = Vector2.ZERO
	visible = true
	queue_redraw()

func advance(dt: float, axis: Vector2, ready: bool) -> void:
	engine_time += dt
	manoeuvre = axis
	# Moving left on screen is still forward flight: retain at least cruising thrust.
	thrust = lerpf(thrust, 1.0 + maxf(axis.x, 0.0) * 0.35 + absf(axis.y) * 0.10, minf(dt * 8.0, 1.0))
	rotation = lerp_angle(rotation, axis.y * 0.025, minf(dt * 9.0, 1.0))
	recoil = move_toward(recoil, 0.0, dt * 42.0)
	barrel.position.x = -recoil
	muzzle_time = maxf(0.0, muzzle_time - dt)
	hit_time = maxf(0.0, hit_time - dt)
	rocket_ready = ready
	queue_redraw()

func fire() -> void:
	recoil = 3.5
	barrel.position.x = -recoil
	muzzle_time = 0.055
	queue_redraw()

func hit() -> void:
	hit_time = 0.16
	queue_redraw()

func muzzle_point() -> Vector2:
	return muzzle.global_position

func muzzle_direction() -> Vector2:
	return muzzle.global_transform.x.normalized()

func rocket_point() -> Vector2:
	return rocket_rail.global_position

func relative_bounds() -> Rect2:
	# Conservative bounds include tail, gun and loaded belly rail after bank/scale.
	var first := VISIBLE_BOUNDS.position.rotated(rotation) * scale
	var result := Rect2(first, Vector2.ZERO)
	for corner in [Vector2(VISIBLE_BOUNDS.end.x, VISIBLE_BOUNDS.position.y), VISIBLE_BOUNDS.end, Vector2(VISIBLE_BOUNDS.position.x, VISIBLE_BOUNDS.end.y)]:
		result = result.expand(corner.rotated(rotation) * scale)
	return result

func local_hit_box() -> Rect2:
	# Deliberately forgiving central hull, excluding the tail and cosmetic exhaust.
	return Rect2(HIT_BOX.position * scale, HIT_BOX.size * scale)

func draw_plume(at: Vector2, direction: Vector2, length: float, width: float, intensity: float) -> void:
	var normal := direction.orthogonal()
	var tip := at + direction * length
	draw_colored_polygon(PackedVector2Array([at + normal * width, at + direction * length * 0.35 + normal * width * 0.8, tip, at + direction * length * 0.35 - normal * width * 0.8, at - normal * width]), Color(0.12, 0.55, 1.0, 0.13 * intensity))
	draw_colored_polygon(PackedVector2Array([at + normal * width * 0.45, at + direction * length * 0.7, at - normal * width * 0.45]), Color(0.20, 0.78, 1.0, 0.65 * intensity))
	draw_line(at, at + direction * length * 0.38, Color(0.83, 0.97, 1.0, intensity), width * 0.25, true)

func _draw() -> void:
	if not is_node_ready():
		return
	var shimmer := 0.94 + sin(engine_time * 37.0) * 0.045 + sin(engine_time * 61.0) * 0.025
	draw_plume(engine_upper.position, Vector2.LEFT, 61.0 * thrust * shimmer, 15, 0.88)
	draw_plume(engine_lower.position, Vector2.LEFT, 54.0 * thrust / shimmer, 13, 0.84)
	draw_texture_rect(HULL, ART_RECT, false, Color(1.0, 0.70, 0.53) if hit_time > 0 else Color.WHITE)
	# Fixed mounting plate and separate recoiling barrel: both share the muzzle transform.
	var base: Vector2 = $Cannon.position
	draw_style_box(metal_panel(Color("263643"), Color("9ba8ad")), Rect2(base + Vector2(-12, -10), Vector2(35, 20)))
	draw_line(base + Vector2(-8, -7), base + Vector2(18, -7), Color("d8d8c6"), 2, true)
	var breech := base + barrel.position
	draw_line(breech + Vector2(13, 0), breech + Vector2(55, 0), Color("111a22"), 10, true)
	draw_line(breech + Vector2(14, -2), breech + Vector2(55, -2), Color("a7b4b8"), 3, true)
	for x in [22, 30, 38]:
		draw_line(breech + Vector2(x, -5), breech + Vector2(x, 5), Color("566972"), 2, true)
	draw_rect(Rect2(breech + Vector2(53, -6), Vector2(7, 12)), Color("455661"))
	draw_line(breech + Vector2(58, -4), breech + Vector2(58, 4), Color("080e16"), 2, true)
	for bolt in [Vector2(-6, -5), Vector2(16, 5)]:
		draw_circle(base + bolt, 1.8, Color("d2be98"))
	# The loaded rocket is attached to the rail, not baked into the hull image.
	var rail := rocket_rail.position
	draw_line(rail + Vector2(-21, -8), rail + Vector2(21, -8), Color("5b6666"), 5, true)
	for x in [-14, 14]:
		draw_line(rail + Vector2(x, -17), rail + Vector2(x, -5), Color("b4aaa0"), 3, true)
	if rocket_ready:
		draw_colored_polygon(PackedVector2Array([rail + Vector2(-22, -5), rail + Vector2(15, -5), rail + Vector2(25, 0), rail + Vector2(15, 5), rail + Vector2(-22, 5)]), Color("cdd4cc"))
		draw_line(rail + Vector2(-6, -5), rail + Vector2(-6, 5), Color("a34f36"), 4)
	if absf(manoeuvre.y) > 0.2:
		var at: Vector2 = $LowerThruster.position if manoeuvre.y < 0 else $UpperThruster.position
		draw_plume(at, Vector2.DOWN if manoeuvre.y < 0 else Vector2.UP, 18.0 + 9.0 * absf(manoeuvre.y), 5, 0.8)
	if manoeuvre.x < -0.25:
		draw_plume(Vector2(103, 16), Vector2.RIGHT, 14.0, 4, 0.65)
	if muzzle_time > 0:
		var at := to_local(muzzle.global_position)
		draw_plume(at, Vector2.RIGHT, 25.0, 10, minf(1.0, muzzle_time / 0.025))

func metal_panel(fill: Color, rim: Color) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = fill
	panel.border_color = rim
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(3)
	return panel

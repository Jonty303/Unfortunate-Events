extends RefCounted
## Swept point against an expanded AABB. Returns earliest t in [0,1], or -1.
## Callers expand by projectile radius, NOT by the decorative glow/trail size.
static func segment_fraction(a: Vector2, b: Vector2, box: Rect2) -> float:
	var direction := b - a
	var enter := 0.0
	var leave := 1.0
	for axis in range(2):
		if absf(direction[axis]) < 0.000001:
			if a[axis] < box.position[axis] or a[axis] > box.end[axis]:
				return -1.0
		else:
			var first: float = (box.position[axis] - a[axis]) / direction[axis]
			var last: float = (box.end[axis] - a[axis]) / direction[axis]
			enter = maxf(enter, minf(first, last))
			leave = minf(leave, maxf(first, last))
			if enter > leave:
				return -1.0
	return enter

static func distance_to_box(point: Vector2, box: Rect2) -> float:
	return point.distance_to(Vector2(clampf(point.x, box.position.x, box.end.x), clampf(point.y, box.position.y, box.end.y)))

static func blast_damage(distance: float, radius: float = 100.0) -> int:
	if distance >= radius:
		return 0
	if distance <= 30.0:
		return 3
	return maxi(1, ceili(3.0 * (1.0 - distance / radius)))

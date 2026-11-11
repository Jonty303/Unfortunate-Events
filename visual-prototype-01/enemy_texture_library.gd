extends RefCounted
## Non-destructive alpha extraction from the existing painted concept crops.
## Cached once on load; never performed per frame. Points are in original source pixels.
static func clipped(source: Texture2D, region: Rect2i, outline: PackedVector2Array, flip: bool = false) -> Texture2D:
	var original := source.get_image()
	var image := original.get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var coverage := 0.0
			for offset in [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]:
				if Geometry2D.is_point_in_polygon(Vector2(x + region.position.x, y + region.position.y) + offset, outline):
					coverage += 0.25
			var pixel := image.get_pixel(x, y)
			pixel.a *= coverage
			image.set_pixel(x, y, pixel)
	if flip: image.flip_x()
	return ImageTexture.create_from_image(image)

static func tank_body() -> Texture2D:
	return clipped(preload("res://art/07_tank.png"), Rect2i(26, 55, 208, 52), PackedVector2Array([
		Vector2(28,65), Vector2(38,58), Vector2(74,55), Vector2(91,59), Vector2(185,61), Vector2(211,70), Vector2(227,75), Vector2(232,86), Vector2(223,95), Vector2(210,102), Vector2(190,107), Vector2(51,107), Vector2(37,99), Vector2(34,87), Vector2(27,83)]))

static func tank_turret() -> Texture2D:
	return clipped(preload("res://art/07_tank.png"), Rect2i(80, 22, 91, 40), PackedVector2Array([
		Vector2(81,54),Vector2(89,39),Vector2(104,32),Vector2(111,24),Vector2(123,24),Vector2(124,32),Vector2(147,33),Vector2(160,38),Vector2(169,47),Vector2(160,57),Vector2(143,60),Vector2(96,59)]), true)

static func launcher_body() -> Texture2D:
	return clipped(preload("res://art/08_launcher.png"), Rect2i(42, 104, 217, 59), PackedVector2Array([
		Vector2(44,128),Vector2(49,110),Vector2(68,106),Vector2(114,106),Vector2(120,115),Vector2(190,113),Vector2(207,113),Vector2(213,123),Vector2(246,124),Vector2(257,137),Vector2(253,154),Vector2(231,161),Vector2(129,161),Vector2(126,153),Vector2(109,157),Vector2(70,160),Vector2(55,151),Vector2(45,140)]))

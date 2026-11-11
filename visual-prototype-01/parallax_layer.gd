extends Node2D
## A raster image plane scrolling at a fraction of world speed.
## Decorative art has no hitboxes. The gameplay world uses shared world_x coordinates.
var art: Texture2D
var speed: float = 0.0
var top: float = 0.0
var travel: float = 0.0

func configure(texture: Texture2D, speed_fraction: float, screen_top: float, z: int) -> void:
	art = texture
	speed = speed_fraction
	top = screen_top
	z_index = z

func set_travel(value: float) -> void:
	travel = value
	queue_redraw()

func _draw() -> void:
	if art == null:
		return
	var tile_width: float = art.get_width()
	if tile_width <= 0:
		return
	var shift: float = fposmod(travel * speed, tile_width)
	var tiles: int = ceili(1920.0 / tile_width) + 2
	for i in range(-1, tiles):
		draw_texture(art, Vector2(i * tile_width - shift, top))

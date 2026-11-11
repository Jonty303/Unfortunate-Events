extends Control
## Optional multi-touch overlay; only owns its own pointer state, never global input actions.
## Authored in the same 1920x1080 canvas as the visual test; no gameplay rescaling.
signal pause_requested
signal restart_requested
signal debug_requested
signal speed_requested
signal mode_changed

enum TouchMode { AUTO, ON, OFF }
const SETTINGS_PATH := "user://touch_controls.cfg"
const STICK_CENTRE := Vector2(205, 953)
const STICK_RADIUS := 86.0
const STICK_ZONE := Rect2(40, 842, 445, 224)
const FIRE_CENTRE := Vector2(1740, 953)
const ROCKET_CENTRE := Vector2(1545, 967)
const FIRE_RADIUS := 83.0
const ROCKET_RADIUS := 67.0
const MODE_RECT := Rect2(1680, 14, 214, 66)
const DEAD_ZONE := 0.14
const CYAN := Color(0.35, 0.88, 1.0)
const AMBER := Color(1.0, 0.65, 0.30)
const UTILITY_RECTS := {
	"pause": Rect2(573, 928, 136, 77),
	"restart": Rect2(733, 928, 136, 77),
	"debug": Rect2(893, 928, 136, 77),
	"speed": Rect2(1053, 928, 136, 77)
}

var mode: int = TouchMode.AUTO
var movement := Vector2.ZERO
var fire_held := false
var rocket_held := false
var game_paused := false
var touch_seen := false
var touch_capable := false
var stick_finger := -999
var stick_tip := STICK_CENTRE
# Pointer IDs >= 0 belong to real fingers. -1 is the optional desktop mouse.
var captures: Dictionary = {}
var button_inside: Dictionary = {}
var save_preferences := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_capable = DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_capable = touch_capable or bool(JavaScriptBridge.eval("(navigator.maxTouchPoints || 0) > 0"))
	var preferences := ConfigFile.new()
	if preferences.load(SETTINGS_PATH) == OK:
		mode = clampi(int(preferences.get_value("touch", "mode", TouchMode.AUTO)), 0, 2)
	if "--touch" in OS.get_cmdline_user_args():
		mode = TouchMode.ON
	queue_redraw()

func controls_visible() -> bool:
	return mode == TouchMode.ON or (mode == TouchMode.AUTO and (touch_capable or touch_seen))

func set_mode(value: int) -> void:
	mode = clampi(value, 0, 2)
	release_all()
	if save_preferences:
		var preferences := ConfigFile.new()
		preferences.set_value("touch", "mode", mode)
		preferences.save(SETTINGS_PATH)
	mode_changed.emit()
	queue_redraw()

func cycle_mode() -> void:
	set_mode((mode + 1) % 3)

func release_all() -> void:
	captures.clear()
	button_inside.clear()
	stick_finger = -999
	movement = Vector2.ZERO
	stick_tip = STICK_CENTRE
	fire_held = false
	rocket_held = false
	queue_redraw()

func set_game_paused(value: bool) -> void:
	if game_paused != value:
		release_all()
	game_paused = value
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()

func _input(event: InputEvent) -> void:
	var consumed := false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if not touch_seen:
				touch_seen = true
				mode_changed.emit()
				queue_redraw()
			consumed = press_pointer(event.index, event.position)
		else:
			consumed = release_pointer(event.index)
	elif event is InputEventScreenDrag:
		consumed = drag_pointer(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			consumed = press_pointer(-1, event.position)
		else:
			consumed = release_pointer(-1)
	elif event is InputEventMouseMotion:
		consumed = drag_pointer(-1, event.position)
	if consumed:
		get_viewport().set_input_as_handled()

func control_at(pos: Vector2) -> String:
	if MODE_RECT.has_point(pos):
		return "mode"
	if not controls_visible():
		return ""
	for key in UTILITY_RECTS:
		if UTILITY_RECTS[key].has_point(pos):
			return key
	if pos.distance_to(FIRE_CENTRE) <= FIRE_RADIUS:
		return "fire"
	if pos.distance_to(ROCKET_CENTRE) <= ROCKET_RADIUS:
		return "rocket"
	if STICK_ZONE.has_point(pos):
		return "stick"
	return ""

func press_pointer(index: int, pos: Vector2) -> bool:
	var action := control_at(pos)
	if action.is_empty():
		return false
	if action == "mode":
		cycle_mode()
		# Retain ownership until release so clicking the selector never fires the cannon.
		captures[index] = "utility"
		return true
	if action in ["pause", "restart", "debug", "speed"]:
		match action:
			"pause": pause_requested.emit()
			"restart": restart_requested.emit()
			"debug": debug_requested.emit()
			"speed": speed_requested.emit()
		captures[index] = "utility"
		return true
	if game_paused:
		captures[index] = "utility"
		return true
	if action == "stick":
		if stick_finger != -999:
			captures[index] = "utility"
			return true
		stick_finger = index
	captures[index] = action
	update_pointer(index, pos)
	return true

func drag_pointer(index: int, pos: Vector2) -> bool:
	if not captures.has(index):
		return false
	update_pointer(index, pos)
	return true

func update_pointer(index: int, pos: Vector2) -> void:
	var action: String = captures.get(index, "")
	if action == "stick" and index == stick_finger:
		var offset := (pos - STICK_CENTRE).limit_length(STICK_RADIUS)
		stick_tip = STICK_CENTRE + offset
		var strength := offset.length() / STICK_RADIUS
		movement = Vector2.ZERO
		if strength > DEAD_ZONE:
			movement = offset.normalized() * ((strength - DEAD_ZONE) / (1.0 - DEAD_ZONE))
	elif action == "fire":
		button_inside[index] = pos.distance_to(FIRE_CENTRE) <= FIRE_RADIUS + 18.0
	elif action == "rocket":
		button_inside[index] = pos.distance_to(ROCKET_CENTRE) <= ROCKET_RADIUS + 18.0
	refresh_buttons()
	queue_redraw()

func release_pointer(index: int) -> bool:
	if not captures.has(index):
		return false
	if index == stick_finger:
		stick_finger = -999
		movement = Vector2.ZERO
		stick_tip = STICK_CENTRE
	captures.erase(index)
	button_inside.erase(index)
	refresh_buttons()
	queue_redraw()
	return true

func refresh_buttons() -> void:
	fire_held = false
	rocket_held = false
	for index in captures:
		if not button_inside.get(index, false):
			continue
		fire_held = fire_held or captures[index] == "fire"
		rocket_held = rocket_held or captures[index] == "rocket"

func blocks_mouse_fire() -> bool:
	# Input polling ignores set_input_as_handled(), so explicitly exclude UI clicks.
	return captures.has(-1) or not control_at(get_global_mouse_position()).is_empty()

func draw_text_centre(text: String, centre: Vector2, font_size: int, tint: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, centre + Vector2(-width * 0.5, font_size * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

func draw_round_button(centre: Vector2, radius: float, text: String, tint: Color, held: bool) -> void:
	draw_circle(centre, radius, Color(0.025, 0.045, 0.07, 0.55))
	if held:
		draw_circle(centre, radius - 4.0, Color(tint, 0.26))
	draw_arc(centre, radius, 0, TAU, 64, Color(tint, 0.82 if held else 0.50), 3.0, true)
	draw_text_centre(text, centre, 26, tint)

func _draw() -> void:
	var mode_names := ["AUTO", "ON", "OFF"]
	draw_style_box(make_panel(), MODE_RECT)
	draw_text_centre("TOUCH: " + mode_names[mode], MODE_RECT.get_center(), 24, CYAN)
	if not controls_visible():
		return
	draw_circle(STICK_CENTRE, STICK_RADIUS + 14.0, Color(0.025, 0.045, 0.07, 0.44))
	draw_arc(STICK_CENTRE, STICK_RADIUS, 0, TAU, 64, Color(CYAN, 0.46), 3.0, true)
	draw_line(STICK_CENTRE - Vector2(18, 0), STICK_CENTRE + Vector2(18, 0), Color(CYAN, 0.30), 2)
	draw_line(STICK_CENTRE - Vector2(0, 18), STICK_CENTRE + Vector2(0, 18), Color(CYAN, 0.30), 2)
	draw_circle(stick_tip, 37, Color(CYAN, 0.42 if stick_finger != -999 else 0.20))
	draw_arc(stick_tip, 37, 0, TAU, 40, Color(CYAN, 0.8), 2, true)
	draw_round_button(FIRE_CENTRE, FIRE_RADIUS, "FIRE", CYAN, fire_held)
	draw_round_button(ROCKET_CENTRE, ROCKET_RADIUS, "ROCKET", AMBER, rocket_held)
	for action in UTILITY_RECTS:
		var rect: Rect2 = UTILITY_RECTS[action]
		draw_style_box(make_panel(), rect)
		var caption: String = "RESUME" if action == "pause" and game_paused else str(action).to_upper()
		draw_text_centre(caption, rect.get_center(), 23, Color("d0e6ed"))

func make_panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.025, 0.045, 0.07, 0.58)
	panel.border_color = Color(CYAN, 0.4)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	return panel

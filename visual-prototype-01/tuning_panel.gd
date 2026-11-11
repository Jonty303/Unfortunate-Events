extends Control
## Touch-native modal: no global mouse emulation and no input leakage into play.
signal opened
signal finished(values: Dictionary, apply_changes: bool, restart: bool)
const Tuning = preload("res://debug_tuning.gd")
const LAUNCH := Rect2(1305, 17, 190, 55)
const PANEL := Rect2(250, 140, 1420, 800)
const CYAN := Color("82dce7")
const INK := Color("111f2b")
const PAPER := Color("e1edf2")
const MUTED := Color("99b0be")
const FOOTERS := ["Defaults", "Save preset", "Load preset", "Cancel", "Apply / restart", "Apply / return"]
var panel_open := false
var draft := Tuning.defaults()
var group := 0
var selected_row := 0
var captures: Dictionary = {}
var status := "Changes are staged until Apply. Saving stores one preset on this device."
var profile_path := Tuning.PROFILE_PATH
var source_values: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_panel(values: Dictionary) -> void:
	draft = Tuning.sanitise(values)
	panel_open = true
	captures.clear()
	status = "PAUSED - changes apply only when you choose Apply."
	opened.emit()
	queue_redraw()

func close_panel(apply_changes: bool, restart: bool = false) -> void:
	if not panel_open: return
	panel_open = false
	captures.clear()
	finished.emit(Tuning.sanitise(draft), apply_changes, restart)
	queue_redraw()

func row_y(index: int) -> float:
	return 320.0 + index * 103.0

func slider_rect(index: int) -> Rect2:
	return Rect2(758, row_y(index) - 8, 470, 65)

func decrement_rect(index: int) -> Rect2:
	return Rect2(674, row_y(index) - 8, 64, 65)

func increment_rect(index: int) -> Rect2:
	return Rect2(1248, row_y(index) - 8, 64, 65)

func toggle_rect(index: int) -> Rect2:
	return Rect2(1160, row_y(index) - 8, 300, 65)

func footer_rect(index: int) -> Rect2:
	return Rect2(280 + index * 226, 826, 214, 64)

func action_at(pos: Vector2) -> String:
	if not panel_open: return "open" if LAUNCH.has_point(pos) else ""
	for i in Tuning.GROUPS.size():
		if Rect2(280 + i * 273, 241, 262, 57).has_point(pos): return "tab:%d" % i
	for i in Tuning.rows(group).size():
		var spec: Dictionary = Tuning.rows(group)[i]
		if typeof(spec["default"]) == TYPE_BOOL:
			if toggle_rect(i).has_point(pos): return "toggle:%d" % i
		else:
			if slider_rect(i).has_point(pos): return "slider:%d" % i
			if decrement_rect(i).has_point(pos): return "dec:%d" % i
			if increment_rect(i).has_point(pos): return "inc:%d" % i
	for i in FOOTERS.size():
		if footer_rect(i).has_point(pos): return "footer:%d" % i
	return "block"

func press_pointer(index: int, pos: Vector2) -> bool:
	var action := action_at(pos)
	if action.is_empty(): return false
	# Only one finger owns a slider at a time.
	if action.begins_with("slider:") and captures.values().has(action): action = "block"
	captures[index] = action
	if action.begins_with("slider:"):
		selected_row = int(action.get_slice(":", 1))
		set_slider(selected_row, pos.x)
	queue_redraw()
	return true

func drag_pointer(index: int, pos: Vector2) -> bool:
	if not captures.has(index): return panel_open
	var action: String = captures[index]
	if action.begins_with("slider:"):
		set_slider(int(action.get_slice(":", 1)), pos.x)
	return true

func release_pointer(index: int, pos: Vector2, canceled: bool = false) -> bool:
	if not captures.has(index): return panel_open
	var action: String = captures[index]
	captures.erase(index)
	if not canceled and action == action_at(pos) and not action.begins_with("slider:"):
		activate(action)
	queue_redraw()
	return true

func set_slider(index: int, x: float) -> void:
	var spec: Dictionary = Tuning.rows(group)[index]
	var fraction := clampf((x - slider_rect(index).position.x) / slider_rect(index).size.x, 0, 1)
	var value := lerpf(spec["min"], spec["max"], fraction)
	draft[spec["key"]] = clampf(snappedf(value, spec["step"]), spec["min"], spec["max"])
	queue_redraw()

func adjust(index: int, direction: float) -> void:
	var spec: Dictionary = Tuning.rows(group)[index]
	var key: String = spec["key"]
	if typeof(spec["default"]) == TYPE_BOOL:
		draft[key] = not draft[key]
	else:
		draft[key] = clampf(snappedf(float(draft[key]) + direction * float(spec["step"]), spec["step"]), spec["min"], spec["max"])
	queue_redraw()

func activate(action: String) -> void:
	var index := int(action.get_slice(":", 1))
	if action == "open":
		open_panel(source_values.call() if source_values.is_valid() else Tuning.defaults())
	elif action.begins_with("tab:"):
		group = index
		selected_row = 0
		captures.clear()
	elif action.begins_with("inc:") or action.begins_with("dec:") or action.begins_with("toggle:"):
		selected_row = index
		adjust(index, -1.0 if action.begins_with("dec:") else 1.0)
	elif action.begins_with("footer:"):
		match index:
			0:
				draft = Tuning.defaults()
				status = "Original 01C defaults staged. Apply to use them; Save to replace your saved preset."
			1:
				var error := Tuning.save_profile(draft, profile_path)
				status = "Preset saved on this device. Apply to use it now." if error == OK else "Could not save preset: %s" % error_string(error)
			2:
				var loaded := Tuning.load_profile(profile_path)
				if loaded["error"] == OK:
					draft = loaded["values"]
					status = "Saved preset loaded into panel. Apply to use it."
				else: status = "No readable saved preset (%s). Current values kept." % error_string(loaded["error"])
			3: close_panel(false)
			4: close_panel(true, true)
			5: close_panel(true)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		captures.clear()
		queue_redraw()

func _input(event: InputEvent) -> void:
	var consumed := panel_open
	if event is InputEventScreenTouch:
		consumed = press_pointer(event.index, event.position) if event.pressed and not event.canceled else release_pointer(event.index, event.position, event.canceled)
	elif event is InputEventScreenDrag:
		consumed = drag_pointer(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		consumed = press_pointer(-1, event.position) if event.pressed else release_pointer(-1, event.position)
	elif event is InputEventMouseMotion:
		consumed = drag_pointer(-1, event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F4:
			if panel_open: close_panel(false)
			else: activate("open")
			consumed = true
		elif panel_open:
			match event.physical_keycode:
				KEY_ESCAPE: close_panel(false)
				KEY_UP: selected_row = posmod(selected_row - 1, Tuning.rows(group).size())
				KEY_DOWN: selected_row = (selected_row + 1) % Tuning.rows(group).size()
				KEY_LEFT: adjust(selected_row, -1)
				KEY_RIGHT: adjust(selected_row, 1)
				KEY_PAGEUP: activate("tab:%d" % posmod(group - 1, Tuning.GROUPS.size()))
				KEY_PAGEDOWN: activate("tab:%d" % ((group + 1) % Tuning.GROUPS.size()))
				KEY_ENTER: close_panel(true)
			queue_redraw()
	elif panel_open and event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_B, JOY_BUTTON_START: close_panel(false)
			JOY_BUTTON_DPAD_UP: selected_row = posmod(selected_row - 1, Tuning.rows(group).size())
			JOY_BUTTON_DPAD_DOWN: selected_row = (selected_row + 1) % Tuning.rows(group).size()
			JOY_BUTTON_DPAD_LEFT: adjust(selected_row, -1)
			JOY_BUTTON_DPAD_RIGHT: adjust(selected_row, 1)
			JOY_BUTTON_LEFT_SHOULDER: activate("tab:%d" % posmod(group - 1, Tuning.GROUPS.size()))
			JOY_BUTTON_RIGHT_SHOULDER: activate("tab:%d" % ((group + 1) % Tuning.GROUPS.size()))
			JOY_BUTTON_A: close_panel(true)
		queue_redraw()
	if consumed: get_viewport().set_input_as_handled()

func text(at: Vector2, content: String, font_size: int = 24, color: Color = PAPER) -> void:
	draw_string(ThemeDB.fallback_font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func button(rect: Rect2, label: String, active: bool = false) -> void:
	draw_rect(rect, Color("224753") if active else Color("1c303d"))
	draw_rect(rect, CYAN if active else Color("47616f"), false, 2)
	var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 23).x
	text(rect.position + Vector2((rect.size.x - width) * 0.5, rect.size.y * 0.5 + 8), label, 23)

func _draw() -> void:
	if not panel_open:
		button(LAUNCH, "TUNING / F4")
		return
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.015, 0.025, 0.035, 0.68))
	draw_rect(PANEL, INK)
	draw_rect(PANEL, Color("3d7787"), false, 2)
	text(Vector2(280, 188), "01D  /  FLIGHT & COMBAT TUNING", 30)
	text(Vector2(280, 219), "PAUSED   |   Drag sliders or tap - / +.   Values use the 1920 x 1080 world, not device pixels.", 21, MUTED)
	for i in Tuning.GROUPS.size(): button(Rect2(280 + i * 273, 241, 262, 57), Tuning.GROUPS[i], i == group)
	var specs := Tuning.rows(group)
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var y := row_y(i)
		if i == selected_row: draw_rect(Rect2(274, y - 13, 1372, 95), Color("172c38"))
		text(Vector2(296, y + 24), spec["label"], 26)
		text(Vector2(296, y + 74), spec["hint"], 20, MUTED)
		var value: Variant = draft[spec["key"]]
		if typeof(spec["default"]) == TYPE_BOOL:
			button(toggle_rect(i), "ON" if value else "OFF", value)
		else:
			button(decrement_rect(i), "-")
			button(increment_rect(i), "+")
			var track := slider_rect(i)
			var fraction := (float(value) - float(spec["min"])) / (float(spec["max"]) - float(spec["min"]))
			var start := Vector2(track.position.x, y + 24)
			draw_line(start, start + Vector2(track.size.x, 0), Color("38515e"), 9, true)
			draw_line(start, start + Vector2(track.size.x * fraction, 0), CYAN, 9, true)
			draw_circle(start + Vector2(track.size.x * fraction, 0), 17, PAPER)
			text(Vector2(1334, y + 32), Tuning.format_value(spec, value), 25, CYAN)
	if group == 4:
		text(Vector2(296, 708), "Inspection helpers are not upgrades. No shields, homing or scoring changes.", 23, MUTED)
	text(Vector2(296, 778), "Apply / return keeps the encounter. Existing projectiles keep their launch speed.", 22, MUTED)
	for i in FOOTERS.size(): button(footer_rect(i), FOOTERS[i], i >= 4)
	text(Vector2(280, 921), status, 20, MUTED)

extends Control
## Multi-touch controls for Godot 4.5; separate fingers for movement and weapons.
const JOY_CENTER := Vector2(215, 840)
const JOY_RADIUS := 112.0
const FIRE_CENTER := Vector2(1702, 838)
const ROCKET_CENTER := Vector2(1488, 912)
const BUTTON_RADIUS := 94.0
const PAUSE_RECT := Rect2(1740, 72, 140, 76)
const CYAN := Color(0.42, 0.89, 1.0)
var visible_controls := false
var joystick_finger := -1
var joystick_direction := Vector2.ZERO
var fire_fingers: Dictionary = {}
var rocket_fingers: Dictionary = {}
var pause_fingers: Dictionary = {}
var pause_requested := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible_controls = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func set_touch_visible(enabled: bool) -> void:
    visible_controls = enabled
    if not enabled: clear_touches()
    queue_redraw()

func clear_touches() -> void:
    joystick_finger = -1
    joystick_direction = Vector2.ZERO
    fire_fingers.clear()
    rocket_fingers.clear()
    pause_fingers.clear()

func is_firing() -> bool:
    return visible_controls and not fire_fingers.is_empty()

func is_rocketing() -> bool:
    return visible_controls and not rocket_fingers.is_empty()

func take_pause_request() -> bool:
    var result := pause_requested
    pause_requested = false
    return result

func _input(event: InputEvent) -> void:
    if not visible_controls: return
    if event is InputEventScreenTouch:
        var finger: int = event.index
        if event.pressed:
            if joystick_finger < 0 and event.position.distance_to(JOY_CENTER) < 185.0:
                joystick_finger = finger
                update_joystick(event.position)
            elif event.position.distance_to(FIRE_CENTER) < BUTTON_RADIUS * 1.25:
                fire_fingers[finger] = true
            elif event.position.distance_to(ROCKET_CENTER) < BUTTON_RADIUS * 1.25:
                rocket_fingers[finger] = true
            elif PAUSE_RECT.has_point(event.position):
                pause_fingers[finger] = true
        else:
            if finger == joystick_finger:
                joystick_finger = -1
                joystick_direction = Vector2.ZERO
            if pause_fingers.has(finger) and PAUSE_RECT.has_point(event.position):
                pause_requested = true
            fire_fingers.erase(finger)
            rocket_fingers.erase(finger)
            pause_fingers.erase(finger)
        queue_redraw()
    elif event is InputEventScreenDrag and event.index == joystick_finger:
        update_joystick(event.position)
        queue_redraw()

func update_joystick(at: Vector2) -> void:
    joystick_direction = ((at - JOY_CENTER) / JOY_RADIUS).limit_length()
    if joystick_direction.length() < 0.13: joystick_direction = Vector2.ZERO

func _draw() -> void:
    if not visible_controls: return
    draw_circle(JOY_CENTER, JOY_RADIUS + 20, Color(0.02, 0.06, 0.11, 0.28))
    draw_arc(JOY_CENTER, JOY_RADIUS, 0, TAU, 72, Color(CYAN, 0.54), 4, true)
    draw_circle(JOY_CENTER + joystick_direction * JOY_RADIUS, 44, Color(CYAN, 0.44))
    draw_button(FIRE_CENTER, "CANNON", is_firing(), CYAN)
    draw_button(ROCKET_CENTER, "ROCKET", is_rocketing(), Color(1.0, 0.67, 0.32))
    draw_rect(PAUSE_RECT, Color(0.02, 0.06, 0.11, 0.45), true)
    draw_rect(PAUSE_RECT, Color(CYAN, 0.55), false, 2)
    draw_string(ThemeDB.fallback_font, PAUSE_RECT.position + Vector2(28, 47), "PAUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)

func draw_button(center: Vector2, caption: String, pressed: bool, tint: Color) -> void:
    draw_circle(center, BUTTON_RADIUS, Color(tint, 0.32 if pressed else 0.14))
    draw_arc(center, BUTTON_RADIUS, 0, TAU, 72, Color(tint, 0.95 if pressed else 0.65), 5, true)
    draw_string(ThemeDB.fallback_font, center + Vector2(-58, 10), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)

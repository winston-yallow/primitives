extends Control

var enabled = false
var timescale = 0.1

var mousemode_cache = Input.get_mouse_mode()

var remote_values := []

onready var info: ColorRect = $InfoBG
onready var info_text: Label = $InfoBG/Text
onready var setting: ColorRect = $SettingsBG
onready var time_vis: ColorRect = $TimeVisualizer

onready var fps_btn: CheckBox = $SettingsBG/Scroll/VBox/FPS/CheckBox
onready var memory_btn: CheckBox = $SettingsBG/Scroll/VBox/Memory/CheckBox
onready var time_btn: CheckBox = $SettingsBG/Scroll/VBox/Timescale/CheckBox

func _ready() -> void:
    disable()

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        match [event.scancode, event.pressed]:
            [KEY_ESCAPE, true]:
                toggle()
            [KEY_BACKSPACE, true]:
                Engine.time_scale = timescale
                time_vis.visible = true
            [KEY_BACKSPACE, false]:
                Engine.time_scale = 1.0
                time_vis.visible = false

func set_timescale(t: float) -> void:
    timescale = t

func exit_game() -> void:
    get_tree().quit()

func reload_scene() -> void:
    # warning-ignore:return_value_discarded
    remote_values = []
    get_tree().reload_current_scene()

func toggle() -> void:
    if enabled:
        disable()
    else:
        enable()

func enable() -> void:
    enabled = true
    setting.visible = true
    get_tree().paused = true
    mousemode_cache = Input.get_mouse_mode()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func disable() -> void:
    enabled = false
    setting.visible = false
    get_tree().paused = false
    Input.set_mouse_mode(mousemode_cache)

func add_remote_value(r: RemoteValue) -> void:
    remote_values.append(r)

# warning-ignore:unused_argument
func _process(delta: float) -> void:
    var items := PoolStringArray()
    
    info.set_size(Vector2(info.get_size().x, 30))
    
    if fps_btn.pressed:
        items.append('FPS: %s' % Engine.get_frames_per_second())
    
    if memory_btn.pressed:
        items.append('Memory (static): %s / %s' % [
            OS.get_static_memory_usage(), OS.get_static_memory_peak_usage()]
        )
        items.append('Memory (dynamic): %s' % OS.get_dynamic_memory_usage())
    
    if time_btn.pressed:
        items.append('Timescale: %s' % Engine.time_scale)
    
    for r in remote_values:
        items.append('%s: %s' % [r.get_description(), r.get_value()])
    
    if items.size() > 0:
        info_text.text = items.join('\n')
        info.set_size(Vector2(info.get_size().x, info_text.get_size().y + 20))
        info.visible = true
    else:
        info.visible = false

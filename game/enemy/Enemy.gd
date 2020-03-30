extends RigidBody


enum STATE {
    NONE,  # Used as the first value for last_state
    IDLE,  # enemy is not tracking player
    FOLLOW,  # player actevely follows the player
    SEARCH,  # lost player but searching
    RETURN  #  returning to idle position
}

export var speed := 4.5
export var velocity_gain := 8.0
export var max_force := 16.0
export var nav_path := NodePath()
export var lookahead := 1.0

var last_state: int = STATE.NONE
var current_state: int = STATE.IDLE

var path_curve: Curve3D

var player_reachable := false
var player: Player
var nav: Navigation

var player_last_calc_pos := Vector3()
var target := Vector3()  # This is where the enemy wants to be

var home_pos: Vector3

var debug_indicator: SpatialMaterial


func _ready() -> void:
    nav = get_node(nav_path)
    target = global_transform.origin
    home_pos = global_transform.origin
    # warning-ignore:return_value_discarded
    $Detector.connect('body_entered', self, 'on_detector_entered')
    # warning-ignore:return_value_discarded
    $Detector.connect('body_exited', self, 'on_detector_exited')
    
    # Debug things. TODO: delete!
    debug_indicator = SpatialMaterial.new()
    debug_indicator.albedo_color = Color(0, 1, 0, 1)
    $DEBUG_INDICATOR.material_override = debug_indicator


func _process(delta: float) -> void:
    
    var state_changed := last_state == current_state
    last_state = current_state
    
    match current_state:
        STATE.IDLE:
            debug_indicator.albedo_color = Color(0, 1, 0, 1)
            _state_idle(delta, state_changed)
        STATE.FOLLOW:
            debug_indicator.albedo_color = Color(1, 0, 0, 1)
            _state_follow(delta, state_changed)
        STATE.SEARCH:
            debug_indicator.albedo_color = Color(0.7, 0, 1, 1)
            _state_search(delta, state_changed)
        STATE.RETURN:
            debug_indicator.albedo_color = Color(0, 0, 1, 1)
            _state_return(delta, state_changed)


func _physics_process(delta: float) -> void:
    
    # Check if the enemy can see the player:
    if player_reachable and current_state != STATE.FOLLOW:
        var state := get_world().direct_space_state
        var result := state.intersect_ray(
            global_transform.origin,
            player.global_transform.origin,
            [self],
            3 # Layers 1 and 2
        )
        if result and result.collider is Player and result.collider.is_detectable():
            current_state = STATE.FOLLOW


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
    var direction := target - state.transform.origin
    var desired := clamped(direction, 1) * speed
    var error := desired - state.linear_velocity
    var force := clamped(velocity_gain * error, max_force)
    add_central_force(force)


func _state_idle(delta: float, state_changed: bool) -> void:
    pass


func _state_follow(delta: float, state_changed: bool) -> void:
    
    var player_pos := player.global_transform.origin
    var recalc_delta_squared := player_pos.distance_squared_to(player_last_calc_pos)
    
    # Trigger a path recalculation if this is the first frame in this
    # state or when the player moved more than 0.5 units (=0.25 when squared)
    if state_changed or recalc_delta_squared > 0.25:
        path_curve = calculate_path(global_transform.origin, player_pos)
        if not path_curve:
            path_curve = null
            current_state = STATE.SEARCH
    
    if path_curve:
        var offset := path_curve.get_closest_offset(global_transform.origin) + lookahead
        target = path_curve.interpolate_baked(offset)


func _state_search(delta: float, state_changed: bool) -> void:
    # Skip this state for now
    current_state = STATE.RETURN


func _state_return(delta: float, state_changed: bool) -> void:
    
    # Only calculate the path in the first frame of this state. The home position
    # will not change
    if state_changed:
        path_curve = calculate_path(global_transform.origin, home_pos)
        if not path_curve:
            push_error('Home position not reachable!')
    
    if path_curve:
        var offset := path_curve.get_closest_offset(global_transform.origin) + lookahead
        target = path_curve.interpolate_baked(offset)
    
    if home_pos.distance_squared_to(global_transform.origin) < 0.1:
        current_state = STATE.IDLE


func calculate_path(from: Vector3, to: Vector3):
    var path := nav.get_simple_path(from, to)
    if path:
        var curve = Curve3D.new()
        for point in path:
            curve.add_point(point)
        return curve
    return null


func on_detector_entered(other: Spatial):
    if other is Player:
        player_reachable = true
        player = other


func on_detector_exited(other: Spatial):
    if other is Player:
        player_reachable = false


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

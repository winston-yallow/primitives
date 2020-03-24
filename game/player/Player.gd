extends RigidBody


enum STATE {
    NORMAL,  # Player has controll
    TRANSITION_IN,  # moving into hiding spot
    HIDDEN,  # frozen in position
    TRANSITION_OUT  #  moving back to normal mode
}

export var speed := 5.0
export var transitions := 5.0

var current_state: int = STATE.NORMAL
var transition_target: Transform
var transition_origin: Transform
var transition_speed: float
var transition_fraction: float


func _ready() -> void:
    # warning-ignore:return_value_discarded
    $Detector.connect('area_entered', self, 'on_detection')
    DevTools.add_remote_value(
        RemoteProp.new(self, 'linear_velocity', ['length', 'round'])
    )
    DevTools.add_remote_value(RemoteProp.new(self, 'linear_velocity'))


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
    
    if current_state == STATE.NORMAL:
    
        var direction := Vector3()
        direction.z += Input.get_action_strength('game_forward')
        direction.z -= Input.get_action_strength('game_backward')
        direction.x += Input.get_action_strength('game_left')
        direction.x -= Input.get_action_strength('game_right')
        
        # TODO: rotate without setting the complete transform
        if state.linear_velocity:
            state.transform = state.transform.looking_at(
                state.transform.origin - state.linear_velocity, Vector3.UP
            )
        
        state.add_central_force(clamped(direction, 1) * speed)
    
    elif current_state == STATE.TRANSITION_IN:
        if mode != MODE_KINEMATIC:
            mode = MODE_KINEMATIC
        transition_fraction += state.step * transition_speed
        transition_fraction = min(1, transition_fraction)
        state.transform = transition_origin.interpolate_with(
            transition_target,
            transition_fraction
        )
        if transition_fraction == 1:
            current_state = STATE.HIDDEN


func on_detection(other: Area):
    if other.is_in_group('magnets'):
        current_state = STATE.TRANSITION_IN
        transition_target = other.global_transform
        transition_origin = global_transform
        transition_fraction = 0
        transition_speed = transitions * transition_target.origin.distance_to(
            transition_origin.origin
        )


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

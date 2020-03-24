extends RigidBody


enum STATE {
    NORMAL,  # Player has controll
    TRANSITION_IN,  # moving into hiding spot
    HIDDEN,  # frozen in position
    TRANSITION_OUT  #  moving back to normal mode
}

export(float, EASE) var input_easing := 1.5
export var speed := 5.0
export var max_force := 28.0
export var velocity_gain := 10.0
export var transition_time_scale := 20.0
export var release_force := 4.5

var current_state: int = STATE.NORMAL

var transition_target: Transform
var transition_origin: Transform
var transition_speed: float
var transition_fraction: float

onready var target_rotation := global_transform.basis.get_euler().y


func _ready() -> void:
    # warning-ignore:return_value_discarded
    $Detector.connect('area_entered', self, 'on_detection')
    DevTools.add_remote_value(
        RemoteProp.new(self, 'linear_velocity', ['length', 'round'])
    )


func _input(event: InputEvent) -> void:
    if event.is_action_pressed('reappear') and current_state == STATE.HIDDEN:
        current_state = STATE.TRANSITION_OUT


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
    
    if current_state == STATE.NORMAL:
    
        var direction := Vector3()
        direction.z += ease(Input.get_action_strength('game_forward'), input_easing)
        direction.z -= ease(Input.get_action_strength('game_backward'), input_easing)
        direction.x += ease(Input.get_action_strength('game_left'), input_easing)
        direction.x -= ease(Input.get_action_strength('game_right'), input_easing)
        
        if direction:
            var a := Vector3.FORWARD
            var b := direction
            var dot := a.x * b.x + (-a.z) * (-b.z)
            var det := a.x * (-b.z) - (-a.z) * b.x
            target_rotation = atan2(det, dot) + PI  # model is rotated by 180°
        
        var current_rotation := state.transform.basis.get_euler().y
        var new_rotation := lerp_angle(
            current_rotation,
            target_rotation,
            7 * state.step
        )
        state.transform.basis = state.transform.basis.rotated(
            Vector3.UP,
            new_rotation - current_rotation
        )
        
        var desired := clamped(direction, 1) * speed
        var error := desired - state.linear_velocity
        var force := clamped(velocity_gain * error, max_force)
        
        state.add_central_force(force)
    
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
    
    elif current_state == STATE.TRANSITION_OUT:
        # TODO: Prevent player movement until completely detached from wall
        mode = MODE_RIGID
        state.apply_central_impulse(Vector3.BACK * release_force)
        current_state = STATE.NORMAL


func on_detection(other: Area):
    if other.is_in_group('magnets') and current_state == STATE.NORMAL:
        current_state = STATE.TRANSITION_IN
        transition_target = other.global_transform
        transition_origin = global_transform
        transition_fraction = 0
        transition_speed = transition_time_scale * transition_target.origin.distance_to(
            transition_origin.origin
        )


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

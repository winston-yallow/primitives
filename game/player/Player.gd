extends RigidBody
class_name Player


enum STATE {
    NORMAL,  # Player has controll
    TRANSITION_IN,  # moving into hiding spot
    HIDDEN,  # frozen in position
    TRANSITION_OUT  #  moving back to normal mode
}

export(float, EASE) var input_easing := 1.5
export var speed := 5.0
export var max_force := 32.0
export var velocity_gain := 15.0
export var transition_time_scale := 20.0
export var release_force := 5.2
export var attach_angle := PI / 1.7
export var detach_angle := PI / 1.85

var current_state: int = STATE.NORMAL

var last_input_direction := Vector3.FORWARD

var detach_requested = false

var transition_spot: MagneticPlayerSpot
var transition_dst: Transform
var transition_src: Transform
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
    
    if event.is_action_pressed('reappear'):
        
        if current_state == STATE.HIDDEN:
            if transition_spot.locked:
                detach_requested = true
            else:
                current_state = STATE.TRANSITION_OUT
                detach_requested = false
        
        elif current_state == STATE.TRANSITION_IN:
            detach_requested = true


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
    
    var input_direction := Vector3()
    input_direction.z += ease(Input.get_action_strength('game_forward'), input_easing)
    input_direction.z -= ease(Input.get_action_strength('game_backward'), input_easing)
    input_direction.x += ease(Input.get_action_strength('game_left'), input_easing)
    input_direction.x -= ease(Input.get_action_strength('game_right'), input_easing)
    
    if input_direction:
        last_input_direction = input_direction
    
    if current_state == STATE.NORMAL:
        
        if input_direction:
            target_rotation = vec3_to_rad(input_direction)
        
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
        
        var desired := clamped(input_direction, 1) * speed
        var error := desired - state.linear_velocity
        var force := clamped(velocity_gain * error, max_force)
        
        state.add_central_force(force)
    
    elif current_state == STATE.TRANSITION_IN:
        
        if mode != MODE_KINEMATIC:
            mode = MODE_KINEMATIC
        
        transition_fraction += state.step * transition_speed
        transition_fraction = min(1, transition_fraction)
        state.transform = transition_src.interpolate_with(
            transition_dst,
            transition_fraction
        )
        if transition_fraction == 1:
            current_state = STATE.HIDDEN
            transition_spot.set_object_attached(self, true)
    
    elif current_state == STATE.HIDDEN:
        if not transition_spot.locked:
            var detach_direction := transition_spot.global_transform.basis.z
            var angle := input_direction.angle_to(detach_direction)
            if detach_requested or angle < detach_angle or not input_direction:
                current_state = STATE.TRANSITION_OUT
    
    elif current_state == STATE.TRANSITION_OUT:
        # TODO: Prevent player movement until completely detached from wall
        mode = MODE_RIGID
        var direction := transition_spot.global_transform.basis.z
        target_rotation = vec3_to_rad(direction)
        state.apply_central_impulse(direction * release_force)
        current_state = STATE.NORMAL
        transition_spot.set_object_attached(self, false)


func on_detection(other: Area):
    if other is MagneticPlayerSpot and current_state == STATE.NORMAL:
        var detach_direction := other.global_transform.basis.z
        var angle := last_input_direction.angle_to(detach_direction)
        if angle > attach_angle:
            current_state = STATE.TRANSITION_IN
            transition_spot = other
            transition_dst = other.global_transform
            transition_src = global_transform
            transition_fraction = 0
            transition_speed = transition_time_scale * transition_dst.origin.distance_to(
                transition_src.origin
            )
            detach_requested = false


func request_detach():
    detach_requested = true


func vec3_to_rad(vec3: Vector3):
    var dot := Vector3.FORWARD.x * vec3.x + (-Vector3.FORWARD.z) * (-vec3.z)
    var det := Vector3.FORWARD.x * (-vec3.z) - (-Vector3.FORWARD.z) * vec3.x
    return atan2(det, dot)


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

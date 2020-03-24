extends RigidBody


export var speed := 5.0


func _ready() -> void:
    DevTools.add_remote_value(
        RemoteProp.new(self, 'linear_velocity', ['length', 'round'])
    )


func _physics_process(delta: float) -> void:
    
    var direction := Vector3()
    direction.z += Input.get_action_strength('game_forward')
    direction.z -= Input.get_action_strength('game_backward')
    direction.x += Input.get_action_strength('game_left')
    direction.x -= Input.get_action_strength('game_right')
    
    add_central_force(
        global_transform.basis.xform(clamped(direction, 1) * speed)
    )


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

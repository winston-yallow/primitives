extends RigidBody


export var speed := 5.0


func _ready() -> void:
    DevTools.add_remote_value(RemoteProp.new(self, "linear_velocity"))


func _physics_process(delta: float) -> void:
    
    var direction := Vector3()
    
    if Input.is_action_pressed("ui_up"):
        direction.z += 1
    if Input.is_action_pressed("ui_down"):
        direction.z -= 1
    if Input.is_action_pressed("ui_left"):
        add_torque(Vector3.UP * 0.2)
    if Input.is_action_pressed("ui_right"):
        add_torque(Vector3.DOWN * 0.2)
    
    add_central_force(
        global_transform.basis.xform(direction.normalized() * speed)
    )


func clamped(vec3: Vector3, length: float) -> Vector3:
    return vec3.normalized() * length if vec3.length() > length else vec3

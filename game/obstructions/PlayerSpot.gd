extends Area
class_name MagneticPlayerSpot


signal object_attached(other)
signal object_detached(other)

export var no_locking := false

var attached := false
var locked := false
var attachment: Spatial
var remote_transform: RemoteTransform


func unlock():
    if is_instance_valid(remote_transform):
        remote_transform.queue_free()
    locked = false


func force_update():
    if is_instance_valid(remote_transform):
        remote_transform.force_update_transform()


func set_object_attached(other: Spatial, state: bool) -> void:
    if state == attached and other == attachment:
        return  # Early exit
    
    attached = state
    attachment = other
    
    if attached:
        unlock()  # Just in case (to prevent memory leaks)
        
        if not no_locking:
            locked = true
            remote_transform = RemoteTransform.new()
            remote_transform.remote_path = other.get_path()
            add_child(remote_transform)
        
        emit_signal('object_attached', other)
        
    else:
        unlock()  # Just in case (to prevent memory leaks)
        emit_signal('object_detached', other)

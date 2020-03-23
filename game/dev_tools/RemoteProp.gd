extends RemoteValue
class_name RemoteProp

var remote_target: Node
var remote_prop: String

func _init(target: Node, prop: String) -> void:
    remote_target = target
    remote_prop = prop

func get_description() -> String:
    return remote_target.name + '.' + remote_prop

func get_value() -> String:
    return remote_target.get(remote_prop)

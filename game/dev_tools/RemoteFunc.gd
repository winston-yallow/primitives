extends RemoteValue
class_name RemoteFunc

var remote_target: Node
var remote_func: String

func _init(target: Node, fn: String) -> void:
    remote_target = target
    remote_func = fn

func get_description() -> String:
    return remote_target.name + '.' + remote_func + '()'

func get_value() -> String:
    return remote_target.call(remote_func)

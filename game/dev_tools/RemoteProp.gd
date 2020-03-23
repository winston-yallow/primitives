extends RemoteValue
class_name RemoteProp

var remote_target: Node
var remote_prop: String
var remote_mods: Array

func _init(target: Node, prop: String, mods := []) -> void:
    remote_target = target
    remote_prop = prop
    remote_mods = mods

func get_description() -> String:
    return remote_target.name + '.' + remote_prop

func get_value() -> String:
    var val = remote_target.get(remote_prop)
    for mod in remote_mods:
        if mod == 'length':
            val = val.length()
        elif mod == 'round':
            val = round(val * 100) / 100
    return val

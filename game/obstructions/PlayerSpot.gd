extends Area
class_name MagneticPlayerSpot


signal player_attached
signal player_detached

var attached := false
var attachment: Spatial


func set_player_attached(other: Spatial, state: bool) -> void:
    if state == attached and other == attachment:
        return  # Early exit
    attached = state
    attachment = other
    if attached:
        emit_signal('player_attached')
    else:
        emit_signal('player_detached')

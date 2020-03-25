extends MeshInstance


var toggled := false

onready var rot_a := rotation.y
onready var rot_b := rot_a + PI

onready var tween: Tween = $Tween
onready var magnetic_spot: MagneticPlayerSpot = $MagneticPlayerSpot


func _ready() -> void:
    # warning-ignore:return_value_discarded
    tween.connect('tween_step', self, 'on_tween_step')
    # warning-ignore:return_value_discarded
    tween.connect('tween_completed', self, 'on_tween_completed')
    # warning-ignore:return_value_discarded
    magnetic_spot.connect('object_attached', self, 'on_attached')


func on_tween_step(_obj: Object, _key: NodePath, _elapsed: float, _val: Object):
    magnetic_spot.force_update()


func on_tween_completed(_obj: Object, _key: NodePath):
    magnetic_spot.unlock()


func on_attached(other: Spatial) -> void:
    if other is Player:
        other.request_detach()
        # warning-ignore:return_value_discarded
        tween.interpolate_property(
            self,
            'rotation:y',
            null,
            rot_a if toggled else rot_b,
            0.8,
            Tween.TRANS_ELASTIC,
            Tween.EASE_IN_OUT
        )
        # warning-ignore:return_value_discarded
        tween.start()
        toggled = not toggled

class_name ColorBlock extends Node2D

static func create() -> ColorBlock:
    return preload("res://components/color_block.tscn").instantiate() as ColorBlock

static var BLOCK_SIZE: Vector2 = Vector2(100, 100)

signal pressed
signal type_changed(old: Type, new: Type)

enum Type {
    Red   ,
    Blue  ,
    Green ,
    Yellow,
    Wall  ,
}

@export var type: Type: get = get_type, set = set_type

@export var pressed_sound: AudioStream: get = get_pressed_sound, set = set_pressed_sound

@onready var _sprite2d = $Sprite2D
@onready var _animation_player = $AnimationPlayer
var _audio_player = AudioStreamPlayer2D.new()

func _init():
    add_child(_audio_player)
    pressed_sound = preload("res://sounds/type_changed.mp3")
    _audio_player.finished.connect(func(): _audio_player.pitch_scale = 1)

func _ready():
    _update_texture()

func _process(delta: float):
    if _type_anim_clock > 0:
        _type_anim_clock -= delta
        if _type_anim_clock <= 0:
            var old = _type
            _type = _type_anim_to
            _update_texture()
            type_changed.emit(old, _type_anim_to)
            _animation_player.play("TypeChanged")
            _audio_player.play()

var _pressed: bool = false

func _input(event: InputEvent):
    if event is InputEventMouseButton:
        var contain = Rect2(
                global_position + Vector2(4, 4),
                BLOCK_SIZE  - 2 * Vector2(4, 4)
                ).has_point(event.position)
        if event.button_index != MOUSE_BUTTON_LEFT:
            pass
        elif event.pressed and contain:
            _pressed = true
        elif _pressed:
            if contain:
                click()
            _pressed = false

var _type: Type = Type.Red
var _type_anim_to: Type = Type.Red
var _type_anim_clock: float = 0

func get_type() -> Type: return _type
func set_type(value: Type):
    if value == _type:
        return
    var old = _type
    _type = value
    _type_anim_to = value
    _type_anim_clock = 0
    type_changed.emit(old, value)
    _update_texture()

func set_type_animated(value: Type, duration: float = 0.5, pitch: float = 1):
    if value == _type or value == _type_anim_to:
        return
    if pitch > 0:
        _audio_player.pitch_scale = pitch
    if duration == 0:
        _type = value
        _type_anim_to = value
        _type_anim_clock = 0
        _update_texture()
        _animation_player.play("Shake")
        if pitch != 0:
            _audio_player.play()
    else:
        _type_anim_to = value
        _type_anim_clock = duration

func get_pressed_sound() -> AudioStream:
    return _audio_player.stream

func set_pressed_sound(value: AudioStream):
    _audio_player.stream = value

func click():
    pressed.emit()
    _animation_player.play("Shake")
    _audio_player.play()

func stop_animation():
    _type = _type_anim_to
    _type_anim_clock = 0
    _update_texture()

# private

func _update_texture():
    if _sprite2d == null:
        return
    if type == ColorBlock.Type.Wall:
        _sprite2d.texture = preload("res://textures/wall.svg")
        _sprite2d.self_modulate = Color.WHITE
    else:
        _sprite2d.texture = preload("res://textures/block.svg")
        _sprite2d.self_modulate = {         
            Type.Red   : Color(0xca5a56ff),
            Type.Blue  : Color(0x53729dff),
            Type.Green : Color(0x63aa98ff),
            Type.Yellow: Color(0xe1c187ff),
        }.get(type, Color(0x66ccff))

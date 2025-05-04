class_name ColorBlockGrid extends Node2D

signal win
signal lose

var total_step: int = 0
var remain_step: int = 0
var target_type: ColorBlock.Type = ColorBlock.Type.Red

var current_type: ColorBlock.Type = ColorBlock.Type.Blue

var edit_mode: bool = false

@onready var _reset_audio_player = $ResetAudioPlayer

func _ready():
    set_grid_size(Vector2i(4, 4))

func _process(delta: float):
    for anim in _import_anim:
        if anim[0] > 0:
            anim[0] -= delta
        else:
            anim[1].set_type_animated(anim[2], 0, 0)
            _import_anim.erase(anim)

func _input(event: InputEvent):
    if not edit_mode:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        var block = _get_block_by_position(event.position - position)
        if block:
            block.set_type_animated(current_type, 0)
    if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT:
        var block = _get_block_by_position(event.position - position)
        if block:
            block.set_type_animated(current_type, 0)

var _grid_size: Vector2i = Vector2i(0, 0)

func get_grid_size() -> Vector2i:
    return _grid_size

func set_grid_size(value: Vector2i):
    if value == get_grid_size():
        return
    
    for pos in Utils.xy_range(_grid_size):
        var block = _get_block_at(pos.x, pos.y)
        for sig in ["pressed", "type_changed"]:
            for conn in block.get_signal_connection_list(sig):
                block.disconnect(sig, conn.callable)
        if pos.x >= value.x or pos.y >= value.y:
            block.queue_free()

    var blocks: Array[ColorBlock] = []
    
    for pos in Utils.xy_range(value):
        var block = _get_block_at(pos.x, pos.y)
        if block == null:
            block = ColorBlock.create()
            add_child(block)
        blocks.push_back(block)
        
        block.type_changed.connect(func(o, n): _on_block_type_changed(block, pos.x, pos.y, o, n))
        block.pressed.connect(func():
            if edit_mode:
                block.type = current_type
            elif block.type != ColorBlock.Type.Wall and block.type != current_type and remain_step > 0:
                block.type = current_type
                remain_step -= 1
            )
    
    _grid_size = value
    _blocks = blocks
    
    _update_block_position()

func get_type_at(x: int, y: int) -> ColorBlock.Type:
    return _get_block_at(x, y).type

func set_type_at(x: int, y: int, type: ColorBlock.Type):
    _get_block_at(x, y).type = type

func get_type_by_position(pos: Vector2):
    return _get_block_by_position(pos).type

func set_type_by_position(pos: Vector2, type: ColorBlock.Type):
    _get_block_by_position(pos).type = type

# [[dura, ColorBlock, type], ...]
var _import_anim: Array[Array] = []

func import(s: String) -> bool:
    while s.length() > 0 and (s[0] == '\n' or s[0] == ' '):
        s.erase(0)
    
    if s.is_empty():
        return false
    
    for block in _blocks:
        _block_spread_step.clear()
        block.stop_animation()
        
    var lines: PackedStringArray = s.split('\n', false)
    if lines.size() < 2:
        return false
    
    _import_anim.clear()
    
    if lines[0].length() >= 2:
        target_type = Utils.type_from_str(lines[0][0])
        total_step = int(lines[0].erase(0))
        remain_step = total_step
    else:
        target_type = ColorBlock.Type.Red
        total_step = 10
        total_step = 10
    
    lines.remove_at(0)
    var cols = lines[0].length()
    var rows = lines.size()
        
    set_grid_size(Vector2i(cols, rows))
    for block in _blocks:
        block.set_block_signals(true)
    for y in range(rows):
        for x in range(cols):
            var line = lines[y]
            _import_anim.push_back([
                    x * 0.01,
                    _get_block_at(x, y),
                    Utils.type_from_str(line[x] if x < line.length() else ""),
                ])
            #set_type_at(x, y, ))
    for block in _blocks:
        block.set_block_signals(false)

    if _reset_audio_player:
        _reset_audio_player.play()

    return true

func export() -> String:
    var s = Utils.type_to_str(target_type) + String.num_int64(total_step) + "\n"
    for y in range(get_grid_size().y):
        for x in range(get_grid_size().x):
            s += Utils.type_to_str(get_type_at(x, y))
        if y + 1 < get_grid_size().y:
            s += '\n'
    return s

# private

var _blocks: Array[ColorBlock] = []

func _get_block_at(x: int, y: int) -> ColorBlock:
    if x >= 0 and x < _grid_size.x and y >= 0 and y < _grid_size.y:
        return _blocks[y * _grid_size.x + x]
    return null

func _get_block_by_position(pos: Vector2) -> ColorBlock:
    return _get_block_at(
            floori(pos.x / ColorBlock.BLOCK_SIZE.x),
            floori(pos.y / ColorBlock.BLOCK_SIZE.y))

func _update_block_position():
    for pos in Utils.xy_range(_grid_size):
        var block: ColorBlock = _get_block_at(pos.x, pos.y)
        block.position = Vector2(
                pos.x * ColorBlock.BLOCK_SIZE.x,
                pos.y * ColorBlock.BLOCK_SIZE.y)

var _block_spread_step = {}

func _on_block_type_changed(
        sender: ColorBlock,
        x: int,
        y: int,
        old: ColorBlock.Type,
        new: ColorBlock.Type):
    if edit_mode:
        _block_spread_step.clear()
        return
        
    var spread_step = 0
    if _block_spread_step.has(sender):
        spread_step = _block_spread_step[sender] + 1
        _block_spread_step.erase(sender)
    for block: ColorBlock in [_get_block_at(x, y + 1),
                              _get_block_at(x, y - 1),
                              _get_block_at(x + 1, y),
                              _get_block_at(x - 1, y)]:
        if block == null:
            continue
        if block.type == old:
            block.set_type_animated(
                    new,
                    clamp(0.5 - spread_step * 0.05, 0.1, 100),
                    clamp(1.0 + (spread_step + 1) * 0.1, 1, 4))
            _block_spread_step[block] = spread_step

    var types = _blocks.map(func(b): return b.type)
    types = types.filter(func(t): return t != ColorBlock.Type.Wall)
    
    if types.is_empty():
        return
    if types.count(target_type) == types.size():
        win.emit()
    elif _block_spread_step.is_empty() and remain_step == 0:
        lose.emit()

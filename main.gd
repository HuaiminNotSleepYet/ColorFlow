extends Control

var _current_level: = ""
@onready var _grid: ColorBlockGrid = $ColorBlockGrid

@onready var _remain_step_label = $RemainStepLabel
@onready var _target_hint_label = $TargetHintLabel

@onready var _type_selector_red    = $TypeSelector/RedSelector
@onready var _type_selector_blue   = $TypeSelector/BlueSelector
@onready var _type_selector_green  = $TypeSelector/GreenSelector
@onready var _type_selector_yellow = $TypeSelector/YellowSelector
@onready var _type_selector_wall   = $TypeSelector/WallSelector

@onready var _current_type_hint_label = $CurrentTypeHintLabel

@onready var _reset_button = $TypeSelector/ResetButton

# audio

@onready var _select_audio_player = $SelectAudioPlayer
@onready var _win_audio_player = $WinAudioPlayer

# edit panel

@onready var _edit_panel: Control = $EditPanel

var _level_list: Array[Dictionary] = []
@onready var _level_selector: ItemList = $EditPanel/LevelSelector
@onready var _reload_level_button: Button = $EditPanel/ReloadLevelButton

@onready var _target_selector: OptionButton = $EditPanel/GridContainer/TargetOptionBox
@onready var _total_step_spinbox: SpinBox = $EditPanel/GridContainer/TotalStepSpinBox
@onready var _col_spinbox: SpinBox = $EditPanel/GridContainer/ColSpinBox
@onready var _row_spinbox: SpinBox = $EditPanel/GridContainer/RowSpinBox

@onready var _textedit: TextEdit = $EditPanel/TextEdit

@onready var _import_button: BaseButton = $EditPanel/ImportButton
@onready var _export_button: BaseButton = $EditPanel/ExportButton

func _ready():
    _grid.win.connect(func(): _win_audio_player.play())
    _grid.lose.connect(func(): print("lose"))
    
    # game control

    for selector in [
            _type_selector_red   ,
            _type_selector_blue  ,
            _type_selector_green ,
            _type_selector_yellow,
            _type_selector_wall  ,
    ]:
        selector.pressed_sound = preload("res://sounds/type_selected.mp3")
        selector.pressed.connect(func():
            _grid.current_type = selector.type
            _select_audio_player.play()
            )
    
    _reset_button.pressed.connect(func(): _grid.import(_current_level))
    
    # edit panel
    
    _target_selector.item_selected.connect(func(index):
        _grid.target_type = Utils.type_from_str(_target_selector.get_item_text(index))
        )
    
    _total_step_spinbox.value_changed.connect(func(value):
        _grid.total_step = value
        _grid.remain_step = value
        )
    
    _col_spinbox.value_changed.connect(func(value: float):
        _grid.set_grid_size(Vector2i(int(value), _grid.get_grid_size().y)))
    _row_spinbox.value_changed.connect(func(value: float):
        _grid.set_grid_size(Vector2i(_grid.get_grid_size().x, int(value))))
    
    _import_button.pressed.connect(func():
        if _grid.import(_textedit.text):
            _total_step_spinbox.value = _grid.total_step
            _col_spinbox.value = _grid.get_grid_size().x
            _row_spinbox.value = _grid.get_grid_size().y
            _current_level = _textedit.text
        )
    _export_button.pressed.connect(func(): _textedit.text = _grid.export())

    _level_selector.item_selected.connect(func(index):
        var level = _level_list[index].level
        _current_level = level
        _grid.import(level)
        for i in range(_target_selector.item_count):
            if _target_selector.get_item_text(i) == Utils.type_to_str(_grid.target_type):
                _target_selector.selected = i
                break
        _total_step_spinbox.value = _grid.total_step
        _col_spinbox.value = _grid.get_grid_size().x
        _row_spinbox.value = _grid.get_grid_size().y
        _textedit.text = level
        )
    _reload_level_button.pressed.connect(self._load_levels)
    _load_levels()

static func _colored_text(color: ColorBlock.Type, s: String) -> String:
    return {
            ColorBlock.Type.Red   : "[color=#ca5a56]",
            ColorBlock.Type.Blue  : "[color=#53729d]",
            ColorBlock.Type.Green : "[color=#63aa98]",
            ColorBlock.Type.Yellow: "[color=#e1c187]",
    }.get(color, "[color=#FFFFFF]") + s + "[/color]"

func _process(_delta: float):
    _grid.position = get_viewport_rect().size / 2 - Vector2(_grid.get_grid_size()) * ColorBlock.BLOCK_SIZE / 2
    
    _current_type_hint_label.position = {
            ColorBlock.Type.Red   : _type_selector_red,
            ColorBlock.Type.Blue  : _type_selector_blue,
            ColorBlock.Type.Green : _type_selector_green,
            ColorBlock.Type.Yellow: _type_selector_yellow,
            ColorBlock.Type.Wall  : _type_selector_wall,
    }.get(_grid.current_type).global_position + Vector2(-20, 50) - _current_type_hint_label.size / 2
    
    if _grid.remain_step < 2:
        _remain_step_label.text = "Remain Steps: " + _colored_text(ColorBlock.Type.Red, String.num_int64(_grid.remain_step))
    else:
        _remain_step_label.text = "Remain Steps: " + _colored_text(ColorBlock.Type.Yellow, String.num_int64(_grid.remain_step))
    
    _target_hint_label.position = _grid.position + Vector2(0, 10 + _grid.get_grid_size().y * ColorBlock.BLOCK_SIZE.y)
    _target_hint_label.text = "Make all blocks to " + {
            ColorBlock.Type.Red   : "[color=#ca5a56]Red[/color]",
            ColorBlock.Type.Blue  : "[color=#53729d]Blue[/color]",
            ColorBlock.Type.Green : "[color=#63aa98]Green[/color]",
            ColorBlock.Type.Yellow: "[color=#e1c187]Yellow[/color]",
    }.get(_grid.target_type, "")

func _input(event: InputEvent):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
            _set_edit_mode(not _grid.edit_mode)
    elif event is InputEventKey and event.is_pressed():
        var selector: ColorBlock = {
                KEY_1: _type_selector_blue,
                KEY_2: _type_selector_red,
                KEY_3: _type_selector_yellow,
                KEY_4: _type_selector_green,
                KEY_5: _type_selector_wall,
        }.get(event.keycode)
        if selector == null:
            return
        elif selector == _type_selector_wall:
            if _grid.edit_mode:
                selector.click()
        else:
            selector.click()

# private

func _set_edit_mode(on: bool):
    _grid.edit_mode = on
    
    if on:
        for i in range(_target_selector.item_count):
            if _target_selector.get_item_text(i) == Utils.type_to_str(_grid.target_type):
                _target_selector.selected = i
                break
        _total_step_spinbox.value = _grid.total_step
        _col_spinbox.value = _grid.get_grid_size().x
        _row_spinbox.value = _grid.get_grid_size().y
        _textedit.text = _grid.export()
        _current_level = _grid.export()
    else:
        if _grid.current_type == ColorBlock.Type.Wall:
            _grid.current_type = ColorBlock.Type.Green
        _grid.remain_step = int(_total_step_spinbox.value)
    
    _type_selector_wall.set_process_input(on)
    create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(
        _type_selector_wall, "transform", Transform2D(0, Vector2(0, 170)) if on else Transform2D(0, Vector2(5, 65)), 0.3)
    create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(
        _type_selector_wall, "scale", Vector2(1, 1) if on else Vector2(0.9, 0.9), 0.3)
    
    create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(
        _edit_panel, "offset_left", 20.0 if on else -20 -_edit_panel.size.x, 0.3)

func _load_levels():
    _level_selector.clear()
    _level_list.clear()
    
    var load_level = func(level_data: Dictionary): 
        var level = {
                "name": level_data.get("name", ""),
                "author": level_data.get("author", ""),
                "level": "\n".join(level_data.get("level", ""))
        }
        if level["name"].is_empty() or level["author"].is_empty() or level["level"].is_empty():
            return
        _level_list.push_back(level)
        _level_selector.add_item("[%s] %s" % [level["author"], level["name"]])
    
    var local_level_dir = DirAccess.open("./levels")
    if local_level_dir == null:
        return
    for file in local_level_dir.get_files():
        var f = FileAccess.open("./levels/" + file, FileAccess.READ)
        if f == null:
            continue
        for level_data in JSON.parse_string(f.get_as_text()):
            load_level.call(level_data)
        f.close()

class_name Utils

static func xy_range(v: Vector2i) -> Array[Vector2i]:
    var arr: Array[Vector2i]
    for yy in range(v.y):
        for xx in range(v.x):
            arr.push_back(Vector2i(xx, yy))
    return arr

static func type_from_str(s: String) -> ColorBlock.Type:
    return {
            "🟥": ColorBlock.Type.Red,
            "🟦": ColorBlock.Type.Blue,
            "🟩": ColorBlock.Type.Green,
            "🟨": ColorBlock.Type.Yellow,
            "⬛": ColorBlock.Type.Wall,
    }.get(s, ColorBlock.Type.Wall)

static func type_to_str(t: ColorBlock.Type) -> String:
    return {
            ColorBlock.Type.Red   : "🟥",
            ColorBlock.Type.Blue  : "🟦",
            ColorBlock.Type.Green : "🟩",
            ColorBlock.Type.Yellow: "🟨",
            ColorBlock.Type.Wall  : "⬛",
    }.get(t, "⬛")

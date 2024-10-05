class_name Stage
extends Node2D

var picture_mode := false

func _ready() -> void:
    RenderingServer.set_default_clear_color(Consts.BACKGROUND_COLOR)

func _process(_dt: float) -> void:
    update_camera()
    queue_redraw()

func _draw() -> void:
    if not picture_mode:
        return

    for body in get_tree().get_nodes_in_group(Body.GROUP_NAME):
        var pts: PackedVector2Array = body.curve.get_baked_points()
        if len(pts) >= 2:
            draw_polyline(pts, body.color, 1.0, true)

func _get_picture_bb() -> Rect2:
    var bodies := get_tree().get_nodes_in_group(Body.GROUP_NAME)
    if len(bodies) == 0:
        return Rect2()
        
    var bb: Rect2 = bodies[0].picture_bb
    for b in bodies.slice(1):
        bb = bb.expand(b.picture_bb.position).expand(b.picture_bb.end)
    return bb

func set_picture_mode(x := true) -> void:
    picture_mode = x

func update_camera(reset := false) -> void:
    var camera := get_viewport().get_camera_2d()
    var bodies := get_tree().get_nodes_in_group(Body.GROUP_NAME)
    if not camera or len(bodies) == 0:
        return

    var bb: Rect2
    if picture_mode:
        bb = _get_picture_bb()
    else:
        bb = Rect2(bodies[0].position - .5 * Vector2.ONE, Vector2.ONE)
        for b in bodies:
            var d: float = 15.0 * b.particles.scale_amount_max
            var b_bb := Rect2(b.position - .5 * d * Vector2.ONE, d * Vector2.ONE)
            bb = bb.expand(b_bb.position).expand(b_bb.end)

    # Center camera
    var sz: Vector2 = get_viewport().get_visible_rect().size
    var margin := sz / 16.0
    var rm = bb.grow_individual(margin.x, margin.y, margin.x, margin.y)
    var z := minf(1.0, minf(sz.x / rm.size.x, sz.y / rm.size.y))

    camera.position = bb.get_center()
    camera.zoom.x = z
    camera.zoom.y = z
    if reset:
        camera.reset_smoothing()

func export_picture(path: String, was_paused = null) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    var bb := _get_picture_bb()
    var offset := bb.position
        
    f.store_string("<?xml version=\"1.0\" standalone=\"no\"?>\n<svg width=\"%d\" height=\"%d\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">" % [ bb.size.x, bb.size.y ])
    for body in get_tree().get_nodes_in_group(Body.GROUP_NAME):
        var pts: PackedVector2Array = body.curve.get_baked_points()
        if len(pts) >= 2:
            var pts_svg: Array[String] = []
            for p in pts:
                var q := p - offset
                pts_svg.append("%f,%f" % [ q.x, q.y ])

            f.store_string("<polyline fill=\"none\" stroke=\"#%s\" stroke-width=\"1\" points=\"%s\" />\n" % [ body.color.to_html(false), " ".join(pts_svg) ])
    f.store_string("</svg>\n")
    f.close()
    
    if was_paused != null:
        get_tree().paused = was_paused

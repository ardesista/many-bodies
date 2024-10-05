@tool
extends Node2D
class_name Body

const G                   := .05     # px^3 / (Kg * s^2)
const MAX_SINGLE_ACCEL    := 600.0   # px / s^2
const INIT_VEL_MAX        := 700.0   # px / s
const INIT_RADIUS_MIN     := 20.0    # px
const INIT_RADIUS_MAX     := 100.0   # px

const GROUP_NAME          := "bodies"

@export var radius := 1.0 : set = set_radius # px
@export var color := Color.WHITE : set = set_color

@onready var particles := $particles
@onready var start_vel: Marker2D = $start_vel

var mass : float : get = get_mass # Kg
var linear_velocity := Vector2.ZERO
var linear_accel := Vector2.ZERO
var position_prev := Vector2.ZERO
var picture_bb: Rect2
var curve: Curve2D

func _ready() -> void:
    add_to_group(GROUP_NAME)
    _reset()
    set_radius(radius)
    linear_velocity = start_vel.position

func init(rng: RandomNumberGenerator) -> void:
    var dx := 2.0 * rng.randf() - 1.0
    var dy := sqrt(1.0 - dx * dx)

    radius = INIT_RADIUS_MIN + (INIT_RADIUS_MAX - INIT_RADIUS_MIN) * rng.randf()
    linear_velocity = INIT_VEL_MAX * (2.0 * rng.randf() - 1.0) * Vector2(dx, dy)
    position = get_viewport().get_visible_rect().size * Vector2(rng.randf(), rng.randf())
    _reset()

func _draw() -> void:
    if not Engine.is_editor_hint():
        return
    
    var p := start_vel.position
    var pn := p.normalized()
    draw_line(Vector2.ZERO, p, Color.WHITE, 1.0, true)
    draw_line(p, p + 16.0 * pn.rotated(.8 * PI), Color.WHITE, 1.0, true)
    draw_line(p, p + 16.0 * pn.rotated(-.8 * PI), Color.WHITE, 1.0, true)

func _reset() -> void:
    position_prev = position
    linear_accel = Vector2.ZERO
    curve = Curve2D.new()
    picture_bb = Rect2(position - .5 * Vector2.ONE, Vector2.ONE)
    particles.restart()

func set_radius(x: float) -> void:
    radius = x
    if particles:
        particles.scale_amount_max = 0.18 * radius
        particles.scale_amount_min = 0.18 * radius

func get_mass() -> float:
    return PI * radius * radius * radius

func set_color(x: Color) -> void:
    color = x
    modulate = color

func _physics_process(dt: float) -> void:
    if Engine.is_editor_hint():
        queue_redraw()
        return
    
    var dp: Vector2
    var d: float 
    var linear_impulse := Vector2.ZERO
    linear_accel = Vector2.ZERO
    for other in get_tree().get_nodes_in_group(GROUP_NAME):
        if other == self:
            continue
    
        dp = (position - other.position)
        d = dp.length()
        if d >= radius + other.radius:
            linear_accel += (-G * other.mass * dp / (d * d)) #.limit_length(MAX_SINGLE_ACCEL)
        else:
            linear_impulse += -2.0 * other.mass * dp.dot(linear_velocity - other.linear_velocity) / (d * d * (mass + other.mass)) * dp

    linear_velocity += linear_accel * dt + linear_impulse
    position += linear_velocity * dt
    if position.distance_to(position_prev) > 1.0:
        curve.add_point(position)
        picture_bb = picture_bb.expand(position)
        position_prev = position

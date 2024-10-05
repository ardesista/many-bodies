extends Stage

const BodyScene := preload("res://Body.tscn")
const ExportDialogScene := preload("res://ExportDialog.tscn")

@onready var seed_line := $HUD/SeedLine
@onready var pause_button := $HUD/PauseButton
@onready var picture_button := $HUD/PictureButton
@onready var n_spinbox := $HUD/NSpinBox

var rng := RandomNumberGenerator.new()

func _ready() -> void:
    super._ready()
    randomize()
    set_bodies_num(int(n_spinbox.value), false)
    set_seed(randi())

func set_bodies_num(n: int, reset := true) -> void:
    var bodies := get_tree().get_nodes_in_group(Body.GROUP_NAME)
    var n_old := len(bodies)
    if n == n_old:
        return

    if n > n_old:
        for i in range(n_old, n):
            var body: Body = BodyScene.instantiate()
            body.color = Color(Consts.BODIES_PALETTE[i % len(Consts.BODIES_PALETTE)])
            add_child(body)
    else:
        for body in bodies.slice(n, n_old):
            body.queue_free() 

    if reset:
        set_seed(seed_line.text.hex_to_int())

func set_seed(x: int) -> void:
    rng.seed = x
    seed_line.text = "%x" % [ x ]
    get_tree().call_group(Body.GROUP_NAME, "init", rng)
    update_camera(true)

func _on_seed_line_text_changed(new_text: String) -> void:
    var t := ""
    for c in new_text:
        if c.to_lower() in [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ]:
            t += c
            if len(t) >= 8:
                break

    if new_text != t:
        seed_line.text = t

func _on_seed_line_text_submitted(new_text: String) -> void:
    if len(new_text) > 0:
        set_seed(new_text.hex_to_int())

func _on_gen_button_pressed() -> void:
    set_seed(randi())

func _on_restart_button_pressed() -> void:
    set_seed(rng.seed)

func _on_pause_button_toggled(button_pressed: bool) -> void:
    get_tree().paused = button_pressed
    pause_button.text = "Play" if button_pressed else "Pause"

func _on_picture_button_toggled(button_pressed: bool) -> void:
    picture_mode = button_pressed
    picture_button.text = "Near" if button_pressed else "Picture"
    queue_redraw()

func _on_export_button_pressed():
    var dialog := ExportDialogScene.instantiate()
    var tree := get_tree()
    var is_paused = tree.paused
    if not is_paused:
        tree.paused = true
        dialog.connect("canceled", tree.set.bind("paused", false))
    dialog.connect("file_selected", self.export_picture.bind(is_paused))
    dialog.popup_exclusive_centered(self)

func _on_n_spin_box_value_changed(value: float) -> void:
    set_bodies_num(int(value))

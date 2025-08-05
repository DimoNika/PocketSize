extends Node3D

var win_label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	win_label = $WinLabel
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		print("player won")
		win_label.visible = true

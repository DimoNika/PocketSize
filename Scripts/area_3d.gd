extends Area3D

var label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label = $BlueLabel
	label.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		body.pick_deminishing_gem()
		label.visible = true
		
		$blue_gem.visible = false
		
	pass # Replace with function body.

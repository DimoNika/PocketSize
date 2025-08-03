extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$YellowLabel.visible = false
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		body.pick_magnifying_gem()
		$YellowLabel.visible = true
		
		$yellow_gem.visible = false
		
		
	pass # Replace with function body.

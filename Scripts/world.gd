extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = $Player
	var custom_camera = $CustomCamera
	var vertical_camera_adjuster = $VerticalCameraAdjuster
	custom_camera.position = Vector3(player.position.x, vertical_camera_adjuster.position.y, 6)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player = $Player
	var custom_camera = $CustomCamera
	var vertical_camera_adjuster = $VerticalCameraAdjuster
	
	custom_camera.position = Vector3(player.position.x + player.camera_offset, vertical_camera_adjuster.position.y + 1.5, 6)
	

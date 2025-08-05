extends Node3D

var timer1 = 210
var timer2 = 240

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer1 -= 1
	timer2 -= 1
	if timer1 < 0:
		var rock_scene = preload("res://Scene/falling_obj.tscn")
		var rock_instance = rock_scene.instantiate()
		rock_instance.position = Vector3(171, 52, 0)
			
		#rock_instance.position = Vector3(1,1,1)
		add_child(rock_instance)
		timer1 = 210
	if timer2 < 0:
		var rock_scene = preload("res://Scene/falling_obj.tscn")
		var rock_instance = rock_scene.instantiate()
		rock_instance.position = Vector3(180, 60, 0)
			
		#rock_instance.position = Vector3(1,1,1)
		add_child(rock_instance)
		timer2 = 240
	
	
